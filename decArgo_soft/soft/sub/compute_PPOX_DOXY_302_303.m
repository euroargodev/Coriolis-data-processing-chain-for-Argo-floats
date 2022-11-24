% ------------------------------------------------------------------------------
% Compute oxygen partial pressure measurements (PPOX_DOXY) from oxygen sensor
% measurements (DPHASE_DOXY) using the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_PPOX_DOXY] = compute_PPOX_DOXY_302_303( ...
%    a_DPHASE_DOXY, a_TEMP_DOXY, ...
%    a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
%    a_PRES, a_TEMP, ...
%    a_PRES_fillValue, a_TEMP_fillValue, ...
%    a_PPOX_DOXY_fillValue, a_profOptode)
%
% INPUT PARAMETERS :
%   a_DPHASE_DOXY           : input DPHASE_DOXY optode data
%   a_TEMP_DOXY             : input TEMP_DOXY optode data
%   a_DPHASE_DOXY_fillValue : fill value for input DPHASE_DOXY data
%   a_TEMP_DOXY_fillValue   : fill value for input TEMP_DOXY data
%   a_PRES                  : input PRES CTD data
%   a_TEMP                  : input TEMP CTD data
%   a_PRES_fillValue        : fill value for input PRES data
%   a_TEMP_fillValue        : fill value for input TEMP data
%   a_PPOX_DOXY_fillValue   : fill value for output PPOX_DOXY data
%   a_profOptode            : OPTODE profile structure
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
function [o_PPOX_DOXY] = compute_PPOX_DOXY_302_303( ...
   a_DPHASE_DOXY, a_TEMP_DOXY, ...
   a_DPHASE_DOXY_fillValue, a_TEMP_DOXY_fillValue, ...
   a_PRES, a_TEMP, ...
   a_PRES_fillValue, a_TEMP_fillValue, ...
   a_PPOX_DOXY_fillValue, a_profOptode)

% output parameters initialization
o_PPOX_DOXY = ones(length(a_DPHASE_DOXY), 1)*a_PPOX_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_201_203_202_d0;
global g_decArgo_doxy_201_203_202_d1;
global g_decArgo_doxy_201_203_202_d2;
global g_decArgo_doxy_201_203_202_d3;
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
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: DOXY calibration coefficients are missing => PPOX_DOXY not computed\n', ...
      g_decArgo_floatNum, ...
      a_profOptode.cycleNumber, ...
      a_profOptode.profileNumber);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 5 4 for the
   % Aanderaa standard calibration (tabDoxyCoef(i,j) = Cij).
   if (~isempty(find((size(tabDoxyCoef) == [5 4]) ~= 1, 1)))
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
   (a_DPHASE_DOXY == a_DPHASE_DOXY_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue));
idNoDef = setdiff(1:length(a_DPHASE_DOXY), idDef);

if (~isempty(idNoDef))
   
   dPhaseDoxyValues = a_DPHASE_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = zeros(size(presValues));
   
   % compute MOLAR_DOXY from DPHASE_DOXY using the Aanderaa standard calibration
   molarDoxyValues = calcoxy_aanderaa3830_aanderaa( ...
      dPhaseDoxyValues, presValues, tempValues, tabDoxyCoef, ...
      g_decArgo_doxy_201_203_202_pCoef1 ...
      );
   
   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(molarDoxyValues, presValues, tempValues, ...
      g_decArgo_doxy_201_203_202_pCoef2, ...
      g_decArgo_doxy_201_203_202_pCoef3 ...
      );
   
   % compute PPOX_DOXY
   ppoxDoxyValues = O2ctoO2p(oxygenPresComp, tempValues, psalValues, presValues, ...
      g_decArgo_doxy_201_203_202_d0, ...
      g_decArgo_doxy_201_203_202_d1, ...
      g_decArgo_doxy_201_203_202_d2, ...
      g_decArgo_doxy_201_203_202_d3, ...
      g_decArgo_doxy_201_203_202_b0, ...
      g_decArgo_doxy_201_203_202_b1, ...
      g_decArgo_doxy_201_203_202_b2, ...
      g_decArgo_doxy_201_203_202_b3, ...
      g_decArgo_doxy_201_203_202_c0 ...
      );
   
   o_PPOX_DOXY(idNoDef) = ppoxDoxyValues;
end

return;
