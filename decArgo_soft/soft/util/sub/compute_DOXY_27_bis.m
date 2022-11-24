% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (TPHASE_DOXY) using the Stern-Volmer equation.
%
% SYNTAX :
% [o_doxyValues] = compute_DOXY_27_bis(a_tPhaseDoxyValues, ...
%    a_presValues, a_tempValues, a_salValues, a_tabDoxyCoef)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxyValues : oxygen sensor measurements
%   a_presValues       : pressure measurement values
%   a_tempValues       : temperature measurement values
%   a_salValues        : salinity measurement values
%   a_tabDoxyCoef      : calibration coefficients (size(a_tabDoxyCoef) = [1 7])
%
% OUTPUT PARAMETERS :
%   o_doxyValues : dissolved oxygen values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_27_bis(a_tPhaseDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues, a_tabDoxyCoef)

% output parameters initialization
o_doxyValues = [];

% default values
global g_decArgo_tPhaseDoxyCountsDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;

% retrieve global coefficient default values
global g_decArgo_doxy_202_204_204_d0;
global g_decArgo_doxy_202_204_204_d1;
global g_decArgo_doxy_202_204_204_d2;
global g_decArgo_doxy_202_204_204_d3;
global g_decArgo_doxy_202_204_204_sPreset;
global g_decArgo_doxy_202_204_204_b0;
global g_decArgo_doxy_202_204_204_b1;
global g_decArgo_doxy_202_204_204_b2;
global g_decArgo_doxy_202_204_204_b3;
global g_decArgo_doxy_202_204_204_c0;
global g_decArgo_doxy_202_204_204_pCoef1;
global g_decArgo_doxy_202_204_204_pCoef2;
global g_decArgo_doxy_202_204_204_pCoef3;

% 07/07/2011 C.Lagadec/J.P.Rannou (needed on Linux platform?)
if isempty(a_tPhaseDoxyValues)
   return;
end

o_doxyValues = ones(length(a_tPhaseDoxyValues), 1)*g_decArgo_doxyDef;

tabDoxyCoef = a_tabDoxyCoef;

idDef = find( ...
   (a_tPhaseDoxyValues == g_decArgo_tPhaseDoxyCountsDef) | ...
   (a_presValues == g_decArgo_presDef) | ...
   (a_tempValues == g_decArgo_tempDef) | ...
   (a_psalValues == g_decArgo_salDef));
idNoDef = setdiff(1:length(o_doxyValues), idDef);

if (~isempty(idNoDef))
   tPhaseDoxyValues = a_tPhaseDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   
   % compute MOLAR_DOXY from TPHASE_DOXY using the Stern-Volmer equation
   molarDoxyValues = calcoxy_aanderaa4330_sternvolmer( ...
      tPhaseDoxyValues, presValues, tempValues, tabDoxyCoef, ...
      g_decArgo_doxy_202_204_204_pCoef1);
   
   % salinity effect correction
   sRef = 0; % not considered since a PHASE_DOXY is transmitted
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, sRef, ...
      g_decArgo_doxy_202_204_204_d0, ...
      g_decArgo_doxy_202_204_204_d1, ...
      g_decArgo_doxy_202_204_204_d2, ...
      g_decArgo_doxy_202_204_204_d3, ...
      g_decArgo_doxy_202_204_204_sPreset, ...
      g_decArgo_doxy_202_204_204_b0, ...
      g_decArgo_doxy_202_204_204_b1, ...
      g_decArgo_doxy_202_204_204_b2, ...
      g_decArgo_doxy_202_204_204_b3, ...
      g_decArgo_doxy_202_204_204_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decArgo_doxy_202_204_204_pCoef2, ...
      g_decArgo_doxy_202_204_204_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density(presValues, tempValues, psalValues);
   oxyValues = oxygenPresComp ./ rho;
   
   o_doxyValues(idNoDef) = oxyValues;
end

return;
