% ------------------------------------------------------------------------------
% Check a given list of floats against a reference one (used to select lines of
% a provided list of floats in an Excel file).
%
% SYNTAX :
%   select_float_list
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
%   10/07/2020 - RNU - creation
% ------------------------------------------------------------------------------
function select_float_list

% float reference file list
FLOAT_REFERENCE_LIST = 'F:\ICE_check\ICE_check_lists\_tmp_prv_info.txt';
% FLOAT_REFERENCE_LIST = 'F:\ICE_check\ICE_check_lists\_tmp_apx_info.txt';
FLOAT_REFERENCE_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp_prv_info.txt';

% float file list to select
FLOAT_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp_in_andro.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_212.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_217.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_222.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_223.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_224.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_226.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_214.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_225.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_216.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_218.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\arvor_ice_221.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\config_prv.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\config_apx.txt';
FLOAT_LIST = 'F:\ICE_check\ICE_check_lists\nke_ice_all_ice_detected.txt';
FLOAT_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_check_ice_floats_BK.txt';

% directory to store the CSV file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';


timeInfo = datestr(now, 'yyyymmddTHHMMSS');

fprintf('Float reference list: %s\n', FLOAT_REFERENCE_LIST);
fprintf('Float list: %s\n', FLOAT_LIST);

% floats are checked against a reference list
if ~(exist(FLOAT_REFERENCE_LIST, 'file') == 2)
   fprintf('File not found: %s\n', FLOAT_REFERENCE_LIST);
   return
end
floatRefList = load(FLOAT_REFERENCE_LIST);

% floats to process come from FLOAT_LIST
if ~(exist(FLOAT_LIST, 'file') == 2)
   fprintf('File not found: %s\n', FLOAT_LIST);
   return
end
floatList = load(FLOAT_LIST);

presentFlag = ismember(floatRefList, floatList);

outputFileName = [DIR_CSV_FILE '\select_float_list_' timeInfo '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
   return
end

fprintf(fidOut, 'Float Ref;Used\n');

for idD = 1:length(floatRefList)
   fprintf(fidOut, '%d;%d\n', floatRefList(idD), presentFlag(idD));
end

fclose(fidOut);

return
