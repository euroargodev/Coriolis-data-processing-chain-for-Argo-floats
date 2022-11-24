% ------------------------------------------------------------------------------
% Retrieve the configuration associated to a given mission number.
%
% SYNTAX :
%  [o_configNames, o_configValues] = get_float_config_argos_1(a_configMissionNumber)
%
% INPUT PARAMETERS :
%   a_configMissionNumber : mission number
%
% OUTPUT PARAMETERS :
%   o_configNames  : retrieved configuration names
%   o_configValues : retrieved configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configNames, o_configValues] = get_float_config_argos_1(a_configMissionNumber)

% output parameters initialization
o_configNames = [];
o_configValues = [];

% current float WMO number
global g_decArgo_floatNum;

% float configuration
global g_decArgo_floatConfig;


% search this cycle and profile configuration
idConf = find(g_decArgo_floatConfig.NUMBER == a_configMissionNumber);
if (isempty(idConf))
   fprintf('WARNING: Float #%d: config #%d is missing\n', ...
      g_decArgo_floatNum, a_configMissionNumber);
   return;
end

% retrieve the data of the concerned configuration
o_configNames = g_decArgo_floatConfig.NAMES;
o_configValues = g_decArgo_floatConfig.VALUES(:, idConf);

return;
