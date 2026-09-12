function figHandle = plotROCCurves(metrics, savePath)
% PLOTROCCURVES Generates multi-class One-vs-Rest ROC curves for 5 DR stages.
%
%   figHandle = plotROCCurves(metrics)
%   figHandle = plotROCCurves(metrics, savePath)
%
%   Inputs:
%       metrics  - Performance struct returned by evaluateMetrics().
%       savePath - (Optional) Export path for graphic file.
%
%   Outputs:
%       figHandle - Figure graphics handle.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    figHandle = figure('Name', 'Multi-Class ROC Curves - Retinal DR Classification', ...
                       'NumberTitle', 'off', 'Position', [100, 100, 800, 620], ...
                       'Color', [1 1 1], 'Visible', 'off');

    colors = [
        0.12, 0.47, 0.71;  % Stage 0: Deep Blue
        0.18, 0.65, 0.38;  % Stage 1: Emerald Green
        0.90, 0.55, 0.15;  % Stage 2: Amber Orange
        0.80, 0.20, 0.20;  % Stage 3: Crimson Red
        0.55, 0.18, 0.65   % Stage 4: Royal Purple
    ];

    lineStyles = {'-', '-', '-', '-', '-'};

    hold on;
    legendEntries = {};

    % Plot individual class ROC curves
    for k = 1:numel(metrics.classNames)
        roc = metrics.rocData{k};
        plot(roc.fpr, roc.tpr, 'Color', colors(k, :), 'LineStyle', lineStyles{k}, ...
             'LineWidth', 2.2);
        
        legendEntries{end+1} = sprintf('%s (AUC = %.3f)', metrics.classNames{k}, roc.auc); %#ok<AGROW>
    end

    % Diagonal random chance reference line
    plot([0, 1], [0, 1], 'k--', 'LineWidth', 1.2);
    legendEntries{end+1} = 'Random Classifier (AUC = 0.500)';

    xlim([0.0, 1.0]);
    ylim([0.0, 1.02]);
    grid on;

    xlabel('False Positive Rate (1 - Specificity)', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('True Positive Rate (Sensitivity / Recall)', 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('SIH26038: Multi-Class ROC Curves (Macro-Average AUC = %.3f)', metrics.auc), ...
          'FontSize', 13, 'FontWeight', 'bold');
    legend(legendEntries, 'Location', 'southeast', 'FontSize', 10);

    if nargin >= 2 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
