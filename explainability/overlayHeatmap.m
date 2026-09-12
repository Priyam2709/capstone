function overlayImg = overlayHeatmap(fundusImg, heatmap, alphaVal, colormapName)
% OVERLAYHEATMAP Blends Grad-CAM saliency onto retinal fundus image with smooth falloff.
%
%   overlayImg = overlayHeatmap(fundusImg, heatmap)
%   overlayImg = overlayHeatmap(fundusImg, heatmap, alphaVal)
%   overlayImg = overlayHeatmap(fundusImg, heatmap, alphaVal, colormapName)
%
%   Inputs:
%       fundusImg    - RGB retinal fundus image (uint8 or double [0, 1]).
%       heatmap      - 2D normalized saliency map in [0, 1].
%       alphaVal     - (Optional) Maximum transparency blending factor [0, 1] (Default: 0.50).
%       colormapName - (Optional) 'jet' (Default), 'turbo', or 'hot'.
%
%   Outputs:
%       overlayImg   - Blended 3-channel RGB image (uint8).
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 3 || isempty(alphaVal)
        alphaVal = 0.50;
    end

    if nargin < 4 || isempty(colormapName)
        colormapName = 'jet';
    end

    if isfloat(fundusImg) && max(fundusImg(:)) <= 1.0
        baseImg = double(fundusImg);
    else
        baseImg = double(fundusImg) / 255.0;
    end

    [H, W, ~] = size(baseImg);

    % Resize heatmap to match image dimensions if needed
    if size(heatmap, 1) ~= H || size(heatmap, 2) ~= W
        heatmap = imresize(heatmap, [H, W], 'bicubic');
    end
    heatmap = max(0.0, min(1.0, heatmap));

    % Generate RGB colormap representation
    numColors = 256;
    cmap = feval(colormapName, numColors);
    indices = round(heatmap * (numColors - 1)) + 1;
    heatRGB = ind2rgb(indices, cmap);

    % Dynamic weighted alpha: blend more strongly in high-activation zones,
    % fading out in low-activation background to keep healthy retina clearly visible
    effectiveAlpha = alphaVal * (heatmap .^ 1.2);
    alpha3D = repmat(effectiveAlpha, [1, 1, 3]);

    blended = (1.0 - alpha3D) .* baseImg + alpha3D .* heatRGB;
    blended = max(0.0, min(1.0, blended));

    overlayImg = im2uint8(blended);
end
