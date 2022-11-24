% ------------------------------------------------------------------------------
% Convert sensor counts values for chlorophyll (in volts).
%
% SYNTAX :
%  [o_chloroVoltValues] = sensor_2_value_for_chloroA_volt_303(a_chloroVoltCounts)
%
% INPUT PARAMETERS :
%   a_chloroVoltCounts : input chlorophyll counts
%
% OUTPUT PARAMETERS :
%   o_chloroVoltValues : output chlorophyll values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_chloroVoltValues] = sensor_2_value_for_chloroA_volt_303(a_chloroVoltCounts)

% output parameters initialization
o_chloroVoltValues = [];

% default values
global g_decArgo_chloroAVoltCountsDef;
global g_decArgo_chloroVoltDef;

% convert counts to values
o_chloroVoltValues = a_chloroVoltCounts;
idDef = find(a_chloroVoltCounts == g_decArgo_chloroAVoltCountsDef);
o_chloroVoltValues(idDef) = ones(length(idDef), 1)*g_decArgo_chloroVoltDef;
idNoDef = find(a_chloroVoltCounts ~= g_decArgo_chloroAVoltCountsDef);
o_chloroVoltValues(idNoDef) = o_chloroVoltValues(idNoDef)/1000;

return;
