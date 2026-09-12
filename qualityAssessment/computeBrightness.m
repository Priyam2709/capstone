function [meanBrightness, uniformity, exposureStats] = computeBrightness(img, mask)
% COMPUTEBRIGHTNESS Evaluates retinal illumination level, uniformity, and exposure defects.
%
%   [meanBrightness, uniformity] = computeBrightness(img)
%   [meanBrightness, uniformity, exposureStats] = computeBrightness(img, mask)
%
%   Inputs:
%       img            - RGB or grayscale fundus image array (uint8 or double [0, 255]).
%       mask           - (Optional) Binary foreground mask isolating retinal tissue.
%
%   Outputs:
%       meanBrightness - Mean luminance of the foreground retinal field [0, 255].
%                        Optimal range: [80, 160].
%       uniformity     - Measure of illumination balance across 4 retinal quadrants [0, 1].
%                        Values >0.75 indicate smooth, even flash illumination.
%       exposureStats  - Struct containing:
%           .underexposedPercent - Percentage of foreground pixels with luminance < 30
%           .overexposedPercent  - Percentage of foreground pixels with luminance > 235 (glare)
%           .medianBrightness    - Median retinal luminance
%           .stdBrightness       - Standard deviation of luminance
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    % Extract perceptual luminance (ITU-R BT.601)
    if size(img, 3) == 3
        if isfloat(img) && max(img(:)) <= 1.0
            imgDbl = double(img) * 255.0;
        else
            imgDbl = double(img);
        end
        luminance = 0.299 * imgDbl(:,:,1) + ...
                    0.587 * imgDbl(:,:,2) + ...
                    0.114 * imgDbl(:,:,3);
    else
        if isfloat(img) && max(img(:)) <= 1.0
            luminance = double(img) * 255.0;
        else
            luminance = double(img);
        end
    end

    % 1. Foreground retinal mask
    if nargin < 2 || isempty(mask)
        rawMask = luminance > 15;
        se = strel('disk', 5);
        mask = imerode(rawMask, se);
    else
        mask = mask > 0;
    end

    retinalPixels = luminance(mask);

    if isempty(retinalPixels)
        meanBrightness = 0.0;
        uniformity = 0.0;
        exposureStats = struct('underexposedPercent', 100.0, 'overexposedPercent', 0.0, ...
                               'medianBrightness', 0.0, 'stdBrightness', 0.0);
        return;
    end

    % 2. Mean, Median, and Std
    meanBrightness = mean(retinalPixels);
    medianBrightness = median(retinalPixels);
    stdBrightness = std(retinalPixels);

    % 3. Exposure Glare & Darkness Statistics
    underCount = sum(retinalPixels < 30);
    overCount  = sum(retinalPixels > 235);
    totalPixels = numel(retinalPixels);

    underexposedPercent = (underCount / totalPixels) * 100.0;
    overexposedPercent  = (overCount / totalPixels) * 100.0;

    % 4. Illumination Uniformity across 4 Quadrants
    [H, W] = size(luminance);
    midH = round(H / 2);
    midW = round(W / 2);

    q1Mask = mask(1:midH, 1:midW);
    q2Mask = mask(1:midH, midW+1:end);
    q3Mask = mask(midH+1:end, 1:midW);
    q4Mask = mask(midH+1:end, midW+1:end);

    q1Lum = luminance(1:midH, 1:midW);
    q2Lum = luminance(1:midH, midW+1:end);
    q3Lum = luminance(midH+1:end, 1:midW);
    q4Lum = luminance(midH+1:end, midW+1:end);

    qMeans = [];
    if any(q1Mask(:)), qMeans(end+1) = mean(q1Lum(q1Mask)); end %#ok<AGROW>
    if any(q2Mask(:)), qMeans(end+1) = mean(q2Lum(q2Mask)); end %#ok<AGROW>
    if any(q3Mask(:)), qMeans(end+1) = mean(q3Lum(q3Mask)); end %#ok<AGROW>
    if any(q4Mask(:)), qMeans(end+1) = mean(q4Lum(q4Mask)); end %#ok<AGROW>

    if numel(qMeans) >= 2
        qRange = max(qMeans) - min(qMeans);
        uniformity = max(0.0, min(1.0, 1.0 - (qRange / max(1.0, mean(qMeans)))));
    else
        uniformity = 1.0;
    end

    % Format output
    meanBrightness = round(meanBrightness, 2);
    uniformity = round(uniformity, 3);
    
    exposureStats = struct();
    exposureStats.underexposedPercent = round(underexposedPercent, 2);
    exposureStats.overexposedPercent  = round(overexposedPercent, 2);
    exposureStats.medianBrightness    = round(medianBrightness, 2);
    exposureStats.stdBrightness       = round(stdBrightness, 2);
    exposureStats.quadrantMeans       = qMeans;
end
