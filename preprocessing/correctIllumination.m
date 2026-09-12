function [correctedImg, backgroundEst] = correctIllumination(img, sigmaVal)
% CORRECTILLUMINATION Compensates for non-uniform illumination, glare, and vignetting.
%
%   correctedImg = correctIllumination(img)
%   [correctedImg, backgroundEst] = correctIllumination(img, sigmaVal)
%
%   Inputs:
%       img           - RGB or grayscale fundus image (uint8 or double).
%       sigmaVal      - (Optional) Gaussian filter standard deviation for background estimation.
%                       Default: ~12% of image width.
%
%   Outputs:
%       correctedImg  - Illumination-leveled fundus image (uint8).
%       backgroundEst - Estimated background illumination field.
%
%   Algorithm:
%       Estimates slowly varying illumination gradient via Gaussian low-pass filtering.
%       Subtracts estimated background while restoring global mean luminance:
%           I_corrected = I - I_background + mean(I_background)
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    [H, W, C] = size(imgUint8);

    if nargin < 2 || isempty(sigmaVal)
        sigmaVal = max(12.0, round(0.12 * W));
    end

    % Retinal foreground mask to avoid black border contamination
    gray = rgb2gray(imgUint8);
    rawMask = gray > 15;
    se = strel('disk', 6);
    mask = imerode(rawMask, se);

    I_dbl = double(imgUint8);
    corrected = zeros(size(I_dbl), 'like', I_dbl);
    backgroundEst = zeros(size(I_dbl), 'like', I_dbl);

    for c = 1:C
        channel = I_dbl(:, :, c);

        % Smooth background surface
        bg = imgaussfilt(channel, sigmaVal);
        backgroundEst(:, :, c) = bg;

        % Restore mean illumination of retinal field
        retinalBg = bg(mask);
        if ~isempty(retinalBg)
            meanBg = mean(retinalBg);
        else
            meanBg = 128.0;
        end

        % Subtractive compensation
        comp = channel - bg + meanBg;
        
        % Restrict within [0, 255]
        corrected(:, :, c) = max(0.0, min(255.0, comp));
    end

    % Mask out non-retinal background back to 0
    if any(~rawMask(:))
        for c = 1:C
            ch = corrected(:, :, c);
            ch(~rawMask) = 0;
            corrected(:, :, c) = ch;
        end
    end

    correctedImg = uint8(corrected);
end
