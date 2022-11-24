% ------------------------------------------------------------------------------
% Convert sensor counts values for nitrate concentration.
%
% SYNTAX :
%  [o_concNitraValues] = sensor_2_value_for_concNitra_ir_rudics(a_concNitraCounts)
%
% INPUT PARAMETERS :
%   a_concNitraCounts : input nitrate concentration counts
%
% OUTPUT PARAMETERS :
%   o_concNitraValues : output nitrate concentration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_concNitraValues] = sensor_2_value_for_concNitra_ir_rudics(a_concNitraCounts)

% output parameters initialization
o_concNitraValues = [];

% default values
global g_decArgo_concNitraCountsDef;
global g_decArgo_concNitraDef;

% convert counts to values
o_concNitraValues = a_concNitraCounts;
idDef = find(a_concNitraCounts == g_decArgo_concNitraCountsDef);
o_concNitraValues(idDef) = ones(length(idDef), 1)*g_decArgo_concNitraDef;
idNoDef = find(a_concNitraCounts ~= g_decArgo_concNitraCountsDef);
o_concNitraValues(idNoDef) = o_concNitraValues(idNoDef)/100;

return
