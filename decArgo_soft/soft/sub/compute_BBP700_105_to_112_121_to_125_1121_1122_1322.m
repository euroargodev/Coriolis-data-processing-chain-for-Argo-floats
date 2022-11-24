% ------------------------------------------------------------------------------
% Compute BBP700 from BETA_BACKSCATTERING700 provided by the ECO2 or ECO3 sensor.
%
% SYNTAX :
%  [o_BBP] = compute_BBP700_105_to_112_121_to_125_1121_1122_1322(a_BETA_BACKSCATTERING, ...
%    a_BETA_BACKSCATTERING_fill_value, a_BBP_fill_value, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)
%
% INPUT PARAMETERS :
%   a_BETA_BACKSCATTERING            : input BETA_BACKSCATTERING data
%   a_BETA_BACKSCATTERING_fill_value : fill value for input BETA_BACKSCATTERING data
%   a_BBP_fill_value                 : fill value for output BBP data
%   a_ctdData                        : ascociated CTD (P, T, S) data
%   a_PRES_fill_value                : fill value for input PRES data
%   a_TEMP_fill_value                : fill value for input TEMP data
%   a_PSAL_fill_value                : fill value for input PSAL data
%
% OUTPUT PARAMETERS :
%   o_BBP : output BBP data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/08/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_BBP] = compute_BBP700_105_to_112_121_to_125_1121_1122_1322(a_BETA_BACKSCATTERING, ...
   a_BETA_BACKSCATTERING_fill_value, a_BBP_fill_value, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fill_value;


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
   elseif ((isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactBackscatter700')) && ...
         (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter700')) && ...
         (isfield(g_decArgo_calibInfo.ECO3, 'KhiCoefBackscatter')))
      scaleFactBackscatter700 = double(g_decArgo_calibInfo.ECO3.ScaleFactBackscatter700);
      darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter700);
      if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter700_O'))
         darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter700_O);
      end
      khiCoefBackscatter = double(g_decArgo_calibInfo.ECO3.KhiCoefBackscatter);
   else
      fprintf('WARNING: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   
   % determine angle of measurement
   % if SENSOR_MODEL == ECO_FLBB => 142°
   % if (ECO_FLBBCD || ECO_FLBB2) == ECO_FLBB => 124°
   angle = 124;
   
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
   elseif ((isfield(g_decArgo_calibInfo.ECO2, 'ScaleFactBackscatter700')) && ...
         (isfield(g_decArgo_calibInfo.ECO2, 'DarkCountBackscatter700')) && ...
         (isfield(g_decArgo_calibInfo.ECO2, 'KhiCoefBackscatter')))
      scaleFactBackscatter700 = double(g_decArgo_calibInfo.ECO2.ScaleFactBackscatter700);
      darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO2.DarkCountBackscatter700);
      if (isfield(g_decArgo_calibInfo.ECO2, 'DarkCountBackscatter700_O'))
         darkCountBackscatter700 = double(g_decArgo_calibInfo.ECO2.DarkCountBackscatter700_O);
      end
      khiCoefBackscatter = double(g_decArgo_calibInfo.ECO2.KhiCoefBackscatter);
   else
      fprintf('WARNING: Float #%d Cycle #%d: inconsistent ECO2 sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
   
   % determine angle of measurement
   % if SENSOR_MODEL == ECO_FLBB => 142°
   % if (ECO_FLBBCD || ECO_FLBB2) == ECO_FLBB => 124°
   angle = 142;
   
end

% compute output data
idNoDef = find((a_BETA_BACKSCATTERING ~= a_BETA_BACKSCATTERING_fill_value) & ...
   (a_ctdData(:, 1) ~= a_PRES_fill_value) & ...
   (a_ctdData(:, 2) ~= a_TEMP_fill_value) & ...
   (a_ctdData(:, 3) ~= a_PSAL_fill_value));
% [betasw124, ~, ~, ~] = betasw124_ZHH2009(700, a_ctdData(:, 3), a_ctdData(:, 2));
[betaswAngle, ~, ~] = betasw_ZHH2009(700, a_ctdData(:, 2), angle, a_ctdData(:, 3));
o_BBP(idNoDef) = 2*pi*khiCoefBackscatter* ...
   ((a_BETA_BACKSCATTERING(idNoDef) - darkCountBackscatter700)*scaleFactBackscatter700 - betaswAngle(idNoDef));

return
