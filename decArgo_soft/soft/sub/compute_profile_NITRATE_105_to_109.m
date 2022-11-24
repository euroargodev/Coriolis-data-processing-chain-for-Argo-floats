% ------------------------------------------------------------------------------
% Compute NITRATE from MOLAR_NITRATE provided by the SUNA sensor.
%
% SYNTAX :
%  [o_NITRATE] = compute_profile_NITRATE_105_to_109(a_MOLAR_NITRATE, ...
%    a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
%    a_MOLAR_NITRATE_pres, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)
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
function [o_NITRATE] = compute_profile_NITRATE_105_to_109(a_MOLAR_NITRATE, ...
   a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
   a_MOLAR_NITRATE_pres, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)

% output parameters initialization
o_NITRATE = ones(length(a_MOLAR_NITRATE), 1)*a_NITRATE_fill_value;

global g_tempoJPR_nitrateFromFloat;


% retrieve configuration information
sunaVerticalOffset = get_static_config_value('CONFIG_PX_1_6_0_0_0');
if (isempty(sunaVerticalOffset))
   sunaVerticalOffset = 0;
   fprintf('WARNING: Float #%d Cycle #%d Profile #%d: SUNA vertical offset is missing => NITRATE data computed with a 0 dbar vertical offset in ''%c'' profile of SUNA sensor\n', ...
      g_decArgo_floatNum, ...
      a_profSuna.cycleNumber, ...
      a_profSuna.profileNumber, ...
      a_profSuna.direction);
end

% interpolate/extrapolate the CTD data at the pressures of the MOLAR_NITRATE
% measurements
if (size(a_ctdData, 1) > 1)
   ctdIntData = compute_interpolated_CTD_measurements(a_ctdData, a_MOLAR_NITRATE_pres+sunaVerticalOffset, 1);
else
   ctdIntData = a_ctdData;
end
if (~isempty(ctdIntData))
   
   idNoDef = find(~((ctdIntData(:, 1) == a_PRES_fill_value) | ...
      (ctdIntData(:, 2) == a_TEMP_fill_value) | ...
      (ctdIntData(:, 3) == a_PSAL_fill_value) | ...
      (a_MOLAR_NITRATE == a_MOLAR_NITRATE_fill_value)));
   
   % compute potential temperature and potential density
   tpot = tetai(ctdIntData(idNoDef, 1), ctdIntData(idNoDef, 2), ctdIntData(idNoDef, 3), 0);
   [null, sigma0] = swstat90(ctdIntData(idNoDef, 3), tpot, 0);
   rho = (sigma0+1000)/1000;
   
   % compute output data (units convertion: micromol/L to micromol/kg)
   o_NITRATE(idNoDef) = a_MOLAR_NITRATE(idNoDef) ./ rho;
end

g_tempoJPR_nitrateFromFloat = o_NITRATE;

return;
