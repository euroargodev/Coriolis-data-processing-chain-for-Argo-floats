% ------------------------------------------------------------------------------
% Print CTS5-USEA IMU data in output CSV file.
%
% SYNTAX :
%  print_data_in_csv_file_ir_rudics_cts5_OPUS(a_imuRawData, a_imuTiltHeadingData, a_imuWaveData)
%
% INPUT PARAMETERS :
%   a_imuRawData         : CTS5-USEA IMU Raw data
%   a_imuTiltHeadingData : CTS5-USEA IMU Tilt & Heading data
%   a_imuWaveData        : CTS5-USEA IMU Wave data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2022 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv_file_ir_rudics_cts5_IMU(a_imuRawData, a_imuTiltHeadingData, a_imuWaveData)

% current float WMO number
global g_decArgo_floatNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloatStr;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_imuRawData) && isempty(a_imuTiltHeadingData) && isempty(a_imuWaveData))
   return
end

if (~isempty(a_imuRawData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_20';
   sensorName = 'Imu (Raw)';
   phasePrev = '';
   for idP = 1:length(a_imuRawData)

      dataStruct = a_imuRawData{idP};

      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;

      treat = dataStruct.treat;

      switch (treat)
         case {'(RW)', '(AM)', '(DW)'}
            fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); TEMP_COUNT_INERTIAL (count)' ...
            ';LINEAR_ACCELERATION_COUNT_X (count); LINEAR_ACCELERATION_COUNT_Y (count); LINEAR_ACCELERATION_COUNT_Z (count)' ...
            ';ANGULAR_RATE_COUNT_X (count); ANGULAR_RATE_COUNT_Y (count); ANGULAR_RATE_COUNT_Z (count)' ...
            ';MAGNETIC_FIELD_COUNT_X (count); MAGNETIC_FIELD_COUNT_Y (count); MAGNETIC_FIELD_COUNT_Z (count)' ...
            '\n'], ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%.1f;%d;%d;%d;%d;%d;%d;%d;%d;%d;%d';
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(AM)'))
               measType = 'mean';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         otherwise
            fprintf('ERROR: Float #%d: IMU Raw treatment type not managed: %s\n', ...
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

if (~isempty(a_imuTiltHeadingData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_20';
   sensorName = 'Imu (Tilt & Heading)';
   phasePrev = '';
   for idP = 1:length(a_imuTiltHeadingData)

      dataStruct = a_imuTiltHeadingData{idP};

      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;

      treat = dataStruct.treat;

      switch (treat)
         case {'(RW)', '(AM)', '(DW)'}
            fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; PRES (dbar); TILT (angularDeg); HEADING (angularDeg)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            outputFmt = '%s; %s;%.1f;%.1f;%.1f';
            if (strcmp(treat, '(RW)'))
               measType = 'raw';
            elseif (strcmp(treat, '(AM)'))
               measType = 'mean';
            elseif (strcmp(treat, '(DW)'))
               measType = 'decimated raw';
            end
         otherwise
            fprintf('ERROR: Float #%d: IMU Tilt & Heading treatment type not managed: %s\n', ...
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

if (~isempty(a_imuWaveData))
   
   fileTypeStr = 'Data_apmt';
   sensorNum = 'SENSOR_20';
   sensorName = 'Imu (Wave)';
   phasePrev = '';
   for idP = 1:length(a_imuWaveData)

      dataStruct = a_imuWaveData{idP};

      phase = dataStruct.phase;
      phase = phase(2:end-1);
      if (~strcmp(phase, phasePrev))
         measNum = 1;
      end
      phasePrev = phase;

      treat = dataStruct.treat;

      switch (treat)
         case {'(RW)'}
            nbPoints = (size(dataStruct.data, 2) - 2)/6;
            headerData = [];
            for id = 1:nbPoints
               headerData = [headerData sprintf([ ...
               '; LINEAR_ACCELERATION_COUNT_X%d (count); LINEAR_ACCELERATION_COUNT_Y%d (count); LINEAR_ACCELERATION_COUNT_Z%d (count)' ...
               '; MAGNETIC_FIELD_COUNT_X%d (count); MAGNETIC_FIELD_COUNT_Y%d (count); MAGNETIC_FIELD_COUNT_Z%d (count)'], ...
               id, id, id, id, id, id)];
            end
            fprintf(g_decArgo_outputCsvFileId, ['%d; %s; %s; %s; %s; %s; %s; -; Float time; Adj. float time; NUMBE_OF_POINTS (count)' headerData '\n'], ...
               g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
               fileTypeStr, phase, sensorNum, sensorName);
            fmtData = repmat(';%d;%d;%d;%d;%d;%d', 1, nbPoints);
            outputFmt = ['%s; %s;%d' fmtData];
            measType = 'raw';
         otherwise
            fprintf('ERROR: Float #%d: IMU Raw treatment type not managed: %s\n', ...
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
