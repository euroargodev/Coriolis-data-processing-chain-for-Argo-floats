% ------------------------------------------------------------------------------
% Print CTS5-USEA SUNA data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_SUNA(a_sunaData)
%
% INPUT PARAMETERS :
%   a_sunaData : CTS5-USEA SUNA data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_SUNA(a_sunaData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_sunaData))
   return
end

fileTypeStr = 'Data_apmt';
sensorNum = 'SENSOR_07';
sensorName = 'Suna';
phasePrev = '';
for idP = 1:length(a_sunaData)
   
   dataStruct = a_sunaData{idP};
   
   phase = dataStruct.phase;
   phase = phase(2:end-1);
   if (~strcmp(phase, phasePrev))
      measNum = 1;
   end
   phasePrev = phase;
   
   treat = dataStruct.treat;
   
   switch (treat)
      case {'(RW)', '(DW)'}
         fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; ' ...
            'PRES (dbar); TEMP (degC); PSAL (PSU); ' ...
            'TEMP_NITRATE (degC); TEMP_SPECTROPHOTOMETER_NITRATE (degC); HUMIDITY_NITRATE (percent); ' ...
            'UV_INTENSITY_DARK_NITRATE (count); UV_INTENSITY_DARK_NITRATE_STD(count); ' ...
            'MOLAR_NITRATE (micromole/l); FIT_ERROR_NITRATE (dimensionless)'], ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         fprintf(g_decArgo_outputCsvFileId, '; UV_INTENSITY_NITRATE_%d (count)', 1:90);
         fprintf(g_decArgo_outputCsvFileId, '\n');
         outputFmt = ['%s; %s;%.1f;%.3f;%.3f;%.3f;%.3f;%g;%d;%d;%g;%g' repmat(';%d', 1, 90)];
         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end
      otherwise
         fprintf('ERROR: Float #%d: SUNA treatment type not managed: %s\n', ...
            g_decArgo_floatNum, ...
            treat);
   end
   
   data = dataStruct.data;
   datesAdj = adjust_time_cts5(data(:, 1));
   for idL = 1:size(data, 1)
      fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; meas #%4d (%s); ' outputFmt '\n'], ...
         g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
         fileTypeStr, phase, sensorNum, sensorName, ...
         measNum, measType, ...
         julian_2_gregorian_dec_argo(data(idL, 1)), julian_2_gregorian_dec_argo(datesAdj(idL)), ...
         data(idL, 2:end));
      measNum = measNum + 1;
   end
end

return
