% ------------------------------------------------------------------------------
% Compute the PRES adjusted values.
%
% SYNTAX :
%  [o_adjData] = compute_adjusted_pres(a_data, a_presOffset)
%
% INPUT PARAMETERS :
%   a_data       : input data
%   a_presOffset : pressure offset
%
% OUTPUT PARAMETERS :
%   o_adjData : output adjusted data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_adjData] = compute_adjusted_pres(a_data, a_presOffset)

o_adjData = a_data;
paramPres = get_netcdf_param_attributes('PRES');
idNoDef = find(o_adjData ~= paramPres.fillValue);
o_adjData(idNoDef) = o_adjData(idNoDef) - a_presOffset;

return
