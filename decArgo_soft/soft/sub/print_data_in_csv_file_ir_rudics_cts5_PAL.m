% ------------------------------------------------------------------------------
% Print CTS5-USEA PAL data in output CSV file.
%
% SYNTAX :
% print_data_in_csv_file_ir_rudics_cts5_PAL(a_palRainWind, ...
%   a_palHighResolution, a_palHighDynamicRange, a_palFullSpectrum)
%
% INPUT PARAMETERS :
%   a_palRainWind         : CTS5-USEA PAL data (rain plus wind format)
%   a_palHighResolution   : CTS5-USEA PAL data (high resolution, meteorological spectrum format)
%   a_palHighDynamicRange : CTS5-USEA PAL data (high dynamic range, meteorological spectrum format))
%   a_palFullSpectrum     : CTS5-USEA PAL data (full spectrum format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/19/2025 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_PAL(a_palRainWind, ...
   a_palHighResolution, a_palHighDynamicRange, a_palFullSpectrum)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_palRainWind) && isempty(a_palHighResolution) && ...
      isempty(a_palHighDynamicRange) && isempty(a_palFullSpectrum))
   return
end

if (~isempty(a_palRainWind))

   fprintf('ERROR: a_palRainWind data not managed yet in print_data_in_csv_file_ir_rudics_cts5_PAL\n');

elseif (~isempty(a_palHighResolution))

   fprintf('ERROR: a_palHighResolution data not managed yet in print_data_in_csv_file_ir_rudics_cts5_PAL\n');

elseif (~isempty(a_palHighDynamicRange))

   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_23';
   sensorName = 'Pal (high dynamic range)';
   phasePrev = '';
   for idP = 1:length(a_palHighDynamicRange)

      dataStruct = a_palHighDynamicRange{idP};

      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;

      fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); Stationarity; Offset (dB); 63 Hz (dB); 125 Hz (dB); 400 Hz (dB); 1 kHz (dB); 2 kHz (dB); 5 kHz (dB); 8 kHz (dB); 12.5 kHz (dB); 20 kHz (dB)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
         fileTypeStr, phase, sensorNum, sensorName);
      outputFmt = ['%s; %s;%.1f;%d' repmat(';%.1f', 1, 10)];

      measType = 'raw';
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

elseif (~isempty(a_palFullSpectrum))

   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_23';
   sensorName = 'Pal (full spectrum)';
   phasePrev = '';
   for idP = 1:length(a_palFullSpectrum)

      dataStruct = a_palFullSpectrum{idP};

      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;

      fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); Offset (dB); 63 Hz (dB); 100 Hz (dB); 125 Hz (dB); 160 Hz (dB); 400 Hz (dB); 500 Hz (dB); 630 Hz (dB); 800 Hz (dB); 1 kHz (dB); 1.25 kHz (dB); 1.6 kHz (dB); 2 kHz (dB); 2.5 kHz (dB); 3.15 kHz (dB); 4 kHz (dB); 5 kHz (dB); 6.3 kHz (dB); 8 kHz (dB); 10 kHz (dB); 12.5 kHz (dB); 16 kHz (dB); 20 kHz (dB); 25 kHz (dB)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
         fileTypeStr, phase, sensorNum, sensorName);
      outputFmt = ['%s; %s;%.1f' repmat(';%.1f', 1, 24)];

      measType = 'raw';
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
