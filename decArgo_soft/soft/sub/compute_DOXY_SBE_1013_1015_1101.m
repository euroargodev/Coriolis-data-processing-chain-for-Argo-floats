% ------------------------------------------------------------------------------
% Compute DOXY from FREQUENCY_DOXY for a SBE 43F IDO sensor.
%
% SYNTAX :
%  [o_DOXY] = compute_DOXY_SBE_1013_1015_1101( ...
%    a_FREQUENCY_DOXY, ...
%    a_FREQUENCY_DOXY_fillValue, ...
%    a_PRES, a_TEMP, a_PSAL, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_DOXY_fillValue)
%
% INPUT PARAMETERS :
%   a_FREQUENCY_DOXY           : input FREQUENCY_DOXY data
%   a_FREQUENCY_DOXY_fillValue : FREQUENCY_DOXY fill value
%   a_PRES                     : input PRES data
%   a_TEMP                     : input TEMP data
%   a_PSAL                     : input PSAL data
%   a_PRES_fillValue           : PRES fill value
%   a_TEMP_fillValue           : TEMP fill value
%   a_PSAL_fillValue           : PSAL fill value
%   a_DOXY_fillValue           : DOXY fill value
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
%   10/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOXY] = compute_DOXY_SBE_1013_1015_1101( ...
   a_FREQUENCY_DOXY, ...
   a_FREQUENCY_DOXY_fillValue, ...
   a_PRES, a_TEMP, a_PSAL, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_DOXY_fillValue)

% output parameters initialization
o_DOXY = ones(length(a_FREQUENCY_DOXY), 1)*a_DOXY_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

% retrieve global coefficient default values
global g_decArgo_doxy_102_207_206_a0;
global g_decArgo_doxy_102_207_206_a1;
global g_decArgo_doxy_102_207_206_a2;
global g_decArgo_doxy_102_207_206_a3;
global g_decArgo_doxy_102_207_206_a4;
global g_decArgo_doxy_102_207_206_a5;
global g_decArgo_doxy_102_207_206_b0;
global g_decArgo_doxy_102_207_206_b1;
global g_decArgo_doxy_102_207_206_b2;
global g_decArgo_doxy_102_207_206_b3;
global g_decArgo_doxy_102_207_206_c0;


if (isempty(a_FREQUENCY_DOXY))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo, 'OPTODE')) && (isfield(g_decArgo_calibInfo.OPTODE, 'SbeTabDoxyCoef')))
   tabDoxyCoef = g_decArgo_calibInfo.OPTODE.SbeTabDoxyCoef;
   % the size of the tabDoxyCoef should be: size(tabDoxyCoef) = 1 6
   if (~isempty(find((size(tabDoxyCoef) == [1 6]) ~= 1, 1)))
      fprintf('ERROR: Float #%d Cycle #%d: DOXY calibration coefficients are inconsistent => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
      return;
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: DOXY calibration coefficients are missing => DOXY data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_FREQUENCY_DOXY == a_FREQUENCY_DOXY_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PSAL == a_PSAL_fillValue));
idNoDef = setdiff(1:length(a_FREQUENCY_DOXY), idDef);

if (~isempty(idNoDef))
   
   frequencyDoxyValues = a_FREQUENCY_DOXY(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = a_PSAL(idNoDef);
   
   % compute MLPL_DOXY from FREQUENCY_DOXY reported by the SBE 43F sensor
   mlplDoxyValues = calcoxy_sbe43f( ...
      frequencyDoxyValues, presValues, tempValues, psalValues, tabDoxyCoef, ...
      g_decArgo_doxy_102_207_206_a0, ...
      g_decArgo_doxy_102_207_206_a1, ...
      g_decArgo_doxy_102_207_206_a2, ...
      g_decArgo_doxy_102_207_206_a3, ...
      g_decArgo_doxy_102_207_206_a4, ...
      g_decArgo_doxy_102_207_206_a5, ...
      g_decArgo_doxy_102_207_206_b0, ...
      g_decArgo_doxy_102_207_206_b1, ...
      g_decArgo_doxy_102_207_206_b2, ...
      g_decArgo_doxy_102_207_206_b3, ...
      g_decArgo_doxy_102_207_206_c0);
   
   % convert MLPL_DOXY in micromol/L
   molarDoxyValues = 44.6596*mlplDoxyValues;
      
   % units convertion (micromol/L to micromol/kg)
   rho = potential_density(presValues, tempValues, psalValues);
   oxyValues = molarDoxyValues ./ rho;
   
   o_DOXY(idNoDef) = oxyValues;     
end

return;
