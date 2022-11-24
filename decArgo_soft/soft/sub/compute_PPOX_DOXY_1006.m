% ------------------------------------------------------------------------------
% Compute PPOX_DOXY from BPHASE_DOXY for a AANDERAA 3830 optode.
%
% SYNTAX :
%  [o_PPOX_DOXY] = compute_PPOX_DOXY_1006( ...
%    a_pres, a_bPhaseDoxy, a_tempDoxy, ...
%    a_pres_fill_value, ...
%    a_bPhaseDoxy_fill_value, a_tempDoxy_fill_value, a_doxy_fill_value)
%
% INPUT PARAMETERS :
%   a_pres                  : input PRES data
%   a_bPhaseDoxy            : input BPHASE_DOXY data
%   a_tempDoxy              : input TEMP_DOXY data
%   a_pres_fill_value       : PRES fill value
%   a_bPhaseDoxy_fill_value : BPHASE_DOXY fill value
%   a_tempDoxy_fill_value   : TEMP_DOXY fill value
%   a_doxy_fill_value       : DOXY fill value
%
% OUTPUT PARAMETERS :
%   o_PPOX_DOXY : output PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/26/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PPOX_DOXY] = compute_PPOX_DOXY_1006( ...
   a_pres, a_bPhaseDoxy, a_tempDoxy, ...
   a_pres_fill_value, ...
   a_bPhaseDoxy_fill_value, a_tempDoxy_fill_value, a_doxy_fill_value)

% output parameters initialization
o_PPOX_DOXY = ones(length(a_bPhaseDoxy), 1)*a_doxy_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_bPhaseDoxy) || isempty(a_tempDoxy))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && ...
      (isfield(g_decArgo_calibInfo.OPTODE, 'TabPhaseCoef')) && ...
      (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabPhaseCoef = g_decArgo_calibInfo.OPTODE.TabPhaseCoef;
   % the size of the tabPhaseCoef should be: size(tabDoxyCoef) = 1 4 for the
   % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
   % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_pres == a_pres_fill_value) | ...
   (a_bPhaseDoxy == a_bPhaseDoxy_fill_value) | ...
   (a_tempDoxy == a_tempDoxy_fill_value));
idNoDef = setdiff([1:length(a_bPhaseDoxy)], idDef);

if (~isempty(idNoDef))
   
   presValues = a_pres(idNoDef);
   bPhaseDoxyValues = a_bPhaseDoxy(idNoDef);
   tempDoxyValues = a_tempDoxy(idNoDef);
   
   % compute DPHASE_DOXY
   rPhaseDoxy = 0;
   uncalPhase = bPhaseDoxyValues - rPhaseDoxy;
   dPhaseDoxyValues = tabPhaseCoef(1) + tabPhaseCoef(2).*uncalPhase + ...
      tabPhaseCoef(3).*uncalPhase.^2 + tabPhaseCoef(3).*uncalPhase.^3;
   
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830(dPhaseDoxyValues, tempDoxyValues, ...
      'aanderaa', tabDoxyCoef);
   
   % compute PPOX_DOXY
   psalValues = zeros(length(a_bPhaseDoxy), 1);
   ppoxDoxyValues = O2ctoO2p(molarDoxyValues, tempDoxyValues, psalValues, presValues);
   
   o_PPOX_DOXY(idNoDef) = ppoxDoxyValues;
end

return;
