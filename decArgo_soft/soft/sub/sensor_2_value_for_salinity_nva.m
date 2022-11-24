% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for salinities.
%
% SYNTAX :
%  [o_salValues] = sensor_2_value_for_salinity_nva(a_salCounts)
%
% INPUT PARAMETERS :
%   a_salCounts : salinity counts
%
% OUTPUT PARAMETERS :
%   o_salValues : salinity values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_salValues] = sensor_2_value_for_salinity_nva(a_salCounts)

% output parameters initialization
o_salValues = [];

% default values
global g_decArgo_salDef;
global g_decArgo_salCountsDef;

% convert counts to values
o_salValues = a_salCounts;
idDef = find(a_salCounts == g_decArgo_salCountsDef);
o_salValues(idDef) = ones(length(idDef), 1)*g_decArgo_salDef;
idNoDef = find(a_salCounts ~= g_decArgo_salCountsDef);
o_salValues(idNoDef) = o_salValues(idNoDef)*0.001 + 10;

return;
