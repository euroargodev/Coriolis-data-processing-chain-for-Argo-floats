% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_prv_ir_sbd()
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
%   10/15/2014 - RNU - creation
%   09/01/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function generate_json_float_meta_prv_ir_sbd()

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 1;

if (CORIOLIS_CONFIGURATION_FLAG)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - START

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = '/home/idmtmp7/vincent/matlab/DB_export/new_iridium_meta.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = '/home/idmtmp7/vincent/matlab/list/new_iridium.txt';

   % directory of RBR CTD metadata files
   RBR_META_DATA_DIR_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/RBR_metadata';

   % directory of individual json float meta-data files
   OUTPUT_DIR_NAME = ['/home/idmtmp7/vincent/matlab/generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

   % directory to store the log file
   DIR_LOG_FILE = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/log';

   % CORIOLIS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - START

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\db_export_6901471_pour_codage_slope_adj_rt.txt';

   % list of concerned floats
   FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

   % directory of RBR CTD metadata files
   RBR_META_DATA_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_WITH_RBR\RBR_META_DATA_FILES\';

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
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_prv_ir_sbd_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
generate_json_float_meta_prv_ir_sbd_(...
   FLOAT_META_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   RBR_META_DATA_DIR_NAME, ...
   OUTPUT_DIR_NAME);

diary off;

return
