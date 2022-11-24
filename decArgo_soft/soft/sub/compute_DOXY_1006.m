% ------------------------------------------------------------------------------
% Compute DOXY from BPHASE_DOXY for a AANDERAA 3830 optode.
% The method used is the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_1006( ...
%    a_BPHASE_DOXY, a_TEMP_DOXY, ...
%    a_BPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, a_TEMP, a_PSAL, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_DOXY_fillValue)
%
% INPUT PARAMETERS :
%   a_BPHASE_DOXY           : input BPHASE_DOXY data
%   a_TEMP_DOXY             : input TEMP_DOXY data
%   a_BPHASE_DOXY_fillValue : BPHASE_DOXY fill value
%   a_TEMP_DOXY_fillValue   : TEMP_DOXY fill value
%   a_PRES                  : input PRES data
%   a_TEMP                  : input TEMP data
%   a_PSAL                  : input PSAL data
%   a_PRES_fillValue        : PRES fill value
%   a_TEMP_fillValue        : TEMP fill value
%   a_PSAL_fillValue        : PSAL fill value
%   a_DOXY_fillValue        : DOXY fill value
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
   a_BPHASE_DOXY, a_TEMP_DOXY, ...
   a_BPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, a_TEMP, a_PSAL, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_DOXY_fillValue)

% output parameters initialization
o_DOXY = ones(length(a_BPHASE_DOXY), 1)*a_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_201_202_202_d0;
global g_decArgo_doxy_201_202_202_d1;
global g_decArgo_doxy_201_202_202_d2;
global g_decArgo_doxy_201_202_202_d3;
global g_decArgo_doxy_201_202_202_sPreset;
global g_decArgo_doxy_201_202_202_b0;
global g_decArgo_doxy_201_202_202_b1;
global g_decArgo_doxy_201_202_202_b2;
global g_decArgo_doxy_201_202_202_b3;
global g_decArgo_doxy_201_202_202_c0;
global g_decArgo_doxy_201_202_202_pCoef1;
global g_decArgo_doxy_201_202_202_pCoef2;
global g_decArgo_doxy_201_202_202_pCoef3;


if (isempty(a_BPHASE_DOXY))
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
   % the size of the tabPhaseCoef should be: size(tabPhaseCoef) = 1 4 for the
   % Aanderaa standard calibration (tabPhaseCoef(i) = PhaseCoefi).
   if (~isempty(find((size(tabPhaseCoef) == [1 4]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return;
   end
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
   % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
   if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_BPHASE_DOXY == a_BPHASE_DOXY_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PSAL == a_PSAL_fillValue));
idNoDef = setdiff(1:length(a_BPHASE_DOXY), idDef);

if (~isempty(idNoDef))
   
   bPhaseDoxyValues = a_BPHASE_DOXY(idNoDef);
   tempValues = a_TEMP(idNoDef);
   presValues = a_PRES(idNoDef);
   psalValues = a_PSAL(idNoDef);
   
   % compute DPHASE_DOXY
   
   phaseCoef0 = tabPhaseCoef(1);
   phaseCoef1 = tabPhaseCoef(2);
   phaseCoef2 = tabPhaseCoef(3);
   phaseCoef3 = tabPhaseCoef(4);

   rPhaseDoxy = 0; % not available from the DO sensor
   uncalPhase = bPhaseDoxyValues - rPhaseDoxy;
   phasePcorr = uncalPhase + g_decArgo_doxy_201_202_202_pCoef1 .* presValues/1000;
   dPhaseDoxyValues = phaseCoef0 + phaseCoef1.*phasePcorr + ...
      phaseCoef2.*phasePcorr.^2 + phaseCoef3.*phasePcorr.^3;
      
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830_aanderaa( ...
      dPhaseDoxyValues, presValues, tempValues, tabDoxyCoef, ...
      0 ... % the phase has already been corrected
      );
   
   % salinity effect correction
   sRef = 0; % not considered since a PHASE_DOXY is transmitted
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, sRef, ...
      g_decArgo_doxy_201_202_202_d0, ...
      g_decArgo_doxy_201_202_202_d1, ...
      g_decArgo_doxy_201_202_202_d2, ...
      g_decArgo_doxy_201_202_202_d3, ...
      g_decArgo_doxy_201_202_202_sPreset, ...
      g_decArgo_doxy_201_202_202_b0, ...
      g_decArgo_doxy_201_202_202_b1, ...
      g_decArgo_doxy_201_202_202_b2, ...
      g_decArgo_doxy_201_202_202_b3, ...
      g_decArgo_doxy_201_202_202_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decArgo_doxy_201_202_202_pCoef2, ...
      g_decArgo_doxy_201_202_202_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density(presValues, tempValues, psalValues);
   oxyValues = oxygenPresComp ./ rho;
   
   o_DOXY(idNoDef) = oxyValues;
end

return;
