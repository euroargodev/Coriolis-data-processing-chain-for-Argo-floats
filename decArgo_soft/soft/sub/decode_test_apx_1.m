% ------------------------------------------------------------------------------
% Decode APEX Argos test messages.
%
% SYNTAX :
%  [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
%    decode_test_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
%    a_sensorData, a_sensorDate, a_presOffsetData)
%
% INPUT PARAMETERS :
%   a_argosDataData  : Argos received message data
%   a_argosDataUsed  : Argos used message data
%   a_argosDataDate  : Argos received message dates
%   a_sensorData     : Argos selected data
%   a_sensorDate     : Argos selected data dates
%   a_presOffsetData : input pressure offset data structure
%
% OUTPUT PARAMETERS :
%   o_miscInfo       : misc info from test and data messages
%   o_metaData       : meta data
%   o_techData       : technical data
%   o_timeInfo       : time info from test and data messages
%   o_presOffsetData : updated pressure offset data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_metaData, o_techData, o_timeInfo, o_presOffsetData] = ...
   decode_test_apx_1(a_argosDataData, a_argosDataUsed, a_argosDataDate, ...
   a_sensorData, a_sensorDate, a_presOffsetData)

% output parameters initialization
o_miscInfo = [];
o_metaData = [];
o_techData = [];
o_timeInfo = [];
o_presOffsetData = a_presOffsetData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_janFirst1970InJulD;
global g_decArgo_janFirst1950InMatlab;

PRINT_FROZEN_BYTES = 0;


% process each sensor data message
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
      tabNbBits = [1 1 1 1 2 2 2 2 1 1 1 1 2 2 1 1 1 1 1 2 1 1]*8;
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
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('TEST MESSAGE #%d', msgNum);
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message redundancy';
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Firmware revision date';
      dataStruct.value = sprintf('%s%s%s', ...
         dec2hex(decData(2), 2), dec2hex(decData(3), 2), dec2hex(decData(4), 2));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Firmware revision date';
      dataStruct.metaConfigLabel = 'FIRMWARE_VERSION';
      dataStruct.metaFlag = 1;
      dataStruct.value = sprintf('%s%s%s', ...
         dec2hex(decData(2), 2), dec2hex(decData(3), 2), dec2hex(decData(4), 2));
      dataStruct.techParamCode = 'FIRMWARE_VERSION';
      dataStruct.techParamId = 961;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Float ID (Apf9 controller serial number)';
      dataStruct.value = decData(5);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Float ID (Apf9 controller serial number)';
      dataStruct.metaConfigLabel = 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY';
      dataStruct.metaFlag = 1;
      dataStruct.value = num2str(decData(5));
      dataStruct.techParamCode = 'CONTROLLER_BOARD_SERIAL_NO_PRIMA';
      dataStruct.techParamId = 1252;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Time since the start of the Mission Prelude';
      dataStruct.raw = decData(6);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'second';
      dataStruct.value = format_time_dec_argo(decData(6)/3600);
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Argos message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = '=> start of the Mission Prelude date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate - decData(6)/86400);
      dataStruct.format = ' %s';
      dataStruct.unit = 'RTC time';
      o_miscInfo{end+1} = dataStruct;
            
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Test msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = '=> start of the Mission Prelude date';
         dataStruct.value = julian_2_gregorian_dec_argo(decDateBis(id) - decDataBis(id, 6)/86400);
         dataStruct.format = ' %s';
         dataStruct.unit = 'RTC time';
         o_miscInfo{end+1} = dataStruct;
      end      
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Mission prelude start date';
      dataStruct.metaConfigLabel = 'STARTUP_DATE';
      dataStruct.metaFlag = 1;
      dataStruct.value = format_date_yyyymmddhhmiss_dec_argo(mean(decDateBis' - decDataBis(:, 6)/86400));
      dataStruct.techParamCode = 'STARTUP_DATE';
      dataStruct.techParamId = 2089;
      dataStruct.techParamValue = datestr(mean(decDateBis' - decDataBis(:, 6)/86400)+g_decArgo_janFirst1950InMatlab, 'dd/mm/yyyy HH:MM:SS');
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = '=> averaged start of the Mission Prelude date';
      dataStruct.value = julian_2_gregorian_dec_argo(mean(decDateBis' - decDataBis(:, 6)/86400));
      dataStruct.format = ' %s';
      dataStruct.unit = 'RTC time';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Float status word';
      dataStruct.value = sprintf('%#X', decData(7));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Float status word';
      dataStruct.techId = 100;
      dataStruct.value = sprintf('%#X', decData(7));
      o_techData{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Surface pressure during transmission';
      dataStruct.raw = decData(8);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decData(8), g_decArgo_presDef);
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Test msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Surface pressure during transmission';
         dataStruct.raw = decDataBis(id, 8);
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf9_pressure(decDataBis(id, 8), g_decArgo_presDef);
         dataStruct.format = '%.1f';
         dataStruct.unit = 'dbar';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabSurfPres = [];
      for id = 1:length(idListFB)
         tabSurfPres(end+1) = sensor_2_value_for_apex_apf9_pressure(decDataBis(id, 8), g_decArgo_presDef);
      end
      tabSurfPres(find(tabSurfPres == g_decArgo_presDef)) = [];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = '=> averaged surface pressure during transmission';
      dataStruct.value = round(mean(tabSurfPres)*10)/10;
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged surface pressure during transmission';
      dataStruct.techId = 101;
      dataStruct.value = num2str(round(mean(tabSurfPres)*10)/10);
      o_techData{end+1} = dataStruct;

      o_presOffsetData.cycleNum(end+1) = 0;
      o_presOffsetData.cyclePresOffset(end+1) = round(mean(tabSurfPres)*10)/10;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Internal vacuum during transmission';
      dataStruct.raw = decData(9);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_vacuum(decData(9));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'InHg';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Test msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Internal vacuum during transmission';
         dataStruct.raw = decDataBis(id, 9);
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf9_vacuum(decDataBis(id, 9));
         dataStruct.format = '%.3f';
         dataStruct.unit = 'InHg';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabVacuum = [];
      for id = 1:length(idListFB)
         tabVacuum(end+1) = sensor_2_value_for_apex_apf9_vacuum(decDataBis(id, 9));
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged internal vacuum during transmission';
      dataStruct.techId = 102;
      dataStruct.value = num2str(round(mean(tabVacuum)*1000)/1000);
      o_techData{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Air bladder pressure during transmission';
      dataStruct.value = decData(10);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Test msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Air bladder pressure during transmission';
         dataStruct.value = decDataBis(id, 10);
         dataStruct.format = '%d';
         dataStruct.unit = 'count';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBladPres = [];
      for id = 1:length(idListFB)
         tabBladPres(end+1) = decDataBis(id, 10);
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged air bladder pressure during transmission';
      dataStruct.techId = 103;
      dataStruct.value = num2str(round(mean(tabBladPres)));
      o_techData{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Quiescent battery voltage during transmission';
      dataStruct.raw = decData(11);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decData(11));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'V';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Test msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = 'Quiescent battery voltage during transmission';
         dataStruct.raw = decDataBis(id, 11);
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'count';
         dataStruct.value = sensor_2_value_for_apex_apf9_voltage(decDataBis(id, 11));
         dataStruct.format = '%.3f';
         dataStruct.unit = 'V';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabBatVolt = [];
      for id = 1:length(idListFB)
         tabBatVolt(end+1) = sensor_2_value_for_apex_apf9_voltage(decDataBis(id, 11));
      end
      dataStruct = get_apx_tech_data_init_struct(msgRed);
      dataStruct.label = 'Averaged quiescent battery voltage during transmission';
      dataStruct.techId = 104;
      dataStruct.value = num2str(round(mean(tabBatVolt)*1000)/1000);
      o_techData{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Up time';
      dataStruct.value = decData(12);
      dataStruct.format = '%d';
      dataStruct.unit = 'hour';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Up time';
      dataStruct.metaConfigLabel = 'CONFIG_UP_UpTime';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(12));
      dataStruct.techParamCode = 'MissionCfgUpTime';
      dataStruct.techParamId = 1536;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
            
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Down time';
      dataStruct.value = decData(13);
      dataStruct.format = '%d';
      dataStruct.unit = 'hour';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Down time';
      dataStruct.metaConfigLabel = 'CONFIG_DOWN_DownTime';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(13));
      dataStruct.techParamCode = 'MissionCfgDownTime';
      dataStruct.techParamId = 1537;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Park pressure';
      dataStruct.raw = decData(14);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'cbar';
      dataStruct.value = decData(14)/10;
      dataStruct.format = '%.1f';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Park pressure';
      dataStruct.metaConfigLabel = 'CONFIG_PRKP_ParkPressure';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(14)/10);
      dataStruct.techParamCode = 'PARKING_PRESSURE';
      dataStruct.techParamId = 425;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      %       dataStruct = get_apx_time_data_init_struct;
      %       dataStruct.label = 'parkingPres';
      %       dataStruct.value = decData(14)/10;
      %       o_timeInfo{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Park piston position';
      dataStruct.value = decData(15);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Park piston position';
      dataStruct.metaConfigLabel = 'CONFIG_PPP_ParkPistonPosition';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(15));
      dataStruct.techParamCode = 'MissionCfgParkPistonPosition';
      dataStruct.techParamId = 1539;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Buoyancy nudge during ascent';
      dataStruct.value = decData(16);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Buoyancy nudge during ascent';
      dataStruct.metaConfigLabel = 'CONFIG_NUDGE_AscentBuoyancyNudge';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(16));
      dataStruct.techParamCode = 'MissionCfgBuoyancyNudge';
      dataStruct.techParamId = 1540;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Internal vacuum threshold';
      dataStruct.raw = decData(17);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = sensor_2_value_for_apex_apf9_vacuum(decData(17));
      dataStruct.format = '%.3f';
      dataStruct.unit = 'InHg';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Internal vacuum threshold';
      dataStruct.metaConfigLabel = 'CONFIG_OK_OkInternalVacuum';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(17));
      dataStruct.techParamCode = 'MissionCfgOKVacuumCount';
      dataStruct.techParamId = 1541;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Ascent time-out';
      dataStruct.value = decData(18);
      dataStruct.format = '%d';
      dataStruct.unit = 'hour';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Ascent time-out';
      dataStruct.metaConfigLabel = 'CONFIG_ASCEND_AscentTimeOut';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(18));
      dataStruct.techParamCode = 'MissionCfgAscentTimeoutPeriod';
      dataStruct.techParamId = 1543;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Maximum air bladder pressure';
      dataStruct.value = decData(19);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Maximum air bladder pressure';
      dataStruct.metaConfigLabel = 'CONFIG_TBP_MaxAirBladderPressure';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(19));
      dataStruct.techParamCode = 'MissionCfgMaxAirBladderPressure';
      dataStruct.techParamId = 1544;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Profile pressure';
      dataStruct.raw = decData(20);
      dataStruct.rawFormat = '%d';
      dataStruct.rawUnit = 'count';
      dataStruct.value = decData(20)/10;
      dataStruct.format = '%d';
      dataStruct.unit = 'dbar';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Profile pressure';
      dataStruct.metaConfigLabel = 'CONFIG_TP_ProfilePressure';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(20)/10);
      dataStruct.techParamCode = 'DEEPEST_PRESSURE';
      dataStruct.techParamId = 426;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      %       dataStruct = get_apx_time_data_init_struct;
      %       dataStruct.label = 'profilePres';
      %       dataStruct.value = decData(20)/10;
      %       o_timeInfo{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Profile piston position';
      dataStruct.value = decData(21);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Profile piston position';
      dataStruct.metaConfigLabel = 'CONFIG_TPP_ProfilePistonPosition';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(21));
      dataStruct.techParamCode = 'MissionCfgTargetProfilePistonPos';
      dataStruct.techParamId = 1546;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Park and profile cycle length';
      dataStruct.value = decData(22);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Park and profile cycle length';
      dataStruct.metaConfigLabel = 'CONFIG_N_ParkAndProfileCycleLength';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(22));
      dataStruct.techParamCode = 'MissionCfgParkAndProfileCount';
      dataStruct.techParamId = 1547;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      %       dataStruct = get_apx_time_data_init_struct;
      %       dataStruct.label = 'parkAndProfileCycleLength';
      %       dataStruct.value = decData(22);
      %       o_timeInfo{end+1} = dataStruct;

   elseif (msgNum == 2)
      
      % first item bit number
      firstBit = 17;
      % item bit lengths
      tabNbBits = [1 1 1 1 1 1 1 1 1 1 1 1 1 3 2 2 4 2 2]*8;
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
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = sprintf('TEST MESSAGE #%d', msgNum);
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Message redundancy';
      dataStruct.value = msgRed;
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Firmware revision date';
      dataStruct.value = sprintf('%s%s%s', ...
         dec2hex(decData(2), 2), dec2hex(decData(3), 2), dec2hex(decData(4), 2));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      updated = 0;
      if (~isempty(o_metaData))
         idF = find([o_metaData.techParamId] == 961);
         if (~isempty(idF))
            if (o_metaData(idF).dataRed < msgRed)
               o_metaData(idF).dataRed = msgRed;
               o_metaData(idF).value = sprintf('%s%s%s', ...
                  dec2hex(decData(2), 2), dec2hex(decData(3), 2), dec2hex(decData(4), 2));
               o_metaData(idF).techParamValue = o_metaData(idF).value;
               updated = 1;
            end
         end
      end
      if (updated == 0)
         dataStruct = get_apx_meta_data_init_struct(msgRed);
         dataStruct.label = 'Firmware revision date';
         dataStruct.metaConfigLabel = 'FIRMWARE_VERSION';
         dataStruct.metaFlag = 1;
         dataStruct.value = sprintf('%s%s%s', ...
            dec2hex(decData(2), 2), dec2hex(decData(3), 2), dec2hex(decData(4), 2));
         dataStruct.techParamCode = 'FIRMWARE_VERSION';
         dataStruct.techParamId = 961;
         dataStruct.techParamValue = dataStruct.value;
         o_metaData = [o_metaData; dataStruct];
      end
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston full extension';
      dataStruct.value = decData(5);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Piston full extension';
      dataStruct.metaConfigLabel = 'CONFIG_FEXT_PistonFullExtension';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(5));
      dataStruct.techParamCode = 'FullyExtendedPistonPos';
      dataStruct.techParamId = 1548;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Piston full retraction';
      dataStruct.value = decData(6);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Piston full retraction';
      dataStruct.metaConfigLabel = 'CONFIG_FRET_PistonFullRetraction';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(6));
      dataStruct.techParamCode = 'RetractedPistonPos';
      dataStruct.techParamId = 1549;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Initial buoyancy nudge';
      dataStruct.value = decData(7);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Initial buoyancy nudge';
      dataStruct.metaConfigLabel = 'CONFIG_IBN_InitialBuoyancyNudge';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(7));
      dataStruct.techParamCode = 'InitialBuoyancyNudge';
      dataStruct.techParamId = 1550;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Compensator hyper-retraction';
      dataStruct.value = decData(8);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Compensator hyper-retraction';
      dataStruct.metaConfigLabel = 'CONFIG_CHR_CompensatorHyperRetraction';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(8));
      dataStruct.techParamCode = 'CompensatorHyperRetraction';
      dataStruct.techParamId = 2029;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Pressure-activation piston position';
      dataStruct.value = decData(9);
      dataStruct.format = '%d';
      dataStruct.unit = 'count';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Pressure-activation piston position';
      dataStruct.metaConfigLabel = 'CONFIG_PACT_PressureActivationPistonPosition';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(9));
      dataStruct.techParamCode = 'PressureActivationPistonPosition';
      dataStruct.techParamId = 2030;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Deep profile descent period';
      dataStruct.value = decData(10);
      dataStruct.format = '%d';
      dataStruct.unit = 'hour';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Deep profile descent period';
      dataStruct.metaConfigLabel = 'CONFIG_DPDP_DeepProfileDescentPeriod';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(10));
      dataStruct.techParamCode = 'DeepProfileDescentPeriod';
      dataStruct.techParamId = 1551;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      %       dataStruct = get_apx_time_data_init_struct;
      %       dataStruct.label = 'deepProfileDescentPeriod';
      %       dataStruct.value = decData(10);
      %       o_timeInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Park descent period';
      dataStruct.value = decData(11);
      dataStruct.format = '%d';
      dataStruct.unit = 'hour';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Park descent period';
      dataStruct.metaConfigLabel = 'CONFIG_PDP_ParkDescentPeriod';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(11));
      dataStruct.techParamCode = 'ParkDescentPeriod';
      dataStruct.techParamId = 1552;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Mission prelude period';
      dataStruct.value = decData(12);
      dataStruct.format = '%d';
      dataStruct.unit = 'hour';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Mission prelude period';
      dataStruct.metaConfigLabel = 'CONFIG_PRE_MissionPreludePeriod';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(12));
      dataStruct.techParamCode = 'MissionPreludePeriod';
      dataStruct.techParamId = 1553;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'ARGOS transmission repetition period';
      dataStruct.value = decData(13);
      dataStruct.format = '%d';
      dataStruct.unit = 'second';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'ARGOS transmission repetition period';
      dataStruct.metaConfigLabel = 'CONFIG_REP_ArgosTransmissionRepetitionPeriod';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(13));
      dataStruct.techParamCode = 'TRANS_REPETITION';
      dataStruct.techParamId = 388;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Argos id';
      dataStruct.value = sprintf('%#X', decData(14));
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Seabird SBE41 serial number';
      dataStruct.value = decData(15);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Seabird SBE41 serial number';
      dataStruct.metaConfigLabel = 'SENSOR_SERIAL_NO';
      dataStruct.metaFlag = 1;
      dataStruct.value = num2str(decData(15));
      dataStruct.techParamCode = 'SENSOR_SERIAL_NO';
      dataStruct.techParamId = 411;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Seabird SBE41 firmware revision';
      dataStruct.value = sprintf('%.2f', decData(16)/100);
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'RTC current date';
      unixEpoch = swapbytes(uint32(decData(17)));
      rtcTime = g_decArgo_janFirst1970InJulD + double(unixEpoch)/86400;
      dataStruct.value = julian_2_gregorian_dec_argo(rtcTime);
      dataStruct.format = ' %s';
      dataStruct.unit = 'RTC time';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Argos message date';
      dataStruct.value = julian_2_gregorian_dec_argo(msgDate);
      dataStruct.format = ' %s';
      dataStruct.unit = 'UTC';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = '=> clock offset';
      dataStruct.value = format_time_dec_argo((rtcTime - msgDate)*24);
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;
      
      for id = 2:length(idList)
         dataStruct = get_apx_misc_data_init_struct('Test msg bis', decDataNumBis(id), decDataRedBis(id), decDateBis(id));
         dataStruct.label = '=> clock offset';
         unixEpoch = swapbytes(uint32(decDataBis(id, 17)));
         rtcTime = g_decArgo_janFirst1970InJulD + double(unixEpoch)/86400;
         dataStruct.value = format_time_dec_argo((rtcTime - decDateBis(id))*24);
         dataStruct.format = '%s';
         o_miscInfo{end+1} = dataStruct;
      end
      
      tabRefDate = [];
      tabClockOffset = [];
      for id = 1:length(idListFB)
         unixEpoch = swapbytes(uint32(decDataBis(id, 17)));
         rtcTime = g_decArgo_janFirst1970InJulD + double(unixEpoch)/86400;
         tabRefDate = [tabRefDate decDateBis(id)];
         tabClockOffset = [tabClockOffset (rtcTime - decDateBis(id))];
      end
      
      dataStruct = get_apx_time_data_init_struct;
      dataStruct.label = 'clockOffsetRefDate';
      dataStruct.value = mean(tabRefDate);
      o_timeInfo{end+1} = dataStruct;

      dataStruct = get_apx_time_data_init_struct;
      dataStruct.label = 'clockOffset';
      dataStruct.value = mean(tabClockOffset);
      o_timeInfo{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = '=> averaged clock offset';
      dataStruct.value = format_time_dec_argo(mean(tabClockOffset)*24);
      dataStruct.format = '%s';
      o_miscInfo{end+1} = dataStruct;

      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Minutes past midnight when down-time will expire';
      if (decData(18) ~= hex2dec('fffe'))
         dataStruct.raw = decData(18);
         dataStruct.rawFormat = '%d';
         dataStruct.rawUnit = 'minutes';
         dataStruct.value = format_time_dec_argo(decData(18)/60);
         dataStruct.format = '%s';
      else
         dataStruct.raw = decData(18);
         dataStruct.rawFormat = '%d';
         dataStruct.value = 'disabled';
         dataStruct.format = '%s';
      end
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Minutes past midnight when down-time will expire';
      dataStruct.metaConfigLabel = 'CONFIG_TOD_DownTimeExpiryTimeOfDay';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(18));
      dataStruct.techParamCode = 'PRCFG_TimeOfDay';
      dataStruct.techParamId = 1019;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
      dataStruct = get_apx_misc_data_init_struct('Test msg', msgNum, msgRed, msgDate);
      dataStruct.label = 'Log verbosity';
      dataStruct.value = decData(19);
      dataStruct.format = '%d';
      o_miscInfo{end+1} = dataStruct;
      
      dataStruct = get_apx_meta_data_init_struct(msgRed);
      dataStruct.label = 'Log verbosity';
      dataStruct.metaConfigLabel = 'CONFIG_DEBUG_LogVerbosity';
      dataStruct.configFlag = 1;
      dataStruct.value = num2str(decData(19));
      dataStruct.techParamCode = 'PRCFG_Verbosity';
      dataStruct.techParamId = 1021;
      dataStruct.techParamValue = dataStruct.value;
      o_metaData = [o_metaData; dataStruct];
      
   else
      fprintf('WARNING: Float #%d Cycle #%d: message #%d is not allowed as test message => not considered\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, msgNum);
   end
end

return;
