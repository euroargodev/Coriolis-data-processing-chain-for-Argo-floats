% ------------------------------------------------------------------------------
% Print parking data in output CSV file.
%
% SYNTAX :
%  print_park_data_in_csv_file(a_parkData)
%
% INPUT PARAMETERS :
%   a_parkData : parking data structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function print_park_data_in_csv_file(a_parkData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (~isempty(a_parkData))
   
   format1 = [];
   format2 = [];
   data = [];
   format1 = [format1 '%d'];
   data{end+1} = g_decArgo_floatNum;
   format1 = [format1 ';%d'];
   data{end+1} = g_decArgo_cycleNum;
   format1 = [format1 ';Park'];
   format1 = [format1 ';-'];
   
   fprintf(g_decArgo_outputCsvFileId, format1, data{:});
   fprintf(g_decArgo_outputCsvFileId, ';Description');
   paramList = a_parkData.paramList;
   for idP = 1:length(paramList)
      fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', paramList(idP).name, paramList(idP).units);
      format2 = [format2 ';' paramList(idP).cFormat];
   end
   fprintf(g_decArgo_outputCsvFileId, ';');
   format2 = [format2 ';'];
   for idP = 1:length(paramList)
      fprintf(g_decArgo_outputCsvFileId, ';%s red', paramList(idP).name);
      format2 = [format2 ';%d'];
   end
   if (~isempty(a_parkData.dataAdj))
      fprintf(g_decArgo_outputCsvFileId, ';');
      format2 = [format2 ';'];
      for idP = 1:length(paramList)
         fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', [paramList(idP).name '_ADJUSTED'], paramList(idP).units);
         format2 = [format2 ';' paramList(idP).cFormat];
      end
   end
   fprintf(g_decArgo_outputCsvFileId, '\n');
   format2 = [format2 '\n'];
   
   paramData = a_parkData.data;
   paramDataRed = a_parkData.dataRed;
   paramDataAdj = a_parkData.dataAdj;
   for idL = 1:size(paramData, 1)
      if (~isempty(paramDataAdj))
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';End park meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataRed(idL, :), paramDataAdj(idL, :));
      else
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';End park meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataRed(idL, :));
      end
   end
   
end

return
