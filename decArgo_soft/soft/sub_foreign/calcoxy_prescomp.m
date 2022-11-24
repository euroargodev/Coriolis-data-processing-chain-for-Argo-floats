% Fonction qui corrige de l'effet de pression
% une concentration d'oxygène en micromol/l
%
% entrée:
%        oxygen: concentration d'oxygène en micromol/l
%        pres: pression en dbar
% sortie:
%        oxygen_prescomp: concentration d'oxygène dissous 
%                        en micromol/l corrigée de l'effet de pression
%

function oxygen_prescomp=calcoxy_prescomp(oxygen,pres)

% Pression compensation correction
oxygen_prescomp = oxygen .*(1+0.032.*pres/1000);
