% ------------------------------------------------------------------------------
% Compute the MLPL_DOXY values in ml/l from the FREQUENCY_DOXY measurements
% reported by a SBE43F sensor.
%
% SYNTAX :
%  [o_mlplDoxy] = calcoxy_sbe43f( ...
%    a_frequencyDoxy, a_pres, a_temp, a_psal, a_tabCoef, ...
%    a_a0, a_a1, a_a2, a_a3, a_a4, a_a5, a_b0, a_b1, a_b2, a_b3, a_c0)
%
% INPUT PARAMETERS :
%   a_frequencyDoxy : outpout from SBE43F's sensor
%   a_pres          : PRES values
%   a_temp          : TEMP values
%   a_psal          : PSAL values
%   a_tabcoef       : calibration coefficients
%                     size(a_tabcoef) = 1 6 and a_tabcoef = [SOC FOFFSET A B C E];
%   a_a0 to a_c0    : additional coefficient value
%
% OUTPUT PARAMETERS :
%   o_mlplDoxy : MLPL_DOXY values (oxygen concentration in ml/L)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mlplDoxy] = calcoxy_sbe43f( ...
   a_frequencyDoxy, a_pres, a_temp, a_psal, a_tabCoef, ...
   a_a0, a_a1, a_a2, a_a3, a_a4, a_a5, a_b0, a_b1, a_b2, a_b3, a_c0)

soc = a_tabCoef(1);
fOffset = a_tabCoef(2);
a = a_tabCoef(3);
b = a_tabCoef(4);
c = a_tabCoef(5);
e = a_tabCoef(6);

ts = log((298.15 - a_temp)./(273.15 + a_temp));

oxsol = exp(a_a0 + a_a1*ts + a_a2*ts.^2 + a_a3*ts.^3 + a_a4*ts.^4 + a_a5*ts.^5 + ...
   (a_psal.*(a_b0 + a_b1*ts + a_b2*ts.^2 + a_b3*ts.^3)) + ...
   (a_c0*a_psal.^2));

o_mlplDoxy = soc*(a_frequencyDoxy + fOffset).*oxsol.*(1.0 + a*a_temp + b*a_temp.^2 + c*a_temp.^3).*exp(e*a_pres./(273.15 + a_temp));

return
