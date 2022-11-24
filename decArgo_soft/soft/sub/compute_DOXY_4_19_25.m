% ------------------------------------------------------------------------------
% Convert oxygen sensor measurements (MOLAR_DOXY) to dissolved oxygen
% measurements (DOXY).
%
% SYNTAX :
% [o_doxyValues] = compute_DOXY_4_19_25(a_molarDoxyValues, ...
%    a_presValues, a_tempValues, a_salValues)
%
% INPUT PARAMETERS :
%   a_molarDoxyValues : oxygen sensor measurements
%   a_presValues      : pressure measurement values
%   a_tempValues      : temperature measurement values
%   a_salValues       : salinity measurement values
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
%   05/20/2011 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_4_19_25(a_molarDoxyValues, ...
   a_presValues, a_tempValues, a_salValues)

% output parameters initialization
o_doxyValues = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_molarDoxyCountsDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% 07/07/2011 C.Lagadec/J.P.Rannou (needed on Linux platform?)
if isempty(a_molarDoxyValues)
   return;
end


% convert MOLAR_DOXY to DOXY
o_doxyValues = ones(length(a_molarDoxyValues), 1)*g_decArgo_doxyDef;
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration reference salinity is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'DoxyCalibRefSalinity')))
   doxyCalibRefSalinity = g_decArgo_calibInfo.OPTODE.DoxyCalibRefSalinity;
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent DOXY calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_molarDoxyValues == g_decArgo_molarDoxyCountsDef) | ...
   (a_presValues == g_decArgo_presDef) | ...
   (a_tempValues == g_decArgo_tempDef) | ...
   (a_salValues == g_decArgo_salDef));
idNoDef = setdiff([1:length(o_doxyValues)], idDef);

molarDoxyValues = a_molarDoxyValues(idNoDef);
presValues = a_presValues(idNoDef);
tempValues = a_tempValues(idNoDef);
salValues = a_salValues(idNoDef);

% salinity effect correction
oxygenSalComp = calcoxy_salcomp(molarDoxyValues, salValues, tempValues, doxyCalibRefSalinity);

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
