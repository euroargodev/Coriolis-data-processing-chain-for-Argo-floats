% ------------------------------------------------------------------------------
% Compute DOWNWELLING_PAR from RAW_DOWNWELLING_PAR provided by the OCR sensor.
%
% SYNTAX :
%  [o_DOWNWELLING_PAR] = compute_DOWNWELLING_PAR_105_to_112_121_to_125( ...
%    a_RAW_DOWNWELLING_PAR, ...
%    a_RAW_DOWNWELLING_PAR_fill_value, a_DOWNWELLING_PAR_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_DOWNWELLING_PAR            : input RAW_DOWNWELLING_PAR data
%   a_RAW_DOWNWELLING_PAR_fill_value : fill value for input RAW_DOWNWELLING_PAR data
%   a_DOWNWELLING_PAR_fill_value     : fill value for output DOWNWELLING_PAR data
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
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_DOWNWELLING_PAR] = compute_DOWNWELLING_PAR_105_to_112_121_to_125( ...
   a_RAW_DOWNWELLING_PAR, ...
   a_RAW_DOWNWELLING_PAR_fill_value, a_DOWNWELLING_PAR_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_DOWNWELLING_PAR = ones(length(a_RAW_DOWNWELLING_PAR), 1)*a_DOWNWELLING_PAR_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'OCR'))
   fprintf('WARNING: Float #%d Cycle #%d: OCR sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.OCR, 'A0PAR')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'A1PAR')) && ...
      (isfield(g_decArgo_calibInfo.OCR, 'LmPAR')))
   a0PAR = double(g_decArgo_calibInfo.OCR.A0PAR);
   a1PAR = double(g_decArgo_calibInfo.OCR.A1PAR);
   lmPAR = double(g_decArgo_calibInfo.OCR.LmPAR);
else
   fprintf('WARNING: Float #%d Cycle #%d: inconsistent OCR sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_RAW_DOWNWELLING_PAR ~= a_RAW_DOWNWELLING_PAR_fill_value);
o_DOWNWELLING_PAR(idNoDef) = ...
   a1PAR*(a_RAW_DOWNWELLING_PAR(idNoDef) - a0PAR)*lmPAR;

return
