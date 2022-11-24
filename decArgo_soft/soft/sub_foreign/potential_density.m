% ------------------------------------------------------------------------------
% Compute potential density.
%
% SYNTAX :
%  [o_rho] = potential_density(a_pres, a_temp, a_psal)
%
% INPUT PARAMETERS :
%   a_pres : PRES values
%   a_temp : TEMP values
%   a_psal : PSAL values
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
%   05/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rho] = potential_density(a_pres, a_temp, a_psal)

% compute potential temperature and potential density
tempPot = tetai(a_pres, a_temp, a_psal, 0);
[~, sigma0] = swstat90(a_psal, tempPot, 0);

o_rho = (sigma0+1000)/1000;

return
