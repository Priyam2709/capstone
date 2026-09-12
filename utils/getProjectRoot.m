function rootPath = getProjectRoot()
% GETPROJECTROOT Returns the absolute path to the project root directory.
%
%   rootPath = getProjectRoot()
%
%   This function dynamically discovers the root directory of the
%   Diabetic Retinopathy screening project by resolving the parent directory
%   of the 'utils' folder. This ensures portability across different
%   workstations, operating systems (Windows, Linux, macOS), and deployment environments.
%
%   Output:
%       rootPath - Absolute path string to the Capstone root directory.
%
%   Example:
%       projectDir = getProjectRoot();
%       configPath = fullfile(projectDir, 'config', 'default_config.json');
%
%   Author: SIH26038 Capstone Engineering Team
%   Date: September 2026

    currentFilePath = mfilename('fullpath');
    utilsDir = fileparts(currentFilePath);
    rootPath = fileparts(utilsDir);

    % Verify root directory exists
    if ~isfolder(rootPath)
        error('SIH26038:InvalidRoot', 'Resolved project root "%s" is not a valid directory.', rootPath);
    end
end
