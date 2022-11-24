% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (MOLAR_DOXY).
%
% SYNTAX :
% [o_doxyValues] = compute_DOXY_4_19_25(a_molarDoxyValues, ...
%    a_presValues, a_tempValues, a_psalValues)
%
% INPUT PARAMETERS :
%   a_molarDoxyValues : oxygen sensor measurements
%   a_presValues      : pressure measurement values
%   a_tempValues      : temperature measurement values
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
%   05/20/2011 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_4_19_25(a_molarDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues)

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

% retrieve global coefficient default values
global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;

% output parameters initialization
o_doxyValues = ones(length(a_molarDoxyValues), 1)*g_decArgo_doxyDef;


if (isempty(a_molarDoxyValues))
   return;
end

% get calibration information
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
   (a_psalValues == g_decArgo_salDef));
idNoDef = setdiff(1:length(o_doxyValues), idDef);

if (~isempty(idNoDef))
   molarDoxyValues = a_molarDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = a_psalValues(idNoDef);
   
   % salinity effect correction
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, doxyCalibRefSalinity, ...
      g_decArgo_doxy_201and202_201_301_d0, ...
      g_decArgo_doxy_201and202_201_301_d1, ...
      g_decArgo_doxy_201and202_201_301_d2, ...
      g_decArgo_doxy_201and202_201_301_d3, ...
      g_decArgo_doxy_201and202_201_301_sPreset, ...
      g_decArgo_doxy_201and202_201_301_b0, ...
      g_decArgo_doxy_201and202_201_301_b1, ...
      g_decArgo_doxy_201and202_201_301_b2, ...
      g_decArgo_doxy_201and202_201_301_b3, ...
      g_decArgo_doxy_201and202_201_301_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decArgo_doxy_201and202_201_301_pCoef2, ...
      g_decArgo_doxy_201and202_201_301_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density(presValues, tempValues, psalValues);
   oxyValues = oxygenPresComp ./ rho;
   
   o_doxyValues(idNoDef) = oxyValues;
end

return;
