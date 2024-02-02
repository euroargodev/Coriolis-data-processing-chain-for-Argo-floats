% ------------------------------------------------------------------------------
% Compute DOWN_IRRADIANCE443 from RAW_DOWNWELLING_IRRADIANCE443 provided by the
% OCR sensor.
%
% SYNTAX :
%  [o_DOWN_IRRADIANCE443] = compute_DOWN_IRRADIANCE443_130_133( ...
%    a_RAW_DOWNWELLING_IRRADIANCE443, ...
%    a_RAW_DOWNWELLING_IRRADIANCE443_fill_value, a_DOWN_IRRADIANCE443_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_IRRADIANCE443            : input RAW_DOWNWELLING_IRRADIANCE443 data
%   a_RAW_DOWNWELLING_IRRADIANCE443_fill_value : fill value for input RAW_DOWNWELLING_IRRADIANCE443 data
%   a_DOWN_IRRADIANCE443_fill_value            : fill value for output DOWN_IRRADIANCE443 data
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE443 : output DOWN_IRRADIANCE443 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/31/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE443] = compute_DOWN_IRRADIANCE443_130_133( ...
   a_RAW_DOWNWELLING_IRRADIANCE443, ...
   a_RAW_DOWNWELLING_IRRADIANCE443_fill_value, a_DOWN_IRRADIANCE443_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWN_IRRADIANCE443 = ones(length(a_RAW_DOWNWELLING_IRRADIANCE443), 1)*a_DOWN_IRRADIANCE443_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'OCR'))
   fprintf('WARNING: Float #%d Cycle #%d: OCR sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0Lambda443')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1Lambda443')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmLambda443')))
   a0Lambda443 = double(g_decArgo_calibInfo.OCR.A0Lambda443);
   a1Lambda443 = double(g_decArgo_calibInfo.OCR.A1Lambda443);
   lmLambda443 = double(g_decArgo_calibInfo.OCR.LmLambda443);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_IRRADIANCE443 ~= a_RAW_DOWNWELLING_IRRADIANCE443_fill_value);
o_DOWN_IRRADIANCE443(idNoDef) = ...
   0.01*a1Lambda443*(a_RAW_DOWNWELLING_IRRADIANCE443(idNoDef) - a0Lambda443)*lmLambda443;

return
