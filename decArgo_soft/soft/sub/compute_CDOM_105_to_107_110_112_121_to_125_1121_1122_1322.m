% ------------------------------------------------------------------------------
% Compute CDOM from FLUORESCENCE_CDOM provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_CDOM] = compute_CDOM_105_to_107_110_112_121_to_125_1121_1122_1322(a_FLUORESCENCE_CDOM, ...
%    a_FLUORESCENCE_CDOM_fill_value, a_CDOM_fill_value)
%
% INPUT PARAMETERS :
%   a_FLUORESCENCE_CDOM            : input FLUORESCENCE_CDOM data
%   a_FLUORESCENCE_CDOM_fill_value : fill value for input FLUORESCENCE_CDOM data
%   a_CDOM_fill_value              : fill value for output CDOM data
%
% OUTPUT PARAMETERS :
%   o_CDOM : output CDOM data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_CDOM] = compute_CDOM_105_to_107_110_112_121_to_125_1121_1122_1322(a_FLUORESCENCE_CDOM, ...
   a_FLUORESCENCE_CDOM_fill_value, a_CDOM_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_CDOM = ones(length(a_FLUORESCENCE_CDOM), 1)*a_CDOM_fill_value;


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
elseif ((isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactCDOM')) && ...
      (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountCDOM')))
   scaleFactCDOM = double(g_decArgo_calibInfo.ECO3.ScaleFactCDOM);
   darkCountCDOM = double(g_decArgo_calibInfo.ECO3.DarkCountCDOM);
   if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountCDOM_O'))
      darkCountCDOM = double(g_decArgo_calibInfo.ECO3.DarkCountCDOM_O);
   end
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_FLUORESCENCE_CDOM ~= a_FLUORESCENCE_CDOM_fill_value);
o_CDOM(idNoDef) = ...
   ((a_FLUORESCENCE_CDOM(idNoDef) - darkCountCDOM)*scaleFactCDOM);

return
