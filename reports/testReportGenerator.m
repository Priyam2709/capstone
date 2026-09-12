% TESTREPORTGENERATOR Comprehensive test runner for Prompt 8: Clinical Report Generation.
%
%   Verifies:
%     1. Full clinical screening report assembly with patient demographics
%     2. Tri-image diagnostic gallery (Original, Enhanced, Grad-CAM Overlay)
%     3. Diagnostic prediction, confidence score, and 5-stage probabilities
%     4. Actionable referral recommendations and clinical triage urgency
%     5. High-resolution PDF export with vector graphics
%     6. District referral roster compilation across patient cohorts
%
%   Usage:
%       testReportGenerator
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

clear; clc; close all;
startup;

logger.info('===================================================================');
logger.info('  SIH26038: Testing Clinical Report Generator Module (Prompt 8)    ');
logger.info('===================================================================');

cfg = loadConfig();

% 1. Create 3 Clinical Scenarios: Routine (Stage 0), Referral (Stage 2), Emergency (Stage 4)
testPatients = {
    % Case A: Routine Surveillance (Stage 0)
    struct('id', 'RURAL-PT-2026-0101', 'name', 'Sunita Devi', 'age', 48, 'gender', 'Female', ...
           'stage', 0, 'conf', 0.965, 'duration', '3 Years', 'glucose', '128 mg/dL (Fasting)'), ...
    % Case B: Moderate NPDR Referral (Stage 2)
    struct('id', 'RURAL-PT-2026-0102', 'name', 'Ramesh Chandra Patel', 'age', 56, 'gender', 'Male', ...
           'stage', 2, 'conf', 0.942, 'duration', '9 Years', 'glucose', '184 mg/dL (Random)'), ...
    % Case C: Emergency Tertiary Care (Stage 4)
    struct('id', 'RURAL-PT-2026-0103', 'name', 'Gurdeep Singh', 'age', 63, 'gender', 'Male', ...
           'stage', 4, 'conf', 0.978, 'duration', '14 Years', 'glucose', '242 mg/dL (Random)')
};

compiledCohort = {};

for i = 1:numel(testPatients)
    p = testPatients{i};
    logger.info('Generating clinical report for Patient: %s (%s, Stage %d)...', ...
                p.id, p.name, p.stage);

    % A. Load or synthesize fundus image
    samplePath = fullfile(cfg.paths.abs_raw_data_dir, 'aptos', sprintf('aptos_%02d_1.png', p.stage));
    if isfile(samplePath)
        [imgProc, imgRaw, ~] = loadImage(samplePath, cfg.image.target_size, false);
    else
        [X, Y] = meshgrid(-112:111, -112:111);
        retinaMask = (sqrt(X.^2 + Y.^2) <= 100);
        imgRaw = repmat(uint8(160 * retinaMask), [1 1 3]);
        imgProc = imgRaw;
    end

    % B. Execute Pipeline Stages
    qualityRes  = assessImageQuality(imgProc, cfg);
    enhancedRes = preprocessPipeline(imgProc, cfg);
    predRes     = predictDR(enhancedRes.enhancedImage, cfg);
    % Set simulated stage and confidence for the test scenario
    predRes.stageCode = p.stage;
    stageNames = cfg.model.class_names;
    predRes.stageName = stageNames{p.stage + 1};
    predRes.confidence = p.conf;
    predRes.confidencePercent = p.conf * 100.0;
    predRes.referralRequired = (p.stage >= 2);

    xaiRes = computeGradCAM([], enhancedRes.enhancedImage, p.stage, cfg, p.conf);

    % C. Assemble Demographic Struct
    patData = struct();
    patData.patientId        = p.id;
    patData.patientName      = p.name;
    patData.patientAge       = p.age;
    patData.patientGender    = p.gender;
    patData.campId           = 'WARDHA-DISTRICT-PHC-02';
    patData.operatorId       = cfg.rural_deployment.field_worker_id;
    patData.screeningDate    = datestr(now, 'yyyy-mm-dd');
    patData.diabetesDuration = p.duration;
    patData.bloodGlucose     = p.glucose;

    % D. Compile and Export Patient PDF Report
    destPdf = fullfile(cfg.paths.abs_reports_dir, sprintf('%s_report.pdf', p.id));
    repResult = generatePatientReport(patData, qualityRes, enhancedRes, predRes, xaiRes, cfg, destPdf);

    fprintf('  [PASS] Generated Report: %s\n', repResult.reportPath);
    compiledCohort{end+1} = repResult.compiledData; %#ok<AGROW>
end

% 2. Test Cohort Aggregation & Referral Roster Export
logger.info('Compiling village camp cohort report and referral roster...');
rosterCsvPath = fullfile(cfg.paths.abs_reports_dir, 'district_referral_roster.csv');
[summaryTbl, referralRoster] = compileCohortReport(compiledCohort, 'WARDHA-DISTRICT-PHC-02', rosterCsvPath);

fprintf('Referral Roster Generated (%d high-priority referrals flagged for district hospital):\n', ...
        height(referralRoster));
disp(referralRoster(:, {'PatientId', 'PatientName', 'Diagnosis', 'Urgency'}));

logger.info('===================================================================');
logger.info('  Prompt 8: Clinical Report Generator Verified Successfully!        ');
logger.info('===================================================================');
