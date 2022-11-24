% ------------------------------------------------------------------------------
% Compute DOXY from FREQUENCY_DOXY for a SBE 63 IDO sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_SBE_1201( ...
%    a_PHASE_DELAY_DOXY, a_TEMP_DOXY, ...
%    a_PHASE_DELAY_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, a_TEMP, a_PSAL, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_DOXY_fillValue)
%
% INPUT PARAMETERS :
%   a_PHASE_DELAY_DOXY           : input PHASE_DELAY_DOXY data
%   a_TEMP_DOXY                  : input TEMP_DOXY data
%   a_PHASE_DELAY_DOXY_fillValue : PHASE_DELAY_DOXY fill value
%   a_TEMP_DOXY_fillValue        : TEMP_DOXY fill value
%   a_PRES                       : input PRES data
%   a_TEMP                       : input TEMP data
%   a_PSAL                       : input PSAL data
%   a_PRES_fillValue             : PRES fill value
%   a_TEMP_fillValue             : TEMP fill value
%   a_PSAL_fillValue             : PSAL fill value
%   a_DOXY_fillValue             : DOXY fill value
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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_DOXY_SBE_1201( ...
   a_PHASE_DELAY_DOXY, a_TEMP_DOXY, ...
   a_PHASE_DELAY_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, a_TEMP, a_PSAL, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_DOXY_fillValue)

% output parameters initialization
o_DOXY = ones(length(a_PHASE_DELAY_DOXY), 1)*a_DOXY_fillValue;

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
global g_decArgo_doxy_103_208_307_sPreset;
global g_decArgo_doxy_103_208_307_solB0;
global g_decArgo_doxy_103_208_307_solB1;
global g_decArgo_doxy_103_208_307_solB2;
global g_decArgo_doxy_103_208_307_solB3;
global g_decArgo_doxy_103_208_307_solC0;
global g_decArgo_doxy_103_208_307_pCoef1;
global g_decArgo_doxy_103_208_307_pCoef2;
global g_decArgo_doxy_103_208_307_pCoef3;


if (isempty(a_PHASE_DELAY_DOXY) || isempty(a_TEMP_DOXY))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 9
   if (~isempty(find((size(tabDoxyCoef) == [1 9]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
      return
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

idDef = find( ...
   (a_PHASE_DELAY_DOXY == a_PHASE_DELAY_DOXY_fillValue) | ...
   (a_TEMP_DOXY == a_TEMP_DOXY_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PSAL == a_PSAL_fillValue));
idNoDef = setdiff(1:length(a_PHASE_DELAY_DOXY), idDef);

if (~isempty(idNoDef))
   
   phaseDelayDoxyValues = a_PHASE_DELAY_DOXY(idNoDef);
   tempDoxyValues = a_TEMP_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = a_PSAL(idNoDef);
   
   % compute MLPL_DOXY from PHASE_DELAY_DOXY reported by the SBE 63 optode
   mlplDoxyValues = calcoxy_sbe63_sternvolmer( ...
      phaseDelayDoxyValues, presValues, tempDoxyValues, tabDoxyCoef, ...
      g_decArgo_doxy_103_208_307_pCoef1);
   
   % convert MLPL_DOXY in micromol/L
   molarDoxyValues = 44.6596*mlplDoxyValues;
   
   % salinity effect correction
   sRef = 0; % not considered since a PHASE_DOXY is transmitted
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, sRef, ...
      g_decArgo_doxy_103_208_307_d0, ...
      g_decArgo_doxy_103_208_307_d1, ...
      g_decArgo_doxy_103_208_307_d2, ...
      g_decArgo_doxy_103_208_307_d3, ...
      g_decArgo_doxy_103_208_307_sPreset, ...
      g_decArgo_doxy_103_208_307_solB0, ...
      g_decArgo_doxy_103_208_307_solB1, ...
      g_decArgo_doxy_103_208_307_solB2, ...
      g_decArgo_doxy_103_208_307_solB3, ...
      g_decArgo_doxy_103_208_307_solC0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decArgo_doxy_103_208_307_pCoef2, ...
      g_decArgo_doxy_103_208_307_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   [measLon, measLat] = get_meas_location(g_decArgo_cycleNum, -1, '');
   rho = potential_density_gsw(presValues, tempValues, psalValues, 0, measLon, measLat);
   rho = rho/1000;

   oxyValues = oxygenPresComp ./ rho;
   idNoNan = find(~isnan(oxyValues));
   
   o_DOXY(idNoDef(idNoNan)) = oxyValues(idNoNan);
end

return
