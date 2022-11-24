% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd_210(a_floatParam)
%
% INPUT PARAMETERS :
%   a_floatParam : parameter packet decoded data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_210(a_floatParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


ID_OFFSET = 1;

if (size(a_floatParam, 1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d param messages in the buffer) => using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(a_floatParam, 1));
end

% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

floatParam = a_floatParam(end, :);

% modify transmitted parameter units so that they fit with the configuration
% ones

% TC02 transmitted in 10 csec => in csec in the configuration
floatParam(44+ID_OFFSET) = floatParam(44+ID_OFFSET)*10;
% TC03 transmitted in 10 csec => in csec in the configuration
floatParam(45+ID_OFFSET) = floatParam(45+ID_OFFSET)*10;
% TC04 transmitted in 1000 csec => in csec in the configuration
floatParam(46+ID_OFFSET) = floatParam(46+ID_OFFSET)*1000;
% TC22 transmitted in 1000 csec => in csec in the configuration
floatParam(64+ID_OFFSET) = floatParam(64+ID_OFFSET)*1000;

for id = 0:31
   name = sprintf('CONFIG_MC%02d_', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam(id+10+ID_OFFSET);
   end
end
for id = 0:24
   name = sprintf('CONFIG_TC%02d_', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam(id+42+ID_OFFSET);
   end
end

% update MC002, MC010 and MC011
confName = 'CONFIG_MC01_';
idPosMc01 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
nbCyclesFirstMission = newConfig(idPosMc01);
if (g_decArgo_cycleNum < nbCyclesFirstMission)

   % first mission
   % copy MC02 in MC002
   if (g_decArgo_cycleNum ~= 0)
      confName = 'CONFIG_MC02_';
      idPosMc02 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
      confName = 'CONFIG_MC002_';
      idPosMc002 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
      newConfig(idPosMc002) = newConfig(idPosMc02);
   end
   % copy MC11 in MC011
   confName = 'CONFIG_MC11_';
   idPosMc11 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosMc011) = newConfig(idPosMc11);
   % copy MC12 in MC012
   confName = 'CONFIG_MC12_';
   idPosMc12 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC012_';
   idPosMc012 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosMc012) = newConfig(idPosMc12);
else
   
   % second mission
   % update MC002
   if (g_decArgo_cycleNum ~= 0)
      if (g_decArgo_cycleNum == nbCyclesFirstMission)
         
         % compute transition cycle duration
         confName = 'CONFIG_MC02_';
         idPosMc02 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         cycleDuration1 = newConfig(idPosMc02);
         confName = 'CONFIG_MC03_';
         idPosMc03 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         cycleDuration2 = newConfig(idPosMc03);
         confName = 'CONFIG_MC05_';
         idPosMc05 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         surfTime = newConfig(idPosMc05);
         
         cycleStartDate = surfTime/24 + (nbCyclesFirstMission-1)*cycleDuration1/24;
         cycleEndDate = fix(cycleStartDate + cycleDuration2/24) + surfTime/24;
         cycleDuration = (cycleEndDate - cycleStartDate)*24;
      else
         confName = 'CONFIG_MC03_';
         idPosMc03 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         cycleDuration = newConfig(idPosMc03);
      end
      confName = 'CONFIG_MC002_';
      idPosMc002 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
      newConfig(idPosMc002) = cycleDuration;
   end

   % copy MC13 in MC011
   confName = 'CONFIG_MC13_';
   idPosMc13 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC011_';
   idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosMc011) = newConfig(idPosMc13);
   % copy MC14 in MC012
   confName = 'CONFIG_MC14_';
   idPosMc14 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   confName = 'CONFIG_MC012_';
   idPosMc012 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosMc012) = newConfig(idPosMc14);
end

% update PX00
if (g_decArgo_cycleNum > 0)
   
   % set the profile direction
   confName = 'CONFIG_MC08_';
   idPosMc08 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   descSampPeriod = newConfig(idPosMc08);
   confName = 'CONFIG_MC10_';
   idPosMc10 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   ascSampPeriod = newConfig(idPosMc10);
   if ((ascSampPeriod ~= 0) && (descSampPeriod == 0))
      direction = 1;
   elseif ((ascSampPeriod == 0) && (descSampPeriod ~= 0))
      direction = 2;
   elseif ((ascSampPeriod ~= 0) && (descSampPeriod ~= 0))
      direction = 3;
   end
   confName = 'CONFIG_PX00_';
   idPosPx00 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosPx00) = direction;
else
   
   % set the descending sampling period to 10 seconds
   confName = 'CONFIG_MC08_';
   idPosMc08 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosMc08) = 10;
   
   % set the profile direction
   confName = 'CONFIG_MC10_';
   idPosMc10 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   ascSampPeriod = newConfig(idPosMc10);
   if (ascSampPeriod == 0)
      direction = 2;
   else
      direction = 3;
   end
   confName = 'CONFIG_PX00_';
   idPosPx00 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
   newConfig(idPosPx00) = direction;
end

% update PX01 and PX02
confName = 'CONFIG_MC28_';
idPosMc28 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
if (~isnan(newConfig(idPosMc28)))
   ctdPumpSwitchOffPres = newConfig(idPosMc28);
else
   ctdPumpSwitchOffPres = 5;
   fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file => using default value (%d dbars)\n', ...
      g_decArgo_floatNum, ctdPumpSwitchOffPres);
end

confName = 'CONFIG_PX01_';
idPosPx01 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
newConfig(idPosPx01) = ctdPumpSwitchOffPres;
confName = 'CONFIG_PX02_';
idPosPx02 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
newConfig(idPosPx02) = ctdPumpSwitchOffPres + 0.5;

% manage alternated profile pressure
confName = 'CONFIG_MC15_';
idPosMc15 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
secondProfRepRate = newConfig(idPosMc15);
if (~isnan(secondProfRepRate) && (secondProfRepRate ~= 1))
   
   % check float internal cycle number VS MC15
   if ((mod(g_decArgo_cycleNum, secondProfRepRate) == 0) || (g_decArgo_cycleNum == 0)) % a_cyNum == 0 added to have the same configuration for cycle #0 and #1
      % profile pressure is MC16
      confName = 'CONFIG_MC16_';
      idPosMc16 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
      secondProfPres = newConfig(idPosMc16);
      if (~isnan(secondProfPres))
         confName = 'CONFIG_MC012_';
         idPosMc012 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         newConfig(idPosMc012) = secondProfPres;
      end
   end
end

% manage auto-increment of parking pressure
confName = 'CONFIG_TC14_';
idPosTc14 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
driftDepthIncrement = newConfig(idPosTc14);
if (~isnan(driftDepthIncrement) && (driftDepthIncrement ~= 0))
   
   % get park pressure of the previous cycle (the previous cycle is the current
   % cycle cycle since we are updating the configuration for the next cycle)
   [configNamesTmp, configValuesTmp] = get_float_config_ir_sbd(g_decArgo_cycleNum);
   if (~isempty(configNamesTmp))
      parkPresPrevCycle = get_config_value('CONFIG_MC011_', configNamesTmp, configValuesTmp);
      if (~isempty(parkPresPrevCycle))
         
         % add TC14 to park pressure of the previous cycle
         confName = 'CONFIG_MC011_';
         idPosMc011 = find(strncmp(confName, configNames, length(confName)) == 1, 1);
         newConfig(idPosMc011) = parkPresPrevCycle + driftDepthIncrement;
      end
   end
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES floatParam(end-1)];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% print_config_in_csv_file_ir_sbd('updateConfig_', 0, g_decArgo_floatConfig);

return;
