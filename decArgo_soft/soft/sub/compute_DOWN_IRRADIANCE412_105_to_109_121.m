% ------------------------------------------------------------------------------
% Compute DOWN_IRRADIANCE412 from RAW_DOWNWELLING_IRRADIANCE412 provided by the
% OCR sensor.
%
% SYNTAX :
%  [o_DOWN_IRRADIANCE412] = compute_DOWN_IRRADIANCE412_105_to_109_121( ...
%    a_RAW_DOWNWELLING_IRRADIANCE412, ...
%    a_RAW_DOWNWELLING_IRRADIANCE412_fill_value, a_DOWN_IRRADIANCE412_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_IRRADIANCE412            : input RAW_DOWNWELLING_IRRADIANCE412 data
%   a_RAW_DOWNWELLING_IRRADIANCE412_fill_value : fill value for input RAW_DOWNWELLING_IRRADIANCE412 data
%   a_DOWN_IRRADIANCE412_fill_value            : fill value for output DOWN_IRRADIANCE412 data
%
% OUTPUT PARAMETERS :
%   o_DOWN_IRRADIANCE412 : output DOWN_IRRADIANCE412 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWN_IRRADIANCE412] = compute_DOWN_IRRADIANCE412_105_to_109_121( ...
   a_RAW_DOWNWELLING_IRRADIANCE412, ...
   a_RAW_DOWNWELLING_IRRADIANCE412_fill_value, a_DOWN_IRRADIANCE412_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWN_IRRADIANCE412 = ones(length(a_RAW_DOWNWELLING_IRRADIANCE412), 1)*a_DOWN_IRRADIANCE412_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif (~isfield(g_decArgo_calibInfo, 'OCR'))
   fprintf('WARNING: Float #%d Cycle #%d: OCR sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0Lambda412')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1Lambda412')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmLambda412')))
   a0Lambda412 = double(g_decArgo_calibInfo.OCR.A0Lambda412);
   a1Lambda412 = double(g_decArgo_calibInfo.OCR.A1Lambda412);
   lmLambda412 = double(g_decArgo_calibInfo.OCR.LmLambda412);
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_IRRADIANCE412 ~= a_RAW_DOWNWELLING_IRRADIANCE412_fill_value);
o_DOWN_IRRADIANCE412(idNoDef) = ...
   0.01*a1Lambda412*(a_RAW_DOWNWELLING_IRRADIANCE412(idNoDef) - a0Lambda412)*lmLambda412;

return;
