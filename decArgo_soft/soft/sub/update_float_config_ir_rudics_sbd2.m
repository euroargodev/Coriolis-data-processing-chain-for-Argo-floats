% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration after the reception of a packedt type
% #251, #254 or #255.
%
% SYNTAX :
%  update_float_config_ir_rudics_sbd2(a_packetType, a_packetDate, a_data)
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
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_rudics_sbd2(a_packetType, a_packetDate, a_data)

% float configuration
global g_decArgo_floatConfig;

% sensor list
global g_decArgo_sensorList;


% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

% update the last configuration values according to msg contents
switch a_packetType
   case 255
      for id = 1:23
         name = sprintf('CONFIG_PV_%d', id-1);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+2);
         end
      end
      for id = 1:53
         name = sprintf('CONFIG_PM_%d', id-1);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+25);
         end
      end
   case 254
      for id = 1:28
         name = sprintf('CONFIG_PT_%d', id-1);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = a_data(id+2);
         end
      end
   case 251
      for id = 1:size(a_data, 1)
         if (ismember(a_data(id, 1), g_decArgo_sensorList))
            name = sprintf('CONFIG_PC_%d_%d_%d', a_data(id, 1), a_data(id, 2), a_data(id, 3));
            idPos = find(strcmp(name, configNames) == 1, 1);
            if (~isempty(idPos))
               newConfig(idPos) = a_data(id, 5);
               
               %             % check received information consistency
               %             if (lastConfig(idPos) ~= a_data(id, 4))
               %                fprintf('WARNING: Float #%d Cycle #%d: inconsistency in 251 packet type (%s: current value %s received old value %s)\n', ...
               %                   g_decArgo_floatNum, g_decArgo_cycleNum, ...
               %                   name, num2str(lastConfig(idPos)), num2str(a_data(id, 4)));
               %             end
            end
         end
      end
end;

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES a_packetDate];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% print_config_in_csv_file_ir_rudics_sbd2([num2str(a_packetType) '_'], 0, g_decArgo_floatConfig);

return;
