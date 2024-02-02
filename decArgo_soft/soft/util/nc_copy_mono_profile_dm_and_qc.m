% ------------------------------------------------------------------------------
% Copy, in a RT profile file, DM data and QC values set by the Coriolis SCOOP
% tool.
% We use 2 data set:
% - the OLD one is supposed to contain DM data and SCOOP QC values
% - the NEW one is supposed to be a direct decoder output
% The final data set contains only files from OLD data set that have DM
% data or SCOOP QC. The provided files are based on a duplication of NEW
% data set files, then updated with OLD dataset DM and SCOOP QCs.
% Note also that the copy of DM data and the report of SCOOP QCs is performed
% for all parameters except those provided in a list (named
% IGNORED_PARAMETER_LIST below).
%
% SYNTAX :
%   nc_copy_mono_profile_dm_and_qc(varargin)
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
%   08/10/2018 - RNU - creation
%   08/10/2018 - RNU - V 1.0: creation
%   06/18/2019 - RNU - V 1.1: some variables indexed by N_PROF are not
%                             copied from OLD file (Ex: FLOAT_SERIAL_NO) but
%                             kept from NEW file so that an update of such
%                             parameter in the data base will be reported in
%                             all N_PROF of the output file
%   06/21/2019 - RNU - V 1.2: update of the list of variables mentioned in
%                             the V 1.1
%   10/09/2019 - RNU - V 1.3: more than one B parameter can be ignored in
%                             the report of SCOOP QCs (IGNORED_PARAMETER
%                             replaced by IGNORED_PARAMETER_LIST)
%   10/14/2019 - RNU - V 1.4: added management of 'DOWN_IRRADIANCE443' and
%                             'DOWN_IRRADIANCE555' parameters
%   11/04/2020 - RNU - V 1.5: copy, in NEW file, the global attributes only
%                             present in OLD file
%   11/12/2020 - RNU - V 1.6: correction of a bug in the copy of
%                             UV_INTENSITY_NITRATE data in output file
%   03/26/2021 - RNU - V 1.7: for ignored parameters, the PARAMETER_DATA_MODE of
%                             the old file should be replaced by the new file
%                             one (and the DATA_MODE processed accordingly).
%   07/08/2022 - RNU - V 1.8: manage case where:
%                             - statistical parameters become 'I' parameters
%                             from old to new file.
%                             - MTIME and NB_SAMPLE_CTD have been moved from
%                             B-PROF to C-PROF.
%                             - fillValue of RAW_DOWNWELLING_PAR and
%                             RAW_DOWNWELLING_IRRADIANCE* has been modified
%                             - fillValue of NB_SAMPLE_CTD and NB_SAMPLE_SFET
%                             has been modified
%   09/06/2022 - RNU - V 1.9: simplified version of 1.8 when both OLD and NEW
%                             files have the same parameters, fillValues, etc...
%   09/15/2022 - RNU - V 1.10: finalize output data set (when a BD file
%                              disapeared)
%   09/15/2022 - RNU - V 1.11: version of 
%                              nc_copy_mono_profile_dm_and_qc_specific only
%   10/03/2022 - RNU - V 1.12: creation of the RT version of the tool
%   09/11/2023 - RNU - V 1.13: all parameter data of DATA_MODE(N_PROF) = 'D'
%                              were copied (without considering
%                              PARAMETER_DATA_MODE(N_ PROF, N_PARAM)). The
%                              copy should concern only parameter data with
%                              PARAMETER_DATA_MODE(N_ PROF, N_PARAM) = 'D'
%   09/13/2023 - RNU - V 1.14: added KEEP_PROFILE_LOCATION_FOR_ALL_FLAG to
%                              report the location information of the first DM
%                              profile on all the profiles of the file
%   09/19/2023 - RNU - V 1.15: error while accessing to PARAMETER(N_PROF,
%                              N_CALIB, N_PARAM, STRING16)
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_dm_and_qc(varargin)

% list of PARAMETER names that should not be considered in the report of DM data
% and SCOOP QCs (only 'B' parameters should be provided; their associated 'I'
% parameters will also be ignored)
% IGNORED_PARAMETER_LIST = [ ...
%    {'DOWN_IRRADIANCE380'} ...
%    {'DOWN_IRRADIANCE412'} ...
%    {'DOWN_IRRADIANCE490'} ...
%    {'DOWNWELLING_PAR'} ...
%    ];
% IGNORED_PARAMETER_LIST = [ ...
%    {'NITRATE'} ...
%    {'DOXY'} ...
%    ];
IGNORED_PARAMETER_LIST = [ ...
   ];

% information to set in 'HISTORY_REFERENCE (N_HISTORY, STRING64)' for the
% current action (64 characters max)
HISTORY_REFERENCE = 'http://doi.org/10.17882/42182';

% top directory of OLD input NetCDF files containing the Qc values and DM
% data
DIR_INPUT_OLD_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_DM_REPORT\DIR_INPUT_OLD_NC_FILES\';

% top directory of NEW input NetCDF files
DIR_INPUT_NEW_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_DM_REPORT\DIR_INPUT_NEW_NC_FILES\';

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_DM_REPORT\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% keep DM profile location information in output file
KEEP_PROFILE_LOCATION_FLAG =  1;

% when KEEP_PROFILE_LOCATION_FLAG =1, you can choose to report the first DM
% profile location information on all the profiles (DM or RT) of the file
KEEP_PROFILE_LOCATION_FOR_ALL_FLAG =  1;

% RT processing flag
global g_cocd_realtimeFlag;
g_cocd_realtimeFlag = 0;

% program version
global g_cocd_ncCopyMonoProfileDmAndQcVersion;
g_cocd_ncCopyMonoProfileDmAndQcVersion = '1.15';

% information to set in 'HISTORY_REFERENCE (N_HISTORY, STRING64);' for the current action
global g_cocd_historyReferenceToReport;
g_cocd_historyReferenceToReport = HISTORY_REFERENCE;

% list of updated files
global g_cocd_updatedFileNameList;
g_cocd_updatedFileNameList = [];

% list of deleted files
global g_cocd_deletedFileNameList;
g_cocd_deletedFileNameList = [];

% flag to keep DM profile location
global g_cocd_reportProfLocFlag;
global g_cocd_reportProfLocAllFlag;
g_cocd_reportProfLocFlag = KEEP_PROFILE_LOCATION_FLAG;
g_cocd_reportProfLocAllFlag = KEEP_PROFILE_LOCATION_FOR_ALL_FLAG;


% default values initialization
init_default_values;

% input parameters management
if (nargin == 0)
   % all the floats of the DIR_INPUT_NEW_NC_FILES directory should be processed
   floatList = [];
   dirNames = dir([DIR_INPUT_NEW_NC_FILES '/*']);
   for idDir = 1:length(dirNames)
      
      dirName = dirNames(idDir).name;
      dirPathName = [DIR_INPUT_NEW_NC_FILES '/' dirName];
      
      if (isdir(dirPathName))
         if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
            floatList = [floatList; str2num(dirName)];
         end
      end
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
logFileName = [DIR_LOG_FILE '/' 'nc_copy_mono_profile_dm_and_qc_' datestr(now, 'yyyymmddTHHMMSS') '.log'];

% process the files according to input and configuration parameters
nc_copy_mono_profile_dm_and_qc_(floatList, logFileName, ...
   DIR_INPUT_OLD_NC_FILES, ...
   DIR_INPUT_NEW_NC_FILES, ...
   DIR_OUTPUT_NC_FILES, ...
   IGNORED_PARAMETER_LIST, ...
   DIR_LOG_FILE);

return
