function varargout = main(mode, varargin)
% MAIN Master orchestration driver for SIH26038 Diabetic Retinopathy screening system.
%
%   main()               - Runs complete end-to-end clinical pipeline demo (default).
%   main('demo')         - Runs end-to-end demo on a sample fundus image.
%   main('gui')          - Launches the interactive 18-view clinical workstation GUI (Dark/Light theme).
%   main('sim')          - Runs the 8-hour rural camp discrete-event queueing simulation.
%   main('test')         - Runs all 10 automated unit, integration, and stress test suites.
%   main('profile')      - Runs latency profiling and edge hardware benchmarking.
%   main('validate')     - Runs clinical validation (confusion matrix, QWK, ROC/AUC).
%   main('all')          - Runs complete test, profiling, validation, simulation & demo.
%
%   Inputs:
%       mode     - (Optional) String specifying operational mode:
%                  'demo' (default), 'gui', 'sim', 'test', 'profile', 'validate', 'all'.
%       varargin - (Optional) Additional arguments forwarded to sub-modules.
%
%   Outputs:
%       varargout - Output results struct or app instance depending on selected mode.
%
%   Smart India Hackathon Problem Statement: SIH26038
%   "Explainable AI-Based Diabetic Retinopathy Screening System for Rural India"
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 1 || isempty(mode)
        mode = 'demo';
    end

    % 1. Ensure project paths are initialized
    startup;

    fprintf('========================================================================\n');
    fprintf('  SIH26038: Explainable AI Retinal Screening System for Rural India     \n');
    fprintf('  Mode Selected: %s                                                     \n', upper(mode));
    fprintf('========================================================================\n\n');

    switch lower(mode)
        case {'demo', 'pipeline'}
            % -------------------------------------------------------------
            % MODE: DEMO (Full Clinical Pipeline on Fundus Image)
            % -------------------------------------------------------------
            out = runDemoPipeline(varargin{:});
            if nargout > 0, varargout{1} = out; end

        case {'gui', 'app'}
            % -------------------------------------------------------------
            % MODE: GUI (Interactive App Designer Interface)
            % -------------------------------------------------------------
            app = launchApp();
            if nargout > 0, varargout{1} = app; end

        case {'sim', 'simulink', 'queue'}
            % -------------------------------------------------------------
            % MODE: SIMULATION (Discrete-Event Camp Queue Model)
            % -------------------------------------------------------------
            simRes = runCampSimulation();
            fig = plotSimulationResults(simRes);
            if nargout > 0, varargout{1} = simRes; end

        case {'test', 'tests', 'unittest'}
            % -------------------------------------------------------------
            % MODE: TEST (Automated System Unit Tests)
            % -------------------------------------------------------------
            results = runAllTests();
            if nargout > 0, varargout{1} = results; end

        case {'profile', 'benchmark', 'perf'}
            % -------------------------------------------------------------
            % MODE: PROFILE (Latency Profiling & Edge Benchmarking)
            % -------------------------------------------------------------
            profRes = profilePipeline();
            if nargout > 0, varargout{1} = profRes; end

        case {'validate', 'eval', 'metrics'}
            % -------------------------------------------------------------
            % MODE: VALIDATION (Clinical Metrics, Confusion Matrix, ROC/AUC)
            % -------------------------------------------------------------
            valRes = evaluateFullValidationSuite();
            if nargout > 0, varargout{1} = valRes; end

        case {'all', 'full', 'master'}
            % -------------------------------------------------------------
            % MODE: ALL (Comprehensive Verification Sequence)
            % -------------------------------------------------------------
            fprintf('Executing Master Verification Sequence: Test -> Profile -> Validate -> Sim -> Demo\n\n');
            testRes = runAllTests();
            profRes = profilePipeline(10);
            valRes = evaluateFullValidationSuite(100);
            simRes = runCampSimulation();
            plotSimulationResults(simRes);
            demoRes = runDemoPipeline();

            masterSummary = struct( ...
                'tests', testRes, ...
                'profiling', profRes, ...
                'validation', valRes, ...
                'simulation', simRes, ...
                'demo', demoRes);
            if nargout > 0, varargout{1} = masterSummary; end

        otherwise
            error('SIH26038:UnknownMode', ...
                  'Unknown mode "%s". Supported modes: demo, gui, sim, test, profile, validate, all', mode);
    end
end

% =========================================================================
% HELPER: RUN DEMO PIPELINE
% =========================================================================
function demoOutput = runDemoPipeline(inputImagePath)
    cfg = loadConfig();
    root = getProjectRoot();

    % 1. Source Image Acquisition
    if nargin < 1 || isempty(inputImagePath)
        sampleCandidate = fullfile(root, 'data', 'raw', 'aptos', 'aptos_sample_3.png');
        if ~isfile(sampleCandidate)
            % Create synthetic sample if not present
            createSyntheticDataset(root, 2);
        end
        if isfile(sampleCandidate)
            inputImagePath = sampleCandidate;
        else
            % Fallback
            inputImagePath = fullfile(root, 'data', 'raw', 'sample_fundus.png');
        end
    end

    logger.info('--- Phase 1: Loading Retinal Fundus Image ---');
    [imgProc, imgRaw, imgMeta] = loadImage(inputImagePath, cfg.image.target_size, false);
    logger.info('Image loaded: %s [%dx%dx%d]', inputImagePath, size(imgProc, 1), size(imgProc, 2), size(imgProc, 3));

    % 2. Image Quality Assessment (IQA Gate)
    logger.info('--- Phase 2: Evaluating Image Quality Assessment (IQA) ---');
    qResult = assessImageQuality(imgProc, cfg);
    fprintf('\n[IQA Results]\n');
    fprintf('  Overall Quality Score : %5.1f / 100\n', qResult.overallScore * 100);
    fprintf('  Clinical Verdict      : %s\n', qResult.category);
    fprintf('  Blur Metric (Laplace) : %5.4f\n', qResult.metrics.blur.value);
    fprintf('  Mean Brightness       : %5.1f / 255\n', qResult.metrics.brightness.value);
    fprintf('  RMS Contrast          : %5.2f\n', qResult.metrics.contrast.value);
    fprintf('  Operator Guidance     : %s\n\n', qResult.recommendation);

    % 3. Preprocessing & CLAHE Enhancement
    logger.info('--- Phase 3: Applying Preprocessing & CLAHE Enhancement ---');
    enhancedResult = preprocessPipeline(imgProc, cfg);
    if isfield(enhancedResult, 'metrics')
        fprintf('[Enhancement Fidelity]\n');
        fprintf('  PSNR Improvement      : %5.2f dB\n', enhancedResult.metrics.psnr);
        fprintf('  Structural Similarity : %5.4f SSIM\n', enhancedResult.metrics.ssim);
        fprintf('  Contrast Gain Ratio   : %5.2f x\n\n', enhancedResult.metrics.contrastRatio);
    end

    % 4. Deep Learning Classification
    logger.info('--- Phase 4: Executing Deep Learning DR Classification ---');
    predResult = predictDR(enhancedResult.enhancedImage, [], cfg);
    fprintf('[Diagnostic Prediction]\n');
    fprintf('  Predicted DR Stage    : Stage %d - %s\n', predResult.predictedClass, predResult.className);
    fprintf('  Model Confidence      : %5.2f %%\n', predResult.confidence * 100);
    fprintf('  Inference Latency     : %5.1f ms\n', predResult.inferenceTimeMs);
    fprintf('  Referral Status       : %s\n', upper(predResult.urgencyLevel));
    fprintf('  Softmax Distribution  :\n');
    stageLabels = {'0: No DR', '1: Mild NPDR', '2: Moderate NPDR', '3: Severe NPDR', '4: Proliferative DR'};
    for c = 1:5
        fprintf('    - %-22s: %5.1f %%\n', stageLabels{c}, predResult.classProbabilities(c) * 100);
    end
    fprintf('\n');

    % 5. Explainable AI (Grad-CAM Saliency)
    logger.info('--- Phase 5: Generating Grad-CAM Saliency Explainability ---');
    xaiResult = computeGradCAM([], enhancedResult.enhancedImage, predResult.predictedClass, cfg);
    logger.info('Grad-CAM visual heatmap generated.');

    % 6. Clinical Diagnostic Report Generation & Export
    logger.info('--- Phase 6: Compiling Clinical Diagnostic PDF Report ---');
    patientData = struct();
    patientData.patientId = 'RURAL-PT-2026-0892';
    patientData.patientName = 'Ramesh Kumar';
    patientData.patientAge = 54;
    patientData.patientGender = 'Male';
    patientData.eyeTested = 'OD';
    patientData.campId = 'PUNE-KHED-PHC-04';
    patientData.operatorId = 'ASHA-ID-841';
    patientData.screeningDate = datestr(now, 'yyyy-mm-dd');
    patientData.diabetesDuration = '8 Years (Type 2)';
    patientData.bloodGlucose = '174 mg/dL (Random)';

    reportResult = generatePatientReport(patientData, qResult, enhancedResult, predResult, xaiResult, cfg);
    fprintf('  PDF Screening Report  : %s\n', reportResult.reportPath);
    if isfield(reportResult, 'pngPath') && exist(reportResult.pngPath, 'file')
        fprintf('  Diagnostic Summary PNG: %s\n', reportResult.pngPath);
    end
    if isfield(reportResult, 'matPath') && exist(reportResult.matPath, 'file')
        fprintf('  Clinical MAT Archive  : %s\n', reportResult.matPath);
    end
    if isfield(reportResult, 'fhirJsonPath') && exist(reportResult.fhirJsonPath, 'file')
        fprintf('  ABDM FHIR R4 Record   : %s\n', reportResult.fhirJsonPath);
    end

    fprintf('\n========================================================================\n');
    fprintf('  SIH26038 DEMO PIPELINE EXECUTION COMPLETED SUCCESSFULLY!             \n');
    fprintf('========================================================================\n\n');

    demoOutput = struct( ...
        'imagePath', inputImagePath, ...
        'quality', qResult, ...
        'enhancement', enhancedResult, ...
        'prediction', predResult, ...
        'explainability', xaiResult, ...
        'report', reportResult);
end
