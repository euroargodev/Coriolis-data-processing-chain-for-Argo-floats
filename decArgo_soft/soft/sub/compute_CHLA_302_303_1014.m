% ------------------------------------------------------------------------------
% Compute CHLA from FLUORESCENCE_CHLA provided by the FLNTU sensor.
%
% SYNTAX :
%  [o_CHLA] = compute_CHLA_302_303_1014(a_FLUORESCENCE_CHLA, ...
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
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_CHLA] = compute_CHLA_302_303_1014(a_FLUORESCENCE_CHLA, ...
   a_FLUORESCENCE_CHLA_fill_value, a_CHLA_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_CHLA = ones(length(a_FLUORESCENCE_CHLA), 1)*a_CHLA_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'FLNTU'))
   fprintf('WARNING: Float #%d Cycle #%d: FLNTU sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.FLNTU, 'ScaleFactChloroA')) && ...
      (isfield(g_decArgo_calibInfo.FLNTU, 'DarkCountChloroA')))
   scaleFactChloroA = double(g_decArgo_calibInfo.FLNTU.ScaleFactChloroA);
   darkCountChloroA = double(g_decArgo_calibInfo.FLNTU.DarkCountChloroA);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent FLNTU sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_FLUORESCENCE_CHLA ~= a_FLUORESCENCE_CHLA_fill_value);
o_CHLA(idNoDef) = (a_FLUORESCENCE_CHLA(idNoDef) - darkCountChloroA)*scaleFactChloroA;
               
return
