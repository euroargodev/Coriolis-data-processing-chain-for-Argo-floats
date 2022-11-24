% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_apx_apf11_iridium_sbd()
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_apf11_iridium_sbd()

% meta-data file exported from Coriolis data base
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_Iridium-SBD_from_VB_20180410.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APEX_APF11Bio_frm_VB_20180615.txt';

% list of concerned floats
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-sbd_2.10.1.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-sbd_2.11.1.txt';

% directory of configuration files at launch
CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\_ConfigAtLaunch\';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% directory to store the CSV file (when DB update is needed)
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_apx_apf11_iridium_sbd_' currentTime '.log'];
diary(logFileName);

% generate JSON meta-data files
rudicsFlag = 0;
generate_json_float_meta_apx_apf11_iridium_(...
   FLOAT_META_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   OUTPUT_DIR_NAME, ...
   DIR_CSV_FILE, ...
   rudicsFlag);

diary off;

return;
