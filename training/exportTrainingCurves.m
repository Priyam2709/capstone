function figHandle = exportTrainingCurves(trainRecord, savePath)
% EXPORTTRAININGCURVES Plots and exports training & validation loss and accuracy curves.
%
%   figHandle = exportTrainingCurves(trainRecord)
%   figHandle = exportTrainingCurves(trainRecord, savePath)
%
%   Inputs:
%       trainRecord - Struct containing:
%           .epochs, .trainLoss, .valLoss, .trainAccuracy, .valAccuracy, .bestEpoch, .architecture
%       savePath    - (Optional) Path to export the figure (.png).
%
%   Outputs:
%       figHandle   - Figure graphics handle.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    figHandle = figure('Name', sprintf('Training Curves - %s', trainRecord.architecture), ...
                       'NumberTitle', 'off', 'Position', [80, 80, 1050, 480], ...
                       'Color', [1 1 1], 'Visible', 'off');

    epochs = trainRecord.epochs;
    bestEp = trainRecord.bestEpoch;

    % Subplot 1: Cross-Entropy Loss
    subplot(1, 2, 1);
    plot(epochs, trainRecord.trainLoss, 'b-', 'LineWidth', 2.0); hold on;
    plot(epochs, trainRecord.valLoss, 'r--', 'LineWidth', 2.0);
    
    % Mark best epoch
    plot(bestEp, trainRecord.valLoss(bestEp), 'p', ...
         'MarkerSize', 12, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k');
    
    xlabel('Epoch', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Cross-Entropy Loss', 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('Loss Convergence (%s)', upper(trainRecord.architecture)), ...
          'FontSize', 12, 'FontWeight', 'bold');
    legend({'Training Loss', 'Validation Loss', sprintf('Best Epoch (%d)', bestEp)}, ...
           'Location', 'northeast', 'FontSize', 9);
    grid on;

    % Subplot 2: Classification Accuracy
    subplot(1, 2, 2);
    plot(epochs, trainRecord.trainAccuracy, 'b-', 'LineWidth', 2.0); hold on;
    plot(epochs, trainRecord.valAccuracy, 'r--', 'LineWidth', 2.0);

    % Mark best epoch
    plot(bestEp, trainRecord.valAccuracy(bestEp), 'p', ...
         'MarkerSize', 12, 'MarkerFaceColor', 'g', 'MarkerEdgeColor', 'k');

    xlabel('Epoch', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('Classification Accuracy (%)', 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('Accuracy Convergence (Best Val: %.1f%%)', trainRecord.bestValAccuracy), ...
          'FontSize', 12, 'FontWeight', 'bold');
    legend({'Training Accuracy', 'Validation Accuracy', sprintf('Best Epoch (%d)', bestEp)}, ...
           'Location', 'southeast', 'FontSize', 9);
    grid on;

    sgtitle(sprintf('SIH26038: Transfer Learning Training Convergence [%s Backbone]', ...
                    upper(trainRecord.architecture)), ...
            'FontSize', 14, 'FontWeight', 'bold');

    if nargin >= 2 && ~isempty(savePath)
        try
            saveOutput(figHandle, savePath, 'figure');
        catch
            saveas(figHandle, savePath);
        end
    end
end
