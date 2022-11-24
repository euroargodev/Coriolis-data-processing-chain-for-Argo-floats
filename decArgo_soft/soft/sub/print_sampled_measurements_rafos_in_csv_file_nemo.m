% ------------------------------------------------------------------------------
% Print RAFOS measurement data in CSV file.
%
% SYNTAX :
%  print_sampled_measurements_rafos_in_csv_file_nemo(a_sampledData)
%
% INPUT PARAMETERS :
%   a_sampledData : RAFOS measurement data
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
function print_sampled_measurements_rafos_in_csv_file_nemo(a_sampledData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_sampledData))
   return
end

format1 = [];
format2 = [];
data = [];
format1 = [format1 '%d'];
data{end+1} = g_decArgo_floatNum;
format1 = [format1 ';%d'];
data{end+1} = g_decArgo_cycleNum;
format1 = [format1 ';Rafos'];

fprintf(g_decArgo_outputCsvFileId, format1, data{:});
fprintf(g_decArgo_outputCsvFileId, ';Description');

if (~isempty(a_sampledData.dates))
   dateList = a_sampledData.dateList;
   fprintf(g_decArgo_outputCsvFileId, ';%s', dateList(1).name);
   format2 = [format2 '; %s'];
end

if (~isempty(a_sampledData.datesAdj))
   fprintf(g_decArgo_outputCsvFileId, ';%s', [dateList(1).name '_ADJUSTED']);
   format2 = [format2 '; %s'];
end

paramList = a_sampledData.paramList;
for idP = 1:length(paramList)
   if (strcmp(paramList(idP).name, 'COR') || strcmp(paramList(idP).name, 'TOA'))
      for id = 1:6
         fprintf(g_decArgo_outputCsvFileId, ';%s_%d', paramList(idP).name, id);
         format2 = [format2 ';' paramList(idP).cFormat];
      end
   else
      fprintf(g_decArgo_outputCsvFileId, ';%s', paramList(idP).name);
      format2 = [format2 ';' paramList(idP).cFormat];
   end
end

if (~isempty(a_sampledData.dataAdj))
   fprintf(g_decArgo_outputCsvFileId, ';');
   format2 = [format2 ';'];
   for idP = 1:length(paramList)
      if (strcmp(paramList(idP).name, 'COR') || strcmp(paramList(idP).name, 'TOA'))
         for id = 1:6
            fprintf(g_decArgo_outputCsvFileId, ';%s_%d', [paramList(idP).name '_ADJUSTED'], id);
            format2 = [format2 ';' paramList(idP).cFormat];
         end
      else
         fprintf(g_decArgo_outputCsvFileId, ';%s', [paramList(idP).name '_ADJUSTED']);
         format2 = [format2 ';' paramList(idP).cFormat];
      end
   end
end
fprintf(g_decArgo_outputCsvFileId, '\n');
format2 = [format2 '\n'];

dates = a_sampledData.dates;
datesAdj = a_sampledData.datesAdj;
paramData = a_sampledData.data;
paramDataAdj = a_sampledData.dataAdj;
idCor = find(strcmp({a_sampledData.paramList.name}, 'COR') == 1, 1);
idToa = find(strcmp({a_sampledData.paramList.name}, 'TOA') == 1, 1);
for idL = 1:size(paramData, 1)
   if (isempty(dates))
      if (isempty(paramDataAdj))
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :));
      else
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';meas. #%d', idL) format2], ...
            data{:}, paramData(idL, :), paramDataAdj(idL, :));
      end
   else
      if (isempty(datesAdj))
         if (isempty(paramDataAdj))
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';meas. #%d', idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), paramData(idL, :));
         else
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';meas. #%d', idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), paramData(idL, :), paramDataAdj(idL, :));
         end
      else
         if (isempty(paramDataAdj))
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';meas. #%d', idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL, 1)), paramData(idL, :));
         else
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';meas. #%d', idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL, 1)), paramData(idL, :), paramDataAdj(idL, :));
         end
      end
   end
end

return
