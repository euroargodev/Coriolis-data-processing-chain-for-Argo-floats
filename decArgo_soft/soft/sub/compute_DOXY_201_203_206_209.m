% ------------------------------------------------------------------------------
% Compute DOXY from C1PHASE_DOXY and C2PHASE_DOXY using TEMP_DOXY provided by
% the OPTODE SENSOR.
% The method used is the Stern-Volmer equation.
%
% SYNTAX :
%  [o_doxyValues] = compute_DOXY_201_203_206_209( ...
%    a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, ...
%    a_presValues, a_psalValues)
%
% INPUT PARAMETERS :
%   a_c1PhaseDoxyValues : input C1PHASE_DOXY data
%   a_c2PhaseDoxyValues : input C2PHASE_DOXY data
%   a_tempDoxyValues    : input TEMP_DOXY data
%   a_presValues        : input PRES data
%   a_psalValues        : input PSAL data
%
% OUTPUT PARAMETERS :
%   o_doxyValues : output DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_201_203_206_209( ...
   a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, ...
   a_presValues, a_psalValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;
global g_decArgo_salDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% output parameters initialization
o_doxyValues = ones(length(a_c1PhaseDoxyValues), 1)*g_decArgo_doxyDef;


if (isempty(a_c1PhaseDoxyValues) || isempty(a_c2PhaseDoxyValues) || isempty(a_tempDoxyValues))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 7
   if (~isempty(find((size(tabDoxyCoef) == [1 7]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_c1PhaseDoxyValues == g_decArgo_c1C2PhaseDoxyDef) | ...
   (a_c2PhaseDoxyValues == g_decArgo_c1C2PhaseDoxyDef) | ...
   (a_tempDoxyValues == g_decArgo_tempDoxyDef) | ...
   (a_presValues == g_decArgo_presDef) | ...
   (a_psalValues == g_decArgo_salDef));
idNoDef = setdiff([1:length(o_doxyValues)], idDef);

if (~isempty(idNoDef))
   
   tPhaseDoxyValues = a_c1PhaseDoxyValues(idNoDef) - a_c2PhaseDoxyValues(idNoDef);
   tempDoxyValues = a_tempDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   psalValues = a_psalValues(idNoDef);

   % compute MOLAR_DOXY from TPHASE_DOXY using the Stern-Volmer equation
   S0 = 0; % not used in the Stern-Volmer equation
   molarDoxyValues = calcoxy_aanderaa4330(tPhaseDoxyValues, tempDoxyValues, ...
      'sternvolmer', tabDoxyCoef, S0);
   
   % salinity effect correction
   Sref = 0;
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, psalValues, tempDoxyValues, Sref);

   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues);
   
   % compute potential temperature and potential density
   tpot = tetai(presValues, tempDoxyValues, psalValues, 0);
   [~, sigma0] = swstat90(psalValues, tpot, 0);
   rho = (sigma0+1000)/1000;
   
   % units convertion (micromol/L to micromol/kg)
   oxyValues = oxygenPresComp ./ rho;
   
   o_doxyValues(idNoDef) = oxyValues;
end

return;
