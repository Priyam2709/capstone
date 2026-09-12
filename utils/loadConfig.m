function config = loadConfig(configPath)
% LOADCONFIG Loads and validates the JSON configuration file for the DR screening system.
%
%   config = loadConfig()
%   config = loadConfig(configPath)
%
%   Inputs:
%       configPath (optional) - Absolute or relative path to a JSON configuration file.
%                               Defaults to 'config/default_config.json'.
%
%   Outputs:
%       config - MATLAB struct containing all configuration parameters with
%                resolved absolute filesystem paths.
%
%   Example:
%       cfg = loadConfig();
%       fprintf('Active model architecture: %s\n', cfg.model.selected_architecture);
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    projectRoot = getProjectRoot();

    % Default to master configuration if path not provided
    if nargin < 1 || isempty(configPath)
        configPath = fullfile(projectRoot, 'config', 'default_config.json');
    else
        if ~ischar(configPath) && ~isstring(configPath)
            error('SIH26038:InvalidInput', 'configPath must be a valid file path string.');
        end
        % Resolve relative path if necessary
        if ~java.io.File(configPath).isAbsolute()
            configPath = fullfile(projectRoot, configPath);
        end
    end

    % Verify file existence
    if ~isfile(configPath)
        error('SIH26038:ConfigNotFound', 'Configuration file not found at: %s', configPath);
    end

    try
        % Read raw file content
        fid = fopen(configPath, 'r');
        if fid == -1
            error('SIH26038:FileOpenError', 'Unable to open configuration file: %s', configPath);
        end
        rawText = fread(fid, '*char')';
        fclose(fid);

        % Decode JSON
        config = jsondecode(rawText);
        logger.info('Loaded configuration from: %s', configPath);
    catch ME
        logger.error('Failed to parse JSON config [%s]: %s', configPath, ME.message);
        rethrow(ME);
    end

    % Validate essential schema elements
    requiredFields = {'project_info', 'paths', 'dataset', 'image', ...
                      'quality_assessment', 'preprocessing', 'model', ...
                      'training', 'explainability', 'reporting'};
    for i = 1:numel(requiredFields)
        if ~isfield(config, requiredFields{i})
            error('SIH26038:InvalidConfigSchema', ...
                  'Configuration file missing required section: "%s"', requiredFields{i});
        end
    end

    % Resolve absolute filesystem paths for all configured directories
    config.paths.project_root = projectRoot;
    config.paths.abs_raw_data_dir = fullfile(projectRoot, config.paths.raw_data_dir);
    config.paths.abs_processed_data_dir = fullfile(projectRoot, config.paths.processed_data_dir);
    config.paths.abs_labels_dir = fullfile(projectRoot, config.paths.labels_dir);
    config.paths.abs_models_dir = fullfile(projectRoot, config.paths.models_dir);
    config.paths.abs_checkpoints_dir = fullfile(projectRoot, config.paths.checkpoints_dir);
    config.paths.abs_results_dir = fullfile(projectRoot, config.paths.results_dir);
    config.paths.abs_logs_dir = fullfile(projectRoot, config.paths.logs_dir);
    config.paths.abs_reports_dir = fullfile(projectRoot, config.paths.reports_dir);
    config.paths.abs_visualizations_dir = fullfile(projectRoot, config.paths.visualizations_dir);

    % Automatically ensure critical result directories exist
    resultDirs = {config.paths.abs_logs_dir, config.paths.abs_reports_dir, ...
                  config.paths.abs_visualizations_dir, config.paths.abs_checkpoints_dir};
    for i = 1:numel(resultDirs)
        if ~isfolder(resultDirs{i})
            mkdir(resultDirs{i});
        end
    end

    logger.debug('Configuration validated successfully. Target model: %s', ...
                 config.model.selected_architecture);
end
