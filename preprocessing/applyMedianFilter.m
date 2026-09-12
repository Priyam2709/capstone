function denoised = applyMedianFilter(img, kernelSize)
% APPLYMEDIANFILTER Denoises fundus images using median filtering.
%
%   denoised = applyMedianFilter(img)
%   denoised = applyMedianFilter(img, kernelSize)
%
%   Inputs:
%       img        - RGB or grayscale retinal image array (uint8 or double).
%       kernelSize - (Optional) 2-element vector [M, N]. Defaults to [3, 3].
%
%   Outputs:
%       denoised   - Filtered image with salt-and-pepper and sensor impulse noise suppressed.
%
%   Clinical Rationale:
%       Eliminates isolated dead camera pixels and sensor grain that could otherwise
%       be falsely flagged as microaneurysms by deep learning feature extractors.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(kernelSize)
        kernelSize = [3, 3];
    end

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    if size(imgUint8, 3) == 3
        denoised = zeros(size(imgUint8), 'like', imgUint8);
        for c = 1:3
            denoised(:, :, c) = medfilt2(imgUint8(:, :, c), kernelSize);
        end
    else
        denoised = medfilt2(imgUint8, kernelSize);
    end
end
