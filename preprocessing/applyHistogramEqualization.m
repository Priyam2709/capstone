function equalizedImg = applyHistogramEqualization(img, blendWeight)
% APPLYHISTOGRAMEQUALIZATION Retinal-adapted luminance histogram equalization.
%
%   equalizedImg = applyHistogramEqualization(img)
%   equalizedImg = applyHistogramEqualization(img, blendWeight)
%
%   Inputs:
%       img         - RGB or grayscale fundus image (uint8 or double).
%       blendWeight - (Optional) Blending factor between original and equalized luminance [0, 1].
%                     Default: 0.40 (prevents unnatural wash-out and excessive noise amplification).
%
%   Outputs:
%       equalizedImg - Luminance-balanced and contrast-equalized fundus image (uint8).
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(blendWeight)
        blendWeight = 0.40;
    end

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    if size(imgUint8, 3) == 3
        % Convert to HSV to equalize Value (V) or L*a*b* Luminance
        labImg = rgb2lab(imgUint8);
        L = labImg(:, :, 1) / 100.0; % Normalize to [0, 1]

        % Mask foreground retina
        gray = rgb2gray(imgUint8);
        mask = gray > 15;

        % Perform histogram equalization on luminance
        L_eq = histeq(L);

        % Controlled linear blend to preserve natural clinical coloration
        L_blended = (1 - blendWeight) * L + blendWeight * L_eq;
        
        labImg(:, :, 1) = L_blended * 100.0;
        equalizedImg = lab2rgb(labImg);
        equalizedImg = im2uint8(max(0.0, min(1.0, equalizedImg)));
    else
        % Grayscale
        eq = histeq(imgUint8);
        equalizedImg = uint8((1 - blendWeight) * double(imgUint8) + blendWeight * double(eq));
    end
end
