% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for TPHASE_DOXY values.
%
% SYNTAX :
%  [o_tPhaseDoxyValues] = sensor_2_value_for_tphase_doxy_27_28_29(a_tPhaseDoxyCounts)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxyCounts : TPHASE_DOXY counts
%
% OUTPUT PARAMETERS :
%   o_tPhaseDoxyValues : TPHASE_DOXY values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tPhaseDoxyValues] = sensor_2_value_for_tphase_doxy_27_28_29(a_tPhaseDoxyCounts)

% output parameters initialization
o_tPhaseDoxyValues = [];

% default values
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_tPhaseDoxyCountsDef;

% convert counts to values
o_tPhaseDoxyValues = a_tPhaseDoxyCounts;
idDef = find(a_tPhaseDoxyCounts == g_decArgo_tPhaseDoxyCountsDef);
o_tPhaseDoxyValues(idDef) = ones(length(idDef), 1)*g_decArgo_tPhaseDoxyDef;
idNoDef = find(a_tPhaseDoxyCounts ~= g_decArgo_tPhaseDoxyCountsDef);
o_tPhaseDoxyValues(idNoDef) = o_tPhaseDoxyValues(idNoDef)*0.008 + 10;

return;
