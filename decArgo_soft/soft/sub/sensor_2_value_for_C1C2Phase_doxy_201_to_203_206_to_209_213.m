% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for C1PHASE_DOXY or C2PHASE_DOXY
% values.
%
% SYNTAX :
%  [o_c1C2PhaseDoxyValues] = sensor_2_value_for_C1C2Phase_doxy_201_to_203_206_to_209_213(a_c1C2PhaseDoxyCounts)
%
% INPUT PARAMETERS :
%   a_c1C2PhaseDoxyCounts : C1PHASE_DOXY or C2PHASE_DOXY counts
%
% OUTPUT PARAMETERS :
%   o_c1C2PhaseDoxyValues : C1PHASE_DOXY values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_c1C2PhaseDoxyValues] = sensor_2_value_for_C1C2Phase_doxy_201_to_203_206_to_209_213(a_c1C2PhaseDoxyCounts)

% output parameters initialization
o_c1C2PhaseDoxyValues = [];

% default values
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_c1C2PhaseDoxyDef;

% convert counts to values
o_c1C2PhaseDoxyValues = a_c1C2PhaseDoxyCounts;
idDef = find(a_c1C2PhaseDoxyCounts == g_decArgo_c1C2PhaseDoxyCountsDef);
o_c1C2PhaseDoxyValues(idDef) = ones(length(idDef), 1)*g_decArgo_c1C2PhaseDoxyDef;
idNoDef = find(a_c1C2PhaseDoxyCounts ~= g_decArgo_c1C2PhaseDoxyCountsDef);
o_c1C2PhaseDoxyValues(idNoDef) = (o_c1C2PhaseDoxyValues(idNoDef)-20000)*2/1000;

return;
