% ------------------------------------------------------------------------------
% Compute TURBIDITY from TURBIDITY_VOLTAGE provided by the SEAPOINT sensor.
%
% SYNTAX :
%  [o_TURBIDITY] = compute_TURBIDITY_SEAPOINT_303(a_TURBIDITY_VOLTAGE, ...
%    a_TURBIDITY_VOLTAGE_fill_value, a_TURBIDITY_fill_value)
%
% INPUT PARAMETERS :
%   a_TURBIDITY_VOLTAGE            : input TURBIDITY_VOLTAGE data
%   a_TURBIDITY_VOLTAGE_fill_value : fill value for input TURBIDITY_VOLTAGE data
%   a_TURBIDITY_fill_value         : fill value for output TURBIDITY data
%
% OUTPUT PARAMETERS :
%   o_TURBIDITY : output TURBIDITY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_TURBIDITY] = compute_TURBIDITY_SEAPOINT_303(a_TURBIDITY_VOLTAGE, ...
   a_TURBIDITY_VOLTAGE_fill_value, a_TURBIDITY_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_TURBIDITY = ones(length(a_TURBIDITY_VOLTAGE), 1)*a_TURBIDITY_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'SEAPOINT'))
   fprintf('WARNING: Float #%d Cycle #%d: SEAPOINT sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.SEAPOINT, 'Point1Volt')) && ...
      (isfield(g_decArgo_calibInfo.SEAPOINT, 'Point1Turbi')) && ...
      (isfield(g_decArgo_calibInfo.SEAPOINT, 'Point2Volt')) && ...
      (isfield(g_decArgo_calibInfo.SEAPOINT, 'Point2Turbi')))
   point1Volt = double(g_decArgo_calibInfo.SEAPOINT.Point1Volt);
   point1Turbi = double(g_decArgo_calibInfo.SEAPOINT.Point1Turbi);
   point2Volt = double(g_decArgo_calibInfo.SEAPOINT.Point2Volt);
   point2Turbi = double(g_decArgo_calibInfo.SEAPOINT.Point2Turbi);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent SEAPOINT sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_TURBIDITY_VOLTAGE ~= a_TURBIDITY_VOLTAGE_fill_value);
aCoef = (point1Turbi-point2Turbi)/(point1Volt-point2Volt);
bCoef = point1Turbi - aCoef*point1Volt;
o_TURBIDITY(idNoDef) = aCoef*a_TURBIDITY_VOLTAGE(idNoDef) + bCoef;
               
return
