% ------------------------------------------------------------------------------
% Print CTS5-USEA RAMSES data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_RAMSES(a_ramsesData)
%
% INPUT PARAMETERS :
%   a_ramsesData : CTS5-USEA SUNA data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/17/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_RAMSES(a_ramsesData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_ramsesData))
   return
end

fileTypeStr = 'Data_apmt';
sensorNum = 'SENSOR_14';
sensorName = 'Ramses';
phasePrev = '';
for idP = 1:length(a_ramsesData)
   
   dataStruct = a_ramsesData{idP};
   
   phase = dataStruct.phase;
   phase = phase(2:end-1);
   if (~strcmp(phase, phasePrev))
      measNum = 1;
   end
   phasePrev = phase;
   
   treat = dataStruct.treat;
   
   data = dataStruct.data;

   switch (treat)
      case {'(RW)', '(DW)'}
         fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; ' ...
            'PRES (dbar); INTEGRATION_TIME (msec); ' ...
            'PRE_PRES (dbar); POST_PRES (dbar); PRE_INCLINATION (degree); POST_INCLINATION (degree); DARK_AVERAGE; Number of channels'], ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         fprintf(g_decArgo_outputCsvFileId, '; RAW_DOWNWELLING_IRRADIANCE_%d (count)', 1:size(data, 2)-9);
         fprintf(g_decArgo_outputCsvFileId, '\n');
         outputFmt = ['%s; %s;%.1f;%d;%.2f;%.2f;%.2f;%.2f;%d;%d' repmat(';%d', 1, size(data, 2)-9)];
         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end
      otherwise
         fprintf('ERROR: Float #%d: RAMSES treatment type not managed: %s\n', ...
            g_decArgo_floatNum, ...
            treat);
   end
   
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
