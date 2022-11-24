% ------------------------------------------------------------------------------
% Print raw OCR sensor data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_OCR_raw( ...
%    a_cycleNum, a_profNum, a_phaseNum, ...
%    a_dataOCRRaw)
%
% INPUT PARAMETERS :
%   a_cycleNum   : cycle number of the packet
%   a_profNum    : profile number of the packet
%   a_phaseNum   : phase number of the packet
%   a_dataOCRRaw : raw OCR data
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
function print_data_in_csv_file_ir_rudics_OCR_raw( ...
   a_cycleNum, a_profNum, a_phaseNum, ...
   a_dataOCRRaw)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% global default values
global g_decArgo_dateDef;
global g_decArgo_iradianceCountsDef;

% unpack the input data
a_dataOCRRawDate = a_dataOCRRaw{1};
a_dataOCRRawDateTrans = a_dataOCRRaw{2};
a_dataOCRRawPres = a_dataOCRRaw{3};
a_dataOCRRawIr1 = a_dataOCRRaw{4};
a_dataOCRRawIr2 = a_dataOCRRaw{5};
a_dataOCRRawIr3 = a_dataOCRRaw{6};
a_dataOCRRawIr4 = a_dataOCRRaw{7};

% select the data (according to cycleNum, profNum and phaseNum)
idDataRaw = find((a_dataOCRRawDate(:, 1) == a_cycleNum) & ...
   (a_dataOCRRawDate(:, 2) == a_profNum) & ...
   (a_dataOCRRawDate(:, 3) == a_phaseNum));

fprintf(g_decArgo_outputCsvFileId, ['%d; %d; %d; %s; OCR raw; Date; PRES (dbar); ' ...
   'RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count); ' ...
   'DOWN_IRRADIANCE380 (W/m^2/nm); DOWN_IRRADIANCE412 (W/m^2/nm); DOWN_IRRADIANCE490 (W/m^2/nm); DOWNWELLING_PAR (microMoleQuanta/m^2/sec)\n'], ...
   g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum));

   data = [];
for idL = 1:length(idDataRaw)
   data = [data; ...
      a_dataOCRRawDate(idDataRaw(idL), 4:end)' ...
      a_dataOCRRawDateTrans(idDataRaw(idL), 4:end)' ...
      a_dataOCRRawPres(idDataRaw(idL), 4:end)' ...
      a_dataOCRRawIr1(idDataRaw(idL), 4:end)' ...
      a_dataOCRRawIr2(idDataRaw(idL), 4:end)' ...
      a_dataOCRRawIr3(idDataRaw(idL), 4:end)' ...
      a_dataOCRRawIr4(idDataRaw(idL), 4:end)'];
end
idDel = find((data(:, 3) == 0) & (data(:, 4) == 0) & ...
   (data(:, 5) == 0) & (data(:, 6) == 0) & (data(:, 7) == 0));
data(idDel, :) = [];

data(:, 3) = sensor_2_value_for_pressure_ir_rudics_sbd2(data(:, 3));
paramDOWN_IRRADIANCE380 = get_netcdf_param_attributes('DOWN_IRRADIANCE380');
data(:, 8) = compute_DOWN_IRRADIANCE380_105_to_109_121(data(:, 4), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE380.fillValue);
paramDOWN_IRRADIANCE412 = get_netcdf_param_attributes('DOWN_IRRADIANCE412');
data(:, 9) = compute_DOWN_IRRADIANCE412_105_to_109_121(data(:, 5), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE412.fillValue);
paramDOWN_IRRADIANCE490 = get_netcdf_param_attributes('DOWN_IRRADIANCE490');
data(:, 10) = compute_DOWN_IRRADIANCE490_105_to_109_121(data(:, 6), g_decArgo_iradianceCountsDef, paramDOWN_IRRADIANCE490.fillValue);
paramDOWNWELLING_PAR = get_netcdf_param_attributes('DOWNWELLING_PAR');
data(:, 11) = compute_DOWNWELLING_PAR_105_to_109_121(data(:, 7), g_decArgo_iradianceCountsDef, paramDOWNWELLING_PAR.fillValue);

for idL = 1:size(data, 1)
   if (data(idL, 1) ~= g_decArgo_dateDef)
      if (data(idL, 2) == 1)
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (T)'];
      else
         date = [julian_2_gregorian_dec_argo(data(idL, 1)) ' (C)'];
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR raw; %s; %.1f; %u; %u; %u; %u; %g; %g; %g; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         date, data(idL, 3:11));
   else
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR raw; ; %.1f; %u; %u; %u; %u; %g; %g; %g; %g\n', ...
         g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(a_phaseNum), ...
         data(idL, 3:11));
   end
end

return;
