% ------------------------------------------------------------------------------
% Retrieve the configuration associated to a given cycle and profile.
%
% SYNTAX :
%  [o_configNames, o_configValues] = get_float_config_ir_rudics_sbd2( ...
%    a_cycleNum, a_profileNum)
%
% INPUT PARAMETERS :
%   a_cycleNum   : cycle number
%   a_profileNum : profile number
%
% OUTPUT PARAMETERS :
%   o_configNames  : retrieve configuration names
%   o_configValues : retrieve configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configNames, o_configValues] = get_float_config_ir_rudics_sbd2( ...
   a_cycleNum, a_profileNum)

% output parameters initialization
o_configNames = [];
o_configValues = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% search this cycle and profile configuration
idUsedConf = find((g_decArgo_floatConfig.USE.CYCLE == a_cycleNum) & ...
   (g_decArgo_floatConfig.USE.PROFILE == a_profileNum));
if (isempty(idUsedConf))
   
   fprintf('WARNING: Float #%d: config missing for cycle #%d and profile #%d => unable to set the vertical sampling scheme\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profileNum);
   return;
end

% retrieve the data of the concerned configuration
idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
o_configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
o_configValues = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);

return;
