function [resultsTable, cohortSummary] = batchPredictDR(imageSources, config, exportCsvPath)
% BATCHPREDICTDR Executes deep learning inference over a batch of fundus images.
%
%   resultsTable = batchPredictDR(imageSources)
%   [resultsTable, cohortSummary] = batchPredictDR(imageSources, config)
%   [resultsTable, cohortSummary] = batchPredictDR(imageSources, config, exportCsvPath)
%
%   Inputs:
%       imageSources  - Folder path, cell array of image paths, or table with ImagePath.
%       config        - (Optional) System configuration struct.
%       exportCsvPath - (Optional) Destination CSV file path for batch records.
%
%   Outputs:
%       resultsTable  - Formatted table of diagnostic predictions across all images.
%       cohortSummary - Struct of aggregate statistics:
%           .totalScreened, .referralCount, .referralRatePercent, .averageLatencyMs,
%           .stageCounts (1x5)
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

    % 1. Extract File List
    fileList = {};
    if ischar(imageSources) || isstring(imageSources)
        srcStr = char(imageSources);
        if isfolder(srcStr)
            imgExts = {'*.png', '*.jpg', '*.jpeg', '*.tif', '*.bmp'};
            for e = 1:numel(imgExts)
                d = dir(fullfile(srcStr, imgExts{e}));
                for k = 1:numel(d)
                    fileList{end+1} = fullfile(d(k).folder, d(k).name); %#ok<AGROW>
                end
            end
        elseif isfile(srcStr)
            fileList = {srcStr};
        end
    elseif iscell(imageSources)
        fileList = imageSources;
    elseif istable(imageSources) && any(strcmpi(imageSources.Properties.VariableNames, 'ImagePath'))
        fileList = cellstr(imageSources.ImagePath);
    end

    totalImages = numel(fileList);
    if totalImages == 0
        error('SIH26038:NoImages', 'No valid fundus images found for batch prediction.');
    end

    try
        logger.info('Starting batch DR inference for %d images...', totalImages);
    catch
    end

    % 2. Allocate Output Arrays
    fileNames    = cell(totalImages, 1);
    stageCodes   = zeros(totalImages, 1, 'int32');
    stageNames   = cell(totalImages, 1);
    confidences  = zeros(totalImages, 1);
    latenciesMs  = zeros(totalImages, 1);
    referrals    = false(totalImages, 1);
    urgencies    = cell(totalImages, 1);
    actions      = cell(totalImages, 1);

    % 3. Sequential Inference Loop
    for i = 1:totalImages
        imgPath = fileList{i};
        [~, fn, fe] = fileparts(imgPath);
        fileNames{i} = [fn, fe];

        pred = predictDR(imgPath, config);

        stageCodes(i)  = int32(pred.stageCode);
        stageNames{i}  = pred.stageName;
        confidences(i) = pred.confidencePercent;
        latenciesMs(i) = pred.inferenceLatencyMs;
        referrals(i)   = pred.referralRequired;
        urgencies{i}   = pred.urgency;
        actions{i}     = pred.actionProtocol;
    end

    % 4. Assemble Results Table
    resultsTable = table(fileNames, stageCodes, stageNames, confidences, ...
                         latenciesMs, referrals, urgencies, actions, ...
                         'VariableNames', {'FileName', 'StageCode', 'StageName', ...
                                           'ConfidencePercent', 'LatencyMs', ...
                                           'ReferralRequired', 'Urgency', 'ActionProtocol'});

    % 5. Aggregate Cohort Statistics
    stageCounts = zeros(1, 5);
    for c = 0:4
        stageCounts(c + 1) = sum(stageCodes == c);
    end
    numReferrals = sum(referrals);
    refRate = (numReferrals / totalImages) * 100.0;
    avgLatency = mean(latenciesMs);

    cohortSummary = struct();
    cohortSummary.totalScreened      = totalImages;
    cohortSummary.referralCount      = numReferrals;
    cohortSummary.referralRatePercent= round(refRate, 1);
    cohortSummary.averageLatencyMs   = round(avgLatency, 1);
    cohortSummary.stageCounts        = stageCounts;

    % 6. Export to CSV if requested
    if nargin >= 3 && ~isempty(exportCsvPath)
        try
            writetable(resultsTable, exportCsvPath);
            try
                logger.info('Batch prediction summary exported to: %s', exportCsvPath);
            catch
            end
        catch ME
            warning('Could not export CSV to %s: %s', exportCsvPath, ME.message);
        end
    end
end
