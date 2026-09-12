function figHandle = plotConfusionMatrix(cm, classNames, savePath)
% PLOTCONFUSIONMATRIX Generates publication-quality 5x5 confusion matrix heatmap.
%
%   figHandle = plotConfusionMatrix(cm)
%   figHandle = plotConfusionMatrix(cm, classNames)
%   figHandle = plotConfusionMatrix(cm, classNames, savePath)
%
%   Inputs:
%       cm         - 5x5 integer confusion matrix.
%       classNames - (Optional) Cell array of 5 stage names.
%       savePath   - (Optional) Export path for graphic file.
%
%   Outputs:
%       figHandle  - Figure graphics handle.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(classNames)
        classNames = { ...
            '0 - No DR', '1 - Mild NPDR', '2 - Moderate NPDR', ...
            '3 - Severe NPDR', '4 - Proliferative DR' ...
        };
    end

    numClasses = size(cm, 1);
    totalSamples = sum(cm(:));
    overallAcc = sum(diag(cm)) / max(1, totalSamples);

    figHandle = figure('Name', 'Confusion Matrix - Retinal DR Classification', ...
                       'NumberTitle', 'off', 'Position', [100, 100, 750, 620], ...
                       'Color', [1 1 1], 'Visible', 'off');

    % Normalized matrix for color intensity (row-normalized by true class)
    cmNorm = zeros(size(cm));
    for r = 1:numClasses
        rowTotal = sum(cm(r, :));
        if rowTotal > 0
            cmNorm(r, :) = cm(r, :) / rowTotal;
        end
    end

    % Render heatmap image
    imagesc(cmNorm);
    colormap(flipud(summer)); % Clean blue-green gradient
    caxis([0 1]);
    colorbar;

    % Axis settings
    set(gca, 'XTick', 1:numClasses, 'XTickLabel', classNames, ...
             'YTick', 1:numClasses, 'YTickLabel', classNames, ...
             'FontSize', 10, 'FontWeight', 'bold');
    xtickangle(30);

    xlabel('Predicted DR Stage', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Ground Truth (True Stage)', 'FontSize', 12, 'FontWeight', 'bold');
    title(sprintf('SIH26038: 5-Stage Confusion Matrix (Overall Accuracy: %.2f%% | N=%d)', ...
                  overallAcc * 100, totalSamples), ...
          'FontSize', 13, 'FontWeight', 'bold');

    % Overlay text labels (Count & Percentage) inside each cell
    for r = 1:numClasses
        for c = 1:numClasses
            val = cm(r, c);
            pct = cmNorm(r, c) * 100.0;
            
            % Choose high contrast text color
            if cmNorm(r, c) > 0.55
                txtColor = [1 1 1]; % White
            else
                txtColor = [0 0 0]; % Black
            end
            
            str = sprintf('%d\n(%.1f%%)', val, pct);
            text(c, r, str, 'HorizontalAlignment', 'center', ...
                 'VerticalAlignment', 'middle', 'FontSize', 9, ...
                 'FontWeight', 'bold', 'Color', txtColor);
        end
    end

    grid on;

    if nargin >= 3 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
