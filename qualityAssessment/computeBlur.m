function [blurScore, blurMap] = computeBlur(grayImg, mask)
% COMPUTEBLUR Evaluates retinal image blur using masked Laplacian variance.
%
%   blurScore = computeBlur(grayImg)
%   [blurScore, blurMap] = computeBlur(grayImg, mask)
%
%   Inputs:
%       grayImg   - 2D grayscale or green-channel fundus image array (uint8 or double).
%       mask      - (Optional) Binary foreground mask isolating retinal tissue.
%                   If omitted, automatically estimated by intensity thresholding.
%
%   Outputs:
%       blurScore - Variance of the Laplacian filter response across the retinal field.
%                   Higher values (>100) indicate sharp retinal vessels and microaneurysms;
%                   lower values (<60) indicate severe defocus or motion blur.
%       blurMap   - 2D array of localized Laplacian response magnitudes.
%
%   Algorithm:
%       Calculates the discrete 2D Laplacian operator response:
%           L = [ 0  1  0;
%                 1 -4  1;
%                 0  1  0 ]
%       Excludes the high-contrast circular aperture edge of the fundus camera
%       to prevent edge artifacts from artificially inflating the blur score.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    I = double(grayImg);
    if max(I(:)) <= 1.0 && isfloat(grayImg)
        I = I * 255.0;
    end

    % 1. Estimate retinal foreground mask if not provided
    if nargin < 2 || isempty(mask)
        rawMask = I > 15;
        % Morphological erosion to exclude the bright outer aperture circle
        se = strel('disk', 7);
        mask = imerode(rawMask, se);
    else
        se = strel('disk', 5);
        mask = imerode(mask > 0, se);
    end

    % 2. Discrete 3x3 Laplacian kernel
    lapKernel = [ 0,  1,  0; ...
                  1, -4,  1; ...
                  0,  1,  0 ];

    % 3. Convolve image with Laplacian
    laplacianResp = conv2(I, lapKernel, 'same');
    blurMap = abs(laplacianResp);

    % 4. Compute variance strictly within valid retinal tissue
    validPixels = laplacianResp(mask);

    if ~isempty(validPixels) && numel(validPixels) > 100
        blurScore = var(validPixels);
    else
        % Fallback for empty/fully masked image
        blurScore = 0.0;
    end

    blurScore = round(blurScore, 2);
end
