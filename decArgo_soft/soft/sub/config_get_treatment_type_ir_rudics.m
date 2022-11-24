% ------------------------------------------------------------------------------
% Retrieve the treatment type of the depth zone associated to a given pressure
% value.
%
% SYNTAX :
%  [o_treatType] = ...
%    config_get_treatment_type_ir_rudics(a_cycleNum, a_profNum, a_presValue)
%
% INPUT PARAMETERS :
%   a_sensorNum : sensor number
%   a_cycleNum  : cycle number
%   a_presValue : pressure value
%
% OUTPUT PARAMETERS :
%   o_treatType : treatment type
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_treatType] = ...
   config_get_treatment_type_ir_rudics(a_cycleNum, a_profNum, a_presValue)
   
% output parameters initialization
o_treatType = [];

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
idConf = find(configNum == usedConfNum(idUsedConf));

% find the depth zone thresholds
depthZoneNum = -1;
for id = 1:4
   % zone threshold
   confParamName = sprintf('CONFIG_PC_0_0_%d', 44+id);
   idPos = find(strcmp(confParamName, configName) == 1, 1);
   if (~isempty(idPos))
      zoneThreshold = configValue(idPos, idConf);
      if (a_presValue <= zoneThreshold)
         depthZoneNum = id;
         break
      end
   end
end
if (depthZoneNum == -1)
   depthZoneNum = 5;
end

% retrieve treatment type for this depth zone
confParamName = sprintf('CONFIG_PC_0_0_%d', 6+(depthZoneNum-1)*9);
idPos = find(strcmp(confParamName, configName) == 1, 1);
if (~isempty(idPos))
   o_treatType = configValue(idPos, idConf);
end

return
