classdef logger
% LOGGER Enterprise logging utility for SIH26038 Diabetic Retinopathy screening system.
%
%   Supports multi-level logging (DEBUG, INFO, WARN, ERROR) with timestamps,
%   simultaneous console display and persistent file logging in results/logs/.
%
%   Methods (Static):
%       logger.init(logFilePath, minLevel) - Initialize logger with custom file and level
%       logger.debug(msg, ...)             - Log debug details
%       logger.info(msg, ...)              - Log general informational messages
%       logger.warn(msg, ...)              - Log warnings and non-fatal anomalies
%       logger.error(msg, ...)             - Log errors, exceptions, and failures
%
%   Example:
%       logger.init();
%       logger.info('Starting retinal image quality assessment...');
%       logger.warn('Image illumination low: %.2f (Threshold: %.2f)', 38.4, 40.0);
%       logger.error('Failed to load image: %s', 'image001.jpg');
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties (Constant)
        LEVEL_DEBUG = 1;
        LEVEL_INFO  = 2;
        LEVEL_WARN  = 3;
        LEVEL_ERROR = 4;
    end

    methods (Static)
        function init(logFilePath, minLevel)
            % Initialize logging destination and threshold
            persistent activeLogFile activeMinLevel
            
            if nargin < 1 || isempty(logFilePath)
                try
                    projectRoot = getProjectRoot();
                    logDir = fullfile(projectRoot, 'results', 'logs');
                    if ~isfolder(logDir)
                        mkdir(logDir);
                    end
                    activeLogFile = fullfile(logDir, 'system.log');
                catch
                    activeLogFile = fullfile('.', 'results', 'logs', 'system.log');
                end
            else
                activeLogFile = logFilePath;
            end

            if nargin < 2 || isempty(minLevel)
                activeMinLevel = logger.LEVEL_INFO;
            else
                activeMinLevel = minLevel;
            end
            
            % Write startup line
            logger.writeEntry('INFO', '==================================================', activeLogFile);
            logger.writeEntry('INFO', 'SIH26038 Diabetic Retinopathy System Logger Started', activeLogFile);
            logger.writeEntry('INFO', '==================================================', activeLogFile);
        end

        function debug(message, varargin)
            % Log debug message
            logger.logAtLevel(logger.LEVEL_DEBUG, 'DEBUG', message, varargin{:});
        end

        function info(message, varargin)
            % Log informational message
            logger.logAtLevel(logger.LEVEL_INFO, 'INFO', message, varargin{:});
        end

        function warn(message, varargin)
            % Log warning message
            logger.logAtLevel(logger.LEVEL_WARN, 'WARN', message, varargin{:});
        end

        function error(message, varargin)
            % Log error message
            logger.logAtLevel(logger.LEVEL_ERROR, 'ERROR', message, varargin{:});
        end
    end

    methods (Static, Access = private)
        function logAtLevel(levelNum, levelTag, message, varargin)
            % Internal dispatcher for log entries
            persistent activeLogFile activeMinLevel
            
            if isempty(activeMinLevel)
                activeMinLevel = logger.LEVEL_INFO;
            end
            
            if isempty(activeLogFile)
                try
                    projectRoot = getProjectRoot();
                    logDir = fullfile(projectRoot, 'results', 'logs');
                    if ~isfolder(logDir)
                        mkdir(logDir);
                    end
                    activeLogFile = fullfile(logDir, 'system.log');
                catch
                    activeLogFile = fullfile('.', 'results', 'logs', 'system.log');
                end
            end

            if levelNum >= activeMinLevel
                if ~isempty(varargin)
                    formattedMsg = sprintf(message, varargin{:});
                else
                    formattedMsg = message;
                end
                logger.writeEntry(levelTag, formattedMsg, activeLogFile);
            end
        end

        function writeEntry(levelTag, message, logFilePath)
            % Formats and emits entry to console and log file
            timestampStr = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
            entry = sprintf('[%s] [%-5s] %s', timestampStr, levelTag, message);

            % Output to MATLAB command window
            switch levelTag
                case 'ERROR'
                    fprintf(2, '%s\n', entry); % Standard error stream
                case 'WARN'
                    fprintf('%s\n', entry);
                otherwise
                    fprintf('%s\n', entry);
            end

            % Append to log file
            try
                fid = fopen(logFilePath, 'a');
                if fid ~= -1
                    fprintf(fid, '%s\n', entry);
                    fclose(fid);
                end
            catch
                % Silently continue if file write fails (e.g. read-only disk)
            end
        end
    end
end
