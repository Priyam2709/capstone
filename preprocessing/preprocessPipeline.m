function enhancedResult = preprocessPipeline(img, config, enabledStages)
% PREPROCESSPIPELINE Complete 6-stage retinal image enhancement pipeline for DR screening.
%
%   enhancedResult = preprocessPipeline(img)
%   enhancedResult = preprocessPipeline(img, config)
%   enhancedResult = preprocessPipeline(img, config, enabledStages)
%
%   Pipeline Sequence:
%       1. Noise Reduction      : Median filtering removes sensor impulse/dead pixels.
%       2. Illumination Leveling: Compensates for uneven camera flash and vignetting.
%       3. CLAHE                : Enhances fine microaneurysms & hemorrhages via L*a*b*.
%       4. Histogram Balancing  : Equalizes broad tonal dynamics without color shift.
%       5. Contrast Enhancement : Dynamic range percentile stretching & gamma correction.
%       6. Edge-Preserving Filter: Suppresses residual high-ISO noise.
%
%   Inputs:
%       img           - Raw RGB retinal fundus image array (uint8 or double).
%       config        - (Optional) System configuration struct from loadConfig().
%       enabledStages - (Optional) Cell array of stages to run (Default: all stages).
%
%   Outputs:
%       enhancedResult - Struct containing:
%           .enhancedImage      - Enhanced 3-channel RGB image (uint8).
%           .originalImage      - Formatted original RGB image.
%           .intermediateImages - Struct of outputs after each pipeline stage.
%           .metrics            - Quantitative metrics struct (PSNR, SSIM, CII, Entropy, EME).
%           .pipelineSteps      - Cell array of stages executed.
%           .psnrImprovement    - PSNR value (dB).
%           .ssimIndex          - SSIM index.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(config)
        try
            config = loadConfig();
        catch
            config = [];
        end
    end

    if isempty(img)
        error('SIH26038:EmptyImage', 'Input fundus image cannot be empty.');
    end

    if isfloat(img) && max(img(:)) <= 1.0
        imgUint8 = im2uint8(img);
    else
        imgUint8 = uint8(img);
    end

    if nargin < 3 || isempty(enabledStages)
        if ~isempty(config) && isfield(config, 'preprocessing') && isfield(config.preprocessing, 'pipeline')
            enabledStages = config.preprocessing.pipeline;
        else
            enabledStages = {'median_filter', 'illumination_correction', ...
                             'clahe', 'histogram_equalization', 'contrast_enhancement'};
        end
    end

    try
        logger.debug('Executing retinal preprocessing pipeline (%d stages)...', numel(enabledStages));
    catch
    end

    intermediate = struct();
    intermediate.raw = imgUint8;
    currentImg = imgUint8;

    % 1. Stage: Median Filtering (Denoising)
    if any(strcmpi(enabledStages, 'median_filter'))
        kernelSize = [3, 3];
        if ~isempty(config) && isfield(config.preprocessing, 'median_filter_kernel')
            kernelSize = config.preprocessing.median_filter_kernel;
        end
        currentImg = applyMedianFilter(currentImg, kernelSize);
        intermediate.denoised = currentImg;
    end

    % 2. Stage: Illumination Correction (Brightness Correction)
    if any(strcmpi(enabledStages, 'illumination_correction'))
        currentImg = correctIllumination(currentImg);
        intermediate.illuminationCorrected = currentImg;
    end

    % 3. Stage: CLAHE (Contrast-Limited Adaptive Histogram Equalization)
    if any(strcmpi(enabledStages, 'clahe'))
        clipLimit = 0.02;
        gridSize = [8, 8];
        if ~isempty(config) && isfield(config.preprocessing, 'clahe_clip_limit')
            clipLimit = config.preprocessing.clahe_clip_limit;
            gridSize  = config.preprocessing.clahe_tile_grid_size;
        end
        currentImg = applyCLAHE(currentImg, clipLimit, gridSize, 'Lab');
        intermediate.claheEnhanced = currentImg;
    end

    % 4. Stage: Histogram Equalization (Luminance Balancing)
    if any(strcmpi(enabledStages, 'histogram_equalization'))
        currentImg = applyHistogramEqualization(currentImg, 0.35);
        intermediate.histogramEqualized = currentImg;
    end

    % 5. Stage: Contrast Enhancement (Percentile Stretch & Gamma)
    if any(strcmpi(enabledStages, 'contrast_enhancement')) || any(strcmpi(enabledStages, 'contrast_stretching'))
        gammaVal = 1.15;
        if ~isempty(config) && isfield(config.preprocessing, 'gamma_correction')
            gammaVal = config.preprocessing.gamma_correction;
        end
        currentImg = enhanceContrast(currentImg, gammaVal, [1.0, 99.0]);
        intermediate.contrastEnhanced = currentImg;
    end

    % 6. Stage: Fine Noise Reduction (Edge-Preserving Bilateral)
    if any(strcmpi(enabledStages, 'noise_reduction'))
        currentImg = reduceNoise(currentImg, 'bilateral');
        intermediate.noiseReduced = currentImg;
    end

    enhancedImg = currentImg;

    % 7. Quantitative Image Quality Assessment Metrics
    metrics = evaluateEnhancementMetrics(imgUint8, enhancedImg);

    % Assemble output struct
    enhancedResult = struct();
    enhancedResult.enhancedImage      = enhancedImg;
    enhancedResult.originalImage      = imgUint8;
    enhancedResult.intermediateImages = intermediate;
    enhancedResult.metrics            = metrics;
    enhancedResult.pipelineSteps      = enabledStages;
    enhancedResult.psnrImprovement    = metrics.psnrDb;
    enhancedResult.ssimIndex          = metrics.ssim;

    try
        logger.info('Retinal enhancement complete: PSNR=%.2f dB, SSIM=%.4f, CII=%.2f, EntropyGain=+%.3f', ...
                    metrics.psnrDb, metrics.ssim, metrics.cii, metrics.entropyGain);
    catch
    end
end
