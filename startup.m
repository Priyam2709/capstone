% STARTUP Entry-point script for SIH26038 Diabetic Retinopathy Screening System.
%
%   Initializes MATLAB path, verifies toolbox dependencies, sets up
%   logging, and loads default system configuration.
%
%   Usage:
%       startup
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

clc;
fprintf('===================================================================\n');
fprintf('  SIH26038: Explainable AI-Based Diabetic Retinopathy Screening     \n');
fprintf('  Designed for Rural Primary Health Centres (PHCs) & Mobile Camps   \n');
fprintf('  University Capstone Engineering Architecture                      \n');
fprintf('===================================================================\n\n');

% 1. Discover Project Root
rootPath = fileparts(mfilename('fullpath'));
fprintf('[1/4] Project root identified: %s\n', rootPath);

% 2. Add subdirectories to MATLAB path
fprintf('[2/4] Configuring search paths...\n');
subDirs = {'config', 'data', 'qualityAssessment', 'preprocessing', ...
           'classification', 'explainability', 'reports', 'gui', ...
           'models', 'utils', 'training', 'testing', 'documentation', 'simulink'};

for i = 1:numel(subDirs)
    dirPath = fullfile(rootPath, subDirs{i});
    if isfolder(dirPath)
        addpath(genpath(dirPath));
    end
end

% 3. Initialize Multi-Level Logger
fprintf('[3/4] Initializing diagnostic logger...\n');
try
    logger.init(fullfile(rootPath, 'results', 'logs', 'system.log'), logger.LEVEL_INFO);
    logger.info('MATLAB environment initialized successfully.');
catch ME
    warning('Logger could not be initialized: %s', ME.message);
end

% 4. Verify Toolbox Dependencies
fprintf('[4/4] Checking required MATLAB toolboxes...\n');
requiredToolboxes = { ...
    'Image Processing Toolbox', ...
    'Deep Learning Toolbox', ...
    'Computer Vision Toolbox', ...
    'Statistics and Machine Learning Toolbox' ...
};

installedToolboxes = ver;
installedNames = {installedToolboxes.Name};

for i = 1:numel(requiredToolboxes)
    tName = requiredToolboxes{i};
    if any(strcmp(installedNames, tName))
        fprintf('   [PASS] %-40s installed.\n', tName);
    else
        fprintf('   [WARN] %-40s NOT detected.\n', tName);
        logger.warn('Missing recommended toolbox: %s', tName);
    end
end

% 5. Validate System Configuration
try
    cfg = loadConfig();
    fprintf('\nSystem ready. Active architecture: %s | Image size: [%dx%d]\n', ...
            cfg.model.selected_architecture, ...
            cfg.image.target_size(1), cfg.image.target_size(2));
    fprintf('Type "main" to run the pipeline, or "launchApp" to open the GUI.\n\n');
catch ME
    fprintf('\n[WARNING] Default configuration failed to validate: %s\n\n', ME.message);
end
