% ------------------------------------------------------------------------------
% Decode APEX Argos data and emergency messages.
%
% SYNTAX :
%  [o_miscInfo, o_profData, o_metaData, o_techData, ...
%    o_trajData, o_timeInfo, o_tabTechNMeas, ...
%    o_timeData, o_presOffsetData] = ...
%    decode_data_apx_21(a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
%    a_sensorData, a_sensorDate, a_cycleNum, a_timeData, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_argosDataData  : Argos received message data
%   a_argosDataUsed  : Argos used message data
%   a_argosDataDate  : Argos received message dates
%   a_sensorData     : Argos selected data
%   a_sensorDate     : Argos selected data dates
%   a_cycleNum       : cycle number
%   a_timeData       : input cycle time data structure
%   a_presOffsetData : input pressure offset data structure
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc info from test and data messages
%   o_profData       : profile data
%   o_metaData       : meta data
%   o_techData       : technical data
%   o_trajData       : trajectory data
%   o_timeInfo       : time info from test and data messages
%   o_tabTechNMeas   : N_MEASUREMENT structure of technical data time series
%   o_timeData       : updated cycle time data structure
%   o_presOffsetData : updated pressure offset data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_profData, o_metaData, o_techData, ...
   o_trajData, o_timeInfo, o_tabTechNMeas, ...
   o_timeData, o_presOffsetData] = ...
   decode_data_apx_21(a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
   a_sensorData, a_sensorDate, a_cycleNum, a_timeData, a_presOffsetData)

% output parameters initialization
o_miscInfo = [];
o_profData = [];
o_metaData = [];
o_techData = [];
o_trajData = [];
o_timeInfo = [];
o_tabTechNMeas = [];
o_timeData = a_timeData;
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_janFirst1970InJulD;

% global measurement codes
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMeanOfDiff;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;

PRINT_FROZEN_BYTES = 0;


if (isempty(a_sensorData))
   return
end

% information on hydrographic data storage
NB_PARAM = 3;
NB_PARAM_BYTE = 6;

% profile data storage variables
% 29 data msg at most (from #10 to #38)
% 24 profile bytes in data msg #12
% 29 profile bytes in data msg #13 to #38 => 29*(38-13+1) = 754
profData = ones(778, 1)*hex2dec('FF'); % 778 = 24 + 754
profReceived = zeros(778, 1);
profRedundancy = ones(778, 1)*-1;

% to store time series of tech data
techSeries = [];

% process each sensor data message
profileLength = -1;
o_timeData.configParam.profileLength = [];
maxMsgNum = 38;
for idL = 1:size(a_sensorData, 1)
   msgData = a_sensorData(idL, :);
   msgRed = msgData(1);
   msgNum = msgData(2);
   msgDate = a_sensorDate(idL);
   idListFB = a_argosDataUsed{idL};
   idList = idListFB;
   if (PRINT_FROZEN_BYTES == 0)
      idList = [];
   end
   
   if (msgNum == 9) % emergency message
      
      % emergency msg
      fprintf('ERROR: Float #%d Cycle #%d: emergency message decoding is implemented but never checked - not used\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      
      if (0)
         
         % first item bit number
         firstBit = 17;
         % item bit lengths
         tabNbBits = [1 1 1 1 1 1 1 1 1 1 1 4 1 1 2]*8;
         % get item bits
         decData = get_bits(firstBit, tabNbBits, msgData);
         
         % also decode data updated during transmission
         decDataBis = [];
         decDataRedBis = [];
         decDataNumBis = [];
         decDateBis = [];
         for id = 1:length(idListFB)
            decDataBis(id, :) = get_bits(firstBit, tabNbBits, a_argosDataData(idListFB(id), :));
            decDataRedBis(id) = 1;
            decDataNumBis(id) = a_argosDataData(idListFB(id), 2);
            decDateBis(id) = a_argosDataDate(idListFB(id));
         end
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = sprintf('EMERGENCY MESSAGE #%d', msgNum);
         o_miscInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Message date';
         dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
         dataStruct.format = ' %s';
         dataStruct.unit = 'UTC';
         o_miscInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Message redundancy';
         dataStruct.value = msgRed;
         dataStruct.format = '%d';
         o_miscInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Firmware revision number';
         dataStruct.value = sprintf('%d.%d.%d', decData(2:4));
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_meta_data_init_struct(msgRed);
         dataStruct.label = 'Firmware revision date';
         dataStruct.metaConfigLabel = 'FIRMWARE_VERSION';
         dataStruct.metaFlag = 1;
         dataStruct.value = sprintf('%d.%d.%d', decData(2:4));
         dataStruct.techParamCode = 'FIRMWARE_VERSION';
         dataStruct.techParamId = 961;
         dataStruct.techParamValue = dataStruct.value;
         o_metaData = [o_metaData; dataStruct];
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Float ID';
         decData2 = get_bits(1, [1 10 6 7], decData(5:7));
         dataStruct.value = sprintf('%03d-%02d%02d', decData2(5:7));
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_meta_data_init_struct(msgRed);
         dataStruct.label = 'Float ID';
         dataStruct.metaConfigLabel = 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY';
         dataStruct.metaFlag = 1;
         decData2 = get_bits(1, [1 10 6 7], decData(5:7));
         dataStruct.value = sprintf('%03d-%02d%02d', decData2(5:7));
         dataStruct.techParamCode = 'CONTROLLER_BOARD_SERIAL_NO_PRIMA';
         dataStruct.techParamId = 1252;
         dataStruct.techParamValue = dataStruct.value;
         o_metaData = [o_metaData; dataStruct];
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Telonics PTT status byte';
         dataStruct.value = 'NOT IMPLEMENTED YET IN FLOAT FIRMWARE';
         %          dataStruct.value = sprintf('0b%s', dec2bin(decData(8), 8));
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
         
         % NOT IMPLEMENTED YET IN FLOAT FIRMWARE
         %          dataStruct = get_apx_tech_data_init_struct(msgRed);
         %          dataStruct.label = 'Telonics PTT status byte';
         %          dataStruct.techId = 900;
         %          dataStruct.value = sprintf('%#X', decData(8));
         %          o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Air bladder pressure during transmission';
         dataStruct.raw = decData(9)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_air_bladder_pressure(decData(9)*16);
         dataStruct.format = '%.2f';
         dataStruct.unit = 'dbar';
         o_miscInfo{end+1} = dataStruct;
         
         for id = 2:length(idList)
            dataStruct = get_apx_misc_data_init_struct('Emer. msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
            dataStruct.label = 'Air bladder pressure during transmission';
            dataStruct.raw = decDataBis(id, 9)*16;
            dataStruct.rawFormat = '%d';
            dataStruct.rawUnit = 'count';
            dataStruct.value = sensor_2_value_for_apex_apf11_air_bladder_pressure(decDataBis(id, 9)*16);
            dataStruct.format = '%.2f';
            dataStruct.unit = 'dbar';
            o_miscInfo{end+1} = dataStruct;
         end
         
         tabBladPres = [];
         for id = 1:length(idListFB)
            tabBladPres(end+1) = sensor_2_value_for_apex_apf11_air_bladder_pressure(decDataBis(id, 9)*16);
         end
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Averaged air bladder pressure during transmission';
         dataStruct.techId = 901;
         dataStruct.value = num2str(round(mean(tabBladPres)*100)/100);
         o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Quiescent battery voltage during transmission';
         dataStruct.raw = decData(10)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decData(10)*16);
         dataStruct.format = '%.2f';
         dataStruct.unit = 'V';
         o_miscInfo{end+1} = dataStruct;
         
         for id = 2:length(idList)
            dataStruct = get_apx_misc_data_init_struct('Emer. msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
            dataStruct.label = 'Quiescent battery voltage during transmission';
            dataStruct.raw = decDataBis(id, 10)*16;
            dataStruct.rawFormat = '%d';
            dataStruct.rawUnit = 'count';
            dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decDataBis(id, 10)*16);
            dataStruct.format = '%.2f';
            dataStruct.unit = 'V';
            o_miscInfo{end+1} = dataStruct;
         end
         
         tabBatVolt = [];
         for id = 1:length(idListFB)
            tabBatVolt(end+1) = sensor_2_value_for_apex_apf11_battery_voltage(decDataBis(id, 10)*16);
         end
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Averaged quiescent battery voltage during transmission';
         dataStruct.techId = 902;
         dataStruct.value = num2str(round(mean(tabBatVolt)*100)/100);
         o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Internal vacuum during transmission';
         dataStruct.raw = decData(11)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_vacuum(decData(11)*16);
         dataStruct.format = '%.2f';
         dataStruct.unit = 'dbar';
         o_miscInfo{end+1} = dataStruct;
         
         for id = 2:length(idList)
            dataStruct = get_apx_misc_data_init_struct('Emer. msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
            dataStruct.label = 'Internal vacuum during transmission';
            dataStruct.raw = decDataBis(id, 11)*16;
            dataStruct.rawFormat = '%d';
            dataStruct.rawUnit = 'count';
            dataStruct.value = sensor_2_value_for_apex_apf11_vacuum(decDataBis(id, 11)*16);
            dataStruct.format = '%.2f';
            dataStruct.unit = 'dbar';
            o_miscInfo{end+1} = dataStruct;
         end
         
         tabVacuum = [];
         for id = 1:length(idListFB)
            tabVacuum(end+1) = sensor_2_value_for_apex_apf11_vacuum(decDataBis(id, 11)*16);
         end
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Averaged internal vacuum during transmission';
         dataStruct.techId = 903;
         dataStruct.value = num2str(round(mean(tabVacuum)*100)/100);
         o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'The exception program counter';
         dataStruct.value = sprintf('%#X', decData(12));
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'The exception program counter';
         dataStruct.techId = 904;
         dataStruct.value = sprintf('%#X', decData(12));
         o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Battery voltage while air pump running';
         dataStruct.raw = decData(13)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decData(13)*16);
         dataStruct.format = '%.2f';
         dataStruct.unit = 'V';
         o_miscInfo{end+1} = dataStruct;
         
         for id = 2:length(idList)
            dataStruct = get_apx_misc_data_init_struct('Emer. msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
            dataStruct.label = 'Battery voltage while air pump running';
            dataStruct.raw = decDataBis(id, 13)*16;
            dataStruct.rawFormat = '%d';
            dataStruct.rawUnit = 'count';
            dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decDataBis(id, 13)*16);
            dataStruct.format = '%.2f';
            dataStruct.unit = 'V';
            o_miscInfo{end+1} = dataStruct;
         end
         
         tabBatVolt = [];
         for id = 1:length(idListFB)
            tabBatVolt(end+1) = sensor_2_value_for_apex_apf11_battery_voltage(decDataBis(id, 13)*16);
         end
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Averaged battery voltage while air pump running';
         dataStruct.techId = 905;
         dataStruct.value = num2str(round(mean(tabBatVolt)*100)/100);
         o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Air pump current while air pump running';
         dataStruct.raw = decData(14)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_air_pump_current(decData(14)*16);
         dataStruct.format = '%.3f';
         dataStruct.unit = 'mA';
         o_miscInfo{end+1} = dataStruct;
         
         for id = 2:length(idList)
            dataStruct = get_apx_misc_data_init_struct('Emer. msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
            dataStruct.label = 'Air pump current while air pump running';
            dataStruct.raw = decDataBis(id, 14)*16;
            dataStruct.rawFormat = '%d';
            dataStruct.rawUnit = 'count';
            dataStruct.value = sensor_2_value_for_apex_apf11_air_pump_current(decDataBis(id, 14)*16);
            dataStruct.format = '%.3f';
            dataStruct.unit = 'mA';
            o_miscInfo{end+1} = dataStruct;
         end
         
         tabBatCur = [];
         for id = 1:length(idListFB)
            tabBatCur(end+1) = sensor_2_value_for_apex_apf11_air_pump_current(decDataBis(id, 14)*16);
         end
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Average air pump current while air pump running';
         dataStruct.techId = 906;
         dataStruct.value = num2str(round(mean(tabBatCur)*1000)/1000);
         o_techData{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Emer. msg', msgNum, msgRed, msgDate);
         dataStruct.label = 'Integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
         dataStruct.value = decData(15);
         dataStruct.format = '%d';
         o_miscInfo{end+1} = dataStruct;
         
         for id = 2:length(idList)
            dataStruct = get_apx_misc_data_init_struct('Emer. msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
            dataStruct.label = 'Integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
            dataStruct.value = decDataBis(id, 15);
            dataStruct.format = '%d';
            o_miscInfo{end+1} = dataStruct;
         end
         
         tabNum = [];
         for id = 1:length(idListFB)
            tabNum(end+1) = decDataBis(id, 15);
         end
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Averaged integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
         dataStruct.techId = 907;
         dataStruct.value = num2str(round(mean(tabNum)));
         o_techData{end+1} = dataStruct;
      end
      
   elseif (msgNum == 10) % data message #1
      
      % first item bit number
      firstBit = 17;
      % item bit lengths
      tabNbBits = [1 1 1 1 1 1 2 1 1 2 1 1 1 4 1 1 1 1 1 1 1 1 2]*8;
      % get item bits
      decData = get_bits(firstBit, tabNbBits, msgData);
      
      % also decode data updated during transmission
      decDataBis = [];
      decDataRedBis = [];
      decDataNumBis = [];
      decDateBis = [];
      for id = 1:length(idListFB)
         decDataBis(id, :) = get_bits(firstBit, tabNbBits, a_argosDataData(idListFB(id), :));
         decDataRedBis(id) = 1;
         decDataNumBis(id) = a_argosDataData(idListFB(id), 2);
         decDateBis(id) = a_argosDataDate(idListFB(id));
      end
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('DATA MESSAGE #%d', msgNum);
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message redundancy';
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Float ID';
      decData2 = get_bits(1, [1 10 6 7], decData(2:4));
      dataStruct.value = sprintf('%03d-%02d%02d', decData2(2:4));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Float ID';
      dataStruct.metaConfigLabel = 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY';
      dataStruct.metaFlag = 1;
      decData2 = get_bits(1, [1 10 6 7], decData(2:4));
      dataStruct.value = sprintf('%03d-%02d%02d', decData2(2:4));
      dataStruct.techParamCode = 'CONTROLLER_BOARD_SERIAL_NO_PRIMA';
      dataStruct.techParamId = 1252;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Profile number';
      dataStruct.value = decData(5);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Profile length';
      dataStruct.value = decData(6);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      profileLength = decData(6);
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Profile length';
      dataStruct.techId = 1000;
      dataStruct.value = num2str(decData(6));
      o_techData{end+1} = dataStruct;
      
      o_timeData.configParam.profileLength = decData(6);
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Float status word';
      dataStruct.value = 'NOT IMPLEMENTED YET IN FLOAT FIRMWARE';
      dataStruct.value = sprintf('0b%s', dec2bin(decData(7), 16));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Float status word';
      dataStruct.techId = 1001;
      dataStruct.value = sprintf('%#X', decData(7));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Telonics PTT status byte';
      dataStruct.value = 'NOT IMPLEMENTED YET IN FLOAT FIRMWARE';
      %       dataStruct.value = sprintf('0b%s', dec2bin(decData(8), 8));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      % NOT IMPLEMENTED YET IN FLOAT FIRMWARE
      %       dataStruct = get_apx_tech_data_init_struct(msgRed);
      %       dataStruct.label = 'Telonics PTT status byte';
      %       dataStruct.techId = 1002;
      %       dataStruct.value = sprintf('%#X', decData(8));
      %       o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Surface pressure during transmission';
      dataStruct.raw = decData(9);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure_1byte(decData(9));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Surface pressure during transmission';
         dataStruct.raw = decDataBis(id, 9);
         dataStruct.rawFormat = '%d';
         dataStruct.value = sensor_2_value_for_apex_apf11_pressure_1byte(decDataBis(id, 9));
         dataStruct.format = '%.3f';
         dataStruct.unit = 'dbar';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabSurfPres = [];
      techSeries.SURF_PRES = [];
      techSeries.SURF_PRES.value = [];
      techSeries.SURF_PRES.time = [];
      for id = 1:length(idListFB)
         surfPresValue = sensor_2_value_for_apex_apf11_pressure_1byte(decDataBis(id, 9));
         techSeries.SURF_PRES.value(end+1) = surfPresValue;
         techSeries.SURF_PRES.time(end+1) = decDateBis(id);        
         tabSurfPres(end+1) = surfPresValue;
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged surface pressure during transmission';
      dataStruct.techId = 1003;
      dataStruct.value = num2str(round(mean(tabSurfPres)*1000)/1000);
      o_techData{end+1} = dataStruct;
      
      % 'Surface pressure at end of Up Time' is always 0 for this float firmware
      % => this item is not used for PressOffset.
      % We use 'Averaged surface pressure during transmission' instead.
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged surface pressure during transmission';
      dataStruct.techId = 1004;
      dataStruct.value = num2str(round(mean(tabSurfPres)*1000)/1000);
      o_techData{end+1} = dataStruct;

      % 'Surface pressure at end of Up Time' is always 0 for this float firmware
      % => this item is not used for PressOffset.
      % We use 'Averaged surface pressure during transmission' instead.
      o_presOffsetData.cycleNum(end+1) = a_cycleNum;
      o_presOffsetData.cyclePresOffset(end+1) = round(mean(tabSurfPres)*1000)/1000;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Surface pressure at end of Up Time';
      dataStruct.raw = decData(10);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(10));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      % 'Surface pressure at end of Up Time' is always 0 for this float firmware
      % => this item is not used for PressOffset.
      % We use 'Averaged surface pressure during transmission' instead.
      %       dataStruct = get_apx_tech_data_init_struct(msgRed);
      %       dataStruct.label = 'Surface pressure at end of Up Time';
      %       dataStruct.techId = 1004;
      %       dataStruct.value = num2str(round(sensor_2_value_for_apex_apf11_pressure(decData(10))*1000)/1000);
      %       o_techData{end+1} = dataStruct;
      
      % 'Surface pressure at end of Up Time' is always 0 for this float firmware
      % => this item is not used for PressOffset.
      % We use 'Averaged surface pressure during transmission' instead.
      %       o_presOffsetData.cycleNum(end+1) = a_cycleNum;
      %       o_presOffsetData.cyclePresOffset(end+1) = sensor_2_value_for_apex_apf11_pressure(decData(10));
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston position when surface detected';
      dataStruct.value = decData(11)*16;
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Piston position when surface detected';
      dataStruct.techId = 1005;
      dataStruct.value = num2str(decData(11)*16);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston position at end of Park phase';
      dataStruct.value = decData(12)*16;
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Piston position at end of Park phase';
      dataStruct.techId = 1006;
      dataStruct.value = num2str(decData(12)*16);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston position at end of Deep descent phase';
      dataStruct.value = decData(13)*16;
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Piston position at end of Deep descent phase';
      dataStruct.techId = 1007;
      dataStruct.value = num2str(decData(13)*16);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'CTD status word';
      dataStruct.value = 'NOT IMPLEMENTED YET IN FLOAT FIRMWARE';
      %       dataStruct.value = sprintf('0b%s', dec2bin(decData(14), 32));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      % NOT IMPLEMENTED YET IN FLOAT FIRMWARE
      %       dataStruct = get_apx_tech_data_init_struct(msgRed);
      %       dataStruct.label = 'SBE41 status word';
      %       dataStruct.techId = 1008;
      %       dataStruct.value = sprintf('%#X', decData(14));
      %       o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Quiescent battery voltage at end of Park phase';
      dataStruct.raw = decData(15)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decData(15)*16);
      dataStruct.format = '%.2f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery voltage at end of Park phase';
      dataStruct.techId = 1009;
      dataStruct.value = num2str(round(sensor_2_value_for_apex_apf11_battery_voltage(decData(15)*16)*100)/100);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Quiescent battery current at end of Park phase';
      dataStruct.raw = decData(16);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_battery_current(decData(16));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery current at end of Park phase';
      dataStruct.techId = 1010;
      dataStruct.value = num2str(round(sensor_2_value_for_apex_apf11_battery_current(decData(16))*1000)/1000);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery voltage while CTD sampling at end of Park phase';
      dataStruct.raw = 'NOT IMPLEMENTED YET IN FLOAT FIRMWARE';
      dataStruct.rawFormat = '%s';
      %       dataStruct.raw = decData(17)*16;
      %       dataStruct.rawFormat = '%d';
      %       dataStruct.rawUnit = 'count';
      %       dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decData(17)*16);
      %       dataStruct.format = '%.2f';
      %       dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      % NOT IMPLEMENTED YET IN FLOAT FIRMWARE
      %       dataStruct = get_apx_tech_data_init_struct(msgRed);
      %       dataStruct.label = 'Battery voltage while CTD sampling at end of Park phase';
      %       dataStruct.techId = 1011;
      %       dataStruct.value = num2str(sensor_2_value_for_apex_apf11_battery_voltage(decData(17)*16));
      %       o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'CTD current while CTD sampling at end of Park phase';
      dataStruct.raw = 'NOT IMPLEMENTED YET IN FLOAT FIRMWARE';
      dataStruct.rawFormat = '%s';
      %       dataStruct.raw = decData(18)*16;
      %       dataStruct.rawFormat = '%d';
      %       dataStruct.rawUnit = 'count';
      %       dataStruct.value = sensor_2_value_for_apex_apf11_ctd_current(decData(18)*16);
      %       dataStruct.format = '%.3f';
      %       dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;
      
      % NOT IMPLEMENTED YET IN FLOAT FIRMWARE
      %       dataStruct = get_apx_tech_data_init_struct(msgRed);
      %       dataStruct.label = 'Battery current while CTD sampling at end of Park phase';
      %       dataStruct.techId = 1012;
      %       dataStruct.value = num2str(sensor_2_value_for_apex_apf11_ctd_current(decData(18)*16));
      %       o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Average battery voltage during initial ascent nudge';
      dataStruct.raw = decData(19)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decData(19)*16);
      dataStruct.format = '%.2f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Average battery voltage measured during initial ascent nudge';
      dataStruct.techId = 1013;
      dataStruct.value = num2str(round(sensor_2_value_for_apex_apf11_battery_voltage(decData(19)*16)*100)/100);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Average buoy pump current during initial ascent nudge';
      dataStruct.raw = decData(20)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_buoy_pump_current(decData(20)*16);
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Average buoy pump current during initial ascent nudge';
      dataStruct.techId = 1014;
      dataStruct.value = num2str(round(sensor_2_value_for_apex_apf11_buoy_pump_current(decData(20)*16)*1000)/1000);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery voltage while air pump running';
      dataStruct.raw = decData(21)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decData(21)*16);
      dataStruct.format = '%.2f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Battery voltage while air pump running';
         dataStruct.raw = decDataBis(id, 21)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_battery_voltage(decDataBis(id, 21)*16);
         dataStruct.format = '%.2f';
         dataStruct.unit = 'V';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBatVolt = [];
      for id = 1:length(idListFB)
         tabBatVolt(end+1) = sensor_2_value_for_apex_apf11_battery_voltage(decDataBis(id, 21)*16);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged battery voltage while air pump running';
      dataStruct.techId = 1015;
      dataStruct.value = num2str(round(mean(tabBatVolt)*100)/100);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Air pump current while air pump running';
      dataStruct.raw = decData(22)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_air_pump_current(decData(22)*16);
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Air pump current while air pump running';
         dataStruct.raw = decDataBis(id, 22)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_air_pump_current(decDataBis(id, 22)*16);
         dataStruct.format = '%.3f';
         dataStruct.unit = 'mA';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBatCur = [];
      for id = 1:length(idListFB)
         tabBatCur(end+1) = sensor_2_value_for_apex_apf11_air_pump_current(decDataBis(id, 22)*16);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Average air pump current while air pump running';
      dataStruct.techId = 1016;
      dataStruct.value = num2str(round(mean(tabBatCur)*1000)/1000);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
      dataStruct.value = decData(23);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
         dataStruct.value = decDataBis(id, 23);
         dataStruct.format = '%d';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabNum = [];
      for id = 1:length(idListFB)
         tabNum(end+1) = decDataBis(id, 23);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
      dataStruct.techId = 1017;
      dataStruct.value = num2str(round(mean(tabNum)));
      o_techData{end+1} = dataStruct;
      
   elseif (msgNum == 11) % data message #2
      
      % first item bit number
      firstBit = 17;
      % item bit lengths
      tabNbBits = [4 2 1 2 2 2 2 2 2 2 2 2 2 2]*8;
      % get item bits
      decData = get_bits(firstBit, tabNbBits, msgData);
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('DATA MESSAGE #%d', msgNum);
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message redundancy';
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'RTC time when down time expired';
      unixEpoch = uint32(decData(1));
      rtcTime = g_decArgo_janFirst1970InJulD + double(unixEpoch)/86400;
      dataStruct.value = julian_2_gregorian_dec_argo(rtcTime);
      dataStruct.format = ' %s';
      dataStruct.unit = 'RTC time';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_time_data_init_struct;
      dataStruct.label = 'downTimeEnd';
      dataStruct.value = rtcTime;
      o_timeInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Time when telemetry phase was initiated relative to down time end';
      timeDelay = twos_complement_dec_argo(decData(2), 16);
      dataStruct.raw = timeDelay;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'minute';
      dataStruct.value = format_time_dec_argo(timeDelay/60);
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = '=> transmission start time';
      dataStruct.value = julian_2_gregorian_dec_argo(rtcTime + timeDelay/1440);
      dataStruct.format = ' %s';
      dataStruct.unit = 'RTC time';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_time_data_init_struct;
      dataStruct.label = 'transStartDateFromFloat';
      dataStruct.value = rtcTime + timeDelay/1440;
      o_timeInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Number of active-ballast adjustments made during the park phase';
      dataStruct.value = decData(3);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Number of active-ballast adjustments made during the park phase';
      dataStruct.techId = 1018;
      dataStruct.value = num2str(decData(3));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Number of hourly park-level PT samples';
      dataStruct.value = decData(4);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Number of hourly park-level PT samples';
      dataStruct.techId = 1019;
      dataStruct.value = num2str(decData(4));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Mean temperature of park-level PT samples';
      dataStruct.raw = decData(5);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(5));
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Mean temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_DriftAtParkMean;
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(5));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Mean pressure diff of park-level PT samples';
      dataStruct.raw = decData(6);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(6));
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Mean pressure diff of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_DriftAtParkMeanOfDiff;
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(6));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Standard deviation of temperature of park-level PT samples';
      dataStruct.raw = decData(7);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(7));
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Standard deviation of temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_DriftAtParkStd;
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(7));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Standard deviation of pressure of park-level PT samples';
      dataStruct.raw = decData(8);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(8));
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Standard deviation of pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_DriftAtParkStd;
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(8));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Minimum temperature of park-level PT samples';
      dataStruct.raw = decData(9);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(9));
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Minimum temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_MinPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(9));
      o_trajData = [o_trajData; dataStruct];
      dataStruct.measCode = g_MC_MinPresInDriftAtParkSupportMeas;
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Pressure associated with Tmin of park-level PT samples';
      dataStruct.raw = decData(10);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(10));
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Pressure associated with Tmin of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MinPresInDriftAtParkSupportMeas;
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(10));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Maximum temperature of park-level PT samples';
      dataStruct.raw = decData(11);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(11));
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Maximum temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_MaxPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf11_temperature(decData(11));
      o_trajData = [o_trajData; dataStruct];
      dataStruct.measCode = g_MC_MaxPresInDriftAtParkSupportMeas;
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Pressure associated with Tmax of park-level PT samples';
      dataStruct.raw = decData(12);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(12));
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Pressure associated with Tmax of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MaxPresInDriftAtParkSupportMeas;
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(12));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Minimum pressure of park-level PT samples';
      dataStruct.raw = decData(13);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(13));
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Minimum pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MinPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(13));
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Maximum pressure of park-level PT samples';
      dataStruct.raw = decData(14);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(14));
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Maximum pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MaxPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf11_pressure(decData(14));
      o_trajData = [o_trajData; dataStruct];
      
   elseif (msgNum == 12) % data message #3
      
      % first item bit number
      firstBit = 17;
      % item bit lengths
      tabNbBits = [1 1 1 2]*8;
      % get item bits
      decData = get_bits(firstBit, tabNbBits, msgData);
      
      % also decode data updated during transmission
      decDataBis = [];
      decDataRedBis = [];
      decDataNumBis = [];
      decDateBis = [];
      for id = 1:length(idListFB)
         decDataBis(id, :) = get_bits(firstBit, tabNbBits, a_argosDataData(idListFB(id), :));
         decDataRedBis(id) = 1;
         decDataNumBis(id) = a_argosDataData(idListFB(id), 2);
         decDateBis(id) = a_argosDataDate(idListFB(id));
      end
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('DATA MESSAGE #%d', msgNum);
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message redundancy';
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Internal vacuum at end of Park phase';
      dataStruct.raw = decData(1)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_vacuum(decData(1)*16);
      dataStruct.format = '%.2f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Internal vacuum at end of Park phase';
      dataStruct.techId = 1020;
      dataStruct.value = num2str(round(sensor_2_value_for_apex_apf11_vacuum(decData(1)*16)*100)/100);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Air bladder pressure during transmission';
      dataStruct.raw = decData(2)*16;
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf11_air_bladder_pressure(decData(2)*16);
      dataStruct.format = '%.2f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Air bladder pressure during transmission';
         dataStruct.raw = decDataBis(id, 2)*16;
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf11_air_bladder_pressure(decDataBis(id, 2)*16);
         dataStruct.format = '%.2f';
         dataStruct.unit = 'dbar';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBladPres = [];
      for id = 1:length(idListFB)
         tabBladPres(end+1) = sensor_2_value_for_apex_apf11_air_bladder_pressure(decDataBis(id, 2)*16);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged air bladder pressure during transmission';
      dataStruct.techId = 1021;
      dataStruct.value = num2str(round(mean(tabBladPres)*100)/100);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'The number of 6-second pulses of the air pump required to inflate the air bladder';
      dataStruct.value = decData(3);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'The number of 6-second pulses of the air pump required to inflate the air bladder';
         dataStruct.value = decDataBis(id, 3);
         dataStruct.format = '%d';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabNum = [];
      for id = 1:length(idListFB)
         tabNum(end+1) = decDataBis(id, 3);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged number of 6-second pulses of the air pump required to inflate the air bladder';
      dataStruct.techId = 1022;
      dataStruct.value = num2str(round(mean(tabNum)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Cumulative piston on time during ascent';
      dataStruct.value = decData(4);
      dataStruct.format = '%d';
      dataStruct.unit = 'second';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Cumulative piston on time during ascent';
      dataStruct.techId = 1023;
      dataStruct.value = num2str(decData(4));
      o_techData{end+1} = dataStruct;
      
      % store profile data
      profData(1:24) = msgData(8:31);
      profReceived(1:24) = 255;
      profRedundancy(1:24) = msgRed;
      
   elseif ((msgNum >= 10) && (msgNum <= maxMsgNum)) % data message #(msgNum-10+1)
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('DATA MESSAGE #%d redundancy', msgNum);
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      % store profile data
      profData(24+(msgNum-13)*29+1:24+(msgNum-13)*29+29) = msgData(3:31);
      profReceived(24+(msgNum-13)*29+1:24+(msgNum-13)*29+29) = 255;
      profRedundancy(24+(msgNum-13)*29+1:24+(msgNum-13)*29+29) = msgRed;
      
   else
      
      fprintf('WARNING: Float #%d Cycle #%d: unexpected message #%d received (with a redundancy of %d) - not considered\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, msgNum, msgRed);
   end
end

% decode profile data
if (~any(profData ~= hex2dec('FF')))
   nbLev = 0;
else
   nbLev = floor(length(profData)/NB_PARAM_BYTE);
   if ((profileLength >= 0) && (nbLev > profileLength))
      nbLev = profileLength;
   end
   if (profileLength == -1)
      fprintf('DEC_WARNING: Float #%d Cycle #%d: profile length has not been received\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
   end
end

if (nbLev > 0)
   
   % first item bit number
   firstBit = 1;
   % item bit lengths
   tabNbBits = repmat(2, 1, nbLev*NB_PARAM)*8;
   % get item bits
   decData = get_bits(firstBit, tabNbBits, profData);
   receivedData = get_bits(firstBit, tabNbBits, profReceived);
   
   profPres = [];
   profPresRaw = [];
   profTemp = [];
   profSal = [];
   for idLev = 1:nbLev
      id = (idLev-1)*NB_PARAM;
      if ((receivedData(id+1) == 65535) && (decData(id+1) ~= 65535))
         temp = sensor_2_value_for_apex_apf11_temperature(decData(id+1));
      else
         temp = g_decArgo_tempDef;
      end
      if ((receivedData(id+2) == 65535) && (decData(id+2) ~= 65535))
         pres = sensor_2_value_for_apex_apf11_pressure(decData(id+2));
      else
         pres = g_decArgo_presDef;
      end
      if ((receivedData(id+3) == 65535) && (decData(id+3) ~= 65535))
         sal = sensor_2_value_for_apex_apf11_salinity(decData(id+3));
      else
         sal = g_decArgo_salDef;
      end
      
      profPres = [profPres; pres];
      profPresRaw = [profPresRaw; profData((idLev-1)*NB_PARAM_BYTE+5) profData((idLev-1)*NB_PARAM_BYTE+6)];
      profTemp = [profTemp; temp];
      profSal = [profSal; sal];
      
   end
   
   % manage data redundancy
   redData = ones(nbLev*NB_PARAM, 1)*-1;
   for id = 1:length(redData)
      redData(id) = min(profRedundancy((id-1)*2+1), profRedundancy((id-1)*2+2));
   end
   profTempRed = redData(1:NB_PARAM:end);
   profSalRed = redData(2:NB_PARAM:end);
   profPresRed = redData(3:NB_PARAM:end);
   
   % clean profile data
   if (profileLength >= 0)
      profPres(profileLength+1:end) = [];
      profTemp(profileLength+1:end) = [];
      profSal(profileLength+1:end) = [];
      
      profPresRed(profileLength+1:end) = [];
      profTempRed(profileLength+1:end) = [];
      profSalRed(profileLength+1:end) = [];
   else
      % the profile length is unknown, we keep only ascending pressures for the
      % profile
      idPresNoDef = find(profPres ~= g_decArgo_presDef);
      idStop = find(diff(profPres(idPresNoDef)) > 0);
      if (~isempty(idStop))
         profileLength2 = idPresNoDef(idStop(1));
         while (((profileLength2 + 1) <= length(profPres)) && ...
               (profPres(profileLength2 + 1) == g_decArgo_presDef))
            profileLength2 = profileLength2 + 1;
         end
         
         profPres(profileLength2+1:end) = [];
         profTemp(profileLength2+1:end) = [];
         profSal(profileLength2+1:end) = [];
         
         profPresRed(profileLength2+1:end) = [];
         profTempRed(profileLength2+1:end) = [];
         profSalRed(profileLength2+1:end) = [];
      end
   end
   
   idDel = (find((profPres == g_decArgo_presDef) & (profTemp == g_decArgo_tempDef) & (profSal == g_decArgo_salDef)));
   profPres(idDel) = [];
   profTemp(idDel) = [];
   profSal(idDel) = [];
   
   profPresRed(idDel) = [];
   profTempRed(idDel) = [];
   profSalRed(idDel) = [];
   
   % initialize profile data structure
   o_profData = get_apx_profile_data_init_struct;
   
   % update the expected number of profile levels
   if (profileLength >= 0)
      o_profData.expectedProfileLength = profileLength;
   end
   
   % create the parameters
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramSal = get_netcdf_param_attributes('PSAL');
   
   % convert decoder default values to netCDF fill values
   profPres(find(profPres == g_decArgo_presDef)) = paramPres.fillValue;
   profTemp(find(profTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   profSal(find(profSal == g_decArgo_salDef)) = paramSal.fillValue;
   
   % add parameter variables to the profile structure
   o_profData.paramList = [paramPres paramTemp paramSal];
   
   % add parameter data to the profile structure
   o_profData.data = [profPres profTemp profSal];
   
   % add parameter data redundancy to the profile structure
   o_profData.dataRed = [profPresRed profTempRed profSalRed];
end

if (~isempty(techSeries))
   if (isfield(techSeries, 'SURF_PRES') && ~isempty(techSeries.SURF_PRES.value))
      o_tabTechNMeas = create_technical_time_series_apx_21_22( ...
         techSeries.SURF_PRES, 'SURFACE_PRESSURE_DBAR');
   end
end

return
