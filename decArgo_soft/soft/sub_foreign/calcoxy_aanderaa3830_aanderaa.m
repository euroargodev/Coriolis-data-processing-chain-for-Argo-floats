% ------------------------------------------------------------------------------
% Compute the MOLAR_DOXY values in umol/L from the DPHASE_DOXY measurements
% reported by a AANDERAA 3830 optode using the Aanderaa standard calibration.
%
% SYNTAX :
%  [o_molarDoxy] = calcoxy_aanderaa3830_aanderaa( ...
%    a_dPhaseDoxy, a_pres, a_temp, a_tabCoef, ...
%    a_pCoef1)
%
% INPUT PARAMETERS :
%   a_dPhaseDoxy : DPHASE_DOXY sensor measurements
%   a_pres       : pressure in dbar
%   a_temp       : temperature from the CTD in °C
%   a_tabCoef    : calibration coefficients
%                  size(tabDoxyCoef) = 5 4 and tabDoxyCoef(i,j) = Cij.
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
function [o_molarDoxy] = calcoxy_aanderaa3830_aanderaa( ...
   a_dPhaseDoxy, a_pres, a_temp, a_tabCoef, ...
   a_pCoef1)

% Aanderaa standard calibration method

phasePcorr = a_dPhaseDoxy + a_pCoef1 .* a_pres/1000;

for idCoef = 1:5
   tmpCoef = a_tabCoef(idCoef, 1) + a_tabCoef(idCoef, 2)*a_temp + a_tabCoef(idCoef, 3)*a_temp.^2 + a_tabCoef(idCoef, 4)*a_temp.^3;
   eval(['C' num2str(idCoef-1) 'Coef=tmpCoef;']);
end
      
o_molarDoxy = C0Coef + C1Coef.*phasePcorr + C2Coef.*phasePcorr.^2 + C3Coef.*phasePcorr.^3 + C4Coef.*phasePcorr.^4;

return;
