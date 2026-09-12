function [imgProcessed, imgRaw, metadata] = loadImage(imagePath, targetSize, normalizeOutput)
% LOADIMAGE Robust retinal fundus image loader with preprocessing & normalization.
%
%   [imgProcessed, imgRaw, metadata] = loadImage(imagePath)
%   [imgProcessed, imgRaw, metadata] = loadImage(imagePath, targetSize)
%   [imgProcessed, imgRaw, metadata] = loadImage(imagePath, targetSize, normalizeOutput)
%
%   Inputs:
%       imagePath       - Path to the retinal image file (.jpg, .jpeg, .png, .tif)
%       targetSize      - (Optional) [Height, Width] or [Height, Width, Channels].
%                         Defaults to [224, 224] if omitted or empty.
%       normalizeOutput - (Optional) Boolean flag. If true, outputs single in [0, 1].
%                         If false, outputs uint8 in [0, 255]. Defaults to true.
%
%   Outputs:
%       imgProcessed    - Preprocessed, resized, and formatted image array.
%       imgRaw          - Original unaltered image as loaded from disk.
%       metadata        - Struct containing original dimensions, channels, bit depth,
%                         file size, and file path.
%
%   Example:
%       [I_proc, I_raw, meta] = loadImage('data/raw/aptos/sample.png', [224, 224], true);
%       imshow(I_proc);
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(imagePath)
        error('SIH26038:MissingArgument', 'imagePath must be specified.');
    end

    if ~ischar(imagePath) && ~isstring(imagePath)
        error('SIH26038:InvalidInput', 'imagePath must be a char or string.');
    end

    imagePath = char(imagePath);

    % Handle relative path resolution
    if ~isfile(imagePath)
        projectRoot = getProjectRoot();
        candidatePath = fullfile(projectRoot, imagePath);
        if isfile(candidatePath)
            imagePath = candidatePath;
        else
            error('SIH26038:ImageNotFound', 'Image file does not exist: %s', imagePath);
        end
    end

    if nargin < 2 || isempty(targetSize)
        targetSize = [224, 224];
    elseif numel(targetSize) == 3
        targetSize = targetSize(1:2);
    end

    if nargin < 3 || isempty(normalizeOutput)
        normalizeOutput = true;
    end

    % Read image from disk
    try
        imgRaw = imread(imagePath);
    catch ME
        logger.error('Failed to read image [%s]: %s', imagePath, ME.message);
        rethrow(ME);
    end

    % Record original metadata
    fileInfo = dir(imagePath);
    origSize = size(imgRaw);
    metadata = struct();
    metadata.filePath = imagePath;
    metadata.fileName = fileInfo.name;
    metadata.fileSizeBytes = fileInfo.bytes;
    metadata.originalHeight = origSize(1);
    metadata.originalWidth = origSize(2);
    metadata.originalChannels = size(imgRaw, 3);
    metadata.classType = class(imgRaw);

    imgWorking = imgRaw;

    % Ensure 3-channel RGB
    if size(imgWorking, 3) == 1
        % Grayscale to RGB
        imgWorking = repmat(imgWorking, [1, 1, 3]);
        metadata.colorConverted = 'Grayscale to RGB';
    elseif size(imgWorking, 3) == 4
        % RGBA: discard alpha channel
        imgWorking = imgWorking(:, :, 1:3);
        metadata.colorConverted = 'RGBA alpha channel stripped';
    else
        metadata.colorConverted = 'None (Standard RGB)';
    end

    % Automatically crop black borders typical of fundus cameras
    imgWorking = autoCropFundusBorder(imgWorking);

    % Resize to target dimensions with antialiasing
    imgProcessed = imresize(imgWorking, targetSize, 'bicubic');

    % Output formatting (single in [0, 1] or uint8 in [0, 255])
    if normalizeOutput
        if ~isfloat(imgProcessed)
            imgProcessed = im2single(imgProcessed);
        else
            % Already float, scale to [0, 1] if needed
            maxVal = max(imgProcessed(:));
            if maxVal > 1.0
                imgProcessed = imgProcessed / 255.0;
            end
        end
    else
        if isfloat(imgProcessed)
            imgProcessed = im2uint8(imgProcessed);
        end
    end

    metadata.processedHeight = size(imgProcessed, 1);
    metadata.processedWidth = size(imgProcessed, 2);
    metadata.targetSize = targetSize;
    metadata.isNormalized = normalizeOutput;

    logger.debug('Loaded and preprocessed image: %s (Original: %dx%d -> Processed: %dx%d)', ...
                 metadata.fileName, metadata.originalHeight, metadata.originalWidth, ...
                 metadata.processedHeight, metadata.processedWidth);
end

function imgCropped = autoCropFundusBorder(img)
    % AUTOCROPFUNDUSBORDER Removes excessive black background borders surrounding retina
    gray = rgb2gray(img);
    mask = gray > 15; % Intensity threshold for non-background retina tissue
    
    [rowIdx, colIdx] = find(mask);
    if isempty(rowIdx) || isempty(colIdx)
        % Image is entirely dark or invalid, return original
        imgCropped = img;
        return;
    end

    minRow = max(1, min(rowIdx));
    maxRow = min(size(img, 1), max(rowIdx));
    minCol = max(1, min(colIdx));
    maxCol = min(size(img, 2), max(colIdx));

    % Add minimal margin (1% padding)
    h = maxRow - minRow + 1;
    w = maxCol - minCol + 1;
    padH = round(0.01 * h);
    padW = round(0.01 * w);

    minRow = max(1, minRow - padH);
    maxRow = min(size(img, 1), maxRow + padH);
    minCol = max(1, minCol - padW);
    maxCol = min(size(img, 2), maxCol + padW);

    imgCropped = img(minRow:maxRow, minCol:maxCol, :);
end
