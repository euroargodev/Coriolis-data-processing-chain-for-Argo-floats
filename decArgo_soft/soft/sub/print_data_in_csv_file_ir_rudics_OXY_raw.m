% ------------------------------------------------------------------------------
% Print raw OXY sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_OXY_raw( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataOXYRaw)
%
% INPUT PARAMETERS :
%   a_cycleNum   : cycle number of the packet
%   a_profNum    : profile number of the packet
%   a_phaseNum   : phase number of the packet
%   a_dataOXYRaw : raw OXY data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_OXY_raw( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataOXYRaw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;

% unpack the input data
a_dataOXYRawDate = a_dataOXYRaw{1};
a_dataOXYRawDateTrans = a_dataOXYRaw{2};
a_dataOXYRawPres = a_dataOXYRaw{3};
a_dataOXYRawC1Phase = a_dataOXYRaw{4};
a_dataOXYRawC2Phase = a_dataOXYRaw{5};
a_dataOXYRawTemp = a_dataOXYRaw{6};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataOXYRawDate(:, 1) == a_cycleNum) & ...
   (a_dataOXYRawDate(:, 2) == a_profNum) & ...
   (a_dataOXYRawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY raw; Date; PRES (dbar); C1PHASE_DOXY (degree); C2PHASE_DOXY (degree); TEMP_DOXY (°C)\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataOXYRawDate(idDataRaw(idL), 4:end)' ...
      a_dataOXYRawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataOXYRawPres(idDataRaw(idL), 4:end)' ...
      a_dataOXYRawC1Phase(idDataRaw(idL), 4:end)' ...
      a_dataOXYRawC2Phase(idDataRaw(idL), 4:end)' ...
      a_dataOXYRawTemp(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0) & ...
   (data(:, 5) == 0) & (data(:, 6) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
data(:, 4) = sensor_2_value_for_C1C2phase_ir_rudics_sbd2(data(:, 4));
data(:, 5) = sensor_2_value_for_C1C2phase_ir_rudics_sbd2(data(:, 5));
data(:, 6) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 6));

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY raw; %s; %.1f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:6));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OXY raw; ; %.1f; %.3f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:6));
   end
end

return;
