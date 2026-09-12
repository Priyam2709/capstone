function qualityReport = assessImageQuality(imgOrPath, config)
% ASSESSIMAGEQUALITY Independent clinical quality gatekeeper for retinal fundus images.
%
%   qualityReport = assessImageQuality(imgOrPath)
%   qualityReport = assessImageQuality(imgOrPath, config)
%
%   Evaluates:
%       - Blur (Laplacian variance on masked retinal field)
%       - Brightness (Mean retinal luminance & 4-quadrant illumination uniformity)
%       - Contrast (RMS contrast & effective dynamic range)
%       - Noise (Immerkaer high-frequency sensor noise & SNR in dB)
%       - Sharpness (Tenengrad edge gradient energy & edge density)
%
%   Outputs:
%       qualityReport - Struct containing:
%           .overallScore       - Composite quality index in [0, 100]
%           .category           - 'Good', 'Needs Enhancement', or 'Retake Image'
%           .metrics            - Raw clinical metric values:
%               .blur           - Laplacian variance
%               .brightness     - Mean luminance [0, 255]
%               .uniformity     - Quadrant uniformity [0, 1]
%               .contrast       - RMS contrast
%               .dynamicRange   - 95th - 5th percentile intensity spread
%               .noise          - Estimated Gaussian noise standard deviation
%               .snrDb          - Signal-to-Noise Ratio (dB)
%               .sharpness      - Tenengrad gradient energy
%               .edgeDensity    - Significant edge proportion
%           .subScores          - Calibrated sub-scores in [0, 100] for each metric
%           .recommendation     - Actionable guidance for rural health workers
%           .isAcceptable       - Boolean flag (true if screening inference can proceed)
%           .exposureDefects    - Percentage of underexposed or glare pixels
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    % 1. Handle Input (File path or Image array)
    if ischar(imgOrPath) || isstring(imgOrPath)
        imgPath = char(imgOrPath);
        if ~isfile(imgPath)
            try
                projectRoot = getProjectRoot();
                candidate = fullfile(projectRoot, imgPath);
                if isfile(candidate), imgPath = candidate; end
            catch
                % Keep original
            end
        end
        rawImg = imread(imgPath);
    elseif isnumeric(imgOrPath) || islogical(imgOrPath)
        rawImg = imgOrPath;
    else
        error('SIH26038:InvalidInput', 'imgOrPath must be an image array or file path string.');
    end

    if isempty(rawImg)
        error('SIH26038:EmptyImage', 'Retinal image cannot be empty.');
    end

    % 2. Normalize and format image
    if isfloat(rawImg) && max(rawImg(:)) <= 1.0
        imgUint8 = im2uint8(rawImg);
    else
        imgUint8 = uint8(rawImg);
    end

    % Extract green channel (contains highest diagnostic vascular contrast)
    if size(imgUint8, 3) == 3
        greenChannel = imgUint8(:, :, 2);
    else
        greenChannel = imgUint8;
    end

    % Extract foreground retinal mask
    gray = rgb2gray(imgUint8);
    rawMask = gray > 15;
    se = strel('disk', 6);
    retinaMask = imerode(rawMask, se);

    % Fallback if mask is degenerated
    if sum(retinaMask(:)) < 1000
        retinaMask = true(size(gray));
    end

    % 3. Extract Default Thresholds and Weights if config not provided
    if nargin < 2 || isempty(config)
        th = struct( ...
            'blur_min_laplacian_variance', 100.0, ...
            'brightness_min', 40.0, ...
            'brightness_max', 215.0, ...
            'contrast_min_rms', 25.0, ...
            'noise_max_std', 20.0, ...
            'sharpness_min_tenengrad', 150.0);
        weights = struct('blur', 0.25, 'brightness', 0.20, 'contrast', 0.20, ...
                         'noise', 0.15, 'sharpness', 0.20);
        scoreThresholds = struct('good', 75.0, 'needs_enhancement', 50.0);
    else
        th = config.quality_assessment.thresholds;
        weights = config.quality_assessment.weights;
        scoreThresholds = config.quality_assessment.score_thresholds;
    end

    % 4. Compute 5 Core Quality Metrics
    [blurMetric, ~] = computeBlur(greenChannel, retinaMask);
    [brightnessMetric, uniformity, expStats] = computeBrightness(imgUint8, retinaMask);
    [contrastMetric, michelson, dynRange] = computeContrast(greenChannel, retinaMask);
    [noiseMetric, snrDb] = computeNoise(greenChannel, retinaMask);
    [sharpnessMetric, edgeDensity] = computeSharpness(greenChannel, retinaMask);

    metrics = struct();
    metrics.blur = blurMetric;
    metrics.brightness = brightnessMetric;
    metrics.uniformity = uniformity;
    metrics.contrast = contrastMetric;
    metrics.michelsonContrast = michelson;
    metrics.dynamicRange = dynRange;
    metrics.noise = noiseMetric;
    metrics.snrDb = snrDb;
    metrics.sharpness = sharpnessMetric;
    metrics.edgeDensity = edgeDensity;

    % 5. Calibrate Individual Metric Sub-Scores (0 to 100)
    % A. Blur Sub-score (Sigmoidal curve around threshold)
    sBlur = min(100.0, max(0.0, (blurMetric / th.blur_min_laplacian_variance) * 85.0));
    if blurMetric >= th.blur_min_laplacian_variance
        sBlur = min(100.0, 85.0 + 15.0 * (1.0 - exp(-(blurMetric - th.blur_min_laplacian_variance) / 80.0)));
    end

    % B. Brightness Sub-score (Penalizes both underexposure < 40 and overexposure > 215)
    if brightnessMetric < th.brightness_min
        sBrightness = max(0.0, (brightnessMetric / th.brightness_min) * 50.0);
    elseif brightnessMetric > th.brightness_max
        sBrightness = max(0.0, 100.0 - ((brightnessMetric - th.brightness_max) / 40.0) * 60.0);
    else
        % Optimal band (80 - 150)
        idealCenter = 115.0;
        dev = abs(brightnessMetric - idealCenter) / 75.0;
        sBrightness = min(100.0, max(60.0, 95.0 - 25.0 * dev + 10.0 * uniformity));
    end

    % C. Contrast Sub-score
    sContrast = min(100.0, max(0.0, (contrastMetric / th.contrast_min_rms) * 80.0));
    if contrastMetric >= th.contrast_min_rms
        sContrast = min(100.0, 80.0 + 20.0 * min(1.0, (contrastMetric - th.contrast_min_rms) / 25.0));
    end

    % D. Noise Sub-score (Lower noise is better)
    if noiseMetric <= 5.0
        sNoise = 100.0;
    else
        sNoise = max(0.0, 100.0 - ((noiseMetric - 5.0) / (th.noise_max_std - 5.0)) * 55.0);
    end

    % E. Sharpness Sub-score
    sSharpness = min(100.0, max(0.0, (sharpnessMetric / th.sharpness_min_tenengrad) * 85.0));
    if sharpnessMetric >= th.sharpness_min_tenengrad
        sSharpness = min(100.0, 85.0 + 15.0 * min(1.0, (sharpnessMetric - th.sharpness_min_tenengrad) / 100.0));
    end

    subScores = struct();
    subScores.blur       = round(sBlur, 1);
    subScores.brightness = round(sBrightness, 1);
    subScores.contrast   = round(sContrast, 1);
    subScores.noise      = round(sNoise, 1);
    subScores.sharpness  = round(sSharpness, 1);

    % 6. Compute Weighted Overall Quality Score
    overallScore = weights.blur       * subScores.blur + ...
                   weights.brightness * subScores.brightness + ...
                   weights.contrast   * subScores.contrast + ...
                   weights.noise      * subScores.noise + ...
                   weights.sharpness  * subScores.sharpness;
    overallScore = round(overallScore, 1);

    % 7. Categorization & Actionable Clinical Recommendation
    % Critical defect gates
    isCriticalBlur = (sBlur < 35.0) || (blurMetric < 35.0);
    isCriticalDark = (brightnessMetric < 28.0) || (expStats.underexposedPercent > 50.0);
    isCriticalGlare = (brightnessMetric > 225.0) || (expStats.overexposedPercent > 35.0);

    if (overallScore >= scoreThresholds.good) && ~isCriticalBlur && ~isCriticalDark && ~isCriticalGlare
        category = 'Good';
        recommendation = 'Image quality is excellent. Retinal microvasculature is crisp and clear. Suitable for direct AI screening.';
        isAcceptable = true;
    elseif (overallScore >= scoreThresholds.needs_enhancement) && ~isCriticalBlur && ~isCriticalDark
        category = 'Needs Enhancement';
        if sContrast < 60.0
            recommendation = 'Moderate contrast deficit detected. Retinal enhancement (CLAHE) recommended prior to classification.';
        elseif sBrightness < 65.0
            recommendation = 'Sub-optimal illumination detected. Retinal background leveling applied before classification.';
        else
            recommendation = 'Image quality is acceptable with enhancement. Proceeding through auto-preprocessing pipeline.';
        end
        isAcceptable = true;
    else
        category = 'Retake Image';
        isAcceptable = false;
        if isCriticalBlur
            recommendation = 'RETAKE REQUIRED: Severe motion blur or defocus detected. Instruct patient to fixate on internal target, steady camera, and recapture.';
        elseif isCriticalDark
            recommendation = 'RETAKE REQUIRED: Severe retinal underexposure. Ensure room is dimmed or increase flash intensity setting.';
        elseif isCriticalGlare
            recommendation = 'RETAKE REQUIRED: Corneal reflection or flash glare artifact. Re-align camera optical axis with patient pupil.';
        else
            recommendation = 'RETAKE REQUIRED: Overall composite image quality is insufficient for reliable diagnostic screening. Recapture image.';
        end
    end

    % 8. Assemble Output Struct
    qualityReport = struct();
    qualityReport.overallScore = overallScore;
    qualityReport.category = category;
    qualityReport.metrics = metrics;
    qualityReport.subScores = subScores;
    qualityReport.recommendation = recommendation;
    qualityReport.isAcceptable = isAcceptable;
    qualityReport.exposureDefects = expStats;

    % Optional logging
    try
        logger.info('IQA Evaluated: Score=%.1f/100 | Category: %s | Action: %s', ...
                    overallScore, category, isAcceptable);
    catch
        % Standalone execution without logger initialized
    end
end
