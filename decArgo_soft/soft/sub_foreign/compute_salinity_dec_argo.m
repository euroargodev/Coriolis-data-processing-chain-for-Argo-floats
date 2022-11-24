% ------------------------------------------------------------------------------
% Détermination de la salinité à partir de la pression, température et
% conductivité (formule fournie par P.BRANNELEC (le 25/02/2009)).
%
% ************************************************************
% * METHODE 1 : CALCUL DE LA SALINITE A PARTIR DE ( P T C )
% * PRACTICAL SALINITY SCALE 1978 : E.L. LEWIS - R.G. PERKIN
% * DEEP-SEA RESEARCH , VOL. 28A , N0 4 , PP. 307 -328 , 1981
% * METHODE PRECONISEE PAR "WORKING DRAFT OF S.C.O.R. (WG51)"
% * C(35.15.0) =CNO68 =42.914 
% * DEEP-SEA RESEARCH , VOL. 23 , PP.157-165 , 1976
% ************************************************************
%
% Modification : le 4/5/93 par C.Lagadec
% --------------
%                changement de la valeur de CN068
%
% Les calculs sont faits en IPTS68.
% Si la température est données dans l'échelle IPTS90 (ce qui est le cas pour
% les flotteurs Argo), il faut la transformer en température donnée dans
% l'échelle IPTS68.
%
% SYNTAX :
%   [o_salinity] = compute_salinity_dec_argo(a_pressure, a_temperature, a_conductivity)
%
% INPUT PARAMETERS :
%   a_pressure     : pression
%   a_temperature  : température
%   a_conductivity : conductivité
%
% OUTPUT PARAMETERS :
%   o_salinity : salinité calculée
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/03/2009 - RNU - creation
% ------------------------------------------------------------------------------
function [o_salinity] = compute_salinity_dec_argo(a_pressure, a_temperature, a_conductivity)

o_salinity = [];

P = a_pressure;
T = a_temperature*1.00024; % température IPST90 transformée en IPTS68
% T = a_temperature;
C = a_conductivity;

CNO68 = 42.914;

R = C/CNO68;
C0 = 0.6766097;
C1 = 2.00564e-2;
C2 = 1.104259e-4;
C3 = -6.9698e-7;
C4 = 1.0031e-9;
RTEMP = ((((C4*T)+C3)*T+C2)*T+C1)*T+C0;

E1 = 2.07e-5;
E2 = -6.37e-10;
E3 = 3.989e-15;
CXP = (((E3*P)+E2)*P+E1)*P;

D1 = 3.426e-2;
D2 = 4.464e-4;
D3 = 4.215e-1;
D4 = -3.107e-3;
AXT = (D4*T+D3)*R;
BXT = ((D2*T)+D1)*T+1.;
RP = CXP/(AXT+BXT)+1.;
RT = R/(RP*RTEMP);

A0 = 0.008;
A1 = -0.1692;
A2 = 25.3851;
A3 = 14.0941;
A4 = -7.0261;
A5 = 2.7081;
B0 = 0.0005;
B1 = -0.0056;
B2 = -0.0066;
B3 = -0.0375;
B4 = 0.0636;
B5 = -0.0144;
DS = (T-15.)/((T-15.)*0.0162+1.);
S = (B5*DS+A5)*RT^2.5+(B4*DS+A4)*RT*RT+(B3*DS+A3)*RT^1.5;
S = S+(B2*DS+A2)*RT+(B1*DS+A1)*RT^.5+(B0*DS+A0);
XS = S;

o_salinity = XS;

return;
