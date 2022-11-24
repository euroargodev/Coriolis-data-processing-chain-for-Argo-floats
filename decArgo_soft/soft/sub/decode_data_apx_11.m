% ------------------------------------------------------------------------------
% Decode APEX Argos data messages.
%
% SYNTAX :
%  [o_miscInfo, o_auxInfo, o_profData, o_parkData, ...
%    o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
%    decode_data_apx_11(a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
%    a_sensorData, a_sensorDate, a_cycleNum, a_timeData, a_presOffsetData, a_decoderId)
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
%   a_decoderId      : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc info from test and data messages
%   o_auxInfo        : auxiliary info from auxiliary engineering data
%   o_profData       : profile data
%   o_parkData       : parking data
%   o_metaData       : meta data
%   o_techData       : technical data
%   o_trajData       : trajectory data
%   o_timeInfo       : time info from test and data messages
%   o_timeData       : updated cycle time data structure
%   o_presOffsetData : updated pressure offset data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_auxInfo, o_profData, o_parkData, ...
   o_metaData, o_techData, o_trajData, o_timeInfo, o_timeData, o_presOffsetData] = ...
   decode_data_apx_11(a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
   a_sensorData, a_sensorDate, a_cycleNum, a_timeData, a_presOffsetData, a_decoderId)

% output parameters initialization
o_miscInfo = [];
o_auxInfo = [];
o_profData = [];
o_parkData = [];
o_metaData = [];
o_techData = [];
o_trajData = [];
o_timeInfo = [];
o_timeData = a_timeData;
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_janFirst1970InJulD;

% global time status
global g_JULD_STATUS_9;

% global measurement codes
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_MedianValueInAscProf;

PRINT_FROZEN_BYTES = 0;


if (isempty(a_sensorData))
   return
end

% information on hydrographic data storage
NB_PARAM = 3;
NB_PARAM_BYTE = 6;

% profile data storage variables
lastMsgNum = max(a_sensorData(:, 2));
profData = ones(14+(lastMsgNum-3)*29, 1)*hex2dec('FF');
profReceived = zeros(14+(lastMsgNum-3)*29, 1);
profRedundancy = ones(14+(lastMsgNum-3)*29, 1)*-1;

% process each sensor data message
profileLength = -1;
o_timeData.configParam.profileLength = [];
firstAuxByte = -1;
paramPres = get_netcdf_param_attributes('PRES');
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
   
   if (msgNum == 1)
      
      % first item bit number
      firstBit = 17;
      % item bit lengths
      tabNbBits = [1 2 1 1 2 2 1 1 1 1 4 1 1 1 1 1 1 1 1 1 1 2]*8;
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
      dataStruct.label = 'Float ID (Apf9 controller serial number)';
      dataStruct.value = decData(2);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Float ID (Apf9 controller serial number)';
      dataStruct.metaConfigLabel = 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY';
      dataStruct.metaFlag = 1;
      dataStruct.value = num2str(decData(2));
      dataStruct.techParamCode = 'CONTROLLER_BOARD_SERIAL_NO_PRIMA';
      dataStruct.techParamId = 1252;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Profile number';
      dataStruct.value = decData(3);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Profile length';
      dataStruct.value = decData(4);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      profileLength = decData(4);
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Profile length';
      dataStruct.techId = 1000;
      dataStruct.value = num2str(decData(4));
      o_techData{end+1} = dataStruct;
      
      o_timeData.configParam.profileLength = decData(4);

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Float status word';
      dataStruct.value = sprintf('%#X', decData(5));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Float status word';
      dataStruct.techId = 1001;
      dataStruct.value = sprintf('%#X', decData(5));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Surface pressure at end of Up Time';
      dataStruct.raw = decData(6);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(6), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Surface pressure at end of Up Time';
      dataStruct.techId = 1002;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_pressure(decData(6), g_decArgo_presDef));
      o_techData{end+1} = dataStruct;
      
      o_presOffsetData.cycleNum(end+1) = a_cycleNum;
      o_presOffsetData.cyclePresOffset(end+1) = sensor_2_value_for_apex_apf9_pressure(decData(6), g_decArgo_presDef);

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Surface pressure during transmission';
      dataStruct.raw = decData(7);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure_1byte(decData(7), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Surface pressure during transmission';
         dataStruct.raw = decDataBis(id, 7);
         dataStruct.rawFormat = '%d';
         dataStruct.value = sensor_2_value_for_apex_apf9_pressure_1byte(decDataBis(id, 7), g_decArgo_presDef);
         dataStruct.format = '%.1f';
         dataStruct.unit = 'dbar';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabSurfPres = [];
      for id = 1:length(idListFB)
         tabSurfPres(end+1) = sensor_2_value_for_apex_apf9_pressure_1byte(decDataBis(id, 7), g_decArgo_presDef);
      end
      tabSurfPres(find(tabSurfPres == g_decArgo_presDef)) = [];
            
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged surface pressure during transmission';
      dataStruct.techId = 1003;
      dataStruct.value = num2str(round(mean(tabSurfPres)*10)/10);
      o_techData{end+1} = dataStruct;  

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston position when surface detected';
      dataStruct.value = decData(8);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Piston position when surface detected';
      dataStruct.techId = 1004;
      dataStruct.value = num2str(decData(8));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston position at end of Park phase';
      dataStruct.value = decData(9);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Piston position at end of Park phase';
      dataStruct.techId = 1005;
      dataStruct.value = num2str(decData(9));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston position at end of Deep descent phase';
      dataStruct.value = decData(10);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Piston position at end of Deep descent phase';
      dataStruct.techId = 1006;
      dataStruct.value = num2str(decData(10));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'SBE41 status word';
      dataStruct.value = sprintf('%#X', decData(11));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'SBE41 status word';
      dataStruct.techId = 1007;
      dataStruct.value = sprintf('%#X', decData(11));
      o_techData{end+1} = dataStruct;
            
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery voltage at end of Park phase';
      dataStruct.raw = decData(12);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decData(12));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery voltage at end of Park phase';
      dataStruct.techId = 1008;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_voltage(decData(12)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery current at end of Park phase';
      dataStruct.raw = decData(13);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_current(decData(13));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery current at end of Park phase';
      dataStruct.techId = 1009;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_current(decData(13)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery voltage while SBE41 sampling at end of Park phase';
      dataStruct.raw = decData(14);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decData(14));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery voltage while SBE41 sampling at end of Park phase';
      dataStruct.techId = 1010;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_voltage(decData(14)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery current while SBE41 sampling at end of Park phase';
      dataStruct.raw = decData(15);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_current(decData(15));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery current while SBE41 sampling at end of Park phase';
      dataStruct.techId = 1011;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_current(decData(15)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery voltage measured just before the end of the initial piston extension beginning Profile phase';
      dataStruct.raw = decData(16);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decData(16));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery voltage measured just before the end of the initial piston extension beginning Profile phase';
      dataStruct.techId = 1012;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_voltage(decData(16)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery current measured just before the end of the initial piston extension beginning Profile phase';
      dataStruct.raw = decData(17);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_current(decData(17));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Battery current measured just before the end of the initial piston extension beginning Profile phase';
      dataStruct.techId = 1013;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_current(decData(17)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery voltage while air pump running';
      dataStruct.raw = decData(18);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decData(18));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Battery voltage while air pump running';
         dataStruct.raw = decDataBis(id, 18);
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decDataBis(id, 18));
         dataStruct.format = '%.3f';
         dataStruct.unit = 'V';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBatVolt = [];
      for id = 1:length(idListFB)
         tabBatVolt(end+1) = sensor_2_value_for_apex_apf9_voltage(decDataBis(id, 18));
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged battery voltage while air pump running';
      dataStruct.techId = 1014;
      dataStruct.value = num2str(round(mean(tabBatVolt)*1000)/1000);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Battery current while air pump running';
      dataStruct.raw = decData(19);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_current(decData(19));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'mA';
      o_miscInfo{end+1} = dataStruct;

      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Battery current while air pump running';
         dataStruct.raw = decDataBis(id, 19);
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf9_current(decDataBis(id, 19));
         dataStruct.format = '%.3f';
         dataStruct.unit = 'mA';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBatCur = [];
      for id = 1:length(idListFB)
         tabBatCur(end+1) = sensor_2_value_for_apex_apf9_current(decDataBis(id, 19));
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged battery current while air pump running';
      dataStruct.techId = 1015;
      dataStruct.value = num2str(round(mean(tabBatCur)*1000)/1000);
      o_techData{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Air bladder pressure during transmission';
      dataStruct.value = decData(20);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Air bladder pressure during transmission';
         dataStruct.value = decDataBis(id, 20);
         dataStruct.format = '%d';
         dataStruct.unit = 'count';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBladPres = [];
      for id = 1:length(idListFB)
         tabBladPres(end+1) = decDataBis(id, 20);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged air bladder pressure during transmission';
      dataStruct.techId = 1016;
      dataStruct.value = num2str(round(mean(tabBladPres)));
      o_techData{end+1} = dataStruct;          

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'The number of 6-second pulses of the air pump required to inflate the air bladder';
      dataStruct.value = decData(21);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'The number of 6-second pulses of the air pump required to inflate the air bladder';
         dataStruct.value = decDataBis(id, 21);
         dataStruct.format = '%d';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabNum = [];
      for id = 1:length(idListFB)
         tabNum(end+1) = decDataBis(id, 21);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged number of 6-second pulses of the air pump required to inflate the air bladder';
      dataStruct.techId = 1017;
      dataStruct.value = num2str(round(mean(tabNum)));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
      dataStruct.value = decData(22);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Data msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
         dataStruct.value = decDataBis(id, 22);
         dataStruct.format = '%d';
         o_miscInfo{end+1} = dataStruct;
      end

      tabNum = [];
      for id = 1:length(idListFB)
         tabNum(end+1) = decDataBis(id, 22);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged integrated Measure of (Volt-Sec) of volume of air pumped during telemetry cycle';
      dataStruct.techId = 1018;
      dataStruct.value = num2str(round(mean(tabNum)));
      o_techData{end+1} = dataStruct;
      
   elseif (msgNum == 2)
      
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
      unixEpoch = swapbytes(uint32(decData(1)));
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
      dataStruct.techId = 1019;
      dataStruct.value = num2str(decData(3));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Number of hourly park-level PT samples';
      dataStruct.value = decData(4);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Number of hourly park-level PT samples';
      dataStruct.techId = 1020;
      dataStruct.value = num2str(decData(4));
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Mean temperature of park-level PT samples';
      dataStruct.raw = decData(5);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(5), g_decArgo_tempDef);
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Mean temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_DriftAtParkMean;
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(5), g_decArgo_tempDef);
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Mean pressure of park-level PT samples';
      dataStruct.raw = decData(6);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(6), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Mean pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_DriftAtParkMean;
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(6), g_decArgo_presDef);
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Standard deviation of temperature of park-level PT samples';
      dataStruct.raw = decData(7);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(7), g_decArgo_tempDef);
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Standard deviation of temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_DriftAtParkStd;
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(7), g_decArgo_tempDef);
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Standard deviation of pressure of park-level PT samples';
      dataStruct.raw = decData(8);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(8), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Standard deviation of pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_DriftAtParkStd;
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(8), g_decArgo_presDef);
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Minimum pressure of park-level PT samples';
      dataStruct.raw = decData(13);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(13), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Minimum pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MinPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(13), g_decArgo_presDef);
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Minimum temperature of park-level PT samples';
      dataStruct.raw = decData(9);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(9), g_decArgo_tempDef);
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Minimum temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_MinPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(9), g_decArgo_tempDef);
      o_trajData = [o_trajData; dataStruct];
      dataStruct.measCode = g_MC_MinPresInDriftAtParkSupportMeas;
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Pressure associated with Tmin of park-level PT samples';
      dataStruct.raw = decData(10);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(10), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Pressure associated with Tmin of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MinPresInDriftAtParkSupportMeas;
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(10), g_decArgo_presDef);
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Maximum pressure of park-level PT samples';
      dataStruct.raw = decData(14);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(14), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Maximum pressure of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MaxPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(14), g_decArgo_presDef);
      o_trajData = [o_trajData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Maximum temperature of park-level PT samples';
      dataStruct.raw = decData(11);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(11), g_decArgo_tempDef);
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Maximum temperature of park-level PT samples';
      dataStruct.paramName = 'TEMP';
      dataStruct.measCode = g_MC_MaxPresInDriftAtPark;
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(11), g_decArgo_tempDef);
      o_trajData = [o_trajData; dataStruct];
      dataStruct.measCode = g_MC_MaxPresInDriftAtParkSupportMeas;
      o_trajData = [o_trajData; dataStruct];

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Pressure associated with Tmax of park-level PT samples';
      dataStruct.raw = decData(12);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(12), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_traj_data_init_struct(msgRed);
      dataStruct.label = 'Pressure associated with Tmax of park-level PT samples';
      dataStruct.paramName = 'PRES';
      dataStruct.measCode = g_MC_MaxPresInDriftAtParkSupportMeas;
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(12), g_decArgo_presDef);
      o_trajData = [o_trajData; dataStruct];

   elseif (msgNum == 3)
      
      % first item bit number
      firstBit = 17;
      % item bit lengths
      tabNbBits = [1 2 1 1 2 2 2 2 2]*8;
      % get item bits
      decData = get_bits(firstBit, tabNbBits, msgData);
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('DATA MESSAGE #%d redundancy', msgNum);
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Internal vacuum at end of Park phase';
      dataStruct.raw = decData(1);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_vacuum(decData(1));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'InHg';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Internal vacuum at end of Park phase';
      dataStruct.techId = 1021;
      dataStruct.value = num2str(sensor_2_value_for_apex_apf9_vacuum(decData(1)));
      o_techData{end+1} = dataStruct;      
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Cumulative piston on time during ascent';
      dataStruct.value = decData(2);
      dataStruct.format = '%d';
      dataStruct.unit = 'second';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Cumulative piston on time during ascent';
      dataStruct.techId = 1022;
      dataStruct.value = num2str(decData(2));
      o_techData{end+1} = dataStruct;        

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Ice evasion record';
      dataStruct.raw = sprintf('%#X', decData(3));
      dataStruct.rawFormat = '%s';
      dataStruct.value = dec2bin(decData(3), 8);
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Ice evasion record';
      dataStruct.techId = 1023;
      dataStruct.value = dec2bin(decData(3), 8);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Number of mixed-layer samples taken';
      dataStruct.value = decData(4);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Number of mixed-layer samples taken';
      dataStruct.techId = 1024;
      dataStruct.value = num2str(decData(4));
      o_techData{end+1} = dataStruct;
      nbMixedlayerTempSamples = decData(4);

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Median of the mixed-layer temperature';
      dataStruct.raw = decData(5);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(5), g_decArgo_tempDef);
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;      
      
      if (nbMixedlayerTempSamples > 0)
         dataStruct = get_apx_traj_data_init_struct(msgRed);
         dataStruct.label = 'Median of the mixed-layer temperature';
         dataStruct.paramName = 'TEMP';
         dataStruct.measCode = g_MC_MedianValueInAscProf;
         dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(5), g_decArgo_tempDef);
         o_trajData = [o_trajData; dataStruct];
      end

      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Infimum of the mixed-layer median temperature since the last successful telemetry';
      dataStruct.raw = decData(6);
      dataStruct.rawFormat = '%d';
      dataStruct.value = sensor_2_value_for_apex_apf9_temperature(decData(6), g_decArgo_tempDef);
      dataStruct.format = '%.3f';
      dataStruct.unit = '°C';
      o_miscInfo{end+1} = dataStruct;      
      
      if (dataStruct.value ~= g_decArgo_tempDef)
         dataStruct = get_apx_tech_data_init_struct(msgRed);
         dataStruct.label = 'Infimum of the mixed-layer median temperature since the last successful telemetry';
         dataStruct.techId = 1025;
         dataStruct.value = num2str(sensor_2_value_for_apex_apf9_temperature(decData(6), g_decArgo_tempDef));
         o_techData{end+1} = dataStruct;
      end
      
      % data sampled at end of the park phase
      parkTemp = sensor_2_value_for_apex_apf9_temperature(decData(7), g_decArgo_tempDef);
      parkSal = sensor_2_value_for_apex_apf9_salinity(decData(8), g_decArgo_salDef);
      parkPres = sensor_2_value_for_apex_apf9_pressure(decData(9), g_decArgo_presDef);

      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      
      % convert decoder default values to netCDF fill values
      parkPres(find(parkPres == g_decArgo_presDef)) = paramPres.fillValue;
      parkTemp(find(parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      parkSal(find(parkSal == g_decArgo_salDef)) = paramSal.fillValue;
      
      % store park data
      o_parkData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_parkData.paramList = [paramPres paramTemp paramSal];
      
      % add parameter data to the data structure
      o_parkData.data = [parkPres parkTemp parkSal];
      
      % add parameter data redundancy to the profile structure
      o_parkData.dataRed = repmat(msgRed, 1, 3);

      % store profile data
      profData(1:14) = msgData(18:31);
      profReceived(1:14) = 255;
      profRedundancy(1:14) = msgRed;
      
   else
      
      dataStruct = get_apx_misc_data_init_struct('Data msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('DATA MESSAGE #%d redundancy', msgNum);
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      % store profile data
      profData(14+(msgNum-4)*29+1:14+(msgNum-4)*29+29) = msgData(3:31);
      profReceived(14+(msgNum-4)*29+1:14+(msgNum-4)*29+29) = 255;
      profRedundancy(14+(msgNum-4)*29+1:14+(msgNum-4)*29+29) = msgRed;

   end
end

% adjust the amount of received data according to profile length
if (profileLength ~= -1)
   [expectedLastMsgNum, ~] = compute_last_apx_argos_msg_number(profileLength, a_decoderId);
   % sometimes the auxiliary engineering data cause an additional message to be
   % generated (ex: 6900743 #5, #6) => we remove only messages with a low
   % reduncdancy (= 1)
   if (lastMsgNum > expectedLastMsgNum)
      idList = find(profRedundancy(end-(lastMsgNum-(expectedLastMsgNum+1))*29+1:end) > 1);
      if (isempty(idList))
         idList = length(profRedundancy) - (lastMsgNum-(expectedLastMsgNum+1))*29;
      end
      profData(max(idList)+1:end) = [];
      profReceived(max(idList)+1:end) = [];
      profRedundancy(max(idList)+1:end) = [];
   end
end

% decode profile data
nbLev = floor(length(profData)/NB_PARAM_BYTE);
if ((profileLength >= 0) && (nbLev > profileLength))
   nbLev = profileLength;
end
if (profileLength == -1)
   fprintf('DEC_WARNING: Float #%d Cycle #%d: profile length has not been received\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
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
         temp = sensor_2_value_for_apex_apf9_temperature(decData(id+1), g_decArgo_tempDef);
      else
         temp = g_decArgo_tempDef;
      end
      if ((receivedData(id+2) == 65535) && (decData(id+2) ~= 65535))
         sal = sensor_2_value_for_apex_apf9_salinity(decData(id+2), g_decArgo_salDef);
      else
         sal = g_decArgo_salDef;
      end
      if ((receivedData(id+3) == 65535) && (decData(id+3) ~= 65535))
         pres = sensor_2_value_for_apex_apf9_pressure(decData(id+3), g_decArgo_presDef);
      else
         pres = g_decArgo_presDef;
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
         profPresRaw(profileLength2+1:end, :) = [];
         profTemp(profileLength2+1:end) = [];
         profSal(profileLength2+1:end) = [];
         
         profPresRed(profileLength2+1:end) = [];
         profTempRed(profileLength2+1:end) = [];
         profSalRed(profileLength2+1:end) = [];
      end
      
      % try to identify auxiliary engineering data start byte
      % according to the depth table if the last pressure is < 6 dbar, the last
      % transmitted message has been received
      if (profPres(end) <= 6)
         % find the raw data of the last pressure value in the received data 
         profData1 = profData(1:end-1);
         profData2 = profData(2:end);
         idLastPres = find((profData1 == profPresRaw(end, 1)) & (profData2 == profPresRaw(end, 2)));
         if (~isempty(idLastPres))
            idOk = find(rem(idLastPres-5, NB_PARAM_BYTE) == 0);
            if (~isempty(idOk))
               idLastPres = idLastPres(idOk);
               firstAuxByte = idLastPres(1) + NB_PARAM_BYTE - 4;
            end
         end
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

% decode auxiliary engineering data
if (((profileLength >= 0) && (length(profData) > profileLength*NB_PARAM_BYTE)) || ...
      ((firstAuxByte ~= -1) && (length(profData) >= firstAuxByte)))
   
   if (profileLength >= 0)
      auxData = profData(nbLev*NB_PARAM_BYTE+1:end);
      msgRed = max(profRedundancy(nbLev*NB_PARAM_BYTE+1:end)); % because we have only one useful redundancy (with -1 if the first bytes have not been received, see 3901080 #145)
      auxReceived = profReceived(nbLev*NB_PARAM_BYTE+1:end);
   else
      auxData = profData(firstAuxByte:end);
      msgRed = max(profRedundancy(firstAuxByte:end)); % because we have only one useful redundancy (with -1 if the first bytes have not been received, see 3901080 #145)
      auxReceived = profReceived(firstAuxByte:end);
   end
   
   % sometimes all auxiliary engineering data are 'FF'
   if ~((length(unique(auxData)) == 1) && (unique(auxData) == 255))
      
      % first item bit number
      firstBit = 1;
      % item bit lengths
      nbPresMarkMax = get_max_number_of_pres_mark(a_decoderId);
      tabNbBits = [2 2 1 repmat(1, 1, nbPresMarkMax)]*8;
      % get item bits
      decData = get_bits(firstBit, tabNbBits, auxData);
      receivedData = get_bits(firstBit, tabNbBits, auxReceived);

      % if the message has been received once and if the number of descending
      % pressure marks is greather than nbPresMarkMax, the message is probably
      % corrupted
      if ~((msgRed < 2) && (length(decData) >= 3) && ...
            (receivedData(3) == 255) && (decData(3) ~= 255) && (decData(3) > nbPresMarkMax))
         
         dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
         dataStruct.label = 'AUXILIARY ENGINEERING DATA';
         o_auxInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
         dataStruct.label = 'Message date';
         dataStruct.value = julian_2_gregorian_dec_argo(a_sensorDate(end));
         dataStruct.format = ' %s';
         dataStruct.unit = 'UTC';
         o_auxInfo{end+1} = dataStruct;
         
         dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
         dataStruct.label = 'Message redundancy';
         dataStruct.value = msgRed;
         dataStruct.format = '%d';
         o_auxInfo{end+1} = dataStruct;
         
         nbPresMark = -1;
         presMark = [];
         for idL = 1:length(decData)
            
            if (idL == 1)
               if ((receivedData(1) == 65535) && (decData(1) ~= 65535))
                  dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
                  dataStruct.label = 'Maximum divergence between pressures (in absolute value)';
                  dataStruct.value = decData(1);
                  dataStruct.format = '%d';
                  dataStruct.unit = 'cbar';
                  o_auxInfo{end+1} = dataStruct;
                  
                  dataStruct = get_apx_tech_data_init_struct(msgRed);
                  dataStruct.label = 'Maximum divergence between pressures (in absolute value)';
                  dataStruct.techId = 1026;
                  dataStruct.value = num2str(decData(1)/10);
                  o_techData{end+1} = dataStruct;
               end
            elseif (idL == 2)
               if ((receivedData(2) == 65535) && (decData(2) ~= 65535))
                  dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
                  dataStruct.label = 'Time of profile initiation';
                  timeProfInit = twos_complement_dec_argo(decData(2), 16);
                  dataStruct.raw = timeProfInit;
                  dataStruct.rawFormat = '%d';
                  dataStruct.rawUnit = 'minute';
                  dataStruct.value = format_time_dec_argo(timeProfInit/60);
                  dataStruct.format = '%s';
                  o_auxInfo{end+1} = dataStruct;
                  
                  dataStruct = get_apx_time_data_init_struct;
                  dataStruct.label = 'tpi';
                  dataStruct.value = timeProfInit/1440;
                  o_timeInfo{end+1} = dataStruct;
                  
                  dataStruct = get_apx_tech_data_init_struct(msgRed);
                  dataStruct.label = 'Time of profile initiation';
                  dataStruct.techId = 1027;
                  dataStruct.value = num2str(twos_complement_dec_argo(decData(2), 16));
                  o_techData{end+1} = dataStruct;
               end
            elseif (idL == 3)
               if ((receivedData(3) == 255) && (decData(3) ~= 255))
                  dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
                  dataStruct.label = 'Number of descent pressure marks';
                  dataStruct.value = decData(3);
                  dataStruct.format = '%d';
                  o_auxInfo{end+1} = dataStruct;
                  
                  dataStruct = get_apx_tech_data_init_struct(msgRed);
                  dataStruct.label = 'Number of descent pressure marks';
                  dataStruct.techId = 1028;
                  dataStruct.value = num2str(decData(3));
                  o_techData{end+1} = dataStruct;
                  
                  nbPresMark = decData(3);
               end
            else
               if (receivedData(idL) == 255)
                  if (nbPresMark ~= -1)
                     if (length(presMark) < nbPresMark)
                        presMark = [presMark; decData(idL)];
                     else
                        break
                     end
                  else
                     % we store all data that may content P marks
                     presMark = [presMark; decData(idL)];
                  end
               else
                  presMark = [presMark; paramPres.fillValue];
               end
            end
         end
         if (~isempty(presMark))
            
            idlist = find(presMark ~= paramPres.fillValue);
            if (~isempty(idlist))
               presMark(max(idlist)+1:end) = [];
            end
            
            if (nbPresMark == -1)
               
               % compute the number of received P marks
               presMark(find(presMark == 255)) = [];
               nbPresMark = length(presMark);
               
               dataStruct = get_apx_misc_data_init_struct('Aux data', lastMsgNum, msgRed, a_sensorDate(end));
               dataStruct.label = 'Number of descent pressure marks (from received P marks)';
               dataStruct.value = nbPresMark;
               dataStruct.format = '%d';
               o_auxInfo{end+1} = dataStruct;
               
               dataStruct = get_apx_tech_data_init_struct(msgRed);
               dataStruct.label = 'Number of descent pressure marks';
               dataStruct.techId = 1028;
               dataStruct.value = num2str(nbPresMark);
               o_techData{end+1} = dataStruct;
            end
            
            % store pressure marks
            descPresMark = get_apx_profile_data_init_struct;
            
            % create the parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(10);
            
            % add parameter variables to the data structure
            descPresMark.paramList = paramPres;
            descPresMark.dateList = paramJuld;
            
            % add pressure marks to the data structure
            idNoDef = find(presMark ~= paramPres.fillValue);
            presMark(idNoDef) = presMark(idNoDef)*10;
            descPresMark.data = presMark;
            descPresMark.dates = ones(size(presMark))*g_decArgo_dateDef;
            descPresMark.datesAdj = ones(size(presMark))*g_decArgo_dateDef;
            descPresMark.datesStatus = repmat(g_JULD_STATUS_9, size(presMark));
            
            % add pressure marks redundancy to the data structure
            descPresMark.dataRed = repmat(msgRed, length(presMark), 1);
            
            % retrieve current cycle times
            idCycleStruct = find([o_timeData.cycleNum] == a_cycleNum);
            if (isempty(idCycleStruct))
               
               % initialize the structure to store current cycle times
               cycleTimeStruct = get_apx_cycle_time_init_struct;
               
               % store cycle times structure
               o_timeData.cycleNum = [o_timeData.cycleNum a_cycleNum];
               o_timeData.cycleTime = [o_timeData.cycleTime cycleTimeStruct];
               
               idCycleStruct = length([o_timeData.cycleTime]);
            end
            
            o_timeData.cycleTime(idCycleStruct).descPresMark = descPresMark;
            
         end
      end
   end
end

return
