% ------------------------------------------------------------------------------
% Print raw ECO3 sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ECO3_raw_108_109( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataECO3Raw)
%
% INPUT PARAMETERS :
%   a_cycleNum    : cycle number of the packet
%   a_profNum     : profile number of the packet
%   a_phaseNum    : phase number of the packet
%   a_dataECO3Raw : raw ECO3 data
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
function print_data_in_csv_file_ECO3_raw_108_109( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataECO3Raw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;
global g_decArgo_chloroADef;
global g_decArgo_backscatDef;

% unpack the input data
a_dataECO3RawDate = a_dataECO3Raw{1};
a_dataECO3RawDateTrans = a_dataECO3Raw{2};
a_dataECO3RawPres = a_dataECO3Raw{3};
a_dataECO3RawChloroA = a_dataECO3Raw{4};
a_dataECO3RawBackscat1 = a_dataECO3Raw{5};
a_dataECO3RawBackscat2 = a_dataECO3Raw{6};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataECO3RawDate(:, 1) == a_cycleNum) & ...
   (a_dataECO3RawDate(:, 2) == a_profNum) & ...
   (a_dataECO3RawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; ECO3 raw; Date; PRES (dbar); ' ...
   'FLUORESCENCE_CHLA (count); BETA_BACKSCATTERING700 (count); BETA_BACKSCATTERING532 (count); CHLA (mg/m3)\n'], ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataECO3RawDate(idDataRaw(idL), 4:end)' ...
      a_dataECO3RawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataECO3RawPres(idDataRaw(idL), 4:end)' ...
      a_dataECO3RawChloroA(idDataRaw(idL), 4:end)' ...
      a_dataECO3RawBackscat1(idDataRaw(idL), 4:end)' ...
      a_dataECO3RawBackscat2(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0) & ...
   (data(:, 5) == 0) & (data(:, 6) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
data(:, 4) = sensor_2_value_for_chloroA_ir_rudics_sbd2(data(:, 4));
data(:, 5) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 5));
data(:, 6) = sensor_2_value_for_backscat_ir_rudics_sbd2(data(:, 6));
paramCHLA = get_netcdf_param_attributes('CHLA');
data(:, 7) = compute_CHLA_105_to_110_121(data(:, 4), g_decArgo_chloroADef, paramCHLA.fillValue);
% paramBBP700 = get_netcdf_param_attributes('BBP700');
% data(:, 8) = compute_BBP700_105_to_110_121(data(:, 5), g_decArgo_backscatDef, paramBBP700.fillValue);
% paramBBP532 = get_netcdf_param_attributes('BBP532');
% data(:, 9) = compute_BBP532_108_109(data(:, 6), g_decArgo_backscatDef, paramBBP532.fillValue);

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO3 raw; %s; %.1f; %.1f; %.1f; %.1f; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:7));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; ECO3 raw; ; %.1f; %.1f; %.1f; %.1f; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:7));
   end
end

return;
