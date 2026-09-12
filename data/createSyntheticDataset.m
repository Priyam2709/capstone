function createSyntheticDataset(datasetName, numSamplesPerClass)
% CREATESYNTHETICDATASET Generates sample fundus images and label CSVs for testing.
%
%   createSyntheticDataset()
%   createSyntheticDataset(datasetName)
%   createSyntheticDataset(datasetName, numSamplesPerClass)
%
%   Inputs:
%       datasetName         - 'APTOS', 'EyePACS', 'IDRiD', or 'Messidor' (Default: 'APTOS')
%       numSamplesPerClass  - Number of mock images per class (Default: 4, Total: 20 images)
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(datasetName)
        datasetName = 'APTOS';
    end
    if nargin < 2 || isempty(numSamplesPerClass)
        numSamplesPerClass = 4;
    end

    projectRoot = getProjectRoot();
    datasetName = upper(char(datasetName));
    
    imgDir = fullfile(projectRoot, 'data', 'raw', lower(datasetName));
    labelDir = fullfile(projectRoot, 'data', 'labels');
    
    if ~isfolder(imgDir), mkdir(imgDir); end
    if ~isfolder(labelDir), mkdir(labelDir); end

    logger.info('Generating synthetic test dataset for [%s] (%d samples/class)...', ...
                datasetName, numSamplesPerClass);

    % Define schema based on dataset source
    switch datasetName
        case 'APTOS'
            idColName = 'id_code';
            labelColName = 'diagnosis';
            ext = '.png';
            csvFile = fullfile(labelDir, 'aptos_labels.csv');
        case 'EYEPACS'
            idColName = 'image';
            labelColName = 'level';
            ext = '.jpeg';
            csvFile = fullfile(labelDir, 'eyepacs_labels.csv');
        case 'IDRID'
            idColName = 'Image_name';
            labelColName = 'Retinopathy_grade';
            ext = '.jpg';
            csvFile = fullfile(labelDir, 'idrid_labels.csv');
        case 'MESSIDOR'
            idColName = 'Image';
            labelColName = 'Retinopathy_grade';
            ext = '.tif';
            csvFile = fullfile(labelDir, 'messidor_labels.csv');
        otherwise
            idColName = 'id_code';
            labelColName = 'diagnosis';
            ext = '.png';
            csvFile = fullfile(labelDir, sprintf('%s_labels.csv', lower(datasetName)));
    end

    idList = {};
    labelList = [];

    [X, Y] = meshgrid(-112:111, -112:111);
    R = sqrt(X.^2 + Y.^2);
    retinaMask = R <= 105;

    for stage = 0:4
        for s = 1:numSamplesPerClass
            idStr = sprintf('%s_%03d_%d', lower(datasetName), stage, s);
            fileName = [idStr, ext];
            filePath = fullfile(imgDir, fileName);

            % Synthetic retinal fundus base (orange-reddish tone)
            rng(stage * 100 + s, 'twister');
            bgNoise = 0.15 * rand(224, 224);
            
            img = zeros(224, 224, 3, 'uint8');
            img(:,:,1) = uint8(210 * retinaMask .* (1 - bgNoise));
            img(:,:,2) = uint8(110 * retinaMask .* (1 - bgNoise));
            img(:,:,3) = uint8(35  * retinaMask .* (1 - bgNoise));

            % Add optic disc (yellowish-white oval at nasal side)
            opticDisc = ((X - 45).^2 / 16^2 + (Y + 10).^2 / 20^2) <= 1;
            for c = 1:3
                channel = img(:,:,c);
                channel(opticDisc) = 240 + randi([0, 15]);
                img(:,:,c) = channel;
            end

            % Add macula / fovea (darker central avascular zone)
            fovea = ((X + 25).^2 / 12^2 + (Y - 5).^2 / 12^2) <= 1;
            img(:,:,1) = img(:,:,1) - uint8(40 * fovea);
            img(:,:,2) = img(:,:,2) - uint8(35 * fovea);

            % Add stage-specific retinal lesions
            switch stage
                case 1 % Mild: isolated microaneurysms (tiny red dots)
                    for k = 1:3
                        rx = randi([-40, 20]); ry = randi([-30, 30]);
                        ma = (X - rx).^2 + (Y - ry).^2 <= 2;
                        img(cat(3, ma, ma, ma)) = 0;
                        img(:,:,1) = img(:,:,1) + uint8(220 * ma);
                    end
                case 2 % Moderate: microaneurysms + hard yellow exudates
                    for k = 1:8
                        rx = randi([-50, 30]); ry = randi([-40, 40]);
                        ex = (X - rx).^2 + (Y - ry).^2 <= 5;
                        img(cat(3, ex, ex, ex)) = 250;
                    end
                case 3 % Severe: blot hemorrhages across quadrants + cotton wool spots
                    for k = 1:15
                        rx = randi([-70, 70]); ry = randi([-70, 70]);
                        hem = (X - rx).^2 + (Y - ry).^2 <= 9;
                        img(:,:,1) = img(:,:,1) + uint8(180 * hem);
                        img(:,:,2) = img(:,:,2) - uint8(80 * hem);
                        img(:,:,3) = img(:,:,3) - uint8(30 * hem);
                    end
                case 4 % Proliferative: neovascularization fronds + severe hemorrhages
                    for k = 1:25
                        rx = randi([-80, 80]); ry = randi([-80, 80]);
                        neo = (X - rx).^2 + (Y - ry).^2 <= 12;
                        img(:,:,1) = img(:,:,1) + uint8(200 * neo);
                        img(:,:,2) = img(:,:,2) - uint8(100 * neo);
                    end
            end

            imwrite(img, filePath);
            idList{end+1, 1} = idStr; %#ok<AGROW>
            labelList(end+1, 1) = stage; %#ok<AGROW>
        end
    end

    % Create labels table and write CSV
    labelTable = table(idList, labelList, 'VariableNames', {idColName, labelColName});
    writetable(labelTable, csvFile);
    logger.info('Synthetic dataset [%s] generated: %d images at %s, CSV at %s', ...
                datasetName, numel(idList), imgDir, csvFile);
end
