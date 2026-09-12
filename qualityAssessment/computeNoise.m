function [noiseStd, snrDb] = computeNoise(grayImg, mask)
% COMPUTENOISE Estimates high-frequency additive sensor noise and Signal-to-Noise Ratio.
%
%   noiseStd = computeNoise(grayImg)
%   [noiseStd, snrDb] = computeNoise(grayImg, mask)
%
%   Inputs:
%       grayImg  - Grayscale or green-channel fundus image array [0, 255].
%       mask     - (Optional) Binary mask of foreground retinal tissue.
%
%   Outputs:
%       noiseStd - Estimated standard deviation of zero-mean additive Gaussian noise.
%                  Low values (<12) indicate clean optical acquisition;
%                  high values (>25) indicate sensor thermal/high-ISO grain.
%       snrDb    - Estimated Signal-to-Noise Ratio in decibels (dB).
%
%   Algorithm:
%       Implements the fast noise variance estimation method (J. Immerkaer, 1996),
%       using a 3x3 difference operator evaluated specifically on homogenous retinal regions
%       to prevent edge and vessel responses from inflating the noise estimate.
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

    % 2. 3x3 Immerkaer Noise Mask
    N = [  1, -2,  1; ...
          -2,  4, -2; ...
           1, -2,  1 ];

    convResp = conv2(I, N, 'same');

    % 3. Exclude strong edges (retinal blood vessels and optic disc rim)
    % by filtering out high-magnitude gradient responses
    sobelGrad = imgradient(I);
    edgeThreshold = prctile(sobelGrad(mask), 65); % Retain smoother 65% of tissue
    
    flatRegionMask = mask & (sobelGrad <= edgeThreshold);
    validResiduals = abs(convResp(flatRegionMask));

    if ~isempty(validResiduals) && numel(validResiduals) > 100
        % Normalization factor for 3x3 Immerkaer filter: sqrt(pi/2) / 6
        noiseStd = sqrt(pi / 2.0) * mean(validResiduals) / 6.0;
    else
        noiseStd = 0.0;
    end

    % 4. Estimate Signal-to-Noise Ratio (SNR) in dB
    retinalSignal = I(mask);
    if ~isempty(retinalSignal) && noiseStd > 0
        meanSignal = mean(retinalSignal);
        snrDb = 20 * log10(max(1.0, meanSignal) / noiseStd);
    else
        snrDb = 40.0;
    end

    noiseStd = round(noiseStd, 2);
    snrDb = round(snrDb, 2);
end
