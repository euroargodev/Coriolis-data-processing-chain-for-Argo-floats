% ------------------------------------------------------------------------------
% Print AST data in output CSV file.
%
% SYNTAX :
%  print_ast_data_in_csv_file(a_astData)
%
% INPUT PARAMETERS :
%   a_astData : AST data structure
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function print_ast_data_in_csv_file(a_astData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (~isempty(a_astData))
   
   format1 = [];
   format2 = [];
   data = [];
   format1 = [format1 '%d'];
   data{end+1} = g_decArgo_floatNum;
   format1 = [format1 ';%d'];
   data{end+1} = g_decArgo_cycleNum;
   format1 = [format1 ';Ast'];
   format1 = [format1 ';-'];
   
   fprintf(g_decArgo_outputCsvFileId, format1, data{:});
   fprintf(g_decArgo_outputCsvFileId, ';Description');
   paramList = a_astData.paramList;
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
   if (~isempty(a_astData.dataAdj))
      fprintf(g_decArgo_outputCsvFileId, ';');
      format2 = [format2 ';'];
      for idP = 1:length(paramList)
         fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', [paramList(idP).name '_ADJUSTED'], paramList(idP).units);
         format2 = [format2 ';' paramList(idP).cFormat];
      end
   end
   fprintf(g_decArgo_outputCsvFileId, '\n');
   format2 = [format2 '\n'];
   
   paramData = a_astData.data;
   paramDataRed = a_astData.dataRed;
   paramDataAdj = a_astData.dataAdj;
   for idL = 1:size(paramData, 1)
      if (~isempty(paramDataAdj))
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';Ascent start meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataRed(idL, :), paramDataAdj(idL, :));
      else
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';Ascent start meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataRed(idL, :));
      end
   end
   
end

return
