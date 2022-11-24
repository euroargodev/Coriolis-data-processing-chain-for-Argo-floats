% ------------------------------------------------------------------------------
% Update configuration information and set the float configuration used to
% process the data of given cycle.
%
% SYNTAX :
%  set_float_config_argos(a_cyNum, a_assignCycleToConf)
%
% INPUT PARAMETERS :
%   a_cyNum             : concerned cycle number
%   a_assignCycleToConf : 1 if the cycle number should be assigned to the
%                         configuration, 0 otherwise
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function set_float_config_argos(a_cyNum, a_assignCycleToConf)

% float configuration
global g_decArgo_floatConfig;


% retrieve the launch configuration
[configNames, currentConfig] = get_float_config_argos_1(0);

% update the launch configuration for the current cycle
nbCyclesFirstMission = get_config_value('CONFIG_MC1_', configNames, currentConfig);
if (a_cyNum < nbCyclesFirstMission + 1)
   
   % first mission
   
   cycleDuration = get_config_value('CONFIG_MC2_', configNames, currentConfig);
   confName = 'CONFIG_MC002_';
   idPosMc002 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc002) = cycleDuration;
   driftDepth = get_config_value('CONFIG_MC10_', configNames, currentConfig);
   confName = 'CONFIG_MC010_';
   idPosMc010 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc010) = driftDepth;
   profDepth = get_config_value('CONFIG_MC11_', configNames, currentConfig);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc011) = profDepth;
   
elseif (a_cyNum >= nbCyclesFirstMission + 1)
   
   % second mission
   
   if (a_cyNum > nbCyclesFirstMission + 1)
      cycleDuration = get_config_value('CONFIG_MC3_', configNames, currentConfig);
   else
      % transition cycle
      cycleDuration1 = get_config_value('CONFIG_MC2_', configNames, currentConfig);
      cycleDuration2 = get_config_value('CONFIG_MC3_', configNames, currentConfig);
      surfTime = get_config_value('CONFIG_MC5_', configNames, currentConfig);
      
      cycleStartDate = surfTime/24 + (nbCyclesFirstMission-1)*cycleDuration1/24;
      cycleEndDate = fix(cycleStartDate + cycleDuration2/24) + surfTime/24;
      cycleDuration = (cycleEndDate - cycleStartDate)*24;
   end
   confName = 'CONFIG_MC002_';
   idPosMc002 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc002) = cycleDuration;
   
   driftDepth = get_config_value('CONFIG_MC12_', configNames, currentConfig);
   confName = 'CONFIG_MC010_';
   idPosMc010 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc010) = driftDepth;
   profDepth = get_config_value('CONFIG_MC13_', configNames, currentConfig);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc011) = profDepth;
end

if (a_cyNum > 1)
   
   % set the profile direction
   descSampPeriod = get_config_value('CONFIG_MC7_', configNames, currentConfig);
   ascSampPeriod = get_config_value('CONFIG_MC9_', configNames, currentConfig);
   if ((ascSampPeriod ~= 0) && (descSampPeriod == 0))
      direction = 1;
   elseif ((ascSampPeriod == 0) && (descSampPeriod ~= 0))
      direction = 2;
   elseif ((ascSampPeriod ~= 0) && (descSampPeriod ~= 0))
      direction = 3;
   end
   confName = 'CONFIG_PX0_';
   idPosPx0 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosPx0) = direction;
else
   
   % set the descending sampling period to 10 seconds
   descSampPeriod = get_config_value('CONFIG_MC7_', configNames, currentConfig);
   if (isempty(descSampPeriod) || (descSampPeriod == 0))
      confName = 'CONFIG_MC7_';
      idPosMc7 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
      currentConfig(idPosMc7) = 10;
   end
   
   % set the profile direction
   ascSampPeriod = get_config_value('CONFIG_MC9_', configNames, currentConfig);
   if (ascSampPeriod == 0)
      direction = 2;
   else
      direction = 3;
   end
   confName = 'CONFIG_PX0_';
   idPosPx0 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosPx0) = direction;
end

% manage alternated profile pressure
secondProfRepRate = get_config_value('CONFIG_TC14_', configNames, currentConfig);
if (~isempty(secondProfRepRate) && (secondProfRepRate ~= 1))
   
   % check float internal cycle number VS TC14
   if ((mod(a_cyNum-1, secondProfRepRate) == 0) || (a_cyNum == 0)) % a_cyNum == 0 added to have the same configuration for cycle #0 and #1
      % profile pressure is TC15
      secondProfPres = get_config_value('CONFIG_TC15_', configNames, currentConfig);
      if (~isempty(secondProfPres))
         confName = 'CONFIG_MC011_';
         idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         currentConfig(idPosMc011) = secondProfPres;
      end
   end
end

% manage auto-increment of parking pressure
driftDepthIncrement = get_config_value('CONFIG_TC17_', configNames, currentConfig);
if (~isempty(driftDepthIncrement) && (driftDepthIncrement ~= 0))
   
   confName = 'CONFIG_MC010_';
   idPosMc010 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   currentConfig(idPosMc010) = currentConfig(idPosMc010) + (a_cyNum-1)*driftDepthIncrement;
end

% look for the current configurations in existing ones
[configNum] = config_exists_ir_sbd_argos( ...
   currentConfig, ...
   g_decArgo_floatConfig.NUMBER, ...
   g_decArgo_floatConfig.VALUES);

% if configNum == -1 the new configuration doesn't exist
% if configNum == 0 the new configuration is identical to launch configuration,
% we create a new one however so that the launch configuration should never be
% referenced in the prof and traj data

if ((configNum == -1) || (configNum == 0))
   
   % create a new config
   
   % we add the new configuration
   g_decArgo_floatConfig.NUMBER(end+1) = ...
      max(g_decArgo_floatConfig.NUMBER) + 1;
   g_decArgo_floatConfig.VALUES(:, end+1) = currentConfig;
   configNum = g_decArgo_floatConfig.NUMBER(end);
end

% assign the config to the current cycle
if (a_assignCycleToConf == 1)
   g_decArgo_floatConfig.USE.CYCLE(end+1) = a_cyNum;
   g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
end
     
% print_config_in_csv_file_ir_sbd('setConfig_', 3, g_decArgo_floatConfig);

return;
