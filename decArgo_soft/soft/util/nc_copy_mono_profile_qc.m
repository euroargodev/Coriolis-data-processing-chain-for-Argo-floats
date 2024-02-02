% ------------------------------------------------------------------------------
% Report SCOOP QC from a Qc file (DIR_INPUT_QC_NC_FILES) to associated C-PROF
% and/or B-PROF files.
%
% 1- Reported SCOOP QC are retrieved from HISTORY section of Qc file under the
% constrains HISTORY_SOFTWARE = 'SCOO' and HISTORY_ACTION = 'CF', then
% HISTORY_PARAMETER =
% - <PARAM> => update <PARAM>_QC (<PARAM> can be adjusted parameter name)
% - 'DAT$'  => update JULD_QC
% - 'POS$'  => update POSITION_QC
%
% 2- Input files to update are first searched in DIR_OUTPUT_NC_FILES, then in
% DIR_INPUT_NC_FILES
%
% 3- When QC updates modify at least one QC of the target file, it is updated.
% The SCOOP QC entries of the HISTORY section of the Qc file are then duplicated
% in the associated C-PROF and/or B-PROF files (depending on HISTORY_PARAMETER).
%
% SYNTAX :
%   nc_copy_mono_profile_qc or nc_copy_mono_profile_qc(6900189, 7900118)
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
%   04/09/2014 - RNU - creation (original tool working on 3 similar sets of
%                      NetCDF mono-profile files)
%   07/18/2014 - RNU - V 2.0: original tool tuned for Coriolis needs
%   10/28/2014 - RNU - V 2.1: in get_nc_profile_info, the comparison is done
%                             using the format '%.5f' (because bio data are
%                             rounded to 1E-5 in the Coriolis data base)
%   12/23/2014 - RNU - V 2.2: the temporary directory, used to duplicate the
%                             input file before updating its QC values, is now
%                             created in the DIR_INPUT_QC_NC_FILES/WMO/
%                             directory
%   01/14/2015 - RNU - V 2.3: before the string conversion (for the comparison),
%                             the data are rounded to 1.E-5 and the negative
%                             zeros converted to positive ones.
%   01/16/2015 - RNU - V 2.4: manage the case where there is no data in a B file
%                             for a given profile.
%   02/27/2015 - RNU - V 2.5: - in 'c' files, report <PARAM>_ADJUSTED_QC if the
%                             DATA_MODE of the concerned profile is 'A' or 'D'
%                             - in 'b' files, report <PARAM>_ADJUSTED_QC if the
%                             PARAMETER_DATA_MODE of the concerned profile and
%                             parameter is 'A' or 'D'
%   07/03/2015 - RNU - V 2.6: there is only one input directory for the nc files
%                             to be updated (this is the executive DAC). The
%                             first level sub-directories of this executive DAC
%                             are scanned when looking for the file to update.
%   07/06/2015 - RNU - V 2.7: the nc input file to update can have levels where
%                             PRES = FillValue, these levels are not present in
%                             the nc input file containing the QC values.
%   07/07/2015 - RNU - V 2.8: since V 2.7, final QC merged values can differ
%                             from input QC file ones. The PROFILE_<PARAM>_QC
%                             values should then be computed from final QC
%                             merged values (in the previous versions they were
%                             copied from input Qc file  ones.
%   10/20/2015 - RNU - V 2.9: when a D c-file to be updated is found, the
%                             associated b-file can be in D or in R mode.
%   07/11/2016 - RNU - V 3.0: new management of HISTORY information:
%                             - existing HISTORY information of input files is
%                             kept
%                             - HISTORY information of QC file (reporting
%                             Coriolis SCOOP tool actions) is copied in 'c'
%                             or 'b' files (according to HISTORY_PARAMETER
%                             information)
%                             - a last HISTORY step is added to report the use
%                             of the current tool (COCQ)
%   09/28/2016 - RNU - V 3.1: HISTORY information of QC file (reporting Coriolis
%                             Objective Analysis and SCOOP tool actions) is
%                             copied in 'c' or 'b' files (according to
%                             HISTORY_PARAMETER information) only for HISTORY
%                             steps where HISTORY_SOFTWARE is in a pre-defined
%                             list (g_cocq_historySoftwareToReport).
%   10/17/2016 - RNU - V 3.2: Also manage QC flags of adjusted parameters.
%   06/23/2021 - RNU - V 3.3: String comparison is not suitable in some cases
%                             (see DOXY value for PRES level 733.59998 dbar of
%                             6902964 #127) we then compare data measurements
%                             (which should not exceed a 1.e-5 interval).
%   07/01/2021 - RNU - V 3.4: Before comparison, PRES data are rounded to 1.e-3
%                             and other parameters to 1.e-5.
%   09/25/2023 - RNU - V 3.5: Only QC SCOOP flags should be reported.
%   10/17/2023 - RNU - V 3.6: When one HISTORY_START/STOP_PRES matches more than
%                             one level of the profile, we consider it only if:
%                             1- the immersion levels are contiguous 2- the
%                             parameter values of these levels are the same.
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_qc(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% top directory of input NetCDF files containing the Qc values
DIR_INPUT_QC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_NC_COPY_MONO_PROFILE_QC\TEST_20231003\dbqc\';
DIR_INPUT_QC_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_NC_COPY_MONO_PROFILE_QC\TEST_20231017\dbqc\';

% top directory of input NetCDF files to be updated (executive DAC, thus top
% directory of the DAC name directories)
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_NC_COPY_MONO_PROFILE_QC\TEST_20231003\edac\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_NC_COPY_MONO_PROFILE_QC\TEST_20231017\edac\';

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_NC_COPY_MONO_PROFILE_QC\TEST_20231003\out\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_NC_COPY_MONO_PROFILE_QC\TEST_20231017\out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% flag to print QC updated values
VERBOSE_MODE = 0;

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% RT processing flag
global g_cocq_realtimeFlag;
g_cocq_realtimeFlag = 0;

% program version
global g_cocq_ncCopyMonoProfileQcVersion;
g_cocq_ncCopyMonoProfileQcVersion = '3.6';

% verbose mode flag
global g_cocq_verboseMode;
g_cocq_verboseMode = VERBOSE_MODE;

% default values initialization
init_default_values;


% input parameters management
if (nargin == 0)
   % all the floats of the DIR_INPUT_QC_NC_FILES directory should be processed
   floatList = [];
   dirNames = dir([DIR_INPUT_QC_NC_FILES '/*']);
   for idDir = 1:length(dirNames)
      
      dirName = dirNames(idDir).name;
      dirPathName = [DIR_INPUT_QC_NC_FILES '/' dirName];
      
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
logFile = [DIR_LOG_FILE '/' 'nc_copy_mono_profile_qc_' datestr(now, 'yyyymmddTHHMMSS') '.log'];

% process the files according to input and configuration parameters
nc_copy_mono_profile_qc_(floatList, logFile, ...
   DIR_INPUT_QC_NC_FILES, ...
   DIR_INPUT_NC_FILES, ...
   DIR_OUTPUT_NC_FILES, ...
   DIR_LOG_FILE);

return
