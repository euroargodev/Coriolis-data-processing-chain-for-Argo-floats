% ------------------------------------------------------------------------------
% Compute oxygen partial pressure measurements (PPOX_DOXY) from oxygen sensor
% measurements (PHASE_DELAY_DOXY) reported by the SBE 63 optode.
%
% SYNTAX :
%  [o_PPOX_DOXY] = compute_PPOX_DOXY_SBE_209( ...
%    a_PHASE_DELAY_DOXY, a_TEMP_DOXY, ...
%    a_PHASE_DELAY_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, a_TEMP, ...
%    a_PRES_fillValue, a_TEMP_fillValue, ...
%    a_PPOX_DOXY_fillValue)
%
% INPUT PARAMETERS :
%   a_PHASE_DELAY_DOXY           : input PHASE_DELAY_DOXY optode data
%   a_TEMP_DOXY                  : input TEMP_DOXY optode data
%   a_PHASE_DELAY_DOXY_fillValue : fill value for input PHASE_DELAY_DOXY data
%   a_TEMP_DOXY_fillValue        : fill value for input TEMP_DOXY data
%   a_PRES                       : input PRES CTD data
%   a_TEMP                       : input TEMP CTD data
%   a_PRES_fillValue             : fill value for input PRES data
%   a_TEMP_fillValue             : fill value for input TEMP data
%   a_PPOX_DOXY_fillValue        : fill value for output PPOX_DOXY data
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
%   06/02/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PPOX_DOXY] = compute_PPOX_DOXY_SBE_209( ...
   a_PHASE_DELAY_DOXY, a_TEMP_DOXY, ...
   a_PHASE_DELAY_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, a_TEMP, ...
   a_PRES_fillValue, a_TEMP_fillValue, ...
   a_PPOX_DOXY_fillValue)

% output parameters initialization
o_PPOX_DOXY = ones(length(a_PHASE_DELAY_DOXY), 1)*a_PPOX_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_103_208_307_d0;
global g_decArgo_doxy_103_208_307_d1;
global g_decArgo_doxy_103_208_307_d2;
global g_decArgo_doxy_103_208_307_d3;
global g_decArgo_doxy_103_208_307_solB0;
global g_decArgo_doxy_103_208_307_solB1;
global g_decArgo_doxy_103_208_307_solB2;
global g_decArgo_doxy_103_208_307_solB3;
global g_decArgo_doxy_103_208_307_solC0;
global g_decArgo_doxy_103_208_307_pCoef1;
global g_decArgo_doxy_103_208_307_pCoef2;
global g_decArgo_doxy_103_208_307_pCoef3;


if (isempty(a_PHASE_DELAY_DOXY) || isempty(a_TEMP_DOXY))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing  => PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
   if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent  => PPOX_DOXY not computed\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing  => PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_PHASE_DELAY_DOXY == a_PHASE_DELAY_DOXY_fillValue) | ...
   (a_TEMP_DOXY == a_TEMP_DOXY_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue));
idNoDef = setdiff(1:length(a_PHASE_DELAY_DOXY), idDef);

if (~isempty(idNoDef))
      
   phaseDelayDoxyValues = a_PHASE_DELAY_DOXY(idNoDef);
   tempDoxyValues = a_TEMP_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = zeros(size(presValues));
   
   % compute MLPL_DOXY from PHASE_DELAY_DOXY reported by the SBE 63 optode
   mlplDoxyValues = calcoxy_sbe63_sternvolmer( ...
      phaseDelayDoxyValues, presValues, tempDoxyValues, tabDoxyCoef, ...
      g_decArgo_doxy_103_208_307_pCoef1);

   % convert MLPL_DOXY in MOLAR_DOXY
   molarDoxyValues = 44.6596*mlplDoxyValues;
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(molarDoxyValues, presValues, tempValues, ...
      g_decArgo_doxy_103_208_307_pCoef2, ...
      g_decArgo_doxy_103_208_307_pCoef3 ...
      );

   % compute PPOX_DOXY
   ppoxDoxyValues = O2ctoO2p(oxygenPresComp, tempValues, psalValues, presValues, ...
      g_decArgo_doxy_103_208_307_d0, ...
      g_decArgo_doxy_103_208_307_d1, ...
      g_decArgo_doxy_103_208_307_d2, ...
      g_decArgo_doxy_103_208_307_d3, ...
      g_decArgo_doxy_103_208_307_solB0, ...
      g_decArgo_doxy_103_208_307_solB1, ...
      g_decArgo_doxy_103_208_307_solB2, ...
      g_decArgo_doxy_103_208_307_solB3, ...
      g_decArgo_doxy_103_208_307_solC0 ...
      );
   
   o_PPOX_DOXY(idNoDef) = ppoxDoxyValues;
end

return;
