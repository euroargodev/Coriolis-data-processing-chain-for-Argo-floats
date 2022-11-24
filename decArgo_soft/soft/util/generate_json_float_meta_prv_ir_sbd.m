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
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150217.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150519.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_JPR_2DO_20150630.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_JPR_ArvorDeep_v2_20150707.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_DOXY_from_VB_20160518.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_ARVOR_I_5-43_21060628.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_ARVOR_I_5-43_21060628.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\Arvor_Ice-5.45\DBexport_ArvorIce_5.45.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\Provor_Do_Ir-5.74\DBexport_CTS3DO_5.74.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\exportJPR_5900A04_from_VB_20170825.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\exportJPR_ArvorDeep_from_VB_20170825.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\db_extract_6901246_6901248_from_FK_20180921.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_export_5.74_5.75_from_VB_20171107.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_DeepIce_5.65_20180201.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\db_export_6901471_pour_codage_slope_adj_rt.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\db_export-3902101_Arvor-Ir-Do_5.46_from_VB_20180216.txt';
FLOAT_META_FILE_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\database_export\float_metadata.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\NEW_20190125\_RNU\DecPrv_info\_configParamNames\DB_Export\6901763_dbexport_inclinometre.txt';

% list of concerned floats
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/arvor_deep_4000.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/arvor_deep_3500.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/arvor_deep.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/coriolis_prv_5.42_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/_nke_ir_sbd_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/provor_do_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/arvor_2do.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_v2.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.45.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.74.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.75.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_5.64.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_5.74_5.75.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_deep_5.65.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_5.46.txt';
% FLOAT_LIST_FILE_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\database_export\provor_float_list.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\NEW_20190125\_RNU\DecArgo_soft\lists\tmp.txt';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['C:\Users\jprannou\NEW_20190125\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\NEW_20190125\_RNU\DecArgo_soft\work\';


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
   OUTPUT_DIR_NAME);

diary off;

return
