function denoisedImg = reduceNoise(img, method, param)
% REDUCENOISE Edge-preserving retinal noise reduction for portable fundus cameras.
%
%   denoisedImg = reduceNoise(img)
%   denoisedImg = reduceNoise(img, method)
%   denoisedImg = reduceNoise(img, method, param)
%
%   Inputs:
%       img    - RGB or grayscale fundus image (uint8 or double).
%       method - (Optional) 'bilateral' (Default), 'wiener', or 'guided'.
%       param  - (Optional) Tuning parameter (e.g., degree of smoothing).
%
%   Outputs:
%       denoisedImg - Noise-reduced fundus image preserving vascular micro-edges.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(method)
        method = 'bilateral';
    end

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    method = lower(char(method));

    switch method
        case 'bilateral'
            % Edge-preserving bilateral filter
            if nargin < 3 || isempty(param)
                spatialSigma = 2.0;
                intensitySigma = 0.15;
            else
                spatialSigma = param(1);
                intensitySigma = param(2);
            end
            try
                denoisedImg = imbilatfilt(imgUint8, intensitySigma, spatialSigma);
            catch
                % Fallback for older releases
                denoisedImg = imgaussfilt(imgUint8, 0.8);
            end

        case 'wiener'
            % Adaptive pixel-wise Wiener filtering
            if nargin < 3 || isempty(param)
                neighborhood = [3, 3];
            else
                neighborhood = param;
            end
            if size(imgUint8, 3) == 3
                denoisedImg = zeros(size(imgUint8), 'like', imgUint8);
                for c = 1:3
                    denoisedImg(:, :, c) = wiener2(imgUint8(:, :, c), neighborhood);
                end
            else
                denoisedImg = wiener2(imgUint8, neighborhood);
            end

        case 'guided'
            % Guided filter using green channel as guidance map
            if nargin < 3 || isempty(param)
                radius = 3;
                epsilon = 0.04;
            else
                radius = param(1);
                epsilon = param(2);
            end
            try
                if size(imgUint8, 3) == 3
                    guide = imgUint8(:, :, 2);
                    denoisedImg = imguidedfilter(imgUint8, guide, ...
                                                 'NeighborhoodSize', [radius, radius], ...
                                                 'DegreeOfSmoothing', epsilon);
                else
                    denoisedImg = imguidedfilter(imgUint8, ...
                                                 'NeighborhoodSize', [radius, radius], ...
                                                 'DegreeOfSmoothing', epsilon);
                end
            catch
                denoisedImg = imgaussfilt(imgUint8, 0.8);
            end

        otherwise
            denoisedImg = imgaussfilt(imgUint8, 0.8);
    end
end
