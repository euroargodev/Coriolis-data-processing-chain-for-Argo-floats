% ------------------------------------------------------------------------------
% Get the config mission number associated with a given cycle number.
%
% SYNTAX :
%  [o_configMissionNumber] = get_config_mission_number_ir_sbd(a_cycleNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : concerned cycle number
%
% OUTPUT PARAMETERS :
%   o_configMissionNumber : configuration mission number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configMissionNumber] = get_config_mission_number_ir_sbd(a_cycleNum)

% output parameters initialization
o_configMissionNumber = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% search this cycle and profile configuration
idUsedConf = find(g_decArgo_floatConfig.USE.CYCLE == a_cycleNum);

if (isempty(idUsedConf))
   
   fprintf('WARNING: Float #%d: config missing for cycle #%d\n', ...
      g_decArgo_floatNum, a_cycleNum);
   return;
end

% retrieve the number of the concerned configuration
o_configMissionNumber = unique(g_decArgo_floatConfig.USE.CONFIG(idUsedConf));

return;
