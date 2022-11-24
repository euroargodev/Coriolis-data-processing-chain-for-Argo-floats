% ------------------------------------------------------------------------------
% Compute oxygen partial pressure measurements (PPOX_DOXY) from oxygen sensor
% measurements (C1PHASE_DOXY and C2PHASE_DOXY) using the Aanderaa standard
% calibration + an additional two-point adjustment.
%
% SYNTAX :
%  [o_PPOX_DOXY] = compute_PPOX_DOXY_123( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, ...
%    a_PRES_fillValue, ...
%    a_PPOX_DOXY_fillValue, a_profOptode)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY           : input C1PHASE_DOXY optode data
%   a_C2PHASE_DOXY           : input C2PHASE_DOXY optode data
%   a_TEMP_DOXY              : input TEMP_DOXY optode data
%   a_C1PHASE_DOXY_fillValue : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fillValue : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fillValue    : fill value for input TEMP_DOXY data
%   a_PRES                   : input PRES CTD data
%   a_PRES_fillValue         : fill value for input PRES data
%   a_PPOX_DOXY_fillValue    : fill value for output PPOX_DOXY data
%   a_profOptode             : OPTODE profile structure
%
% OUTPUT PARAMETERS :
%   o_PPOX_DOXY : output PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PPOX_DOXY] = compute_PPOX_DOXY_123( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, ...
   a_PRES_fillValue, ...
   a_PPOX_DOXY_fillValue, a_profOptode)

% output parameters initialization
o_PPOX_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_PPOX_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_202_205_303_a0;
global g_decArgo_doxy_202_205_303_a1;
global g_decArgo_doxy_202_205_303_a2;
global g_decArgo_doxy_202_205_303_a3;
global g_decArgo_doxy_202_205_303_a4;
global g_decArgo_doxy_202_205_303_a5;
global g_decArgo_doxy_202_205_303_d0;
global g_decArgo_doxy_202_205_303_d1;
global g_decArgo_doxy_202_205_303_d2;
global g_decArgo_doxy_202_205_303_d3;
global g_decArgo_doxy_202_205_303_b0;
global g_decArgo_doxy_202_205_303_b1;
global g_decArgo_doxy_202_205_303_b2;
global g_decArgo_doxy_202_205_303_b3;
global g_decArgo_doxy_202_205_303_c0;
global g_decArgo_doxy_202_205_303_pCoef1;
global g_decArgo_doxy_202_205_303_pCoef2;
global g_decArgo_doxy_202_205_303_pCoef3;


if (isempty(a_C1PHASE_DOXY) || isempty(a_C2PHASE_DOXY) || isempty(a_TEMP_DOXY))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY calibration coefficients are missing => PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 6 28 for the
   % Aanderaa standard calibration + an additional two-point adjustment
   if (~isempty(find((size(tabDoxyCoef) == [6 28]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d Profile #%d: DOXY calibration coefficients are inconsistent => PPOX_DOXY not computed\n', ...
         g_decArgo_floatNum, ...
         a_profOptode.cycleNumber, ...
         a_profOptode.profileNumber);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: inconsistent DOXY calibration coefficients => PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber);
   return;
end

idDef = find( ...
   (a_C1PHASE_DOXY == a_C1PHASE_DOXY_fillValue) | ...
   (a_C2PHASE_DOXY == a_C2PHASE_DOXY_fillValue) | ...
   (a_TEMP_DOXY == a_TEMP_DOXY_fillValue) | ...
   (a_PRES == a_PRES_fillValue));
idNoDef = setdiff(1:length(a_C1PHASE_DOXY), idDef);

if (~isempty(idNoDef))
   
   c1PaseDoxyValues = a_C1PHASE_DOXY(idNoDef);
   c2PaseDoxyValues = a_C2PHASE_DOXY(idNoDef);
   tempDoxyValues = a_TEMP_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   psalValues = zeros(size(presValues));
   
   tPhaseDoxyValues = c1PaseDoxyValues - c2PaseDoxyValues;
   
   % compute MOLAR_DOXY from TPHASE_DOXY using the Aanderaa standard calibration
   % + an additional two-point adjustment
   molarDoxyValues = calcoxy_aanderaa4330_aanderaa( ...
      tPhaseDoxyValues, presValues, tempDoxyValues, tabDoxyCoef, ...
      g_decArgo_doxy_202_205_303_pCoef1, ...
      g_decArgo_doxy_202_205_303_a0, ...
      g_decArgo_doxy_202_205_303_a1, ...
      g_decArgo_doxy_202_205_303_a2, ...
      g_decArgo_doxy_202_205_303_a3, ...
      g_decArgo_doxy_202_205_303_a4, ...
      g_decArgo_doxy_202_205_303_a5 ...
      );

   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(molarDoxyValues, presValues, tempDoxyValues, ...
      g_decArgo_doxy_202_205_303_pCoef2, ...
      g_decArgo_doxy_202_205_303_pCoef3 ...
      );
   
   % compute PPOX_DOXY
   ppoxDoxyValues = O2ctoO2p(oxygenPresComp, tempDoxyValues, psalValues, presValues, ...
      g_decArgo_doxy_202_205_303_d0, ...
      g_decArgo_doxy_202_205_303_d1, ...
      g_decArgo_doxy_202_205_303_d2, ...
      g_decArgo_doxy_202_205_303_d3, ...
      g_decArgo_doxy_202_205_303_b0, ...
      g_decArgo_doxy_202_205_303_b1, ...
      g_decArgo_doxy_202_205_303_b2, ...
      g_decArgo_doxy_202_205_303_b3, ...
      g_decArgo_doxy_202_205_303_c0 ...
      );
   
   o_PPOX_DOXY(idNoDef) = ppoxDoxyValues;
end

return;
