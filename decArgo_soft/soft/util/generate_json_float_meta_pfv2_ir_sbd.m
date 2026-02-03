% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and store it in META.json
% file.
%
% SYNTAX :
%  generate_json_float_meta_pfv2_ir_sbd()
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
%   09/17/2024 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_pfv2_ir_sbd()

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 0;

if (CORIOLIS_CONFIGURATION_FLAG)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - START

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = '/home/idmtmp7/vincent/matlab/DB_export/new_iridium_meta.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = '/home/coriolis_exp/binlx/co04/co0414/co041404/decArgo_config_floats/argoFloatInfo/float_sensor_list.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = '/home/idmtmp7/vincent/matlab/list/new_iridium.txt';

   % directory of launch configuration for each float
   CONFIG_DIR_NAME = TBD;

   % directory of RBR CTD metadata files
   RBR_META_DATA_DIR_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/RBR_metadata';

   % directory of individual json float meta-data files
   OUTPUT_DIR_NAME = ['/home/idmtmp7/vincent/matlab/generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

   % directory to store the log file
   DIR_LOG_FILE = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/log';

   % directory of Iridium email files
   DIR_INPUT_RSYNC_DATA = TBD;

   % temporary directory used to decode received XML settings files
   TMP_DIR_NAME = TBD;

   % CORIOLIS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - START

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\6990728_PFV2_8.02_dbExport.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_info\_float_sensor_list\float_sensor_list.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmpPfv2.txt';

   % directory of launch configuration for each float
   CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_ARVOR\PFV2_ConfigAtLaunch\';

   % directory of RBR CTD metadata files
   RBR_META_DATA_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_WITH_RBR\RBR_META_DATA_FILES\';

   % directory of individual json float meta-data files
   OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

   % directory to store the log file
   DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

   % directory of Iridium email files
   DIR_INPUT_RSYNC_DATA = 'C:\Users\jprannou\_DATA\IN\RSYNC\CTS3\rsync_data\';

   % temporary directory used to decode received XML settings files
   TMP_DIR_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\tmp\';

   % JPR CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_pfv2_ir_sbd_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
rtVersionFlag = 0;
generate_json_float_meta_pfv2_ir_sbd_(...
   FLOAT_META_FILE_NAME, ...
   SENSOR_LIST_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   RBR_META_DATA_DIR_NAME, ...
   OUTPUT_DIR_NAME, ...
   DIR_INPUT_RSYNC_DATA, ...
   TMP_DIR_NAME, ...
   currentTime, ...
   rtVersionFlag);

diary off;

return
