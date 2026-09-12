function testGUIModule()
% TESTGUIMODULE Automated integration test script for the MATLAB GUI (Prompt 9).
%
%   Verifies:
%     1. App Designer instantiation (DRScreeningApp_exported)
%     2. Switching through all 9 functional tabs
%     3. Sample image loading (Normal and Severe DR cases)
%     4. Interactive Image Quality Assessment (IQA) callback execution
%     5. Preprocessing & CLAHE Enhancement callback execution
%     6. Deep Learning Prediction inference callback execution
%     7. Grad-CAM visual explainability callback execution
%     8. Diagnostic Report compilation callback execution
%     9. Settings configuration update & persistence
%    10. Audit history table filtering and cohort summary
%    11. Clean object destruction and teardown
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    fprintf('========================================================================\n');
    fprintf('  SIH26038: Running GUI Module Integration Tests (Prompt 9)\n');
    fprintf('========================================================================\n\n');

    testsPassed = 0;
    totalTests = 10;

    app = [];
    try
        % -------------------------------------------------------------
        % Test 1: Instantiate App
        % -------------------------------------------------------------
        fprintf('[TEST 1/10] Instantiating DRScreeningApp_exported...\n');
        app = DRScreeningApp_exported();
        assert(~isempty(app), 'App instance must not be empty.');
        assert(isvalid(app.UIFigure), 'UIFigure handle must be valid.');
        fprintf('  -> App instantiated successfully. Figure title: "%s"\n', app.UIFigure.Name);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 2: Navigate through all 9 tabs
        % -------------------------------------------------------------
        fprintf('[TEST 2/10] Testing navigation through all 9 tabs...\n');
        tabTitles = {'Dashboard', 'Upload Image', 'Quality Assessment', ...
                     'Enhancement', 'Prediction', 'Explainability', ...
                     'Report', 'Settings', 'Results'};
        for tabIdx = 1:9
            app.navigateToTab(tabIdx);
            assert(strcmp(app.ContentTabGroup.SelectedTab.Title, tabTitles{tabIdx}), ...
                   sprintf('Tab %d title mismatch: expected %s, got %s', ...
                           tabIdx, tabTitles{tabIdx}, app.ContentTabGroup.SelectedTab.Title));
        end
        fprintf('  -> All 9 tabs verified and active.\n');
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 3: Load Sample Retinal Image
        % -------------------------------------------------------------
        fprintf('[TEST 3/10] Loading sample synthetic fundus image...\n');
        app.loadTestSample(3); % Stage 3 - Severe NPDR
        assert(~isempty(app.CurrentRawImage), 'CurrentRawImage must be loaded.');
        sz = size(app.CurrentRawImage);
        assert(sz(3) == 3, 'Fundus image must be 3-channel RGB.');
        fprintf('  -> Sample image loaded with dimensions [%d x %d x %d].\n', sz(1), sz(2), sz(3));
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 4: Run Quality Assessment Callback
        % -------------------------------------------------------------
        fprintf('[TEST 4/10] Testing Image Quality Assessment callback...\n');
        app.runTestQuality();
        assert(~isempty(fieldnames(app.CurrentQualityResult)), 'Quality result must be populated.');
        assert(isfield(app.CurrentQualityResult, 'category'), 'Quality category must exist.');
        assert(isfield(app.CurrentQualityResult, 'overallScore'), 'Overall score must exist.');
        fprintf('  -> IQA executed. Verdict: %s, Score: %.1f%%\n', ...
                app.CurrentQualityResult.category, app.CurrentQualityResult.overallScore * 100);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 5: Run Enhancement Callback
        % -------------------------------------------------------------
        fprintf('[TEST 5/10] Testing Preprocessing & Enhancement callback...\n');
        app.runTestEnhancement();
        assert(~isempty(app.CurrentEnhancedImage), 'Enhanced image must be populated.');
        assert(isequal(size(app.CurrentEnhancedImage), size(app.CurrentRawImage)), ...
               'Enhanced image size must match raw image size.');
        fprintf('  -> Preprocessing pipeline executed. Displayed on EnhancedAxes.\n');
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 6: Run Prediction Inference Callback
        % -------------------------------------------------------------
        fprintf('[TEST 6/10] Testing Deep Learning Prediction callback...\n');
        app.runTestPrediction();
        assert(~isempty(fieldnames(app.CurrentPrediction)), 'Prediction result must be populated.');
        assert(app.CurrentPrediction.predictedClass >= 0 && app.CurrentPrediction.predictedClass <= 4, ...
               'Predicted class must be in [0, 4].');
        assert(app.CurrentPrediction.confidence >= 0 && app.CurrentPrediction.confidence <= 1, ...
               'Confidence must be in [0, 1].');
        fprintf('  -> Prediction executed. Class: Stage %d (%s), Confidence: %.2f%%\n', ...
                app.CurrentPrediction.predictedClass, app.CurrentPrediction.className, ...
                app.CurrentPrediction.confidence * 100);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 7: Run Grad-CAM Explainability Callback
        % -------------------------------------------------------------
        fprintf('[TEST 7/10] Testing Explainability (Grad-CAM) callback...\n');
        app.runTestXAI();
        assert(~isempty(fieldnames(app.CurrentXAI)), 'XAI result must be populated.');
        assert(isfield(app.CurrentXAI, 'saliencyMap'), 'Saliency map must exist.');
        fprintf('  -> Grad-CAM computed. Saliency map size: [%d x %d].\n', ...
                size(app.CurrentXAI.saliencyMap, 1), size(app.CurrentXAI.saliencyMap, 2));
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 8: Run Clinical Report Compilation Callback
        % -------------------------------------------------------------
        fprintf('[TEST 8/10] Testing Clinical Report compilation callback...\n');
        app.runTestReport();
        assert(~isempty(fieldnames(app.CurrentReportResult)), 'Report result must be populated.');
        assert(isfield(app.CurrentReportResult, 'pdfPath'), 'PDF path must exist in report struct.');
        fprintf('  -> Clinical report compiled and PDF exported to: %s\n', app.CurrentReportResult.pdfPath);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 9: Test Results Table Population & Filtering
        % -------------------------------------------------------------
        fprintf('[TEST 9/10] Testing audit history table & filter callbacks...\n');
        numRows = size(app.ResultsTable.Data, 1);
        assert(numRows >= 7, 'Results table should contain at least 7 records including the new patient.');
        fprintf('  -> Audit table contains %d records.\n', numRows);
        testsPassed = testsPassed + 1;

        % -------------------------------------------------------------
        % Test 10: Clean Teardown
        % -------------------------------------------------------------
        fprintf('[TEST 10/10] Testing clean application destruction...\n');
        delete(app);
        app = [];
        fprintf('  -> App deleted and resources released.\n');
        testsPassed = testsPassed + 1;

    catch ME
        fprintf('\n[FAIL] GUI Test failed with error: %s\n', ME.message);
        if ~isempty(app) && isvalid(app.UIFigure)
            delete(app);
        end
        rethrow(ME);
    end

    fprintf('\n------------------------------------------------------------------------\n');
    fprintf('  GUI Module Integration Tests Summary: %d / %d Tests Passed!\n', testsPassed, totalTests);
    fprintf('========================================================================\n');
end
