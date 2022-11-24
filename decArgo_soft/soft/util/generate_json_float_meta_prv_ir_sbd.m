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

% meta-data file exported from Coriolis data base
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\deep_norway_6903557.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\db_export_6901471_pour_codage_slope_adj_rt.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\6903268_DBexport.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\5900A05_DBexport.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\calib_error_method_v2.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\db_export_5.47_with_DO_3902110.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\db_export_Arvor_bad_decId_20201012.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_RBR_6903075_6903076.txt';

% list of concerned floats
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_5.66.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\test_doxy_adj_err_5.46_5.74.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_rbr_5.49.txt';

% directory of RBR CTD metadata files
RBR_META_DATA_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_WITH_RBR\RBR_META_DATA_FILES\';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


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
