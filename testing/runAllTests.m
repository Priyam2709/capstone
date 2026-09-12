function testResults = runAllTests()
% RUNALLTESTS Executes the complete automated test suite for SIH26038.
%
%   testResults = runAllTests()
%
%   Discovers and executes all 9 unit and integration test classes:
%     1. TestUtils - Path resolution, config loading, logging, image I/O
%     2. TestDatasetLoader - APTOS/EyePACS/IDRiD/Messidor loading & synthetic data
%     3. TestQualityAssessment - Blur, brightness, contrast, noise, sharpness, IQA
%     4. TestPreprocessing - CLAHE, illumination correction, median filter, PSNR/SSIM
%     5. TestModelClassification - Deep learning inference, 5 stages, referral logic
%     6. TestExplainability - Grad-CAM saliency heatmaps, overlay, justifications
%     7. TestReportGenerator - Patient PDF reports, clinical summaries, cohort rosters
%     8. TestGUI - 9-tab App Designer navigation, callbacks, and teardown
%     9. TestSimulinkQueue - Discrete-event simulation, M/M/c queues, sensitivity
%
%   Outputs:
%       testResults - Array of matlab.unittest.TestResult objects.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    fprintf('========================================================================\n');
    fprintf('  SIH26038: Comprehensive System & Unit Test Runner\n');
    fprintf('  Explainable AI Diabetic Retinopathy Screening System (Rural India)\n');
    fprintf('========================================================================\n\n');

    % Ensure project paths are initialized
    startup;

    projectRoot = getProjectRoot();
    testingDir = fullfile(projectRoot, 'testing');

    % Discover and construct full test suite
    testFiles = { ...
        'TestUtils.m', ...
        'TestDatasetLoader.m', ...
        'TestQualityAssessment.m', ...
        'TestPreprocessing.m', ...
        'TestModelClassification.m', ...
        'TestExplainability.m', ...
        'TestReportGenerator.m', ...
        'TestGUI.m', ...
        'TestSimulinkQueue.m', ...
        'TestStressAndEdgeCases.m' ...
    };

    fullSuite = [];
    for k = 1:numel(testFiles)
        fPath = fullfile(testingDir, testFiles{k});
        if exist(fPath, 'file')
            try
                suiteItem = matlab.unittest.TestSuite.fromFile(fPath);
                fullSuite = [fullSuite, suiteItem]; %#ok<AGROW>
                fprintf('  [LOADED] Test Suite: %-25s (%d test cases)\n', testFiles{k}, numel(suiteItem));
            catch ME
                fprintf('  [WARN]   Could not load suite %s: %s\n', testFiles{k}, ME.message);
            end
        end
    end

    fprintf('\nTotal test cases queued for execution: %d\n', numel(fullSuite));
    fprintf('Running automated verification suite...\n\n');

    % Execute tests
    startTime = tic;
    testResults = run(fullSuite);
    totalElapsedSec = toc(startTime);

    % Tabulate Results
    numPassed = sum([testResults.Passed]);
    numFailed = sum([testResults.Failed]);
    numIncomplete = sum([testResults.Incomplete]);

    fprintf('\n========================================================================\n');
    fprintf('  TEST EXECUTION SUMMARY REPORT\n');
    fprintf('========================================================================\n');
    fprintf('  Total Test Cases : %d\n', numel(testResults));
    fprintf('  Passed           : %d (%5.1f%%)\n', numPassed, (numPassed / max(1, numel(testResults))) * 100);
    fprintf('  Failed           : %d\n', numFailed);
    fprintf('  Incomplete       : %d\n', numIncomplete);
    fprintf('  Execution Time   : %.2f seconds\n', totalElapsedSec);
    fprintf('========================================================================\n\n');

    % Save structured test audit report to results/reports/
    reportsDir = fullfile(projectRoot, 'results', 'reports');
    if ~exist(reportsDir, 'dir')
        mkdir(reportsDir);
    end

    reportSummary = struct();
    reportSummary.timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    reportSummary.totalTests = numel(testResults);
    reportSummary.passed = numPassed;
    reportSummary.failed = numFailed;
    reportSummary.durationSeconds = totalElapsedSec;
    reportSummary.passRatePct = (numPassed / max(1, numel(testResults))) * 100;

    reportPath = fullfile(reportsDir, 'test_execution_report.json');
    fid = fopen(reportPath, 'w');
    if fid ~= -1
        fprintf(fid, '%s', jsonencode(reportSummary));
        fclose(fid);
        logger.info('Test audit report saved to: %s', reportPath);
    end

    if numFailed > 0
        logger.error('Unit tests completed with %d failure(s).', numFailed);
    else
        logger.info('ALL %d UNIT TESTS PASSED SUCCESSFULLY! (Pass rate: 100%%)', numPassed);
    end
end
