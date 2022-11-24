% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_prv_cts4_ir_rudics
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
%   06/17/2013 - RNU - creation
%   09/01/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function generate_json_float_meta_prv_cts4_ir_rudics

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 1;

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
   CALIB_FILE_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS4/DataFromFloatToMeta/CalibCoef/calib_coef.txt';

   % directory of individual configuration commands report files
   CONFIG_DIR_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS4/ConfigAtLaunch';

   % directory of SUNA calibration files
   SUNA_CALIB_DIR_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS4/meta_remocean_www/suna_calibration_file';

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
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\CTS4_6.14_with_2BB_6904134_DBexport.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\_DATA\IN\decArgo_config_floats\argoFloatInfo\float_sensor_list.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

   % calibration coefficient file decoded from data
   CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS4\DataFromFloatToMeta\CalibCoef\calib_coef.txt';

   % directory of individual configuration commands report files
   CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS4\meta_remocean_www\ConfigAtLaunch\';

   % directory of SUNA calibration files
   SUNA_CALIB_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS4\meta_remocean_www\suna_calibration_file\';

   % directory of individual json float meta-data files
   OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

   % directory to store the log file
   DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

   % JPR CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_prv_cts4_ir_rudics_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
generate_json_float_meta_prv_cts4_ir_rudics_(...
   FLOAT_META_FILE_NAME, ...
   SENSOR_LIST_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CALIB_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   SUNA_CALIB_DIR_NAME, ...
   OUTPUT_DIR_NAME);

diary off;

return
