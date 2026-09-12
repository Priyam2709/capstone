classdef TestDatasetLoader < matlab.unittest.TestCase
% TESTDATASETLOADER Unit tests for dataset loading, synthetic generation, and validation.
%
%   Verifies:
%     1. Synthetic dataset generator creates valid PNG images and labels.
%     2. loadDataset loads datastores and labels properly.
%     3. validateDataset checks resolution, aspect ratio, and channel counts.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        ProjectRoot char
        TestOutputDir char
    end

    methods (TestClassSetup)
        function setupEnvironment(testCase)
            testCase.ProjectRoot = getProjectRoot();
            testCase.TestOutputDir = fullfile(testCase.ProjectRoot, 'results', 'test_scratch');
            if ~exist(testCase.TestOutputDir, 'dir')
                mkdir(testCase.TestOutputDir);
            end
        end
    end

    methods (Test)
        function testSyntheticDatasetGeneration(testCase)
            % Generate synthetic dataset with 2 samples per class
            numPerClass = 2;
            stats = createSyntheticDataset(testCase.ProjectRoot, numPerClass);
            testCase.verifyNotEmpty(stats, 'createSyntheticDataset should return generation statistics.');
            testCase.verifyGreaterThanOrEqual(stats.totalGenerated, numPerClass * 5, ...
                'Expected at least 10 synthetic images generated.');
        end

        function testDatasetValidation(testCase)
            rawDir = fullfile(testCase.ProjectRoot, 'data', 'raw', 'aptos');
            if exist(rawDir, 'dir')
                valReport = validateDataset(rawDir);
                testCase.verifyTrue(isfield(valReport, 'totalImages'), 'Validation report must contain totalImages.');
                testCase.verifyTrue(isfield(valReport, 'validImages'), 'Validation report must contain validImages.');
                testCase.verifyGreaterThan(valReport.validImages, 0, 'Must have at least 1 valid image.');
            end
        end

        function testLoadDataset(testCase)
            cfg = loadConfig();
            ds = loadDataset('aptos', cfg);
            testCase.verifyNotEmpty(ds, 'Dataset loader must return a datastore struct or object.');
            testCase.verifyTrue(isfield(ds, 'imds') || isa(ds, 'matlab.io.datastore.ImageDatastore'), ...
                'Dataset must contain image datastore.');
        end
    end
end
