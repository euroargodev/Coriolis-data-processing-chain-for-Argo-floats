% ------------------------------------------------------------------------------
% Adjust DOXY measurements.
% DOXY_ADJUSTED is estimated from an adjustment of PPOX_DOXY at surface on WOA
% climatology.
%
% SYNTAX :
%  [o_DOXY_ADJUSTED, o_DOXY_ADJUSTED_ERROR] = compute_DOXY_ADJUSTED( ...
%    a_PRES, a_TEMP, a_PSAL, a_DOXY, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, a_DOXY_fillValue, ...
%    a_slope, a_offset, a_doDrift, a_doInclineT, a_launchDate, a_adjError, a_adjDate, a_profOptode)   
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
%   a_doDrift        : drift to be used for PPOX_DOXY adjustment
%   a_doInclineT     : incline_t to be used for PPOX_DOXY adjustment
%   a_launchDate     : float launch date
%   a_adjError       : error on PPOX_DOXY adjusted values
%   a_adjDate        : start date to apply adjustment
%   a_profOptode     : OPTODE profile structure
%
% OUTPUT PARAMETERS :
%   o_DOXY_ADJUSTED       : output DOXY adjusted data
%   o_DOXY_ADJUSTED_ERROR : output error on DOXY adjusted data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY_ADJUSTED, o_DOXY_ADJUSTED_ERROR] = compute_DOXY_ADJUSTED( ...
   a_PRES, a_TEMP, a_PSAL, a_DOXY, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, a_DOXY_fillValue, ...
   a_slope, a_offset, a_doDrift, a_doInclineT, a_launchDate, a_adjError, a_adjDate, a_profOptode)   
   
% output parameters initialization
o_DOXY_ADJUSTED = ones(length(a_DOXY), 1)*a_DOXY_fillValue;
if (~isnan(a_adjError))
   o_DOXY_ADJUSTED_ERROR = ones(length(a_DOXY), 1)*a_DOXY_fillValue;
else
   o_DOXY_ADJUSTED_ERROR = [];
end

% current float WMO number
global g_decArgo_floatNum;

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

% global default values
global g_decArgo_dateDef;


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
   [measLon, measLat] = get_meas_location(a_profOptode.cycleNumber, a_profOptode.profileNumber, a_profOptode);
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, measLon, measLat);
   rho = rho/1000;
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
   
   if (a_profOptode.date ~= g_decArgo_dateDef)      
      ppoxDoxyAdjValues = (a_slope * (1 + a_doDrift/100 * (a_profOptode.date-a_launchDate)/365) + a_doInclineT*tempValues) .* (ppoxDoxyValues + a_offset);
   else
      fprintf('WARNING: Float #%d Cycle #%d%c: profile is not dated - DOXY_ADJUSTED set to FillValue\n', ...
         g_decArgo_floatNum, ...
         a_profOptode.outputCycleNumber, a_profOptode.direction);
   end
   
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

   % convert DOXY_ADJUSTED_in_molar_units into DOXY_ADJUSTED
   % units convertion (micromol/L to micromol/kg)
   doxyAdjValues = molarDoxyAdjValues ./ rho;
   
   o_DOXY_ADJUSTED(idNoDef) = doxyAdjValues;
   
   % compute DOXY_ADJUSTED_ERROR

   if (~isnan(a_adjError))
      
      % use PPOX_DOXY_ADJUSTED_ERROR from META-DATA
      ppoxDoxyAdjErrValues = a_adjError;
      
      % increase PPOX_DOXY_ADJUSTED_ERROR with time (1 mbar/year)
      if (~isempty(a_adjDate))
         ppoxDoxyAdjErrValues = ppoxDoxyAdjErrValues + (a_profOptode.date - a_adjDate)/365;
      end
      
      % convert PPOX_ADJUSTED_ERROR into DOXY_ADJUSTED_ERROR_in_molar_units_and_inside_conditions
      % units convertion (hPa to micromol/L)
      oxygenAdjErrPresUncomp = O2ptoO2c(ppoxDoxyAdjErrValues, tempValues, psalValues, presValues, ...
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
      molarDoxyAdjErrValues  = calcoxy_prescomp(oxygenAdjErrPresUncomp, presValues, tempValues, ...
         g_decArgo_doxy_202_205_304_pCoef2, ...
         g_decArgo_doxy_202_205_304_pCoef3 ...
         );
      
      % convert DOXY_ADJUSTED_ERROR_in_molar_units into DOXY_ADJUSTED_ERROR
      % units convertion (micromol/L to micromol/kg)
      doxyAdjErrValues = molarDoxyAdjErrValues ./ rho;
      
      o_DOXY_ADJUSTED_ERROR(idNoDef) = doxyAdjErrValues;
   end
end

return
