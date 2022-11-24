% ------------------------------------------------------------------------------
% Correct DO (in micromol/L) from pressure effect.
%
% SYNTAX :
%  [o_oxygenPrescomp] = calcoxy_prescomp(a_oxygen, a_pres, a_temp, ...
%    a_pCoef2, a_pCoef3)
%
% INPUT PARAMETERS :
%   a_oxygen              : DO values
%   a_pres                : PRES values
%   a_temp                : TEMP values
%   a_pCoef2 and a_pCoef3 : additional coefficient values
%
% OUTPUT PARAMETERS :
%   o_oxygenPrescomp : DO values (in micromol/L) corrected from pressure effect
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/20/2011 - Virginie THIERRY - creation
%   05/17/2016 - RNU - update
% ------------------------------------------------------------------------------
function [o_oxygenPrescomp] = calcoxy_prescomp(a_oxygen, a_pres, a_temp, ...
   a_pCoef2, a_pCoef3)

% pressure compensation correction
o_oxygenPrescomp = a_oxygen .* (1 + ((a_pCoef2 .* a_temp) + a_pCoef3) .* a_pres/1000);

return
