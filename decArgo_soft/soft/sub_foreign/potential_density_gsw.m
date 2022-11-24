% ------------------------------------------------------------------------------
% Compute potential density using Seawater library
% 
% SYNTAX :
%  [o_rho] = potential_density_gsw(a_pres, a_temp, a_psal, a_RefPres, a_lon, a_lat)
% 
% INPUT PARAMETERS :
%   a_pres    : PRES values
%   a_temp    : TEMP values
%   a_psal    : PSAL values
%   a_RefPres : reference pressure
%   a_lon     : longitude of the measurements
%   a_lat     : latitude of the measurements
% 
% OUTPUT PARAMETERS :
%   o_rho : potential density
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/26/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rho] = potential_density_gsw(a_pres, a_temp, a_psal, a_RefPres, a_lon, a_lat)

% FILL VALUES OF INPUT DATA SHOULD BE PREVIOUSLY REPLACED BY NAN VALUES

% compute density using Seawater library

% gsw library is not tolerant to negative pressure values (or erratic pressures)
presValid = a_pres;
presValid(find((presValid >= -5) & (presValid < 0))) = 0;
presValid(find((presValid < -5) | (presValid > 11000))) = nan;

[absoluteSalinity, ~] = gsw_SA_from_SP(a_psal, presValid, a_lon, a_lat);

conservativeTemperature = gsw_CT_from_t(absoluteSalinity, a_temp, a_pres);

o_rho = gsw_rho(absoluteSalinity, conservativeTemperature, a_RefPres);

return
