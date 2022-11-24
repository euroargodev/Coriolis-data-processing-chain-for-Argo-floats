% ------------------------------------------------------------------------------
% Compute NITRATE from MOLAR_NITRATE provided by the SUNA sensor.
%
% SYNTAX :
%  [o_NITRATE] = compute_prof_NITRATE_from_MOLAR_1xx_5_to_9_11_12_14_21_to_25(a_MOLAR_NITRATE, ...
%    a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
%    a_MOLAR_NITRATE_pres, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, a_profSuna)
%
% INPUT PARAMETERS :
%   a_MOLAR_NITRATE            : input MOLAR_NITRATE data
%   a_MOLAR_NITRATE_fill_value : fill value for input MOLAR_NITRATE data
%   a_NITRATE_fill_value       : fill value for output NITRATE data
%   a_MOLAR_NITRATE_pres       : pressure levels of the MOLAR_NITRATE data
%   a_ctdData                  : CTD (P, T, S) profile data
%   a_PRES_fill_value          : fill value for input PRES data
%   a_TEMP_fill_value          : fill value for input TEMP data
%   a_PSAL_fill_value          : fill value for input PSAL data
%   a_profSuna                 : input SUNA profile structure
%
% OUTPUT PARAMETERS :
%   o_NITRATE : output NITRATE data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_NITRATE] = compute_prof_NITRATE_from_MOLAR_1xx_5_to_9_11_12_14_21_to_25(a_MOLAR_NITRATE, ...
   a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
   a_MOLAR_NITRATE_pres, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, a_profSuna)

% output parameters initialization
o_NITRATE = ones(length(a_MOLAR_NITRATE), 1)*a_NITRATE_fill_value;

% current float WMO number
global g_decArgo_floatNum;

% arrays to store calibration information
global g_decArgo_calibInfo;

global g_tempoJPR_nitrateFromFloat;


% retrieve configuration information
sunaVerticalOffset = 0;
if (isempty(g_decArgo_calibInfo))
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA vertical offset is missing - NITRATE data computed with a 0 dbar vertical offset in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
elseif (isfield(g_decArgo_calibInfo, 'SUNA') && ...
      isfield(g_decArgo_calibInfo.SUNA, 'SunaVerticalOffset'))
   sunaVerticalOffset = g_decArgo_calibInfo.SUNA.SunaVerticalOffset;
else
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA vertical offset is missing - NITRATE data computed with a 0 dbar vertical offset in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
end

% interpolate/extrapolate the CTD data at the pressures of the MOLAR_NITRATE
% measurements
ctdIntData = compute_interpolated_CTD_measurements( ...
   a_ctdData, a_MOLAR_NITRATE_pres+sunaVerticalOffset, a_profSuna.direction);
if (~isempty(ctdIntData))
   
   idNoDef = find(~((ctdIntData(:, 1) == a_PRES_fill_value) | ...
      (ctdIntData(:, 2) == a_TEMP_fill_value) | ...
      (ctdIntData(:, 3) == a_PSAL_fill_value) | ...
      (a_MOLAR_NITRATE == a_MOLAR_NITRATE_fill_value)));
   
   % compute potential temperature and potential density
   [measLon, measLat] = get_meas_location(a_profSuna.cycleNumber, a_profSuna.profileNumber, a_profSuna);
   rho = potential_density_gsw(ctdIntData(idNoDef, 1), ctdIntData(idNoDef, 2), ctdIntData(idNoDef, 3), 0, measLon, measLat);
   rho = rho/1000;
   
   % compute output data (units convertion: micromol/L to micromol/kg)
   nitrateValues = a_MOLAR_NITRATE(idNoDef) ./ rho;
   idNoNan = find(~isnan(nitrateValues));
   o_NITRATE(idNoDef(idNoNan)) = nitrateValues(idNoNan);
end

g_tempoJPR_nitrateFromFloat = o_NITRATE;

return
