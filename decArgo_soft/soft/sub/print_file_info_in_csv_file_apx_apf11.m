% ------------------------------------------------------------------------------
% Print float file names in CSV file.
%
% SYNTAX :
%  print_file_info_in_csv_file_apx_apf11( ...
%    a_scienceLogFileList, a_vitalsLogFileList, ...
%    a_systemLogFileList, a_criticalLogFileList)
%
% INPUT PARAMETERS :
%   a_scienceLogFileList : list of science_log files
%   a_vitalsLogFileList : list of vitals_log files
%   a_systemLogFileList : list of system_log files
%   a_criticalLogFileList : list of critical_log files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_file_info_in_csv_file_apx_apf11( ...
   a_scienceLogFileList, a_vitalsLogFileList, ...
   a_systemLogFileList, a_criticalLogFileList)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


for id = 1:length(a_scienceLogFileList)
   [~, fileName, ext] = fileparts(a_scienceLogFileList{id});
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; Sci; -; science_log data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
end
   
for id = 1:length(a_vitalsLogFileList)
   [~, fileName, ext] = fileparts(a_vitalsLogFileList{id});
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; Vit; -; vitals_log data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
end

for id = 1:length(a_systemLogFileList)
   [~, fileName, ext] = fileparts(a_systemLogFileList{id});
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; Sys; -; system_log data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
end

for id = 1:length(a_criticalLogFileList)
   [~, fileName, ext] = fileparts(a_criticalLogFileList{id});
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; File info; Cri; -; critical_log data file name; %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, [fileName ext]);
end

return;
