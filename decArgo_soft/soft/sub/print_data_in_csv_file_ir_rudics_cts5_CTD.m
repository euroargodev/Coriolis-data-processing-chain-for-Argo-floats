% ------------------------------------------------------------------------------
% Print CTS5-USEA CTD data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_CTD(a_ctdData)
%
% INPUT PARAMETERS :
%   a_ctdData : CTS5-USEA CTD data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_CTD(a_ctdData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_ctdData))
   return
end

fileTypeStr = 'Data_apmt';
sensorNum = 'SENSOR_01';
sensorName = 'Ctd';
phasePrev = '';
for idP = 1:length(a_ctdData)
   
   dataStruct = a_ctdData{idP};
   
   phase = dataStruct.phase;
   phase = phase(2:end-1);
   if (~strcmp(phase, phasePrev))
      measNum = 1;
   end
   phasePrev = phase;
   
   treat = dataStruct.treat;
   if (strcmp(treat, '(SS)'))
      measNum = 1;
   end
   
   switch (treat)
      case {'(RW)', '(AM)', '(SS)', '(DW)'}
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); TEMP (degC); PSAL (PSU)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.2f;%.4f;%.3f';
         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(AM)'))
            measType = 'mean';
         elseif (strcmp(treat, '(SS)'))
            measType = 'subsurface point';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end
      case '(AM)(SD)'
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); TEMP (degC); PSAL (PSU); TEM_STDP (degC); PSAL_STD (PSU)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.2f;%.4f;%.3f;%.4f;%.3f';
         measType = 'mean + stdev';
      case '(AM)(MD)'
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); TEMP (degC); PSAL (PSU); PRES_MED (dbar); TEMP_MED (degC); PSAL_MED (PSU)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.2f;%.4f;%.3f;%.2f;%.4f;%.3f';
         measType = 'mean + median';
      case '(AM)(SD)(MD)'
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); TEMP (degC); PSAL (PSU); TEMP_STD  (degC); PSAL_STD  (PSU); PRES_MED (dbar); TEMP_MED (degC); PSAL_MED (PSU)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.2f;%.4f;%.3f;%.4f;%.3f;%.2f;%.4f;%.3f';
         measType = 'mean + stdev + median';
      otherwise
         fprintf('ERROR: Float #%d: CTD treatment type not managed: %s\n', ...
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
