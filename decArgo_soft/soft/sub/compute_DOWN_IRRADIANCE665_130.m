% ------------------------------------------------------------------------------
% Compute DOWN_IRRADIANCE665 from RAW_DOWNWELLING_IRRADIANCE665 provided by the
% OCR sensor.
%
% SYNTAX :
%  [o_DOWN_IRRADIANCE665] = compute_DOWN_IRRADIANCE665_130( ...
%    a_RAW_DOWNWELLING_IRRADIANCE665, ...
%    a_RAW_DOWNWELLING_IRRADIANCE665_fill_value, a_DOWN_IRRADIANCE665_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_IRRADIANCE665            : input RAW_DOWNWELLING_IRRADIANCE665 data
%   a_RAW_DOWNWELLING_IRRADIANCE665_fill_value : fill value for input RAW_DOWNWELLING_IRRADIANCE665 data
%   a_DOWN_IRRADIANCE665_fill_value            : fill value for output DOWN_IRRADIANCE665 data
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE665 : output DOWN_IRRADIANCE665 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/31/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE665] = compute_DOWN_IRRADIANCE665_130( ...
   a_RAW_DOWNWELLING_IRRADIANCE665, ...
   a_RAW_DOWNWELLING_IRRADIANCE665_fill_value, a_DOWN_IRRADIANCE665_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWN_IRRADIANCE665 = ones(length(a_RAW_DOWNWELLING_IRRADIANCE665), 1)*a_DOWN_IRRADIANCE665_fill_value;


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
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0Lambda665')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1Lambda665')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmLambda665')))
   a0Lambda665 = double(g_decArgo_calibInfo.OCR.A0Lambda665);
   a1Lambda665 = double(g_decArgo_calibInfo.OCR.A1Lambda665);
   lmLambda665 = double(g_decArgo_calibInfo.OCR.LmLambda665);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_IRRADIANCE665 ~= a_RAW_DOWNWELLING_IRRADIANCE665_fill_value);
o_DOWN_IRRADIANCE665(idNoDef) = ...
   0.01*a1Lambda665*(a_RAW_DOWNWELLING_IRRADIANCE665(idNoDef) - a0Lambda665)*lmLambda665;

return
