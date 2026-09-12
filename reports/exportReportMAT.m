function matPath = exportReportMAT(reportData, enhancedResult, destinationMatPath)
% EXPORTREPORTMAT Exports complete clinical screening tensors and metadata to a MATLAB MAT archive.
%
%   matPath = exportReportMAT(reportData)
%   matPath = exportReportMAT(reportData, enhancedResult)
%   matPath = exportReportMAT(reportData, enhancedResult, destinationMatPath)
%
%   Inputs:
%       reportData         - Compiled report data struct from generatePatientReport()
%       enhancedResult     - (Optional) Enhanced image results struct
%       destinationMatPath - (Optional) Destination .mat file path
%
%   Outputs:
%       matPath            - Absolute path of saved .mat file
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    % 1. Resolve Path
    if nargin < 3 || isempty(destinationMatPath)
        try
            projectRoot = getProjectRoot();
            reportsDir = fullfile(projectRoot, 'results', 'reports');
        catch
            reportsDir = fullfile('.', 'results', 'reports');
        end
        if ~isfolder(reportsDir), mkdir(reportsDir); end

        repId = 'REPORT';
        if isfield(reportData, 'reportId'), repId = reportData.reportId; end
        destinationMatPath = fullfile(reportsDir, sprintf('%s_screening_data.mat', repId));
    end

    % 2. Assemble Master Clinical MAT Payload
    clinicalArchive = struct();
    clinicalArchive.reportId    = 'RPT-001';
    if isfield(reportData, 'reportId'), clinicalArchive.reportId = reportData.reportId; end
    clinicalArchive.exportedAt  = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    clinicalArchive.softwareVersion = '1.0.0-production';
    clinicalArchive.regulatoryStandard = 'NPCB&VI / ABDM SaMD Class-B';

    if isfield(reportData, 'patient'), clinicalArchive.patient = reportData.patient; end
    if isfield(reportData, 'quality'), clinicalArchive.quality = reportData.quality; end
    if isfield(reportData, 'prediction'), clinicalArchive.prediction = reportData.prediction; end
    if isfield(reportData, 'explainability'), clinicalArchive.explainability = reportData.explainability; end
    if isfield(reportData, 'doctorNotes'), clinicalArchive.doctorNotes = reportData.doctorNotes; end

    if nargin >= 2 && ~isempty(enhancedResult) && isstruct(enhancedResult)
        clinicalArchive.images = enhancedResult;
    elseif isfield(reportData, 'enhanced')
        clinicalArchive.images = reportData.enhanced;
    end

    % 3. Save to Disk
    try
        save(destinationMatPath, 'clinicalArchive', '-v7.3');
        matPath = destinationMatPath;
        try
            logger.info('Clinical workspace data archived to: %s', matPath);
        catch
        end
    catch ME
        % Fallback without -v7.3 flag if HDF5 engine is unsupported
        save(destinationMatPath, 'clinicalArchive');
        matPath = destinationMatPath;
    end
end
