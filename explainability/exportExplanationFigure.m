function figHandle = exportExplanationFigure(rawOrEnhancedImg, xaiResult, savePath)
% EXPORTEXPLANATIONFIGURE Exports comprehensive 4-panel Explainable AI diagnostic graphic.
%
%   exportExplanationFigure(rawOrEnhancedImg, xaiResult)
%   figHandle = exportExplanationFigure(rawOrEnhancedImg, xaiResult, savePath)
%
%   Panels:
%       1. Enhanced Retinal Fundus with Highlighted Lesion Bounding Boxes
%       2. Continuous Grad-CAM Activation Heatmap with Colorbar
%       3. Saliency Heatmap Overlay Blended onto Fundus
%       4. Clinical Narrative Explanation Card with Referral Urgency
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if isfloat(rawOrEnhancedImg) && max(rawOrEnhancedImg(:)) <= 1.0
        imgUint8 = im2uint8(rawOrEnhancedImg);
    else
        imgUint8 = uint8(rawOrEnhancedImg);
    end

    figHandle = figure('Name', sprintf('Explainable AI Diagnostic Report - %s', xaiResult.stageName), ...
                       'NumberTitle', 'off', 'Position', [50, 50, 1150, 680], ...
                       'Color', [0.98, 0.98, 0.99], 'Visible', 'off');

    % 1. Panel 1: Annotated Fundus with Highlighted Lesions
    subplot('Position', [0.05, 0.52, 0.28, 0.38]);
    imshow(xaiResult.annotatedImage);
    title('1. Highlighted Lesions (Bounding Boxes)', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0.1 0.1 0.1]);
    xlabel(sprintf('%d focal hotspot(s) detected', xaiResult.lesionStats.numClusters), ...
           'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.15 0.55 0.25]);

    % 2. Panel 2: Continuous 2D Grad-CAM Heatmap
    subplot('Position', [0.37, 0.52, 0.28, 0.38]);
    imagesc(xaiResult.heatmap);
    colormap(jet);
    caxis([0 1]);
    colorbar('Location', 'eastoutside');
    axis image off;
    title('2. Grad-CAM Activation Saliency', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0.05 0.35 0.65]);
    xlabel('Feature Intensity: [0 (Low) to 1 (High Attention)]', 'FontSize', 8.5);

    % 3. Panel 3: Saliency Heatmap Overlay Blended onto Fundus
    subplot('Position', [0.69, 0.52, 0.28, 0.38]);
    imshow(xaiResult.overlayImage);
    title('3. Heatmap Overlay Blended Fundus', 'FontSize', 10.5, 'FontWeight', 'bold', 'Color', [0.65 0.15 0.15]);
    xlabel(sprintf('Coverage: %.1f%% of Retinal Field', xaiResult.lesionStats.coveragePercent), ...
           'FontSize', 9, 'FontWeight', 'bold', 'Color', [0.65 0.15 0.15]);

    % 4. Panel 4: Clinical Narrative Explanation Card
    exp = xaiResult.clinicalExplanation;
    
    stageColors = [
        0.10, 0.60, 0.30;  % 0: Green
        0.15, 0.50, 0.80;  % 1: Blue
        0.85, 0.55, 0.10;  % 2: Amber
        0.85, 0.25, 0.10;  % 3: Orange-Red
        0.80, 0.10, 0.15   % 4: Crimson
    ];
    badgeColor = stageColors(max(1, min(5, xaiResult.targetClass + 1)), :);

    narrativeCardText = sprintf([...
        'DIAGNOSTIC CLASSIFICATION: %s   (CONFIDENCE: %.1f%%)\n\n' ...
        'ANATOMICAL LOCALIZATION:\n' ...
        '  • Primary Saliency Focus :  %s\n' ...
        '  • Retinal Lesion Coverage:  %.1f%% of total fundus area (%d focal cluster/s)\n' ...
        '  • Key Lesion Biomarkers  :  %s\n\n' ...
        'CLINICAL JUSTIFICATION FOR FIELD OPERATOR:\n%s\n\n' ...
        'TELE-OPHTHALMOLOGY REFERRAL GUIDANCE:\n%s'], ...
        upper(xaiResult.stageName), xaiResult.confidencePercent, ...
        exp.dominantQuadrant, exp.coveragePercent, xaiResult.lesionStats.numClusters, ...
        exp.lesionTypes, exp.summaryText, exp.referralUrgency);

    annotation('textbox', [0.05, 0.08, 0.90, 0.38], ...
               'String', narrativeCardText, 'FontSize', 9.5, ...
               'BackgroundColor', [1 1 1], 'EdgeColor', badgeColor, 'LineWidth', 1.6);

    % Main Title
    sgtitle('SIH26038: Explainable AI (Grad-CAM) Diagnostic Lesion Analysis', ...
            'FontSize', 13, 'FontWeight', 'bold', 'Color', [0.05 0.15 0.35]);

    % Save output if path specified
    if nargin >= 3 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
