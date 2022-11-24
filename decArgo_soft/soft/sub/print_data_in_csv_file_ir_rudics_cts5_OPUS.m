% ------------------------------------------------------------------------------
% Print CTS5-USEA OPUS data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_OPUS(a_opusLightData, a_opusBlackData)
%
% INPUT PARAMETERS :
%   a_opusLightData : CTS5-USEA OPUS-LIGHT data
%   a_opusBlackData : CTS5-USEA OPUS-BLACK data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/15/2021 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_OPUS(a_opusLightData, a_opusBlackData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_opusLightData) && isempty(a_opusBlackData))
   return
end

if (~isempty(a_opusLightData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_15';
   sensorName = 'Opus (LIGHT)';
   phasePrev = '';
   for idP = 1:length(a_opusLightData)
      
      dataStruct = a_opusLightData{idP};
      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;
      
      data = dataStruct.data;
      nbF = unique(data(:, 7));
      nbB = unique(data(:, 263));
      
      treat = dataStruct.treat;
      
      switch (treat)
         case {'(RW)', '(DW)'}
            header1 = '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); SPECTRUM_TYPE_NITRATE (2:calibrated, 4:raw); AVERAGING_NITRATE (count); FLASH_COUNT_NITRATE (count); TEMP_NITRATE (degC)';
            header2 = [' ;nb channels full' sprintf('; UV_INTENSITY_FULL_NITRATE_%d (count)', 1:nbF)];
            header3 = [' ;nb channels binned' sprintf('; UV_INTENSITY_BINNED_NITRATE_%d (count)', 1:nbB)];
            fprintf(g_decArgo_outputCsvFileId, [header1 header2 header3 '\n'], ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            format1 = [' %s; %s;%.1f;%d;%d;%d;%.4f'];
            format2 = [';%d' repmat(';%d', 1, nbF)];
            format3 = [';%d' repmat(';%d', 1, nbB)];
            outputFmt = [format1 format2 format3];
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
            
         otherwise
            fprintf('ERROR: Float #%d: OPUS-LIGHT treatment type not managed: %s\n', ...
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
            data(idL, 2:7),  data(idL, 8:8+nbF-1), data(idL, 263:264+nbB-1));
         measNum = measNum + 1;
      end
   end
end

if (~isempty(a_opusBlackData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_15';
   sensorName = 'Opus (BLACK)';
   phasePrev = '';
   for idP = 1:length(a_opusBlackData)
      
      dataStruct = a_opusBlackData{idP};
      
      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;
      
      treat = dataStruct.treat;
      
      switch (treat)
         case {'(RW)', '(DW)'}
            fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); BLACK_AVERAGING_NITRATE (count); BLACK_FLASH_COUNT_NITRATE (count); BLACK_TEMP_NITRATE (degC); UV_INTENSITY_DARK_NITRATE_AVG (count); UV_INTENSITY_DARK_NITRATE_SD (count)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%.1f;%d;%d;%.4f;%g;%g';
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         otherwise
            fprintf('ERROR: Float #%d: OPUS-BLACK treatment type not managed: %s\n', ...
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
end

return
