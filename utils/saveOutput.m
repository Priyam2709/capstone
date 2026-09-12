function outputPath = saveOutput(dataOrHandle, destinationPath, fileType)
% SAVEOUTPUT Centralized artifact saver for images, figures, MAT files, and JSON.
%
%   outputPath = saveOutput(dataOrHandle, destinationPath)
%   outputPath = saveOutput(dataOrHandle, destinationPath, fileType)
%
%   Inputs:
%       dataOrHandle    - Data to save: image array (uint8/single/double),
%                         figure handle, MATLAB struct/table, or text string.
%       destinationPath - Target path (relative to project root or absolute).
%       fileType        - (Optional) 'image', 'figure', 'mat', 'json', 'text'.
%                         If omitted, inferred from the file extension.
%
%   Outputs:
%       outputPath      - Resolved absolute path of the saved artifact.
%
%   Example:
%       fig = figure(); plot([1 2 3]);
%       saveOutput(fig, 'results/visualizations/roc_curve.png');
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(destinationPath)
        error('SIH26038:MissingArgument', 'Both data and destinationPath must be provided.');
    end

    projectRoot = getProjectRoot();

    % Resolve absolute path
    if ~java.io.File(destinationPath).isAbsolute()
        outputPath = fullfile(projectRoot, destinationPath);
    else
        outputPath = destinationPath;
    end

    % Ensure target directory exists
    targetDir = fileparts(outputPath);
    if ~isfolder(targetDir)
        mkdir(targetDir);
    end

    % Determine file type if not specified
    if nargin < 3 || isempty(fileType)
        [~, ~, ext] = fileparts(outputPath);
        ext = lower(ext);
        switch ext
            case {'.png', '.jpg', '.jpeg', '.tif', '.tiff', '.bmp'}
                if isgraphics(dataOrHandle)
                    fileType = 'figure';
                else
                    fileType = 'image';
                end
            case '.fig'
                fileType = 'figure';
            case '.mat'
                fileType = 'mat';
            case '.json'
                fileType = 'json';
            case {'.txt', '.csv', '.log'}
                fileType = 'text';
            otherwise
                fileType = 'unknown';
        end
    end

    try
        switch lower(fileType)
            case 'image'
                % Convert floating point [0, 1] to uint8 if needed for PNG/JPG
                imgToSave = dataOrHandle;
                if isfloat(imgToSave) && max(imgToSave(:)) <= 1.0
                    imgToSave = im2uint8(imgToSave);
                end
                imwrite(imgToSave, outputPath);

            case 'figure'
                if ~isgraphics(dataOrHandle)
                    error('SIH26038:InvalidFigureHandle', 'Provided data is not a valid graphics handle.');
                end
                try
                    % High-resolution modern exportgraphics
                    exportgraphics(dataOrHandle, outputPath, 'Resolution', 300);
                catch
                    % Fallback for older MATLAB releases
                    saveas(dataOrHandle, outputPath);
                end

            case 'mat'
                payload = dataOrHandle; %#ok<NASGU>
                save(outputPath, 'payload', '-v7.3');

            case 'json'
                if ~isstruct(dataOrHandle)
                    error('SIH26038:InvalidJSONData', 'Data for JSON export must be a struct.');
                end
                try
                    jsonStr = jsonencode(dataOrHandle, 'PrettyPrint', true);
                catch
                    jsonStr = jsonencode(dataOrHandle);
                end
                fid = fopen(outputPath, 'w');
                if fid == -1
                    error('SIH26038:FileError', 'Cannot write to: %s', outputPath);
                end
                fwrite(fid, jsonStr, 'char');
                fclose(fid);

            case 'text'
                fid = fopen(outputPath, 'w');
                if fid == -1
                    error('SIH26038:FileError', 'Cannot write to: %s', outputPath);
                end
                if ischar(dataOrHandle) || isstring(dataOrHandle)
                    fprintf(fid, '%s\n', dataOrHandle);
                elseif istable(dataOrHandle)
                    writetable(dataOrHandle, outputPath);
                end
                fclose(fid);

            otherwise
                error('SIH26038:UnsupportedFileType', 'Unsupported file type: %s', fileType);
        end

        logger.info('Saved output artifact to: %s', outputPath);
    catch ME
        logger.error('Failed to save output to [%s]: %s', outputPath, ME.message);
        rethrow(ME);
    end
end
