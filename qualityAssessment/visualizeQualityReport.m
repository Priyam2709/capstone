function figHandle = visualizeQualityReport(img, qualityReport, savePath)
% VISUALIZEQUALITYREPORT Generates diagnostic panel of IQA metrics and visual badges.
%
%   visualizeQualityReport(img, qualityReport)
%   figHandle = visualizeQualityReport(img, qualityReport, savePath)
%
%   Inputs:
%       img           - RGB retinal fundus image array.
%       qualityReport - Struct returned by assessImageQuality().
%       savePath      - (Optional) Destination path to save the diagnostic figure.
%
%   Outputs:
%       figHandle     - Graphics handle to the generated figure.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    figHandle = figure('Name', sprintf('Image Quality Assessment - [%s]', qualityReport.category), ...
                       'NumberTitle', 'off', 'Position', [80, 80, 1100, 560], ...
                       'Color', [0.98, 0.98, 0.99], 'Visible', 'off');

    % Set category badge colors
    switch qualityReport.category
        case 'Good'
            badgeColor = [0.10, 0.65, 0.35]; % Emerald Green
            statusIcon = '✓ GOOD QUALITY (APPROVED FOR AI)';
        case 'Needs Enhancement'
            badgeColor = [0.90, 0.60, 0.10]; % Amber / Orange
            statusIcon = '⚠ NEEDS ENHANCEMENT (AUTO-CLAHE)';
        otherwise
            badgeColor = [0.85, 0.20, 0.20]; % Crimson Red
            statusIcon = '✗ RETAKE IMAGE (QUALITY CRITICAL)';
    end

    % 1. Left Subplot: Retinal Fundus with Overlay Badge
    subplot('Position', [0.06, 0.18, 0.38, 0.70]);
    imshow(img);
    title(statusIcon, 'FontSize', 12, 'FontWeight', 'bold', 'Color', badgeColor);

    % Add Score Annotation on top of image
    scoreBoxStr = sprintf('Composite Score: %.1f / 100', qualityReport.overallScore);
    xlabel(scoreBoxStr, 'FontSize', 11, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);

    % 2. Right Top Subplot: Normalized Metric Sub-Scores (Bar Chart)
    subplot('Position', [0.52, 0.52, 0.44, 0.36]);
    metricLabels = {'Blur', 'Brightness', 'Contrast', 'Noise', 'Sharpness'};
    subVals = [qualityReport.subScores.blur, ...
               qualityReport.subScores.brightness, ...
               qualityReport.subScores.contrast, ...
               qualityReport.subScores.noise, ...
               qualityReport.subScores.sharpness];

    b = bar(subVals, 'FaceColor', 'flat');
    % Color individual bars based on thresholds
    for k = 1:numel(subVals)
        if subVals(k) >= 75
            b.CData(k, :) = [0.12, 0.65, 0.35]; % Green
        elseif subVals(k) >= 50
            b.CData(k, :) = [0.90, 0.60, 0.12]; % Amber
        else
            b.CData(k, :) = [0.85, 0.22, 0.22]; % Red
        end
    end

    ylim([0 115]);
    set(gca, 'XTickLabel', metricLabels, 'FontSize', 10, 'FontWeight', 'bold');
    ylabel('Calibrated Score (0 - 100)', 'FontSize', 10);
    title('Diagnostic Quality Metric Sub-Scores', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;

    % Threshold guide lines
    yline(75, 'g--', 'Good Quality (>=75)', 'LineWidth', 1.2, 'FontSize', 9);
    yline(50, 'r--', 'Retake Limit (<50)', 'LineWidth', 1.2, 'FontSize', 9);

    % Add value text on top of bars
    for k = 1:numel(subVals)
        text(k, subVals(k) + 4, sprintf('%.1f', subVals(k)), ...
             'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
    end

    % 3. Right Bottom Subplot: Detailed Raw Clinical Metrics Table
    m = qualityReport.metrics;
    rawDetailsStr = sprintf([...
        'Raw Metrics:  Blur: %.1f | Lum: %.1f | RMS Cont: %.1f | Noise Std: %.1f | SNR: %.1f dB | Tenengrad: %.1f\n' ...
        'Exposure:     Underexposed: %.1f%%  |  Glare / Overexposed: %.1f%%  |  Uniformity: %.2f'], ...
        m.blur, m.brightness, m.contrast, m.noise, m.snrDb, m.sharpness, ...
        qualityReport.exposureDefects.underexposedPercent, ...
        qualityReport.exposureDefects.overexposedPercent, m.uniformity);

    annotation('textbox', [0.52, 0.31, 0.44, 0.14], ...
               'String', rawDetailsStr, 'FontSize', 9, ...
               'BackgroundColor', [0.95 0.96 0.98], 'EdgeColor', [0.8 0.85 0.9]);

    % 4. Bottom Clinical Guidance Card
    recBannerStr = sprintf('CLINICAL GUIDANCE: %s', qualityReport.recommendation);
    annotation('textbox', [0.06, 0.04, 0.90, 0.09], ...
               'String', recBannerStr, 'FontSize', 10, 'FontWeight', 'bold', ...
               'ForegroundColor', badgeColor, ...
               'BackgroundColor', [1 1 1], 'EdgeColor', badgeColor, 'LineWidth', 1.5);

    % Super Title
    sgtitle('SIH26038: Automated Retinal Image Quality Assessment (IQA)', ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.05 0.15 0.35]);

    % Save output if path specified
    if nargin >= 3 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
