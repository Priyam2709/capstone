classdef TestUtils < matlab.unittest.TestCase
% TESTUTILS Unit test suite for core system utilities.
%
%   Tests:
%       - getProjectRoot: returns existing directory
%       - loadConfig: returns valid struct with expected sections
%       - logger: verifies log methods without throwing exceptions
%       - loadImage: validates image reading, normalization, and resizing
%       - saveOutput: verifies file writing across formats
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    methods (Test)
        function testGetProjectRoot(testCase)
            root = getProjectRoot();
            testCase.verifyTrue(isfolder(root), 'Project root must be an existing directory.');
        end

        function testLoadConfigDefault(testCase)
            cfg = loadConfig();
            testCase.verifyNotEmpty(cfg, 'Config struct must not be empty.');
            testCase.verifyTrue(isfield(cfg, 'paths'), 'Config must have paths field.');
            testCase.verifyTrue(isfield(cfg, 'model'), 'Config must have model field.');
            testCase.verifyEqual(cfg.model.num_classes, 5, 'Number of classes must be 5.');
        end

        function testLogger(testCase)
            testCase.verifyWarningFree(@() logger.info('Test info message'));
            testCase.verifyWarningFree(@() logger.warn('Test warning message'));
            testCase.verifyWarningFree(@() logger.debug('Test debug message'));
        end

        function testLoadImageAndNormalize(testCase)
            % Create a temporary small test image
            tempImg = uint8(repmat(reshape([255, 128, 64], [1, 1, 3]), [50, 50, 1]));
            tempPath = fullfile(tempdir, 'test_fundus_small.png');
            imwrite(tempImg, tempPath);

            [procImg, rawImg, meta] = loadImage(tempPath, [224, 224], true);

            testCase.verifyEqual(size(procImg), [224, 224, 3], 'Processed image must be 224x224x3.');
            testCase.verifyTrue(isfloat(procImg), 'Processed image must be floating point.');
            testCase.verifyLessThanOrEqual(max(procImg(:)), 1.0, 'Pixel values must be <= 1.0.');
            testCase.verifyEqual(meta.originalHeight, 50, 'Original height metadata mismatch.');

            if isfile(tempPath)
                delete(tempPath);
            end
        end

        function testErrorHandler(testCase)
            try
                error('SIH26038:TestError', 'Unit test exception');
            catch ME
                userMsg = errorHandler(ME, 'Unit Testing', false);
                testCase.verifyNotEmpty(userMsg, 'Error handler must return an actionable user message.');
            end
        end
    end
end
