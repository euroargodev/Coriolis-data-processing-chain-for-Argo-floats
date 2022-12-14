% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (TPHASE_DOXY) using the Stern-Volmer equation.
%
% SYNTAX :
% [o_doxyValues] = compute_DOXY_27_32(a_tPhaseDoxyValues, ...
%    a_presValues, a_tempValues, a_psalValues)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxyValues : oxygen sensor measurements
%   a_presValues       : pressure measurement values
%   a_tempValues       : temperature measurement values
%   a_psalValues       : salinity measurement values
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
function [o_doxyValues] = compute_DOXY_27_32(a_tPhaseDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_tPhaseDoxyCountsDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

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

% output parameters initialization
o_doxyValues = ones(length(a_tPhaseDoxyValues), 1)*g_decArgo_doxyDef;


if (isempty(a_tPhaseDoxyValues))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7
   if (~isempty(find((size(tabDoxyCoef) == [2 7]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent DOXY calibration coefficients\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

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
   [measLon, measLat] = get_meas_location(g_decArgo_cycleNum, -1, '');
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, measLon, measLat);
   rho = rho/1000;
   
   oxyValues = oxygenPresComp ./ rho;
   idNoNan = find(~isnan(oxyValues));
   
   o_doxyValues(idNoDef(idNoNan)) = oxyValues(idNoNan);
end

return
