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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/07/2020 - RNU - creation
% ------------------------------------------------------------------------------
function select_float_list

% float reference file list
FLOAT_REFERENCE_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\provor_float_info_20201006.txt';
% FLOAT_REFERENCE_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\apex_float_info_20201006.txt';
% FLOAT_REFERENCE_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\nova_float_info_20201006.txt';
% FLOAT_REFERENCE_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp16.txt';

% float file list to select
FLOAT_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_nke_prv_ir.txt';
FLOAT_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_apx_argos.txt';
FLOAT_LIST = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmpAll_nke_arvor_cm.txt';

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
