% ------------------------------------------------------------------------------
% Retrieve the value of a configuration parameter for a given cycle.
%
% SYNTAX :
% [o_configParamValue] = get_config_value_pfv2_2(a_configParamName, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_configParamName : name of the wanted configuration parameter
%   a_cycleNum        : cycle number
%
% OUTPUT PARAMETERS :
%   o_configParamValue : retrieved value of the configuration parameter
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/24/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configParamValue] = get_config_value_pfv2_2(a_configParamName, a_cycleNum)

% output parameters initialization
o_configParamValue = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


idUsedConf = find(g_decArgo_floatConfig.USE.CYCLE == a_cycleNum);
if (length(idUsedConf) ~= 1)
   if (isempty(idUsedConf))
      fprintf('WARNING: Float #%d: Config missing for cycle #%d\n', ...
         g_decArgo_floatNum, a_cycleNum);
   else
      fprintf('WARNING: Float #%d: Multiple (%d) values for configuration parameter ''%s'' for cycle #%d\n', ...
         g_decArgo_floatNum, a_configParamName, a_cycleNum);
   end
   return
end

% retrieve the data of the concerned configuration
configNumber = unique(g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == configNumber);
configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
configValues = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);

% retrieve the configuration parameter value
idPos = find(strcmp(a_configParamName, configNames));
if (~isempty(idPos) && ~isnan(configValues(idPos)))
   o_configParamValue = configValues(idPos);
end

return
