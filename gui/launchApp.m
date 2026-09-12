function appInstance = launchApp()
% LAUNCHAPP Entry launcher for the SIH26038 Diabetic Retinopathy Screening GUI.
%
%   appInstance = launchApp()
%
%   Verifies graphic environment, initializes configuration and paths,
%   and instantiates the MATLAB App Designer user interface.
%
%   Outputs:
%       appInstance - Handle to the instantiated DRScreeningApp object.
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    logger.info('Initializing SIH26038 App Designer Interface...');

    % Ensure paths are initialized
    startup;

    % Instantiate GUI application
    try
        appInstance = DRScreeningApp_exported();
        logger.info('DRScreeningApp GUI launched successfully.');
    catch ME
        logger.error('Failed to launch GUI app: %s', ME.message);
        rethrow(ME);
    end
end
