% ------------------------------------------------------------------------------
% Compute DOXY from C1PHASE_DOXY and C2PHASE_DOXY using TEMP_DOXY provided by
% the OPTODE SENSOR.
% The method used is the Stern-Volmer equation.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_107_109( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, a_TEMP_DOXY_fill_value, ...
%    a_DOXY_fill_value, ...
%    a_ctdData, ...
%    a_PRES_fill_value, a_PSAL_fill_value, ...
%    a_profOptode)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY            : input C1PHASE_DOXY data
%   a_C2PHASE_DOXY            : input C2PHASE_DOXY data
%   a_TEMP_DOXY               : input TEMP_DOXY data
%   a_C1PHASE_DOXY_fill_value : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fill_value : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fill_value    : fill value for input TEMP_DOXY data
%   a_DOXY_fill_value         : fill value for output DOXY data
%   a_ctdData                 : ascociated CTD (P, S) data
%   a_PRES_fill_value         : fill value for input PRES data
%   a_PSAL_fill_value         : fill value for input PSAL data
%   a_profOptode              : OPTODE profile structure
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
%   06/24/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_DOXY_107_109( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fill_value, a_C2PHASE_DOXY_fill_value, a_TEMP_DOXY_fill_value, ...
   a_DOXY_fill_value, ...
   a_ctdData, ...
   a_PRES_fill_value, a_PSAL_fill_value, ...
   a_profOptode)

% output parameters initialization
o_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_DOXY_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_C1PHASE_DOXY) || isempty(a_C2PHASE_DOXY) || isempty(a_TEMP_DOXY))
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
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 7
   if (~isempty(find((size(tabDoxyCoef) == [1 7]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d Profile #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
         g_decArgo_floatNum, ...
         a_profOptode.cycleNumber, ...
         a_profOptode.profileNumber, ...
         a_profOptode.direction);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: inconsistent DOXY calibration coefficients => DOXY data set to fill value in ''%c'' profile of OPTODE sensor\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber, ...
      a_profOptode.direction);
   return;
end

idDef = find( ...
   (a_C1PHASE_DOXY == a_C1PHASE_DOXY_fill_value) | ...
   (a_C2PHASE_DOXY == a_C2PHASE_DOXY_fill_value) | ...
   (a_TEMP_DOXY == a_TEMP_DOXY_fill_value) | ...
   (a_ctdData(:, 1) == a_PRES_fill_value) | ...
   (a_ctdData(:, 2) == a_PSAL_fill_value));
idNoDef = setdiff([1:length(a_C1PHASE_DOXY)], idDef);

if (~isempty(idNoDef))
   c1PaseDoxyValues = a_C1PHASE_DOXY(idNoDef);
   c2PaseDoxyValues = a_C2PHASE_DOXY(idNoDef);
   tempDoxyValues = a_TEMP_DOXY(idNoDef);
   presValues = a_ctdData(idNoDef, 1);
   psalValues = a_ctdData(idNoDef, 2);
   
   tPhaseDoxyValues = c1PaseDoxyValues - c2PaseDoxyValues;
   
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
   
   o_DOXY(idNoDef) = oxyValues;
end

return;
