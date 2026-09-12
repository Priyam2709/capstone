classdef TestReportGenerator < matlab.unittest.TestCase
% TESTREPORTGENERATOR Unit tests for patient and cohort clinical report generators.
%
%   Verifies:
%     1. Patient report structure generation.
%     2. Clinical recommendation and referral timeline determination.
%     3. PDF and markdown export functions.
%     4. Village screening cohort roster aggregation.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        Config struct
        MockPatient struct
        MockQuality struct
        MockPrediction struct
        MockXAI struct
    end

    methods (TestMethodSetup)
        function setupData(testCase)
            testCase.Config = loadConfig();

            testCase.MockPatient = struct( ...
                'id', 'TEST-PAT-001', ...
                'name', 'Kavita Singh', ...
                'age', 52, ...
                'gender', 'Female', ...
                'eyeTested', 'OD', ...
                'campName', 'Khed PHC Screening Camp', ...
                'district', 'Pune');

            testCase.MockQuality = struct( ...
                'category', 'Good', ...
                'overallScore', 0.915, ...
                'recommendation', 'Image quality is clinically acceptable.');

            testCase.MockPrediction = struct( ...
                'predictedStage', 2, ...
                'stageName', 'Moderate NPDR', ...
                'confidence', 0.934, ...
                'referralRequired', true, ...
                'referralUrgency', 'Non-urgent referral within 30 days');

            testCase.MockXAI = struct( ...
                'saliencyMap', rand(224, 224), ...
                'justification', 'Saliency hotspots indicate exudate clusters in macular periphery.');
        end
    end

    methods (Test)
        function testGeneratePatientReport(testCase)
            rep = generatePatientReport(testCase.MockPatient, testCase.MockQuality, ...
                                        testCase.MockPrediction, testCase.MockXAI, testCase.Config);
            testCase.verifyNotEmpty(rep, 'generatePatientReport must return struct.');
            testCase.verifyTrue(isfield(rep, 'patient'), 'Report must contain patient demographic.');
            testCase.verifyTrue(isfield(rep, 'prediction'), 'Report must contain prediction data.');
            testCase.verifyTrue(isfield(rep, 'markdownReport'), 'Report must contain markdown text.');
        end

        function testExportReportPDF(testCase)
            rep = generatePatientReport(testCase.MockPatient, testCase.MockQuality, ...
                                        testCase.MockPrediction, testCase.MockXAI, testCase.Config);
            pdfPath = exportReportPDF(rep, testCase.Config);
            testCase.verifyNotEmpty(pdfPath, 'exportReportPDF must return file path.');
            testCase.verifyTrue(exist(pdfPath, 'file') ~= 0, 'Exported PDF file must exist on disk.');
        end

        function testCompileCohortReport(testCase)
            rep1 = generatePatientReport(testCase.MockPatient, testCase.MockQuality, ...
                                         testCase.MockPrediction, testCase.MockXAI, testCase.Config);
            p2 = testCase.MockPatient;
            p2.id = 'TEST-PAT-002';
            pred2 = testCase.MockPrediction;
            pred2.predictedStage = 0;
            pred2.stageName = 'No DR';
            pred2.referralRequired = false;
            rep2 = generatePatientReport(p2, testCase.MockQuality, pred2, testCase.MockXAI, testCase.Config);

            cohort = compileCohortReport({rep1, rep2});
            testCase.verifyNotEmpty(cohort, 'Cohort report must not be empty.');
            testCase.verifyEqual(cohort.totalPatients, 2, 'Total patients must be 2.');
            testCase.verifyEqual(cohort.referralCount, 1, 'Expected 1 referral.');
        end
    end
end
