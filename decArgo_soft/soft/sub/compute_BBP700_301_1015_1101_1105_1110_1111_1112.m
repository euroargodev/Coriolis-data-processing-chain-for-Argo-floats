% ------------------------------------------------------------------------------
% Compute BBP700 from BETA_BACKSCATTERING700 provided by the FLBB sensor.
%
% SYNTAX :
%  [o_BBP] = compute_BBP700_301_1015_1101_1105_1110_1111_1112(a_BETA_BACKSCATTERING, ...
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_BBP] = compute_BBP700_301_1015_1101_1105_1110_1111_1112(a_BETA_BACKSCATTERING, ...
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
   return;
elseif (~isfield(g_decArgo_calibInfo, 'FLBB'))
   fprintf('WARNING: Float #%d Cycle #%d: FLBB sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
elseif ((isfield(g_decArgo_calibInfo.FLBB, 'ScaleFactBackscatter700')) && ...
      (isfield(g_decArgo_calibInfo.FLBB, 'DarkCountBackscatter700')) && ...
      (isfield(g_decArgo_calibInfo.FLBB, 'KhiCoefBackscatter')))
   scaleFactBackscatter700 = double(g_decArgo_calibInfo.FLBB.ScaleFactBackscatter700);
   darkCountBackscatter700 = double(g_decArgo_calibInfo.FLBB.DarkCountBackscatter700);
   if (isfield(g_decArgo_calibInfo.FLBB, 'DarkCountBackscatter700_O'))
      darkCountBackscatter700 = double(g_decArgo_calibInfo.FLBB.DarkCountBackscatter700_O);
   end
   khiCoefBackscatter = double(g_decArgo_calibInfo.FLBB.KhiCoefBackscatter);
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent FLBB sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return;
end

% compute output data
idNoDef = find((a_BETA_BACKSCATTERING ~= a_BETA_BACKSCATTERING_fill_value) & ...
   (a_ctdData(:, 1) ~= a_PRES_fill_value) & ...
   (a_ctdData(:, 2) ~= a_TEMP_fill_value) & ...
   (a_ctdData(:, 3) ~= a_PSAL_fill_value));
% [betasw124, ~, ~, ~] = betasw124_ZHH2009(700, a_ctdData(:, 3), a_ctdData(:, 2));
[betasw142, ~, ~] = betasw_ZHH2009(700, a_ctdData(:, 2), 142, a_ctdData(:, 3));
o_BBP(idNoDef) = 2*pi*khiCoefBackscatter* ...
   ((a_BETA_BACKSCATTERING(idNoDef) - darkCountBackscatter700)*scaleFactBackscatter700 - betasw142(idNoDef));

return;
