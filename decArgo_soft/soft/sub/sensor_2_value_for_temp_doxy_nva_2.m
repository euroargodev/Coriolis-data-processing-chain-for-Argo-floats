% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for TEMP_DOXY.
%
% SYNTAX :
%  [o_tempDoxyValues] = sensor_2_value_for_temp_doxy_nva_1_2(a_tempDoxyCounts)
%
% INPUT PARAMETERS :
%   a_tempDoxyCounts : TEMP_DOXY counts
%
% OUTPUT PARAMETERS :
%   o_tempDoxyValues : TEMP_DOXY values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tempDoxyValues] = sensor_2_value_for_temp_doxy_nva_2(a_tempDoxyCounts)

% output parameters initialization
o_tempDoxyValues = [];

% default values
global g_decArgo_tempDoxyDef;
global g_decArgo_tempDoxyCountsDef;

% convert counts to values
o_tempDoxyValues = a_tempDoxyCounts;
idDef = find(a_tempDoxyCounts == g_decArgo_tempDoxyCountsDef);
o_tempDoxyValues(idDef) = ones(length(idDef), 1)*g_decArgo_tempDoxyDef;
idNoDef = find(a_tempDoxyCounts ~= g_decArgo_tempDoxyCountsDef);
o_tempDoxyValues(idNoDef) = o_tempDoxyValues(idNoDef)*0.001 - 5;

return
