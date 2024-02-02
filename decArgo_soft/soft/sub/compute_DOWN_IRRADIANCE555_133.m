% ------------------------------------------------------------------------------
% Compute DOWN_IRRADIANCE555 from RAW_DOWNWELLING_IRRADIANCE555 provided by the
% OCR sensor.
%
% SYNTAX :
%  [o_DOWN_IRRADIANCE555] = compute_DOWN_IRRADIANCE555_133( ...
%    a_RAW_DOWNWELLING_IRRADIANCE555, ...
%    a_RAW_DOWNWELLING_IRRADIANCE555_fill_value, a_DOWN_IRRADIANCE555_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_IRRADIANCE555            : input RAW_DOWNWELLING_IRRADIANCE555 data
%   a_RAW_DOWNWELLING_IRRADIANCE555_fill_value : fill value for input RAW_DOWNWELLING_IRRADIANCE555 data
%   a_DOWN_IRRADIANCE555_fill_value            : fill value for output DOWN_IRRADIANCE555 data
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE555 : output DOWN_IRRADIANCE555 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE555] = compute_DOWN_IRRADIANCE555_133( ...
   a_RAW_DOWNWELLING_IRRADIANCE555, ...
   a_RAW_DOWNWELLING_IRRADIANCE555_fill_value, a_DOWN_IRRADIANCE555_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWN_IRRADIANCE555 = ones(length(a_RAW_DOWNWELLING_IRRADIANCE555), 1)*a_DOWN_IRRADIANCE555_fill_value;


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
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0Lambda555')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1Lambda555')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmLambda555')))
   a0Lambda555 = double(g_decArgo_calibInfo.OCR.A0Lambda555);
   a1Lambda555 = double(g_decArgo_calibInfo.OCR.A1Lambda555);
   lmLambda555 = double(g_decArgo_calibInfo.OCR.LmLambda555);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_IRRADIANCE555 ~= a_RAW_DOWNWELLING_IRRADIANCE555_fill_value);
o_DOWN_IRRADIANCE555(idNoDef) = ...
   0.01*a1Lambda555*(a_RAW_DOWNWELLING_IRRADIANCE555(idNoDef) - a0Lambda555)*lmLambda555;

return
