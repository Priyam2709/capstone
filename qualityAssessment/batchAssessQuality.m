function [resultsTable, batchSummary] = batchAssessQuality(imageSources, config, exportCsvPath)
% BATCHASSESSQUALITY Evaluates Image Quality Assessment across multiple fundus images.
%
%   resultsTable = batchAssessQuality(imageSources)
%   [resultsTable, batchSummary] = batchAssessQuality(imageSources, config)
%   [resultsTable, batchSummary] = batchAssessQuality(imageSources, config, exportCsvPath)
%
%   Inputs:
%       imageSources  - Can be:
%                       - Directory path string containing retinal images
%                       - Cell array of image file paths
%                       - Table with an 'ImagePath' column
%       config        - (Optional) Configuration struct from loadConfig().
%       exportCsvPath - (Optional) Destination CSV file path for batch records.
%
%   Outputs:
%       resultsTable  - Table with columns:
%           [FileName, Category, OverallScore, Blur, Brightness, Contrast, Noise, Sharpness, IsAcceptable, Recommendation]
%       batchSummary  - Struct with aggregate metrics:
%           .totalImages, .goodCount, .needsEnhancementCount, .retakeCount,
%           .passRatePercent, .averageOverallScore
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(config)
        try
            config = loadConfig();
        catch
            config = [];
        end
    end

    % 1. Parse Image Sources
    fileList = {};
    if ischar(imageSources) || isstring(imageSources)
        srcStr = char(imageSources);
        if isfolder(srcStr)
            % Directory provided
            imgExts = {'*.png', '*.jpg', '*.jpeg', '*.tif', '*.tiff', '*.bmp'};
            for e = 1:numel(imgExts)
                d = dir(fullfile(srcStr, imgExts{e}));
                for k = 1:numel(d)
                    fileList{end+1} = fullfile(d(k).folder, d(k).name); %#ok<AGROW>
                end
            end
        elseif isfile(srcStr)
            fileList = {srcStr};
        else
            error('SIH26038:InvalidPath', 'Provided path is neither a folder nor a file: %s', srcStr);
        end
    elseif iscell(imageSources)
        fileList = imageSources;
    elseif istable(imageSources) && any(strcmpi(imageSources.Properties.VariableNames, 'ImagePath'))
        fileList = cellstr(imageSources.ImagePath);
    else
        error('SIH26038:InvalidInput', 'Unsupported imageSources input type.');
    end

    totalImages = numel(fileList);
    if totalImages == 0
        error('SIH26038:NoImagesFound', 'No images found in the specified source.');
    end

    try
        logger.info('Starting batch IQA for %d images...', totalImages);
    catch
    end

    % 2. Initialize Output Columns
    fileNames    = cell(totalImages, 1);
    categories   = cell(totalImages, 1);
    scores       = zeros(totalImages, 1);
    blurs        = zeros(totalImages, 1);
    brightnesses = zeros(totalImages, 1);
    contrasts    = zeros(totalImages, 1);
    noises       = zeros(totalImages, 1);
    sharpnesses  = zeros(totalImages, 1);
    acceptables  = false(totalImages, 1);
    recs         = cell(totalImages, 1);

    % 3. Process every image
    for i = 1:totalImages
        imgPath = fileList{i};
        [~, fname, fext] = fileparts(imgPath);
        fileNames{i} = [fname, fext];

        try
            img = imread(imgPath);
            qRep = assessImageQuality(img, config);

            categories{i}   = qRep.category;
            scores{i}       = qRep.overallScore;
            blurs{i}        = qRep.metrics.blur;
            brightnesses{i} = qRep.metrics.brightness;
            contrasts{i}    = qRep.metrics.contrast;
            noises{i}       = qRep.metrics.noise;
            sharpnesses{i}  = qRep.metrics.sharpness;
            acceptables{i}  = qRep.isAcceptable;
            recs{i}         = qRep.recommendation;
        catch ME
            categories{i}   = 'Error';
            scores{i}       = 0.0;
            acceptables{i}  = false;
            recs{i}         = sprintf('Assessment failed: %s', ME.message);
        end
    end

    % 4. Assemble Results Table
    resultsTable = table(fileNames, categories, scores, blurs, brightnesses, ...
                         contrasts, noises, sharpnesses, acceptables, recs, ...
                         'VariableNames', {'FileName', 'Category', 'OverallScore', ...
                                           'Blur', 'Brightness', 'Contrast', ...
                                           'Noise', 'Sharpness', 'IsAcceptable', 'Recommendation'});

    % 5. Aggregate Statistics
    goodCount   = sum(strcmp(categories, 'Good'));
    enhanceCount = sum(strcmp(categories, 'Needs Enhancement'));
    retakeCount = sum(strcmp(categories, 'Retake Image') | strcmp(categories, 'Error'));
    avgScore    = mean(scores);
    passRate    = ((goodCount + enhanceCount) / totalImages) * 100.0;

    batchSummary = struct();
    batchSummary.totalImages = totalImages;
    batchSummary.goodCount = goodCount;
    batchSummary.needsEnhancementCount = enhanceCount;
    batchSummary.retakeCount = retakeCount;
    batchSummary.passRatePercent = round(passRate, 1);
    batchSummary.averageOverallScore = round(avgScore, 1);

    % 6. Export to CSV if requested
    if nargin >= 3 && ~isempty(exportCsvPath)
        try
            writetable(resultsTable, exportCsvPath);
            try
                logger.info('Batch IQA records saved to: %s', exportCsvPath);
            catch
            end
        catch ME
            warning('Could not export CSV to %s: %s', exportCsvPath, ME.message);
        end
    end
end
