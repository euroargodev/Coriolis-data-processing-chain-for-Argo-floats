% ------------------------------------------------------------------------------
% Print raw SEAFET sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_SEAFET_raw( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataSEAFETRaw)
%
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_phaseNum      : phase number of the packet
%   a_dataSEAFETRaw : raw SEAFET data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2019 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_SEAFET_raw( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataSEAFETRaw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;

% unpack the input data
a_dataSEAFETRawDate = a_dataSEAFETRaw{1};
a_dataSEAFETRawDateTrans = a_dataSEAFETRaw{2};
a_dataSEAFETRawPres = a_dataSEAFETRaw{3};
a_dataSEAFETRawVref = a_dataSEAFETRaw{4};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataSEAFETRawDate(:, 1) == a_cycleNum) & ...
   (a_dataSEAFETRawDate(:, 2) == a_profNum) & ...
   (a_dataSEAFETRawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET raw; Date; PRES (dbar); VRS_PH (volt)\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataSEAFETRawDate(idDataRaw(idL), 4:end)' ...
      a_dataSEAFETRawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataSEAFETRawPres(idDataRaw(idL), 4:end)' ...
      a_dataSEAFETRawVref(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
data(:, 4) = sensor_2_value_for_vrsPh_ir_rudics(data(:, 4));

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET raw; %s; %.1f; %.6f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:4));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAFET raw; ; %.1f; %.6f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:4));
   end
end

return
