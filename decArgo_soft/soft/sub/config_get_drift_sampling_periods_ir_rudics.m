% ------------------------------------------------------------------------------
% Retrieve the drift sampling periods for a given sensor.
%
% SYNTAX :
%  [o_driftSampPeriod, o_zoneThreshold] = ...
%    config_get_drift_sampling_periods_ir_rudics(a_sensorNum, a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_sensorNum : sensor number
%   a_cycleNum  : cycle number
%   a_profNum   : profile number
%
% OUTPUT PARAMETERS :
%   o_driftSampPeriod : drift sampling periods (in days)
%   o_zoneThreshold   : thresholds defining the depth zones
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_driftSampPeriod, o_zoneThreshold] = ...
   config_get_drift_sampling_periods_ir_rudics(a_sensorNum, a_cycleNum, a_profNum)
   
% output parameters initialization
o_driftSampPeriod = ones(5, 1)*-1;
o_zoneThreshold = ones(4, 1)*-1;

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

% find the sampling periods and the depth zone thresholds
for id = 1:5
   % sampling period
   confParamName = sprintf('CONFIG_PC_%d_0_%d', ...
      a_sensorNum, 1+(id-1)*9);
   idPos = find(strcmp(confParamName, configName) == 1, 1);
   if (~isempty(idPos))
      o_driftSampPeriod(id) = configValue(idPos, idConf)/1440;
   end
end
for id = 1:4
   % zone threshold
   confParamName = sprintf('CONFIG_PC_%d_0_%d', ...
      a_sensorNum, 44+id);
   idPos = find(strcmp(confParamName, configName) == 1, 1);
   if (~isempty(idPos))
      o_zoneThreshold(id) = configValue(idPos, idConf);
   end
end

return;
