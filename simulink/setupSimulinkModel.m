function simParams = setupSimulinkModel(customParams)
% SETUPSIMULINKMODEL Initializes simulation parameters for rural DR screening queues.
%
%   simParams = setupSimulinkModel()
%   simParams = setupSimulinkModel(customParams)
%
%   Configures discrete-event parameters representing the rural screening workflow:
%     1. Patient Arrival Process (Poisson process at rural primary health camp)
%     2. Registration & Vitals Station (1 ASHA worker)
%     3. Fundus Image Acquisition Station (1 or 2 Handheld / Tabletop cameras)
%     4. Image Quality Assessment (IQA) & Retake Feedback Loop
%     5. Edge AI Pipeline (Quality, CLAHE Enhancement, ResNet-50, Grad-CAM)
%     6. Tele-Ophthalmologist Review Station (Selective triage for Stage >= 2)
%     7. Referral & Counselling Station
%
%   Inputs:
%       customParams - (Optional) Struct overriding default camp parameters:
%                      .patientsPerDay (default: 120)
%                      .campHours (default: 8)
%                      .numCameras (default: 1)
%                      .retakeProbability (default: 0.08)
%                      .referralProbability (default: 0.22)
%
%   Outputs:
%       simParams - Comprehensive parameter struct containing timing, capacity,
%                   stochastic distribution settings, and theoretical M/M/c
%                   and M/G/1 analytical queue metrics.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(customParams)
        customParams = struct();
    end

    logger.info('Initializing Simulink rural screening workflow parameters...');

    simParams = struct();

    % 1. Operational Camp Parameters
    if isfield(customParams, 'campHours')
        simParams.campHours = customParams.campHours;
    else
        simParams.campHours = 8.0; % 8-hour operational camp day
    end

    if isfield(customParams, 'patientsPerDay')
        simParams.patientsPerDay = customParams.patientsPerDay;
    else
        simParams.patientsPerDay = 120; % Expected attendees
    end

    simParams.campDurationMinutes = simParams.campHours * 60; % 480 minutes
    simParams.arrivalRatePerHour = simParams.patientsPerDay / simParams.campHours; % 15 patients/hr
    simParams.arrivalRatePerMin = simParams.arrivalRatePerHour / 60; % 0.25 patients/min (\lambda)
    simParams.meanInterarrivalTimeMinutes = 1 / simParams.arrivalRatePerMin; % 4.0 mins

    % 2. Station 1: Registration & Preliminary Vitals (1 ASHA worker)
    simParams.station1_registration = struct();
    simParams.station1_registration.name = 'Registration & Vitals Intake';
    simParams.station1_registration.numServers = 1;
    simParams.station1_registration.meanMinutes = 2.5; % Average 2.5 mins per patient
    simParams.station1_registration.stdMinutes = 0.5;
    simParams.station1_registration.serviceRatePerMin = 1 / simParams.station1_registration.meanMinutes; % 0.40 /min

    % 3. Station 2: Fundus Image Acquisition
    simParams.station2_camera = struct();
    simParams.station2_camera.name = 'Fundus Image Acquisition';
    if isfield(customParams, 'numCameras')
        simParams.station2_camera.numServers = customParams.numCameras;
    else
        simParams.station2_camera.numServers = 1; % 1 Portable Camera by default
    end
    simParams.station2_camera.meanMinutes = 3.2; % ~3.2 mins for bilateral capture
    simParams.station2_camera.stdMinutes = 0.8;
    simParams.station2_camera.serviceRatePerMin = 1 / simParams.station2_camera.meanMinutes; % 0.3125 /min per camera

    % 4. Quality Assessment & Retake Feedback Loop
    if isfield(customParams, 'retakeProbability')
        simParams.retakeProbability = customParams.retakeProbability;
    else
        simParams.retakeProbability = 0.08; % 8% retake rate based on blur/glare
    end
    simParams.maxRetakesAllowed = 2; % Max 2 retakes to prevent infinite queue loops

    % 5. Station 3: Automated Edge AI Pipeline (Quality + Enhancement + AI + Grad-CAM)
    simParams.station3_ai = struct();
    simParams.station3_ai.name = 'Edge AI Processing Node';
    simParams.station3_ai.numServers = 1; % Edge laptop / Jetson node
    simParams.station3_ai.iqaLatencySec = 1.2;
    simParams.station3_ai.claheLatencySec = 1.8;
    simParams.station3_ai.inferenceLatencySec = 0.4;
    simParams.station3_ai.gradCamLatencySec = 1.6;
    simParams.station3_ai.totalLatencySec = simParams.station3_ai.iqaLatencySec + ...
                                           simParams.station3_ai.claheLatencySec + ...
                                           simParams.station3_ai.inferenceLatencySec + ...
                                           simParams.station3_ai.gradCamLatencySec; % 5.0 seconds
    simParams.station3_ai.meanMinutes = simParams.station3_ai.totalLatencySec / 60.0; % ~0.0833 mins
    simParams.station3_ai.stdMinutes = 0.01;
    simParams.station3_ai.serviceRatePerMin = 1 / simParams.station3_ai.meanMinutes; % 12.0 /min

    % 6. Station 4: Tele-Ophthalmologist Review (Selective Triage)
    simParams.station4_doctor = struct();
    simParams.station4_doctor.name = 'Tele-Ophthalmologist Remote Review';
    simParams.station4_doctor.numServers = 1; % 1 Supervising Specialist at District Hub
    simParams.station4_doctor.meanMinutes = 4.0; % ~4 mins per referred patient
    simParams.station4_doctor.stdMinutes = 1.0;
    simParams.station4_doctor.serviceRatePerMin = 1 / simParams.station4_doctor.meanMinutes; % 0.25 /min

    % Triage Routing: Stage >= 2 (Moderate, Severe, PDR) require doctor review (~22%)
    if isfield(customParams, 'referralProbability')
        simParams.referralProbability = customParams.referralProbability;
    else
        simParams.referralProbability = 0.22;
    end
    simParams.doctorAuditRateNormal = 0.05; % Random 5% quality audit of Stage 0/1 cases
    simParams.doctorRoutingProbability = simParams.referralProbability + ...
                                         (1 - simParams.referralProbability) * simParams.doctorAuditRateNormal; % ~25.9%

    % 7. Station 5: Referral & Counselling Station
    simParams.station5_counselling = struct();
    simParams.station5_counselling.name = 'Patient Counselling & Referral Dispatch';
    simParams.station5_counselling.numServers = 1;
    simParams.station5_counselling.meanMinutes = 2.0;
    simParams.station5_counselling.stdMinutes = 0.5;
    simParams.station5_counselling.serviceRatePerMin = 1 / simParams.station5_counselling.meanMinutes; % 0.50 /min

    % 8. Theoretical Queueing Analysis (M/M/c & Jackson Network Formulations)
    lambda = simParams.arrivalRatePerMin;
    effectiveLambdaCamera = lambda / (1 - simParams.retakeProbability); % Feedback amplification

    % Station 1 (Registration: M/M/1)
    rhoReg = lambda / simParams.station1_registration.serviceRatePerMin;
    WqReg = rhoReg / (simParams.station1_registration.serviceRatePerMin * (1 - rhoReg));
    LqReg = rhoReg^2 / (1 - rhoReg);

    % Station 2 (Camera: M/M/c with effective rate)
    cCam = simParams.station2_camera.numServers;
    muCam = simParams.station2_camera.serviceRatePerMin;
    rhoCam = effectiveLambdaCamera / (cCam * muCam);
    if rhoCam < 1.0
        if cCam == 1
            WqCam = rhoCam / (muCam * (1 - rhoCam));
            LqCam = rhoCam^2 / (1 - rhoCam);
        else
            % M/M/2 Erlang-C formula
            r = effectiveLambdaCamera / muCam;
            p0 = 1 / (1 + r + (r^2 / 2) * (1 / (1 - rhoCam)));
            P_wait = (r^cCam / (factorial(cCam) * (1 - rhoCam))) * p0;
            WqCam = P_wait / (cCam * muCam - effectiveLambdaCamera);
            LqCam = effectiveLambdaCamera * WqCam;
        end
    else
        % Over-saturated queue
        WqCam = Inf;
        LqCam = Inf;
    end

    % Station 3 (AI: M/M/1)
    rhoAI = lambda / simParams.station3_ai.serviceRatePerMin;
    WqAI = rhoAI / (simParams.station3_ai.serviceRatePerMin * (1 - rhoAI));
    LqAI = rhoAI^2 / (1 - rhoAI);

    % Station 4 (Doctor Review: M/M/1 with routed arrival)
    lambdaDoc = lambda * simParams.doctorRoutingProbability;
    muDoc = simParams.station4_doctor.serviceRatePerMin;
    rhoDoc = lambdaDoc / muDoc;
    if rhoDoc < 1.0
        WqDoc = rhoDoc / (muDoc * (1 - rhoDoc));
        LqDoc = rhoDoc^2 / (1 - rhoDoc);
    else
        WqDoc = Inf;
        LqDoc = Inf;
    end

    % Compile Analytics
    simParams.analytics = struct();
    simParams.analytics.utilization = struct( ...
        'registration', min(1.0, rhoReg), ...
        'camera', min(1.0, rhoCam), ...
        'ai', min(1.0, rhoAI), ...
        'doctor', min(1.0, rhoDoc));

    simParams.analytics.expectedWaitMinutes = struct( ...
        'registration', max(0, WqReg), ...
        'camera', max(0, WqCam), ...
        'ai', max(0, WqAI), ...
        'doctor', max(0, WqDoc));

    simParams.analytics.expectedQueueLength = struct( ...
        'registration', max(0, LqReg), ...
        'camera', max(0, LqCam), ...
        'ai', max(0, LqAI), ...
        'doctor', max(0, LqDoc));

    % Identify Theoretical Bottleneck
    utils = [rhoReg, rhoCam, rhoAI, rhoDoc];
    names = {'Registration Worker', 'Fundus Camera Station', 'Edge AI Compute Node', 'Tele-Ophthalmologist'};
    [maxUtil, bIdx] = max(utils);
    simParams.analytics.bottleneckStation = names{bIdx};
    simParams.analytics.bottleneckUtilization = maxUtil;

    % Theoretical maximum sustainable throughput
    maxThroughputPerMin = min([simParams.station1_registration.serviceRatePerMin, ...
                               (cCam * muCam) * (1 - simParams.retakeProbability), ...
                               simParams.station3_ai.serviceRatePerMin, ...
                               muDoc / simParams.doctorRoutingProbability]);
    simParams.analytics.maxDailyCapacity = floor(maxThroughputPerMin * simParams.campDurationMinutes * 0.95);

    % Assign into base workspace for Simulink block diagrams
    try
        assignin('base', 'simParams', simParams);
    catch
        % Ignored in non-interactive sessions
    end

    logger.info('Simulink Model Setup Complete. Primary Bottleneck: %s (%.1f%% Util) | Max Daily Capacity: %d patients', ...
                simParams.analytics.bottleneckStation, simParams.analytics.bottleneckUtilization * 100, ...
                simParams.analytics.maxDailyCapacity);
end
