classdef TestExplainability < matlab.unittest.TestCase
% TESTEXPLAINABILITY Unit tests for Grad-CAM saliency & Explainable AI modules.
%
%   Verifies:
%     1. Grad-CAM activation map computation on retinal fundus inputs.
%     2. Heatmap blending and colormap overlay generation.
%     3. Salient lesion segmentation and bounding box extraction.
%     4. Natural language clinical diagnostic justification generation.
%     5. Visual explanation figure exporting.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        Config struct
        SampleImage uint8
        MockPrediction struct
    end

    methods (TestMethodSetup)
        function setupData(testCase)
            testCase.Config = loadConfig();
            testCase.SampleImage = uint8(120 + 40 * rand(224, 224, 3));

            % Mock prediction structure
            testCase.MockPrediction = struct( ...
                'predictedClass', 2, ...
                'className', 'Moderate NPDR', ...
                'confidence', 0.912, ...
                'clinicalDescription', 'Microaneurysms and hard exudates detected in multiple quadrants.', ...
                'referralRecommended', true, ...
                'urgencyLevel', 'Priority Tele-Ophthalmology Referral (within 30 days)', ...
                'inferenceTimeMs', 42.5);
        end
    end

    methods (Test)
        function testComputeGradCAM(testCase)
            xai = computeGradCAM([], testCase.SampleImage, 2, testCase.Config);
            testCase.verifyNotEmpty(xai, 'computeGradCAM must return struct.');
            testCase.verifyTrue(isfield(xai, 'saliencyMap'), 'Must contain saliencyMap.');
            testCase.verifyEqual(size(xai.saliencyMap), [224, 224], ...
                'Saliency map must match input height and width.');
            testCase.verifyGreaterThanOrEqual(min(xai.saliencyMap(:)), 0.0, 'Saliency must be >= 0.');
            testCase.verifyLessThanOrEqual(max(xai.saliencyMap(:)), 1.0, 'Saliency must be <= 1.');
        end

        function testOverlayHeatmap(testCase)
            salMap = rand(224, 224);
            overlay = overlayHeatmap(testCase.SampleImage, salMap, 0.5, 'jet');
            testCase.verifyEqual(size(overlay), size(testCase.SampleImage), ...
                'Overlay size must match original image size.');
            testCase.verifyEqual(class(overlay), 'uint8', 'Overlay must be uint8.');
        end

        function testSegmentSalientLesions(testCase)
            salMap = zeros(224, 224);
            salMap(50:70, 50:70) = 0.85; % Salient hotspot
            salMap(120:140, 120:140) = 0.90;

            lesions = segmentSalientLesions(salMap, testCase.SampleImage, 0.70);
            testCase.verifyNotEmpty(lesions, 'Lesion segmentation must return struct.');
            testCase.verifyTrue(isfield(lesions, 'binaryMask'), 'Must have binaryMask.');
            testCase.verifyTrue(isfield(lesions, 'numRegions'), 'Must have numRegions.');
            testCase.verifyGreaterThanOrEqual(lesions.numRegions, 1, 'Should detect at least 1 region.');
        end

        function testGenerateExplanation(testCase)
            xai = computeGradCAM([], testCase.SampleImage, 2, testCase.Config);
            expl = generateExplanation(testCase.MockPrediction, xai, testCase.Config);
            testCase.verifyNotEmpty(expl, 'generateExplanation must return struct.');
            testCase.verifyTrue(isfield(expl, 'clinicalSummary'), 'Must have clinicalSummary.');
            testCase.verifyTrue(isfield(expl, 'formattedReport'), 'Must have formattedReport.');
            testCase.verifyNotEmpty(expl.formattedReport, 'Report text must not be empty.');
        end
    end
end
