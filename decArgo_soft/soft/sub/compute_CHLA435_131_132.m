% ------------------------------------------------------------------------------
% Compute CHLA435 from FLUORESCENCE_CHLA435 provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_CHLA435] = compute_CHLA435_131_132(a_FLUORESCENCE_CHLA435, ...
%    a_FLUORESCENCE_CHLA435_fill_value, a_CHLA435_fill_value)
%
% INPUT PARAMETERS :
%   a_FLUORESCENCE_CHLA435            : input FLUORESCENCE_CHLA435 data
%   a_FLUORESCENCE_CHLA435_fill_value : fill value for input FLUORESCENCE_CHLA435 data
%   a_CHLA435_fill_value              : fill value for output CHLA435 data
%
% OUTPUT PARAMETERS :
%   o_CHLA435 : output CHLA435 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/26/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_CHLA435] = compute_CHLA435_131_132(a_FLUORESCENCE_CHLA435, ...
   a_FLUORESCENCE_CHLA435_fill_value, a_CHLA435_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_CHLA435 = ones(length(a_FLUORESCENCE_CHLA435), 1)*a_CHLA435_fill_value;

      
% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'ECO3'))
   fprintf('WARNING: Float #%d Cycle #%d: ECO3 sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactChloroA435')) && ...
      (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA435')))
   scaleFactChloroA435 = double(g_decArgo_calibInfo.ECO3.ScaleFactChloroA435);
   darkCountChloroA435 = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA435);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_FLUORESCENCE_CHLA435 ~= a_FLUORESCENCE_CHLA435_fill_value);
o_CHLA435(idNoDef) = (a_FLUORESCENCE_CHLA435(idNoDef) - darkCountChloroA435)*scaleFactChloroA435;
               
return
