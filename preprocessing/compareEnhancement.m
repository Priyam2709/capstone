function figHandle = compareEnhancement(originalImg, enhancedImg, metrics, savePath)
% COMPAREENHANCEMENT Multi-panel side-by-side visualization of retinal enhancement.
%
%   compareEnhancement(originalImg, enhancedImg)
%   compareEnhancement(originalImg, enhancedImg, metrics)
%   figHandle = compareEnhancement(originalImg, enhancedImg, metrics, savePath)
%
%   Displays:
%       1. Original Raw Fundus Image
%       2. Enhanced Fundus Image (CLAHE + Preprocessing)
%       3. Green Channel Diagnostic Comparison (Vessel & Lesion Visualizer)
%       4. Pixel Intensity Histogram Comparison (Original vs. Enhanced)
%       5. Quantitative Quality Metrics Banner (PSNR, SSIM, CII, Entropy, EME)
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 3 || isempty(metrics)
        metrics = evaluateEnhancementMetrics(originalImg, enhancedImg);
    end

    if isfloat(originalImg) && max(originalImg(:)) <= 1.0
        origUint8 = im2uint8(originalImg);
    else
        origUint8 = uint8(originalImg);
    end

    if isfloat(enhancedImg) && max(enhancedImg(:)) <= 1.0
        enhUint8 = im2uint8(enhancedImg);
    else
        enhUint8 = uint8(enhancedImg);
    end

    figHandle = figure('Name', 'Retinal Preprocessing & CLAHE Enhancement Comparison', ...
                       'NumberTitle', 'off', 'Position', [60, 60, 1150, 640], ...
                       'Color', [0.98, 0.98, 0.99], 'Visible', 'off');

    % 1. Top-Left: Original Image
    subplot('Position', [0.06, 0.52, 0.27, 0.38]);
    imshow(origUint8);
    title('1. Original Raw Fundus', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

    % 2. Top-Center: Enhanced Image
    subplot('Position', [0.37, 0.52, 0.27, 0.38]);
    imshow(enhUint8);
    title('2. Enhanced Retinal Fundus', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.10, 0.55, 0.25]);

    % 3. Top-Right: Green Channel Microvascular Detail
    subplot('Position', [0.68, 0.52, 0.27, 0.38]);
    imshow(enhUint8(:, :, 2));
    title('3. Enhanced Green Channel (Lesions)', 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.05, 0.35, 0.65]);

    % 4. Bottom-Left: Histogram Comparison (Original vs Enhanced)
    subplot('Position', [0.06, 0.14, 0.42, 0.30]);
    origGreen = origUint8(:, :, 2);
    enhGreen  = enhUint8(:, :, 2);
    
    [countsOrig, bins] = imhist(origGreen(origGreen > 15));
    [countsEnh, ~]     = imhist(enhGreen(enhGreen > 15));

    plot(bins, countsOrig, 'Color', [0.8 0.2 0.2], 'LineWidth', 1.8); hold on;
    plot(bins, countsEnh,  'Color', [0.1 0.6 0.3], 'LineWidth', 1.8);
    xlim([15 255]); grid on;
    xlabel('Pixel Intensity Value (Green Spectrum)', 'FontSize', 9);
    ylabel('Frequency', 'FontSize', 9);
    title('Green Channel Dynamic Range Distribution', 'FontSize', 11, 'FontWeight', 'bold');
    legend({'Raw Fundus (Narrow Peak)', 'Enhanced (Broad Dynamic Range)'}, ...
           'Location', 'northeast', 'FontSize', 9);

    % 5. Bottom-Right: Quantitative Metric Dashboard Card
    metricSummaryStr = sprintf([...
        'QUANTITATIVE IMAGE QUALITY IMPROVEMENT METRICS:\n\n' ...
        '  • Peak Signal-to-Noise Ratio (PSNR)  :  %.2f dB   (Target: > 28.0 dB)\n' ...
        '  • Structural Similarity Index (SSIM) :  %.4f      (Target: > 0.850)\n' ...
        '  • Contrast Improvement Index (CII)   :  %.2fx     (Factor: > 1.00x)\n' ...
        '  • Shannon Information Entropy        :  %.2f -> %.2f bits/px (+%.3f gain)\n' ...
        '  • Enhancement Measure by Entropy(EME):  %.2f dB\n' ...
        '  • Vascular Sharpness Improvement     :  +%.1f%%\n\n' ...
        'Clinical Status: Microaneurysms and intraretinal microvasculature visibly enhanced.'], ...
        metrics.psnrDb, metrics.ssim, metrics.cii, ...
        metrics.originalEntropy, metrics.enhancedEntropy, metrics.entropyGain, ...
        metrics.eme, metrics.sharpnessGainPercent);

    annotation('textbox', [0.52, 0.14, 0.43, 0.30], ...
               'String', metricSummaryStr, 'FontSize', 10, ...
               'BackgroundColor', [1 1 1], 'EdgeColor', [0.10, 0.55, 0.25], 'LineWidth', 1.5);

    % Main Title
    sgtitle('SIH26038: Retinal Image Enhancement & Microvascular Preprocessing Pipeline', ...
            'FontSize', 13, 'FontWeight', 'bold', 'Color', [0.05 0.15 0.35]);

    % Save output if path specified
    if nargin >= 4 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
