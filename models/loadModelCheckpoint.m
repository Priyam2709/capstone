function checkpointData = loadModelCheckpoint(modelPathOrName)
% LOADMODELCHECKPOINT Loads a saved neural network checkpoint for inference/resumption.
%
%   checkpointData = loadModelCheckpoint(modelPathOrName)
%
%   Inputs:
%       modelPathOrName - Full file path to a .mat checkpoint, or architecture name
%                         (e.g., 'resnet50' -> loads models/resnet50_best.mat).
%
%   Outputs:
%       checkpointData  - Struct containing:
%           .model         - Network object
%           .architecture  - Architecture name
%           .epoch         - Checkpoint epoch
%           .valLoss       - Validation loss
%           .valAccuracy   - Validation accuracy
%           .savedAt       - Serialization timestamp
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(modelPathOrName)
        modelPathOrName = 'resnet50';
    end

    modelPath = char(modelPathOrName);

    % Resolve path
    if ~isfile(modelPath)
        try
            projectRoot = getProjectRoot();
            candidates = { ...
                fullfile(projectRoot, 'models', sprintf('%s_best.mat', lower(modelPath))), ...
                fullfile(projectRoot, 'models', 'checkpoints', modelPath), ...
                fullfile(projectRoot, modelPath) ...
            };
            for i = 1:numel(candidates)
                if isfile(candidates{i})
                    modelPath = candidates{i};
                    break;
                end
            end
        catch
        end
    end

    if ~isfile(modelPath)
        error('SIH26038:ModelNotFound', 'Model checkpoint file not found: %s', modelPathOrName);
    end

    loaded = load(modelPath);
    if isfield(loaded, 'checkpointData')
        checkpointData = loaded.checkpointData;
    else
        checkpointData = loaded;
    end

    try
        logger.info('Loaded model checkpoint: %s (Architecture: %s, Epoch: %d)', ...
                    modelPath, checkpointData.architecture, checkpointData.epoch);
    catch
    end
end
