% ------------------------------------------------------------------------------
% Compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY provided by a Aanderaa
% 4330 optode
%
% SYNTAX :
%  [o_ppoxDoxyValues] = compute_PPOX_DOXY_AANDERAA_209( ...
%    a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, a_presValues)
%
% INPUT PARAMETERS :
%   a_c1PhaseDoxyValues : surface C1PHASE_DOXY data
%   a_c2PhaseDoxyValues : surface C2PHASE_DOXY data
%   a_tempDoxyValues    : surface TEMP_DOXY data
%   a_presValues        : surface PRES data
%
% OUTPUT PARAMETERS :
%   o_ppoxDoxyValues : output PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/26/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ppoxDoxyValues] = compute_PPOX_DOXY_AANDERAA_209( ...
   a_c1PhaseDoxyValues, a_c2PhaseDoxyValues, a_tempDoxyValues, a_presValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% output parameters initialization
o_ppoxDoxyValues = ones(length(a_c1PhaseDoxyValues), 1)*g_decArgo_doxyDef;


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
   (a_presValues == g_decArgo_presDef));
idNoDef = setdiff([1:length(o_ppoxDoxyValues)], idDef);

if (~isempty(idNoDef))
   
   tPhaseDoxyValues = a_c1PhaseDoxyValues(idNoDef) - a_c2PhaseDoxyValues(idNoDef);
   tempDoxyValues = a_tempDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);

   % compute MOLAR_DOXY from TPHASE_DOXY using the Stern-Volmer equation
   S0 = 0; % not used in the Stern-Volmer equation
   molarDoxyValues = calcoxy_aanderaa4330(tPhaseDoxyValues, tempDoxyValues, ...
      'sternvolmer', tabDoxyCoef, S0);
   
   % compute PPOX_DOXY
   psalValues = zeros(length(a_c1PhaseDoxyValues), 1);
   ppoxDoxyValues = O2ctoO2p(molarDoxyValues, tempDoxyValues, psalValues, presValues);
   
   o_ppoxDoxyValues(idNoDef) = ppoxDoxyValues;
end

return;
