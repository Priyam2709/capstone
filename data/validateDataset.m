function [cleanTable, report] = validateDataset(rawTable, imageDir, idColName, labelColName)
% VALIDATEDATASET Detects missing images, flags invalid labels, and sanitizes dataset table.
%
%   [cleanTable, report] = validateDataset(rawTable, imageDir)
%   [cleanTable, report] = validateDataset(rawTable, imageDir, idColName, labelColName)
%
%   Inputs:
%       rawTable     - MATLAB table read directly from CSV.
%       imageDir     - Directory containing the raw fundus images.
%       idColName    - (Optional) Column name for image IDs. Inferred if empty.
%       labelColName - (Optional) Column name for diagnosis labels. Inferred if empty.
%
%   Outputs:
%       cleanTable   - Sanitized table containing only verified image paths and valid labels.
%       report       - Struct detailing:
%           .totalRows         - Original CSV row count
%           .validCount        - Number of verified valid samples
%           .missingCount      - Number of image files referenced in CSV but missing from disk
%           .missingList       - Cell array of missing image identifiers
%           .invalidLabelCount - Number of labels outside valid range [0, 4] or non-integer
%           .invalidLabelList  - Cell array of flagged invalid records
%           .classDistribution - 1x5 vector of valid sample counts per DR stage
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(rawTable)
        error('SIH26038:InvalidInput', 'rawTable must be a non-empty MATLAB table.');
    end

    if nargin < 2 || isempty(imageDir)
        error('SIH26038:InvalidInput', 'imageDir must be specified.');
    end

    % 1. Auto-detect ID and Label Column Names if not provided
    varNames = rawTable.Properties.VariableNames;
    
    if nargin < 3 || isempty(idColName)
        candidateIdCols = {'id_code', 'image', 'Image_name', 'Image', 'image_id', 'id', 'filename', 'FileName'};
        idColName = '';
        for i = 1:numel(candidateIdCols)
            if any(strcmpi(varNames, candidateIdCols{i}))
                idx = find(strcmpi(varNames, candidateIdCols{i}), 1);
                idColName = varNames{idx};
                break;
            end
        end
        if isempty(idColName)
            idColName = varNames{1}; % Default to first column
        end
    end

    if nargin < 4 || isempty(labelColName)
        candidateLabelCols = {'diagnosis', 'level', 'Retinopathy_grade', 'dr_grade', 'label', 'target', 'class'};
        labelColName = '';
        for i = 1:numel(candidateLabelCols)
            if any(strcmpi(varNames, candidateLabelCols{i}))
                idx = find(strcmpi(varNames, candidateLabelCols{i}), 1);
                labelColName = varNames{idx};
                break;
            end
        end
        if isempty(labelColName)
            labelColName = varNames{2}; % Default to second column
        end
    end

    logger.info('Validating dataset with ID column: "%s", Label column: "%s"...', ...
                idColName, labelColName);

    totalRows = height(rawTable);
    validIndices = false(totalRows, 1);
    resolvedPaths = strings(totalRows, 1);
    sanitizedLabels = zeros(totalRows, 1, 'int32');

    missingList = {};
    invalidLabelList = {};
    classDist = zeros(1, 5);

    supportedExts = {'', '.png', '.jpg', '.jpeg', '.tif', '.tiff', '.bmp'};

    % 2. Inspect every record
    for r = 1:totalRows
        rawId = rawTable.(idColName)(r);
        if iscell(rawId), rawId = rawId{1}; end
        rawIdStr = char(string(rawId));

        rawLbl = rawTable.(labelColName)(r);
        if iscell(rawLbl), rawLbl = rawLbl{1}; end

        % Validate label value (must be numeric integer between 0 and 4)
        lblNum = double(rawLbl);
        if isnan(lblNum) || isempty(lblNum) || lblNum < 0 || lblNum > 4 || floor(lblNum) ~= lblNum
            invalidLabelList{end+1} = sprintf('Row %d: ID "%s" has invalid label "%s"', ...
                                              r, rawIdStr, string(rawLbl)); %#ok<AGROW>
            continue;
        end

        % Resolve file path on disk across candidate extensions
        foundFile = '';
        for e = 1:numel(supportedExts)
            candidateFile = fullfile(imageDir, [rawIdStr, supportedExts{e}]);
            if isfile(candidateFile)
                foundFile = candidateFile;
                break;
            end
        end

        if isempty(foundFile)
            missingList{end+1} = sprintf('Row %d: Image file not found for ID "%s" in %s', ...
                                         r, rawIdStr, imageDir); %#ok<AGROW>
            continue;
        end

        % Valid record
        validIndices(r) = true;
        resolvedPaths(r) = string(foundFile);
        sanitizedLabels(r) = int32(lblNum);
        classDist(lblNum + 1) = classDist(lblNum + 1) + 1;
    end

    % 3. Assemble sanitized clean table
    cleanTable = table();
    cleanTable.ImageId = string(rawTable.(idColName)(validIndices));
    cleanTable.ImagePath = resolvedPaths(validIndices);
    cleanTable.Diagnosis = sanitizedLabels(validIndices);

    % Map descriptive stage names
    stageNamesList = {'0 - No DR', '1 - Mild NPDR', '2 - Moderate NPDR', ...
                      '3 - Severe NPDR', '4 - Proliferative DR'};
    cleanTable.StageName = categorical(stageNamesList(cleanTable.Diagnosis + 1));

    % 4. Assemble validation report
    report = struct();
    report.totalRows = totalRows;
    report.validCount = sum(validIndices);
    report.missingCount = numel(missingList);
    report.missingList = missingList;
    report.invalidLabelCount = numel(invalidLabelList);
    report.invalidLabelList = invalidLabelList;
    report.classDistribution = classDist;
    report.isClean = (report.missingCount == 0) && (report.invalidLabelCount == 0);

    logger.info('Dataset validation results: %d/%d valid (Missing: %d, Invalid Labels: %d)', ...
                report.validCount, totalRows, report.missingCount, report.invalidLabelCount);
    if ~report.isClean
        logger.warn('Sanitization filtered out %d problematic entries.', ...
                    totalRows - report.validCount);
    end
end
