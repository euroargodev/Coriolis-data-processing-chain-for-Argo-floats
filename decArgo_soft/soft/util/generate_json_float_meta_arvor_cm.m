% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_arvor_cm
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
%   11/10/2015 - RNU - creation
%   09/04/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function generate_json_float_meta_arvor_cm

% meta-data file exported from Coriolis data base
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\Arvor-Cm-Bio\DBexport_arvorCM_fromVB20151030.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_DOXY_from_VB_20160518.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\Desktop\MAJ_REM_20170306\DBexport_BioArgo_from_VB_20170307.txt';
% FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\Remocean\MAJ_REM_20170306\DBexport_BioArgo_from_VB_20170307.txt';
FLOAT_META_FILE_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\database_export\float_metadata.txt';

% list of concerned floats
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_cm.txt';
FLOAT_LIST_FILE_NAME = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\TEMPO_check_generate_meta\database_export\provor_float_list.txt';

% calibration coefficient file decoded from data
% CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\Remocean\DataFromFloatToMeta\CalibCoef\calib_coef.txt';
CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS5\CTS5_float_config\DataFromFloatToMeta\CalibCoef\calib_coef.txt';

% directory of individual configuration commands report files
% CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\Remocean\ConfigAtLaunch\ArvorCM\';
CONFIG_DIR_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS4\meta_remocean_www\ConfigAtLaunch\ArvorCM\';

% directory of individual json float meta-data files
OUTPUT_DIR_NAME = ['F:\NEW_20190125\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% directory to store the log file
DIR_LOG_FILE = 'F:\NEW_20190125\_RNU\DecArgo_soft\work\';


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% log file creation
logFileName = [DIR_LOG_FILE '/generate_json_float_meta_arvor_cm_' currentTime '.log'];
diary(logFileName);

fprintf('Log file: %s\n', logFileName);

% generate JSON meta-data files
generate_json_float_meta_arvor_cm_(...
   FLOAT_META_FILE_NAME, ...
   FLOAT_LIST_FILE_NAME, ...
   CALIB_FILE_NAME, ...
   CONFIG_DIR_NAME, ...
   OUTPUT_DIR_NAME);

diary off;

return
