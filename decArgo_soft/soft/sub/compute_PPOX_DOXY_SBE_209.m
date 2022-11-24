% ------------------------------------------------------------------------------
% Compute PPOX_DOXY from PHASE_DELAY_DOXY provided by a SBE 63 optode.
%
% SYNTAX :
%  [o_ppoxDoxyValues] = compute_PPOX_DOXY_SBE_209( ...
%    a_phaseDelayDoxyValues, a_tempDoxyValues, ...
%    a_presValues)
%
% INPUT PARAMETERS :
%   a_phaseDelayDoxyValues : input PHASE_DELAY_DOXY data
%   a_tempDoxyValues       : input TEMP_DOXY data
%   a_presValues           : input PRES data
%
% OUTPUT PARAMETERS :
%   o_ppoxDoxyValues : output DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/27/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ppoxDoxyValues] = compute_PPOX_DOXY_SBE_209( ...
   a_phaseDelayDoxyValues, a_tempDoxyValues, ...
   a_presValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% output parameters initialization
o_ppoxDoxyValues = ones(length(a_phaseDelayDoxyValues), 1)*g_decArgo_doxyDef;


if (isempty(a_phaseDelayDoxyValues) || isempty(a_tempDoxyValues))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
   if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
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
   (a_phaseDelayDoxyValues == g_decArgo_phaseDelayDoxyDef) | ...
   (a_tempDoxyValues == g_decArgo_tempDoxyDef) | ...
   (a_presValues == g_decArgo_presDef));
idNoDef = setdiff([1:length(o_ppoxDoxyValues)], idDef);

if (~isempty(idNoDef))
   
   phaseDelayDoxyValues = a_phaseDelayDoxyValues(idNoDef);
   tempDoxyValues = a_tempDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   psalValues = zeros(size(presValues));

   % compute MLPL_DOXY from PHASE_DELAY_DOXY reported by the SBE 63 optode
   mlplDoxyValues = calcoxy_sbe63(phaseDelayDoxyValues, tempDoxyValues, ...
      presValues, psalValues, tabDoxyCoef);

   % convert MLPL_DOXY in MOLAR_DOXY
   molarDoxyValues = 44.6596*mlplDoxyValues;
   
   % compute PPOX_DOXY
   ppoxDoxyValues = O2ctoO2p(molarDoxyValues, tempDoxyValues, psalValues, presValues);
   
   o_ppoxDoxyValues(idNoDef) = ppoxDoxyValues;
end

return;
