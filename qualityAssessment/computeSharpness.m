function [sharpnessTenengrad, edgeDensity] = computeSharpness(grayImg, mask)
% COMPUTESHARPNESS Evaluates retinal sharpness using Tenengrad gradient energy.
%
%   sharpnessTenengrad = computeSharpness(grayImg)
%   [sharpnessTenengrad, edgeDensity] = computeSharpness(grayImg, mask)
%
%   Inputs:
%       grayImg            - Grayscale or green-channel fundus image array [0, 255].
%       mask               - (Optional) Binary mask of foreground retinal tissue.
%
%   Outputs:
%       sharpnessTenengrad - Mean squared Sobel gradient magnitude of significant edges.
%                            Higher values (>150) indicate crisp vascular bifurcation definition.
%       edgeDensity        - Proportion of retinal pixels containing sharp edge transitions [0, 1].
%
%   Significance:
%       Sharpness is the primary indicator that the optical focus plane aligns precisely
%       with the neurosensory retinal layer, enabling microaneurysm detection.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    I = double(grayImg);
    if max(I(:)) <= 1.0 && isfloat(grayImg)
        I = I * 255.0;
    end

    % 1. Foreground mask
    if nargin < 2 || isempty(mask)
        rawMask = I > 15;
        se = strel('disk', 6);
        mask = imerode(rawMask, se);
    else
        mask = mask > 0;
    end

    % 2. Sobel Gradient Operators
    sobelX = [ -1,  0,  1; ...
               -2,  0,  2; ...
               -1,  0,  1 ];
    sobelY = sobelX';

    gx = conv2(I, sobelX, 'same');
    gy = conv2(I, sobelY, 'same');

    gradSq = gx.^2 + gy.^2;

    % 3. Tenengrad Energy on Masked Retinal Field
    maskedGradSq = gradSq(mask);

    if isempty(maskedGradSq) || numel(maskedGradSq) < 100
        sharpnessTenengrad = 0.0;
        edgeDensity = 0.0;
        return;
    end

    % Threshold to filter out sensor floor noise (Tenengrad threshold)
    threshold = 40.0;
    significantEdges = maskedGradSq(maskedGradSq > threshold);

    if ~isempty(significantEdges)
        sharpnessTenengrad = mean(significantEdges);
        edgeDensity = numel(significantEdges) / numel(maskedGradSq);
    else
        sharpnessTenengrad = 0.0;
        edgeDensity = 0.0;
    end

    sharpnessTenengrad = round(sharpnessTenengrad, 2);
    edgeDensity = round(edgeDensity, 4);
end
