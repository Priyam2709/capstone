function [out1, out2] = compileCohortReport(patientRecords, campId, exportPath)
% COMPILECOHORTREPORT Aggregates camp screening statistics and generates district referral rosters.
%
%   cohortSummary = compileCohortReport(patientRecords)
%   [summaryTable, referralRoster] = compileCohortReport(patientRecords)
%   [summaryTable, referralRoster] = compileCohortReport(patientRecords, campId)
%   [summaryTable, referralRoster] = compileCohortReport(patientRecords, campId, exportPath)
%
%   Inputs:
%       patientRecords - Cell array or struct array of compiled individual screening results.
%       campId         - (Optional) Camp / PHC identifier string (Default: 'WARDHA-DISTRICT-PHC-CAMP-01').
%       exportPath     - (Optional) Destination CSV path for the district referral roster.
%
%   Outputs:
%       If 1 output requested:
%           out1 - Struct containing:
%               .totalPatients  - Total screened count
%               .referralCount  - Total referred count
%               .referralRate   - Percentage referred
%               .stageCounts    - 1x5 array of counts per ICDR stage
%               .summaryTable   - Formatted summary table
%               .referralRoster - Table of referred patients
%       If 2 outputs requested:
%           out1 - summaryTable (MATLAB table)
%           out2 - referralRoster (MATLAB table)
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    if nargin < 2 || isempty(campId)
        campId = 'WARDHA-DISTRICT-PHC-CAMP-01';
    end

    stageNames = {'0 - No DR', '1 - Mild NPDR', '2 - Moderate NPDR', ...
                  '3 - Severe NPDR', '4 - Proliferative DR'};

    totalScreened = numel(patientRecords);

    rosterVarNames = {'PatientId', 'PatientName', 'Age', 'Gender', ...
                      'Diagnosis', 'ConfidencePercent', 'Urgency', ...
                      'LesionLocation', 'ReportDocumentId'};

    if totalScreened == 0
        emptyTbl = table((0:4)', stageNames', zeros(5, 1), zeros(5, 1), ...
                         'VariableNames', {'StageCode', 'StageName', 'PatientCount', 'Percentage'});
        emptyRoster = cell2table(cell(0, 9), 'VariableNames', rosterVarNames);
        if nargout <= 1
            res = struct('totalPatients', 0, 'referralCount', 0, 'referralRate', 0, ...
                         'stageCounts', zeros(1, 5), 'summaryTable', emptyTbl, 'referralRoster', emptyRoster);
            out1 = res;
        else
            out1 = emptyTbl;
            out2 = emptyRoster;
        end
        return;
    end

    % 1. Parse Patient Records Flexibly
    stageCounts = zeros(1, 5);
    referralRows = {};

    for i = 1:totalScreened
        rec = patientRecords{i};
        if isfield(rec, 'compiledData')
            data = rec.compiledData;
        else
            data = rec;
        end

        % Extract Prediction
        stg = 0;
        refReq = false;
        stgName = 'Stage 0 - No DR';
        confPct = 95.0;
        urgStr = 'Routine annual rescreening';

        if isfield(data, 'prediction')
            pObj = data.prediction;
            if isfield(pObj, 'stageCode'), stg = pObj.stageCode;
            elseif isfield(pObj, 'predictedStage'), stg = pObj.predictedStage;
            elseif isfield(pObj, 'predictedClass'), stg = pObj.predictedClass; end

            if isfield(pObj, 'referralRequired'), refReq = pObj.referralRequired; end
            if isfield(pObj, 'stageName'), stgName = pObj.stageName; end
            if isfield(pObj, 'confidencePercent'), confPct = pObj.confidencePercent;
            elseif isfield(pObj, 'confidence'), confPct = pObj.confidence * 100.0; end
            if isfield(pObj, 'urgency'), urgStr = pObj.urgency;
            elseif isfield(pObj, 'referralUrgency'), urgStr = pObj.referralUrgency; end
        end

        stg = max(0, min(4, round(stg)));
        stageCounts(stg + 1) = stageCounts(stg + 1) + 1;

        % If referral required, append to roster
        if refReq || stg >= 2
            pId = sprintf('PT-%03d', i);
            pName = 'Screening Patient';
            pAge = 50;
            pGender = 'Unknown';
            if isfield(data, 'patient')
                pat = data.patient;
                if isfield(pat, 'patientId'), pId = pat.patientId;
                elseif isfield(pat, 'id'), pId = pat.id; end

                if isfield(pat, 'patientName'), pName = pat.patientName;
                elseif isfield(pat, 'name'), pName = pat.name; end

                if isfield(pat, 'patientAge'), pAge = pat.patientAge;
                elseif isfield(pat, 'age'), pAge = pat.age; end

                if isfield(pat, 'patientGender'), pGender = pat.patientGender;
                elseif isfield(pat, 'gender'), pGender = pat.gender; end
            end

            lesionLoc = 'Temporal Periphery';
            if isfield(data, 'explainability') && isfield(data.explainability, 'lesionStats')
                if isfield(data.explainability.lesionStats, 'dominantQuadrant')
                    lesionLoc = data.explainability.lesionStats.dominantQuadrant;
                end
            end

            docId = sprintf('RPT-%03d', i);
            if isfield(data, 'reportId'), docId = data.reportId;
            elseif isfield(rec, 'reportId'), docId = rec.reportId; end

            referralRows{end+1} = { ...
                pId, pName, pAge, pGender, ...
                stgName, round(confPct, 1), urgStr, ...
                lesionLoc, docId ...
            }; %#ok<AGROW>
        end
    end

    % 2. Build Summary Table
    pcts = (stageCounts / max(1, totalScreened)) * 100.0;
    summaryTable = table((0:4)', stageNames', stageCounts', round(pcts', 1), ...
                         'VariableNames', {'StageCode', 'StageName', 'PatientCount', 'Percentage'});

    % 3. Build Referral Roster
    if ~isempty(referralRows)
        referralRoster = cell2table(vertcat(referralRows{:}), 'VariableNames', rosterVarNames);
    else
        referralRoster = cell2table(cell(0, 9), 'VariableNames', rosterVarNames);
    end

    numRef = height(referralRoster);
    refRate = (numRef / max(1, totalScreened)) * 100.0;

    % 4. Display Formatted Camp Summary to Command Window
    fprintf('\n========================================================================================\n');
    fprintf('  RURAL SCREENING CAMP EXECUTIVE SUMMARY: [%s]\n', campId);
    fprintf('========================================================================================\n');
    fprintf('  Total Patients Screened       : %d\n', totalScreened);
    fprintf('  Patients Flagged for Referral : %d (%.1f%% of cohort)\n', numRef, refRate);
    fprintf('  --------------------------------------------------------------------------------------\n');
    disp(summaryTable);
    fprintf('========================================================================================\n\n');

    % 5. Export to CSV if requested
    if nargin >= 3 && ~isempty(exportPath)
        try
            writetable(referralRoster, exportPath);
            try
                logger.info('District referral roster exported to: %s', exportPath);
            catch
            end
        catch ME
            warning('Could not export referral roster: %s', ME.message);
        end
    end

    % 6. Return appropriate outputs based on nargout
    if nargout <= 1
        res = struct();
        res.totalPatients  = totalScreened;
        res.referralCount  = numRef;
        res.referralRate   = refRate;
        res.stageCounts    = stageCounts;
        res.summaryTable   = summaryTable;
        res.referralRoster = referralRoster;
        out1 = res;
    else
        out1 = summaryTable;
        out2 = referralRoster;
    end
end
