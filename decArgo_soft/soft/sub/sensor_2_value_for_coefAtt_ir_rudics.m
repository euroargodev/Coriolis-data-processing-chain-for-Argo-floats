% ------------------------------------------------------------------------------
% Convert sensor counts values for coef attenuation.
%
% SYNTAX :
%  [o_coefAttValues] = sensor_2_value_for_coefAtt_ir_rudics(a_coefAttCounts)
%
% INPUT PARAMETERS :
%   a_coefAttCounts : input coef attenuation counts
%
% OUTPUT PARAMETERS :
%   o_coefAttValues : output coef attenuation values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_coefAttValues] = sensor_2_value_for_coefAtt_ir_rudics(a_coefAttCounts)

% output parameters initialization
o_coefAttValues = [];

% default values
global g_decArgo_coefAttCountsDef;
global g_decArgo_coefAttDef;

% convert counts to values
o_coefAttValues = a_coefAttCounts;
idDef = find(a_coefAttCounts == g_decArgo_coefAttCountsDef);
o_coefAttValues(idDef) = ones(length(idDef), 1)*g_decArgo_coefAttDef;
idNoDef = find(a_coefAttCounts ~= g_decArgo_coefAttCountsDef);
o_coefAttValues(idNoDef) = o_coefAttValues(idNoDef)/1000;

return
