% ------------------------------------------------------------------------------
% Compute dissolved oxygen measurements (DOXY) from oxygen sensor measurements
% (DPHASE_DOXY) using the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_302_303( ...
%    a_DPHASE_DOXY, a_TEMP_DOXY, ...
%    a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, a_TEMP, a_PSAL, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_DOXY_fillValue, a_profOptode)
%
% INPUT PARAMETERS :
%   a_DPHASE_DOXY           : input DPHASE_DOXY optode data
%   a_TEMP_DOXY             : input TEMP_DOXY optode data
%   a_DPHASE_DOXY_fillValue : fill value for input DPHASE_DOXY data
%   a_TEMP_DOXY_fillValue   : fill value for input TEMP_DOXY data
%   a_PRES                  : input PRES CTD data
%   a_TEMP                  : input TEMP CTD data
%   a_PSAL                  : input PSAL CTD data
%   a_PRES_fillValue        : fill value for input PRES data
%   a_TEMP_fillValue        : fill value for input TEMP data
%   a_PSAL_fillValue        : fill value for input PSAL data
%   a_DOXY_fillValue        : fill value for output DOXY data
%   a_profOptode            : OPTODE profile structure
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
   a_DPHASE_DOXY, a_TEMP_DOXY, ...
   a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, a_TEMP, a_PSAL, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_DOXY_fillValue, a_profOptode)

% output parameters initialization
o_DOXY = ones(length(a_DPHASE_DOXY), 1)*a_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_201_203_202_d0;
global g_decArgo_doxy_201_203_202_d1;
global g_decArgo_doxy_201_203_202_d2;
global g_decArgo_doxy_201_203_202_d3;
global g_decArgo_doxy_201_203_202_sPreset;
global g_decArgo_doxy_201_203_202_b0;
global g_decArgo_doxy_201_203_202_b1;
global g_decArgo_doxy_201_203_202_b2;
global g_decArgo_doxy_201_203_202_b3;
global g_decArgo_doxy_201_203_202_c0;
global g_decArgo_doxy_201_203_202_pCoef1;
global g_decArgo_doxy_201_203_202_pCoef2;
global g_decArgo_doxy_201_203_202_pCoef3;


if (isempty(a_DPHASE_DOXY))
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
   if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
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
   (a_DPHASE_DOXY == a_DPHASE_DOXY_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PSAL == a_PSAL_fillValue));
idNoDef = setdiff(1:length(a_DPHASE_DOXY), idDef);

if (~isempty(idNoDef))
   dPhaseDoxyValues = a_DPHASE_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = a_PSAL(idNoDef);
   
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830_aanderaa( ...
      dPhaseDoxyValues, presValues, tempValues, tabDoxyCoef, ...
      g_decArgo_doxy_201_203_202_pCoef1 ...
      );
   
   % salinity effect correction
   sRef = 0; % not considered since a PHASE_DOXY is transmitted
   oxygenSalComp = calcoxy_salcomp(molarDoxyValues, tempValues, psalValues, sRef, ...
      g_decArgo_doxy_201_203_202_d0, ...
      g_decArgo_doxy_201_203_202_d1, ...
      g_decArgo_doxy_201_203_202_d2, ...
      g_decArgo_doxy_201_203_202_d3, ...
      g_decArgo_doxy_201_203_202_sPreset, ...
      g_decArgo_doxy_201_203_202_b0, ...
      g_decArgo_doxy_201_203_202_b1, ...
      g_decArgo_doxy_201_203_202_b2, ...
      g_decArgo_doxy_201_203_202_b3, ...
      g_decArgo_doxy_201_203_202_c0 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(oxygenSalComp, presValues, tempValues, ...
      g_decArgo_doxy_201_203_202_pCoef2, ...
      g_decArgo_doxy_201_203_202_pCoef3 ...
      );
   
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density(presValues, tempValues, psalValues);
   oxyValues = oxygenPresComp ./ rho;
   
   o_DOXY(idNoDef) = oxyValues;
end

return;
