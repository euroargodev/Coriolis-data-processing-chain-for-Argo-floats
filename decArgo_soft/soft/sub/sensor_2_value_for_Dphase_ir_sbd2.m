% ------------------------------------------------------------------------------
% Convert sensor counts values for D phase.
%
% SYNTAX :
%  [o_phaseValues] = sensor_2_value_for_Dphase_ir_sbd2(a_phaseCounts)
%
% INPUT PARAMETERS :
%   a_phaseCounts : input D phase counts
%
% OUTPUT PARAMETERS :
%   o_phaseValues : output D phase counts
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_phaseValues] = sensor_2_value_for_Dphase_ir_sbd2(a_phaseCounts)

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
