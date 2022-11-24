% ------------------------------------------------------------------------------
% Convert sensor counts values for turbidity.
%
% SYNTAX :
%  [o_turbiValues] = sensor_2_value_for_turbi_ir_rudics(a_turbiCounts)
%
% INPUT PARAMETERS :
%   a_turbiCounts : input turbidity counts
%
% OUTPUT PARAMETERS :
%   o_turbiValues : output turbidity values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_turbiValues] = sensor_2_value_for_turbi_ir_rudics(a_turbiCounts)

% output parameters initialization
o_turbiValues = [];

% default values
global g_decArgo_turbiCountsDef;
global g_decArgo_turbiDef;

% convert counts to values
o_turbiValues = a_turbiCounts;
idDef = find(a_turbiCounts == g_decArgo_turbiCountsDef);
o_turbiValues(idDef) = ones(length(idDef), 1)*g_decArgo_turbiDef;
idNoDef = find(a_turbiCounts ~= g_decArgo_turbiCountsDef);
o_turbiValues(idNoDef) = o_turbiValues(idNoDef)/10;

return;
