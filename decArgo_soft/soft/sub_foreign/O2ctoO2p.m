function pO2=O2ctoO2p(O2conc,T,S,P, a_d0, a_d1, a_d2, a_d3, a_b0, a_b1, a_b2, a_b3, a_c0)
%function pO2=O2ctoO2p(O2conc,temp,sal,pres)
%
% convert molar oxygen concentration to oxygen partial pressure
%
% inputs:
%   O2conc - oxygen concentration in umol L-1
%   T      - temperature in °C
%   S      - salinity (PSS-78)
%   P      - hydrostatic pressure in dbar (default: 0 dbar)
%
% output:
%   pO2    - oxygen partial pressure in mbar
%
% according to recommendations by SCOR WG 142 "Quality Control Procedures
% for Oxygen and Other Biogeochemical Sensors on Floats and Gliders"
%
% Henry Bittig
% Laboratoire d'Océanographie de Villefranche-sur-Mer, France
% bittig@obs-vlfr.fr
% 28.10.2015

% set input default
% if nargin<4, P     = 0;       end

xO2     = 0.20946; % mole fraction of O2 in dry air (Glueckauf 1951)
pH2Osat = 1013.25 .* (exp(a_d0 + (a_d1*(100./(T+273.15))) + (a_d2*log(((273.15+T)./100))) + a_d3.*S)); % saturated water vapor in mbar
sca_T   = log((298.15-T) ./ (273.15+T)); % scaled temperature for use in TCorr and SCorr
TCorr   = 44.6596.*exp(2.00907 + 3.22014.*sca_T + 4.05010.*sca_T.^2 + 4.94457.*sca_T.^3 - 2.56847e-1.*sca_T.^4 + 3.88767.*sca_T.^5); % temperature correction part from Garcia and Gordon (1992), Benson and Krause (1984) refit mL(STP) L-1; and conversion from mL(STP) L-1 to umol L-1
Scorr   = exp(S.*(a_b0 + a_b1.*sca_T + a_b2.*sca_T.^2 + a_b3.*sca_T.^3) + a_c0.*S.^2); % salinity correction part from Garcia and Gordon (1992), Benson and Krause (1984) refit ml(STP) L-1
Vm      = 0.317; % molar volume of O2 in m3 mol-1 Pa dbar-1 (Enns et al. 1965)
R       = 8.314; % universal gas constant in J mol-1 K-1

pO2 = O2conc .* (xO2.*(1013.25-pH2Osat)) ./ (TCorr.*Scorr) .* exp(Vm.*P ./ (R.*(T+273.15)));