function [annotatedImg, lesionStats] = segmentSalientLesions(fundusImg, heatmap, thresholdVal)
% SEGMENTSALIENTLESIONS Localizes and annotates focal lesion clusters from Grad-CAM.
%
%   [annotatedImg, lesionStats] = segmentSalientLesions(fundusImg, heatmap)
%   [annotatedImg, lesionStats] = segmentSalientLesions(fundusImg, heatmap, thresholdVal)
%
%   Inputs:
%       fundusImg    - RGB retinal fundus image (uint8 or double [0, 1]).
%       heatmap      - 2D normalized Grad-CAM saliency map in [0, 1].
%       thresholdVal - (Optional) Saliency activation threshold (Default: 0.55).
%
%   Outputs:
%       annotatedImg - RGB image with highlighted lesion contours and bounding boxes.
%       lesionStats  - Struct array containing:
%           .numClusters       - Total number of distinct focal lesion hotspots
%           .clusters          - Array of structs: [Centroid, BoundingBox, AreaPixels, Quadrant]
%           .coveragePercent   - Total salient area as percentage of retinal field
%           .dominantQuadrant  - Anatomical quadrant with highest activation density
%
%   Anatomical Quadrants:
%       - 'Central Macular Zone'
%       - 'Superior-Temporal Quadrant'
%       - 'Superior-Nasal Quadrant'
%       - 'Inferior-Temporal Quadrant'
%       - 'Inferior-Nasal Quadrant'
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 3 || isempty(thresholdVal)
        thresholdVal = 0.55;
    end

    if isfloat(fundusImg) && max(fundusImg(:)) <= 1.0
        imgUint8 = im2uint8(fundusImg);
    else
        imgUint8 = uint8(fundusImg);
    end

    [H, W, ~] = size(imgUint8);

    % Resize heatmap to match image dimensions if needed
    if size(heatmap, 1) ~= H || size(heatmap, 2) ~= W
        heatmap = imresize(heatmap, [H, W], 'bicubic');
    end
    heatmap = max(0.0, min(1.0, heatmap));

    % 1. Binary Saliency Mask of Salient Lesions
    binarySaliency = heatmap >= thresholdVal;
    
    % Morphological cleanup (remove isolated 1-pixel noise and fill micro-holes)
    se = strel('disk', 2);
    cleanMask = imclose(imopen(binarySaliency, se), se);

    % 2. Connected Component Analysis for Focal Hotspots
    cc = bwconncomp(cleanMask);
    props = regionprops(cc, 'BoundingBox', 'Centroid', 'Area', 'Eccentricity');

    annotatedImg = imgUint8;
    clusterList = [];
    quadrantCounts = containers.Map({'Central Macula', 'Superior-Temporal', ...
                                     'Superior-Nasal', 'Inferior-Temporal', ...
                                     'Inferior-Nasal'}, [0, 0, 0, 0, 0]);

    midX = W / 2.0;
    midY = H / 2.0;
    maculaRadius = 0.18 * min(H, W);

    % 3. Extract and Annotate Each Lesion Cluster
    for k = 1:numel(props)
        area = props(k).Area;
        if area < 15 % Ignore tiny specks
            continue;
        end

        cen = props(k).Centroid;
        bb  = props(k).BoundingBox;

        % Determine anatomical quadrant
        dx = cen(1) - midX;
        dy = cen(2) - midY;
        distFromCenter = sqrt(dx^2 + dy^2);

        if distFromCenter <= maculaRadius
            quad = 'Central Macula';
        elseif dx >= 0 && dy <= 0
            quad = 'Superior-Temporal';
        elseif dx < 0 && dy <= 0
            quad = 'Superior-Nasal';
        elseif dx >= 0 && dy > 0
            quad = 'Inferior-Temporal';
        else
            quad = 'Inferior-Nasal';
        end

        quadrantCounts(quad) = quadrantCounts(quad) + 1;

        cEntry = struct();
        cEntry.Centroid = round(cen, 1);
        cEntry.BoundingBox = round(bb, 1);
        cEntry.AreaPixels = area;
        cEntry.Quadrant = quad;
        clusterList = [clusterList; cEntry]; %#ok<AGROW>

        % Draw yellow/cyan bounding box overlay on annotated image
        rStart = max(1, round(bb(2)));
        rEnd   = min(H, round(bb(2) + bb(4)));
        cStart = max(1, round(bb(1)));
        cEnd   = min(W, round(bb(1) + bb(3)));

        % Draw box border (2 pixels thick)
        borderMask = false(H, W);
        borderMask(rStart:min(H, rStart+1), cStart:cEnd) = true;
        borderMask(max(1, rEnd-1):rEnd, cStart:cEnd) = true;
        borderMask(rStart:rEnd, cStart:min(W, cStart+1)) = true;
        borderMask(rStart:rEnd, max(1, cEnd-1):cEnd) = true;

        % Color border in bright yellow-green
        annotatedImg(cat(3, borderMask, false(H, W), false(H, W))) = 255; % R
        annotatedImg(cat(3, false(H, W), borderMask, false(H, W))) = 230; % G
        annotatedImg(cat(3, false(H, W), false(H, W), borderMask)) = 0;   % B
    end

    % 4. Identify Dominant Quadrant
    qKeys = quadrantCounts.keys;
    qVals = cell2mat(quadrantCounts.values);
    [maxVal, maxIdx] = max(qVals);
    if maxVal > 0
        dominantQuadrant = qKeys{maxIdx};
    else
        dominantQuadrant = 'Diffuse Non-Focal Attention';
    end

    % 5. Compute Coverage Metric
    retinaMask = rgb2gray(imgUint8) > 15;
    totalRetinalPixels = max(1, sum(retinaMask(:)));
    salientPixels = sum(cleanMask(:) & retinaMask(:));
    coveragePercent = (salientPixels / totalRetinalPixels) * 100.0;

    % 6. Assemble Output Struct
    lesionStats = struct();
    lesionStats.numClusters = numel(clusterList);
    lesionStats.clusters = clusterList;
    lesionStats.coveragePercent = round(coveragePercent, 2);
    lesionStats.dominantQuadrant = dominantQuadrant;
    lesionStats.salientMask = cleanMask;
end
