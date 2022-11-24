% ------------------------------------------------------------------------------
% Set the float configuration used to process the data of given profiles.
%
% SYNTAX :
%  set_float_config_ir_rudics_cts4_111_113_114(a_cyProfNum)
%
% INPUT PARAMETERS :
%   a_cyProfNum : float cycle and profile number associated to that configuration
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function set_float_config_ir_rudics_cts4_111_113_114(a_cyProfNum)

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% retrieve the configuration of the previous profile
configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
if (~isempty(g_decArgo_floatConfig.USE.CONFIG))
   idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == g_decArgo_floatConfig.USE.CONFIG(end));
else
   idConf = 1;
end
currentConfig = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);

% update the current configuration
tmpConfNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
tmpConfValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
tmpConfDate = g_decArgo_floatConfig.DYNAMIC_TMP.DATES(end);

% update the configuration for the concerned cycle and profile
cyNum = fix(a_cyProfNum/100);
profNum = a_cyProfNum - fix(a_cyProfNum/100)*100;

% update the current configuration
for id = 1:length(tmpConfNames)
   configName = tmpConfNames{id};
   idPos = find(strcmp(configName, configNames) == 1, 1);
   if (~isempty(idPos))
      currentConfig(idPos) = tmpConfValues(id);
   end
end

% for PM parameters, duplicate the information of the concerned
% profile in the PM03 to PM07 parameters
for id = 1:5
   configName = sprintf('CONFIG_PM_%d', 3+(id-1)+profNum*5);
   idL1 = find(strcmp(configName, configNames) == 1, 1);
   configName = sprintf('CONFIG_PM_%02d', 3+(id-1));
   idL2 = find(strcmp(configName, configNames) == 1, 1);
   currentConfig(idL2) = currentConfig(idL1);
end

% fill the CONFIG_PV_03 parameter
idF1 = find(strcmp('CONFIG_PV_0', configNames) == 1, 1);
if (~isnan(currentConfig(idF1)))
   idFPV03 = find(strcmp('CONFIG_PV_03', configNames) == 1, 1);
   if (currentConfig(idF1) == 1)
      idF2 = find(strcmp('CONFIG_PV_3', configNames) == 1, 1);
      currentConfig(idFPV03) = currentConfig(idF2);
   else
      for idCP = 1:currentConfig(idF1)
         confName = sprintf('CONFIG_PV_%d', 4+(idCP-1)*4);
         idFDay = find(strcmp(confName, configNames) == 1, 1);
         day = currentConfig(idFDay);
         
         confName = sprintf('CONFIG_PV_%d', 5+(idCP-1)*4);
         idFMonth = find(strcmp(confName, configNames) == 1, 1);
         month = currentConfig(idFMonth);
         
         confName = sprintf('CONFIG_PV_%d', 6+(idCP-1)*4);
         idFyear = find(strcmp(confName, configNames) == 1, 1);
         year = currentConfig(idFyear);
         
         if ~((day == 31) && (month == 12) && (year == 99))
            pvDate = gregorian_2_julian_dec_argo( ...
               sprintf('20%02d/%02d/%02d 00:00:00', year, month, day));
            if (tmpConfDate < pvDate)
               confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
               idFCyclePeriod = find(strcmp(confName, configNames) == 1, 1);
               currentConfig(idFPV03) = currentConfig(idFCyclePeriod);
               break
            end
         else
            confName = sprintf('CONFIG_PV_%d', 3+(idCP-1)*4);
            idFCyclePeriod = find(strcmp(confName, configNames) == 1, 1);
            currentConfig(idFPV03) = currentConfig(idFCyclePeriod);
            break
         end
      end
   end
end

% fill the CONFIG_PC_0_1_19 parameter
idPC0119 = find(strcmp('CONFIG_PC_0_1_19', configNames) == 1, 1);
if (~isempty(idPC0119))
   idPC014 = find(strcmp('CONFIG_PC_0_1_4', configNames) == 1, 1);
   if (~isempty(idPC014))
      
      configPC014 = currentConfig(idPC014);
      
      % retrieve the treatment type of the depth zone associated
      % to CONFIG_PC_0_1_4 pressure value
      
      % find the depth zone thresholds
      depthZoneNum = -1;
      for id = 1:4
         % zone threshold
         confParamName = sprintf('CONFIG_PC_0_0_%d', 44+id);
         idPos = find(strcmp(confParamName, configNames) == 1, 1);
         if (~isempty(idPos))
            zoneThreshold = currentConfig(idPos);
            if (configPC014 <= zoneThreshold)
               depthZoneNum = id;
               break
            end
         end
      end
      if (depthZoneNum == -1)
         depthZoneNum = 5;
      end
      
      % retrieve treatment type for this depth zone
      confParamName = sprintf('CONFIG_PC_0_0_%d', 6+(depthZoneNum-1)*9);
      idPos = find(strcmp(confParamName, configNames) == 1, 1);
      if (~isempty(idPos))
         treatType = currentConfig(idPos);
         if (treatType == 0)
            currentConfig(idPC0119) = configPC014;
         else
            currentConfig(idPC0119) = configPC014 + 0.5;
         end
      end
   end
end

% look for the current configurations in existing ones
[configNum] = config_exists_ir_rudics_sbd2( ...
   currentConfig, ...
   g_decArgo_floatConfig.DYNAMIC.NUMBER, ...
   g_decArgo_floatConfig.DYNAMIC.VALUES, ...
   g_decArgo_floatConfig.DYNAMIC.IGNORED_ID);

% if configNum == -1 the new configuration doesn't exist
% if configNum == 0 the new configuration is identical to launch
% configuration, we create a new one however so that the launch
% configuration should never be referenced in the prof and traj
% data

% anomaly-managment: check if a config already exists for this
% cycle and profile
idUsedConf = find((g_decArgo_floatConfig.USE.CYCLE == cyNum) & ...
   (g_decArgo_floatConfig.USE.PROFILE == profNum));

if (~isempty(idUsedConf))
   
   fprintf('WARNING: Float #%d: config already exists for cycle #%d and profile #%d - updating the current one\n', ...
      g_decArgo_floatNum, cyNum, profNum);
   
   if ((configNum == -1) || (configNum == 0))
      idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == ...
         g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
      g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf) = currentConfig;
   else
      g_decArgo_floatConfig.USE.CONFIG(idUsedConf) = configNum;
   end
   
else
   
   % nominal case
   if ((configNum == -1) || (configNum == 0))
      
      % create a new config
      
      g_decArgo_floatConfig.DYNAMIC.NUMBER(end+1) = ...
         max(g_decArgo_floatConfig.DYNAMIC.NUMBER) + 1;
      g_decArgo_floatConfig.DYNAMIC.VALUES(:, end+1) = currentConfig;
      configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER(end);
   end
   
   % assign the config to the cycle and profile
   g_decArgo_floatConfig.USE.CYCLE(end+1) = cyNum;
   g_decArgo_floatConfig.USE.PROFILE(end+1) = profNum;
   g_decArgo_floatConfig.USE.CYCLE_OUT(end+1) = -1;
   g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
end

% create_csv_to_print_config_ir_rudics_sbd2('setConfig_', 1, g_decArgo_floatConfig);

return
