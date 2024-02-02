% ------------------------------------------------------------------------------
% Report SCOOP QC from a Qc file (DIR_INPUT_QC_NC_FILES) to associated C-PROF
% and/or B-PROF files.
%
% 1- The Qc file is expected to have the same parameter measurements as the
% S-PROF file. The <PARAM>_dPRES parameters are retrieved from the S-PROF file
% (expected to be in the DIR_INPUT_GDAC_NC_FILES directory). Only QC of levels
% where <PARAM>_dPRES = 0 are reported to associated C-PROF and/or B-PROF files.
%
% 2- Reported SCOOP QC are retrieved from HISTORY section of Qc file under the
% constrains HISTORY_SOFTWARE = 'SCOO' and HISTORY_ACTION = 'CF', then
% HISTORY_PARAMETER =
% - <PARAM> => update <PARAM>_QC (<PARAM> can be adjusted parameter name)
% - 'DAT$'  => update JULD_QC
% - 'POS$'  => update POSITION_QC
%
% 3- Input files to update are first searched in DIR_OUTPUT_NC_FILES, then in
% DIR_INPUT_EDAC_NC_FILES
%
% 4- When QC updates modify at least one QC of the target file, it is updated.
% The SCOOP QC entries of the HISTORY section of the Qc file are then duplicated
% in the associated C-PROF and/or B-PROF files (depending on HISTORY_PARAMETER).
%
% SYNTAX :
%   nc_copy_synthetic_profile_qc or nc_copy_synthetic_profile_qc(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - V 1.0: creation
%   11/28/2023 - RNU - V 1.1: anomaly in copy of SCOOP action from QC file to C
%                             or B PROF file.
%   12/04/2023 - RNU - V 1.2: uninitialized variable.
%   01/22/2024 - RNU - V 1.3: uninitialized variable.
% ------------------------------------------------------------------------------
function nc_copy_synthetic_profile_qc(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% top directory of input NetCDF files containing the Qc values
% (top directory of the DAC name directories)
DIR_INPUT_QC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF\TEST_20240122\dbqc\';

% top directory of input NetCDF files to be updated
% (E-DAC, thus top directory of the DAC name directories)
DIR_INPUT_EDAC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF\TEST_20240122\edac\';

% top directory of input S-PROF and META NetCDF files
% (G-DAC, thus top directory of the DAC name directories)
DIR_INPUT_GDAC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF\TEST_20240122\gdac\';

% top directory of output NetCDF updated files
% (top directory of the DAC name directories)
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF\TEST_20240122\out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the csv file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv';

% flag to print QC updated values
VERBOSE_MODE = 0;

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% RT processing flag
global g_cocsq_realtimeFlag;
g_cocsq_realtimeFlag = 0;

% program version
global g_cocsq_ncCopySyntheticProfileQcVersion;
g_cocsq_ncCopySyntheticProfileQcVersion = '1.3';

% date of the run
global g_cocsq_nowUtc;
g_cocsq_nowUtc = now_utc;

global g_cocsq_verboseMode;
g_cocsq_verboseMode = VERBOSE_MODE;

% default values initialization
init_default_values;


% input parameters management
if (nargin == 0)
   % all the floats of the DIR_INPUT_QC_NC_FILES directories should be processed
   floatList = [];
   dirNames1 = dir(DIR_INPUT_QC_NC_FILES);
   for idDir1 = 1:length(dirNames1)
      
      dirName1 = dirNames1(idDir1).name;
      if (strcmp(dirName1, '.') || strcmp(dirName1, '..'))
         continue
      end           
      dirPathName1 = [DIR_INPUT_QC_NC_FILES '/' dirName1];

      dirNames2 = dir(dirPathName1);
      for idDir2 = 1:length(dirNames2)

         dirName2 = dirNames2(idDir2).name;
         if (strcmp(dirName2, '.') || strcmp(dirName2, '..'))
            continue
         end
         floatList = [floatList; str2num(dirName2)];
      end
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_copy_synthetic_profile_qc_' datestr(g_cocsq_nowUtc, 'yyyymmddTHHMMSS') '.log'];

% process the files according to input and configuration parameters
nc_copy_synthetic_profile_qc_(floatList, logFile, ...
   DIR_INPUT_QC_NC_FILES, ...
   DIR_INPUT_EDAC_NC_FILES, ...
   DIR_INPUT_GDAC_NC_FILES, ...
   DIR_OUTPUT_NC_FILES, ...
   DIR_LOG_FILE, ...
   DIR_CSV_FILE);

return
