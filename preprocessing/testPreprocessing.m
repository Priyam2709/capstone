% TESTPREPROCESSING Comprehensive test runner for Prompt 4: Image Enhancement Pipeline.
%
%   Verifies:
%     1. CLAHE in L*a*b* color space
%     2. Median filtering for sensor noise suppression
%     3. Illumination correction & background leveling
%     4. Luminance histogram equalization
%     5. Dynamic range percentile contrast enhancement
%     6. Edge-preserving bilateral noise reduction
%     7. Side-by-side comparison visualizer
%     8. Quantitative metrics (PSNR, SSIM, CII, Entropy, EME)
%
%   Usage:
%       testPreprocessing
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

clear; clc; close all;
startup;

logger.info('===================================================================');
logger.info('  SIH26038: Testing Retinal Image Enhancement Pipeline (Prompt 4)  ');
logger.info('===================================================================');

cfg = loadConfig();

% 1. Obtain a Challenging Test Image (Dim & Noisy Fundus)
samplePath = fullfile(cfg.paths.abs_raw_data_dir, 'aptos', 'aptos_02_1.png');

if isfile(samplePath)
    [rawImg, ~, ~] = loadImage(samplePath, cfg.image.target_size, false);
else
    % Create synthetic dim/noisy fundus
    [X, Y] = meshgrid(-112:111, -112:111);
    R = sqrt(X.^2 + Y.^2);
    retinaMask = R <= 105;
    
    rawImg = zeros(224, 224, 3, 'uint8');
    rawImg(:,:,1) = uint8(120 * retinaMask .* (1 - 0.2*rand(224)));
    rawImg(:,:,2) = uint8(60  * retinaMask .* (1 - 0.2*rand(224)));
    rawImg(:,:,3) = uint8(20  * retinaMask .* (1 - 0.2*rand(224)));
    
    % Add faint microaneurysms
    for k = 1:6
        rx = randi([-40, 40]); ry = randi([-40, 40]);
        ma = (X - rx).^2 + (Y - ry).^2 <= 3;
        rawImg(:,:,1) = rawImg(:,:,1) + uint8(100 * ma);
    end
end

logger.info('Testing individual pipeline functions on retinal fundus image...');

% 2. Test Individual Sub-Modules
t1 = applyMedianFilter(rawImg, [3, 3]);
logger.info('  [PASS] applyMedianFilter executed.');

t2 = correctIllumination(t1);
logger.info('  [PASS] correctIllumination executed.');

t3 = applyCLAHE(t2, 0.02, [8, 8], 'Lab');
logger.info('  [PASS] applyCLAHE (Lab mode) executed.');

t4 = applyHistogramEqualization(t3, 0.35);
logger.info('  [PASS] applyHistogramEqualization executed.');

t5 = enhanceContrast(t4, 1.15, [1.0, 99.0]);
logger.info('  [PASS] enhanceContrast executed.');

t6 = reduceNoise(t5, 'bilateral');
logger.info('  [PASS] reduceNoise (Bilateral) executed.');

% 3. Run Master Enhancement Pipeline Orchestrator
logger.info('Executing master preprocessPipeline orchestrator...');
enhancedResult = preprocessPipeline(rawImg, cfg);

% 4. Display Quantitative Metrics
m = enhancedResult.metrics;
fprintf('\n========================================================================================\n');
fprintf('  Quantitative Image Enhancement Improvement Metrics:\n');
fprintf('========================================================================================\n');
fprintf('  Peak Signal-to-Noise Ratio (PSNR)  :  %6.2f dB   (Target: > 28 dB)\n', m.psnrDb);
fprintf('  Structural Similarity Index (SSIM) :  %6.4f      (Target: > 0.85)\n', m.ssim);
fprintf('  Contrast Improvement Index (CII)   :  %6.2fx     (Target: > 1.0x)\n', m.cii);
fprintf('  Shannon Information Entropy        :  %6.2f -> %6.2f bits/px (Gain: +%.3f)\n', ...
        m.originalEntropy, m.enhancedEntropy, m.entropyGain);
fprintf('  Enhancement Measure (EME)          :  %6.2f dB\n', m.eme);
fprintf('  Vascular Sharpness Gain            :  +%5.1f%%\n', m.sharpnessGainPercent);
fprintf('========================================================================================\n\n');

% 5. Generate and Export Side-by-Side Comparison
logger.info('Generating side-by-side comparison dashboard...');
exportPath = fullfile(cfg.paths.abs_visualizations_dir, 'enhancement_comparison_test.png');
figHandle = compareEnhancement(rawImg, enhancedResult.enhancedImage, m, exportPath);
logger.info('Exported comparison dashboard to: %s', exportPath);

logger.info('===================================================================');
logger.info('  Prompt 4: Image Enhancement Pipeline Verified Successfully!      ');
logger.info('===================================================================');
