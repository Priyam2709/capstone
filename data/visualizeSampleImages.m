function [figHandle, sampleImages] = visualizeSampleImages(datasetSplitsOrTable, targetSize, savePath)
% VISUALIZESAMPLEIMAGES Displays sample retinal images for each of the 5 DR classes.
%
%   visualizeSampleImages(datasetSplitsOrTable)
%   visualizeSampleImages(datasetSplitsOrTable, targetSize)
%   [figHandle, sampleImages] = visualizeSampleImages(datasetSplitsOrTable, targetSize, savePath)
%
%   Inputs:
%       datasetSplitsOrTable - Struct from loadDataset() or a table with ImagePath & Diagnosis.
%       targetSize           - (Optional) [Height, Width] or [H, W, C]. Default: [224, 224].
%       savePath             - (Optional) Filepath to export the montage image (.png).
%
%   Outputs:
%       figHandle            - Figure handle.
%       sampleImages         - 1x5 cell array of loaded sample images.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    % Extract data table
    if isstruct(datasetSplitsOrTable) && isfield(datasetSplitsOrTable, 'train')
        dataTable = [datasetSplitsOrTable.train; datasetSplitsOrTable.val; datasetSplitsOrTable.test];
        datasetName = datasetSplitsOrTable.datasetName;
    elseif istable(datasetSplitsOrTable)
        dataTable = datasetSplitsOrTable;
        datasetName = 'Custom';
    else
        error('SIH26038:InvalidInput', 'Input must be a datasetSplits struct or a valid table.');
    end

    if nargin < 2 || isempty(targetSize)
        targetSize = [224, 224];
    elseif numel(targetSize) == 3
        targetSize = targetSize(1:2);
    end

    stageNames = {
        'Stage 0: No DR', ...
        'Stage 1: Mild NPDR', ...
        'Stage 2: Moderate NPDR', ...
        'Stage 3: Severe NPDR', ...
        'Stage 4: Proliferative DR'
    };

    stageDescriptions = {
        'Normal retina, clear macula', ...
        'Microaneurysms only', ...
        'Hemorrhages & hard exudates', ...
        'Quadrant hemorrhages / IRMA', ...
        'Neovascularization / vit. hem.'
    };

    figHandle = figure('Name', sprintf('Sample Fundus Images - %s', datasetName), ...
                       'NumberTitle', 'off', 'Position', [50, 100, 1300, 360], ...
                       'Color', [1 1 1], 'Visible', 'off');

    sampleImages = cell(1, 5);

    % Find one representative sample per class
    for c = 0:4
        cRows = find(dataTable.Diagnosis == c);
        
        subplot(1, 5, c + 1);
        if ~isempty(cRows)
            chosenIdx = cRows(1); % First sample
            imgPath = char(dataTable.ImagePath(chosenIdx));
            imgId = char(string(dataTable.ImageId(chosenIdx)));

            try
                [procImg, ~, meta] = loadImage(imgPath, targetSize, false);
                imshow(procImg);
                sampleImages{c + 1} = procImg;
                
                titleStr = sprintf('%s\n[%s]\n(%dx%d)', ...
                                   stageNames{c + 1}, imgId, ...
                                   meta.processedHeight, meta.processedWidth);
                title(titleStr, 'FontSize', 9, 'FontWeight', 'bold');
                xlabel(stageDescriptions{c + 1}, 'FontSize', 8, 'Color', [0.3 0.3 0.3]);
            catch ME
                % If image load fails, display placeholder
                text(0.5, 0.5, sprintf('Image Load Error\n%s', ME.message), ...
                     'HorizontalAlignment', 'center', 'Color', 'red');
                title(stageNames{c + 1}, 'FontSize', 9);
            end
        else
            text(0.5, 0.5, 'No Samples Available', ...
                 'HorizontalAlignment', 'center', 'Color', [0.5 0.5 0.5]);
            title(stageNames{c + 1}, 'FontSize', 9);
        end
        axis off;
    end

    % Main super title
    sgtitle(sprintf('SIH26038: Representative Fundus Samples per DR Stage [%s Dataset | Target Size: %dx%d]', ...
                    datasetName, targetSize(1), targetSize(2)), ...
            'FontSize', 12, 'FontWeight', 'bold');

    % Save figure
    if nargin < 3 || isempty(savePath)
        try
            projectRoot = getProjectRoot();
            savePath = fullfile(projectRoot, 'results', 'visualizations', ...
                                sprintf('sample_images_%s.png', lower(datasetName)));
        catch
            savePath = '';
        end
    end

    if ~isempty(savePath)
        saveOutput(figHandle, savePath, 'figure');
    end
end
