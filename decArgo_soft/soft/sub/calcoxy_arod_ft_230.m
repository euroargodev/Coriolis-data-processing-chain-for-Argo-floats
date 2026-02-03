% ------------------------------------------------------------------------------
% Compute the MOLAR_DOXY values in umol/L from the COUNT_DOXY and
% LED_FLASHING_COUNT_DOXY measurements reported by an AROD_FT optode.
%
% SYNTAX :
% [o_molarDoxy] = calcoxy_arod_ft_230( ...
%   a_countDoxy, a_ledFlashingCountDoxy, a_temp, ...
%   doxyCoefC, doxyCoefD, doxyCoefE)
%
% INPUT PARAMETERS :
%   a_countDoxy            : input COUNT_DOXY optode data
%   a_ledFlashingCountDoxy : input LED_FLASHING_COUNT_DOXY optode data
%   a_temp                 : input TEMP CTD data
%
% OUTPUT PARAMETERS :
%   o_molarDoxy : output MOLAR_DOXY data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_molarDoxy] = calcoxy_arod_ft_230( ...
   a_countDoxy, a_ledFlashingCountDoxy, a_temp, ...
   doxyCoefC, doxyCoefD, doxyCoefE)

% calibration coefficients
doxyCoefC0 = doxyCoefC(1);
doxyCoefC1 = doxyCoefC(2);
doxyCoefC2 = doxyCoefC(3);
doxyCoefD0 = doxyCoefD(1);
doxyCoefD1 = doxyCoefD(2);
doxyCoefD2 = doxyCoefD(3);
doxyCoefD3 = doxyCoefD(4);
doxyCoefD4 = doxyCoefD(5);
doxyCoefE0 = doxyCoefE(1);

% compute MOLAR_DOXY according to §7.2.40 of Argo DOXY cookbook
% (https://dx.doi.org/10.13155/39795)
N = a_countDoxy * 0.0001;
T = a_ledFlashingCountDoxy * 0.01;
partA = 1 + doxyCoefD0 * a_temp;
partB = doxyCoefD1 + doxyCoefD2 * N + doxyCoefD3 * T + doxyCoefD4 .* T .* N;
partC = a_temp .* (a_temp .* doxyCoefC2 + doxyCoefC1) + doxyCoefC0;

o_molarDoxy = ((partA ./ partB) .^ doxyCoefE0 - 1) ./ partC;

return
