% ------------------------------------------------------------------------------
% Compute TOA from RAW_TOA provided by the RAFOS sensor.
%
% SYNTAX :
%  [o_TOA] = compute_TOA(a_RAW_TOA, a_RAW_TOA_fill_value, a_TOA_fill_value)
%
% INPUT PARAMETERS :
%   a_RAW_TOA            : input RAW_TOA data
%   a_RAW_TOA_fill_value : fill value for input RAW_TOA data
%   a_TOA_fill_value     : fill value for output TOA data
%
% OUTPUT PARAMETERS :
%   o_TOA : output TOA data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/18/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_TOA] = compute_TOA(a_RAW_TOA, a_RAW_TOA_fill_value, a_TOA_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% output parameters initialization
o_TOA = ones(size(a_RAW_TOA))*a_TOA_fill_value;


if (ismember('RAFOS', g_decArgo_sensorMountedOnFloat))
   
   % RAFOS sensor
   
   % calibration coefficients
   if (isempty(g_decArgo_calibInfo))
      fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif (~isfield(g_decArgo_calibInfo, 'RAFOS'))
      fprintf('WARNING: Float #%d Cycle #%d: RAFOS sensor calibration information is missing\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   elseif ((isfield(g_decArgo_calibInfo.RAFOS, 'SlopeRafosTOA')) && ...
         (isfield(g_decArgo_calibInfo.RAFOS, 'OffsetRafosTOA')))
      slopeRafosTOA = double(g_decArgo_calibInfo.RAFOS.SlopeRafosTOA);
      offsetRafosTOA = double(g_decArgo_calibInfo.RAFOS.OffsetRafosTOA);
   else
      fprintf('ERROR: Float #%d Cycle #%d: inconsistent RAFOS sensor calibration information\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum);
      return
   end
end

% compute output data
idNoDef = find(a_RAW_TOA ~= a_RAW_TOA_fill_value);
o_TOA(idNoDef) = a_RAW_TOA(idNoDef).*slopeRafosTOA + offsetRafosTOA;
               
return
