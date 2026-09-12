function saveConfig(config, configPath)
% SAVECONFIG Persists a configuration struct into a JSON file.
%
%   saveConfig(config)
%   saveConfig(config, configPath)
%
%   Inputs:
%       config     - MATLAB struct containing system configuration settings.
%       configPath - (Optional) Destination file path. Defaults to 'config/default_config.json'.
%
%   Example:
%       cfg = loadConfig();
%       cfg.training.batch_size = 16;
%       saveConfig(cfg, 'config/custom_config.json');
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    projectRoot = getProjectRoot();

    if nargin < 2 || isempty(configPath)
        configPath = fullfile(projectRoot, 'config', 'default_config.json');
    else
        if ~java.io.File(configPath).isAbsolute()
            configPath = fullfile(projectRoot, configPath);
        end
    end

    if ~isstruct(config)
        error('SIH26038:InvalidInput', 'config must be a valid MATLAB struct.');
    end

    % Strip temporary absolute paths before persisting
    cleanedConfig = config;
    if isfield(cleanedConfig, 'paths')
        fnames = fieldnames(cleanedConfig.paths);
        for i = 1:numel(fnames)
            if startsWith(fnames{i}, 'abs_') || strcmp(fnames{i}, 'project_root')
                cleanedConfig.paths = rmfield(cleanedConfig.paths, fnames{i});
            end
        end
    end

    % Ensure target directory exists
    targetDir = fileparts(configPath);
    if ~isfolder(targetDir)
        mkdir(targetDir);
    end

    try
        % Encode to JSON (with indentation if supported)
        try
            jsonStr = jsonencode(cleanedConfig, 'PrettyPrint', true);
        catch
            jsonStr = jsonencode(cleanedConfig);
        end

        fid = fopen(configPath, 'w');
        if fid == -1
            error('SIH26038:FileWriteError', 'Unable to write to file: %s', configPath);
        end
        fwrite(fid, jsonStr, 'char');
        fclose(fid);

        logger.info('Saved configuration to: %s', configPath);
    catch ME
        logger.error('Failed to save configuration [%s]: %s', configPath, ME.message);
        rethrow(ME);
    end
end
