% ------------------------------------------------------------------------------
% Set value of a float static configuration item.
%
% SYNTAX :
%  set_static_config_value(a_configName, a_configValue)
%
% INPUT PARAMETERS :
%   a_configName  : static configuration item name
%   a_configValue : static configuration item value
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function set_static_config_value(a_configName, a_configValue)

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% retrieve the data of the concerned configuration
idConfItem = find(strcmp(g_decArgo_floatConfig.STATIC.NAMES, a_configName) == 1, 1);
if (~isempty(idConfItem))
   g_decArgo_floatConfig.STATIC.VALUES{idConfItem} = num2str(a_configValue);
else
   fprintf('WARNING: Float #%d: static config parameter ''%s'' is missing\n', ...
      g_decArgo_floatNum, a_configName);
end

return
