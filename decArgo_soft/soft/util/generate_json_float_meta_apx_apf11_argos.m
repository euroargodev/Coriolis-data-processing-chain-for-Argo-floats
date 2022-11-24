% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_apx_apf11_argos()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_apf11_argos()

% meta-data file exported from Coriolis data base
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_Argos_from_VB_20171204.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_Argos_lot2&3_from_VB_20180514.txt';
FLOAT_META_FILE_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\database_export\float_metadata.txt';

% list of concerned floats
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_argos_2.8.0.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_argos_2.10.4.txt';
FLOAT_LIST_FILE_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\database_export\apex_float_list.txt';

% directory of configuration files at launch
% CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\_ConfigAtLaunch\';
CONFIG_DIR_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\ConfigAtLaunch\';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['F:\NEW_20190125\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\';

% directory to store the CSV file (when DB update is needed)
DIR_CSV_FILE = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\';


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_apx_apf11_argos_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
generate_json_float_meta_apx_apf11_argos_(...
   FLOAT_META_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   OUTPUT_DIR_NAME, ...
   DIR_CSV_FILE);

diary off;

return
