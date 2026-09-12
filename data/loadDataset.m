function [datasetSplits, summaryInfo] = loadDataset(datasetName, config, customSplitRatios)
% LOADDATASET Ingests, validates, and partitions fundus datasets into stratified splits.
%
%   [datasetSplits, summaryInfo] = loadDataset()
%   [datasetSplits, summaryInfo] = loadDataset(datasetName)
%   [datasetSplits, summaryInfo] = loadDataset(datasetName, config)
%   [datasetSplits, summaryInfo] = loadDataset(datasetName, config, customSplitRatios)
%
%   Supports:
%       - 'APTOS'    : Kaggle APTOS 2019 Blindness Detection (3,662 retinal images)
%       - 'EyePACS'  : Kaggle Diabetic Retinopathy Detection (35,126 retinal images)
%       - 'IDRiD'    : Indian Diabetic Retinopathy Image Dataset (516 retinal images)
%       - 'Messidor' : Messidor & Messidor-2 French Clinical Datasets (1,748 images)
%
%   Inputs:
%       datasetName       - (Optional) 'APTOS', 'EyePACS', 'IDRiD', or 'Messidor'.
%                           Defaults to config.dataset.active_dataset ('APTOS').
%       config            - (Optional) System configuration struct from loadConfig().
%       customSplitRatios - (Optional) Struct with .train, .val, .test ratios
%                           (e.g., struct('train', 0.70, 'val', 0.15, 'test', 0.15)).
%
%   Outputs:
%       datasetSplits     - Struct containing:
%           .train - Table of training samples [ImageId, ImagePath, Diagnosis, StageName]
%           .val   - Table of validation samples [ImageId, ImagePath, Diagnosis, StageName]
%           .test  - Table of test samples [ImageId, ImagePath, Diagnosis, StageName]
%           .targetSize - Configured image dimensions [Height, Width, Channels]
%           .datasetName - Name of active dataset
%       summaryInfo       - Struct containing:
%           .totalImages       - Total count of valid images
%           .validationReport  - Integrity report from validateDataset()
%           .splitCounts       - Counts of train, val, and test samples
%           .classDistribution - Class counts per split [5 x 3 matrix]
%           .targetImageSize   - Target image dimensions
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(config)
        config = loadConfig();
    end

    if nargin < 1 || isempty(datasetName)
        datasetName = config.dataset.active_dataset;
    end
    datasetName = upper(char(datasetName));

    if nargin < 3 || isempty(customSplitRatios)
        splitRatios = config.dataset.split_ratios;
    else
        splitRatios = customSplitRatios;
    end

    logger.info('Loading and parsing dataset: [%s]...', datasetName);

    % 1. Resolve Dataset Directories and Label CSV
    projectRoot = config.paths.project_root;
    imgDir = fullfile(projectRoot, config.paths.raw_data_dir, lower(datasetName));
    labelDir = fullfile(projectRoot, config.paths.labels_dir);

    % Candidate CSV filenames
    candidateCsvs = {
        fullfile(labelDir, sprintf('%s_labels.csv', lower(datasetName))), ...
        fullfile(labelDir, sprintf('%s.csv', lower(datasetName))), ...
        fullfile(labelDir, 'train.csv'), ...
        fullfile(imgDir, 'labels.csv') ...
    };

    csvPath = '';
    for i = 1:numel(candidateCsvs)
        if isfile(candidateCsvs{i})
            csvPath = candidateCsvs{i};
            break;
        end
    end

    if isempty(csvPath)
        error('SIH26038:LabelFileNotFound', ...
              'Label CSV file for dataset "%s" not found in %s.', datasetName, labelDir);
    end

    logger.info('Reading label annotations from: %s', csvPath);
    rawCsvTable = readtable(csvPath);

    % 2. Validate Dataset Integrity (detect missing images & invalid labels)
    [cleanTable, valReport] = validateDataset(rawCsvTable, imgDir);

    if valReport.validCount == 0
        error('SIH26038:EmptyValidDataset', ...
              'No valid fundus images found for dataset "%s". Please populate %s.', ...
              datasetName, imgDir);
    end

    % 3. Create Stratified Train / Validation / Test Splits
    logger.info('Creating stratified splits (Train: %.0f%%, Val: %.0f%%, Test: %.0f%%)...', ...
                splitRatios.train * 100, splitRatios.val * 100, splitRatios.test * 100);

    % Deterministic random seed for reproducibility
    if isfield(config.dataset, 'random_seed')
        rng(config.dataset.random_seed, 'twister');
    else
        rng(42, 'twister');
    end

    trainIdx = [];
    valIdx   = [];
    testIdx  = [];

    classDistMatrix = zeros(5, 3); % Rows: Classes 0-4, Cols: [Train, Val, Test]

    % Partition each class proportionally
    for c = 0:4
        cIndices = find(cleanTable.Diagnosis == c);
        numClassSamples = numel(cIndices);

        if numClassSamples == 0
            continue;
        end

        % Shuffle indices of this class
        shuffled = cIndices(randperm(numClassSamples));

        % Compute partition cutoffs
        nTrain = round(splitRatios.train * numClassSamples);
        nVal   = round(splitRatios.val * numClassSamples);
        
        % Ensure at least 1 sample in test if there are sufficient samples
        if (numClassSamples - nTrain - nVal) < 1 && numClassSamples >= 3
            if nTrain > 1
                nTrain = nTrain - 1;
            elseif nVal > 1
                nVal = nVal - 1;
            end
        end
        nTest = numClassSamples - nTrain - nVal;

        cTrain = shuffled(1:nTrain);
        cVal   = shuffled(nTrain + 1 : nTrain + nVal);
        cTest  = shuffled(nTrain + nVal + 1 : end);

        trainIdx = [trainIdx; cTrain]; %#ok<AGROW>
        valIdx   = [valIdx; cVal];     %#ok<AGROW>
        testIdx  = [testIdx; cTest];   %#ok<AGROW>

        classDistMatrix(c + 1, 1) = numel(cTrain);
        classDistMatrix(c + 1, 2) = numel(cVal);
        classDistMatrix(c + 1, 3) = numel(cTest);
    end

    % 4. Assemble Output Tables
    datasetSplits = struct();
    datasetSplits.train = cleanTable(trainIdx, :);
    datasetSplits.val   = cleanTable(valIdx, :);
    datasetSplits.test  = cleanTable(testIdx, :);
    datasetSplits.targetSize = config.image.target_size;
    datasetSplits.datasetName = datasetName;

    % 5. Assemble Summary Struct
    summaryInfo = struct();
    summaryInfo.datasetName = datasetName;
    summaryInfo.totalImages = valReport.validCount;
    summaryInfo.validationReport = valReport;
    summaryInfo.splitCounts = struct('train', height(datasetSplits.train), ...
                                     'val', height(datasetSplits.val), ...
                                     'test', height(datasetSplits.test));
    summaryInfo.classDistribution = classDistMatrix;
    summaryInfo.targetImageSize = config.image.target_size;

    logger.info('Dataset [%s] successfully partitioned: Train=%d, Val=%d, Test=%d (Total: %d)', ...
                datasetName, summaryInfo.splitCounts.train, ...
                summaryInfo.splitCounts.val, summaryInfo.splitCounts.test, ...
                summaryInfo.totalImages);
end
