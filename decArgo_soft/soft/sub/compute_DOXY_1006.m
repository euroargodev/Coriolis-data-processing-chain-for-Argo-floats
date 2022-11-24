% ------------------------------------------------------------------------------
% Compute DOXY from BPHASE_DOXY for a AANDERAA 3830 optode.
% The method used is the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_1006( ...
%    a_pres, a_temp, a_psal, a_bPhaseDoxy, a_tempDoxy, ...
%    a_pres_fill_value, a_temp_fill_value, a_psal_fill_value, ...
%    a_bPhaseDoxy_fill_value, a_tempDoxy_fill_value, a_doxy_fill_value)
%
% INPUT PARAMETERS :
%   a_pres                  : input PRES data
%   a_temp                  : input TEMP data
%   a_psal                  : input PSAL data
%   a_bPhaseDoxy            : input BPHASE_DOXY data
%   a_tempDoxy              : input TEMP_DOXY data
%   a_pres_fill_value       : PRES fill value
%   a_temp_fill_value       : TEMP fill value
%   a_psal_fill_value       : PSAL fill value
%   a_bPhaseDoxy_fill_value : BPHASE_DOXY fill value
%   a_tempDoxy_fill_value   : TEMP_DOXY fill value
%   a_doxy_fill_value       : DOXY fill value
%
% OUTPUT PARAMETERS :
%   o_DOXY : output DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_DOXY_1006( ...
   a_pres, a_temp, a_psal, a_bPhaseDoxy, a_tempDoxy, ...
   a_pres_fill_value, a_temp_fill_value, a_psal_fill_value, ...
   a_bPhaseDoxy_fill_value, a_tempDoxy_fill_value, a_doxy_fill_value)

% output parameters initialization
o_DOXY = ones(length(a_bPhaseDoxy), 1)*a_doxy_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_bPhaseDoxy) || isempty(a_temp))
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
   (a_bPhaseDoxy == a_bPhaseDoxy_fill_value) | ...
   (a_temp == a_temp_fill_value) | ...
   (a_pres == a_pres_fill_value) | ...
   (a_psal == a_psal_fill_value));
idNoDef = setdiff([1:length(a_bPhaseDoxy)], idDef);

if (~isempty(idNoDef))
   
   bPhaseDoxyValues = a_bPhaseDoxy(idNoDef);
   tempValues = a_temp(idNoDef);
   presValues = a_pres(idNoDef);
   psalValues = a_psal(idNoDef);
   
   % compute DPHASE_DOXY
   rPhaseDoxy = 0;
   uncalPhase = bPhaseDoxyValues - rPhaseDoxy;
   dPhaseDoxyValues = tabPhaseCoef(1) + tabPhaseCoef(2).*uncalPhase + ...
      tabPhaseCoef(3).*uncalPhase.^2 + tabPhaseCoef(3).*uncalPhase.^3;
   
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830(dPhaseDoxyValues, tempValues, ...
      'aanderaa', tabDoxyCoef);
   
   % salinity effect correction
   Sref = 0;
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, psalValues, tempValues, Sref);
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues);
   
   % compute potential temperature and potential density
   tpot = tetai(presValues, tempValues, psalValues, 0);
   [~, sigma0] = swstat90(psalValues, tpot, 0);
   rho = (sigma0+1000)/1000;
   
   % units convertion (micromol/L to micromol/kg)
   oxyValues = oxygenPresComp ./ rho;
   
   o_DOXY(idNoDef) = oxyValues;
end

return;
