% ------------------------------------------------------------------------------
% Print float configuration in output CSV file.
%
% SYNTAX :
%  print_config_in_csv_file_121(a_comment)
%
% INPUT PARAMETERS :
%   a_comment : additional comment
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_config_in_csv_file_121(a_comment)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% float configuration
global g_decArgo_floatConfig;


% retrieve the TMP configuration
configNums = g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER;
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES;

% print the TMP configuration
fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
   a_comment, 'Configuration number', configNums(1, end));
for idL = 1:length(configNames)
   fprintf(g_decArgo_outputCsvFileId, '%d;%s;%s;%s;-;%s;%g\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
      a_comment, configNames{idL}, configValues(idL, end));
end

return;
