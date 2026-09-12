function savedPath = saveModelCheckpoint(modelPayload, modelName, epoch, valLoss, valAcc, destinationDir)
% SAVEMODELCHECKPOINT Persists trained neural network weights, hyperparameters, and metrics.
%
%   savedPath = saveModelCheckpoint(modelPayload, modelName, epoch, valLoss, valAcc)
%   savedPath = saveModelCheckpoint(modelPayload, modelName, epoch, valLoss, valAcc, destinationDir)
%
%   Inputs:
%       modelPayload   - Trained network object (DAGNetwork, dlnetwork, or layerGraph).
%       modelName      - Name string (e.g. 'resnet50', 'mobilenetv2').
%       epoch          - Current epoch number.
%       valLoss        - Validation loss achieved.
%       valAcc         - Validation accuracy achieved (percentage).
%       destinationDir - (Optional) Destination folder.
%
%   Outputs:
%       savedPath      - Absolute path of the serialized checkpoint file.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 6 || isempty(destinationDir)
        try
            projectRoot = getProjectRoot();
            destinationDir = fullfile(projectRoot, 'models', 'checkpoints');
        catch
            destinationDir = fullfile('.', 'models', 'checkpoints');
        end
    end

    if ~isfolder(destinationDir)
        mkdir(destinationDir);
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    fileName = sprintf('%s_epoch%02d_valAcc%.1f_%s.mat', ...
                       lower(modelName), epoch, valAcc, timestamp);
    savedPath = fullfile(destinationDir, fileName);

    % Assemble serialization payload
    checkpointData = struct();
    checkpointData.model = modelPayload;
    checkpointData.architecture = modelName;
    checkpointData.epoch = epoch;
    checkpointData.valLoss = valLoss;
    checkpointData.valAccuracy = valAcc;
    checkpointData.savedAt = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    checkpointData.classNames = { ...
        '0 - No DR', '1 - Mild NPDR', '2 - Moderate NPDR', ...
        '3 - Severe NPDR', '4 - Proliferative DR' ...
    };

    save(savedPath, 'checkpointData', '-v7.3');

    % Also save as current best symlink/file in models/
    try
        modelsDir = fileparts(destinationDir);
        bestPath = fullfile(modelsDir, sprintf('%s_best.mat', lower(modelName)));
        save(bestPath, 'checkpointData', '-v7.3');
    catch
    end

    try
        logger.info('Saved model checkpoint to: %s', savedPath);
    catch
    end
end
