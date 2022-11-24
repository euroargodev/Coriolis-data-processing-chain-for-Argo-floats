% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_arvor_c_ir_sbd()
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
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_arvor_c_ir_sbd()

% meta-data file exported from Coriolis data base
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\ARVORC_dbExport.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\DB_export_ArvorC_20220912.txt';

% list of concerned floats
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_c_5.3_5.301_all.txt';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_arvor_c_ir_sbd_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
generate_json_float_meta_arvor_c_ir_sbd_(...
   FLOAT_META_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   OUTPUT_DIR_NAME);

diary off;

return
