% ------------------------------------------------------------------------------
% Retrieve the value of a ice parameter for a given cycle and profile.
%
% SYNTAX :
%  [o_iceModeActive] = config_ice_mode_active_111_113(a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_cycleNum      : cycle number
%   a_profNum       : profile number
%
% OUTPUT PARAMETERS :
%   o_iceModeActive : value of 'PG 0' configuration parameter
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iceModeActive] = config_ice_mode_active_111_113(a_cycleNum, a_profNum)

% output parameters initialization
o_iceModeActive = 0;

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
   return
end
idConf = find(configNum == usedConfNum(idUsedConf));

% retrieve the configuration value
idPos = find(strcmp(configName, 'CONFIG_PG_0') == 1, 1);
if (configValue(idPos, idConf) > 0)
   o_iceModeActive = 1;
end

return
