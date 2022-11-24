% ------------------------------------------------------------------------------
% Print measurement data in CSV file.
%
% SYNTAX :
%  print_sampled_measurements_in_csv_file_apx_ir_rudics( ...
%    a_sampledData, a_measType, a_FileType, a_cyOffset)
%
% INPUT PARAMETERS :
%   a_sampledData : measurement data
%   a_measType    : measurement types
%   a_FileType    : source file
%   a_cyOffset    : cycle offset
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
function print_sampled_measurements_in_csv_file_apx_ir_rudics( ...
   a_sampledData, a_measType, a_FileType, a_cyOffset)

if (iscell(a_sampledData))
   for id = 1:length(a_sampledData)
      print_sampled_measurements_in_csv_file(a_sampledData{id}, a_measType, a_FileType, a_cyOffset, num2str(id));
   end
else
   if (~isempty(a_sampledData))
      print_sampled_measurements_in_csv_file(a_sampledData, a_measType, a_FileType, a_cyOffset, '-');
   end
end

return;

% ------------------------------------------------------------------------------
% Print measurement data in CSV file.
%
% SYNTAX :
%  print_sampled_measurements_in_csv_file( ...
%    a_sampledData, a_measType, a_FileType, a_cyOffset, a_msgRecordNum)
%
% INPUT PARAMETERS :
%   a_sampledData  : measurement data
%   a_measType     : measurement types
%   a_FileType     : source file
%   a_cyOffset     : cycle offset
%   a_msgRecordNum : number of the record
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
function print_sampled_measurements_in_csv_file( ...
   a_sampledData, a_measType, a_FileType, a_cyOffset, a_msgRecordNum)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_sampledData))
   return;
end
   
cycleNumber = g_decArgo_cycleNum;
if ((cycleNumber + a_cyOffset) >= 0)
   cycleNumber = cycleNumber + a_cyOffset;
end
   
format1 = [];
format2 = [];
data = [];
format1 = [format1 '%d'];
data{end+1} = g_decArgo_floatNum;
format1 = [format1 ';%d'];
data{end+1} = cycleNumber;
format1 = [format1 ';' a_measType];
format1 = [format1 ';' a_FileType];
format1 = [format1 ';' a_msgRecordNum];

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
   fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', paramList(idP).name, paramList(idP).units);
   format2 = [format2 ';' paramList(idP).cFormat];
end

if (~isempty(a_sampledData.dataAdj))
   fprintf(g_decArgo_outputCsvFileId, ';');
   format2 = [format2 ';'];
   for idP = 1:length(paramList)
      fprintf(g_decArgo_outputCsvFileId, ';%s (%s)', [paramList(idP).name '_ADJUSTED'], paramList(idP).units);
      format2 = [format2 ';' paramList(idP).cFormat];
   end
end
fprintf(g_decArgo_outputCsvFileId, '\n');
format2 = [format2 '\n'];

dates = a_sampledData.dates;
datesAdj = a_sampledData.datesAdj;
paramData = a_sampledData.data;
paramDataAdj = a_sampledData.dataAdj;
for idL = 1:size(paramData, 1)
   if (isempty(dates))
      if (isempty(paramDataAdj))
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';%s meas. #%d', a_measType, idL) format2], ...
            data{:}, paramData(idL, :));
      else
         fprintf(g_decArgo_outputCsvFileId, ...
            [format1 sprintf(';%s meas. #%d', a_measType, idL) format2], ...
            data{:}, paramData(idL, :), paramDataAdj(idL, :));
      end
   else
      if (isempty(datesAdj))
         if (isempty(paramDataAdj))
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';%s meas. #%d', a_measType, idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), paramData(idL, :));
         else
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';%s meas. #%d', a_measType, idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), paramData(idL, :), paramDataAdj(idL, :));
         end
      else
         if (isempty(paramDataAdj))
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';%s meas. #%d', a_measType, idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL, 1)), paramData(idL, :));
         else
            fprintf(g_decArgo_outputCsvFileId, ...
               [format1 sprintf(';%s meas. #%d', a_measType, idL) format2], ...
               data{:}, julian_2_gregorian_dec_argo(dates(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL, 1)), paramData(idL, :), paramDataAdj(idL, :));
         end
      end
   end
end

return;
