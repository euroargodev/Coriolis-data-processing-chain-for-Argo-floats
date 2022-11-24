% ------------------------------------------------------------------------------
% Compute BBP532 from BETA_BACKSCATTERING532 provided by the ECO3 sensor.
%
% SYNTAX :
%  [o_BBP] = compute_BBP532_108_109(a_BETA_BACKSCATTERING, ...
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
function [o_BBP] = compute_BBP532_108_109(a_BETA_BACKSCATTERING, ...
   a_BETA_BACKSCATTERING_fill_value, a_BBP_fill_value, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_BBP = ones(length(a_BETA_BACKSCATTERING), 1)*a_BBP_fill_value;


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
elseif ((isfield(g_decArgo_calibInfo.ECO3, 'ScaleFactBackscatter532')) && ...
      (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter532')) && ...
      (isfield(g_decArgo_calibInfo.ECO3, 'KhiCoefBackscatter')))
   scaleFactBackscatter532 = double(g_decArgo_calibInfo.ECO3.ScaleFactBackscatter532);
   darkCountBackscatter532 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter532);
   if (isfield(g_decArgo_calibInfo.ECO3, 'DarkCountBackscatter532_O'))
      darkCountBackscatter532 = double(g_decArgo_calibInfo.ECO3.DarkCountBackscatter532_O);
   end
   khiCoefBackscatter = double(g_decArgo_calibInfo.ECO3.KhiCoefBackscatter);
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent ECO3 sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find((a_BETA_BACKSCATTERING ~= a_BETA_BACKSCATTERING_fill_value) & ...
   (a_ctdData(:, 1) ~= a_PRES_fill_value) & ...
   (a_ctdData(:, 2) ~= a_TEMP_fill_value) & ...
   (a_ctdData(:, 3) ~= a_PSAL_fill_value));
% [betasw124, ~, ~, ~] = betasw124_ZHH2009(532, a_ctdData(:, 3), a_ctdData(:, 2));
[betasw124, ~, ~] = betasw_ZHH2009(532, a_ctdData(:, 2), 124, a_ctdData(:, 3));
o_BBP(idNoDef) = 2*pi*khiCoefBackscatter* ...
   ((a_BETA_BACKSCATTERING(idNoDef) - darkCountBackscatter532)*scaleFactBackscatter532 - betasw124(idNoDef));

return
