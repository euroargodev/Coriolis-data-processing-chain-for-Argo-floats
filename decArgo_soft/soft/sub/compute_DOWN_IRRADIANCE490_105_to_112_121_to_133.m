% ------------------------------------------------------------------------------
% Compute DOWN_IRRADIANCE490 from RAW_DOWNWELLING_IRRADIANCE490 provided by the
% OCR sensor.
%
% SYNTAX :
%  [o_DOWN_IRRADIANCE490] = compute_DOWN_IRRADIANCE490_105_to_112_121_to_133( ...
%    a_RAW_DOWNWELLING_IRRADIANCE490, ...
%    a_RAW_DOWNWELLING_IRRADIANCE490_fill_value, a_DOWN_IRRADIANCE490_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_IRRADIANCE490            : input RAW_DOWNWELLING_IRRADIANCE490 data
%   a_RAW_DOWNWELLING_IRRADIANCE490_fill_value : fill value for input RAW_DOWNWELLING_IRRADIANCE490 data
%   a_DOWN_IRRADIANCE490_fill_value            : fill value for output DOWN_IRRADIANCE490 data
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE490 : output DOWN_IRRADIANCE490 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE490] = compute_DOWN_IRRADIANCE490_105_to_112_121_to_133( ...
   a_RAW_DOWNWELLING_IRRADIANCE490, ...
   a_RAW_DOWNWELLING_IRRADIANCE490_fill_value, a_DOWN_IRRADIANCE490_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWN_IRRADIANCE490 = ones(length(a_RAW_DOWNWELLING_IRRADIANCE490), 1)*a_DOWN_IRRADIANCE490_fill_value;


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
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0Lambda490')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1Lambda490')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmLambda490')))
   a0Lambda490 = double(g_decArgo_calibInfo.OCR.A0Lambda490);
   a1Lambda490 = double(g_decArgo_calibInfo.OCR.A1Lambda490);
   lmLambda490 = double(g_decArgo_calibInfo.OCR.LmLambda490);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_IRRADIANCE490 ~= a_RAW_DOWNWELLING_IRRADIANCE490_fill_value);
o_DOWN_IRRADIANCE490(idNoDef) = ...
   0.01*a1Lambda490*(a_RAW_DOWNWELLING_IRRADIANCE490(idNoDef) - a0Lambda490)*lmLambda490;

return
