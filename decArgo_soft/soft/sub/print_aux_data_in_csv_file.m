% ------------------------------------------------------------------------------
% Print auxiliary engineering data in output CSV file.
%
% SYNTAX :
%  print_aux_data_in_csv_file(a_timeData)
%
% INPUT PARAMETERS :
%   a_timeData : cycle time data structure
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
function print_aux_data_in_csv_file(a_timeData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (~isempty(a_timeData.cycleNum))
   idCy = find([a_timeData.cycleNum] == g_decArgo_cycleNum);
   if (~isempty(idCy))
      if (~isempty(a_timeData.cycleTime(idCy).descPresMark))
         
         format1 = [];
         format2 = [];
         data = [];
         format1 = [format1 '%d'];
         data{end+1} = g_decArgo_floatNum;
         format1 = [format1 ';%d'];
         data{end+1} = g_decArgo_cycleNum;
         format1 = [format1 ';Pres mark'];
         format1 = [format1 ';-'];
         
         fprintf(g_decArgo_outputCsvFileId, format1, data{:});
         fprintf(g_decArgo_outputCsvFileId, ';Description');
         paramList = a_timeData.cycleTime(idCy).descPresMark.paramList;
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
         if (~isempty(a_timeData.cycleTime(idCy).descPresMark.dataAdj))
            fprintf(g_decArgo_outputCsvFileId, ';');
            format2 = [format2 ';'];
            for idP = 1:length(paramList)
               fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', [paramList(idP).name '_ADJUSTED'], paramList(idP).units);
               format2 = [format2 ';' paramList(idP).cFormat];
            end
         end
         fprintf(g_decArgo_outputCsvFileId, '\n');
         format2 = [format2 '\n'];
         
         paramData = a_timeData.cycleTime(idCy).descPresMark.data;
         paramDataRed = a_timeData.cycleTime(idCy).descPresMark.dataRed;
         paramDataAdj = a_timeData.cycleTime(idCy).descPresMark.dataAdj;
         for idL = 1:size(paramData, 1)
            if (~isempty(paramDataAdj))
               fprintf(g_decArgo_outputCsvFileId, ...
                  [format1 sprintf(';Desc. pressure mark #%d', idL) format2], ...
                  data{:}, paramData(idL, :), paramDataRed(idL, :), paramDataAdj(idL, :));
            else
               fprintf(g_decArgo_outputCsvFileId, ...
                  [format1 sprintf(';Desc. pressure mark #%d', idL) format2], ...
                  data{:}, paramData(idL, :), paramDataRed(idL, :));
            end
         end
      end
   end
end

return
