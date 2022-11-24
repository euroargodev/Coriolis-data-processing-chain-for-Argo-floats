% ------------------------------------------------------------------------------
% Compute NITRATE from MOLAR_NITRATE provided by the SUNA sensor.
%
% SYNTAX :
%  [o_NITRATE] = compute_drift_NITRATE_1xx_5_to_9_11_12_14_15_21_to_25(a_MOLAR_NITRATE, ...
%    a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
%    a_MOLAR_NITRATE_dates, a_ctdDates, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, a_profSuna)
%
% INPUT PARAMETERS :
%   a_MOLAR_NITRATE            : input MOLAR_NITRATE data
%   a_MOLAR_NITRATE_fill_value : fill value for input MOLAR_NITRATE data
%   a_NITRATE_fill_value       : fill value for output NITRATE data
%   a_MOLAR_NITRATE_dates      : dates of the MOLAR_NITRATE data
%   a_ctdDates                 : dates of ascociated CTD (P, T, S) data
%   a_ctdData                  : ascociated CTD (P, T, S) data
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
function [o_NITRATE] = compute_drift_NITRATE_1xx_5_to_9_11_12_14_15_21_to_25(a_MOLAR_NITRATE, ...
   a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
   a_MOLAR_NITRATE_dates, a_ctdDates, a_ctdData, ...compute_drift_NITRATE_1xx_5_to_9_11_12_14_15_21_to_25
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value, a_profSuna)

% output parameters initialization
o_NITRATE = ones(length(a_MOLAR_NITRATE), 1)*a_NITRATE_fill_value;


% assign the CTD data to the MOLAR_NITRATE measurements (timely closest
% association)
ctdLinkData = assign_CTD_measurements(a_ctdDates, a_ctdData, a_MOLAR_NITRATE_dates);
if (~isempty(ctdLinkData))
   
   idNoDef = find(~((ctdLinkData(:, 1) == a_PRES_fill_value) | ...
      (ctdLinkData(:, 2) == a_TEMP_fill_value) | ...
      (ctdLinkData(:, 3) == a_PSAL_fill_value) | ...
      (a_MOLAR_NITRATE == a_MOLAR_NITRATE_fill_value)));
   
   % compute potential temperature and potential density
   [measLon, measLat] = get_meas_location(a_profSuna.cycleNumber, a_profSuna.profileNumber, a_profSuna);
   rho = potential_density_gsw(ctdLinkData(idNoDef, 1), ctdLinkData(idNoDef, 2), ctdLinkData(idNoDef, 3), 0, measLon, measLat);
   rho = rho/1000;
   
   % compute output data (units convertion: micromol/L to micromol/kg)
   nitrateValues = a_MOLAR_NITRATE(idNoDef) ./ rho;
   idNoNan = find(~isnan(nitrateValues));
   o_NITRATE(idNoDef(idNoNan)) = nitrateValues(idNoNan);
end
               
return
