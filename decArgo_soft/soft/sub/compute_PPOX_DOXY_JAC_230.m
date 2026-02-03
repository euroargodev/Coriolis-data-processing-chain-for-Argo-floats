% ------------------------------------------------------------------------------
% Compute oxygen partial pressure measurements (PPOX_DOXY) from oxygen sensor
% measurements (COUNT_DOXY and LED_FLASHING_COUNT_DOXY) reported by an AROD_FT optode.
%
% SYNTAX :
% [o_ppoxDoxyValues] = compute_PPOX_DOXY_JAC_230( ...
%   a_countDoxyValues, a_ledFlashingCountDoxyValues, ...
%   a_presValues, a_tempValues, a_psalValues)
%
% INPUT PARAMETERS :
%   a_countDoxyValues            : input COUNT_DOXY optode data
%   a_ledFlashingCountDoxyValues : input LED_FLASHING_COUNT_DOXY optode data
%   a_presValues                 : input PRES CTD data
%   a_tempValues                 : input TEMP CTD data
%   a_psalValues                 : input PSAL CTD data
%
% OUTPUT PARAMETERS :
%   o_ppoxDoxyValues : output PPOX_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ppoxDoxyValues] = compute_PPOX_DOXY_JAC_230( ...
   a_countDoxyValues, a_ledFlashingCountDoxyValues, ...
   a_presValues, a_tempValues, a_psalValues)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_doxyCountsDef;
global g_decArgo_ledFlashingDoxyCountsDef;
global g_decArgo_doxyDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_301_210_401_d0;
global g_decArgo_doxy_301_210_401_d1;
global g_decArgo_doxy_301_210_401_d2;
global g_decArgo_doxy_301_210_401_d3;
global g_decArgo_doxy_301_210_401_b0;
global g_decArgo_doxy_301_210_401_b1;
global g_decArgo_doxy_301_210_401_b2;
global g_decArgo_doxy_301_210_401_b3;
global g_decArgo_doxy_301_210_401_c0;

% output parameters initialization
o_ppoxDoxyValues = ones(length(a_countDoxyValues), 1)*g_decArgo_doxyDef;


if (isempty(a_countDoxyValues) || isempty(a_ledFlashingCountDoxyValues))
   return
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'TabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.TabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 7 7
   if (~isempty(find((size(tabDoxyCoef) == [7 7]) ~= 1, 1)))
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
   (a_countDoxyValues == g_decArgo_doxyCountsDef) | ...
   (a_ledFlashingCountDoxyValues == g_decArgo_ledFlashingDoxyCountsDef) | ...
   (a_presValues == g_decArgo_presDef) | ...
   (a_tempValues == g_decArgo_tempDef) | ...
   (a_psalValues == g_decArgo_salDef));
idNoDef = setdiff(1:length(o_ppoxDoxyValues), idDef);

if (~isempty(idNoDef))

   doxyCoefC = tabDoxyCoef(4, 1:3);
   if (any(isnan(doxyCoefC)))
      fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   doxyCoefD = tabDoxyCoef(5, 1:5);
   if (any(isnan(doxyCoefD)))
      fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   doxyCoefE = tabDoxyCoef(6, 1);
   if (any(isnan(doxyCoefE)))
      fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   doxyCoefCp = tabDoxyCoef(7, 1);
   if (any(isnan(doxyCoefCp)))
      fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing - DOXY data set to fill value\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end

   countDoxyValues = a_countDoxyValues(idNoDef);
   ledFlashingCountDoxyValues = a_ledFlashingCountDoxyValues(idNoDef);
   presValues = a_presValues(idNoDef);
   tempValues = a_tempValues(idNoDef);
   psalValues = zeros(size(presValues));

   % compute MOLAR_DOXY from COUNT_DOXY and LED_FLASHING_COUNT_DOXY
   molarDoxyValues = calcoxy_arod_ft_230( ...
      countDoxyValues, ledFlashingCountDoxyValues, tempValues, ...
      doxyCoefC, doxyCoefD, doxyCoefE);

   % pressure effect correction
   oxygenPresComp = calcoxy_prescomp(molarDoxyValues, presValues, tempValues, ...
      0, ...
      10*doxyCoefCp ...
      );

   % compute PPOX_DOXY
   ppoxDoxyValues = O2ctoO2p(oxygenPresComp, tempValues, psalValues, presValues, ...
      g_decArgo_doxy_301_210_401_d0, ...
      g_decArgo_doxy_301_210_401_d1, ...
      g_decArgo_doxy_301_210_401_d2, ...
      g_decArgo_doxy_301_210_401_d3, ...
      g_decArgo_doxy_301_210_401_b0, ...
      g_decArgo_doxy_301_210_401_b1, ...
      g_decArgo_doxy_301_210_401_b2, ...
      g_decArgo_doxy_301_210_401_b3, ...
      g_decArgo_doxy_301_210_401_c0 ...
      );

   % fprintf('Float #;Cycle #;NearSurf/InAir;PRES;TEMP;COUNT_DOXY;LED_FLASHING_COUNT_DOXY;MOLAR_DOXY;PRES comp MOLAR_DOXY;PPOX_DOXY\n');
   % for idMes = 1:length(presValues)
   %    fprintf('%d;%d;NearSurf/InAir;%.1f;%.3f;%d;%d;%.3f;%.3f;%.3f\n', ...
   %       g_decArgo_floatNum, g_decArgo_cycleNum, ...
   %       presValues(idMes), tempValues(idMes), ...
   %       countDoxyValues(idMes), ledFlashingCountDoxyValues(idMes), molarDoxyValues(idMes), oxygenPresComp(idMes), ppoxDoxyValues(idMes));
   % end

   o_ppoxDoxyValues(idNoDef) = ppoxDoxyValues;
end

return
