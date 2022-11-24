% ------------------------------------------------------------------------------
% Convert oxygen sensor measurements (TPHASE_DOXY) to dissolved oxygen
% measurements (DOXY) using the Stern-Volmer equation.
%
% SYNTAX :
% [o_doxyValues] = compute_DOXY_27(a_tPhaseDoxyValues, ...
%    a_presValues, a_tempValues, a_salValues)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxyValues : oxygen sensor measurements
%   a_presValues       : pressure measurement values
%   a_tempValues       : temperature measurement values
%   a_salValues        : salinity measurement values
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
function [o_doxyValues] = compute_DOXY_27(a_tPhaseDoxyValues, ...
   a_presValues, a_tempValues, a_salValues)

% output parameters initialization
o_doxyValues = [];

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

% 07/07/2011 C.Lagadec/J.P.Rannou (needed on Linux platform?)
if isempty(a_tPhaseDoxyValues)
   return;
end


% convert MOLAR_DOXY to DOXY
o_doxyValues = ones(length(a_tPhaseDoxyValues), 1)*g_decArgo_doxyDef;
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 7
   if (~isempty(find((size(tabDoxyCoef) == [1 7]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent DOXY calibration coefficients\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_tPhaseDoxyValues == g_decArgo_tPhaseDoxyCountsDef) | ...
   (a_presValues == g_decArgo_presDef) | ...
   (a_tempValues == g_decArgo_tempDef) | ...
   (a_salValues == g_decArgo_salDef));
idNoDef = setdiff([1:length(o_doxyValues)], idDef);

tPhaseDoxyValues = a_tPhaseDoxyValues(idNoDef);
presValues = a_presValues(idNoDef);
tempValues = a_tempValues(idNoDef);
salValues = a_salValues(idNoDef);

% compute MOLAR_DOXY from TPHASE_DOXY using the Stern-Volmer equation
S0 = 0; % not used in the Stern-Volmer equation
molarDoxyValues = calcoxy_aanderaa4330(tPhaseDoxyValues, tempValues, ...
   'sternvolmer', tabDoxyCoef, S0);

% salinity effect correction
Sref = 0;
oxygenSalComp = calcoxy_salcomp(molarDoxyValues, salValues, tempValues, Sref);

% pressure effect correction
oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues);

% compute potential temperature and potential density
tpot = tetai(presValues, tempValues, salValues, 0);
[null, sigma0] = swstat90(salValues, tpot, 0);
rho = (sigma0+1000)/1000;

% units convertion (micromol/L to micromol/kg)
oxyValues = oxygenPresComp ./ rho;

o_doxyValues(idNoDef) = oxyValues;

return;
