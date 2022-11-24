% ------------------------------------------------------------------------------
% Compute the MOLAR_DOXY values in umol/L from the TPHASE_DOXY measurements
% reported by a AANDERAA 4330 optode using the Aanderaa standard calibration or
% the Aanderaa standard calibration + an additional two-point adjustment.
%
% SYNTAX :
%  [o_molarDoxy] = calcoxy_aanderaa4330_aanderaa( ...
%    a_tPhaseDoxy, a_pres, a_temp, a_tabCoef, ...
%    a_pCoef1, a_a0, a_a1, a_a2, a_a3, a_a4, a_a5)
%
% INPUT PARAMETERS :
%   a_tPhaseDoxy : TPHASE_DOXY sensor measurements
%   a_pres       : pressure in dbar
%   a_temp       : temperature measurement values in °C (from the optode if
%                  available, from the CTD otherwise)
%   a_tabCoef    : calibration coefficients
%                  For the Aanderaa standard calibration method:
%                      size(a_tabCoef) = 5 28 and
%                      a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
%                      a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
%                      a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
%                      a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
%                      a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
%                  For the Aanderaa standard calibration  + an additional two-point adjustment method:
%                      size(a_tabCoef) = 6 28 and
%                      a_tabCoef(1, 1:4) = [PhaseCoef0 PhaseCoef1 ... PhaseCoef3]
%                      a_tabCoef(2, 1:6) = [TempCoef0 TempCoef1 ... TempCoef5]
%                      a_tabCoef(3, 1:28) = [FoilCoefA0 FoilCoefA1 ... FoilCoefA13 FoilCoefB0 FoilCoefB1 ... FoilCoefB13]
%                      a_tabCoef(4, 1:28) = [FoilPolyDegT0 FoilPolyDegT1 ... FoilPolyDegT27]
%                      a_tabCoef(5, 1:28) = [FoilPolyDegO0 FoilPolyDegO1 ... FoilPolyDegO27]
%                      a_tabCoef(6, 1:2) = [ConcCoef0 ConcCoef1]
%   a_pCoef1      : additional coefficient value
%   a_a0 to a_a5  : additional coefficient values
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
function [o_molarDoxy] = calcoxy_aanderaa4330_aanderaa( ...
   a_tPhaseDoxy, a_pres, a_temp, a_tabCoef, ...
   a_pCoef1, a_a0, a_a1, a_a2, a_a3, a_a4, a_a5)

% retrieve global coefficient default values
global g_decArgo_doxy_nomAirPress;
global g_decArgo_doxy_nomAirMix;


% Aanderaa standard calibration method

phaseCoef0 = a_tabCoef(1, 1);
phaseCoef1 = a_tabCoef(1, 2);
phaseCoef2 = a_tabCoef(1, 3);
phaseCoef3 = a_tabCoef(1, 4);

phasePcorr = a_tPhaseDoxy + a_pCoef1 .* a_pres/1000;

calPhase = phaseCoef0 + phaseCoef1*phasePcorr + ...
   phaseCoef2*phasePcorr.^2 + phaseCoef3*phasePcorr.^3;

deltaP = zeros(size(a_temp));
for i = 1:28
   deltaP = deltaP + a_tabCoef(3, i) * (a_temp.^a_tabCoef(4, i)) .* (calPhase.^a_tabCoef(5, i));
end

nomAirPress = g_decArgo_doxy_nomAirPress;
nomAirMix = g_decArgo_doxy_nomAirMix;

pVapour = exp(52.57 - 6690.9./(a_temp + 273.15) - 4.681*log(a_temp + 273.15));
airSat = deltaP .* 100 ./ ((nomAirPress - pVapour)*nomAirMix);

ts = log((298.15 - a_temp)./(273.15 + a_temp));
expo = a_a0 + a_a1*ts + a_a2*ts.^2 + a_a3*ts.^3 + a_a4*ts.^4 + a_a5*ts.^5;
cStar = exp(expo);

o_molarDoxy = cStar*44.614.*airSat/100;

% additional two-point adjustment
if (size(a_tabCoef, 1) == 6)
   o_molarDoxy = a_tabCoef(6,1) + a_tabCoef(6,2)*o_molarDoxy;
end

return
