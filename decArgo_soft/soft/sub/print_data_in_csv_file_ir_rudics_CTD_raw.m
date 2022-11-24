% ------------------------------------------------------------------------------
% Print raw CTD sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_CTD_raw( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataCTDRaw)
%
% INPUT PARAMETERS :
%   a_decoderId  : float decoder Id
%   a_cycleNum   : cycle number of the packet
%   a_profNum    : profile number of the packet
%   a_phaseNum   : phase number of the packet
%   a_dataCTDRaw : raw CTD data
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
function print_data_in_csv_file_ir_rudics_CTD_raw( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataCTDRaw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;


% unpack the input data
a_dataCTDRawDate = a_dataCTDRaw{1};
a_dataCTDRawDateTrans = a_dataCTDRaw{2};
a_dataCTDRawPres = a_dataCTDRaw{3};
a_dataCTDRawTemp = a_dataCTDRaw{4};
a_dataCTDRawSal = a_dataCTDRaw{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataCTDRawDate(:, 1) == a_cycleNum) & ...
   (a_dataCTDRawDate(:, 2) == a_profNum) & ...
   (a_dataCTDRawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD raw; Date; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataCTDRawDate(idDataRaw(idL), 4:end)' ...
      a_dataCTDRawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataCTDRawPres(idDataRaw(idL), 4:end)' ...
      a_dataCTDRawTemp(idDataRaw(idL), 4:end)' ...
      a_dataCTDRawSal(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0) & (data(:, 5) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
data(:, 4) = sensor_2_value_for_temperature_ir_rudics_sbd2(data(:, 4));
data(:, 5) = sensor_2_value_for_salinity_ir_rudics_sbd2(data(:, 5));

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD raw; %s; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:5));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; CTD raw; ; %.1f; %.3f; %.3f\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:5));
   end
end

return
