classdef TestGUI < matlab.unittest.TestCase
% TESTGUI Unit test suite for MATLAB App Designer interface.
%
%   Verifies:
%     1. App instantiation and component tree creation.
%     2. Switching through all 9 tabs.
%     3. Programmatic test sample loading.
%     4. Full analysis pipeline execution inside GUI context.
%     5. Clean teardown and figure destruction.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        AppInstance
    end

    methods (TestMethodSetup)
        function launchAppInstance(testCase)
            testCase.AppInstance = DRScreeningApp_exported();
        end
    end

    methods (TestMethodTeardown)
        function closeAppInstance(testCase)
            if ~isempty(testCase.AppInstance) && isvalid(testCase.AppInstance.UIFigure)
                delete(testCase.AppInstance);
            end
        end
    end

    methods (Test)
        function testAppInstantiation(testCase)
            testCase.verifyNotEmpty(testCase.AppInstance, 'App instance must not be empty.');
            testCase.verifyTrue(isvalid(testCase.AppInstance.UIFigure), 'UIFigure handle must be valid.');
        end

        function testTabNavigation(testCase)
            for tabIdx = 1:9
                testCase.AppInstance.navigateToTab(tabIdx);
                testCase.verifyEqual(testCase.AppInstance.ContentTabGroup.SelectedTab, ...
                    testCase.AppInstance.ContentTabGroup.Children(tabIdx), ...
                    sprintf('Tab %d must be selected.', tabIdx));
            end
        end

        function testPipelineInGUI(testCase)
            % 1. Load sample
            testCase.AppInstance.loadTestSample(3);
            testCase.verifyNotEmpty(testCase.AppInstance.CurrentRawImage, 'Sample image must be loaded.');

            % 2. Run quality
            testCase.AppInstance.runTestQuality();
            testCase.verifyNotEmpty(fieldnames(testCase.AppInstance.CurrentQualityResult), ...
                'Quality result must be populated in GUI.');

            % 3. Run enhancement
            testCase.AppInstance.runTestEnhancement();
            testCase.verifyNotEmpty(testCase.AppInstance.CurrentEnhancedImage, ...
                'Enhanced image must be populated in GUI.');

            % 4. Run prediction
            testCase.AppInstance.runTestPrediction();
            testCase.verifyNotEmpty(fieldnames(testCase.AppInstance.CurrentPrediction), ...
                'Prediction result must be populated in GUI.');

            % 5. Run explainability
            testCase.AppInstance.runTestXAI();
            testCase.verifyNotEmpty(fieldnames(testCase.AppInstance.CurrentXAI), ...
                'XAI result must be populated in GUI.');
        end
    end
end
