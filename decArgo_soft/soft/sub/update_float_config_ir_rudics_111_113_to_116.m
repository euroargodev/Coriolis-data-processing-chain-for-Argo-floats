% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration after the reception of a packedt type
% #248, #249, #254 or #255.
%
% SYNTAX :
%  update_float_config_ir_rudics_111_113_to_116( ...
%    a_floatProgRudics, a_floatProgTech, a_floatProgParam, a_floatProgSensor, a_irSessionNum)
%
% INPUT PARAMETERS :
%   a_floatProgRudics       : decoded float Iridium config (PI) data (type 248)
%   a_floatProgTech         : decoded float Tech config (PT and PG) data (type 254)
%   a_floatProgParam        : decoded float Vector & Mission config (PV and PM) data (type 255)
%   a_floatProgSensor       : decoded float Sensor config (PC) data (type 249)
%   a_irSessionNum          : number of the Iridium session
%   a_considerProgParamFlag : flag to consider PV & PM parameters
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
function update_float_config_ir_rudics_111_113_to_116( ...
   a_floatProgRudics, a_floatProgTech, a_floatProgParam, a_floatProgSensor, ...
   a_irSessionNum, a_considerProgParamFlag)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% sensor list
global g_decArgo_sensorList;

% float configuration
global g_decArgo_floatConfig;

% array to store :
% - all configuration parameters of a second Iridium session (that
% should not be used immediatly)
% - PV & PM parameters that should be use on a new cycle only (in case of
% multi-profile mode)
global g_decArgo_floatProgTab;


if (a_considerProgParamFlag == 0)

   % store configuration parameters
   g_decArgo_floatProgTab = cat(1, g_decArgo_floatProgTab, ...
      [{a_floatProgRudics} {a_floatProgTech} {a_floatProgParam} {a_floatProgSensor} {a_irSessionNum-1}]);

   % don't consider configuration parameters of a second iridium session
   if (a_irSessionNum == 2)
      return
   end
end

keepList = [];
for idConf = 1:size(g_decArgo_floatProgTab, 1)
   
   inputFloatProgRudics = g_decArgo_floatProgTab{idConf, 1};
   inputFloatProgTech = g_decArgo_floatProgTab{idConf, 2};
   inputFloatProgParam = g_decArgo_floatProgTab{idConf, 3};
   inputFloatProgSensor = g_decArgo_floatProgTab{idConf, 4};
   waitFlag = g_decArgo_floatProgTab{idConf, 5};
   if (waitFlag)
      g_decArgo_floatProgTab{idConf, 5} = 0;
      keepList = [keepList idConf];
      continue
   end
   
   % create and fill a new set of configuration values
   configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
   newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
   
   % update the last configuration values according to msg contents
   packDates = [];
   for idPack = 1:size(inputFloatProgRudics, 1)
      floatProgRudics = inputFloatProgRudics(idPack, :);
      packDates = [packDates floatProgRudics(1)];
      for id = 3:7
         name = sprintf('CONFIG_PI_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatProgRudics(id+1);
         end
      end
   end
   for idPack = 1:size(inputFloatProgTech, 1)
      floatProgTech = inputFloatProgTech(idPack, :);
      packDates = [packDates floatProgTech(1)];
      for id = 0:29
         name = sprintf('CONFIG_PT_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatProgTech(id+4);
         end
      end
      for id = 0:8
         name = sprintf('CONFIG_PG_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = floatProgTech(id+34);
         end
      end
   end
   if (a_considerProgParamFlag == 1)
      for idPack = 1:size(inputFloatProgParam, 1)
         floatProgParam = inputFloatProgParam(idPack, :);
         packDates = [packDates floatProgParam(1)];
         for id = 0:6
            name = sprintf('CONFIG_PV_%d', id);
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = floatProgParam(id+6);
            end
         end
         for id = 0:52
            name = sprintf('CONFIG_PM_%d', id);
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = floatProgParam(id+13);
            end
         end
      end
   end
   for idPack = 1:size(inputFloatProgSensor, 1)
      floatProgSensor = inputFloatProgSensor(idPack, :);
      if (~ismember(floatProgSensor(2), g_decArgo_sensorList))
         fprintf('DEC_WARNING: Float #%d Cycle #%d: inconsistent sensor CONF data received (for sensor #%d which is not mounted on the float) - ignoring configuration data\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            floatProgSensor(2));
         continue
      end
      packDates = [packDates floatProgSensor(1)];
      if (floatProgSensor(3) == 0)
         % standard parameters
         for id = 0:48
            name = sprintf('CONFIG_PC_%d_0_%d', floatProgSensor(2), id);
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = floatProgSensor(id+8);
            end
         end
      else
         % specific parameters
         for id = 0:19
            name = sprintf('CONFIG_PC_%d_1_%d', floatProgSensor(2), id);
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = floatProgSensor(id+8);
            end
         end
      end
   end
   
   % update float configuration
   g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES min(packDates)];
   g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

   %    a=1
   %    create_csv_to_print_config_ir_rudics_sbd2('', 0, g_decArgo_floatConfig);

end

if (a_considerProgParamFlag == 1)
   g_decArgo_floatProgTab = g_decArgo_floatProgTab(keepList, :);
end

return
