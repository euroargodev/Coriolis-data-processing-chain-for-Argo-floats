% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics engineering data.
%
% SYNTAX :
%  [o_techInfo, o_techData, o_pMarkData, o_parkData, o_surfData] = ...
%    process_apx_ir_engineering_data(a_engData, a_engRecordNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_engData      : input engineering data
%   a_engRecordNum : number of the record
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_techInfo  : technical misc information
%   o_techData  : technical data
%   o_pMarkData : descending pressure marks data (from engineering data)
%   o_parkData  : park measurement data (from engineering data)
%   o_surfData  : surf measurement data (from engineering data)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techInfo, o_techData, o_pMarkData, o_parkData, o_surfData] = ...
   process_apx_ir_engineering_data(a_engData, a_engRecordNum, a_decoderId)

% output parameters initialization
o_techInfo = [];
o_techData = [];
o_pMarkData = [];
o_parkData = [];
o_surfData = [];


if (isempty(a_engData))
   return
end

fields = fieldnames(a_engData);
for id = 1:length(fields)
   if (~isempty(a_engData.(fields{id})))
      [techInfo, techData, pMarkData, parkData, surfData] = ...
         process_eng(fields{id}, a_engData.(fields{id}), a_engRecordNum, a_decoderId);
      if (~isempty(techInfo))
         o_techInfo{end+1} = techInfo;
      end
      if (~isempty(techData))
         o_techData{end+1} = techData;
      end
      if (~isempty(pMarkData))
         o_pMarkData{end+1} = pMarkData;
      end
      if (~isempty(parkData))
         o_parkData{end+1} = parkData;
      end
      if (~isempty(surfData))
         o_surfData{end+1} = surfData;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Parse and process Apex Iridium Rudics engineering data.
%
% SYNTAX :
%  [o_techInfo, o_techData, o_pMarkData, o_parkData, o_surfData] = ...
%    process_eng(a_engName, a_engValue, a_engRecordNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_engName      : input engineering parameter name
%   a_engValue     : input engineering parameter value
%   a_engRecordNum : number of the record
%   a_decoderId    : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_techInfo  : technical misc information
%   o_techData  : technical data
%   o_pMarkData : descending pressure marks data (from engineering data)
%   o_parkData  : park measurement data (from engineering data)
%   o_surfData  : surf measurement data (from engineering data)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techInfo, o_techData, o_pMarkData, o_parkData, o_surfData] = ...
   process_eng(a_engName, a_engValue, a_engRecordNum, a_decoderId)

% output parameters initialization
o_techInfo = [];
o_techData = [];
o_pMarkData = [];
o_parkData = [];
o_surfData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_engName)
   case 'ActiveBallastAdjustments'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1001;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'AirBladderPressure'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1002;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'AirPumpAmps'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_current(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'mA';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1003;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'AirPumpVolts'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_voltage(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'V';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1004;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Apf9iFwRev'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
   case 'ApfId'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
   case 'BuoyancyPumpAmps'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_current(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'mA';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1005;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'BuoyancyPumpOnTime'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'second';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1006;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'BuoyancyPumpVolts'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_voltage(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'V';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1007;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'CurrentBuoyancyPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1009;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'CurrentPistonPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1008;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'DeepProfileBuoyancyPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1011;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'DeepProfilePistonPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1010;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'FlashErrorsCorrectable'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1012;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'FlashErrorsUncorrectable'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1013;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'FlbbStatus'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1014;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'FloatId'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
   case 'FwRev'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
   case 'GpsFixTime'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'second';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1015;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'IceEvasionRecord'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = dec2bin(hex2dec(a_engValue(3:end)), 8);
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1016;
      o_techData.value = o_techInfo.value;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'IceMLMedianT'
      valueStr = a_engValue;
      if (valueStr(end) == 'C')
         valueStr = valueStr(1:end-1);
      end
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = valueStr;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'degree_Celsius';
   case 'IceMLSample'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1017;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'NpfFwRev'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
   case 'ObsIndex'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1018;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'OptodeAmps'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_current(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'mA';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1019;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'OptodeVolts'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_voltage(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'V';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1020;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'ParkBuoyancyPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1021;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'ParkDescentPCnt'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1022;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'ParkDescentP'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = 'ParkDescentPCnt';
      o_techInfo.value = num2str(length(a_engValue));
      o_techInfo.format = '%s';

      % process P marks
      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
            
      % store P marks data
      o_pMarkData = get_apx_profile_data_init_struct;
      
      % add parameter variables to the data structure
      o_pMarkData.paramList = paramPres;
      
      % add parameter data to the data structure
      o_pMarkData.data = cellfun(@str2num, a_engValue)'*10;      
   case 'ParkObs'
      o_parkData = process_apx_ir_rudics_single_obs(a_engValue, a_decoderId, 0);
   case 'ParkPistonPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1023;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'ProfileId'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
   case 'QuiescentAmps'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_current(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'mA';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1024;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'QuiescentVolts'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_voltage(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'V';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1025;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'RtcSkew'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'second';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1026;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Sbe41cpAmps'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_current(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'mA';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1027;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Sbe41cpStatus'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1028;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Sbe41cpVolts'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_voltage(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'V';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1029;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Sbe63Amps'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_current(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'mA';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1030;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Sbe63Volts'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_voltage(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'V';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1031;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'status'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1032;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'SurfaceBuoyancyPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1034;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'SurfaceObs'
      o_surfData = process_apx_ir_rudics_single_obs(a_engValue, a_decoderId, 1);
   case 'SurfacePistonPosition'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'count';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1033;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'SurfacePressure'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.value = a_engValue;
      o_techInfo.format = '%s';
      o_techInfo.unit = 'dbar';
      
      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1035;
      o_techData.value = a_engValue;
      o_techData.cyNum = g_decArgo_cycleNum;
   case 'Vacuum'
      o_techInfo = get_apx_misc_data_init_struct('Tech', a_engRecordNum, [], []);
      o_techInfo.label = a_engName;
      o_techInfo.raw = a_engValue;
      o_techInfo.rawFormat = '%s';
      o_techInfo.rawUnit = 'count';
      o_techInfo.value = sensor_2_value_for_apex_apf9_vacuum(str2num(a_engValue));
      o_techInfo.format = '%.3f';
      o_techInfo.unit = 'InHg';

      o_techData = get_apx_tech_data_init_struct(1);
      o_techData.label = a_engName;
      o_techData.techId = 1036;
      o_techData.value = sprintf('%.3f', o_techInfo.value);
      o_techData.cyNum = g_decArgo_cycleNum;

   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Not managed engineering information ''%s''\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_engName);
end
   
return
