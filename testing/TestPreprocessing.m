classdef TestPreprocessing < matlab.unittest.TestCase
% TESTPREPROCESSING Unit test suite for retinal image preprocessing and enhancement.
%
%   Verifies:
%     1. CLAHE adaptive histogram equalization on the green channel.
%     2. Illumination correction via morphological background subtraction.
%     3. Median filtering / noise reduction.
%     4. Full preprocessing pipeline execution and output formatting.
%     5. Fidelity metrics (PSNR, SSIM, contrast enhancement ratio).
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        TestFundus uint8
        Config struct
    end

    methods (TestMethodSetup)
        function setupData(testCase)
            % Synthetic 256x256 retinal patch with circular fundus mask
            H = 256; W = 256;
            [X, Y] = meshgrid(1:W, 1:H);
            mask = sqrt((X - W/2).^2 + (Y - H/2).^2) <= (W/2 - 10);

            redCh = zeros(H, W);
            greenCh = zeros(H, W);
            blueCh = zeros(H, W);

            redCh(mask) = 180 + 20 * randn(sum(mask(:)), 1);
            greenCh(mask) = 70 + 15 * randn(sum(mask(:)), 1);
            blueCh(mask) = 30 + 10 * randn(sum(mask(:)), 1);

            testCase.TestFundus = uint8(cat(3, max(0, min(255, redCh)), ...
                                              max(0, min(255, greenCh)), ...
                                              max(0, min(255, blueCh))));
            testCase.Config = loadConfig();
        end
    end

    methods (Test)
        function testApplyCLAHE(testCase)
            claheImg = applyCLAHE(testCase.TestFundus, 0.02);
            testCase.verifyEqual(size(claheImg), size(testCase.TestFundus), ...
                'CLAHE output dimensions must match input dimensions.');
            testCase.verifyEqual(class(claheImg), 'uint8', 'CLAHE output must be uint8.');
        end

        function testCorrectIllumination(testCase)
            corrImg = correctIllumination(testCase.TestFundus, 30);
            testCase.verifyEqual(size(corrImg), size(testCase.TestFundus), ...
                'Illumination corrected image dimensions must match input.');
            testCase.verifyEqual(class(corrImg), 'uint8', 'Corrected image must be uint8.');
        end

        function testApplyMedianFilter(testCase)
            filteredImg = applyMedianFilter(testCase.TestFundus, 3);
            testCase.verifyEqual(size(filteredImg), size(testCase.TestFundus), ...
                'Filtered image dimensions must match input.');
        end

        function testPreprocessPipeline(testCase)
            result = preprocessPipeline(testCase.TestFundus, testCase.Config);
            testCase.verifyNotEmpty(result, 'Pipeline result must not be empty.');
            testCase.verifyTrue(isfield(result, 'enhancedImage'), 'Result must have enhancedImage.');
            testCase.verifyTrue(isfield(result, 'metrics'), 'Result must have metrics field.');
            testCase.verifyGreaterThan(result.metrics.psnr, 15.0, 'PSNR must be > 15 dB.');
            testCase.verifyGreaterThan(result.metrics.ssim, 0.50, 'SSIM must be > 0.50.');
        end

        function testEvaluateEnhancementMetrics(testCase)
            metrics = evaluateEnhancementMetrics(testCase.TestFundus, testCase.TestFundus);
            testCase.verifyTrue(metrics.ssim >= 0.99, 'Self-SSIM must be approximately 1.0.');
            testCase.verifyTrue(isinf(metrics.psnr) || metrics.psnr > 50, 'Self-PSNR must be very high or Inf.');
        end
    end
end
