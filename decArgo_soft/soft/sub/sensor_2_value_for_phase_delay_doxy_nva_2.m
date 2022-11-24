% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for PHASE_DELAY_DOXY.
%
% SYNTAX :
%  [o_phaseDelayDoxyValues] = sensor_2_value_for_phase_delay_doxy_nva_2(a_phaseDelayDoxyCounts)
%
% INPUT PARAMETERS :
%   a_phaseDelayDoxyCounts : PHASE_DELAY_DOXY counts
%
% OUTPUT PARAMETERS :
%   o_phaseDelayDoxyValues : PHASE_DELAY_DOXY values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseDelayDoxyValues] = sensor_2_value_for_phase_delay_doxy_nva_2(a_phaseDelayDoxyCounts)

% output parameters initialization
o_phaseDelayDoxyValues = [];

% default values
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_phaseDelayDoxyCountsDef;

% convert counts to values
o_phaseDelayDoxyValues = a_phaseDelayDoxyCounts;
idDef = find(a_phaseDelayDoxyCounts == g_decArgo_phaseDelayDoxyCountsDef);
o_phaseDelayDoxyValues(idDef) = ones(length(idDef), 1)*g_decArgo_phaseDelayDoxyDef;
idNoDef = find(a_phaseDelayDoxyCounts ~= g_decArgo_phaseDelayDoxyCountsDef);
o_phaseDelayDoxyValues(idNoDef) = o_phaseDelayDoxyValues(idNoDef)*0.001;

return
