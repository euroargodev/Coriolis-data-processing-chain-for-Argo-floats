% ------------------------------------------------------------------------------
% Update float configuration with current mission and/or sample configuration
% data.
%
% SYNTAX :
%  update_float_config_apx_apf11_ir(a_missionCfg, a_sampleCfg)
%
% INPUT PARAMETERS :
%   a_missionCfg : input mission configuration data from system_log file
%   a_sampleCfg  : input sample configuration data from system_log file
%
% OUTPUT PARAMETERS :.
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_apx_apf11_ir(a_missionCfg, a_sampleCfg)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


% create new config
configNames = g_decArgo_floatConfig.NAMES;
newConfigValues = g_decArgo_floatConfig.VALUES(:, end);

% consider mission configuration parameters
if (~isempty(a_missionCfg))
   % select the last mission set
   [~, idMis] = max([a_missionCfg{:, 1}]);
   misStruct = a_missionCfg{idMis, 2};
   confParam = fieldnames(misStruct);
   for id = 1:length(confParam)
      floatConfigLabel = confParam{id};
      floatConfigValue = misStruct.(floatConfigLabel);
      [configName, configValue] = get_config(floatConfigLabel, floatConfigValue);
      if (~isempty(configName))
         idF = find(strcmp(configName, configNames));
         if (~isempty(idF))
            newConfigValues(idF) = configValue;
         else
            fprintf('WARNING: Float #%d Cycle #%d: Not managed configuration label ''%s''\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               configName);
         end
      end
   end
end

% consider sampling configuration parameters
if (~isempty(a_sampleCfg))
   
   % if new sampling configuration parameters are encountered
   addConfigNames = [];
   addConfigValues = [];

   % select the last sample set
   [~, idMis] = max([a_sampleCfg{:, 1}]);
   sampleConfData = a_sampleCfg{idMis, 2};
   [configSampName, configSampVal] = create_sampling_configuration(sampleConfData);
   for id = 1:length(configSampName)
      configName = configSampName{id};
      configValue = str2double(configSampVal{id});
      idF = find(strcmp(configName, configNames));
      if (~isempty(idF))
         newConfigValues(idF) = configValue;
      else
         addConfigNames{end+1} = configName;
         addConfigValues(end+1) = configValue;
      end
   end
   
   % update the number of configuration parameters
   if (~isempty(addConfigNames))
      configNames = g_decArgo_floatConfig.NAMES;
      configValues = g_decArgo_floatConfig.VALUES;
      configNames = [configNames; addConfigNames'];
      configValues = [configValues; nan(length(addConfigNames), size(configValues, 2))];
      
      g_decArgo_floatConfig.NAMES = configNames;
      g_decArgo_floatConfig.VALUES = configValues;
      
      newConfigValues = [newConfigValues; addConfigValues'];
   end
end

% update configuration parameters that depend on other ones

% compute CONFIG_CT_CycleTime
idF = find(strcmp(configNames, 'CONFIG_DPF_DeepProfileFirstFloat'));
if ((newConfigValues(idF) == 1) && (g_decArgo_cycleNum == 1))
   % first cycle of a DPF float
   idF1 = find(strcmp(configNames, 'CONFIG_CT_CycleTime'));
   idF2 = find(strcmp(configNames, 'CONFIG_UP_UpTime'));
   idF3 = find(strcmp(configNames, 'CONFIG_TP_ProfilePressure'));
   if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
      % estimated descent speed : 4 cm/s (determined from Argos data)
      % park phase : 5 minutes
      newConfigValues(idF1) = newConfigValues(idF3)*100/(4*60) + 5 + newConfigValues(idF2);
      %          fprintf('DPF cycle duration : %.1f minutes\n', configValues(idF1));
   end
else
   idF1 = find(strcmp(configNames, 'CONFIG_CT_CycleTime'));
   idF2 = find(strcmp(configNames, 'CONFIG_DOWN_DownTime'));
   idF3 = find(strcmp(configNames, 'CONFIG_UP_UpTime'));
   if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
      newConfigValues(idF1) = newConfigValues(idF2) + newConfigValues(idF3);
   end
end

% is it always profiling from the same depth ?
idF = find(strcmp(configNames, 'CONFIG_N_ParkAndProfileCycleLength'));
parkAndProfileCycleLength = newConfigValues(idF);
if (parkAndProfileCycleLength ~= 1)
   idF1 = find(strcmp(configNames, 'CONFIG_PRKP_ParkPressure'));
   idF2 = find(strcmp(configNames, 'CONFIG_TP_ProfilePressure'));
   parkPres = newConfigValues(idF1);
   if (~isnan(parkPres))
      if ((g_decArgo_cycleNum > 1) && (rem(g_decArgo_cycleNum, parkAndProfileCycleLength) ~= 0))
         newConfigValues(idF2) = parkPres;
      end
   end
end

% look for the current configurations in existing ones
[newConfigNum] = config_exists_ir_sbd_argos( ...
   newConfigValues, ...
   g_decArgo_floatConfig.NUMBER, ...
   g_decArgo_floatConfig.VALUES);

% if configNum == -1 the new configuration doesn't exist
% if configNum == 0 the new configuration is identical to launch configuration,
% we create a new one however so that the launch configuration should never be
% referenced in the prof and traj data
   
if ((newConfigNum == -1) || (newConfigNum == 0))
   
   if (g_decArgo_cycleNum > 0)
      
      % we add the new configuration
      g_decArgo_floatConfig.NUMBER(end+1) = ...
         max(g_decArgo_floatConfig.NUMBER) + 1;
      g_decArgo_floatConfig.VALUES(:, end+1) = newConfigValues;
      newConfigNum = g_decArgo_floatConfig.NUMBER(end);
   else
      
      % for cycle #0
      % if newConfigNum == -1 we replace the launch configuration by the new one
      % configNum == 0 nothing to do (prelude configuration identical to launch
      % one)
      if (newConfigNum == -1)
         if (size(g_decArgo_floatConfig.VALUES, 2) == 1)
            g_decArgo_floatConfig.VALUES(:, 1) = newConfigValues;
         else
            fprintf('ERROR: Float #%d Cycle #%d: Configuration issue (when trying to update launch configuration (inconsistent size of existing configuration)\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum);
         end
      end
   end
end
   
% assign the config to the cycle
if (g_decArgo_cycleNum > 0)
   g_decArgo_floatConfig.USE.CYCLE(end+1) = g_decArgo_cycleNum;
   g_decArgo_floatConfig.USE.CONFIG(end+1) = newConfigNum;
end
     
% create_csv_to_print_config_apx_apf11_ir('setConfig_', g_decArgo_floatConfig);

return;

% ------------------------------------------------------------------------------
% Retrive configuration name and value to store for a given configuration
% parameter.
%
% SYNTAX :
%  [o_configName, o_configValue] = get_config(a_floatConfLabel, a_floatConfValue)
%
% INPUT PARAMETERS :
%   a_configInfoLabel : float configuration label
%   a_configInfoValue : float configuration value
%
% OUTPUT PARAMETERS :
%   o_configName  : decoder configuration parameter name
%   o_configValue : decoder configuration parameter value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configName, o_configValue] = get_config(a_floatConfLabel, a_floatConfValue)

% output parameters initialization
o_configName = [];
o_configValue = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


switch (a_floatConfLabel)
   case 'ActivateRecoveryMode'
      o_configName = 'CONFIG_ARM_ActivateRecoveryModeFlag';
      if (strcmpi(a_floatConfValue, 'off'))
         o_configValue = 0;
      else
         o_configValue = 1;
      end
   case 'AscentRate'
      o_configName = 'CONFIG_AR_AscentRate';
      o_configValue = str2double(a_floatConfValue);
   case 'AscentStartTimes'
      o_configName = 'CONFIG_TOD_DownTimeExpiryTimeOfDay';
      o_configValue = unique(str2double(a_floatConfValue));
   case 'AscentTimeout'
      o_configName = 'CONFIG_ASCEND_AscentTimeOut';
      o_configValue = str2double(a_floatConfValue);
   case 'AscentTimerInterval'
      o_configName = 'CONFIG_ATI_AscentTimerInterval';
      o_configValue = str2double(a_floatConfValue);
   case 'BuoyancyNudge'
      o_configName = 'CONFIG_NUDGE_AscentBuoyancyNudge';
      o_configValue = str2double(a_floatConfValue);
   case 'DeepDescentCount'
      o_configName = 'CONFIG_TPP_ProfilePistonPosition';
      o_configValue = str2double(a_floatConfValue);
   case 'DeepDescentPressure'
      o_configName = 'CONFIG_TP_ProfilePressure';
      o_configValue = str2double(a_floatConfValue);
   case 'DeepDescentTimeout'
      o_configName = 'CONFIG_DPDP_DeepProfileDescentPeriod';
      o_configValue = str2double(a_floatConfValue);
   case 'DeepDescentTimerInterval'
      o_configName = 'CONFIG_DDTI_DeepDescentTimerInterval';
      o_configValue = str2double(a_floatConfValue);
   case 'DeepProfileFirst'
      o_configName = 'CONFIG_DPF_DeepProfileFirstFloat';
      if (strcmpi(a_floatConfValue, 'off'))
         o_configValue = 0;
      else
         o_configValue = 1;
      end
   case 'DownTime'
      o_configName = 'CONFIG_DOWN_DownTime';
      o_configValue = str2double(a_floatConfValue);
   case 'EmergencyTimerInterval'
      o_configName = 'CONFIG_ETI_EmergencyTimerInterval';
      o_configValue = str2double(a_floatConfValue);
   case 'HyperRetractCount'
      o_configName = 'CONFIG_HRC_HyperRetractCount';
      o_configValue = str2double(a_floatConfValue);
   case 'HyperRetractPressure'
      o_configName = 'CONFIG_HRP_HyperRetractPressure';
      o_configValue = str2double(a_floatConfValue);
   case 'IceBreakupDays'
      o_configName = 'CONFIG_IBD_IceBreakupDays';
      o_configValue = str2double(a_floatConfValue);
   case 'IceCriticalT'
      o_configName = 'CONFIG_IMLT_IceDetectionTemperature';
      o_configValue = str2double(a_floatConfValue);
   case 'IceDetectionP'
      o_configName = 'CONFIG_IDP_IceDetectionMaxPres';
      o_configValue = str2double(a_floatConfValue);
   case 'IceEvasionP'
      o_configName = 'CONFIG_IEP_IceEvasionPressure';
      o_configValue = str2double(a_floatConfValue);
   case 'IceMonths'
      o_configName = 'CONFIG_ICEM_IceDetectionMask';
      o_configValue = hex2dec(a_floatConfValue);
   case 'IdleTimerInterval'
      o_configName = 'CONFIG_ITI_IdleTimerInterval';
      o_configValue = str2double(a_floatConfValue);
   case 'InitialBuoyancyNudge'
      o_configName = 'CONFIG_IBN_InitialBuoyancyNudge';
      o_configValue = str2double(a_floatConfValue);
   case 'LeakDetect'
      o_configName = 'CONFIG_LD_LeakDetectFlag';
      if (strcmpi(a_floatConfValue, 'off'))
         o_configValue = 0;
      else
         o_configValue = 1;
      end
   case 'LogVerbosity'
      o_configName = 'CONFIG_DEBUG_LogVerbosity';
      o_configValue = str2double(a_floatConfValue);
   case 'MActivationCount'
      o_configName = 'CONFIG_PACT_PressureActivationPistonPosition';
      o_configValue = str2double(a_floatConfValue);
   case 'MActivationPressure'
      o_configName = 'CONFIG_MAP_MissionActivationPressure';
      o_configValue = str2double(a_floatConfValue);
   case 'MinBuoyancyCount'
      o_configName = 'CONFIG_MBC_MinBuoyancyCount';
      o_configValue = str2double(a_floatConfValue);
   case 'MinVacuum'
      o_configName = 'CONFIG_OK_OkInternalVacuum';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkBuoyancyNudge'
      o_configName = 'CONFIG_PBN_ParkBuoyancyNudge';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkDeadBand'
      o_configName = 'CONFIG_PDB_ParkDeadBand';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkDescentCount'
      o_configName = 'CONFIG_PPP_ParkPistonPosition';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkDescentTimeout'
      o_configName = 'CONFIG_PDP_ParkDescentPeriod';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkDescentTimerInterval'
      o_configName = 'CONFIG_PDTI_ParkDescentTimerInterval';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkPressure'
      o_configName = 'CONFIG_PRKP_ParkPressure';
      o_configValue = str2double(a_floatConfValue);
   case 'ParkTimerInterval'
      o_configName = 'CONFIG_PTI_ParkTimerInterval';
      o_configValue = str2double(a_floatConfValue);
   case 'PnPCycleLen'
      o_configName = 'CONFIG_N_ParkAndProfileCycleLength';
      o_configValue = str2double(a_floatConfValue);
   case 'PreludeSelfTest'
      o_configName = 'CONFIG_PST_PreludeSelfTestFlag';
      if (strcmpi(a_floatConfValue, 'off'))
         o_configValue = 0;
      else
         o_configValue = 1;
      end
   case 'PreludeTime'
      o_configName = 'CONFIG_PRE_MissionPreludePeriod';
      o_configValue = str2double(a_floatConfValue);
   case 'SurfacePressure'
      o_configName = 'CONFIG_SPSPC_SurfacePressureStopPumpedCtd';
      o_configValue = str2double(a_floatConfValue);
   case 'TelemetryInterval'
      o_configName = 'CONFIG_REP_ArgosTransmissionRepetitionPeriod';
      o_configValue = str2double(a_floatConfValue);
   case 'UpTime'
      o_configName = 'CONFIG_UP_UpTime';
      o_configValue = str2double(a_floatConfValue);
   case 'VitalsMask'
      o_configName = 'CONFIG_VM_VitalsMask';
      o_configValue = hex2dec(a_floatConfValue);
   case 'CheckSum'
      % not considered
   case 'float_id'
      % not considered
   case 'air_bladder_max'
      o_configName = 'CONFIG_TBP_MaxAirBladderPressure';
      o_configValue = str2double(a_floatConfValue);
   case 'buoyancy_pump_min'
      o_configName = 'CONFIG_FRET_PistonFullRetraction';
      o_configValue = str2double(a_floatConfValue);
   case 'buoyancy_pump_max'
      o_configName = 'CONFIG_FRET_PistonFullRetraction';
      o_configValue = str2double(a_floatConfValue);
   case 'argos_decimal_id'
      % not considered
   case 'argos_hex_id'
      % not considered
   case 'argos_frequency'
      % not considered
      
   otherwise
      fprintf('WARNING: Float #%d Cycle #%d: Not managed float configuration label ''%s''\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_floatConfLabel);
end

return;
