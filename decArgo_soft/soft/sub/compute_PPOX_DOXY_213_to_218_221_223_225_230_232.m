% ------------------------------------------------------------------------------
% Compute oxygen partial pressure measurements (PPOX_DOXY) from oxygen sensor
% measurements (C1PHASE_DOXY and C2PHASE_DOXY) using the Stern-Volmer equation.
%
% SYNTAX :
%  [o_PPOX_DOXY] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
%    a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
%    a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, a_TEMP, ...
%    a_PRES_fillValue, a_TEMP_fillValue, ...
%    a_PPOX_DOXY_fillValue)
%
% INPUT PARAMETERS :
%   a_C1PHASE_DOXY           : input C1PHASE_DOXY optode data
%   a_C2PHASE_DOXY           : input C2PHASE_DOXY optode data
%   a_TEMP_DOXY              : input TEMP_DOXY optode data
%   a_C1PHASE_DOXY_fillValue : fill value for input C1PHASE_DOXY data
%   a_C2PHASE_DOXY_fillValue : fill value for input C2PHASE_DOXY data
%   a_TEMP_DOXY_fillValue    : fill value for input TEMP_DOXY data
%   a_PRES                   : input PRES CTD data
%   a_TEMP                   : input TEMP CTD data
%   a_PRES_fillValue         : fill value for input PRES data
%   a_TEMP_fillValue         : fill value for input TEMP data
%   a_PPOX_DOXY_fillValue    : fill value for output PPOX_DOXY data
%
% OUTPUT PARAMETERS :
%   o_PPOX_DOXY : output PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/02/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PPOX_DOXY] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
   a_C1PHASE_DOXY, a_C2PHASE_DOXY, a_TEMP_DOXY, ...
   a_C1PHASE_DOXY_fillValue, a_C2PHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, a_TEMP, ...
   a_PRES_fillValue, a_TEMP_fillValue, ...
   a_PPOX_DOXY_fillValue)

% output parameters initialization
o_PPOX_DOXY = ones(length(a_C1PHASE_DOXY), 1)*a_PPOX_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

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
global g_decArgo_doxy_202_205_304_pCoef1;
global g_decArgo_doxy_202_205_304_pCoef2;
global g_decArgo_doxy_202_205_304_pCoef3;


if (isempty(a_C1PHASE_DOXY) || isempty(a_C2PHASE_DOXY) || isempty(a_TEMP_DOXY))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 2 7 or 7 7 (for
   % decId 230)
   if (~isempty(find(((size(tabDoxyCoef) == [2 7]) ~= 1) & ((size(tabDoxyCoef) == [7 7]) ~= 1), 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent - PPOX_DOXY not computed\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

idDef = find( ...
   (a_C1PHASE_DOXY == a_C1PHASE_DOXY_fillValue) | ...
   (a_C2PHASE_DOXY == a_C2PHASE_DOXY_fillValue) | ...
   (a_TEMP_DOXY == a_TEMP_DOXY_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue));
idNoDef = setdiff(1:length(a_C1PHASE_DOXY), idDef);

if (~isempty(idNoDef))

   c1PaseDoxyValues = a_C1PHASE_DOXY(idNoDef);
   c2PaseDoxyValues = a_C2PHASE_DOXY(idNoDef);
   tempDoxyValues = a_TEMP_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = zeros(size(presValues));

   tPhaseDoxyValues = c1PaseDoxyValues - c2PaseDoxyValues;

   % compute MOLAR_DOXY from TPHASE_DOXY using the Stern-Volmer equation
   molarDoxyValues = calcoxy_aanderaa4330_sternvolmer( ...
      tPhaseDoxyValues, presValues, tempDoxyValues, tabDoxyCoef, ...
      g_decArgo_doxy_202_205_304_pCoef1);

   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(molarDoxyValues, presValues, tempValues, ...
      g_decArgo_doxy_202_205_304_pCoef2, ...
      g_decArgo_doxy_202_205_304_pCoef3 ...
      );

   % compute PPOX_DOXY
   ppoxDoxyValues = O2ctoO2p(oxygenPresComp, tempValues, psalValues, presValues, ...
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

   % fprintf('Float #;Cycle #;NearSurf/InAir;PRES;TEMP;C1PHASE_DOXY;C2PHASE_DOXY;TEMP_DOXY;MOLAR_DOXY;PRES comp MOLAR_DOXY;PPOX_DOXY\n');
   % for idMes = 1:length(presValues)
   %    fprintf('%d;%d;NearSurf/InAir;%.1f;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f;%.3f\n', ...
   %       g_decArgo_floatNum, g_decArgo_cycleNum, ...
   %       presValues(idMes), tempValues(idMes), ...
   %       c1PaseDoxyValues(idMes), c2PaseDoxyValues(idMes), tempDoxyValues(idMes), molarDoxyValues(idMes), oxygenPresComp(idMes), ppoxDoxyValues(idMes));
   % end

   o_PPOX_DOXY(idNoDef) = ppoxDoxyValues;
end

return
