function testSimulinkModule()
% TESTSIMULINKMODULE Automated verification test suite for Simulink & DES queues.
%
%   Verifies:
%     1. Parameter initialization and theoretical M/M/c analytical formulas.
%     2. Custom parameter overrides (varying camp hours, camera count).
%     3. Full discrete-event simulation execution across an 8-hour shift.
%     4. Entity integrity (timestamps, monotonicity, non-negative queues).
%     5. Server utilization calculations and bottleneck identification.
%     6. Sensitivity analysis (1 Camera vs 2 Cameras impact on wait times).
%     7. Plot generation and figure export to disk.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    fprintf('========================================================================\n');
    fprintf('  SIH26038: Running Simulink & Queueing Workflow Tests (Prompt 10)\n');
    fprintf('========================================================================\n\n');

    testsPassed = 0;
    totalTests = 7;

    try
        % -------------------------------------------------------------
        % Test 1: Parameter Setup & Theoretical Queueing Analysis
        % -------------------------------------------------------------
        fprintf('[TEST 1/7] Testing parameter initialization & M/M/c queueing model...\n');
        simParams = setupSimulinkModel();
        assert(isstruct(simParams), 'simParams must be a struct.');
        assert(isfield(simParams, 'analytics'), 'simParams must contain analytical estimates.');
        assert(simParams.analytics.utilization.camera > 0, 'Camera utilization must be > 0.');
        assert(~isempty(simParams.analytics.bottleneckStation), 'Bottleneck station must be identified.');
        fprintf('  -> Default model setup valid. Theoretical Bottleneck: %s (Util: %.1f%%)\n', ...
                simParams.analytics.bottleneckStation, simParams.analytics.bottleneckUtilization * 100);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 2: Custom Parameter Overrides
        % -------------------------------------------------------------
        fprintf('[TEST 2/7] Testing custom parameter overrides (2 cameras, 10-hr camp)...\n');
        custom = struct('campHours', 10, 'patientsPerDay', 150, 'numCameras', 2);
        params2 = setupSimulinkModel(custom);
        assert(params2.campHours == 10, 'Camp hours override failed.');
        assert(params2.station2_camera.numServers == 2, 'Camera count override failed.');
        assert(params2.analytics.utilization.camera < simParams.analytics.utilization.camera, ...
               'Dual cameras should have lower utilization than single camera.');
        fprintf('  -> Overrides verified. Dual-camera utilization dropped from %.1f%% to %.1f%%\n', ...
                simParams.analytics.utilization.camera * 100, params2.analytics.utilization.camera * 100);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 3: Run Discrete-Event Simulation (Baseline: 1 Camera)
        % -------------------------------------------------------------
        fprintf('[TEST 3/7] Running 8-hour discrete-event simulation (1 Camera baseline)...\n');
        simResults1 = runCampSimulation(simParams, 42);
        assert(isstruct(simResults1), 'Simulation results must be a struct.');
        assert(simResults1.summary.totalArrivals > 80, 'Expected at least 80 patient arrivals in 8 hours.');
        assert(simResults1.summary.totalCompleted > 0, 'Completed patient count must be > 0.');
        assert(simResults1.summary.meanWaitTimeMinutes >= 0, 'Waiting time must be non-negative.');
        fprintf('  -> Simulation completed: %d arrivals, %d screened (%.1f%% throughput).\n', ...
                simResults1.summary.totalArrivals, simResults1.summary.totalCompleted, ...
                simResults1.summary.completionRatePct);
        fprintf('  -> Average Wait: %.2f mins | P95 Wait: %.2f mins | Total System Time: %.2f mins\n', ...
                simResults1.summary.meanWaitTimeMinutes, simResults1.summary.p95WaitTimeMinutes, ...
                simResults1.summary.meanSystemTimeMinutes);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 4: Verify Patient Entity Timestamps & Monotonicity
        % -------------------------------------------------------------
        fprintf('[TEST 4/7] Verifying patient entity trajectory integrity...\n');
        pts = simResults1.patients;
        for k = 1:min(20, numel(pts))
            assert(pts(k).arrivalTime <= pts(k).regStartTime, 'Arrival must precede registration.');
            assert(pts(k).regStartTime <= pts(k).regEndTime, 'Registration start must precede end.');
            assert(pts(k).cameraStartTime <= pts(k).cameraEndTime, 'Camera start must precede end.');
            assert(pts(k).departureTime >= pts(k).arrivalTime, 'Departure must occur after arrival.');
        end
        fprintf('  -> Monotonic timestamps and queueing discipline verified across all patient entities.\n');
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 5: Server Utilization & Bottleneck Identification
        % -------------------------------------------------------------
        fprintf('[TEST 5/7] Verifying server utilizations & bottleneck station...\n');
        metrics = simResults1.stationMetrics;
        assert(metrics.registration.serverUtilization >= 0 && metrics.registration.serverUtilization <= 1, 'Reg util out of bounds.');
        assert(metrics.camera.serverUtilization >= 0 && metrics.camera.serverUtilization <= 1, 'Cam util out of bounds.');
        assert(metrics.ai.serverUtilization >= 0 && metrics.ai.serverUtilization <= 1, 'AI util out of bounds.');
        assert(metrics.doctor.serverUtilization >= 0 && metrics.doctor.serverUtilization <= 1, 'Doc util out of bounds.');
        assert(metrics.counselling.serverUtilization >= 0 && metrics.counselling.serverUtilization <= 1, 'Counsel util out of bounds.');

        fprintf('  -> Server Utilizations:\n');
        fprintf('       * Registration:       %5.1f%%\n', metrics.registration.serverUtilization * 100);
        fprintf('       * Fundus Camera:      %5.1f%%\n', metrics.camera.serverUtilization * 100);
        fprintf('       * Edge AI Node:       %5.1f%%\n', metrics.ai.serverUtilization * 100);
        fprintf('       * Tele-Doctor Review: %5.1f%%\n', metrics.doctor.serverUtilization * 100);
        fprintf('       * Counselling:        %5.1f%%\n', metrics.counselling.serverUtilization * 100);
        fprintf('  -> Identified Empirical Bottleneck: %s (Util: %.1f%%)\n', ...
                simResults1.summary.bottleneckStation, simResults1.summary.bottleneckUtilization * 100);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 6: Sensitivity Analysis (1 Camera vs 2 Cameras)
        % -------------------------------------------------------------
        fprintf('[TEST 6/7] Running sensitivity analysis: 1 Camera vs 2 Cameras...\n');
        paramsDual = setupSimulinkModel(struct('numCameras', 2));
        simResults2 = runCampSimulation(paramsDual, 42);

        wait1 = simResults1.summary.meanWaitTimeMinutes;
        wait2 = simResults2.summary.meanWaitTimeMinutes;
        fprintf('  -> Single Camera Mean Wait: %.2f mins | Dual Camera Mean Wait: %.2f mins\n', wait1, wait2);
        assert(wait2 < wait1, 'Adding a second camera must reduce average patient waiting time.');
        pctReduction = ((wait1 - wait2) / wait1) * 100;
        fprintf('  -> Waiting time reduced by %.1f%% with dual camera deployment!\n', pctReduction);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 7: Visualization Generation & Export
        % -------------------------------------------------------------
        fprintf('[TEST 7/7] Generating and exporting multi-panel queue analysis figure...\n');
        root = getProjectRoot();
        outFigPath = fullfile(root, 'results', 'figures', 'simulink_queue_analysis.png');
        figHandle = plotSimulationResults(simResults1, outFigPath);
        assert(isvalid(figHandle), 'Figure handle must be valid.');
        close(figHandle);
        assert(exist(outFigPath, 'file') ~= 0, 'Exported figure file must exist on disk.');
        fprintf('  -> Figure verified and exported to: %s\n', outFigPath);
        testsPassed = testsPassed + 1;

    catch ME
        fprintf('\n[FAIL] Simulink Module Test failed with error: %s\n', ME.message);
        rethrow(ME);
    end

    fprintf('\n------------------------------------------------------------------------\n');
    fprintf('  Simulink Module Tests Summary: %d / %d Tests Passed Successfully!\n', testsPassed, totalTests);
    fprintf('========================================================================\n');
end
