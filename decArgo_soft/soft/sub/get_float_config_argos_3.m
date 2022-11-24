% ------------------------------------------------------------------------------
% Retrieve a configuration parameter.
% The last value of the configuration parameter is retrieved => used to retrieve
% static configuration parameter.
%
% SYNTAX :
%  [o_configValue] = get_float_config_argos_3(a_configName)
%
% INPUT PARAMETERS :
%   a_configName : configuration parameter name
%
% OUTPUT PARAMETERS :
%   o_configValues : configuration parameter value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_float_config_argos_3(a_configName)

% output parameters initialization
o_configValue = [];

% float configuration
global g_decArgo_floatConfig;

% retrieve the configuration value
configNames = g_decArgo_floatConfig.NAMES;
configValues = g_decArgo_floatConfig.VALUES;
idPos = find(strncmp(configNames, a_configName, length(a_configName)) == 1, 1);
if (~isempty(idPos))
   configValue = configValues(idPos, end);
   if (~isnan(configValue))
      o_configValue = configValue;
   end
end

return;
