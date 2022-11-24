% ------------------------------------------------------------------------------
% Get a config value from a given configuration.
%
% SYNTAX :
%  [o_configValue] = get_config_value(a_configName, a_configNames, a_configValues)
%
% INPUT PARAMETERS :
%   a_configName   : name of the wanted config parameter
%   a_configNames  : configuration names
%   a_configValues : configuration values
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
%   01/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_config_value(a_configName, a_configNames, a_configValues)

% output parameters initialization
o_configValue = [];

% retrieve the configuration value
idPos = find(strncmp(a_configName, a_configNames, length(a_configName)) == 1, 1);
if (~isempty(idPos) && ~isempty(a_configValues(idPos)) && ~isnan(a_configValues(idPos)))
   if (~iscell(a_configValues))
      o_configValue = a_configValues(idPos);
   else
      o_configValue = str2num(a_configValues{idPos});
   end
end

return
