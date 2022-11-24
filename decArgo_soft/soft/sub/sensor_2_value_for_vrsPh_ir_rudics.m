% ------------------------------------------------------------------------------
% Convert sensor counts values for VRS_PH.
%
% SYNTAX :
%  [o_vrsPhValues] = sensor_2_value_for_vrsPh_ir_rudics(a_vrsPhCounts)
%
% INPUT PARAMETERS :
%   a_vrsPhCounts : input coef attenuation counts
%
% OUTPUT PARAMETERS :
%   o_vrsPhValues : output coef attenuation values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_vrsPhValues] = sensor_2_value_for_vrsPh_ir_rudics(a_vrsPhCounts)

% output parameters initialization
o_vrsPhValues = [];

% default values
global g_decArgo_vrsPhCountsDef;
global g_decArgo_vrsPhDef;

% convert counts to values
o_vrsPhValues = a_vrsPhCounts;
idDef = find(a_vrsPhCounts == g_decArgo_vrsPhCountsDef);
o_vrsPhValues(idDef) = ones(length(idDef), 1)*g_decArgo_vrsPhDef;
idNoDef = find(a_vrsPhCounts ~= g_decArgo_vrsPhCountsDef);
o_vrsPhValues(idNoDef) = o_vrsPhValues(idNoDef)/1000000;

return
