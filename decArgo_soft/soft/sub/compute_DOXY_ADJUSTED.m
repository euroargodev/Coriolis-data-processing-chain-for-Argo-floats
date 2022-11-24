% ------------------------------------------------------------------------------
% Adjust DOXY measurements.
% DOXY_ADJUSTED is estimated from an adjustment of PPOX_DOXY at surface on WOA
% climatology.
%
% SYNTAX :
%  [o_DOXY_ADJUSTED] = compute_DOXY_ADJUSTED( ...
%    a_PRES, a_TEMP, a_PSAL, a_DOXY, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, a_DOXY_fillValue, ...
%    a_slope, a_offset)   
%
% INPUT PARAMETERS :
%   a_PRES           : input PRES data
%   a_TEMP           : input TEMP data
%   a_PSAL           : input PSAL data
%   a_DOXY           : input DOXY data
%   a_PRES_fillValue : fill value for input PRES data
%   a_TEMP_fillValue : fill value for input TEMP data
%   a_PSAL_fillValue : fill value for input PSAL data
%   a_DOXY_fillValue : fill value for input DOXY data
%   a_DOXY_fillValue : fill value for input DOXY data
%   a_slope          : slope of PPOX_DOXY adjustment
%   a_offset         : slope of PPOX_DOXY adjustment
%
% OUTPUT PARAMETERS :
%   o_DOXY_ADJUSTED : output DOXY adjusted data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY_ADJUSTED] = compute_DOXY_ADJUSTED( ...
   a_PRES, a_TEMP, a_PSAL, a_DOXY, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, a_DOXY_fillValue, ...
   a_slope, a_offset)   
   
% output parameters initialization
o_DOXY_ADJUSTED = ones(length(a_DOXY), 1)*a_DOXY_fillValue;

% retrieve global coefficient default values
global g_decArgo_doxy_202_205_304_d0;
global g_decArgo_doxy_202_205_304_d1;
global g_decArgo_doxy_202_205_304_d2;
global g_decArgo_doxy_202_205_304_d3;
global g_decArgo_doxy_202_205_304_b0;
global g_decArgo_doxy_202_205_304_b1;
global g_decArgo_doxy_202_205_304_b2;
global g_decArgo_doxy_202_205_304_b3;
global g_decArgo_doxy_202_205_304_c0;
global g_decArgo_doxy_202_205_304_pCoef2;
global g_decArgo_doxy_202_205_304_pCoef3;


if (isempty(a_PRES) || isempty(a_TEMP) || isempty(a_PSAL) || isempty(a_DOXY))
   return
end

idDef = find( ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PSAL == a_PSAL_fillValue) | ...
   (a_DOXY == a_DOXY_fillValue));
idNoDef = setdiff(1:length(a_DOXY), idDef);

if (~isempty(idNoDef))
   
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = a_PSAL(idNoDef);
   doxyValues = a_DOXY(idNoDef);

   % convert DOXY into DOXY_in_molar_units
   % units convertion (micromol/kg to micromol/L)
   rho = potential_density(presValues, tempValues, psalValues);
   molarDoxyValues = doxyValues .* rho;

   % pressure effect un-correction: 
   % at presValue, optode quenched by different pO2 inside membrane than pO2
   % outside in seawater due to re-equilibration effect
   % translate already corrected value (outside conditions) back to sensed value
   % (inside membrane)
   oxygenPresUncomp = calcoxy_presuncomp(molarDoxyValues, presValues, tempValues, ...
      g_decArgo_doxy_202_205_304_pCoef2, ...
      g_decArgo_doxy_202_205_304_pCoef3 ...
      );

   % convert DOXY_in_molar_units_and_inside_conditions into PPOX_DOXY 
   % units convertion (micromol/L to hPa)
   ppoxDoxyValues = O2ctoO2p(oxygenPresUncomp, tempValues, psalValues, presValues, ...
      g_decArgo_doxy_202_205_304_d0, ...
      g_decArgo_doxy_202_205_304_d1, ...
      g_decArgo_doxy_202_205_304_d2, ...
      g_decArgo_doxy_202_205_304_d3, ...
      g_decArgo_doxy_202_205_304_b0, ...
      g_decArgo_doxy_202_205_304_b1, ...
      g_decArgo_doxy_202_205_304_b2, ...
      g_decArgo_doxy_202_205_304_b3, ...
      g_decArgo_doxy_202_205_304_c0 ...
      );
   
   % adjust PPOX_DOXY
   ppoxDoxyAdjValues = ppoxDoxyValues * a_slope + a_offset;
   
   % convert PPOX_ADJUSTED into DOXY_ADJUSTED_in_molar_units_and_inside_conditions 
   % units convertion (hPa to micromol/L)
   oxygenAdjPresUncomp = O2ptoO2c(ppoxDoxyAdjValues, tempValues, psalValues, presValues, ...
      g_decArgo_doxy_202_205_304_d0, ...
      g_decArgo_doxy_202_205_304_d1, ...
      g_decArgo_doxy_202_205_304_d2, ...
      g_decArgo_doxy_202_205_304_d3, ...
      g_decArgo_doxy_202_205_304_b0, ...
      g_decArgo_doxy_202_205_304_b1, ...
      g_decArgo_doxy_202_205_304_b2, ...
      g_decArgo_doxy_202_205_304_b3, ...
      g_decArgo_doxy_202_205_304_c0 ...
      );

   % pressure effect re-correction: 
   % at presValue, optode quenched by different pO2 inside membrane than pO2
   % outside in seawater due to re-equilibration effect
   % translate adjusted sensed value (inside membrane) to adjusted corrected
   % value (outside conditions)
   molarDoxyAdjValues  = calcoxy_prescomp(oxygenAdjPresUncomp, presValues, tempValues, ...
      g_decArgo_doxy_202_205_304_pCoef2, ...
      g_decArgo_doxy_202_205_304_pCoef3 ...
      );

   % convert DOXY_ADJUSTED_in_molar_units into DOXY 
   % units convertion (micromol/L to micromol/kg)
   doxyAdjValues = molarDoxyAdjValues ./ rho;

   o_DOXY_ADJUSTED(idNoDef) = doxyAdjValues;
end

return
