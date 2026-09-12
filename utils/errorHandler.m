function userMsg = errorHandler(ME, contextMessage, isFatal)
% ERRORHANDLER Centralized error interceptor and graceful fallback for rural screening.
%
%   userMsg = errorHandler(ME)
%   userMsg = errorHandler(ME, contextMessage)
%   userMsg = errorHandler(ME, contextMessage, isFatal)
%
%   Inputs:
%       ME             - MATLAB MException object, or error string.
%       contextMessage - (Optional) Human-readable explanation of what was being attempted.
%       isFatal        - (Optional) Boolean flag. If true, rethrows or halts execution.
%                        If false, logs warning and returns fallback guidance. Defaults to false.
%
%   Outputs:
%       userMsg        - Sanitized, actionable clinical message for field health workers.
%
%   Example:
%       try
%           assessQuality(badImage);
%       catch ME
%           msg = errorHandler(ME, 'Image Quality Assessment', false);
%       end
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(contextMessage)
        contextMessage = 'Operation in progress';
    end

    if nargin < 3 || isempty(isFatal)
        isFatal = false;
    end

    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

    % Extract error details
    if isa(ME, 'MException')
        errIdentifier = ME.identifier;
        errMsg = ME.message;
        stackTrace = ME.stack;
    else
        errIdentifier = 'SIH26038:GeneralError';
        errMsg = char(ME);
        stackTrace = struct('file', {'Unknown'}, 'name', {'Direct Call'}, 'line', {0});
    end

    % Format stack trace details
    stackDetails = '';
    for i = 1:numel(stackTrace)
        stackDetails = sprintf('%s\n    -> In %s (Line %d) [%s]', ...
            stackDetails, stackTrace(i).name, stackTrace(i).line, stackTrace(i).file);
    end

    % Log error via system logger
    logger.error('Error encountered during [%s]: [%s] %s%s', ...
                 contextMessage, errIdentifier, errMsg, stackDetails);

    % Formulate actionable user message for rural clinical operators
    switch errIdentifier
        case {'SIH26038:ImageNotFound', 'MATLAB:imagesci:imread:fileDoesNotExist'}
            userMsg = sprintf('Image file could not be found. Please recapture the retinal fundus image.');
        case 'SIH26038:InvalidImageSize'
            userMsg = sprintf('Retinal image resolution is non-standard. Ensure camera is set to 224x224 or higher.');
        case 'SIH26038:LowQualityRetake'
            userMsg = sprintf('Image quality is insufficient (too blurry or dark). Retake image before proceeding.');
        case 'SIH26038:ModelLoadError'
            userMsg = sprintf('AI Model weights could not be loaded. Verify checkpoint path in settings.');
        otherwise
            userMsg = sprintf('System encountered a technical anomaly during "%s": %s. (Error Code: %s)', ...
                              contextMessage, errMsg, errIdentifier);
    end

    % Record to persistent error registry
    try
        projectRoot = getProjectRoot();
        errorLogPath = fullfile(projectRoot, 'results', 'logs', 'error_history.json');
        
        entry = struct();
        entry.timestamp = timestamp;
        entry.context = contextMessage;
        entry.identifier = errIdentifier;
        entry.message = errMsg;
        entry.isFatal = isFatal;
        entry.userGuidance = userMsg;

        if isfile(errorLogPath)
            raw = fileread(errorLogPath);
            history = jsondecode(raw);
            if ~iscell(history)
                history = {history};
            end
            history{end+1} = entry;
        else
            history = {entry};
        end
        saveOutput(history, errorLogPath, 'json');
    catch
        % Suppress secondary errors during logging
    end

    % If fatal, halt execution
    if isFatal && isa(ME, 'MException')
        rethrow(ME);
    end
end
