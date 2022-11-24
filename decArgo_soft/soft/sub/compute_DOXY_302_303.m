% ------------------------------------------------------------------------------
% Compute DOXY from DPHASE_DOXY.
% The method used is the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_302_303( ...
%    a_DPHASE_DOXY, a_TEMP, ...
%    a_DPHASE_DOXY_fill_value, a_TEMP_fill_value, ...
%    a_DOXY_fill_value, ...
%    a_ctdData, ...
%    a_PRES_fill_value, a_PSAL_fill_value, ...
%    a_profOptode)
%
% INPUT PARAMETERS :
%   a_DPHASE_DOXY            : input DPHASE_DOXY data
%   a_TEMP                   : input TEMP data
%   a_DPHASE_DOXY_fill_value : fill value for input DPHASE_DOXY data
%   a_TEMP_fill_value        : fill value for input TEMP data
%   a_DOXY_fill_value        : fill value for output DOXY data
%   a_ctdData                : ascociated CTD (P, S) data
%   a_PRES_fill_value        : fill value for input PRES data
%   a_PSAL_fill_value        : fill value for input PSAL data
%   a_profOptode             : OPTODE profile structure
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
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_DOXY_302_303( ...
   a_DPHASE_DOXY, a_TEMP, ...
   a_DPHASE_DOXY_fill_value, a_TEMP_fill_value, ...
   a_DOXY_fill_value, ...
   a_ctdData, ...
   a_PRES_fill_value, a_PSAL_fill_value, ...
   a_profOptode)

% output parameters initialization
o_DOXY = ones(length(a_DPHASE_DOXY), 1)*a_DOXY_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_DPHASE_DOXY) || isempty(a_TEMP))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY calibration coefficients are missing => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber, ...
      a_profOptode.direction);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
   % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
else
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: inconsistent DOXY calibration coefficients => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber, ...
      a_profOptode.direction);
   return;
end

idDef = find( ...
   (a_DPHASE_DOXY == a_DPHASE_DOXY_fill_value) | ...
   (a_TEMP == a_TEMP_fill_value) | ...
   (a_ctdData(:, 1) == a_PRES_fill_value) | ...
   (a_ctdData(:, 2) == a_PSAL_fill_value));
idNoDef = setdiff([1:length(a_DPHASE_DOXY)], idDef);

if (~isempty(idNoDef))
   dPhaseDoxyValues = a_DPHASE_DOXY(idNoDef);
   tempDoxyValues = a_TEMP(idNoDef);
   presValues = a_ctdData(idNoDef, 1);
   psalValues = a_ctdData(idNoDef, 2);
   
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830(dPhaseDoxyValues, tempDoxyValues, ...
      'aanderaa', tabDoxyCoef);
   
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
   
   o_DOXY(idNoDef) = oxyValues;
end

return;
