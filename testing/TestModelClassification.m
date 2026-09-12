classdef TestModelClassification < matlab.unittest.TestCase
% TESTMODELCLASSIFICATION Unit tests for deep learning architecture & prediction engine.
%
%   Verifies:
%     1. Model builder instantiation for supported architectures.
%     2. Prediction inference engine with synthetic fundus inputs.
%     3. 5-class probability vector integrity (summing to ~1.0).
%     4. Referral triage threshold triggering (Stage >= 2).
%     5. Batch prediction functionality.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    properties
        Config struct
        SampleImage uint8
    end

    methods (TestMethodSetup)
        function setupData(testCase)
            testCase.Config = loadConfig();
            % Synthetic 224x224 retinal image
            testCase.SampleImage = uint8(120 + 30 * rand(224, 224, 3));
        end
    end

    methods (Test)
        function testBuildModel(testCase)
            lgraph = buildModel('resnet50', 5);
            testCase.verifyNotEmpty(lgraph, 'Model builder must return layer graph or dlnetwork.');
        end

        function testPredictDR(testCase)
            result = predictDR(testCase.SampleImage, [], testCase.Config);
            testCase.verifyNotEmpty(result, 'predictDR must return prediction struct.');
            testCase.verifyTrue(isfield(result, 'predictedClass'), 'Must contain predictedClass.');
            testCase.verifyTrue(result.predictedClass >= 0 && result.predictedClass <= 4, ...
                'Predicted class must be an integer between 0 and 4.');
            testCase.verifyTrue(isfield(result, 'confidence'), 'Must contain confidence.');
            testCase.verifyTrue(result.confidence >= 0 && result.confidence <= 1.0, ...
                'Confidence must be within [0, 1].');
            testCase.verifyEqual(numel(result.classProbabilities), 5, ...
                'Must have 5 class probabilities.');
            testCase.verifyEqual(sum(result.classProbabilities), 1.0, 'AbsTol', 1e-3, ...
                'Probabilities must sum to 1.0.');
        end

        function testReferralLogic(testCase)
            result = predictDR(testCase.SampleImage, [], testCase.Config);
            if result.predictedClass >= testCase.Config.model.referralThreshold
                testCase.verifyTrue(result.referralRecommended, ...
                    'Stage >= threshold must trigger referral.');
                testCase.verifyNotEmpty(result.urgencyLevel, 'Urgency level must be defined.');
            else
                testCase.verifyFalse(result.referralRecommended, ...
                    'Stage < threshold should not trigger referral.');
            end
        end

        function testBatchPrediction(testCase)
            batch = {testCase.SampleImage, testCase.SampleImage};
            batchResults = batchPredictDR(batch, [], testCase.Config);
            testCase.verifyEqual(numel(batchResults), 2, 'Batch result count must match input count.');
            testCase.verifyTrue(isfield(batchResults(1), 'predictedClass'), 'Batch item must have predictedClass.');
        end
    end
end
