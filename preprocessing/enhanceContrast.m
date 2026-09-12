function enhancedImg = enhanceContrast(img, gammaVal, clipPercentiles)
% ENHANCECONTRAST Retinal dynamic range stretching and adaptive gamma correction.
%
%   enhancedImg = enhanceContrast(img)
%   enhancedImg = enhanceContrast(img, gammaVal)
%   enhancedImg = enhanceContrast(img, gammaVal, clipPercentiles)
%
%   Inputs:
%       img             - RGB or grayscale retinal fundus image (uint8 or double).
%       gammaVal        - (Optional) Gamma correction exponent (Default: 1.15).
%                         Values >1 stretch darker microvascular detail.
%       clipPercentiles - (Optional) [lowPercentile, highPercentile] for contrast stretch (Default: [1.0, 99.0]).
%
%   Outputs:
%       enhancedImg     - Contrast-stretched RGB or grayscale image (uint8).
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(gammaVal)
        gammaVal = 1.15;
    end

    if nargin < 3 || isempty(clipPercentiles)
        clipPercentiles = [1.0, 99.0];
    end

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    % Extract foreground retinal mask
    gray = rgb2gray(imgUint8);
    mask = gray > 15;

    if size(imgUint8, 3) == 3
        % Work in L*a*b* color space to preserve chromaticity of blood vessels
        labImg = rgb2lab(imgUint8);
        L = labImg(:, :, 1); % [0, 100]

        retinalL = L(mask);
        if ~isempty(retinalL) && numel(retinalL) > 100
            lowVal = prctile(retinalL, clipPercentiles(1));
            highVal = prctile(retinalL, clipPercentiles(2));
            
            if highVal > lowVal
                % Linear contrast stretch on Luminance
                L_stretched = (L - lowVal) / (highVal - lowVal) * 100.0;
                L_stretched = max(0.0, min(100.0, L_stretched));
                
                % Gamma adjustment
                L_norm = L_stretched / 100.0;
                L_gamma = (L_norm .^ (1.0 / gammaVal)) * 100.0;
                
                labImg(:, :, 1) = L_gamma;
                enhancedImg = lab2rgb(labImg);
                enhancedImg = im2uint8(max(0.0, min(1.0, enhancedImg)));
            else
                enhancedImg = imgUint8;
            end
        else
            enhancedImg = imgUint8;
        end
    else
        % Grayscale
        I = double(imgUint8);
        retinalI = I(mask);
        if ~isempty(retinalI)
            lowVal = prctile(retinalI, clipPercentiles(1));
            highVal = prctile(retinalI, clipPercentiles(2));
            if highVal > lowVal
                I_stretched = (I - lowVal) / (highVal - lowVal) * 255.0;
                I_stretched = max(0.0, min(255.0, I_stretched));
                I_gamma = ((I_stretched / 255.0) .^ (1.0 / gammaVal)) * 255.0;
                enhancedImg = uint8(I_gamma);
            else
                enhancedImg = imgUint8;
            end
        else
            enhancedImg = imgUint8;
        end
    end
end
