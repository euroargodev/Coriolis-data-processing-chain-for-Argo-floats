% ------------------------------------------------------------------------------
% Print log and msg file names in CSV file.
%
% SYNTAX :
%  print_file_info_in_csv_file(a_msgFileList, a_logFileList)
%
% INPUT PARAMETERS :
%   a_msgFileList : msg file name
%   a_logFileList : log file names list
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_file_info_in_csv_file(a_msgFileList, a_logFileList)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


% fprintf(g_decArgo_outputCsvFileId, '%d; %d; Info; -; IRIDIUM DATA FILE CONTENTS\n', ...
%    g_decArgo_floatNum, g_decArgo_cycleNum);

for id = 1:length(a_msgFileList)
   [~, fileName, ext] = fileparts(a_msgFileList{id});
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; Msg; -; Msg data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
end
   
for id = 1:length(a_logFileList)
   [~, fileName, ext] = fileparts(a_logFileList{id});
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; Log; -; Log data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
end

return;
