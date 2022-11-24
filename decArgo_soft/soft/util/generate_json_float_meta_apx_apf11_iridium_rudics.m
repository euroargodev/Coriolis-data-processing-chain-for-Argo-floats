% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_apx_apf11_iridium_rudics()
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
%   11/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_apf11_iridium_rudics()

% meta-data file exported from Coriolis data base
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DBexport_Finland_APF11_Rudics_from_VB_20181023.txt';

% list of concerned floats
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11_iridium-rudics_all.txt';

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
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_apx_apf11_iridium_rudics_' currentTime '.log'];
diary(logFileName);

% generate JSON meta-data files
rudicsFlag = 1;
generate_json_float_meta_apx_apf11_iridium_(...
   FLOAT_META_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   OUTPUT_DIR_NAME, ...
   DIR_CSV_FILE, ...
   rudicsFlag);

diary off;

return;
