% ------------------------------------------------------------------------------
% Read the metadata.xml file transmitted by CTS5-USEA floats, compare its
% content to the BDD information and store the metadata in the dedicated
% structure.
%
% SYNTAX :
%  [o_metaStruct] = get_meta_data_cts5_130(...
%    a_metaDataXmlFileName, a_metaStruct, a_sensorListNum, a_floatNum, a_outputCsvDirName, a_rtVersionFlag)
%
% INPUT PARAMETERS :
%   a_metaDataXmlFileName : metadata.xml file
%   a_metaStruct          : input meta-data structure
%   a_sensorListNum       : list of CTS5-USEA sensor numbers
%   a_floatNum            : float WMO number
%   a_outputCsvDirName    : output CSV file directory
%   a_rtVersionFlag       : 1 if it is the RT version of the tool, 0 otherwise
%
% OUTPUT PARAMETERS :
%   o_metaStruct : output meta-data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/14/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_data_cts5_130(...
   a_metaDataXmlFileName, a_metaStruct, a_sensorListNum, a_floatNum, a_outputCsvDirName, a_rtVersionFlag)

% output parameters initialization
o_metaStruct = a_metaStruct;

% CSV output files
global g_cogj_csvFileBddId;
global g_cogj_csvFileBddPathName;
global g_cogj_csvFileCoefId;
global g_cogj_csvFileCoefPathName;


% read meta-data file
metaData = decode_apmt_metadata_129_130_131(a_metaDataXmlFileName);

% check meta-data and store meta-data if needed
if (isfield(metaData, 'profiler'))
   if (~a_rtVersionFlag)
      if (isfield(metaData.profiler, 'sn'))
         if (~strcmp(metaData.profiler.sn, o_metaStruct.FLOAT_SERIAL_NO))
            if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
               [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
            end
            fprintf('WARNING: BDD: Float #%d: FLOAT_SERIAL_NO differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
               a_floatNum, ...
               o_metaStruct.FLOAT_SERIAL_NO, ...
               metaData.profiler.sn, ...
               g_cogj_csvFileBddPathName);
            fprintf(g_cogj_csvFileBddId, '%d;392;1;%s;INST_REFERENCE\n', ...
               a_floatNum, ...
               metaData.profiler.sn);
         end
      end
   end
   if (~a_rtVersionFlag)
      if (isfield(metaData.profiler, 'model'))
         if (~strcmp(metaData.profiler.model, o_metaStruct.PLATFORM_TYPE))
            if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
               [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
            end
            fprintf('WARNING: BDD: Float #%d: PLATFORM_TYPE differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
               a_floatNum, ...
               o_metaStruct.PLATFORM_TYPE, ...
               metaData.profiler.model, ...
               g_cogj_csvFileBddPathName);
            fprintf(g_cogj_csvFileBddId, '%d;2209;1;%s;PLATFORM_TYPE\n', ...
               a_floatNum, ...
               metaData.profiler.model);
         end
      end
   end
end
if (isfield(metaData, 'telecom'))
   if (~a_rtVersionFlag)
      if (isfield(metaData.telecom, 'type'))
         if (~strcmp(metaData.telecom.type, o_metaStruct.TRANS_SYSTEM{1}))
            if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
               [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
            end
            fprintf('WARNING: BDD: Float #%d: TRANS_SYSTEM differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
               a_floatNum, ...
               o_metaStruct.TRANS_SYSTEM{1}, ...
               metaData.telecom.type, ...
               g_cogj_csvFileBddPathName);
            fprintf(g_cogj_csvFileBddId, '%d;385;1;%s;TRANS_SYSTEM\n', ...
               a_floatNum, ...
               metaData.telecom.type);
         end
      end
   end
   if (isfield(metaData.telecom, 'cid'))
      if (~isfield(o_metaStruct, 'META_AUX_FLOAT_SIM_CARD_NUMBER'))
         o_metaStruct.META_AUX_FLOAT_SIM_CARD_NUMBER = metaData.telecom.cid;
      end
   end
end

if (isfield(metaData, 'hardware'))
   if (~a_rtVersionFlag)
      if (isfield(metaData.hardware, 'control_board'))
         if (isfield(metaData.hardware.control_board, 'model'))
            if (~strcmp(metaData.hardware.control_board.model, o_metaStruct.CONTROLLER_BOARD_TYPE_PRIMARY))
               if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                  [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
               end
               fprintf('WARNING: BDD: Float #%d: CONTROLLER_BOARD_TYPE_PRIMARY differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                  a_floatNum, ...
                  o_metaStruct.CONTROLLER_BOARD_TYPE_PRIMARY, ...
                  metaData.hardware.control_board.model, ...
                  g_cogj_csvFileBddPathName);
               fprintf(g_cogj_csvFileBddId, '%d;1250;1;%s;CONTROLLER_BOARD_TYPE_PRIMARY\n', ...
                  a_floatNum, ...
                  metaData.hardware.control_board.model);
            end
         end
         if (isfield(metaData.hardware.control_board, 'firmware'))
            if (~strcmp(metaData.hardware.control_board.firmware, o_metaStruct.FIRMWARE_VERSION))
               if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                  [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
               end
               fprintf('WARNING: BDD: Float #%d: CONTROLLER_BOARD_TYPE_PRIMARY differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                  a_floatNum, ...
                  o_metaStruct.FIRMWARE_VERSION, ...
                  metaData.hardware.control_board.firmware, ...
                  g_cogj_csvFileBddPathName);
               fprintf(g_cogj_csvFileBddId, '%d;961;1;%s;FIRMWARE_VERSION\n', ...
                  a_floatNum, ...
                  metaData.hardware.control_board.firmware);
            end
         end
      end
   end
   if (isfield(metaData.hardware, 'measure_board'))
      if (~a_rtVersionFlag)
         if (isfield(metaData.hardware.measure_board, 'model'))
            if (~strcmp(metaData.hardware.measure_board.model, o_metaStruct.CONTROLLER_BOARD_TYPE_SECONDARY))
               if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                  [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
               end
               fprintf('WARNING: BDD: Float #%d: CONTROLLER_BOARD_TYPE_SECONDARY differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                  a_floatNum, ...
                  o_metaStruct.CONTROLLER_BOARD_TYPE_SECONDARY, ...
                  metaData.hardware.measure_board.model, ...
                  g_cogj_csvFileBddPathName);
               fprintf(g_cogj_csvFileBddId, '%d;1251;1;%s;CONTROLLER_BOARD_TYPE_SECONDARY\n', ...
                  a_floatNum, ...
                  metaData.hardware.measure_board.model);
            end
         end
      end
      if (isfield(metaData.hardware.measure_board, 'firmware'))
         if (~isfield(o_metaStruct, 'META_AUX_FIRMWARE_VERSION_SECONDARY'))
            o_metaStruct.META_AUX_FIRMWARE_VERSION_SECONDARY = metaData.hardware.measure_board.firmware;
         end
      end
   end
   if (isfield(metaData.hardware, 'battery'))
      if (isfield(metaData.hardware.battery, 'pack_1'))
         if (isfield(metaData.hardware.battery.pack_1, 'type'))
            if (~isfield(o_metaStruct, 'META_AUX_BATTERY_PACK1_TYPE'))
               o_metaStruct.META_AUX_BATTERY_PACK1_TYPE = metaData.hardware.battery.pack_1.type;
            end
         end
         if (isfield(metaData.hardware.battery.pack_1, 'voltage'))
            if (~isfield(o_metaStruct, 'META_AUX_BATTERY_PACK1_VOLTAGE'))
               o_metaStruct.META_AUX_BATTERY_PACK1_VOLTAGE = metaData.hardware.battery.pack_1.voltage;
            end
         end
         if (isfield(metaData.hardware.battery.pack_1, 'capacity'))
            if (~isfield(o_metaStruct, 'META_AUX_BATTERY_PACK1_CAPACITY'))
               o_metaStruct.META_AUX_BATTERY_PACK1_CAPACITY = metaData.hardware.battery.pack_1.capacity;
            end
         end
      end
      if (isfield(metaData.hardware.battery, 'pack_2'))
         if (isfield(metaData.hardware.battery.pack_2, 'type'))
            if (~isfield(o_metaStruct, 'META_AUX_BATTERY_PACK2_TYPE'))
               o_metaStruct.META_AUX_BATTERY_PACK2_TYPE = metaData.hardware.battery.pack_2.type;
            end
         end
         if (isfield(metaData.hardware.battery.pack_2, 'voltage'))
            if (~isfield(o_metaStruct, 'META_AUX_BATTERY_PACK2_VOLTAGE'))
               o_metaStruct.META_AUX_BATTERY_PACK2_VOLTAGE = metaData.hardware.battery.pack_2.voltage;
            end
         end
         if (isfield(metaData.hardware.battery.pack_2, 'capacity'))
            if (~isfield(o_metaStruct, 'META_AUX_BATTERY_PACK2_CAPACITY'))
               o_metaStruct.META_AUX_BATTERY_PACK2_CAPACITY = metaData.hardware.battery.pack_2.capacity;
            end
         end
      end
   end
end

if (isfield(metaData, 'sensors'))
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CTD
   if (any(a_sensorListNum == 1))
      if (isfield(metaData.sensors, 'sensor_sbe41'))
         if (~a_rtVersionFlag)
            if (isfield(metaData.sensors.sensor_sbe41, 'sensor_pressure') && ...
                  isfield(metaData.sensors.sensor_sbe41.sensor_pressure, 'sn'))
               idF = find(strcmp('CTD_PRES', o_metaStruct.SENSOR));
               if (~isempty(idF))
                  if (str2double(metaData.sensors.sensor_sbe41.sensor_pressure.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                     if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                        [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                     end
                     fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                        a_floatNum, ...
                        'CTD_PRES', ...
                        o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                        metaData.sensors.sensor_sbe41.sensor_pressure.sn, ...
                        g_cogj_csvFileBddPathName);
                     fprintf(g_cogj_csvFileBddId, '%d;411;1;%s;SENSOR_SERIAL_NO\n', ...
                        a_floatNum, ...
                        metaData.sensors.sensor_sbe41.sensor_pressure.sn);
                  end
               else
                  fprintf('ERROR: Float #%d: cannot find expected ''CTD_PRES'' sensor in DB contents - CTD_PRES metadata ignored\n', ...
                     a_floatNum);
               end
            end
            if (isfield(metaData.sensors.sensor_sbe41, 'sensor'))
               if (isfield(metaData.sensors.sensor_sbe41.sensor, 'sn'))
                  idF = find(strcmp('CTD_TEMP', o_metaStruct.SENSOR));
                  if (~isempty(idF))
                     if (str2double(metaData.sensors.sensor_sbe41.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'CTD_TEMP', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_sbe41.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;2;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_sbe41.sensor.sn);
                     end
                  else
                     fprintf('ERROR: Float #%d: cannot find expected ''CTD_TEMP'' sensor in DB contents - CTD_TEMP metadata ignored\n', ...
                        a_floatNum);
                  end
                  idF = find(strcmp('CTD_CNDC', o_metaStruct.SENSOR));
                  if (~isempty(idF))
                     if (str2double(metaData.sensors.sensor_sbe41.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'CTD_CNDC', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_sbe41.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;3;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_sbe41.sensor.sn);
                     end
                  else
                     fprintf('ERROR: Float #%d: cannot find expected ''CTD_CNDC'' sensor in DB contents - CTD_CNDC metadata ignored\n', ...
                        a_floatNum);
                  end
               end
               if (isfield(metaData.sensors.sensor_sbe41.sensor, 'model') && ...
                     isfield(metaData.sensors.sensor_sbe41, 'sbe41_board') && ...
                     isfield(metaData.sensors.sensor_sbe41.sbe41_board, 'firmware') && ...
                     ~isempty(metaData.sensors.sensor_sbe41.sbe41_board.firmware))
                  sensorModel = [metaData.sensors.sensor_sbe41.sensor.model ...
                     '_V' metaData.sensors.sensor_sbe41.sbe41_board.firmware];
                  idF = find(strcmp('CTD_TEMP', o_metaStruct.SENSOR));
                  if (~isempty(idF))
                     if (~strcmp(sensorModel, o_metaStruct.SENSOR_MODEL{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'CTD_TEMP', ...
                           o_metaStruct.SENSOR_MODEL{idF}, ...
                           sensorModel, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;2;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           sensorModel);
                     end
                  else
                     fprintf('ERROR: Float #%d: cannot find expected ''CTD_TEMP'' sensor in DB contents - CTD_TEMP metadata ignored\n', ...
                        a_floatNum);
                  end
                  idF = find(strcmp('CTD_CNDC', o_metaStruct.SENSOR));
                  if (~isempty(idF))
                     if (~strcmp(sensorModel, o_metaStruct.SENSOR_MODEL{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'CTD_CNDC', ...
                           o_metaStruct.SENSOR_MODEL{idF}, ...
                           sensorModel, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;3;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           sensorModel);
                     end
                  else
                     fprintf('ERROR: Float #%d: cannot find expected ''CTD_CNDC'' sensor in DB contents - CTD_CNDC metadata ignored\n', ...
                        a_floatNum);
                  end
               end
            end
         end
         if (isfield(metaData.sensors.sensor_sbe41, 'sbe41_board'))
            if (isfield(metaData.sensors.sensor_sbe41.sbe41_board, 'firmware'))
               if (~isfield(o_metaStruct, 'META_AUX_SBE41_FIRMWARE_VERSION'))
                  o_metaStruct.META_AUX_SBE41_FIRMWARE_VERSION = metaData.sensors.sensor_sbe41.sbe41_board.firmware;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_sbe41, 'temperature_coeff'))
            if (isfield(metaData.sensors.sensor_sbe41.temperature_coeff, 'ta0') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.temperature_coeff.ta0))
               o_metaStruct.SBE_TEMP_COEF_TA0 = ['a0=' metaData.sensors.sensor_sbe41.temperature_coeff.ta0];
            end
            if (isfield(metaData.sensors.sensor_sbe41.temperature_coeff, 'ta1') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.temperature_coeff.ta1))
               o_metaStruct.SBE_TEMP_COEF_TA1 = ['a1=' metaData.sensors.sensor_sbe41.temperature_coeff.ta1];
            end
            if (isfield(metaData.sensors.sensor_sbe41.temperature_coeff, 'ta2') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.temperature_coeff.ta2))
               o_metaStruct.SBE_TEMP_COEF_TA2 = ['a2=' metaData.sensors.sensor_sbe41.temperature_coeff.ta2];
            end
            if (isfield(metaData.sensors.sensor_sbe41.temperature_coeff, 'ta3') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.temperature_coeff.ta3))
               o_metaStruct.SBE_TEMP_COEF_TA3 = ['a3=' metaData.sensors.sensor_sbe41.temperature_coeff.ta3];
            end
         end
         if (isfield(metaData.sensors.sensor_sbe41, 'conductivity_coeff'))
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'g') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.g))
               o_metaStruct.SBE_CNDC_COEF_G = ['g=' metaData.sensors.sensor_sbe41.conductivity_coeff.g];
            end
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'h') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.h))
               o_metaStruct.SBE_CNDC_COEF_H = ['h=' metaData.sensors.sensor_sbe41.conductivity_coeff.h];
            end
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'i') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.i))
               o_metaStruct.SBE_CNDC_COEF_I = ['i=' metaData.sensors.sensor_sbe41.conductivity_coeff.i];
            end
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'j') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.j))
               o_metaStruct.SBE_CNDC_COEF_J = ['j=' metaData.sensors.sensor_sbe41.conductivity_coeff.j];
            end
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'ctcor') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.ctcor))
               o_metaStruct.SBE_CNDC_COEF_CTCOR = ['CTcor=' metaData.sensors.sensor_sbe41.conductivity_coeff.ctcor];
            end
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'cpcor') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.cpcor))
               o_metaStruct.SBE_CNDC_COEF_CPCOR = ['CPcor=' metaData.sensors.sensor_sbe41.conductivity_coeff.cpcor];
            end
            if (isfield(metaData.sensors.sensor_sbe41.conductivity_coeff, 'wbotc') && ...
                  ~isempty(metaData.sensors.sensor_sbe41.conductivity_coeff.wbotc))
               o_metaStruct.SBE_CNDC_COEF_WBOTC = ['WBOTC=' metaData.sensors.sensor_sbe41.conductivity_coeff.wbotc];
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % DO
   if (any(a_sensorListNum == 2))
      if (~a_rtVersionFlag)
         if (isfield(metaData.sensors, 'sensor_do'))
            idF = find(strcmp('OPTODE_DOXY', o_metaStruct.SENSOR));
            if (~isempty(idF))
               if (isfield(metaData.sensors.sensor_do, 'sensor'))
                  if (isfield(metaData.sensors.sensor_do.sensor, 'sn'))
                     if (str2double(metaData.sensors.sensor_do.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'OPTODE_DOXY', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_do.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;101;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.sensor.sn);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.sensor, 'model'))
                     if (~strcmp(metaData.sensors.sensor_do.sensor.model, o_metaStruct.SENSOR_MODEL{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'OPTODE_DOXY', ...
                           o_metaStruct.SENSOR_MODEL{idF}, ...
                           metaData.sensors.sensor_do.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;101;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.sensor.model);
                     end
                  end
               end
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % COEF
               if (isfield(metaData.sensors.sensor_do, 'phase_coeff') && ...
                     isfield(metaData.sensors.sensor_do.phase_coeff, 'c0'))
                  if (str2double(metaData.sensors.sensor_do.phase_coeff.c0) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.PhaseCoef0))
                     if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                        [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                     end
                     fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_PHASE_COEF_0 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                        a_floatNum, ...
                        o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.PhaseCoef0, ...
                        metaData.sensors.sensor_do.phase_coeff.c0, ...
                        g_cogj_csvFileBddPathName);
                     fprintf(g_cogj_csvFileBddId, '%d;1647;1;%s;AANDERAA_OPTODE_PHASE_COEF_0\n', ...
                        a_floatNum, ...
                        metaData.sensors.sensor_do.phase_coeff.c0);
                  end
               end
               if (isfield(metaData.sensors.sensor_do, 'svu_foil_coeff'))
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c0'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c0) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef0))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C0 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef0, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c0, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1362;1;%s;AANDERAA_OPTODE_COEF_C0\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c0);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c1'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c1) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef1))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C1 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef1, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c1, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1363;1;%s;AANDERAA_OPTODE_COEF_C1\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c1);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c2'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c2) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef2))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C2 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef2, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c2, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1364;1;%s;AANDERAA_OPTODE_COEF_C2\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c2);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c3'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c3) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef3))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C3 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef3, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c3, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1365;1;%s;AANDERAA_OPTODE_COEF_C3\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c3);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c4'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c4) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef4))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C4 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef4, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c4, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1366;1;%s;AANDERAA_OPTODE_COEF_C4\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c4);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c5'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c5) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef5))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C5 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef5, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c5, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1367;1;%s;AANDERAA_OPTODE_COEF_C5\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c5);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_do.svu_foil_coeff, 'c6'))
                     if (str2double(metaData.sensors.sensor_do.svu_foil_coeff.c6) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef6))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: AANDERAA_OPTODE_COEF_C6 differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OPTODE.SVUFoilCoef6, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c6, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;1367;1;%s;AANDERAA_OPTODE_COEF_C6\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_do.svu_foil_coeff.c6);
                     end
                  end
               end
            else
               fprintf('ERROR: Float #%d: cannot find expected ''OPTODE_DOXY'' sensor in DB contents - OPTODE metadata ignored\n', ...
                  a_floatNum);
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % OCR
   if (any(a_sensorListNum == 3))
      if (~a_rtVersionFlag)
         if (isfield(metaData.sensors, 'sensor_ocr'))
            idF = find(strcmp('RADIOMETER_DOWN_IRR412', o_metaStruct.SENSOR));
            idF2 = find(strcmp('RADIOMETER_DOWN_IRR443', o_metaStruct.SENSOR));
            idF3 = find(strcmp('RADIOMETER_DOWN_IRR490', o_metaStruct.SENSOR));
            idF4 = find(strcmp('RADIOMETER_DOWN_IRR665', o_metaStruct.SENSOR));
            if (~isempty(idF) && ~isempty(idF2) && ~isempty(idF3) && ~isempty(idF4))
               if (isfield(metaData.sensors.sensor_ocr, 'sensor'))
                  if (isfield(metaData.sensors.sensor_ocr.sensor, 'sn'))
                     if (str2double(metaData.sensors.sensor_ocr.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR412', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_ocr.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;202;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.sn);

                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR443', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF2}, ...
                           metaData.sensors.sensor_ocr.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;205;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.sn);

                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR490', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF3}, ...
                           metaData.sensors.sensor_ocr.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;203;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.sn);

                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR665', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF4}, ...
                           metaData.sensors.sensor_ocr.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;206;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.sn);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.sensor, 'model'))
                     if (~strcmp(metaData.sensors.sensor_ocr.sensor.model, o_metaStruct.SENSOR_MODEL{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR412', ...
                           o_metaStruct.SENSOR_MODEL{idF}, ...
                           metaData.sensors.sensor_ocr.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;202;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.model);

                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR443', ...
                           o_metaStruct.SENSOR_MODEL{idF2}, ...
                           metaData.sensors.sensor_ocr.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;205;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.model);

                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR490', ...
                           o_metaStruct.SENSOR_MODEL{idF3}, ...
                           metaData.sensors.sensor_ocr.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;203;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.model);

                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'RADIOMETER_DOWN_IRR665', ...
                           o_metaStruct.SENSOR_MODEL{idF4}, ...
                           metaData.sensors.sensor_ocr.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;206;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.sensor.model);
                     end
                  end
               end
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % COEF
               if (isfield(metaData.sensors.sensor_ocr, 'channel_01'))
                  if (isfield(metaData.sensors.sensor_ocr.channel_01, 'a0'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda412 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda412;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.a0);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_01.a0) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda412))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda412 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda412, ...
                           metaData.sensors.sensor_ocr.channel_01.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda412;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.a0);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_01, 'a1'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda412 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda412;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.a1);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_01.a1) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda412))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda412 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda412, ...
                           metaData.sensors.sensor_ocr.channel_01.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda412;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.a1);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_01, 'im'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda412 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda412;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.im);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_01.im) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda412))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda412 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda412, ...
                           metaData.sensors.sensor_ocr.channel_01.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda412;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_01.im);
                     end
                  end
               end
               if (isfield(metaData.sensors.sensor_ocr, 'channel_02'))
                  if (isfield(metaData.sensors.sensor_ocr.channel_02, 'a0'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda443 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda443;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.a0);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_02.a0) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda443))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda443 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda443, ...
                           metaData.sensors.sensor_ocr.channel_02.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda443;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.a0);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_02, 'a1'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda443 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda443;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.a1);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_02.a1) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda443))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda443 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda443, ...
                           metaData.sensors.sensor_ocr.channel_02.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda443;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.a1);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_02, 'im'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda443 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda443;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.im);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_02.im) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda443))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda443 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda443, ...
                           metaData.sensors.sensor_ocr.channel_02.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda443;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_02.im);
                     end
                  end
               end
               if (isfield(metaData.sensors.sensor_ocr, 'channel_03'))
                  if (isfield(metaData.sensors.sensor_ocr.channel_03, 'a0'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda490 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda490;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.a0);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_03.a0) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda490))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda490 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda490, ...
                           metaData.sensors.sensor_ocr.channel_03.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda490;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.a0);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_03, 'a1'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda490 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda490;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.a1);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_03.a1) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda490))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda490 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda490, ...
                           metaData.sensors.sensor_ocr.channel_03.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda490;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.a1);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_03, 'im'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda490 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda490;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.im);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_03.im) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda490))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda490 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda490, ...
                           metaData.sensors.sensor_ocr.channel_03.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda490;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_03.im);
                     end
                  end
               end
               if (isfield(metaData.sensors.sensor_ocr, 'channel_04'))
                  if (isfield(metaData.sensors.sensor_ocr.channel_04, 'a0'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda665 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda665;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.a0);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_04.a0) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda665))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A0Lambda665 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A0Lambda665, ...
                           metaData.sensors.sensor_ocr.channel_04.a0, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A0Lambda665;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.a0);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_04, 'a1'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda665 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda665;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.a1);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_04.a1) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda665))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR A1Lambda665 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.A1Lambda665, ...
                           metaData.sensors.sensor_ocr.channel_04.a1, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;A1Lambda665;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.a1);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_ocr.channel_04, 'im'))
                     if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'OCR'))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda665 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda665;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.im);
                     elseif (str2double(metaData.sensors.sensor_ocr.channel_04.im) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda665))
                        if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                           [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                        end
                        fprintf('WARNING: COEF: Float #%d: OCR LmLambda665 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           o_metaStruct.CALIBRATION_COEFFICIENT.OCR.LmLambda665, ...
                           metaData.sensors.sensor_ocr.channel_04.im, ...
                           g_cogj_csvFileCoefPathName);
                        fprintf(g_cogj_csvFileCoefId, '%d;OCR;LmLambda665;%s\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_ocr.channel_04.im);
                     end
                  end
               end
            else
               fprintf('ERROR: Float #%d: cannot find expected ''RADIOMETER_DOWN_IRR380'' and/or ''RADIOMETER_DOWN_IRR412'' and/or ''RADIOMETER_DOWN_IRR490'' and/or ''RADIOMETER_PAR'' sensor in DB contents - OCR metadata ignored\n', ...
                  a_floatNum);
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % ECO
   if (any(a_sensorListNum == 4))
      if (~a_rtVersionFlag)
         if (any(strcmp(o_metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'ECO3')))
            % ECO3
            if (isfield(metaData.sensors, 'sensor_eco'))
               idF = find(strcmp('FLUOROMETER_CHLA', o_metaStruct.SENSOR));
               idF2 = find(strcmp('BACKSCATTERINGMETER_BBP700', o_metaStruct.SENSOR));
               idF3 = find(strcmp('FLUOROMETER_CDOM', o_metaStruct.SENSOR));
               if (~isempty(idF) && ~isempty(idF2) && ~isempty(idF3))
                  if (isfield(metaData.sensors.sensor_eco, 'sensor'))
                     if (isfield(metaData.sensors.sensor_eco.sensor, 'sn'))
                        if (~isempty(metaData.sensors.sensor_eco.sensor.sn))
                           if (str2double(metaData.sensors.sensor_eco.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                              if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                                 [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                              end
                              fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 'FLUOROMETER_CHLA', ...
                                 o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                                 metaData.sensors.sensor_eco.sensor.sn, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;411;301;%s;SENSOR_SERIAL_NO\n', ...
                                 a_floatNum, ...
                                 metaData.sensors.sensor_eco.sensor.sn);

                              fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 'BACKSCATTERINGMETER_BBP700', ...
                                 o_metaStruct.SENSOR_SERIAL_NO{idF2}, ...
                                 metaData.sensors.sensor_eco.sensor.sn, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;411;302;%s;SENSOR_SERIAL_NO\n', ...
                                 a_floatNum, ...
                                 metaData.sensors.sensor_eco.sensor.sn);

                              fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 'FLUOROMETER_CDOM', ...
                                 o_metaStruct.SENSOR_SERIAL_NO{idF3}, ...
                                 metaData.sensors.sensor_eco.sensor.sn, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;411;303;%s;SENSOR_SERIAL_NO\n', ...
                                 a_floatNum, ...
                                 metaData.sensors.sensor_eco.sensor.sn);
                           end
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.sensor, 'model'))
                        if (~isempty(metaData.sensors.sensor_eco.sensor.model))
                           if (~strcmp(metaData.sensors.sensor_eco.sensor.model, o_metaStruct.SENSOR_MODEL{idF}))
                              if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                                 [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                              end
                              fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 'FLUOROMETER_CHLA', ...
                                 o_metaStruct.SENSOR_MODEL{idF}, ...
                                 metaData.sensors.sensor_eco.sensor.model, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;410;301;%s;SENSOR_MODEL\n', ...
                                 a_floatNum, ...
                                 metaData.sensors.sensor_eco.sensor.model);

                              fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 'BACKSCATTERINGMETER_BBP', ...
                                 o_metaStruct.SENSOR_MODEL{idF2}, ...
                                 metaData.sensors.sensor_eco.sensor.model, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;410;302;%s;SENSOR_MODEL\n', ...
                                 a_floatNum, ...
                                 metaData.sensors.sensor_eco.sensor.model);

                              fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 'FLUOROMETER_CDOM', ...
                                 o_metaStruct.SENSOR_MODEL{idF3}, ...
                                 metaData.sensors.sensor_eco.sensor.model, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;410;303;%s;SENSOR_MODEL\n', ...
                                 a_floatNum, ...
                                 metaData.sensors.sensor_eco.sensor.model);
                           end
                        end
                     end
                  end
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % COEF
                  if (isfield(metaData.sensors.sensor_eco, 'channel_01'))
                     if (isfield(metaData.sensors.sensor_eco.channel_01, 'sf'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 ScaleFactChloroA coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;ScaleFactChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.sf);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_01.sf) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.ScaleFactChloroA))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 ScaleFactChloroA coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.ScaleFactChloroA, ...
                              metaData.sensors.sensor_eco.channel_01.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;ScaleFactChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.sf);
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.channel_01, 'dc'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 DarkCountChloroA coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;DarkCountChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.dc);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_01.dc) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountChloroA))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 DarkCountChloroA coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountChloroA, ...
                              metaData.sensors.sensor_eco.channel_01.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;DarkCountChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.dc);
                        end
                     end
                  end
                  if (isfield(metaData.sensors.sensor_eco, 'channel_02'))
                     if (isfield(metaData.sensors.sensor_eco.channel_02, 'sf'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 ScaleFactBackscatter700 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;ScaleFactBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.sf);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_02.sf) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.ScaleFactBackscatter700))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 ScaleFactBackscatter700 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.ScaleFactBackscatter700, ...
                              metaData.sensors.sensor_eco.channel_02.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;ScaleFactBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.sf);
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.channel_02, 'dc'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 DarkCountBackscatter700 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;DarkCountBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.dc);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_02.dc) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountBackscatter700))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 DarkCountBackscatter700 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountBackscatter700, ...
                              metaData.sensors.sensor_eco.channel_02.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;DarkCountBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.dc);
                        end
                     end
                  end
                  if (isfield(metaData.sensors.sensor_eco, 'channel_03'))
                     if (isfield(metaData.sensors.sensor_eco.channel_03, 'sf'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 ScaleFactCDOM coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_03.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;ScaleFactCDOM;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_03.sf);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_03.sf) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.ScaleFactCDOM))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 ScaleFactCDOM coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.ScaleFactCDOM, ...
                              metaData.sensors.sensor_eco.channel_03.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;ScaleFactCDOM;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_03.sf);
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.channel_03, 'dc'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 DarkCountCDOM coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_03.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;DarkCountCDOM;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_03.dc);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_03.dc) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountCDOM))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO3 DarkCountCDOM coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountCDOM, ...
                              metaData.sensors.sensor_eco.channel_03.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO3;DarkCountCDOM;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_03.dc);
                        end
                     end
                  end
                  KhiCoefBackscatter = '1.076';
                  if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
                     if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                        [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                     end
                     fprintf('WARNING: COEF: Float #%d: ECO3 KhiCoefBackscatter coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                        a_floatNum, ...
                        KhiCoefBackscatter, ...
                        g_cogj_csvFileCoefPathName);
                     fprintf(g_cogj_csvFileCoefId, '%d;ECO3;KhiCoefBackscatter;%s\n', ...
                        a_floatNum, ...
                        KhiCoefBackscatter);
                  elseif (str2double(KhiCoefBackscatter) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.KhiCoefBackscatter))
                     if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                        [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                     end
                     fprintf('WARNING: COEF: Float #%d: ECO3 KhiCoefBackscatter coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                        a_floatNum, ...
                        o_metaStruct.CALIBRATION_COEFFICIENT.ECO3.KhiCoefBackscatter, ...
                        KhiCoefBackscatter, ...
                        g_cogj_csvFileCoefPathName);
                     fprintf(g_cogj_csvFileCoefId, '%d;ECO3;KhiCoefBackscatter;%s\n', ...
                        a_floatNum, ...
                        KhiCoefBackscatter);
                  end
               else
                  fprintf('ERROR: Float #%d: cannot find expected ''FLUOROMETER_CHLA'' and/or ''BACKSCATTERINGMETER_BBP700'' and/or ''FLUOROMETER_CDOM'' sensor in DB contents - ECO3 metadata ignored\n', ...
                     a_floatNum);
               end
            end
         elseif (any(strcmp(o_metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'ECO2')))
            % ECO2
            if (isfield(metaData.sensors, 'sensor_eco'))
               idF = find(strcmp('FLUOROMETER_CHLA', o_metaStruct.SENSOR));
               idF2 = find(strcmp('BACKSCATTERINGMETER_BBP700', o_metaStruct.SENSOR));
               if (~isempty(idF) && ~isempty(idF2))
                  if (isfield(metaData.sensors.sensor_eco, 'sensor'))
                     if (isfield(metaData.sensors.sensor_eco.sensor, 'sn'))
                        if (str2double(metaData.sensors.sensor_eco.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                           if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                              [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                           end
                           fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              'FLUOROMETER_CHLA', ...
                              o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                              metaData.sensors.sensor_eco.sensor.sn, ...
                              g_cogj_csvFileBddPathName);
                           fprintf(g_cogj_csvFileBddId, '%d;411;301;%s;SENSOR_SERIAL_NO\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.sensor.sn);

                           fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              'BACKSCATTERINGMETER_BBP700', ...
                              o_metaStruct.SENSOR_SERIAL_NO{idF2}, ...
                              metaData.sensors.sensor_eco.sensor.sn, ...
                              g_cogj_csvFileBddPathName);
                           fprintf(g_cogj_csvFileBddId, '%d;411;302;%s;SENSOR_SERIAL_NO\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.sensor.sn);
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.sensor, 'model'))
                        if (~strcmp(metaData.sensors.sensor_eco.sensor.model, o_metaStruct.SENSOR_MODEL{idF}))
                           if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                              [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                           end
                           fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              'FLUOROMETER_CHLA', ...
                              o_metaStruct.SENSOR_MODEL{idF}, ...
                              metaData.sensors.sensor_eco.sensor.model, ...
                              g_cogj_csvFileBddPathName);
                           fprintf(g_cogj_csvFileBddId, '%d;410;301;%s;SENSOR_MODEL\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.sensor.model);

                           fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              'BACKSCATTERINGMETER_BBP', ...
                              o_metaStruct.SENSOR_MODEL{idF2}, ...
                              metaData.sensors.sensor_eco.sensor.model, ...
                              g_cogj_csvFileBddPathName);
                           fprintf(g_cogj_csvFileBddId, '%d;410;302;%s;SENSOR_MODEL\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.sensor.model);
                        end
                     end
                  end
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % COEF
                  if (isfield(metaData.sensors.sensor_eco, 'channel_01'))
                     if (isfield(metaData.sensors.sensor_eco.channel_01, 'sf'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO2'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 ScaleFactChloroA coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;ScaleFactChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.sf);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_01.sf) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.ScaleFactChloroA))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 ScaleFactChloroA coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.ScaleFactChloroA, ...
                              metaData.sensors.sensor_eco.channel_01.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;ScaleFactChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.sf);
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.channel_01, 'dc'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO2'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 DarkCountChloroA coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;DarkCountChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.dc);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_01.dc) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.DarkCountChloroA))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 DarkCountChloroA coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.DarkCountChloroA, ...
                              metaData.sensors.sensor_eco.channel_01.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;DarkCountChloroA;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_01.dc);
                        end
                     end
                  end
                  if (isfield(metaData.sensors.sensor_eco, 'channel_02'))
                     if (isfield(metaData.sensors.sensor_eco.channel_02, 'sf'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO2'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 ScaleFactBackscatter700 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;ScaleFactBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.sf);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_02.sf) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.ScaleFactBackscatter700))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 ScaleFactBackscatter700 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.ScaleFactBackscatter700, ...
                              metaData.sensors.sensor_eco.channel_02.sf, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;ScaleFactBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.sf);
                        end
                     end
                     if (isfield(metaData.sensors.sensor_eco.channel_02, 'dc'))
                        if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO2'))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 DarkCountBackscatter700 coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;DarkCountBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.dc);
                        elseif (str2double(metaData.sensors.sensor_eco.channel_02.dc) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.DarkCountBackscatter700))
                           if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                              [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                           end
                           fprintf('WARNING: COEF: Float #%d: ECO2 DarkCountBackscatter700 coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.DarkCountBackscatter700, ...
                              metaData.sensors.sensor_eco.channel_02.dc, ...
                              g_cogj_csvFileCoefPathName);
                           fprintf(g_cogj_csvFileCoefId, '%d;ECO2;DarkCountBackscatter700;%s\n', ...
                              a_floatNum, ...
                              metaData.sensors.sensor_eco.channel_02.dc);
                        end
                     end
                  end
                  KhiCoefBackscatter = '1.097';
                  if (~isfield(o_metaStruct.CALIBRATION_COEFFICIENT, 'ECO2'))
                     if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                        [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                     end
                     fprintf('WARNING: COEF: Float #%d: ECO2 KhiCoefBackscatter coef (%s) is missing in META.json file - calib_coef file contents should be updated (see %s)\n', ...
                        a_floatNum, ...
                        KhiCoefBackscatter, ...
                        g_cogj_csvFileCoefPathName);
                     fprintf(g_cogj_csvFileCoefId, '%d;ECO2;KhiCoefBackscatter;%s\n', ...
                        a_floatNum, ...
                        KhiCoefBackscatter);
                  elseif (str2double(KhiCoefBackscatter) ~= str2double(o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.KhiCoefBackscatter))
                     if (isempty(g_cogj_csvFileCoefId) || (g_cogj_csvFileCoefId == -1))
                        [g_cogj_csvFileCoefId, g_cogj_csvFileCoefPathName] = open_csv_file(a_outputCsvDirName, 'C', g_cogj_csvFileCoefPathName);
                     end
                     fprintf('WARNING: COEF: Float #%d: ECO2 KhiCoefBackscatter coef differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                        a_floatNum, ...
                        o_metaStruct.CALIBRATION_COEFFICIENT.ECO2.KhiCoefBackscatter, ...
                        KhiCoefBackscatter, ...
                        g_cogj_csvFileCoefPathName);
                     fprintf(g_cogj_csvFileCoefId, '%d;ECO2;KhiCoefBackscatter;%s\n', ...
                        a_floatNum, ...
                        KhiCoefBackscatter);
                  end
               else
                  fprintf('ERROR: Float #%d: cannot find expected ''FLUOROMETER_CHLA'' and/or ''BACKSCATTERINGMETER_BBP700'' sensor in DB contents - ECO2 metadata ignored\n', ...
                     a_floatNum);
               end
            end
         else
            fprintf('ERROR: Float #%d: cannot find expected ''ECO3'' or ''ECO2'' in SENSOR_MOUNTED_ON_FLOAT - ECO metadata ignored\n', ...
               a_floatNum);
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % SBEPH
   if (any(a_sensorListNum == 5))
      if (~a_rtVersionFlag)
         if (isfield(metaData.sensors, 'sensor_sbeph'))
            idF = find(strcmp('TRANSISTOR_PH', o_metaStruct.SENSOR));
            if (~isempty(idF))
               if (isfield(metaData.sensors.sensor_sbeph, 'sensor'))
                  if (isfield(metaData.sensors.sensor_sbeph.sensor, 'sn'))
                     if (str2double(metaData.sensors.sensor_sbeph.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'TRANSISTOR_PH', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_sbeph.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;701;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_sbeph.sensor.sn);
                     end
                  end
               end
            else
               fprintf('ERROR: Float #%d: cannot find expected ''TRANSISTOR_PH'' sensor in DB contents - TRANSISTOR_PH metadata ignored\n', ...
                  a_floatNum);
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CROVER
   if (any(a_sensorListNum == 6))
      if (isfield(metaData.sensors, 'sensor_crover'))
         idF = find(strcmp('TRANSMISSOMETER_CP660', o_metaStruct.SENSOR));
         if (~isempty(idF))
            if (~a_rtVersionFlag)
               if (isfield(metaData.sensors.sensor_crover, 'sensor'))
                  if (isfield(metaData.sensors.sensor_crover.sensor, 'sn'))
                     if (str2double(metaData.sensors.sensor_crover.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'TRANSMISSOMETER_CP660', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_crover.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;501;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_crover.sensor.sn);
                     end
                  end
               end
            end
            if (isfield(metaData.sensors.sensor_crover, 'path_length'))
               if (isfield(metaData.sensors.sensor_crover.path_length, 'pth'))
                  if (~isfield(o_metaStruct, 'META_AUX_CROVER_PATH_LENGTH'))
                     o_metaStruct.META_AUX_CROVER_PATH_LENGTH = metaData.sensors.sensor_crover.path_length.pth;
                  end
               end
            end
            if (isfield(metaData.sensors.sensor_crover, 'calibration'))
               if (isfield(metaData.sensors.sensor_crover.calibration, 'cln'))
                  if (~isfield(o_metaStruct, 'META_AUX_CROVER_CALIBRATION_VALUE'))
                     o_metaStruct.META_AUX_CROVER_CALIBRATION_VALUE = metaData.sensors.sensor_crover.calibration.cln;
                  end
               end
            end
         else
            fprintf('ERROR: Float #%d: cannot find expected ''TRANSMISSOMETER_CP660'' sensor in DB contents - TRANSMISSOMETER_CP660 metadata ignored\n', ...
               a_floatNum);
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % SUNA
   if (any(a_sensorListNum == 7))
      if (isfield(metaData.sensors, 'sensor_suna'))
         if (~a_rtVersionFlag)
            idF = find(strcmp('SPECTROPHOTOMETER_NITRATE', o_metaStruct.SENSOR) & strcmp('SATLANTIC', o_metaStruct.SENSOR_MAKER));
            if (~isempty(idF))
               if (isfield(metaData.sensors.sensor_suna, 'sensor'))
                  if (isfield(metaData.sensors.sensor_suna.sensor, 'sn'))
                     if (str2double(metaData.sensors.sensor_suna.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'SPECTROPHOTOMETER_NITRATE', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_suna.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;601;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_suna.sensor.sn);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_suna.sensor, 'model'))
                     if (~strcmp(metaData.sensors.sensor_suna.sensor.model, o_metaStruct.SENSOR_MODEL{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'SPECTROPHOTOMETER_NITRATE', ...
                           o_metaStruct.SENSOR_MODEL{idF}, ...
                           metaData.sensors.sensor_suna.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;601;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_suna.sensor.model);
                     end
                  end
                  if (isfield(metaData.sensors.sensor_suna.sensor, 'spectrum'))
                     valueStr = metaData.sensors.sensor_suna.sensor.spectrum;
                     [val, count, errmsg, nextindex] = sscanf(valueStr, 'Output pixels %d-%d');
                     if (isempty(errmsg) && (count == 2))
                        pixelBeginMeta = val(1);
                        pixelEndMeta = val(2);
                        idBegin = find(strcmp('CONFIG_PX_1_6_0_0_3', o_metaStruct.CONFIG_PARAMETER_NAME));
                        idEnd = find(strcmp('CONFIG_PX_1_6_0_0_4', o_metaStruct.CONFIG_PARAMETER_NAME));
                        if (~isempty(idBegin))
                           pixelBeginBdd = o_metaStruct.CONFIG_PARAMETER_VALUE{idBegin};
                           if (pixelBeginMeta ~= str2double(pixelBeginBdd))
                              if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                                 [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                              end
                              fprintf('WARNING: BDD: Float #%d: SUNA_APF_OUTPUT_PIXEL_BEGIN differ (database: ''%d'' xml:''%d'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 str2double(pixelBeginBdd), ...
                                 pixelBeginMeta, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;2204;1;%d;SUNA_APF_OUTPUT_PIXEL_BEGIN\n', ...
                                 a_floatNum, ...
                                 pixelBeginMeta);
                           end
                        else
                           if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                              [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                           end
                           fprintf('WARNING: BDD: Float #%d: SUNA_APF_OUTPUT_PIXEL_BEGIN (xml:''%d'') is missing in META.json file - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              pixelBeginMeta, ...
                              g_cogj_csvFileBddPathName);
                           fprintf(g_cogj_csvFileBddId, '%d;2204;1;%d;SUNA_APF_OUTPUT_PIXEL_BEGIN\n', ...
                              a_floatNum, ...
                              pixelBeginMeta);
                        end
                        if (~isempty(idEnd))
                           pixelEndBdd = o_metaStruct.CONFIG_PARAMETER_VALUE{idEnd};
                           if (pixelEndMeta ~= str2double(pixelEndBdd))
                              if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                                 [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                              end
                              fprintf('WARNING: BDD: Float #%d: SUNA_APF_OUTPUT_PIXEL_END differ (database: ''%d'' xml:''%d'') - DB contents should be updated (see %s)\n', ...
                                 a_floatNum, ...
                                 str2double(pixelEndBdd), ...
                                 pixelEndMeta, ...
                                 g_cogj_csvFileBddPathName);
                              fprintf(g_cogj_csvFileBddId, '%d;2205;1;%d;SUNA_APF_OUTPUT_PIXEL_END\n', ...
                                 a_floatNum, ...
                                 pixelEndMeta);
                           end
                        else
                           fprintf('WARNING: BDD: Float #%d: SUNA_APF_OUTPUT_PIXEL_END (xml:''%d'') is missing in META.json file - DB contents should be updated (see %s)\n', ...
                              a_floatNum, ...
                              pixelEndMeta, ...E
                              g_cogj_csvFileBddPathName);
                           fprintf(g_cogj_csvFileBddId, '%d;2205;1;%d;SUNA_APF_OUTPUT_PIXEL_END\n', ...
                              a_floatNum, ...
                              pixelEndMeta);
                        end
                     else
                        fprintf('ERROR: Float #%d: unable to parse metaData.sensors.sensor_suna.sensor.spectrum = ''%s'' - SUNA PIXEL BEGIN/END information not retrieve\n', ...
                           a_floatNum, ...
                           valueStr);
                     end
                  end
               end
            else
               fprintf('ERROR: Float #%d: cannot find expected ''SPECTROPHOTOMETER_NITRATE'' sensor in DB contents - SPECTROPHOTOMETER_NITRATE metadata ignored\n', ...
                  a_floatNum);
            end
         end
         if (isfield(metaData.sensors.sensor_suna, 'suna_board'))
            if (isfield(metaData.sensors.sensor_suna.suna_board, 'firmwre'))
               if (isfield(o_metaStruct, 'META_AUX_SUNA_FIRMWARE_VERSION'))
                  o_metaStruct.META_AUX_SUNA_FIRMWARE_VERSION = metaData.sensors.sensor_suna.suna_board.firmwre;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_suna, 'spectrometer'))
            if (isfield(metaData.sensors.sensor_suna.spectrometer, 'spinterp'))
               if (isfield(o_metaStruct, 'META_AUX_SUNA_SPECTROMETER_INTEGRATION_TIME'))
                  o_metaStruct.META_AUX_SUNA_SPECTROMETER_INTEGRATION_TIME = metaData.sensors.sensor_suna.spectrometer.spinterp;
               end
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % UVP
   if (any(a_sensorListNum == 8))
      if (isfield(metaData.sensors, 'sensor_uvp6'))
         idF = find(strcmp('AUX_PARTICLES_PLANKTON_CAMERA', o_metaStruct.SENSOR));
         if (~isempty(idF))
            if (isfield(metaData.sensors.sensor_uvp6, 'sensor'))
               if (~a_rtVersionFlag)
                  if (isfield(metaData.sensors.sensor_uvp6.sensor, 'sn'))
                     if (~strcmp(metaData.sensors.sensor_uvp6.sensor.sn, o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'AUX_PARTICLES_PLANKTON_CAMERA', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_uvp6.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;801;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_uvp6.sensor.sn);
                     end
                  end
               end
               if (~a_rtVersionFlag)
                  if (isfield(metaData.sensors.sensor_uvp6.sensor, 'model'))
                     if (~strcmp(metaData.sensors.sensor_uvp6.sensor.model, o_metaStruct.SENSOR_MODEL{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_MODEL for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'AUX_PARTICLES_PLANKTON_CAMERA', ...
                           o_metaStruct.SENSOR_MODEL{idF}, ...
                           metaData.sensors.sensor_uvp6.sensor.model, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;410;801;%s;SENSOR_MODEL\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_uvp6.sensor.model);
                     end
                  end
               end
            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % CONFIG
            for idConf = 0:9
               confName = sprintf('acq_conf_%d', idConf);
               if (isfield(metaData.sensors.sensor_uvp6, confName) && ...
                     isfield(metaData.sensors.sensor_uvp6.(confName), 'frame'))
                  if (~isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_NAMES'))
                     o_metaStruct.META_AUX_UVP_CONFIG_NAMES = [];
                  end
                  if (~isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_PARAMETERS'))
                     o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS = [];
                  end
                  frame = metaData.sensors.sensor_uvp6.(confName).frame;
                  idFC = strfind(frame, ',');
                  o_metaStruct.META_AUX_UVP_CONFIG_NAMES{end+1} = frame(1:idFC(1)-1);
                  o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS{end+1} = frame;
               end
            end
            for idConf = 0:1
               confName = sprintf('taxo_conf_%d', idConf);
               if (isfield(metaData.sensors.sensor_uvp6, confName) && ...
                     isfield(metaData.sensors.sensor_uvp6.(confName), 'frame'))
                  if (~isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_NAMES'))
                     o_metaStruct.META_AUX_UVP_CONFIG_NAMES = [];
                  end
                  if (~isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_PARAMETERS'))
                     o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS = [];
                  end
                  frame = metaData.sensors.sensor_uvp6.(confName).frame;
                  idFC = strfind(frame, ',');
                  o_metaStruct.META_AUX_UVP_CONFIG_NAMES{end+1} = frame(1:idFC(1)-1);
                  o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS{end+1} = frame;
               end
            end
            if (isfield(metaData.sensors.sensor_uvp6, 'hw_conf') && ...
                  isfield(metaData.sensors.sensor_uvp6.hw_conf, 'frame'))
               if (~isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_NAMES'))
                  o_metaStruct.META_AUX_UVP_CONFIG_NAMES = [];
               end
               if (~isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_PARAMETERS'))
                  o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS = [];
               end
               frame = metaData.sensors.sensor_uvp6.hw_conf.frame;
               o_metaStruct.META_AUX_UVP_CONFIG_NAMES{end+1} = 'HW_CONF';
               o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS{end+1} = frame;
            end
            if (isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_NAMES'))
               o_metaStruct.META_AUX_UVP_CONFIG_NAMES = o_metaStruct.META_AUX_UVP_CONFIG_NAMES';
            end
            if (isfield(o_metaStruct, 'META_AUX_UVP_CONFIG_PARAMETERS'))
               o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS = o_metaStruct.META_AUX_UVP_CONFIG_PARAMETERS';
            end
         else
            fprintf('ERROR: Float #%d: cannot find expected ''AUX_PARTICLES_PLANKTON_CAMERA'' sensor in DB contents - UVP metadata ignored\n', ...
               a_floatNum);
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % OPUS
   if (any(a_sensorListNum == 15))
      if (isfield(metaData.sensors, 'sensor_opus'))
         idF = find(strcmp('AUX_SPECTROPHOTOMETER_NITRATE', o_metaStruct.SENSOR) & strcmp('TRIOS', o_metaStruct.SENSOR_MAKER));
         if (~isempty(idF))
            if (~a_rtVersionFlag)
               if (isfield(metaData.sensors.sensor_opus, 'sensor'))
                  if (isfield(metaData.sensors.sensor_opus.sensor, 'sn'))
                     if (~strcmp(metaData.sensors.sensor_opus.sensor.sn, o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'AUX_SPECTROPHOTOMETER_NITRATE', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_opus.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;901;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_opus.sensor.sn);
                     end
                  end
               end
            end
            if (isfield(metaData.sensors.sensor_opus, 'opus_board'))
               if (isfield(metaData.sensors.sensor_opus.opus_board, 'firmware'))
                  if (~isfield(o_metaStruct, 'META_AUX_OPUS_FIRMWARE_VERSION'))
                     o_metaStruct.META_AUX_OPUS_FIRMWARE_VERSION = metaData.sensors.sensor_opus.opus_board.firmware;
                  end
               end
            end
            if (isfield(metaData.sensors.sensor_opus, 'sensor_lamp'))
               if (isfield(metaData.sensors.sensor_opus.sensor_lamp, 'sn'))
                  if (~isfield(o_metaStruct, 'META_AUX_OPUS_SENSOR_LAMP_SERIAL_NO'))
                     o_metaStruct.META_AUX_OPUS_SENSOR_LAMP_SERIAL_NO = metaData.sensors.sensor_opus.sensor_lamp.sn;
                  end
               end
            end
            if (isfield(metaData.sensors.sensor_opus, 'waterbase'))
               if (isfield(metaData.sensors.sensor_opus.waterbase, 'length'))
                  if (~isfield(o_metaStruct, 'META_AUX_OPUS_WATERBASE_LENGTH'))
                     o_metaStruct.META_AUX_OPUS_WATERBASE_LENGTH = metaData.sensors.sensor_opus.waterbase.length;
                  end
               end
               if (isfield(metaData.sensors.sensor_opus.waterbase, 'intensities'))
                  if (~isfield(o_metaStruct, 'META_AUX_OPUS_WATERBASE_INTENSITIES'))
                     o_metaStruct.META_AUX_OPUS_WATERBASE_INTENSITIES = metaData.sensors.sensor_opus.waterbase.intensities;
                  end
               end
            end
         else
            fprintf('ERROR: Float #%d: cannot find expected ''AUX_SPECTROPHOTOMETER_NITRATE'' sensor in DB contents - OPUS metadata ignored\n', ...
               a_floatNum);
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MPE
   if (any(a_sensorListNum == 17))
      if (isfield(metaData.sensors, 'sensor_mpe'))
         idF = find(strcmp('AUX_RADIOMETER_PAR', o_metaStruct.SENSOR));
         if (~a_rtVersionFlag)
            if (~isempty(idF))
               if (isfield(metaData.sensors.sensor_mpe, 'sensor'))
                  if (isfield(metaData.sensors.sensor_mpe.sensor, 'sn'))
                     if (str2double(metaData.sensors.sensor_mpe.sensor.sn) ~= str2double(o_metaStruct.SENSOR_SERIAL_NO{idF}))
                        if (isempty(g_cogj_csvFileBddId) || (g_cogj_csvFileBddId == -1))
                           [g_cogj_csvFileBddId, g_cogj_csvFileBddPathName] = open_csv_file(a_outputCsvDirName, 'B', g_cogj_csvFileBddPathName);
                        end
                        fprintf('WARNING: BDD: Float #%d: SENSOR_SERIAL_NO for ''%s'' differ (database: ''%s'' xml:''%s'') - DB contents should be updated (see %s)\n', ...
                           a_floatNum, ...
                           'AUX_RADIOMETER_PAR', ...
                           o_metaStruct.SENSOR_SERIAL_NO{idF}, ...
                           metaData.sensors.sensor_mpe.sensor.sn, ...
                           g_cogj_csvFileBddPathName);
                        fprintf(g_cogj_csvFileBddId, '%d;411;1301;%s;SENSOR_SERIAL_NO\n', ...
                           a_floatNum, ...
                           metaData.sensors.sensor_mpe.sensor.sn);
                     end
                  end
               end
            end
         end
         if (isfield(metaData.sensors.sensor_mpe, 'acquisition'))
            if (isfield(metaData.sensors.sensor_mpe.acquisition, 'average') && ...
                  ~isempty(metaData.sensors.sensor_mpe.acquisition.average))
               o_metaStruct.META_AUX_MPE_ACQUISITION_AVERAGE = metaData.sensors.sensor_mpe.acquisition.average;
            end
            if (isfield(metaData.sensors.sensor_mpe.acquisition, 'rate') && ...
                  ~isempty(metaData.sensors.sensor_mpe.acquisition.rate))
               o_metaStruct.META_AUX_MPE_ACQUISITION_RATE = metaData.sensors.sensor_mpe.acquisition.rate;
            end
         end
         if (isfield(metaData.sensors.sensor_mpe, 'photodetector'))
            if (isfield(metaData.sensors.sensor_mpe.photodetector, 'responsivityw') && ...
                  ~isempty(metaData.sensors.sensor_mpe.photodetector.responsivityw))
               o_metaStruct.META_AUX_MPE_PHOTODETECTOR_RESPONSIVITY_W = metaData.sensors.sensor_mpe.photodetector.responsivityw;
            end
            if (isfield(metaData.sensors.sensor_mpe.photodetector, 'responsivitya') && ...
                  ~isempty(metaData.sensors.sensor_mpe.photodetector.responsivitya))
               o_metaStruct.META_AUX_MPE_PHOTODETECTOR_RESPONSIVITY_A = metaData.sensors.sensor_mpe.photodetector.responsivitya;
            end
            if (isfield(metaData.sensors.sensor_mpe.photodetector, 'units') && ...
                  ~isempty(metaData.sensors.sensor_mpe.photodetector.units))
               o_metaStruct.META_AUX_MPE_PHOTODETECTOR_RESPONSIVITY_UNITS = metaData.sensors.sensor_mpe.photodetector.units;
            end
         end
         if (isfield(metaData.sensors.sensor_mpe, 'microradiometer'))
            if (isfield(metaData.sensors.sensor_mpe.microradiometer, 'gainhm') && ...
                  ~isempty(metaData.sensors.sensor_mpe.microradiometer.gainhm))
               o_metaStruct.META_AUX_MPE_MICRORADIOMETER_GAIN_HM = metaData.sensors.sensor_mpe.microradiometer.gainhm;
            end
            if (isfield(metaData.sensors.sensor_mpe.microradiometer, 'gainml') && ...
                  ~isempty(metaData.sensors.sensor_mpe.microradiometer.gainml))
               o_metaStruct.META_AUX_MPE_MICRORADIOMETER_GAIN_ML = metaData.sensors.sensor_mpe.microradiometer.gainml;
            end
            if (isfield(metaData.sensors.sensor_mpe.microradiometer, 'offseth') && ...
                  ~isempty(metaData.sensors.sensor_mpe.microradiometer.offseth))
               o_metaStruct.META_AUX_MPE_MICRORADIOMETER_OFFSET_H = metaData.sensors.sensor_mpe.microradiometer.offseth;
            end
            if (isfield(metaData.sensors.sensor_mpe.microradiometer, 'offsetm') && ...
                  ~isempty(metaData.sensors.sensor_mpe.microradiometer.offsetm))
               o_metaStruct.META_AUX_MPE_MICRORADIOMETER_OFFSET_M = metaData.sensors.sensor_mpe.microradiometer.offsetm;
            end
            if (isfield(metaData.sensors.sensor_mpe.microradiometer, 'offsetl') && ...
                  ~isempty(metaData.sensors.sensor_mpe.microradiometer.offsetl))
               o_metaStruct.META_AUX_MPE_MICRORADIOMETER_OFFSET_L = metaData.sensors.sensor_mpe.microradiometer.offsetl;
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % HYDROC
   if (any(a_sensorListNum == 18))
      if (isfield(metaData.sensors, 'sensor_hydroc'))
         if (~isfield(o_metaStruct, 'META_AUX_HYDROC_SERIAL_NO'))
            o_metaStruct.META_AUX_HYDROC_SERIAL_NO = metaData.sensors.sensor_hydroc.sensor.sn;
         end
         if (~isfield(o_metaStruct, 'META_AUX_HYDROC_FIRMWARE_VERSION'))
            o_metaStruct.META_AUX_HYDROC_FIRMWARE_VERSION = metaData.sensors.sensor_hydroc.hydroc_board.firmware;
         end
         if (~isfield(o_metaStruct, 'META_AUX_HYDROC_HARDWARE_VERSION'))
            o_metaStruct.META_AUX_HYDROC_HARDWARE_VERSION = metaData.sensors.sensor_hydroc.hydroc_board.hardware;
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % RAMSES
   if (any(a_sensorListNum == 14))
      if (isfield(metaData.sensors, 'sensor_ramses'))
         if (isfield(metaData.sensors.sensor_ramses, 'ramses_board'))
            if (isfield(metaData.sensors.sensor_ramses.ramses_board, 'firmware'))
               if (~isfield(o_metaStruct, 'META_AUX_RAMSES_ACC_FIRMWARE_VERSION'))
                  o_metaStruct.META_AUX_RAMSES_ACC_FIRMWARE_VERSION = metaData.sensors.sensor_ramses.ramses_board.firmware;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_ramses, 'spectrum'))
            if (isfield(metaData.sensors.sensor_ramses.spectrum, 'length'))
               if (~isfield(o_metaStruct, 'META_AUX_RAMSES_ACC_SPECTRUM_LENGTH'))
                  o_metaStruct.META_AUX_RAMSES_ACC_SPECTRUM_LENGTH = metaData.sensors.sensor_ramses.spectrum.length;
               end
            end
            if (isfield(metaData.sensors.sensor_ramses.spectrum, 'wavelengths'))
               if (~isfield(o_metaStruct, 'META_AUX_RAMSES_ACC_SPECTRUM_WAVELENGTHS'))
                  o_metaStruct.META_AUX_RAMSES_ACC_SPECTRUM_WAVELENGTHS = metaData.sensors.sensor_ramses.spectrum.wavelengths;
               end
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % RAMSES2
   if (any(a_sensorListNum == 21))
      if (isfield(metaData.sensors, 'sensor_ramses2'))
         if (isfield(metaData.sensors.sensor_ramses2, 'ramses_board'))
            if (isfield(metaData.sensors.sensor_ramses2.ramses_board, 'firmware'))
               if (~isfield(o_metaStruct, 'META_AUX_RAMSES_ARC_FIRMWARE_VERSION'))
                  o_metaStruct.META_AUX_RAMSES_ARC_FIRMWARE_VERSION = metaData.sensors.sensor_ramses2.ramses_board.firmware;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_ramses2, 'spectrum'))
            if (isfield(metaData.sensors.sensor_ramses2.spectrum, 'length'))
               if (~isfield(o_metaStruct, 'META_AUX_RAMSES_ARC_SPECTRUM_LENGTH'))
                  o_metaStruct.META_AUX_RAMSES_ARC_SPECTRUM_LENGTH = metaData.sensors.sensor_ramses2.spectrum.length;
               end
            end
            if (isfield(metaData.sensors.sensor_ramses2.spectrum, 'wavelengths'))
               if (~isfield(o_metaStruct, 'META_AUX_RAMSES_ARC_SPECTRUM_WAVELENGTHS'))
                  o_metaStruct.META_AUX_RAMSES_ARC_SPECTRUM_WAVELENGTHS = metaData.sensors.sensor_ramses2.spectrum.wavelengths;
               end
            end
         end
      end
   end
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IMU
   if (any(a_sensorListNum == 20))
      if (isfield(metaData.sensors, 'sensor_imu'))
         if (isfield(metaData.sensors.sensor_imu, 'sensor'))
            if (isfield(metaData.sensors.sensor_imu.sensor, 'orientation'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ORIENTATION'))
                  o_metaStruct.META_AUX_IMU_ORIENTATION = metaData.sensors.sensor_imu.sensor.orientation;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.sensor, 'mode'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_MODE'))
                  o_metaStruct.META_AUX_IMU_MODE = metaData.sensors.sensor_imu.sensor.mode;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_imu, 'temperature'))
            if (isfield(metaData.sensors.sensor_imu.temperature, 't0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_TEMPERATURE_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_TEMPERATURE_COR_OFFSET = metaData.sensors.sensor_imu.temperature.t0;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_imu, 'accelerometer'))
            if (isfield(metaData.sensors.sensor_imu.accelerometer, 'ax0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ACCELEROMETER_X_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_ACCELEROMETER_X_COR_OFFSET = metaData.sensors.sensor_imu.accelerometer.ax0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.accelerometer, 'ay0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ACCELEROMETER_Y_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_ACCELEROMETER_Y_COR_OFFSET = metaData.sensors.sensor_imu.accelerometer.ay0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.accelerometer, 'az0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ACCELEROMETER_Z_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_ACCELEROMETER_Z_COR_OFFSET = metaData.sensors.sensor_imu.accelerometer.az0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.accelerometer, 'axg'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ACCELEROMETER_X_COR_GAIN'))
                  o_metaStruct.META_AUX_IMU_ACCELEROMETER_X_COR_GAIN = metaData.sensors.sensor_imu.accelerometer.axg;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.accelerometer, 'ayg'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ACCELEROMETER_Y_COR_GAIN'))
                  o_metaStruct.META_AUX_IMU_ACCELEROMETER_Y_COR_GAIN = metaData.sensors.sensor_imu.accelerometer.ayg;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.accelerometer, 'azg'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_ACCELEROMETER_Z_COR_GAIN'))
                  o_metaStruct.META_AUX_IMU_ACCELEROMETER_Z_COR_GAIN = metaData.sensors.sensor_imu.accelerometer.azg;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_imu, 'gyroscope'))
            if (isfield(metaData.sensors.sensor_imu.gyroscope, 'gx0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_GYROSCOPE_X_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_GYROSCOPE_X_COR_OFFSET = metaData.sensors.sensor_imu.gyroscope.gx0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.gyroscope, 'gy0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_GYROSCOPE_Y_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_GYROSCOPE_Y_COR_OFFSET = metaData.sensors.sensor_imu.gyroscope.gy0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.gyroscope, 'gz0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_GYROSCOPE_Z_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_GYROSCOPE_Z_COR_OFFSET = metaData.sensors.sensor_imu.gyroscope.gz0;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_imu, 'magnetometer'))
            if (isfield(metaData.sensors.sensor_imu.magnetometer, 'mx0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_MAGNETOMETER_X_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_MAGNETOMETER_X_COR_OFFSET = metaData.sensors.sensor_imu.magnetometer.mx0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.magnetometer, 'my0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_MAGNETOMETER_Y_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_MAGNETOMETER_Y_COR_OFFSET = metaData.sensors.sensor_imu.magnetometer.my0;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.magnetometer, 'mz0'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_MAGNETOMETER_Z_COR_OFFSET'))
                  o_metaStruct.META_AUX_IMU_MAGNETOMETER_Z_COR_OFFSET = metaData.sensors.sensor_imu.magnetometer.mz0;
               end
            end
         end
         if (isfield(metaData.sensors.sensor_imu, 'compass'))
            if (isfield(metaData.sensors.sensor_imu.compass, 'hi1'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_COMPASS_HARD_IRON_COR_OFFSET1'))
                  o_metaStruct.META_AUX_IMU_COMPASS_HARD_IRON_COR_OFFSET1 = metaData.sensors.sensor_imu.compass.hi1;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.compass, 'hi2'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_COMPASS_HARD_IRON_COR_OFFSET2'))
                  o_metaStruct.META_AUX_IMU_COMPASS_HARD_IRON_COR_OFFSET2 = metaData.sensors.sensor_imu.compass.hi2;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.compass, 'si11'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX11'))
                  o_metaStruct.META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX11 = metaData.sensors.sensor_imu.compass.si11;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.compass, 'si12'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX12'))
                  o_metaStruct.META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX12 = metaData.sensors.sensor_imu.compass.si12;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.compass, 'si21'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX21'))
                  o_metaStruct.META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX21 = metaData.sensors.sensor_imu.compass.si21;
               end
            end
            if (isfield(metaData.sensors.sensor_imu.compass, 'si22'))
               if (~isfield(o_metaStruct, 'META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX22'))
                  o_metaStruct.META_AUX_IMU_COMPASS_SOFT_IRON_COR_MATRIX22 = metaData.sensors.sensor_imu.compass.si22;
               end
            end
         end
      end
   end
end

if (~isempty(g_cogj_csvFileCoefId))
   fclose(g_cogj_csvFileCoefId);
   g_cogj_csvFileCoefId = '';
end

if (~isempty(g_cogj_csvFileBddId))
   fclose(g_cogj_csvFileBddId);
   g_cogj_csvFileBddId = '';
end

return

% ------------------------------------------------------------------------------
% Open CSV file.
%
% SYNTAX :
%  [o_csvFileId, o_csvFilePathName] = open_csv_file( ...
%    a_outputCsvDirName, a_fileType, a_csvFilePathName)
%
% INPUT PARAMETERS :
%   a_outputCsvDirName : output CSV file directory
%   a_fileType         : file type ('B': BDD file, 'C': calib coef file)
%
% OUTPUT PARAMETERS :
%   o_csvFileId       : CSV file Id
%   o_csvFilePathName : CSV file path name
%   a_csvFilePathName : input CSV file path name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_csvFileId, o_csvFilePathName] = open_csv_file( ...
   a_outputCsvDirName, a_fileType, a_csvFilePathName)

% output parameters initialization
o_csvFileId = '';
o_csvFilePathName = '';

% open output CSV file
if (a_fileType == 'B')
   if (isempty(a_csvFilePathName))
      csvFilePathName = [a_outputCsvDirName '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      csvFileId = fopen(csvFilePathName, 'wt');
      if (csvFileId == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', csvFilePathName);
         return
      end

      header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
      fprintf(csvFileId, '%s\n', header);
   else
      csvFilePathName = a_csvFilePathName;
      csvFileId = fopen(csvFilePathName, 'a');
      if (csvFileId == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', csvFilePathName);
         return
      end
   end
end
if (a_fileType == 'C')
   if (isempty(a_csvFilePathName))
      csvFilePathName = [a_outputCsvDirName '/data_to_update_calib_coef_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      csvFileId = fopen(csvFilePathName, 'wt');
      if (csvFileId == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', csvFilePathName);
         return
      end

      header = 'WMO;SENSOR;COEF_NAME;COEF_VALUE';
      fprintf(csvFileId, '%s\n', header);
   else
      csvFilePathName = a_csvFilePathName;
      csvFileId = fopen(csvFilePathName, 'a');
      if (csvFileId == -1)
         fprintf('ERROR: Unable to create CSV output file: %s\n', csvFilePathName);
         return
      end
   end
end

o_csvFileId = csvFileId;
o_csvFilePathName = csvFilePathName;

return

