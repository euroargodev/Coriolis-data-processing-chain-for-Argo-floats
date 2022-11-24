% ------------------------------------------------------------------------------
% Compute the MLPL_DOXY values in ml/l from the PHASE_DELAY_DOXY measurements
% reported by a SBE63 sensor.
%
% SYNTAX :
%  [o_mlplDoxy] = calcoxy_sbe63_sternvolmer( ...
%    a_phaseDelayDoxy, a_pres, a_tempDoxy, a_tabCoef, a_pCoef1)
%
% INPUT PARAMETERS :
%   a_phaseDelayDoxy : outpout from SBE63's sensor (delay in microsecond)
%   a_pres           : pressure in dbar
%   a_tempDoxy       : temperature output from SBE 63's thermistor in °C
%   a_tabcoef        : calibration coefficients
%                      size(a_tabcoef) = 1 9 and
%                         a_tabcoef(1:3) = [A0 A1 A2]
%                         a_tabcoef(4:5) = [B0 B1]
%                         a_tabcoef(6:8) = [C0 C1 C2]
%                         a_tabcoef(9) = E
%   a_pCoef1         : additional coefficient value
%
% OUTPUT PARAMETERS :
%   o_mlplDoxy : MLPL_DOXY values (oxygen concentration in ml/L)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Virginie Thierry (IFREMER/LPO)(Virginie.Thierry@ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/03/2014 - VT - creation
% ------------------------------------------------------------------------------
function [o_mlplDoxy] = calcoxy_sbe63_sternvolmer( ...
   a_phaseDelayDoxy, a_pres, a_tempDoxy, a_tabCoef, a_pCoef1)

% Stern-Volmer calibration method

a0 = a_tabCoef(1);
a1 = a_tabCoef(2);
a2 = a_tabCoef(3);
b0 = a_tabCoef(4);
b1 = a_tabCoef(5);
c0 = a_tabCoef(6);
c1 = a_tabCoef(7);
c2 = a_tabCoef(8);

v = (a_phaseDelayDoxy + a_pCoef1 .* a_pres/1000)/39.457071;

ksv = c0 + c1*a_tempDoxy + c2*a_tempDoxy.*a_tempDoxy;

o_mlplDoxy = (((a0 + a1*a_tempDoxy + a2*v.*v) ./ (b0 + b1*v) - 1) ./ ksv);

return;
