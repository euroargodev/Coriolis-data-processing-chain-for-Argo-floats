% ------------------------------------------------------------------------------
% Retrieve the configuration value of a configuration parameter for a given
% cycle.
%
% SYNTAX :
%  [o_configValue] = get_config_value_apx_ir_rudics(a_configName, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_configName : name of the wanted config parameter
%   a_cycleNum   : concerned cycle number
%
% OUTPUT PARAMETERS :
%   o_configValue : retrieved configuration value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_config_value_apx_ir_rudics(a_configName, a_cycleNum)

% output parameters initialization
o_configValue = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
idConf = find(g_decArgo_floatConfig.NUMBER == configMissionNumber);
if (isempty(idConf))
   fprintf('WARNING: Float #%d Cycle #%d: config #%d is missing\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, configMissionNumber);
   return;
end
configNames = g_decArgo_floatConfig.NAMES;
configValues = g_decArgo_floatConfig.VALUES(:, idConf);

% retrieve the configuration value
idPos = find(strncmp(a_configName, configNames, length(a_configName)) == 1, 1);
if (~isempty(idPos) && ~isempty(configValues(idPos)) && ~isnan(configValues(idPos)))
   if (~iscell(configValues))
      o_configValue = configValues(idPos);
   else
      o_configValue = str2num(configValues{idPos});
   end
end

return;
