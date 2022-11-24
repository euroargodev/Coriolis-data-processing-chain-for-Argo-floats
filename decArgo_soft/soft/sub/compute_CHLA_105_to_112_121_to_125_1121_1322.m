% ------------------------------------------------------------------------------
% Compute CHLA from FLUORESCENCE_CHLA provided by the ECO2 or ECO3 sensor.
%
% SYNTAX :
%  [o_CHLA] = compute_CHLA_105_to_112_121_to_125_1121_1322(a_FLUORESCENCE_CHLA, ...
%    a_FLUORESCENCE_CHLA_fill_value, a_CHLA_fill_value)
%
% INPUT PARAMETERS :
%   a_FLUORESCENCE_CHLA            : input FLUORESCENCE_CHLA data
%   a_FLUORESCENCE_CHLA_fill_value : fill value for input FLUORESCENCE_CHLA data
%   a_CHLA_fill_value              : fill value for output CHLA data
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
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_CHLA] = compute_CHLA_105_to_112_121_to_125_1121_1322(a_FLUORESCENCE_CHLA, ...
   a_FLUORESCENCE_CHLA_fill_value, a_CHLA_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% output parameters initialization
o_CHLA = ones(length(a_FLUORESCENCE_CHLA), 1)*a_CHLA_fill_value;


if (ismember('ECO3', g_decArgo_sensorMountedOnFloat))
   
   % ECO3 sensor
   
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
   elseif ((isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactChloroA')) && ...
         (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountChloroA')))
      scaleFactChloroA = double(g_decArgo_calibInfo.ECO3.ScaleFactChloroA);
      darkCountChloroA = double(g_decArgo_calibInfo.ECO3.DarkCountChloroA);
      if (isfield(g_decArgo_calibInfo.ECO3, 'darkCountChloroA_O'))
         darkCountChloroA = double(g_decArgo_calibInfo.ECO3.darkCountChloroA_O);
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   
elseif (ismember('ECO2', g_decArgo_sensorMountedOnFloat))
   
   % ECO2 sensor
   
   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'ECO2'))
      fprintf('WARNING: Float #%d Cycle #%d: ECO2 sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif ((isfield(g_decArgo_calibInfo.ECO2, 'ScaleFactChloroA')) && ...
         (isfield(g_decArgo_calibInfo.ECO2, 'DarkCountChloroA')))
      scaleFactChloroA = double(g_decArgo_calibInfo.ECO2.ScaleFactChloroA);
      darkCountChloroA = double(g_decArgo_calibInfo.ECO2.DarkCountChloroA);
      if (isfield(g_decArgo_calibInfo.ECO2, 'darkCountChloroA_O'))
         darkCountChloroA = double(g_decArgo_calibInfo.ECO2.darkCountChloroA_O);
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d: inconsistent ECO2 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   
end

% compute output data
idNoDef = find(a_FLUORESCENCE_CHLA ~= a_FLUORESCENCE_CHLA_fill_value);
o_CHLA(idNoDef) = (a_FLUORESCENCE_CHLA(idNoDef) - darkCountChloroA)*scaleFactChloroA;
               
return
