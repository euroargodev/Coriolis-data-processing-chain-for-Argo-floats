% ------------------------------------------------------------------------------
% Compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL from TRANSISTOR_PH sensor
% measurements (VRS_PH).
%
% SYNTAX :
%  [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_PH_1322( ...
%    a_VRS_PH, ...
%    a_VRS_PH_fillValue, ...
%    a_PRES, a_TEMP, a_PSAL, ...
%    a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
%    a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue)
%
% INPUT PARAMETERS :
%   a_VRS_PH                     : input VRS_PH data
%   a_VRS_PH_fillValue           : fill value for input VRS_PH data
%   a_PRES                       : input PRES CTD data
%   a_TEMP                       : input TEMP CTD data
%   a_PSAL                       : input PSAL CTD data
%   a_PRES_fillValue             : fill value for input PRES data
%   a_TEMP_fillValue             : fill value for input TEMP data
%   a_PSAL_fillValue             : fill value for input PSAL data
%   a_PH_IN_SITU_FREE_fillValue  : fill value for output PH_IN_SITU_FREE data
%   a_PH_IN_SITU_TOTAL_fillValue : fill value for output PH_IN_SITU_TOTAL data
% 
% OUTPUT PARAMETERS :
%   o_PH_IN_SITU_FREE  : output PH_IN_SITU_FREE data
%   o_PH_IN_SITU_TOTAL : output PH_IN_SITU_TOTAL data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_PH_IN_SITU_FREE, o_PH_IN_SITU_TOTAL] = compute_PH_1322( ...
   a_VRS_PH, ...
   a_VRS_PH_fillValue, ...
   a_PRES, a_TEMP, a_PSAL, ...
   a_PRES_fillValue, a_TEMP_fillValue, a_PSAL_fillValue, ...
   a_PH_IN_SITU_FREE_fillValue, a_PH_IN_SITU_TOTAL_fillValue)

% output parameters initialization
o_PH_IN_SITU_FREE = ones(length(a_VRS_PH), 1)*a_PH_IN_SITU_FREE_fillValue;
o_PH_IN_SITU_TOTAL = ones(length(a_VRS_PH), 1)*a_PH_IN_SITU_TOTAL_fillValue;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store calibration information
global g_decArgo_calibInfo;


if (isempty(a_VRS_PH))
   return;
end

% get calibration information
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: TRANSISTOR_PH sensor calibration information is missing => PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif (~isfield(g_decArgo_calibInfo, 'TRANSISTOR_PH'))
   fprintf('WARNING: Float #%d Cycle #%d: TRANSISTOR_PH sensor calibration information is missing => PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k0')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'k2')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f0')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f1')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f2')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f3')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f4')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f5')) && ...
      (isfield(g_decArgo_calibInfo.TRANSISTOR_PH, 'f6')))
   transPhK0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k0);
   transPhK2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.k2);
   transPhF0 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f0);
   transPhF1 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f1);
   transPhF2 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f2);
   transPhF3 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f3);
   transPhF4 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f4);
   transPhF5 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f5);
   transPhF6 = double(g_decArgo_calibInfo.TRANSISTOR_PH.f6);
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent TRANSISTOR_PH sensor calibration information => PH_IN_SITU_FREE and PH_IN_SITU_TOTAL data set to fill value\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

idDef = find( ...
   (a_VRS_PH == a_VRS_PH_fillValue) | ...
   (a_PRES == a_PRES_fillValue) | ...
   (a_TEMP == a_TEMP_fillValue) | ...
   (a_PSAL == a_PSAL_fillValue));
idNoDef = setdiff(1:length(a_VRS_PH), idDef);

if (~isempty(idNoDef))
   
   vrsPhValues = a_VRS_PH(idNoDef);
   presValues = a_PRES(idNoDef);
   tempValues = a_TEMP(idNoDef);
   psalValues = a_PSAL(idNoDef);
   
   % sensor dependent pressure coefficients
   % the f0 coefficient on the Sea-Bird calibration sheet is not used.
   transPhPCoefs = [transPhF1; transPhF2; transPhF3; transPhF4; transPhF5; transPhF6];
   
   % compute PH_IN_SITU_FREE and PH_IN_SITU_TOTAL
   [phFreeValues, phTotalValues] = phcalc(vrsPhValues, ...
      presValues, tempValues, psalValues, ...
      transPhK0, transPhK2, transPhPCoefs);
   
   % update output parameters
   o_PH_IN_SITU_FREE(idNoDef) = phFreeValues;
   o_PH_IN_SITU_TOTAL(idNoDef) = phTotalValues;

end

return;
