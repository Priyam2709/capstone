function [rmsContrast, michelsonContrast, dynamicRange] = computeContrast(grayImg, mask)
% COMPUTECONTRAST Evaluates global RMS contrast, dynamic range, and local Michelson contrast.
%
%   rmsContrast = computeContrast(grayImg)
%   [rmsContrast, michelsonContrast, dynamicRange] = computeContrast(grayImg, mask)
%
%   Inputs:
%       grayImg           - Grayscale or green-channel fundus image array [0, 255].
%       mask              - (Optional) Binary mask of foreground retinal tissue.
%
%   Outputs:
%       rmsContrast       - Root Mean Square contrast of retinal tissue.
%                           Standard deviation of normalized pixel intensities.
%       michelsonContrast - Contrast ratio (Imax - Imin) / (Imax + Imin) of vascular detail.
%       dynamicRange      - Effective intensity spread (95th - 5th percentile) [0, 255].
%
%   Significance:
%       Adequate contrast in the green spectrum is essential to differentiate
%       dark microaneurysms and bright lipid exudates against the choroidal background.
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
        se = strel('disk', 5);
        mask = imerode(rawMask, se);
    else
        mask = mask > 0;
    end

    retinalPixels = I(mask);

    if isempty(retinalPixels) || numel(retinalPixels) < 100
        rmsContrast = 0.0;
        michelsonContrast = 0.0;
        dynamicRange = 0.0;
        return;
    end

    % 2. RMS Contrast
    meanVal = mean(retinalPixels);
    rmsContrast = sqrt(mean((retinalPixels - meanVal).^2));

    % 3. Effective Dynamic Range (Robust percentiles to exclude outlier sensor noise)
    p05 = prctile(retinalPixels, 5);
    p95 = prctile(retinalPixels, 95);
    dynamicRange = max(0.0, p95 - p05);

    % 4. Michelson Local Contrast
    if (p95 + p05) > 0
        michelsonContrast = (p95 - p05) / (p95 + p05);
    else
        michelsonContrast = 0.0;
    end

    rmsContrast = round(rmsContrast, 2);
    michelsonContrast = round(michelsonContrast, 3);
    dynamicRange = round(dynamicRange, 2);
end
