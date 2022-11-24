% ------------------------------------------------------------------------------
% Compute DOWNWELLING_PAR from VOLTAGE_DOWNWELLING_PAR provided by the MPE sensor.
%
% SYNTAX :
%  [o_DOWNWELLING_PAR] = compute_DOWNWELLING_PAR_mpe_128_129( ...
%    a_VOLTAGE_DOWNWELLING_PAR, ...
%    a_VOLTAGE_DOWNWELLING_PAR_fill_value, a_DOWNWELLING_PAR_fill_value)
%
% INPUT PARAMETERS :
%   a_VOLTAGE_DOWNWELLING_PAR            : input VOLTAGE_DOWNWELLING_PAR data
%   a_VOLTAGE_DOWNWELLING_PAR_fill_value : fill value for input VOLTAGE_DOWNWELLING_PAR data
%   a_DOWNWELLING_PAR_fill_value         : fill value for output DOWNWELLING_PAR data
%
% OUTPUT PARAMETERS :
%   o_DOWNWELLING_PAR : output DOWNWELLING_PAR data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/18/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWNWELLING_PAR] = compute_DOWNWELLING_PAR_mpe_128_129( ...
   a_VOLTAGE_DOWNWELLING_PAR, ...
   a_VOLTAGE_DOWNWELLING_PAR_fill_value, a_DOWNWELLING_PAR_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWNWELLING_PAR = ones(length(a_VOLTAGE_DOWNWELLING_PAR), 1)*a_DOWNWELLING_PAR_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'MPE'))
   fprintf('WARNING: Float #%d Cycle #%d: MPE sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (isfield(g_decArgo_calibInfo.MPE, 'ResponsivityW'))
   responsivityW = str2double(g_decArgo_calibInfo.MPE.ResponsivityW);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent MPE sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_VOLTAGE_DOWNWELLING_PAR ~= a_VOLTAGE_DOWNWELLING_PAR_fill_value);
o_DOWNWELLING_PAR(idNoDef) = ...
   1e4 * a_VOLTAGE_DOWNWELLING_PAR(idNoDef) / responsivityW;

return
