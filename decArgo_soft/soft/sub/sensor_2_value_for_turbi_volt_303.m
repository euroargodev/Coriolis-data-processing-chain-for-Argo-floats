% ------------------------------------------------------------------------------
% Convert sensor counts values for turbidity (in volts).
%
% SYNTAX :
%  [o_turbiVoltValues] = sensor_2_value_for_turbi_volt_303(a_turbiVoltCounts)
%
% INPUT PARAMETERS :
%   a_turbiVoltCounts : input turbidity counts
%
% OUTPUT PARAMETERS :
%   o_turbiVoltValues : output turbidity values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_turbiVoltValues] = sensor_2_value_for_turbi_volt_303(a_turbiVoltCounts)

% output parameters initialization
o_turbiVoltValues = [];

% default values
global g_decArgo_turbiVoltCountsDef;
global g_decArgo_turbiVoltDef;

% convert counts to values
o_turbiVoltValues = a_turbiVoltCounts;
idDef = find(a_turbiVoltCounts == g_decArgo_turbiVoltCountsDef);
o_turbiVoltValues(idDef) = ones(length(idDef), 1)*g_decArgo_turbiVoltDef;
idNoDef = find(a_turbiVoltCounts ~= g_decArgo_turbiVoltCountsDef);
o_turbiVoltValues(idNoDef) = o_turbiVoltValues(idNoDef)/1000;

return
