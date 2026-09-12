function simResults = runCampSimulation(simParams, randomSeed)
% RUNCAMPSIMULATION Executes high-fidelity discrete-event screening camp simulation.
%
%   simResults = runCampSimulation()
%   simResults = runCampSimulation(simParams)
%   simResults = runCampSimulation(simParams, randomSeed)
%
%   Simulates individual patient flow through a rural primary health screening
%   camp over an operational day (typically 8 hours = 480 minutes).
%
%   Simulation Pipeline:
%     1. Patient Arrival Process: Non-homogeneous / homogeneous Poisson process
%     2. Registration & Preliminary Vitals Intake (ASHA Worker)
%     3. Fundus Image Acquisition Station (1 or 2 Handheld Cameras)
%     4. Image Quality Assessment (IQA) & Retake Feedback Loop
%     5. Edge AI Processing (IQA + CLAHE Preprocessing + ResNet-50 + Grad-CAM)
%     6. Tele-Ophthalmologist Review (Selective Triage for Stage >= 2)
%     7. Patient Counselling & Referral Dispatch
%
%   Inputs:
%       simParams  - (Optional) Struct of parameters from setupSimulinkModel().
%       randomSeed - (Optional) Integer seed for reproducibility (default: 42).
%
%   Outputs:
%       simResults - Struct containing:
%                    .summary: Overall throughput, average & 95th percentile wait times
%                    .stationMetrics: Per-station utilization, wait, and queue stats
%                    .timeSeries: Minute-by-minute queue lengths and server states
%                    .patientTable: Comprehensive tabular record of all patients
%                    .simParams: Configuration parameters used
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(simParams)
        simParams = setupSimulinkModel();
    end

    if nargin < 2 || isempty(randomSeed)
        randomSeed = 42;
    end

    % Set random seed for deterministic verification
    rng(randomSeed);

    logger.info('Starting Rural Screening Camp Discrete-Event Simulation (Seed: %d)...', randomSeed);

    T_end = simParams.campDurationMinutes; % 480 minutes

    % -----------------------------------------------------------------
    % 1. Generate Patient Arrivals via Poisson Process
    % -----------------------------------------------------------------
    lambda = simParams.arrivalRatePerMin;
    interArrivals = exprnd(1 / lambda, [round(simParams.patientsPerDay * 1.5), 1]);
    arrivalTimes = cumsum(interArrivals);
    % Retain arrivals during camp operational hours
    validArrivals = arrivalTimes(arrivalTimes <= T_end);
    N_patients = numel(validArrivals);

    logger.info('Generated %d patient arrivals for %d-hour camp shift.', N_patients, simParams.campHours);

    % Initialize Patient Entity Structure Array
    patients = repmat(struct( ...
        'id', 0, ...
        'arrivalTime', 0, ...
        'regWaitTime', 0, 'regStartTime', 0, 'regDuration', 0, 'regEndTime', 0, ...
        'cameraWaitTime', 0, 'cameraStartTime', 0, 'cameraDuration', 0, 'cameraEndTime', 0, ...
        'retakeCount', 0, ...
        'aiWaitTime', 0, 'aiStartTime', 0, 'aiDuration', 0, 'aiEndTime', 0, ...
        'assignedStage', 0, 'stageName', '', 'requiresDoctor', false, ...
        'docWaitTime', 0, 'docStartTime', 0, 'docDuration', 0, 'docEndTime', 0, ...
        'counselWaitTime', 0, 'counselStartTime', 0, 'counselDuration', 0, 'counselEndTime', 0, ...
        'departureTime', 0, 'totalWaitTime', 0, 'totalSystemTime', 0, ...
        'completedInShift', false), N_patients, 1);

    % Rural epidemiological DR prevalence distribution
    % 0: No DR (70%), 1: Mild (12%), 2: Moderate (10%), 3: Severe (5%), 4: PDR (3%)
    stageProbs = [0.70, 0.12, 0.10, 0.05, 0.03];
    stageCumulative = cumsum(stageProbs);
    stageNames = {'No DR', 'Mild NPDR', 'Moderate NPDR', 'Severe NPDR', 'Proliferative DR'};

    % -----------------------------------------------------------------
    % 2. Server Availability State Trackers
    % -----------------------------------------------------------------
    regServerNextFree = 0; % Registration desk
    
    numCameras = simParams.station2_camera.numServers;
    cameraServersNextFree = zeros(1, numCameras); % Camera stations
    
    aiServerNextFree = 0; % Edge compute node
    docServerNextFree = 0; % Tele-ophthalmologist
    counselServerNextFree = 0; % Counselling desk

    % -----------------------------------------------------------------
    % 3. Sequential Event Processing per Patient
    % -----------------------------------------------------------------
    for i = 1:N_patients
        p = patients(i);
        p.id = i;
        p.arrivalTime = validArrivals(i);

        % Station 1: Registration & Preliminary Vitals
        % Service duration: log-normal or Gaussian truncated to positive
        p.regDuration = max(0.8, normrnd(simParams.station1_registration.meanMinutes, ...
                                        simParams.station1_registration.stdMinutes));
        p.regStartTime = max(p.arrivalTime, regServerNextFree);
        p.regWaitTime = p.regStartTime - p.arrivalTime;
        p.regEndTime = p.regStartTime + p.regDuration;
        regServerNextFree = p.regEndTime;

        % Station 2: Fundus Image Acquisition (with IQA Retake Loop)
        readyForCamera = p.regEndTime;
        retakes = 0;
        cumCamWait = 0;
        firstCamStart = 0;
        totalCamDuration = 0;

        while true
            % Assign to first available camera server
            [camFreeTime, chosenCamIdx] = min(cameraServersNextFree);
            camStart = max(readyForCamera, camFreeTime);
            camWait = camStart - readyForCamera;
            cumCamWait = cumCamWait + camWait;

            if retakes == 0
                firstCamStart = camStart;
            end

            camDuration = max(1.2, normrnd(simParams.station2_camera.meanMinutes, ...
                                           simParams.station2_camera.stdMinutes));
            totalCamDuration = totalCamDuration + camDuration;
            camEnd = camStart + camDuration;
            cameraServersNextFree(chosenCamIdx) = camEnd;

            % Evaluate IQA quality & retake check
            if rand() < simParams.retakeProbability && retakes < simParams.maxRetakesAllowed
                retakes = retakes + 1;
                % Patient immediately re-enters camera station after 0.5 min lens cleaning
                readyForCamera = camEnd + 0.5;
            else
                break;
            end
        end

        p.retakeCount = retakes;
        p.cameraWaitTime = cumCamWait;
        p.cameraStartTime = firstCamStart;
        p.cameraDuration = totalCamDuration;
        p.cameraEndTime = camEnd;

        % Station 3: Edge AI Processing (IQA + CLAHE + ResNet-50 + Grad-CAM)
        p.aiDuration = max(0.04, normrnd(simParams.station3_ai.meanMinutes, ...
                                         simParams.station3_ai.stdMinutes));
        p.aiStartTime = max(p.cameraEndTime, aiServerNextFree);
        p.aiWaitTime = p.aiStartTime - p.cameraEndTime;
        p.aiEndTime = p.aiStartTime + p.aiDuration;
        aiServerNextFree = p.aiEndTime;

        % Assign DR Stage & Clinical Need for Tele-Consultation
        rStage = rand();
        assignedIdx = find(rStage <= stageCumulative, 1, 'first');
        if isempty(assignedIdx), assignedIdx = 1; end
        p.assignedStage = assignedIdx - 1;
        p.stageName = stageNames{assignedIdx};

        % Selective Triage Rule: Stage >= 2 OR random 5% audit
        if p.assignedStage >= 2 || rand() < simParams.doctorAuditRateNormal
            p.requiresDoctor = true;
        else
            p.requiresDoctor = false;
        end

        % Station 4: Tele-Ophthalmologist Review (if routed)
        if p.requiresDoctor
            p.docDuration = max(1.5, normrnd(simParams.station4_doctor.meanMinutes, ...
                                            simParams.station4_doctor.stdMinutes));
            p.docStartTime = max(p.aiEndTime, docServerNextFree);
            p.docWaitTime = p.docStartTime - p.aiEndTime;
            p.docEndTime = p.docStartTime + p.docDuration;
            docServerNextFree = p.docEndTime;
            readyForCounsel = p.docEndTime;
        else
            p.docDuration = 0;
            p.docStartTime = p.aiEndTime;
            p.docWaitTime = 0;
            p.docEndTime = p.aiEndTime;
            readyForCounsel = p.aiEndTime;
        end

        % Station 5: Patient Counselling & Referral Dispatch
        p.counselDuration = max(0.8, normrnd(simParams.station5_counselling.meanMinutes, ...
                                            simParams.station5_counselling.stdMinutes));
        p.counselStartTime = max(readyForCounsel, counselServerNextFree);
        p.counselWaitTime = p.counselStartTime - readyForCounsel;
        p.counselEndTime = p.counselStartTime + p.counselDuration;
        counselServerNextFree = p.counselEndTime;

        % Total Trajectory Timestamps
        p.departureTime = p.counselEndTime;
        p.totalWaitTime = p.regWaitTime + p.cameraWaitTime + p.aiWaitTime + ...
                          p.docWaitTime + p.counselWaitTime;
        p.totalSystemTime = p.departureTime - p.arrivalTime;
        p.completedInShift = (p.departureTime <= T_end);

        patients(i) = p;
    end

    % -----------------------------------------------------------------
    % 4. Time-Series Sampling (Minute-by-minute queue lengths)
    % -----------------------------------------------------------------
    timeVector = 0:1:T_end;
    numTimeSteps = numel(timeVector);

    regQueue = zeros(1, numTimeSteps);
    camQueue = zeros(1, numTimeSteps);
    aiQueue  = zeros(1, numTimeSteps);
    docQueue = zeros(1, numTimeSteps);
    counselQueue = zeros(1, numTimeSteps);

    regBusy = zeros(1, numTimeSteps);
    camBusy = zeros(1, numTimeSteps);
    aiBusy  = zeros(1, numTimeSteps);
    docBusy = zeros(1, numTimeSteps);
    counselBusy = zeros(1, numTimeSteps);

    cumulativeArrivals = zeros(1, numTimeSteps);
    cumulativeDepartures = zeros(1, numTimeSteps);

    for tIdx = 1:numTimeSteps
        t = timeVector(tIdx);

        % Cumulative counts
        cumulativeArrivals(tIdx) = sum([patients.arrivalTime] <= t);
        cumulativeDepartures(tIdx) = sum([patients.departureTime] <= t);

        % Queue counts: arrived at station queue but not yet in service
        regQueue(tIdx) = sum([patients.arrivalTime] <= t & [patients.regStartTime] > t);
        camQueue(tIdx) = sum([patients.regEndTime] <= t & [patients.cameraStartTime] > t);
        aiQueue(tIdx)  = sum([patients.cameraEndTime] <= t & [patients.aiStartTime] > t);
        
        docWaitingMask = [patients.requiresDoctor] & [patients.aiEndTime] <= t & [patients.docStartTime] > t;
        docQueue(tIdx) = sum(docWaitingMask);

        % Counselling queue
        counselReadyTimes = arrayfun(@(p) max(p.aiEndTime, p.docEndTime), patients);
        counselQueue(tIdx) = sum(counselReadyTimes <= t & [patients.counselStartTime] > t);

        % Busy server states
        regBusy(tIdx) = sum([patients.regStartTime] <= t & [patients.regEndTime] > t) >= 1;
        camBusy(tIdx) = min(numCameras, sum([patients.cameraStartTime] <= t & [patients.cameraEndTime] > t));
        aiBusy(tIdx)  = sum([patients.aiStartTime] <= t & [patients.aiEndTime] > t) >= 1;
        docBusy(tIdx) = sum([patients.requiresDoctor] & [patients.docStartTime] <= t & [patients.docEndTime] > t) >= 1;
        counselBusy(tIdx) = sum([patients.counselStartTime] <= t & [patients.counselEndTime] > t) >= 1;
    end

    % -----------------------------------------------------------------
    % 5. Aggregate Summary Metrics & KPI Calculation
    % -----------------------------------------------------------------
    allCompleted = patients([patients.completedInShift]);
    numCompleted = numel(allCompleted);

    summary = struct();
    summary.totalArrivals = N_patients;
    summary.totalCompleted = numCompleted;
    summary.completionRatePct = (numCompleted / N_patients) * 100;
    summary.retakeTotalCount = sum([patients.retakeCount]);
    summary.retakeRatePct = (summary.retakeTotalCount / N_patients) * 100;
    summary.doctorReviewCount = sum([patients.requiresDoctor]);
    summary.doctorReviewPct = (summary.doctorReviewCount / N_patients) * 100;

    % Waiting Times
    allWaitTimes = [patients.totalWaitTime];
    allSystemTimes = [patients.totalSystemTime];
    
    summary.meanWaitTimeMinutes = mean(allWaitTimes);
    summary.medianWaitTimeMinutes = median(allWaitTimes);
    summary.p95WaitTimeMinutes = prctile(allWaitTimes, 95);
    summary.maxWaitTimeMinutes = max(allWaitTimes);

    summary.meanSystemTimeMinutes = mean(allSystemTimes);
    summary.p95SystemTimeMinutes = prctile(allSystemTimes, 95);

    % Station Specific Metrics
    stationMetrics = struct();
    stationMetrics.registration = struct( ...
        'name', 'Registration Desk', ...
        'meanWaitMinutes', mean([patients.regWaitTime]), ...
        'p95WaitMinutes', prctile([patients.regWaitTime], 95), ...
        'maxQueueLength', max(regQueue), ...
        'meanQueueLength', mean(regQueue), ...
        'serverUtilization', mean(regBusy));

    stationMetrics.camera = struct( ...
        'name', sprintf('Camera Station (%d camera)', numCameras), ...
        'meanWaitMinutes', mean([patients.cameraWaitTime]), ...
        'p95WaitMinutes', prctile([patients.cameraWaitTime], 95), ...
        'maxQueueLength', max(camQueue), ...
        'meanQueueLength', mean(camQueue), ...
        'serverUtilization', mean(camBusy) / numCameras);

    stationMetrics.ai = struct( ...
        'name', 'Edge AI Node', ...
        'meanWaitMinutes', mean([patients.aiWaitTime]), ...
        'p95WaitMinutes', prctile([patients.aiWaitTime], 95), ...
        'maxQueueLength', max(aiQueue), ...
        'meanQueueLength', mean(aiQueue), ...
        'serverUtilization', mean(aiBusy));

    docPatients = patients([patients.requiresDoctor]);
    if ~isempty(docPatients)
        docWaits = [docPatients.docWaitTime];
    else
        docWaits = 0;
    end
    stationMetrics.doctor = struct( ...
        'name', 'Tele-Ophthalmologist', ...
        'meanWaitMinutes', mean(docWaits), ...
        'p95WaitMinutes', prctile(docWaits, 95), ...
        'maxQueueLength', max(docQueue), ...
        'meanQueueLength', mean(docQueue), ...
        'serverUtilization', mean(docBusy));

    stationMetrics.counselling = struct( ...
        'name', 'Counselling & Referral', ...
        'meanWaitMinutes', mean([patients.counselWaitTime]), ...
        'p95WaitMinutes', prctile([patients.counselWaitTime], 95), ...
        'maxQueueLength', max(counselQueue), ...
        'meanQueueLength', mean(counselQueue), ...
        'serverUtilization', mean(counselBusy));

    % Bottleneck Identification
    stnUtils = [stationMetrics.registration.serverUtilization, ...
                stationMetrics.camera.serverUtilization, ...
                stationMetrics.ai.serverUtilization, ...
                stationMetrics.doctor.serverUtilization, ...
                stationMetrics.counselling.serverUtilization];
    stnNames = {'Registration', 'Fundus Camera', 'Edge AI Node', 'Tele-Ophthalmologist', 'Counselling'};
    [maxUtil, bIdx] = max(stnUtils);
    summary.bottleneckStation = stnNames{bIdx};
    summary.bottleneckUtilization = maxUtil;

    % Build Output Structure
    simResults = struct();
    simResults.summary = summary;
    simResults.stationMetrics = stationMetrics;
    simResults.simParams = simParams;
    simResults.timeSeries = struct( ...
        'time', timeVector, ...
        'cumulativeArrivals', cumulativeArrivals, ...
        'cumulativeDepartures', cumulativeDepartures, ...
        'queues', struct('registration', regQueue, 'camera', camQueue, ...
                         'ai', aiQueue, 'doctor', docQueue, 'counselling', counselQueue), ...
        'busy', struct('registration', regBusy, 'camera', camBusy, ...
                       'ai', aiBusy, 'doctor', docBusy, 'counselling', counselBusy));
    simResults.patients = patients;

    % Create structured MATLAB Table for downstream analysis
    simResults.patientTable = struct2table(patients);

    logger.info('Camp Simulation Finished: %d/%d processed (%.1f%%). Avg Wait: %.1f mins | Bottleneck: %s (%.1f%% Util)', ...
                numCompleted, N_patients, summary.completionRatePct, ...
                summary.meanWaitTimeMinutes, summary.bottleneckStation, summary.bottleneckUtilization * 100);
end
