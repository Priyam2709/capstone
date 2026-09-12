function [figHandle, distTable] = displayClassDistribution(datasetSplits, summaryInfo, savePath)
% DISPLAYCLASSDISTRIBUTION Displays and plots class distribution across dataset splits.
%
%   displayClassDistribution(datasetSplits)
%   displayClassDistribution(datasetSplits, summaryInfo)
%   [figHandle, distTable] = displayClassDistribution(datasetSplits, summaryInfo, savePath)
%
%   Inputs:
%       datasetSplits - Struct with .train, .val, .test tables from loadDataset().
%       summaryInfo   - (Optional) Summary info struct from loadDataset().
%       savePath      - (Optional) Path to save the distribution plot (.png).
%
%   Outputs:
%       figHandle     - Graphics handle to the generated figure.
%       distTable     - Formatted summary table of class counts and percentages.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    stageNames = {
        '0 - No DR', ...
        '1 - Mild NPDR', ...
        '2 - Moderate NPDR', ...
        '3 - Severe NPDR', ...
        '4 - Proliferative DR'
    };

    % Compute counts from tables if summaryInfo is missing
    trainCounts = zeros(5, 1);
    valCounts   = zeros(5, 1);
    testCounts  = zeros(5, 1);

    for c = 0:4
        trainCounts(c + 1) = sum(datasetSplits.train.Diagnosis == c);
        valCounts(c + 1)   = sum(datasetSplits.val.Diagnosis == c);
        testCounts(c + 1)  = sum(datasetSplits.test.Diagnosis == c);
    end

    totalPerClass = trainCounts + valCounts + testCounts;
    grandTotal = sum(totalPerClass);
    if grandTotal > 0
        percentages = (totalPerClass / grandTotal) * 100.0;
    else
        percentages = zeros(5, 1);
    end

    % 1. Command Window Formatted Table Output
    fprintf('\n========================================================================================\n');
    fprintf('  Class Distribution Analysis: Dataset [%s]\n', datasetSplits.datasetName);
    fprintf('========================================================================================\n');
    fprintf('  %-5s  %-24s  %6s  %6s  %6s  %6s  %8s\n', ...
            'Code', 'DR Clinical Stage', 'Train', 'Val', 'Test', 'Total', 'Share (%)');
    fprintf('  --------------------------------------------------------------------------------------\n');
    for c = 1:5
        fprintf('  [%d]    %-24s  %6d  %6d  %6d  %6d   %6.1f%%\n', ...
                c - 1, stageNames{c}, trainCounts(c), valCounts(c), ...
                testCounts(c), totalPerClass(c), percentages(c));
    end
    fprintf('  --------------------------------------------------------------------------------------\n');
    fprintf('  %-31s  %6d  %6d  %6d  %6d   %6.1f%%\n', ...
            'TOTAL SAMPLES', sum(trainCounts), sum(valCounts), ...
            sum(testCounts), grandTotal, 100.0);
    fprintf('========================================================================================\n\n');

    % 2. Assemble Table Struct
    distTable = table((0:4)', stageNames', trainCounts, valCounts, testCounts, ...
                      totalPerClass, round(percentages, 1), ...
                      'VariableNames', {'Code', 'StageName', 'Train', 'Val', 'Test', 'Total', 'Percentage'});

    % 3. Generate Grouped Bar Chart Figure
    figHandle = figure('Name', sprintf('Class Distribution - %s', datasetSplits.datasetName), ...
                       'NumberTitle', 'off', 'Position', [100, 100, 950, 480], ...
                       'Color', [1 1 1], 'Visible', 'off');

    splitMatrix = [trainCounts, valCounts, testCounts];
    b = bar(splitMatrix, 'grouped');
    
    % Professional color scheme
    b(1).FaceColor = [0.12, 0.47, 0.71]; % Train: Navy blue
    b(2).FaceColor = [0.18, 0.65, 0.38]; % Val: Emerald green
    b(3).FaceColor = [0.90, 0.55, 0.15]; % Test: Amber orange

    grid on;
    set(gca, 'XTick', 1:5, 'XTickLabel', stageNames, 'FontSize', 10);
    ylabel('Number of Retinal Fundus Images', 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('ICDR Diabetic Retinopathy Severity Scale', 'FontSize', 11, 'FontWeight', 'bold');
    title(sprintf('Stratified Class Distribution: %s Dataset (Total: %d Images)', ...
                  datasetSplits.datasetName, grandTotal), ...
          'FontSize', 13, 'FontWeight', 'bold');
    legend({'Train Set (70%)', 'Validation Set (15%)', 'Test Set (15%)'}, ...
           'Location', 'northeast', 'FontSize', 10);

    % Save plot if path provided or save to default visualizations directory
    if nargin < 3 || isempty(savePath)
        try
            projectRoot = getProjectRoot();
            savePath = fullfile(projectRoot, 'results', 'visualizations', ...
                                sprintf('class_distribution_%s.png', lower(datasetSplits.datasetName)));
        catch
            savePath = '';
        end
    end

    if ~isempty(savePath)
        saveOutput(figHandle, savePath, 'figure');
    end
end
