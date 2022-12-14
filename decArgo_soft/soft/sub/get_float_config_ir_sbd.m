% ------------------------------------------------------------------------------
% Retrieve the configuration associated to a given cycle.
%
% SYNTAX :
%  [o_configNames, o_configValues] = get_float_config_ir_sbd(a_cycleNum)
%
% INPUT PARAMETERS :
%   a_cycleNum   : cycle number
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
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configNames, o_configValues] = get_float_config_ir_sbd(a_cycleNum)

% output parameters initialization
o_configNames = [];
o_configValues = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% search this cycle and profile configuration
idUsedConf = find(g_decArgo_floatConfig.USE.CYCLE == a_cycleNum);

if (isempty(idUsedConf))
   
   fprintf('WARNING: Float #%d: config missing for cycle #%d\n', ...
      g_decArgo_floatNum, a_cycleNum);
   return
end

% retrieve the data of the concerned configuration
configNumber = unique(g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == configNumber);
o_configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
o_configValues = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);

return
