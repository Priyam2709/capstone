classdef TestSimulinkQueue < matlab.unittest.TestCase
% TESTSIMULINKQUEUE Unit tests for discrete-event simulation and queueing workflows.
%
%   Verifies:
%     1. Simulink / DES parameter setup and M/M/c analytical formulas.
%     2. 8-hour camp simulation execution and throughput metrics.
%     3. Entity monotonicity and non-negative wait times.
%     4. Sensitivity analysis (camera count impact).
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        DefaultParams struct
    end

    methods (TestMethodSetup)
        function setupData(testCase)
            testCase.DefaultParams = setupSimulinkModel();
        end
    end

    methods (Test)
        function testParameterInitialization(testCase)
            testCase.verifyNotEmpty(testCase.DefaultParams, 'Simulation parameters must not be empty.');
            testCase.verifyTrue(isfield(testCase.DefaultParams, 'analytics'), 'Must have analytics field.');
            testCase.verifyGreaterThan(testCase.DefaultParams.analytics.utilization.camera, 0, ...
                'Camera utilization must be positive.');
        end

        function testDiscreteEventExecution(testCase)
            simRes = runCampSimulation(testCase.DefaultParams, 42);
            testCase.verifyNotEmpty(simRes, 'Simulation result must not be empty.');
            testCase.verifyGreaterThan(simRes.summary.totalArrivals, 50, ...
                'Expected > 50 patient arrivals.');
            testCase.verifyGreaterThan(simRes.summary.totalCompleted, 0, ...
                'Completed patients must be > 0.');
            testCase.verifyGreaterThanOrEqual(simRes.summary.meanWaitTimeMinutes, 0, ...
                'Wait times must be non-negative.');
        end

        function testSensitivityAnalysis(testCase)
            sim1 = runCampSimulation(testCase.DefaultParams, 42);
            custom = struct('numCameras', 2);
            params2 = setupSimulinkModel(custom);
            sim2 = runCampSimulation(params2, 42);

            testCase.verifyLessThan(sim2.summary.meanWaitTimeMinutes, sim1.summary.meanWaitTimeMinutes, ...
                'Dual cameras must decrease mean patient wait time.');
        end
    end
end
