% ------------------------------------------------------------------------------
% Retrieve the value of a configuration parameter from a given configuration.
%
% SYNTAX :
% [o_configParamValue] = get_config_value_pfv2_3(a_configParamName, a_configNames, a_configValues)
%
% INPUT PARAMETERS :
%   a_configParamName : name of the wanted configuration parameter
%   a_configNames     : configuration names
%   a_configValues    : configuration values
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
%   09/28/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configParamValue] = get_config_value_pfv2_3(a_configParamName, a_configNames, a_configValues)

% output parameters initialization
o_configParamValue = [];


% retrieve the configuration parameter value
idPos = find(strcmp(a_configParamName, a_configNames));
if (~isempty(idPos) && ~isnan(a_configValues(idPos)))
   o_configParamValue = a_configValues(idPos);
end

return
