% ------------------------------------------------------------------------------
% Compute CP660 from TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660 provided by the
% CROVER sensor.
%
% SYNTAX :
 % [o_CP660] = compute_CP660( ...
 %   a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660, ...
 %   a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_fill_value, a_CP660_fill_value)
%
% INPUT PARAMETERS :
%   a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660            : input TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660 data
%   a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_fill_value : fill value for input TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660 data
%   a_CP660_fill_value                                      : fill value for output CP660 data
%
% OUTPUT PARAMETERS :
%   o_CP660 : output CP660 data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/16/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_CP660] = compute_CP660( ...
   a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660, ...
   a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_fill_value, a_CP660_fill_value)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% output parameters initialization
o_CP660 = ones(length(a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660), 1)*a_CP660_fill_value;


% calibration coefficients
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d: calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif (~isfield(g_decArgo_calibInfo, 'CROVER'))
   fprintf('WARNING: Float #%d Cycle #%d: CROVER sensor calibration information is missing\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
elseif ((isfield(g_decArgo_calibInfo.CROVER, 'Pathlength_CP660')) && ...
      (isfield(g_decArgo_calibInfo.CROVER, 'CSCDARK_CP660')) && ...
      (isfield(g_decArgo_calibInfo.CROVER, 'CSCCAL_CP660')))
   pathLengthCP660 = double(g_decArgo_calibInfo.CROVER.Pathlength_CP660);
   cscDark660 = double(g_decArgo_calibInfo.CROVER.CSCDARK_CP660);
   cscCal660 = double(g_decArgo_calibInfo.CROVER.CSCCAL_CP660);
else
   fprintf('ERROR: Float #%d Cycle #%d: inconsistent CROVER sensor calibration information\n', ...
      g_decArgo_floatNum, ...
      g_decArgo_cycleNum);
   return
end

% compute output data
idNoDef = find(a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660 ~= a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660_fill_value);
o_CP660(idNoDef) = -(1/pathLengthCP660) * ...
   log((a_TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660(idNoDef) - cscDark660) / (cscCal660 - cscDark660));

if (any(isinf(o_CP660)))
   o_CP660(isinf(o_CP660)) = a_CP660_fill_value;
end

return
