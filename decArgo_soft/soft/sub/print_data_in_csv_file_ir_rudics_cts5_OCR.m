% ------------------------------------------------------------------------------
% Print CTS5-USEA OCR data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_OCR(a_ocrData)
%
% INPUT PARAMETERS :
%   a_ocrData : CTS5-USEA OCR data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_OCR(a_ocrData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_ocrData))
   return
end

fileTypeStr = 'Data_apmt';
sensorNum = 'SENSOR_03';
sensorName = 'Ocr';
phasePrev = '';
for idP = 1:length(a_ocrData)
   
   dataStruct = a_ocrData{idP};
   
   phase = dataStruct.phase;
   phase = phase(2:end-1);
   if (~strcmp(phase, phasePrev))
      measNum = 1;
   end
   phasePrev = phase;
   
   treat = dataStruct.treat;
   
   switch (treat)
      case {'(RW)', '(AM)', '(DW)'}
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%d;%d;%d;%d';
         if (strcmp(treat, '(RW)'))
            measType = 'raw';
         elseif (strcmp(treat, '(AM)'))
            measType = 'mean';
         elseif (strcmp(treat, '(DW)'))
            measType = 'decimated raw';
         end
      case '(AM)(SD)'
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count); RAW_DOWNWELLING_IRRADIANCE380_STD (count); RAW_DOWNWELLING_IRRADIANCE412_STD (count); RAW_DOWNWELLING_IRRADIANCE490_STD (count); RAW_DOWNWELLING_PAR_STD (count)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%d;%d;%d;%d;%d;%d;%d;%d';
         measType = 'mean + stdev';
      case '(AM)(MD)'
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count); PRES_MED (dbar); RAW_DOWNWELLING_IRRADIANCE380_MED  (count); RAW_DOWNWELLING_IRRADIANCE412_MED  (count); RAW_DOWNWELLING_IRRADIANCE490_MED  (count); RAW_DOWNWELLING_PAR_MED  (count)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%d;%d;%d;%d%.1f;%d;%d;%d;%d';
         measType = 'mean + median';
      case '(AM)(SD)(MD)'
         fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); RAW_DOWNWELLING_IRRADIANCE380 (count); RAW_DOWNWELLING_IRRADIANCE412 (count); RAW_DOWNWELLING_IRRADIANCE490 (count); RAW_DOWNWELLING_PAR (count); RAW_DOWNWELLING_IRRADIANCE380_STD (count); RAW_DOWNWELLING_IRRADIANCE412_STD (count); RAW_DOWNWELLING_IRRADIANCE490_STD (count); RAW_DOWNWELLING_PAR_STD (count); PRES_MED (dbar); RAW_DOWNWELLING_IRRADIANCE380_MED  (count); RAW_DOWNWELLING_IRRADIANCE412_MED  (count); RAW_DOWNWELLING_IRRADIANCE490_MED  (count); RAW_DOWNWELLING_PAR_MED  (count)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
            fileTypeStr, phase, sensorNum, sensorName);
         outputFmt = '%s; %s;%.1f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d';
         measType = 'mean + stdev + median';
      otherwise
         fprintf('ERROR: Float #%d: OCR treatment type not managed: %s\n', ...
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
