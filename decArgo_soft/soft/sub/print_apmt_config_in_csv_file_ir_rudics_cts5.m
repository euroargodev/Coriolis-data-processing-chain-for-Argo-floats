% ------------------------------------------------------------------------------
% Print APMT configuration data in output CSV file.
%
% SYNTAX :
%  print_apmt_config_in_csv_file_ir_rudics_cts5(a_configData)
%
% INPUT PARAMETERS :
%   a_configData : APMT configuration data
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
function print_apmt_config_in_csv_file_ir_rudics_cts5(a_configData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_configData))
   return;
end

fileTypeStr = 'Config_APMT';
fieldNames = fieldnames(a_configData);
for idF = 1:length(fieldNames)
   section = fieldNames{idF};
   dataNumList = a_configData.(section).num;
   dataNameList = a_configData.(section).name;
   dataFmtList = a_configData.(section).fmt;
   dataValueList = a_configData.(section).data;
   for idI = 1:length(dataNameList)
      dataNum = dataNumList{idI};
      dataName = dataNameList{idI};
      dataFmt = dataFmtList{idI};
      dataValue = dataValueList{idI};
      if (strncmp(section, 'PATTERN_', length('PATTERN_')) && ...
            (dataNum == 0) && (strcmp(dataValue, 'False')))
         break;
      end
      if (~isempty(dataFmt))
         dataValueStr = sprintf(dataFmt, dataValue);
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; P%02d: %s;"%s"\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, section, dataNum, dataName, dataValueStr);
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; P%02d: %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, section, dataNum, dataName);
      end
   end
end

return;
