% ------------------------------------------------------------------------------
% Retrieve the value of a static configuration parameter.
%
% SYNTAX :
%  [o_configValue] = get_static_config_value(a_configName, a_warningIfMissing)
%
% INPUT PARAMETERS :
%   a_configName       : static configuration parameter name
%   a_warningIfMissing : print a warning if wanted config parameter is missing
%
% OUTPUT PARAMETERS :
%   o_configValue : static configuration parameter value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/08/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configValue] = get_static_config_value(a_configName, a_warningIfMissing)

% output parameters initialization
o_configValue = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% retrieve the data of the concerned configuration
idConfItem = find(strcmp(g_decArgo_floatConfig.STATIC.NAMES, a_configName) == 1, 1);
if (~isempty(idConfItem))
   o_configValue = str2num(g_decArgo_floatConfig.STATIC.VALUES{idConfItem});
elseif (a_warningIfMissing == 1)
   fprintf('WARNING: Float #%d: static config parameter ''%s'' is missing\n', ...
      g_decArgo_floatNum, a_configName);
end

return;
