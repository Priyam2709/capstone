function figHandle = visualizePredictionCard(imgOrPath, predictionResult, savePath)
% VISUALIZEPREDICTIONCARD Generates a visual diagnostic card of deep learning inference.
%
%   visualizePredictionCard(imgOrPath, predictionResult)
%   figHandle = visualizePredictionCard(imgOrPath, predictionResult, savePath)
%
%   Displays:
%       - Retinal fundus image with predicted stage badge
%       - 5-class softmax probability horizontal bar chart
%       - Referral triage urgency badge (Green for Routine, Red for Urgent Referral)
%       - Plain-language action protocol for field health workers
%       - Latency & model architecture metadata
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if ischar(imgOrPath) || isstring(imgOrPath)
        try
            img = imread(char(imgOrPath));
        catch
            img = zeros(224, 224, 3, 'uint8');
        end
    else
        img = imgOrPath;
    end

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    figHandle = figure('Name', sprintf('DR Diagnostic Prediction - %s', predictionResult.stageName), ...
                       'NumberTitle', 'off', 'Position', [80, 80, 1050, 560], ...
                       'Color', [0.98, 0.98, 0.99], 'Visible', 'off');

    % Set stage colors
    stageColors = [
        0.12, 0.65, 0.35;  % 0: Green (No DR)
        0.20, 0.55, 0.85;  % 1: Blue (Mild)
        0.90, 0.60, 0.15;  % 2: Amber (Moderate)
        0.85, 0.30, 0.15;  % 3: Orange-Red (Severe)
        0.80, 0.10, 0.15   % 4: Crimson (PDR)
    ];

    pColor = stageColors(max(1, min(5, predictionResult.stageCode + 1)), :);

    % 1. Left Panel: Retinal Image with Stage Overlay
    subplot('Position', [0.06, 0.20, 0.38, 0.68]);
    imshow(imgUint8);
    title(sprintf('%s (%.1f%%)', predictionResult.stageName, predictionResult.confidencePercent), ...
          'FontSize', 12, 'FontWeight', 'bold', 'Color', pColor);
    xlabel(sprintf('Inference Latency: %.1f ms (%s)', ...
                   predictionResult.inferenceLatencyMs, upper(predictionResult.modelArchitecture)), ...
           'FontSize', 10, 'FontWeight', 'bold', 'Color', [0.3 0.3 0.3]);

    % 2. Right Top Panel: 5-Class Probability Distribution
    subplot('Position', [0.52, 0.52, 0.44, 0.36]);
    probVals = predictionResult.classProbabilities * 100.0;
    classLabels = {'0 - No DR', '1 - Mild', '2 - Moderate', '3 - Severe', '4 - PDR'};

    b = barh(1:5, probVals, 'FaceColor', 'flat');
    for k = 1:5
        b.CData(k, :) = stageColors(k, :);
    end

    set(gca, 'YTick', 1:5, 'YTickLabel', classLabels, ...
             'YDir', 'reverse', 'FontSize', 10, 'FontWeight', 'bold');
    xlim([0 105]);
    xlabel('Softmax Probability (%)', 'FontSize', 10);
    title('Class Probability Distribution', 'FontSize', 12, 'FontWeight', 'bold');
    grid on;

    % Value text labels on horizontal bars
    for k = 1:5
        text(probVals(k) + 2, k, sprintf('%.1f%%', probVals(k)), ...
             'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 9);
    end

    % 3. Right Bottom Panel: Triage & Referral Card
    if predictionResult.referralRequired
        triageBg = [0.99, 0.94, 0.94];
        triageBorder = [0.85, 0.20, 0.20];
        refIcon = 'REFERRAL REQUIRED: YES (Sight-Threatening DR Detected)';
    else
        triageBg = [0.94, 0.99, 0.95];
        triageBorder = [0.12, 0.65, 0.35];
        refIcon = 'REFERRAL NOT REQUIRED: Routine Local Follow-Up';
    end

    triageText = sprintf([...
        '%s\n\n' ...
        'URGENCY: %s\n' ...
        'ACTION PROTOCOL: %s'], ...
        refIcon, predictionResult.urgency, predictionResult.actionProtocol);

    annotation('textbox', [0.52, 0.20, 0.44, 0.27], ...
               'String', triageText, 'FontSize', 9.5, 'FontWeight', 'bold', ...
               'ForegroundColor', triageBorder, ...
               'BackgroundColor', triageBg, 'EdgeColor', triageBorder, 'LineWidth', 1.5);

    % 4. Bottom Description Banner
    descBanner = sprintf('CLINICAL PATHOLOGY: %s', predictionResult.stageDescription);
    annotation('textbox', [0.06, 0.04, 0.90, 0.10], ...
               'String', descBanner, 'FontSize', 9, ...
               'BackgroundColor', [1 1 1], 'EdgeColor', [0.8 0.8 0.8]);

    % Super Title
    sgtitle('SIH26038: Automated Diabetic Retinopathy Diagnostic Card', ...
            'FontSize', 14, 'FontWeight', 'bold', 'Color', [0.05 0.15 0.35]);

    if nargin >= 3 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
