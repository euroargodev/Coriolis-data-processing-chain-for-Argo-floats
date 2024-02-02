% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_prv_cts5_ir_rudics
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
%   02/21/2017 - RNU - creation
%   09/04/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function generate_json_float_meta_prv_cts5_ir_rudics

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 0;

if (CORIOLIS_CONFIGURATION_FLAG)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - START

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = '/home/idmtmp7/vincent/matlab/DB_export/new_rem_meta.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = '/home/coriolis_exp/binlx/co04/co0414/co041404/decArgo_config_floats/argoFloatInfo/float_sensor_list.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = '/home/idmtmp7/vincent/matlab/list/new_rem.txt';

   % calibration coefficient file decoded from data
   CALIB_FILE_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS5/DataFromFloatToMeta/CalibCoef/calib_coef.txt';

   % directory of launch configuration for each float
   CONFIG_DIR_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS5/ConfigAtLaunch';

   % directory of SUNA calibration files
   SUNA_CALIB_DIR_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS5/meta_remocean_www/suna_calibration_file';

   % directory of individual json float meta-data files
   OUTPUT_DIR_NAME = ['/home/idmtmp7/vincent/matlab/generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

   % directory to store the log file
   DIR_LOG_FILE = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/log/';

   % CORIOLIS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - START

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\OneDrive - Capgemini\Desktop\SOS_VB\new_rem_meta.txt';
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\db_export_4903784_7.18.txt';
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_Jumbo.txt';
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_CTS5-USEA_6903069.txt';
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_CTS5_USEA_6903093.txt';
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_CTS5_UVP_6902968.txt';
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\dbExport_UVP.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\OneDrive - Capgemini\Desktop\SOS_VB\float_sensor_list.txt';
   SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_info\_float_sensor_list\float_sensor_list.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\OneDrive - Capgemini\Desktop\SOS_VB\new_rem.txt';
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_UVP_6904240.txt';
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_UVP_6903069.txt';
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_UVP_6903093.txt';
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_UVP_6902968.txt';
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_UVP_ko.txt';

   % calibration coefficient file decoded from data
   CALIB_FILE_NAME = 'C:\Users\jprannou\OneDrive - Capgemini\Desktop\SOS_VB\calib_coef.txt';
   CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS5\CTS5_float_config\DataFromFloatToMeta\CalibCoef\calib_coef.txt';

   % directory of launch configuration for each float
   CONFIG_DIR_NAME = 'C:\Users\jprannou\OneDrive - Capgemini\Desktop\SOS_VB\';
   CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS5\CTS5_float_config\ConfigAtLaunch\';

   % directory of SUNA calibration files
   SUNA_CALIB_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS5\CTS5_float_config\meta_CTS5_www\suna_calibration_file\';

   % directory of individual json float meta-data files
   OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

   % directory to store the log file
   DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

   % JPR CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

% default values initialization
init_default_values;


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_prv_cts5_ir_rudics_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
rtVersionFlag = 0;
generate_json_float_meta_prv_cts5_ir_rudics_(...
   FLOAT_META_FILE_NAME, ...
   SENSOR_LIST_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CALIB_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   SUNA_CALIB_DIR_NAME, ...
   OUTPUT_DIR_NAME, ...
   DIR_LOG_FILE, ...
   rtVersionFlag);

diary off;

return
