% ------------------------------------------------------------------------------
% Correct DO (in micromol/L) from salinity effect.
%
% SYNTAX :
%  [o_oxygenSalcomp] = calcoxy_salcomp_bis(a_oxygen, a_temp, a_psal, a_sRef, ...
%    a_d0, a_d1, a_d2, a_d3, a_sPreset, ...
%    a_b0_int, a_b1_int, a_b2_int, a_b3_int, a_c0_int, ...
%    a_b0, a_b1, a_b2, a_b3, a_c0)
%
% INPUT PARAMETERS :
%   a_oxygen     : DO values
%   a_temp       : TEMP values
%   a_psal       : PSAL values
%   a_sRef       : reference salinity given in the optode settings
%   a_d0 to a_c0 : additional coefficient values
%
% OUTPUT PARAMETERS :
%   o_oxygenSalcomp : DO values (in micromol/L) corrected from salinity effect
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2011 - Virginie THIERRY - creation
%   05/17/2016 - RNU - update
%   06/08/2016 - Henry BITTIG - separate Sref compensation from PSAL one
% ------------------------------------------------------------------------------
function [o_oxygenSalcomp] = calcoxy_salcomp_bis(a_oxygen, a_temp, a_psal, a_sRef, ...
   a_d0, a_d1, a_d2, a_d3, a_sPreset, ...
   a_b0_int, a_b1_int, a_b2_int, a_b3_int, a_c0_int, ...
   a_b0, a_b1, a_b2, a_b3, a_c0)

% water vapour effect
pH2O = @(t, s) 1013.25 .* exp(a_d0 + a_d1.*(100./(t+273.15)) + a_d2.*log(100./(t+273.15)) + a_d3.*s);
a = (1013.25 - pH2O(a_temp, a_sPreset))./(1013.25 - pH2O(a_temp, a_psal));

% salinity compensation correction
ts = log((298.15 - a_temp)./(273.15 + a_temp));

% only if MOLAR_DOXY is the transmitted parameter:
% otherwise a_sRef=0!
% remove the Aanderaa optode-internal or SBE63 optode-internal salinity
% compensation to re-obtain a freshwater MOLAR_DOXY
% the coefficients b0_int, b1_int, b2_int, b3_int, c0_int are hard-coded 
% into the optode, so depending on the manufacturer they are the Aanderaa
% (slightly different from b0, b1, ...) or Sea-Bird (same as b0, b1, ...)
% coefficients
a_oxygen_fresh = a_oxygen ./ exp(((a_sRef).*(a_b0_int + (a_b1_int.*ts) + (a_b2_int.*ts.^2)+(a_b3_int.*ts.^3))) + (a_c0_int.*(a_sRef.^2))); 

% and re-do the salinity compensation with the SCOR WG 142 recommendations
% including the water vapor effect on the solubility
o_oxygenSalcomp = a_oxygen_fresh .* a .* exp(((a_psal).*(a_b0 + (a_b1.*ts) + (a_b2.*ts.^2)+(a_b3.*ts.^3))) + (a_c0.*(a_psal.^2)));

return;
