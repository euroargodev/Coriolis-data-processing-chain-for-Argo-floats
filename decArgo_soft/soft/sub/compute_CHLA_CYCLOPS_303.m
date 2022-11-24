% ------------------------------------------------------------------------------
% Compute CHLA from FLUORESCENCE_VOLTAGE_CHLA provided by the CYCLOPS sensor.
%
% SYNTAX :
%  [o_CHLA] = compute_CHLA_CYCLOPS_303(a_FLUORESCENCE_VOLTAGE_CHLA, ...
%    a_FLUORESCENCE_VOLTAGE_CHLA_fill_value, a_CHLA_fill_value)
%
% INPUT PARAMETERS :
%   a_FLUORESCENCE_VOLTAGE_CHLA            : input FLUORESCENCE_VOLTAGE_CHLA data
%   a_FLUORESCENCE_VOLTAGE_CHLA_fill_value : fill value for input
%                                            FLUORESCENCE_VOLTAGE_CHLA data
%   a_CHLA_fill_value                      : fill value for output CHLA data
%
% OUTPUT PARAMETERS :
%   o_CHLA : output CHLA data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_CHLA] = compute_CHLA_CYCLOPS_303(a_FLUORESCENCE_VOLTAGE_CHLA, ...
   a_FLUORESCENCE_VOLTAGE_CHLA_fill_value, a_CHLA_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_CHLA = ones(length(a_FLUORESCENCE_VOLTAGE_CHLA), 1)*a_CHLA_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'CYCLOPS'))
   fprintf('WARNING: Float #%d Cycle #%d: CYCLOPS sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.CYCLOPS, 'Point1Volt')) && ...
      (isfield(g_decArgo_calibInfo.CYCLOPS, 'Point1ChloroA')) && ...
      (isfield(g_decArgo_calibInfo.CYCLOPS, 'Point2Volt')) && ...
      (isfield(g_decArgo_calibInfo.CYCLOPS, 'Point2ChloroA')))
   point1Volt = double(g_decArgo_calibInfo.CYCLOPS.Point1Volt);
   point1ChloroA = double(g_decArgo_calibInfo.CYCLOPS.Point1ChloroA);
   point2Volt = double(g_decArgo_calibInfo.CYCLOPS.Point2Volt);
   point2ChloroA = double(g_decArgo_calibInfo.CYCLOPS.Point2ChloroA);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent CYCLOPS sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_FLUORESCENCE_VOLTAGE_CHLA ~= a_FLUORESCENCE_VOLTAGE_CHLA_fill_value);
aCoef = (point1ChloroA-point2ChloroA)/(point1Volt-point2Volt);
bCoef = point1ChloroA - aCoef*point1Volt;
o_CHLA(idNoDef) = aCoef*a_FLUORESCENCE_VOLTAGE_CHLA(idNoDef) + bCoef;
               
return
