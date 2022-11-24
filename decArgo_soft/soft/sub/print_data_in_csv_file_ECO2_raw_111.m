% ------------------------------------------------------------------------------
% Print raw ECO2 sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ECO2_raw_111( ...
%    a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataECO2Raw)
%
% INPUT PARAMETERS :
%   a_decoderId   : float decoder Id
%   a_cycleNum    : cycle number of the packet
%   a_profNum     : profile number of the packet
%   a_phaseNum    : phase number of the packet
%   a_dataECO2Raw : raw ECO2 data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ECO2_raw_111( ...
   a_decoderId, a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataECO2Raw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;
global g_decArgo_chloroADef;

% unpack the input data
a_dataECO2RawDate = a_dataECO2Raw{1};
a_dataECO2RawDateTrans = a_dataECO2Raw{2};
a_dataECO2RawPres = a_dataECO2Raw{3};
a_dataECO2RawChloroA = a_dataECO2Raw{4};
a_dataECO2RawBackscat = a_dataECO2Raw{5};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataECO2RawDate(:, 1) == a_cycleNum) & ...
   (a_dataECO2RawDate(:, 2) == a_profNum) & ...
   (a_dataECO2RawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; ECO2 raw; Date; PRES (dbar); ' ...
   'FLUORESCENCE_CHLA (count); BETA_BACKSCATTERING700 (count); CHLA (mg/m3)\n'], ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum)); % BBP700 not computed because it neeeds CTD data

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataECO2RawDate(idDataRaw(idL), 4:end)' ...
      a_dataECO2RawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataECO2RawPres(idDataRaw(idL), 4:end)' ...
      a_dataECO2RawChloroA(idDataRaw(idL), 4:end)' ...
      a_dataECO2RawBackscat(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0) & (data(:, 5) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3), a_decoderId);
data(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 4));
data(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 5));
paramCHLA = get_netcdf_param_attributes('CHLA');
data(:, 6) = compute_CHLA_105_to_112_121_122_124(data(:, 4), g_decArgo_chloroADef, paramCHLA.fillValue);

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO2 raw; %s; %.1f; %.1f; %.1f; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:6));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO2 raw; ; %.1f; %.1f; %.1f; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:6));
   end
end

return;
