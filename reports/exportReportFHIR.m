function jsonPath = exportReportFHIR(reportData, destinationJsonPath)
% EXPORTREPORTFHIR Exports clinical screening result as an ABDM-compliant FHIR R4 JSON record.
%
%   jsonPath = exportReportFHIR(reportData)
%   jsonPath = exportReportFHIR(reportData, destinationJsonPath)
%
%   Specifications:
%       - FHIR Release 4 (R4) Resource: DiagnosticReport & Observation
%       - LOINC Code: LP200057-0 (Diabetic Retinopathy Screening)
%       - SNOMED-CT Codes mapped to 5 ICDR severity stages:
%           * Stage 0: 23986001 (Normal fundus / No DR)
%           * Stage 1: 312991008 (Mild nonproliferative diabetic retinopathy)
%           * Stage 2: 312992001 (Moderate nonproliferative diabetic retinopathy)
%           * Stage 3: 1551000119108 (Severe nonproliferative diabetic retinopathy)
%           * Stage 4: 390834007 (Proliferative diabetic retinopathy)
%       - Integration: Ayushman Bharat Digital Mission (ABDM) EHR Gateway
%
%   Inputs:
%       reportData          - Compiled report data struct from generatePatientReport()
%       destinationJsonPath - (Optional) Destination file path for JSON document
%
%   Outputs:
%       jsonPath            - Absolute path of the exported FHIR JSON file
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    % 1. Resolve Output Path
    if nargin < 2 || isempty(destinationJsonPath)
        try
            projectRoot = getProjectRoot();
            reportsDir = fullfile(projectRoot, 'results', 'reports');
        catch
            reportsDir = fullfile('.', 'results', 'reports');
        end
        if ~isfolder(reportsDir), mkdir(reportsDir); end
        
        repId = 'REPORT';
        if isfield(reportData, 'reportId'), repId = reportData.reportId; end
        destinationJsonPath = fullfile(reportsDir, sprintf('%s_fhir.json', repId));
    end

    % 2. Extract Fields safely
    p = struct();
    if isfield(reportData, 'patient'), p = reportData.patient; end
    if ~isfield(p, 'patientId'), p.patientId = 'RURAL-PT-001'; end
    if ~isfield(p, 'patientName'), p.patientName = 'Patient Name'; end
    if ~isfield(p, 'patientAge'), p.patientAge = 50; end
    if ~isfield(p, 'patientGender'), p.patientGender = 'Unknown'; end
    if ~isfield(p, 'campId'), p.campId = 'PHC-CAMP'; end
    if ~isfield(p, 'operatorId'), p.operatorId = 'OP-001'; end

    pred = struct();
    if isfield(reportData, 'prediction'), pred = reportData.prediction; end
    stg = 0;
    if isfield(pred, 'stageCode'), stg = pred.stageCode;
    elseif isfield(pred, 'predictedStage'), stg = pred.predictedStage;
    elseif isfield(pred, 'predictedClass'), stg = pred.predictedClass;
    end
    stg = max(0, min(4, round(stg)));

    conf = 0.95;
    if isfield(pred, 'confidence'), conf = pred.confidence;
    elseif isfield(pred, 'confidencePercent'), conf = pred.confidencePercent / 100.0;
    end

    urgency = 'Routine Surveillance';
    if isfield(pred, 'urgency'), urgency = pred.urgency;
    elseif isfield(pred, 'referralUrgency'), urgency = pred.referralUrgency;
    end

    % 3. SNOMED-CT Clinical Stage Mappings
    snomedCodes = {'23986001', '312991008', '312992001', '1551000119108', '390834007'};
    snomedDisplays = { ...
        'Normal retinal fundus - No diabetic retinopathy', ...
        'Mild nonproliferative diabetic retinopathy', ...
        'Moderate nonproliferative diabetic retinopathy', ...
        'Severe nonproliferative diabetic retinopathy', ...
        'Proliferative diabetic retinopathy' ...
    };

    stageName = snomedDisplays{stg + 1};
    snomedCode = snomedCodes{stg + 1};

    repId = 'RPT-001';
    if isfield(reportData, 'reportId'), repId = reportData.reportId; end

    genAt = datestr(now, 'yyyy-mm-ddTHH:MM:SS+05:30');

    % 4. Assemble FHIR R4 DiagnosticReport Resource
    fhir = struct();
    fhir.resourceType = 'DiagnosticReport';
    fhir.id = repId;
    fhir.status = 'final';

    % Category
    catCoding = struct('system', 'http://loinc.org', 'code', 'LP200057-0', 'display', 'Diabetic Retinopathy Screening');
    fhir.category = {struct('coding', {catCoding})};

    % Service Code
    svcCoding = struct('system', 'http://snomed.info/sct', 'code', '4855003', 'display', 'Diabetic Retinopathy Evaluation');
    fhir.code = struct('coding', {svcCoding}, 'text', 'Explainable AI Diabetic Retinopathy Fundus Triage');

    % Subject (Patient)
    fhir.subject = struct('reference', sprintf('Patient/%s', p.patientId), ...
                          'display', p.patientName, ...
                          'identifier', struct('system', 'https://healthid.abdm.gov.in', 'value', p.patientId));

    % Performer & Organization
    facility = 'Rural Primary Health Centre';
    if isfield(reportData, 'organization'), facility = reportData.organization; end
    fhir.performer = { ...
        struct('reference', sprintf('Practitioner/%s', p.operatorId), 'display', sprintf('Field Operator: %s', p.operatorId)), ...
        struct('reference', sprintf('Organization/%s', p.campId), 'display', facility) ...
    };

    % Effective & Issued Timestamps
    fhir.effectiveDateTime = genAt;
    fhir.issued = genAt;

    % Conclusion & Findings
    fhir.conclusion = sprintf('Stage %d: %s. Referral Urgency: %s. Model Confidence: %.1f%%.', ...
                             stg, stageName, urgency, conf * 100.0);

    codeCoding = struct('system', 'http://snomed.info/sct', 'code', snomedCode, 'display', stageName);
    fhir.conclusionCode = {struct('coding', {codeCoding})};

    % Contained Observation (AI Quantitative Findings)
    obs = struct();
    obs.resourceType = 'Observation';
    obs.id = sprintf('obs-%s', repId);
    obs.status = 'final';
    obs.code = struct('text', 'AI Model Inference & Explainability Metrics');
    obs.valueQuantity = struct('value', round(conf * 100, 1), 'unit', '%', 'system', 'http://unitsofmeasure.org', 'code', '%');

    % Component Observations: IQA & XAI
    components = {};
    if isfield(reportData, 'quality') && isfield(reportData.quality, 'overallScore')
        components{end+1} = struct( ...
            'code', struct('text', 'Image Quality Assessment Score'), ...
            'valueQuantity', struct('value', round(reportData.quality.overallScore, 1), 'unit', 'score', 'system', 'http://unitsofmeasure.org', 'code', '{score}') ...
        );
    end
    if isfield(reportData, 'explainability') && isfield(reportData.explainability, 'lesionStats')
        cov = reportData.explainability.lesionStats.coveragePercent;
        quad = reportData.explainability.lesionStats.dominantQuadrant;
        components{end+1} = struct( ...
            'code', struct('text', 'Saliency Heatmap Coverage'), ...
            'valueQuantity', struct('value', round(cov, 1), 'unit', '%', 'system', 'http://unitsofmeasure.org', 'code', '%') ...
        );
        components{end+1} = struct( ...
            'code', struct('text', 'Dominant Lesion Quadrant'), ...
            'valueString', quad ...
        );
    end
    obs.component = components;
    fhir.contained = {obs};

    % 5. Serialize and Write JSON
    jsonText = jsonencode(fhir);
    
    % Pretty-format JSON if possible
    try
        % Standard JSON formatting indent
        openB = char(123);
        closeB = char(125);
        jsonText = strrep(jsonText, ',"', sprintf(',\n  "'));
        jsonText = strrep(jsonText, openB, sprintf('%s\n  ', openB));
        jsonText = strrep(jsonText, closeB, sprintf('\n%s', closeB));
    catch
    end

    fid = fopen(destinationJsonPath, 'w');
    if fid == -1
        error('exportReportFHIR:FileOpenError', 'Unable to write FHIR JSON to: %s', destinationJsonPath);
    end
    fwrite(fid, jsonText, 'char');
    fclose(fid);

    jsonPath = destinationJsonPath;
    try
        logger.info('Exported ABDM-compliant FHIR R4 JSON record to: %s', jsonPath);
    catch
    end
end
