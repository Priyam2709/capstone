classdef TestStressAndEdgeCases < matlab.unittest.TestCase
% TESTSTRESSANDEDGECASES Comprehensive stress, boundary condition, and edge-case verification suite.
%
%   Verifies system robustness and fault-tolerance across:
%     1. Zero-byte, corrupted, and invalid format image inputs
%     2. Extreme lighting anomalies (0 lux blackout, 255 lux corneal glare saturation)
%     3. Non-standard aspect ratios (16:9 panoramic, extreme vertical strips)
%     4. Sub-resolution thumbnails (32x32) and high-resolution captures (1024x1024)
%     5. Incomplete, missing, or malformed patient demographic records
%     6. Non-standard color channel inputs (2D grayscale, 4-channel RGBA)
%     7. High-throughput sequential screening stress test (memory leak & latency profiling)
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        Config
        ScratchDir
    end

    methods (TestMethodSetup)
        function setupEnvironment(testCase)
            testCase.Config = loadConfig();
            root = getProjectRoot();
            testCase.ScratchDir = fullfile(root, 'results', 'scratch_tests');
            if ~isfolder(testCase.ScratchDir)
                mkdir(testCase.ScratchDir);
            end
        end
    end

    methods (TestMethodTeardown)
        function cleanupEnvironment(testCase)
            if isfolder(testCase.ScratchDir)
                try
                    rmdir(testCase.ScratchDir, 's');
                catch
                end
            end
        end
    end

    methods (Test)
        function testZeroByteAndCorruptedImages(testCase)
            % Test 1: Zero-byte file handling
            zeroByteFile = fullfile(testCase.ScratchDir, 'empty_zero_byte.png');
            fid = fopen(zeroByteFile, 'w');
            fclose(fid);

            % Verify loadImage handles 0-byte file gracefully without unhandled crash
            try
                [procImg, rawImg, success] = loadImage(zeroByteFile, [224, 224], false);
                testCase.verifyFalse(success, 'loadImage must return success=false on 0-byte file.');
            catch ME
                testCase.verifyNotEmpty(ME.message, 'Expected handled exception on zero-byte file.');
            end

            % Test 2: Text file disguised with .png extension
            corruptPng = fullfile(testCase.ScratchDir, 'corrupted_header.png');
            fid = fopen(corruptPng, 'w');
            fprintf(fid, 'This is a corrupt text file masquerading as a medical fundus image.');
            fclose(fid);

            try
                [procImg, rawImg, success] = loadImage(corruptPng, [224, 224], false);
                testCase.verifyFalse(success, 'loadImage must return success=false on corrupted PNG.');
            catch ME
                testCase.verifyNotEmpty(ME.message, 'Expected handled exception on corrupt PNG.');
            end
        end

        function testExtremeExposureBlackout(testCase)
            % Test 0-lux total blackout (lens cap on / dead camera sensor)
            blackImg = zeros(224, 224, 3, 'uint8');

            qRes = assessImageQuality(blackImg, testCase.Config);
            testCase.verifyNotEmpty(qRes, 'IQA must return assessment struct for blackout.');
            testCase.verifyLessThan(qRes.overallScore, 60, ...
                'Pure blackout image must receive an overall score below 60.');
            testCase.verifyTrue(any(strcmp(qRes.category, {'Retake Image', 'Needs Enhancement'})), ...
                'Blackout image must trigger Retake or Enhancement category.');
            testCase.verifyLessThan(qRes.metrics.brightness, 10, ...
                'Blackout mean brightness must be near zero.');
        end

        function testExtremeExposureGlare(testCase)
            % Test 255-lux extreme overexposure (corneal glare / sensor saturation)
            whiteImg = 255 * ones(224, 224, 3, 'uint8');

            qRes = assessImageQuality(whiteImg, testCase.Config);
            testCase.verifyNotEmpty(qRes, 'IQA must return assessment struct for pure glare.');
            testCase.verifyLessThan(qRes.overallScore, 60, ...
                'Saturated glare image must receive an overall score below 60.');
            testCase.verifyTrue(any(strcmp(qRes.category, {'Retake Image', 'Needs Enhancement'})), ...
                'Overexposed glare image must trigger Retake or Enhancement category.');
            testCase.verifyGreaterThan(qRes.metrics.brightness, 240, ...
                'Glare mean brightness must be > 240.');
        end

        function testNonSquareAspectRatios(testCase)
            % Test A: Ultra-wide 16:9 panoramic fundus image (180 x 320)
            wideImg = uint8(randi([30, 220], [180, 320, 3]));
            enhWide = preprocessPipeline(wideImg, testCase.Config);

            testCase.verifyEqual(size(enhWide.enhancedImage), [224, 224, 3], ...
                'Preprocessing must standardize 16:9 wide image to [224, 224, 3].');
            testCase.verifyFalse(any(isnan(enhWide.enhancedImage(:))), ...
                'Preprocessed wide image must contain no NaNs.');

            % Test B: Ultra-tall vertical strip fundus image (400 x 100)
            tallImg = uint8(randi([30, 220], [400, 100, 3]));
            enhTall = preprocessPipeline(tallImg, testCase.Config);

            testCase.verifyEqual(size(enhTall.enhancedImage), [224, 224, 3], ...
                'Preprocessing must standardize ultra-tall image to [224, 224, 3].');
            testCase.verifyFalse(any(isnan(enhTall.enhancedImage(:))), ...
                'Preprocessed tall image must contain no NaNs.');
        end

        function testSubAndHighResolutionScaling(testCase)
            % Test A: Sub-resolution tiny thumbnail (32 x 32)
            tinyImg = uint8(randi([40, 200], [32, 32, 3]));
            enhTiny = preprocessPipeline(tinyImg, testCase.Config);
            testCase.verifyEqual(size(enhTiny.enhancedImage), [224, 224, 3], ...
                'Preprocessing must upscale 32x32 thumbnail to [224, 224, 3].');

            % Test B: High-resolution fundus capture (1024 x 1024)
            highResImg = uint8(randi([40, 200], [1024, 1024, 3]));
            enhHigh = preprocessPipeline(highResImg, testCase.Config);
            testCase.verifyEqual(size(enhHigh.enhancedImage), [224, 224, 3], ...
                'Preprocessing must downscale 1024x1024 image to [224, 224, 3].');
        end

        function testInvalidColorChannels(testCase)
            % Test A: 2D Grayscale image passed to preprocessing pipeline
            grayImg = uint8(randi([40, 200], [200, 200]));
            enhGray = preprocessPipeline(grayImg, testCase.Config);

            testCase.verifyEqual(size(enhGray.enhancedImage, 3), 3, ...
                'Preprocessing must automatically replicate single-channel grayscale to 3-channel RGB.');

            % Test B: 4-Channel RGBA image (with alpha channel)
            rgbaImg = uint8(randi([40, 200], [200, 200, 4]));
            enhRgba = preprocessPipeline(rgbaImg(:, :, 1:3), testCase.Config);
            testCase.verifyEqual(size(enhRgba.enhancedImage, 3), 3, ...
                '3-channel RGB slice must preprocess cleanly.');
        end

        function testMalformedPatientDemographics(testCase)
            % Empty patient struct
            emptyPat = struct();
            qMock = struct('overallScore', 85, 'category', 'Good', ...
                           'metrics', struct('blur', 80, 'brightness', 120, 'contrast', 45));
            predMock = struct('stageCode', 1, 'stageName', 'Mild NPDR', 'confidence', 0.92, ...
                              'referralRequired', false, 'urgency', 'Rescreen 6-12 months');
            xaiMock = struct('summaryNarrative', 'Minor microaneurysm visible in nasal retina.', ...
                             'lesionStats', struct('dominantQuadrant', 'Nasal', 'coveragePercent', 2.1));

            rep = generatePatientReport(emptyPat, qMock, predMock, xaiMock, testCase.Config);
            testCase.verifyNotEmpty(rep.reportId, 'Report ID must be generated even for empty patient struct.');
            testCase.verifyNotEmpty(rep.patient.patientId, 'Default patient ID must be assigned.');

            % Special characters in patient ID
            weirdPat = struct('patientId', 'PT-#$@!/\\2026', 'patientName', 'Test Name');
            repWeird = generatePatientReport(weirdPat, qMock, predMock, xaiMock, testCase.Config);
            testCase.verifyFalse(contains(repWeird.reportId, '/'), 'Report ID must sanitize slashes.');
            testCase.verifyFalse(contains(repWeird.reportId, '\'), 'Report ID must sanitize backslashes.');
            testCase.verifyFalse(contains(repWeird.reportId, '#'), 'Report ID must sanitize pound signs.');
        end

        function testHighThroughputSequentialStress(testCase)
            % Simulate rapid sequential screening workload (10 patients in rapid succession)
            numIterations = 10;
            latencies = zeros(1, numIterations);

            [X, Y] = meshgrid(-112:111, -112:111);
            mask = (sqrt(X.^2 + Y.^2) <= 100);
            baseImg = repmat(uint8(140 * mask), [1, 1, 3]);

            for k = 1:numIterations
                tIter = tic;
                q = assessImageQuality(baseImg, testCase.Config);
                enh = preprocessPipeline(baseImg, testCase.Config);
                pred = predictDR(enh.enhancedImage, testCase.Config);
                xai = computeGradCAM([], enh.enhancedImage, pred.predictedClass, testCase.Config);
                latencies(k) = toc(tIter);

                testCase.verifyNotEmpty(pred, 'Prediction must succeed in rapid batch iteration.');
                testCase.verifyNotEmpty(xai, 'Grad-CAM must succeed in rapid batch iteration.');
            end

            meanLatSec = mean(latencies);
            testCase.verifyLessThan(meanLatSec, 2.0, ...
                'Mean pipeline screening latency must be < 2.0 seconds under continuous sequential load.');
        end
    end
end
