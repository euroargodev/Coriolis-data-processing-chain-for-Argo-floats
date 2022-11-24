% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for PHASE_DELAY_DOXY values.
%
% SYNTAX :
%  [o_phaseDelayDoxyValues] = sensor_2_value_for_phase_delay_doxy_209(a_phaseDelayDoxyCounts)
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
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseDelayDoxyValues] = sensor_2_value_for_phase_delay_doxy_209(a_phaseDelayDoxyCounts)

% output parameters initialization
o_phaseDelayDoxyValues = [];

% default values
global g_decArgo_phaseDelayDoxyCountsDef;
global g_decArgo_phaseDelayDoxyDef;

% convert counts to values
o_phaseDelayDoxyValues = a_phaseDelayDoxyCounts;
idDef = find(a_phaseDelayDoxyCounts == g_decArgo_phaseDelayDoxyCountsDef);
o_phaseDelayDoxyValues(idDef) = ones(length(idDef), 1)*g_decArgo_phaseDelayDoxyDef;
idNoDef = find(a_phaseDelayDoxyCounts ~= g_decArgo_phaseDelayDoxyCountsDef);
o_phaseDelayDoxyValues(idNoDef) = o_phaseDelayDoxyValues(idNoDef)/1000;

return;
