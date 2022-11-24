% ------------------------------------------------------------------------------
% Compute DOXY from PHASE_DELAY_DOXY using TEMP_DOXY provided by the SBE 63
% sensor.
% The method used is the Stern-Volmer equation.
%
% SYNTAX :
%  [o_doxyValues] = compute_DOXY_SBE_209( ...
%    a_phaseDelayDoxyValues, a_tempDoxyValues, ...
%    a_presValues, a_psalValues)
%
% INPUT PARAMETERS :
%   a_phaseDelayDoxyValues : input PHASE_DELAY_DOXY data
%   a_tempDoxyValues       : input TEMP_DOXY data
%   a_presValues           : input PRES data
%   a_psalValues           : input PSAL data
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
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_doxyValues] = compute_DOXY_SBE_209( ...
   a_phaseDelayDoxyValues, a_tempDoxyValues, ...
   a_presValues, a_psalValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;
global g_decArgo_salDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% output parameters initialization
o_doxyValues = ones(length(a_phaseDelayDoxyValues), 1)*g_decArgo_doxyDef;


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
   (a_presValues == g_decArgo_presDef) | ...
   (a_psalValues == g_decArgo_salDef));
idNoDef = setdiff([1:length(o_doxyValues)], idDef);

if (~isempty(idNoDef))
   
   phaseDelayDoxyValues = a_phaseDelayDoxyValues(idNoDef);
   tempDoxyValues = a_tempDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   psalValues = a_psalValues(idNoDef);

   % compute MLPL_DOXY from PHASE_DELAY_DOXY reported by the SBE 63 optode
   mlplDoxyValues = calcoxy_sbe63(phaseDelayDoxyValues, tempDoxyValues, ...
      presValues, psalValues, tabDoxyCoef);

   % convert MLPL_DOXY in micromol/L
   oxyValues = 44.6596*mlplDoxyValues;
   
   % compute potential temperature and potential density
   tpot = tetai(presValues, tempDoxyValues, psalValues, 0);
   [~, sigma0] = swstat90(psalValues, tpot, 0);
   rho = (sigma0+1000)/1000;
   
   % units convertion (micromol/L to micromol/kg)
   oxyValues = oxyValues ./ rho;
   
   o_doxyValues(idNoDef) = oxyValues;
end

return;
