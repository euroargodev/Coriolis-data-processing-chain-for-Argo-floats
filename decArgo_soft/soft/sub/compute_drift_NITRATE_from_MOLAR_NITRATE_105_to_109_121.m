% ------------------------------------------------------------------------------
% Compute NITRATE from MOLAR_NITRATE provided by the SUNA sensor.
%
% SYNTAX :
%  [o_NITRATE] = compute_drift_NITRATE_from_MOLAR_NITRATE_105_to_109_121(a_MOLAR_NITRATE, ...
%    a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
%    a_MOLAR_NITRATE_dates, a_ctdDates, a_ctdData, ...
%    a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)
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
function [o_NITRATE] = compute_drift_NITRATE_from_MOLAR_NITRATE_105_to_109_121(a_MOLAR_NITRATE, ...
   a_MOLAR_NITRATE_fill_value, a_NITRATE_fill_value, ...
   a_MOLAR_NITRATE_dates, a_ctdDates, a_ctdData, ...
   a_PRES_fill_value, a_TEMP_fill_value, a_PSAL_fill_value)

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
   tpot = tetai(ctdLinkData(idNoDef, 1), ctdLinkData(idNoDef, 2), ctdLinkData(idNoDef, 3), 0);
   [null, sigma0] = swstat90(ctdLinkData(idNoDef, 3), tpot, 0);
   rho = (sigma0+1000)/1000;
   
   % compute output data (units convertion: micromol/L to micromol/kg)
   o_NITRATE(idNoDef) = a_MOLAR_NITRATE(idNoDef) ./ rho;
end
               
return;
