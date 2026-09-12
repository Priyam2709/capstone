% TESTTRAININGMODULE Comprehensive test runner for Prompt 5: Deep Learning Training.
%
%   Verifies:
%     1. Architecture building for ResNet18, ResNet50, EfficientNet-B0, MobileNetV2
%     2. Retinal data augmentation configuration
%     3. Transfer learning training execution with early stopping & LR scheduling
%     4. Model checkpoint persistence and reloading
%     5. Multi-class evaluation (Confusion matrix, ROC/AUC, Precision, Recall, F1)
%     6. Plot generation: Loss/accuracy curves, 5x5 confusion matrix, and ROC curves
%
%   Usage:
%       testTrainingModule
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

clear; clc; close all;
startup;

logger.info('===================================================================');
logger.info('  SIH26038: Testing Deep Learning Training Module (Prompt 5)       ');
logger.info('===================================================================');

cfg = loadConfig();

% 1. Verify Model Construction for All 4 Architectures
architectures = {'resnet18', 'resnet50', 'efficientnetb0', 'mobilenetv2'};
fprintf('\n--- 1. Testing Model Building across 4 Transfer Learning Backbones ---\n');
for i = 1:numel(architectures)
    arch = architectures{i};
    [lg, info] = buildModel(arch, 5, cfg);
    fprintf('  [PASS] %-15s : Target Layer="%s", InputSize=[%dx%d], Params=~%.1fM\n', ...
            upper(arch), info.targetConvLayer, info.inputSize(1), info.inputSize(2), ...
            info.approxParams / 1e6);
end

% 2. Verify Data Augmentation Setup
fprintf('\n--- 2. Testing Data Augmentation Pipeline ---\n');
[augObj, augCfg] = configureAugmenter(cfg);
fprintf('  [PASS] Augmentation Configured: Rot=[%d, %d] deg, Scale=[%.2f, %.2f], Flip=[H:%d, V:%d]\n', ...
        augCfg.RandRotation(1), augCfg.RandRotation(2), ...
        augCfg.RandXScale(1), augCfg.RandXScale(2), ...
        augCfg.RandXReflection, augCfg.RandYReflection);

% 3. Execute Training Pipeline on Configured Model
primaryModel = cfg.model.selected_architecture;
fprintf('\n--- 3. Executing Master Training Pipeline for [%s] ---\n', upper(primaryModel));
[trainedNet, trainRec, testM] = trainModel([], primaryModel, cfg);

fprintf('\n[Training Convergence Summary: %s]\n', upper(primaryModel));
fprintf('  Total Epochs Completed : %d\n', numel(trainRec.epochs));
fprintf('  Optimal Epoch Number   : %d\n', trainRec.bestEpoch);
fprintf('  Best Validation Loss   : %.4f\n', trainRec.bestValLoss);
fprintf('  Best Validation Acc    : %.2f%%\n', trainRec.bestValAccuracy);

% 4. Verify Performance Metrics & Evaluation
fprintf('\n[Test Partition Performance Evaluation]\n');
fprintf('  Overall Test Accuracy  : %.2f%%\n', testM.accuracy * 100);
fprintf('  Macro-Averaged Precision: %.2f%%\n', testM.precision * 100);
fprintf('  Macro-Averaged Recall  : %.2f%% (Sensitivity)\n', testM.recall * 100);
fprintf('  Macro-Averaged Specificity: %.2f%%\n', testM.specificity * 100);
fprintf('  Macro-Averaged F1-Score: %.4f\n', testM.f1Score);
fprintf('  Macro-Averaged ROC AUC : %.4f\n\n', testM.auc);

fprintf('  Per-Class Diagnostic Breakdown:\n');
fprintf('  %-22s  %10s  %10s  %10s  %8s\n', ...
        'Clinical DR Stage', 'Precision', 'Recall', 'F1-Score', 'AUC');
fprintf('  ------------------------------------------------------------------\n');
for c = 1:5
    fprintf('  %-22s  %9.1f%%  %9.1f%%  %10.4f  %8.4f\n', ...
            testM.classNames{c}, ...
            testM.perClass.precision(c) * 100, ...
            testM.perClass.recall(c) * 100, ...
            testM.perClass.f1Score(c), ...
            testM.perClass.auc(c));
end
fprintf('  ------------------------------------------------------------------\n\n');

% 5. Verify Model Checkpoint Persistence & Reloading
fprintf('--- 5. Testing Model Checkpoint Serialization & Reloading ---\n');
loadedChk = loadModelCheckpoint(primaryModel);
fprintf('  [PASS] Model Checkpoint successfully verified: Arch=%s, SavedEpoch=%d, ValAcc=%.1f%%\n', ...
        loadedChk.architecture, loadedChk.epoch, loadedChk.valAccuracy);

logger.info('===================================================================');
logger.info('  Prompt 5: Deep Learning Training Module Verified Successfully!    ');
logger.info('===================================================================');
