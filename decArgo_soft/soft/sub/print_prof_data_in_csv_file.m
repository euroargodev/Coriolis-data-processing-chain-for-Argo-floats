% ------------------------------------------------------------------------------
% Print profile data in output CSV file.
%
% SYNTAX :
%  print_prof_data_in_csv_file(a_profData)
%
% INPUT PARAMETERS :
%   a_profData : profile data structure
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
function print_prof_data_in_csv_file(a_profData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (~isempty(a_profData))
   
   format1 = [];
   format2 = [];
   data = [];
   format1 = [format1 '%d'];
   data{end+1} = g_decArgo_floatNum;
   format1 = [format1 ';%d'];
   data{end+1} = g_decArgo_cycleNum;
   format1 = [format1 ';Asc prof'];
   format1 = [format1 ';-'];
   
   fprintf(g_decArgo_outputCsvFileId, format1, data{:});
   fprintf(g_decArgo_outputCsvFileId, ';Description');
   paramList = a_profData.paramList;
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
   if (~isempty(a_profData.dataAdj))
      fprintf(g_decArgo_outputCsvFileId, ';');
      format2 = [format2 ';'];
      for idP = 1:length(paramList)
         fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', [paramList(idP).name '_ADJUSTED'], paramList(idP).units);
         format2 = [format2 ';' paramList(idP).cFormat];
      end
   end
   fprintf(g_decArgo_outputCsvFileId, '\n');
   format2 = [format2 '\n'];
   
   paramData = a_profData.data;
   paramDataRed = a_profData.dataRed;
   paramDataAdj = a_profData.dataAdj;
   for idL = 1:size(paramData, 1)
      if (~isempty(paramDataAdj))
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';Asc. profile meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataRed(idL, :), paramDataAdj(idL, :));
      else
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';Asc. profile meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataRed(idL, :));
      end
   end
   
end

return
