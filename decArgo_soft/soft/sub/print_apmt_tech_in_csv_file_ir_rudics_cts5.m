% ------------------------------------------------------------------------------
% Print APMT technical data in output CSV file.
%
% SYNTAX :
%  print_apmt_tech_in_csv_file_ir_rudics_cts5(a_techData, a_fileType)
%
% INPUT PARAMETERS :
%   a_techData : APMT technical data
%   a_fileType : input APMT file type
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
function print_apmt_tech_in_csv_file_ir_rudics_cts5(a_techData, a_fileType)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_techData))
   return
end

fileTypeStr = '-';
switch (a_fileType)
   case 3
      fileTypeStr = 'Autotest';
   case 4
      fileTypeStr = 'Technical';
   case 5
      fileTypeStr = 'EndOfLife';
   otherwise
      fprintf('WARNING: Nothing define yet for file type: %d\n', ...
         a_fileType);
end

fieldNames = fieldnames(a_techData);
for idF = 1:length(fieldNames)
   section = fieldNames{idF};
   dataNameList = a_techData.(section).name;
   dataFmtList = a_techData.(section).fmt;
   dataValueList = a_techData.(section).data;
   dataValueStrList = a_techData.(section).dataStr;
   dataValueAdjStrList = a_techData.(section).dataAdjStr;
   for idI = 1:length(dataNameList)
      dataName = dataNameList{idI};
      if (~isempty(dataFmtList))
         dataFmt = dataFmtList{idI};
         dataValue = dataValueList{idI};
         dataValueStr2 = [];
         if (length(dataValueStrList) >= idI)
            dataValueStr2 = dataValueStrList{idI};
            dataValueStr3 = dataValueAdjStrList{idI};
         end
         if (~isempty(dataValue))
            dataValueStr = sprintf(dataFmt, dataValue);
            if (isempty(dataValueStr2))
               fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s;"%s"\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, section, dataName, dataValueStr);
            else
               fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s (adj: %s)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                  fileTypeStr, section, dataName, dataValueStr2, dataValueStr3);
            end
         else
            fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, section, dataName);
         end
      else
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s %s; %s; %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, section, dataName);
      end
   end
end

return
