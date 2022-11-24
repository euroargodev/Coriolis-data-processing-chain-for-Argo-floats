% ------------------------------------------------------------------------------
% Print .profile file names in CSV file.
%
% SYNTAX :
%  print_file_info_in_csv_file_nemo(a_profileFile)
%
% INPUT PARAMETERS :
%   a_profileFile : .profile file name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_file_info_in_csv_file_nemo(a_profileFile)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


[~, fileName, ext] = fileparts(a_profileFile);
fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; .profile data file name; %s\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);

return
