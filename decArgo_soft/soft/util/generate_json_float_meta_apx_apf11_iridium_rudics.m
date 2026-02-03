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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_apf11_iridium_rudics()

% meta-data file exported from Coriolis data base
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\Desktop\SOS_VB_apx_olaf\dbExport_Olaf.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\Desktop\SOS_VB_HISTO\SOS_VB_apx_olaf2\dbexport_ApexOlaf2.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\db_export_APF11_2.18.1_7900989.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\dbexport_7900563_pour_ramses.txt';

% list of sensors mounted on floats
SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_info\_float_sensor_list\float_sensor_list.txt';

% list of concerned floats
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\Desktop\SOS_VB_apx_olaf\_apex_olaf.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\Desktop\SOS_VB_HISTO\SOS_VB_apx_olaf2\_apex_olaf2.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';

% calibration coefficient file
CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\_CalibCoef\calib_coef.txt';

% directory of configuration files at launch
CONFIG_DIR_NAME = 'C:\Users\jprannou\Desktop\SOS_VB_apx_olaf\';
CONFIG_DIR_NAME = 'C:\Users\jprannou\Desktop\SOS_VB_HISTO\SOS_VB_apx_olaf2\ConfigAtLaunch\';
% CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\_ConfigAtLaunch\';

% directory of RAMSES calibration files
RAMSES_CALIB_DIR_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\_ramses_calibration_file\';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the CSV file (when DB update is needed)
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_apx_apf11_iridium_rudics_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
rudicsFlag = 1;
rtVersionFlag = 0;
generate_json_float_meta_apx_apf11_iridium_(...
   FLOAT_META_FILE_NAME, ...
   SENSOR_LIST_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CALIB_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   RAMSES_CALIB_DIR_NAME, ...
   OUTPUT_DIR_NAME, ...
   DIR_CSV_FILE, ...
   rudicsFlag, ...
   rtVersionFlag);

diary off;

return
