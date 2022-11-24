% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd_202(a_floatParam)
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
%   12/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_202(a_floatParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;


if (size(a_floatParam, 1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d param messages in the buffer) - using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(a_floatParam, 1));
end

% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

floatParam = a_floatParam(end, :);

for id = 0:3
   name = sprintf('CONFIG_PM%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam(id+9);
   end
end
for id = 5:17
   name = sprintf('CONFIG_PM%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam(id+8);
   end
end
for id = [0:15 18 20:25]
   name = sprintf('CONFIG_PT%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = floatParam(id+26);
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
name = 'CONFIG_PX00';
idPos = find(strcmp(name, configNames) == 1, 1);
if (~isempty(idPos))
   if (floatParam(8) > g_decArgo_firstDeepCycleNumber)
      
      direction = 0;
      if ((floatParam(13) == 0) && (floatParam(15) ~= 0))
         direction = 1; % ascending
      elseif ((floatParam(13) ~= 0) && (floatParam(15) ~= 0))
         direction = 3; % descending and ascending
      elseif ((floatParam(13) ~= 0) && (floatParam(15) == 0))
         direction = 2; % descending
      end
   else
      direction = 3;
   end
   newConfig(idPos) = direction;
end

% for the configuration of the first deep cycle
if (floatParam(8) == g_decArgo_firstDeepCycleNumber)
   
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
if (floatParam(42) ~= 1)
   
   % check cycle number VS PT16
   if (mod(floatParam(8), floatParam(42)) == 0)
      % profile pressure is PT17
      idPos = find(strcmp(configNames, 'CONFIG_PM09') == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = floatParam(43)*10;
      end
   end
end

% manage auto-increment of parking pressure
if (floatParam(45) ~= 0)
   
   % get park pressure of the previous cycle
   [configNames, configValues] = get_float_config_ir_sbd(floatParam(8)-1);
   if (~isempty(configNames))
      parkPresPrevCycle = get_config_value('CONFIG_PM08', configNames, configValues);
      if (~isempty(parkPresPrevCycle))
         
         % add PT19 to park pressure of the previous cycle
         idPos = find(strcmp(configNames, 'CONFIG_PM08') == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = parkPresPrevCycle + floatParam(45);
         end
      end
   end
end

% update the units of some technical parameters
for id = [0 2 3 6 12 13]
   name = sprintf('CONFIG_PT%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = newConfig(idPos)*10;
   end
end
for id = [4]
   name = sprintf('CONFIG_PT%02d', id);
   idPos = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idPos))
      newConfig(idPos) = newConfig(idPos)*1000;
   end
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES floatParam(end-1)];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% create_csv_to_print_config_ir_sbd('updateConfig_', 0, g_decArgo_floatConfig);

return
