% ------------------------------------------------------------------------------
% Compute the MOLAR_DOXY values in umol/L from the TPHASE_DOXY measurements
% reported by a AANDERAA 4330 optode using the Stern-Volmer equation.
%
% SYNTAX :
%  [o_molarDoxy] = calcoxy_aanderaa4330_sternvolmer( ...
%    a_tPhaseDoxy, a_pres, a_temp, a_tabCoef, a_pCoef1)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxy : TPHASE_DOXY sensor measurements
%   a_pres       : pressure in dbar
%   a_temp       : temperature measurement values in °C (from the optode if
%                  available, from the CTD otherwise)
%   a_tabCoef    : calibration coefficients
%                  size(a_tabCoef) = 2 7 and
%                      a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
%                      a_tabCoef(2, 1:7) = [SVUFoilCoef0 SVUFoilCoef1 ... SVUFoilCoef6]
%   a_pCoef1      : additional coefficient value
%
% OUTPUT PARAMETERS :
%   o_molarDoxy : MOLAR_DOXY values (in umol/L)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Virginie Thierry (IFREMER/LPO)(Virginie.Thierry@ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/01/2013 - VT - creation
% ------------------------------------------------------------------------------
function [o_molarDoxy] = calcoxy_aanderaa4330_sternvolmer( ...
   a_tPhaseDoxy, a_pres, a_temp, a_tabCoef, a_pCoef1)

% Stern-Volmer calibration method

phaseCoef0 = a_tabCoef(1, 1);
phaseCoef1 = a_tabCoef(1, 2);
phaseCoef2 = a_tabCoef(1, 3);
phaseCoef3 = a_tabCoef(1, 4);

c0 = a_tabCoef(2, 1);
c1 = a_tabCoef(2, 2);
c2 = a_tabCoef(2, 3);
c3 = a_tabCoef(2, 4);
c4 = a_tabCoef(2, 5);
c5 = a_tabCoef(2, 6);
c6 = a_tabCoef(2, 7);

phasePcorr = a_tPhaseDoxy + a_pCoef1 .* a_pres/1000;

calPhase = phaseCoef0 + phaseCoef1*phasePcorr + ...
   phaseCoef2*phasePcorr.^2 + phaseCoef3*phasePcorr.^3;

ksv = c0 + c1*a_temp + c2*a_temp.^2;

o_molarDoxy = (((c3 + c4*a_temp) ./ (c5 + c6*calPhase)) - 1) ./ ksv;

return;
