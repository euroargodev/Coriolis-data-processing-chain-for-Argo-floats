% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration after the reception of a packedt type
% #248, #249, #254 or #255.
%
% SYNTAX :
%  update_float_config_ir_rudics_111(a_packetType, a_packetDate, a_data)
%
% INPUT PARAMETERS :
%   a_packetType : packet type number
%   a_packetDate : packet date
%   a_data       : packet data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_rudics_111(a_packetType, a_packetDate, a_data)

% float configuration
global g_decArgo_floatConfig;


% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

% update the last configuration values according to msg contents
switch a_packetType
   case 255
      for id = 0:6
         name = sprintf('CONFIG_PV_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+5);
         end
      end
      for id = 0:52
         name = sprintf('CONFIG_PM_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+12);
         end
      end
   case 254
      for id = 0:29
         name = sprintf('CONFIG_PT_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+3);
         end
      end
      for id = 0:8
         name = sprintf('CONFIG_PG_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+33);
         end
      end
   case 248
      for id = 3:7
         name = sprintf('CONFIG_PI_%d', id);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id);
         end
      end
   case 249
      if (a_data(2) == 0)
         
         % standard parameters
         for id = 0:48
            name = sprintf('CONFIG_PC_%d_0_%d', a_data(1), id);
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = a_data(id+7);
            end
         end
      else
         
         % specific parameters
         for id = 0:18
            name = sprintf('CONFIG_PC_%d_1_%d', a_data(1), id);
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = a_data(id+7);
            end
         end
      end
end;

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES a_packetDate];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% create_csv_to_print_config_ir_rudics_sbd2([num2str(a_packetType) '_'], 0, g_decArgo_floatConfig);

return;
