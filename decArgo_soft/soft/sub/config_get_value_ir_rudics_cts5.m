% ------------------------------------------------------------------------------
% Retrieve the value of a configuration parameter for a given cycle and profile.
%
% SYNTAX :
%  [o_confParamvalue] = config_get_value_ir_rudics_cts5(a_cycleNum, a_profNum, a_confParamName)
%
% INPUT PARAMETERS :
%   a_cycleNum      : cycle number
%   a_profNum       : profile number
%   a_confParamName : configuration parameter name
%
% OUTPUT PARAMETERS :
%   o_confParamvalue : value of the configuration parameter
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confParamvalue] = config_get_value_ir_rudics_cts5(a_cycleNum, a_profNum, a_confParamName)

% output parameters initialization
o_confParamvalue = [];

% float configuration
global g_decArgo_floatConfig;


% current configuration
configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
configName = g_decArgo_floatConfig.DYNAMIC.NAMES;
configValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
usedCy = g_decArgo_floatConfig.USE.CYCLE;
usedProf = g_decArgo_floatConfig.USE.PROFILE;
usedConfNum = g_decArgo_floatConfig.USE.CONFIG;

% find the id of the concerned configuration
idUsedConf = find((usedCy == a_cycleNum) & (usedProf == a_profNum));
if (isempty(idUsedConf))
   % the configuration does not exist (no data received yet)
   return;
end
idConf = find(configNum == usedConfNum(idUsedConf));

% retrieve the configuration value
idPos = find(strcmp(a_confParamName, configName) == 1, 1);
o_confParamvalue = configValue(idPos, idConf);

return;
