% ------------------------------------------------------------------------------
% Convert sensor counts values for CDOM.
%
% SYNTAX :
%  [o_cdomValues] = sensor_2_value_for_cdom_ir_rudics(a_cdomCounts)
%
% INPUT PARAMETERS :
%   a_cdomCounts : input CDOM counts
%
% OUTPUT PARAMETERS :
%   o_cdomValues : output CDOM counts
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cdomValues] = sensor_2_value_for_cdom_ir_rudics(a_cdomCounts)

% output parameters initialization
o_cdomValues = [];

% default values
global g_decArgo_cdomCountsDef;
global g_decArgo_cdomDef;

% convert counts to values
o_cdomValues = a_cdomCounts;
idDef = find(a_cdomCounts == g_decArgo_cdomCountsDef);
o_cdomValues(idDef) = ones(length(idDef), 1)*g_decArgo_cdomDef;
idNoDef = find(a_cdomCounts ~= g_decArgo_cdomCountsDef);
o_cdomValues(idNoDef) = o_cdomValues(idNoDef)/10;

return;
