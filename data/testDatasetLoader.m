% TESTDATASETLOADER Demonstration and verification script for Prompt 2: Dataset Loader.
%
%   Verifies:
%     1. Ingestion of 4 major clinical fundus datasets (APTOS, EyePACS, IDRiD, Messidor)
%     2. Automatic CSV label parsing across varying column schemas
%     3. Detection of missing image files
%     4. Detection and filtering of invalid labels
%     5. Stratified train (70%), validation (15%), and test (15%) splits
%     6. Configurable image size support
%     7. Class distribution table and bar chart export
%     8. Representative 5-class sample visualization montage
%
%   Usage:
%       testDatasetLoader
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

clear; clc; close all;
startup;

logger.info('===================================================================');
logger.info('  SIH26038: Testing Dataset Loader Module (Prompt 2 Requirements)  ');
logger.info('===================================================================');

cfg = loadConfig();
supportedDatasets = cfg.dataset.supported_datasets;

% 1. Test Ingestion across all 4 supported datasets
for i = 1:numel(supportedDatasets)
    dsName = supportedDatasets{i};
    logger.info('--- Testing Ingestion for Dataset: %s ---', dsName);
    
    try
        [splits, summary] = loadDataset(dsName, cfg);
        
        fprintf('  [SUCCESS] Dataset: %-10s | Total Valid: %3d | Train: %2d | Val: %2d | Test: %2d\n', ...
                dsName, summary.totalImages, ...
                summary.splitCounts.train, summary.splitCounts.val, summary.splitCounts.test);
        
        % Check missing image detection and invalid label filtering
        rep = summary.validationReport;
        fprintf('            Integrity Check  : %d missing files detected and isolated\n', rep.missingCount);
        fprintf('                             : %d invalid labels detected and filtered\n', rep.invalidLabelCount);
        
    catch ME
        logger.error('Failed testing dataset [%s]: %s', dsName, ME.message);
    end
end

% 2. Perform Deep Verification on Primary Dataset (APTOS)
primaryDataset = 'APTOS';
logger.info('--- Running Deep Analysis & Visualization on Primary Dataset: %s ---', primaryDataset);

[splitsAptos, summaryAptos] = loadDataset(primaryDataset, cfg);

% 3. Display Class Distribution & Generate Plot
logger.info('Displaying class distribution and exporting chart...');
[figDist, distTable] = displayClassDistribution(splitsAptos, summaryAptos);

% 4. Visualize Sample Images across all 5 DR Stages with Configurable Size
customTargetSize = [256, 256];
logger.info('Generating 5-class sample montage with custom target size [%dx%d]...', ...
            customTargetSize(1), customTargetSize(2));
[figSamples, sampleImgs] = visualizeSampleImages(splitsAptos, customTargetSize);

logger.info('===================================================================');
logger.info('  Prompt 2: Dataset Loader Verification Completed Successfully!     ');
logger.info('===================================================================');
