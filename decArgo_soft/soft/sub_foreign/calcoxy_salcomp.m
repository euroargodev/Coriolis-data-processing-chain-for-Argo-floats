% Fonction qui corrige de l'effet de salinité
% une concentration d'oxygène en micromol/l
%
% entrée:
%        oxygen: concentration d'oxygène en micromol/l
%        temp: température de l'otpode en °C
%        psal: salinité
%        Sref: salinité de référence de l'optode
% sortie:
%        oxygen_salcomp: concentration d'oxygène dissous 
%                        en micromol/l corrigée de l'effet de salinité
%

function oxygen_salcomp=calcoxy_salcomp(oxygen,psal,temp,Sref)

% Salinity compensation correction
ts = log((298.15-temp)./(273.15+temp));


   B0 = -6.24097e-3;
   B1 = -6.93498e-3;
   B2 = -6.90358e-3;
   B3 = -4.29155e-3;
   C0 = -3.11680e-7;

oxygen_salcomp = oxygen .* exp(((psal-Sref).*(B0+(B1.*ts)+(B2.*ts.^2)+(B3.*ts.^3)))+(C0.*(psal.^2 -Sref*Sref)));
