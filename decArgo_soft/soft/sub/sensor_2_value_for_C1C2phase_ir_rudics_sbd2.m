% ------------------------------------------------------------------------------
% Convert sensor counts values for C1 or C2 phase.
%
% SYNTAX :
%  [o_phaseValues] = sensor_2_value_for_C1C2phase_ir_rudics_sbd2(a_phaseCounts)
%
% INPUT PARAMETERS :
%   a_phaseCounts : input C1 or C2 phase counts
%
% OUTPUT PARAMETERS :
%   o_phaseValues : output C1 or C2 phase counts
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseValues] = sensor_2_value_for_C1C2phase_ir_rudics_sbd2(a_phaseCounts)

% output parameters initialization
o_phaseValues = [];

% default values
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_oxyPhaseDef;

% convert counts to values
o_phaseValues = a_phaseCounts;
idDef = find(a_phaseCounts == g_decArgo_oxyPhaseCountsDef);
o_phaseValues(idDef) = ones(length(idDef), 1)*g_decArgo_oxyPhaseDef;
idNoDef = find(a_phaseCounts ~= g_decArgo_oxyPhaseCountsDef);
o_phaseValues(idNoDef) = o_phaseValues(idNoDef)/1000;

return;
