function [augmenter, augConfig] = configureAugmenter(config)
% CONFIGUREAUGMENTER Constructs data augmentation pipeline for retinal training.
%
%   augmenter = configureAugmenter()
%   [augmenter, augConfig] = configureAugmenter(config)
%
%   Applies ophthalmologically valid transformations:
%       - Random Horizontal Flip: Natural nasal/temporal symmetry
%       - Random Vertical Flip: Superior/inferior arcades variation
%       - Random Rotation: [-25 to +25 degrees] simulating head tilt
%       - Random Scaling: [0.9 to 1.1] simulating varied optical magnification
%       - Random Shear: [-5 to +5 degrees] minor corneal curvature variance
%
%   Outputs:
%       augmenter - MATLAB imageDataAugmenter object.
%       augConfig - Struct of configured augmentation parameters.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(config)
        try
            config = loadConfig();
        catch
            config = [];
        end
    end

    % Default Augmentation Parameters
    if ~isempty(config) && isfield(config, 'training') && isfield(config.training, 'data_augmentation')
        a = config.training.data_augmentation;
        xReflection = a.random_horizontal_flip;
        yReflection = a.random_vertical_flip;
        rotRange    = a.random_rotation_range;
        scaleRange  = a.random_scale_range;
        shearRange  = a.random_shear_range;
    else
        xReflection = true;
        yReflection = true;
        rotRange    = [-25, 25];
        scaleRange  = [0.90, 1.10];
        shearRange  = [-5, 5];
    end

    augConfig = struct();
    augConfig.RandXReflection = xReflection;
    augConfig.RandYReflection = yReflection;
    augConfig.RandRotation    = rotRange;
    augConfig.RandXScale      = scaleRange;
    augConfig.RandYScale      = scaleRange;
    augConfig.RandXShear      = shearRange;
    augConfig.RandYShear      = shearRange;

    % Build Deep Learning Toolbox augmenter
    try
        augmenter = imageDataAugmenter( ...
            'RandXReflection', xReflection, ...
            'RandYReflection', yReflection, ...
            'RandRotation', rotRange, ...
            'RandXScale', scaleRange, ...
            'RandYScale', scaleRange, ...
            'RandXShear', shearRange, ...
            'RandYShear', shearRange);
    catch
        % Fallback struct if Deep Learning Toolbox is not present
        augmenter = augConfig;
    end
end
