% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd_229(a_floatParam, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_floatParam : parameter packet decoded data
%   a_cycleNum   : associated cycle number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_229(a_floatParam, a_cycleNum)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% offset in cycle number (in case of reset of the float)
global g_decArgo_cycleNumOffset;

% float configuration
global g_decArgo_floatConfig;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;


% we must use the float internal cycle number to set the configuration values
% (if the float has been reset float internal cycle number differ from decoder
% cycle number)
floatInternalCycleNumber = g_decArgo_cycleNum - g_decArgo_cycleNumOffset;

floatParam1 = a_floatParam{1};
if (size(floatParam1, 1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d param messages #1 in the buffer) - using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(floatParam1, 1));
end
if (~isempty(floatParam1))
   floatParam1 = floatParam1(end, :);
end

floatParam2 = a_floatParam{2};
if (size(floatParam2, 1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d param messages #2 in the buffer) - using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(floatParam2, 1));
end
if (~isempty(floatParam2))
   floatParam2 = floatParam2(end, :);
end

if (isempty(floatParam1) && isempty(floatParam2))
   return
end

% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

if (~isempty(floatParam1))

   for id = 0:3
      if (id == 1)
         if (floatParam1(9) == 1)
            % for the configuration of the first deep cycle don't modify cycle
            % duration
            continue
         end
      end
      name = sprintf('CONFIG_PM%02d', id);
      idPos = find(strcmp(name, configNames) == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = floatParam1(id+10);
      end
   end
   for id = 5:17
      name = sprintf('CONFIG_PM%02d', id);
      idPos = find(strcmp(name, configNames) == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = floatParam1(id+9);
      end
   end
   for id = [0:15 18 21:36]
      name = sprintf('CONFIG_PT%02d', id);
      idPos = find(strcmp(name, configNames) == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = floatParam1(id+27);
      end
   end
   for id = 0:13
      name = sprintf('CONFIG_PG%02d', id);
      idPos = find(strcmp(name, configNames) == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = floatParam1(id+64);
      end
   end
   name = 'CONFIG_PY00';
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam1(78);
   end
end

if (~isempty(floatParam2))

   for id = 5:16
      name = sprintf('CONFIG_FR%02d', id);
      idPos = find(strcmp(name, configNames) == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = floatParam2(id+10);
      end
   end
   name = 'CONFIG_FR19';
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam2(29);
   end
end

% PT15 is used to manage CTD and PT21 to manage OPTODE
% if PT21 = 1 replace its value with PT15 (can be 2)
idPos = find(strcmp(configNames, 'CONFIG_PT21') == 1, 1);
if (~isempty(idPos))
   if (newConfig(idPos) == 1)
      idPos2 = find(strcmp(configNames, 'CONFIG_PT15') == 1, 1);
      newConfig(idPos) = newConfig(idPos2);
   end
end

if (~isempty(floatParam1))

   name = 'CONFIG_PX00';
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      if (floatInternalCycleNumber + 1 > g_decArgo_firstDeepCycleNumber)

         direction = 0;
         if ((floatParam1(14) == 0) && (floatParam1(16) ~= 0))
            direction = 1; % ascending
         elseif ((floatParam1(14) ~= 0) && (floatParam1(16) ~= 0))
            direction = 3; % descending and ascending
         elseif ((floatParam1(14) ~= 0) && (floatParam1(16) == 0))
            direction = 2; % descending
         end
      else
         direction = 3;
      end
      newConfig(idPos) = direction;
   end

   % for the configuration of the first deep cycle
   if (floatInternalCycleNumber + 1 == g_decArgo_firstDeepCycleNumber)

      % as the float always profiles during the first descent (at a 10 sec period)
      % when CONFIG_PM05 = 0 in the starting configuration, set it to 10 sec
      idPos = find(strcmp(configNames, 'CONFIG_PM05') == 1, 1);
      if (~isempty(idPos))
         if (newConfig(idPos) == 0)
            newConfig(idPos) = 10;
         end
      end
   end

   % manage alternated profile pressure
   if (floatParam1(43) ~= 1)

      % check cycle number VS PT16
      if (mod(floatInternalCycleNumber, floatParam1(43)) == 0)
         % profile pressure is PT17
         idPos = find(strcmp(configNames, 'CONFIG_PM09') == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatParam1(44)*10;
         end
      end
   end

   % manage auto-increment of parking pressure
   if (floatParam1(46) ~= 0)

      % get park pressure of the previous cycle
      [configNames, configValues] = get_float_config_ir_sbd(floatParam1(9)-1);
      if (~isempty(configNames))
         parkPresPrevCycle = get_config_value('CONFIG_PM08', configNames, configValues);
         if (~isempty(parkPresPrevCycle))

            % add PT19 to park pressure of the previous cycle
            idPos = find(strcmp(configNames, 'CONFIG_PM08') == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = parkPresPrevCycle + floatParam1(46);
            end
         end
      end
   end
end

% CTD and profile cut-off pressure
name = 'CONFIG_PT20';
idPos = find(strcmp(name, configNames) == 1, 1);
if (~isnan(newConfig(idPos)))
   ctdPumpSwitchOffPres = newConfig(idPos);
else
   ctdPumpSwitchOffPres = 5;
   fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file - using default value (%d dbars)\n', ...
      g_decArgo_floatNum, ctdPumpSwitchOffPres);
end
name = 'CONFIG_PX01';
idPos = find(strcmp(name, configNames) == 1, 1);
if (~isempty(idPos))
   newConfig(idPos) = ctdPumpSwitchOffPres;
end
name = 'CONFIG_PX02';
idPos = find(strcmp(name, configNames) == 1, 1);
if (~isempty(idPos))
   newConfig(idPos) = ctdPumpSwitchOffPres + 0.5;
end

% update the units of some technical parameters
for id = [0 2 3 6 12 13]
   name = sprintf('CONFIG_PT%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = newConfig(idPos)*10;
   end
end
for id = [4 32]
   name = sprintf('CONFIG_PT%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = newConfig(idPos)*1000;
   end
end

if (~isempty(floatParam1))
   updateDate = floatParam1(end-1);
elseif (~isempty(floatParam2))
   updateDate = floatParam2(end-1);
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES = [g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES a_cycleNum];
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES updateDate];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% create_csv_to_print_config_ir_sbd('updateConfig_', 0, g_decArgo_floatConfig);

return
