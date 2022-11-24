% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd_221(a_floatParam, a_cycleNum)
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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/06/2019 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_221(a_floatParam, a_cycleNum)

% default values
global g_decArgo_dateDef;

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

% from
% - decId 223 for Arvor
% - decId 221 for Arvor Deep
% configuration parameters are not transmitted each cycle
% consequently we must update the configuration of the second deep cycle with
% initial parameters, this should be done once (except if alterneated profil or
% auto-increment flag are set)
global  g_decArgo_doneOnceFlag;


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

% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

updateDate = g_decArgo_dateDef;
if (~isempty(floatParam1) || ~isempty(floatParam2))
   
   if (~isempty(floatParam1))
      for id = 0:3
         name = sprintf('CONFIG_PM%02d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatParam1(id+10);
         end
      end
      for id = 5:18
         name = sprintf('CONFIG_PM%02d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatParam1(id+9);
         end
      end
      for id = [0:14 16:37]
         name = sprintf('CONFIG_PT%02d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatParam1(id+28);
         end
      end
   end
   
   if (~isempty(floatParam2))
      for id = 0:15
         name = sprintf('CONFIG_PG%02d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatParam2(id+10);
         end
      end
   end
   
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
      
      % set cycle #1 duration
      idPos = find(strcmp(configNames, 'CONFIG_PM01') == 1, 1);
      if (~isempty(idPos))
         newConfig(idPos) = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(idPos, 1);
      end
   end
   
   % manage alternated profile pressure
   if (floatParam1(44) ~= 1)
      
      % check cycle number VS PT16
      if (mod(floatInternalCycleNumber + 1, floatParam1(44)) == 0)
         % profile pressure is PT17
         idPos = find(strcmp(configNames, 'CONFIG_PM09') == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatParam1(45);
         end
      end
      
      g_decArgo_doneOnceFlag = 2; % alternatePeriod or pressureIncrement should be considered once again
   end
   
   % manage auto-increment of parking pressure
   if (floatParam1(47) ~= 0)
      
      % get park pressure of the previous cycle
      [configNames, configValues] = get_float_config_ir_sbd(floatParam1(9)-1);
      if (~isempty(configNames))
         parkPresPrevCycle = get_config_value('CONFIG_PM08', configNames, configValues);
         if (~isempty(parkPresPrevCycle))
            
            % add PT19 to park pressure of the previous cycle
            idPos = find(strcmp(configNames, 'CONFIG_PM08') == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = parkPresPrevCycle + floatParam1(47);
            end
         end
      end
      
      g_decArgo_doneOnceFlag = 2; % alternatePeriod or pressureIncrement should be considered once again
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
   else
      updateDate = floatParam2(end-1);
   end

else
   
   if (g_decArgo_doneOnceFlag == 0)
      
      staticConfigNames = g_decArgo_floatConfig.STATIC.NAMES;
      staticConfigValues = g_decArgo_floatConfig.STATIC.VALUES;
      
      % set PM01 and PM05 to initial values
      idDel = [];
      for id = [1 5]
         name = sprintf('CONFIG_PM%02d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            idPos2 = find(strcmp(name, staticConfigNames) == 1, 1);
            if (~isempty(idPos2))
               newConfig(idPos) = str2double(staticConfigValues{idPos2});
               idDel = [idDel idPos2];
            end
         end
      end
      
      % update PX00 (profiling direction)
      idPx00 = find(strcmp('CONFIG_PX00', configNames) == 1, 1);
      if (~isempty(idPx00))
         
         idPm05 = find(strcmp('CONFIG_PM05', configNames) == 1, 1);
         idPm07 = find(strcmp('CONFIG_PM07', configNames) == 1, 1);
         if (~isempty(idPm05) && ~isnan(newConfig(idPm05)) && ...
               ~isempty(idPm07) && ~isnan(newConfig(idPm07)))
            
            descentSamPeriod = newConfig(idPm05);
            ascentSamPeriod = newConfig(idPm07);
            
            direction = 0;
            if ((descentSamPeriod == 0) && (ascentSamPeriod ~= 0))
               direction = 1; % ascending
            elseif ((descentSamPeriod ~= 0) && (ascentSamPeriod ~= 0))
               direction = 3; % descending and ascending
            elseif ((descentSamPeriod ~= 0) && (ascentSamPeriod == 0))
               direction = 2; % descending
            end
            
            newConfig(idPx00) = direction;
         end
      end
      
      % remove temporary static parameters
      g_decArgo_floatConfig.STATIC.NAMES(idDel) = [];
      g_decArgo_floatConfig.STATIC.VALUES(idDel) = [];
   end
   
   % manage alternated profile pressure
   alternatePeriod = '';
   idPt16 = find(strcmp('CONFIG_PT16', configNames) == 1, 1);
   if (~isempty(idPt16) && ~isnan(newConfig(idPt16)))
      alternatePeriod = newConfig(idPt16);
      if (alternatePeriod ~= 1)
         
         % check cycle number VS PT16
         if (mod(floatInternalCycleNumber + 1, alternatePeriod) == 0)
            
            % profile pressure is PT17
            idPt17 = find(strcmp('CONFIG_PT17', configNames) == 1, 1);
            if (~isempty(idPt17) && ~isnan(newConfig(idPt17)))
               alternatePressure = newConfig(idPt17);
               idPm09 = find(strcmp(configNames, 'CONFIG_PM09') == 1, 1);
               if (~isempty(idPm09))
                  newConfig(idPm09) = alternatePressure;
               end
            end
         end
      end
   end
   
   % manage auto-increment of parking pressure
   pressureIncrement = '';
   idPt19 = find(strcmp('CONFIG_PT19', configNames) == 1, 1);
   if (~isempty(idPt19) && ~isnan(newConfig(idPt19)))
      pressureIncrement = newConfig(idPt19);
      if (pressureIncrement ~= 0)

         % get park pressure of the previous cycle
         [configNames, configValues] = get_float_config_ir_sbd(a_cycleNum-1);
         if (~isempty(configNames))
            parkPresPrevCycle = get_config_value('CONFIG_PM08', configNames, configValues);
            if (~isempty(parkPresPrevCycle))
               
               % add PT19 to park pressure of the previous cycle
               idPm08 = find(strcmp(configNames, 'CONFIG_PM08') == 1, 1);
               if (~isempty(idPm08))
                  newConfig(idPm08) = parkPresPrevCycle + pressureIncrement;
               end
            end
         end
      end
   end
   
   if (~isempty(alternatePeriod) && (alternatePeriod == 1) && ...
         ~isempty(pressureIncrement) && (pressureIncrement == 0))
      g_decArgo_doneOnceFlag = 1; % no need to check again until alternatePeriod or pressureIncrement are modified
   else
      g_decArgo_doneOnceFlag = 2; % alternatePeriod or pressureIncrement should be considered once again
   end
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES = [g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES a_cycleNum];
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES updateDate];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% create_csv_to_print_config_ir_sbd('updateConfig_', 0, g_decArgo_floatConfig);

return
