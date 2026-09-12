function outImg = applyCLAHE(inImg, clipLimit, tileGridSize, colorMode)
% APPLYCLAHE Contrast-Limited Adaptive Histogram Equalization for fundus images.
%
%   outImg = applyCLAHE(inImg)
%   outImg = applyCLAHE(inImg, clipLimit)
%   outImg = applyCLAHE(inImg, clipLimit, tileGridSize)
%   outImg = applyCLAHE(inImg, clipLimit, tileGridSize, colorMode)
%
%   Inputs:
%       inImg        - RGB or grayscale retinal fundus image (uint8 or double).
%       clipLimit    - (Optional) Contrast threshold limit (Default: 0.02, or integer e.g. 2.0).
%       tileGridSize - (Optional) 2-element vector [M, N] contextual tiles (Default: [8, 8]).
%       colorMode    - (Optional) 'Lab' (Default) or 'GreenChannel'.
%
%   Outputs:
%       outImg       - CLAHE-enhanced RGB or grayscale image (uint8).
%
%   Clinical Rationale:
%       Enhancing the L* channel in CIELAB or the green channel selectively boosts
%       the visibility of subtle microaneurysms and intraretinal microvascular
%       abnormalities (IRMA) without colorimetric distortion.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(clipLimit)
        clipLimit = 0.02;
    elseif clipLimit > 1.0
        clipLimit = clipLimit / 100.0; % Convert percentage/integer factor (e.g. 2.0 -> 0.02)
    end

    if nargin < 3 || isempty(tileGridSize)
        tileGridSize = [8, 8];
    end

    if nargin < 4 || isempty(colorMode)
        colorMode = 'Lab';
    end

    if isfloat(inImg) && max(inImg(:)) <= 1.0
        imgUint8 = im2uint8(inImg);
    else
        imgUint8 = uint8(inImg);
    end

    if size(imgUint8, 3) == 3
        switch lower(colorMode)
            case 'lab'
                % CIELAB color space: Enhance L* (luminance) channel
                labImg = rgb2lab(imgUint8);
                L_norm = labImg(:, :, 1) / 100.0;
                
                L_enh = adapthisteq(L_norm, ...
                                    'ClipLimit', clipLimit, ...
                                    'NumTiles', tileGridSize, ...
                                    'Distribution', 'rayleigh');
                
                labImg(:, :, 1) = L_enh * 100.0;
                outImg = lab2rgb(labImg);
                outImg = im2uint8(max(0.0, min(1.0, outImg)));

            case 'greenchannel'
                % Green channel selective enhancement
                outImg = imgUint8;
                outImg(:, :, 2) = adapthisteq(imgUint8(:, :, 2), ...
                                              'ClipLimit', clipLimit, ...
                                              'NumTiles', tileGridSize, ...
                                              'Distribution', 'rayleigh');

            otherwise
                % Default to Lab
                labImg = rgb2lab(imgUint8);
                L_norm = labImg(:, :, 1) / 100.0;
                L_enh = adapthisteq(L_norm, 'ClipLimit', clipLimit, 'NumTiles', tileGridSize);
                labImg(:, :, 1) = L_enh * 100.0;
                outImg = im2uint8(lab2rgb(labImg));
        end
    else
        % Grayscale direct CLAHE
        outImg = adapthisteq(imgUint8, 'ClipLimit', clipLimit, 'NumTiles', tileGridSize);
    end
end
