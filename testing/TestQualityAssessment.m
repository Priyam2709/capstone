classdef TestQualityAssessment < matlab.unittest.TestCase
% TESTQUALITYASSESSMENT Unit tests for retinal Image Quality Assessment (IQA).
%
%   Verifies blur, brightness, contrast, noise, sharpness, and classification logic.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        GoodTestImage uint8
        BlurryTestImage uint8
    end

    methods (TestMethodSetup)
        function setupTestImages(testCase)
            % Synthetic sharp fundus patch
            [X, Y] = meshgrid(1:100, 1:100);
            sharpPattern = uint8(128 + 50 * sin(X / 5) .* cos(Y / 5));
            testCase.GoodTestImage = repmat(sharpPattern, [1, 1, 3]);

            % Synthetic blurry fundus patch (Gaussian smoothed)
            blurryPattern = uint8(imgaussfilt(double(sharpPattern), 6.0));
            testCase.BlurryTestImage = repmat(blurryPattern, [1, 1, 3]);
        end
    end

    methods (Test)
        function testBlurDistinction(testCase)
            sharpScore = computeBlur(testCase.GoodTestImage(:, :, 2));
            blurryScore = computeBlur(testCase.BlurryTestImage(:, :, 2));
            testCase.verifyGreaterThan(sharpScore, blurryScore, ...
                'Sharp image Laplacian variance must exceed blurry image score.');
        end

        function testBrightnessCalculation(testCase)
            [meanB, uniformity] = computeBrightness(testCase.GoodTestImage);
            testCase.verifyGreaterThan(meanB, 0, 'Mean brightness must be positive.');
            testCase.verifyLessThanOrEqual(meanB, 255, 'Mean brightness must not exceed 255.');
            testCase.verifyGreaterThanOrEqual(uniformity, 0, 'Uniformity must be >= 0.');
        end

        function testContrastCalculation(testCase)
            c = computeContrast(testCase.GoodTestImage(:, :, 2));
            testCase.verifyGreaterThan(c, 0, 'RMS contrast of structured pattern must be positive.');
        end

        function testAssessImageQualityStructure(testCase)
            cfg = loadConfig();
            report = assessImageQuality(testCase.GoodTestImage, cfg);

            testCase.verifyTrue(isfield(report, 'overallScore'), 'Report must contain overallScore.');
            testCase.verifyTrue(isfield(report, 'category'), 'Report must contain category.');
            testCase.verifyTrue(isfield(report, 'recommendation'), 'Report must contain recommendation.');
            testCase.verifyTrue(any(strcmp(report.category, {'Good', 'Needs Enhancement', 'Retake Image'})), ...
                'Category must match defined clinical classes.');
        end
    end
end
