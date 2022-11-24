% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd_nva(a_dataAck)
%
% INPUT PARAMETERS :
%   a_dataAck : parameter packet decoded data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_nva(a_dataAck)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;

% flag used to add 1 to cycle numbers
global g_decArgo_firstDeepCycleDone;

% default values
global g_decArgo_dateDef;


% create and fill a new set of configuration values
configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
newConfig = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

if (~isempty(a_dataAck))
   
   % process acknowledgment data
   for idC = 1:size(a_dataAck, 1)
      cmdt = a_dataAck(idC, 1);
      prmn = a_dataAck(idC, 2);
      value = a_dataAck(idC, 3);
      status = a_dataAck(idC, 4);
      if (status == 1)
         cmd = 'M';
         if (cmdt == 2)
            cmd = 'H';
         end
         name = sprintf('CONFIG_P%c%02d', cmd, prmn);
         idPos = find(strcmp(name, configNames) == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = value;
         end
      else
         fprintf('INFO: Float #%d: User command [CMDT: %d, PRMN: %d, VALUE: %d] was unsuccessful (from acknowledgment message dated: %s)\n', ...
            g_decArgo_floatNum, a_dataAck(idC, 1:3), julian_2_gregorian_dec_argo(a_dataAck(idC, end)));
      end
   end
   configDate = a_dataAck(1, end);
   
else
   
   % update 'CONFIG_PM04' after the first deep cycle
   idPos = find(strcmp(g_decArgo_floatConfig.TMP.NAMES, 'CONFIG_PM04') == 1, 1);
   if (~isempty(idPos))
      configPm04Val = g_decArgo_floatConfig.TMP.VALUES(idPos);
      if (~isnan(configPm04Val))
         idPos = find(strcmp(configNames, 'CONFIG_PM04') == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = configPm04Val;
         end
      end
   end
   
   % update 'CONFIG_PM00' after the first deep cycle
   idPos = find(strcmp(g_decArgo_floatConfig.TMP.NAMES, 'CONFIG_PM00') == 1, 1);
   if (~isempty(idPos))
      configPm00Val = g_decArgo_floatConfig.TMP.VALUES(idPos);
      if (~isnan(configPm00Val))
         idPos = find(strcmp(configNames, 'CONFIG_PM00') == 1, 1);
         if (~isempty(idPos))
            newConfig(idPos) = configPm00Val;
         end
      end
   end
   
   configDate = g_decArgo_dateDef;

end

% update 'CONFIG_PX00' according to newConfig values
name = 'CONFIG_PX00';
idPos = find(strcmp(name, configNames) == 1, 1);
if (~isempty(idPos))
   ascentSampling = [];
   name = 'CONFIG_PM03';
   idP = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idP))
      ascentSampling = newConfig(idP);
   end
   descentSampling = [];
   name = 'CONFIG_PM04';
   idP = find(strcmp(name, configNames) == 1, 1);
   if (~isempty(idP))
      descentSampling = newConfig(idP);
   end
   
   if (~isempty(ascentSampling) && ~isempty(descentSampling))
      direction = 0;
      if ((descentSampling == 0) && (ascentSampling ~= 0))
         direction = 1; % ascending
      elseif ((descentSampling ~= 0) && (ascentSampling ~= 0))
         direction = 3; % descending and ascending
      elseif ((descentSampling ~= 0) && (ascentSampling == 0))
         direction = 2; % descending
      end
   end

   newConfig(idPos) = direction;
end

% update float configuration
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [g_decArgo_floatConfig.DYNAMIC_TMP.DATES configDate];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [g_decArgo_floatConfig.DYNAMIC_TMP.VALUES newConfig];

% print_config_in_csv_file_ir_sbd('updateConfig_', 0, g_decArgo_floatConfig);

return;
