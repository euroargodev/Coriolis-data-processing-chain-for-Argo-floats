% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for pressures.
%
% SYNTAX :
%  [o_presValues] = sensor_2_value_for_pressure_201_203_215_216_218_221(a_presCounts)
%
% INPUT PARAMETERS :
%   a_presCounts : pressure counts
%
% OUTPUT PARAMETERS :
%   o_presValues : pressure values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_presValues] = sensor_2_value_for_pressure_201_203_215_216_218_221(a_presCounts)

% output parameters initialization
o_presValues = [];

% default values
global g_decArgo_presDef;
global g_decArgo_presCountsDef;

% convert counts to values
o_presValues = a_presCounts;
idDef = find(a_presCounts == g_decArgo_presCountsDef);
o_presValues(idDef) = ones(length(idDef), 1)*g_decArgo_presDef;
idNoDef = find(a_presCounts ~= g_decArgo_presCountsDef);
o_presValues(idNoDef) = (twos_complement_dec_argo(o_presValues(idNoDef), 16)+30000)/10;

return
