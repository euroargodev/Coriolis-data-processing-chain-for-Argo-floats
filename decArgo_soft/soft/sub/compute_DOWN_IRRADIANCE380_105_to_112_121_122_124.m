% ------------------------------------------------------------------------------
% Compute DOWN_IRRADIANCE380 from RAW_DOWNWELLING_IRRADIANCE380 provided by the
% OCR sensor.
%
% SYNTAX :
%  [o_DOWN_IRRADIANCE380] = compute_DOWN_IRRADIANCE380_105_to_112_121_122_124( ...
%    a_RAW_DOWNWELLING_IRRADIANCE380, ...
%    a_RAW_DOWNWELLING_IRRADIANCE380_fill_value, a_DOWN_IRRADIANCE380_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_IRRADIANCE380            : input RAW_DOWNWELLING_IRRADIANCE380 data
%   a_RAW_DOWNWELLING_IRRADIANCE380_fill_value : fill value for input RAW_DOWNWELLING_IRRADIANCE380 data
%   a_DOWN_IRRADIANCE380_fill_value            : fill value for output DOWN_IRRADIANCE380 data
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE380 : output DOWN_IRRADIANCE380 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE380] = compute_DOWN_IRRADIANCE380_105_to_112_121_122_124( ...
   a_RAW_DOWNWELLING_IRRADIANCE380, ...
   a_RAW_DOWNWELLING_IRRADIANCE380_fill_value, a_DOWN_IRRADIANCE380_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWN_IRRADIANCE380 = ones(length(a_RAW_DOWNWELLING_IRRADIANCE380), 1)*a_DOWN_IRRADIANCE380_fill_value;


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
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0Lambda380')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1Lambda380')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmLambda380')))
   a0Lambda380 = double(g_decArgo_calibInfo.OCR.A0Lambda380);
   a1Lambda380 = double(g_decArgo_calibInfo.OCR.A1Lambda380);
   lmLambda380 = double(g_decArgo_calibInfo.OCR.LmLambda380);
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_IRRADIANCE380 ~= a_RAW_DOWNWELLING_IRRADIANCE380_fill_value);
o_DOWN_IRRADIANCE380(idNoDef) = ...
   0.01*a1Lambda380*(a_RAW_DOWNWELLING_IRRADIANCE380(idNoDef) - a0Lambda380)*lmLambda380;

return
