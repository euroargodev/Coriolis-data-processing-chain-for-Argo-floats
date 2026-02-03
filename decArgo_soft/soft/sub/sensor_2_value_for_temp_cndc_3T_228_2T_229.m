% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for salinity corrections.
%
% SYNTAX :
%  [o_tempCndcValues] = sensor_2_value_for_temp_cndc_3T_228_2T_229(a_tempCndcCounts)
%
% INPUT PARAMETERS :
%   a_tempCndcCounts : salinity correction counts
%
% OUTPUT PARAMETERS :
%   o_tempCndcValues : salinity correction values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/22/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tempCndcValues] = sensor_2_value_for_temp_cndc_3T_228_2T_229(a_tempCndcCounts)

% output parameters initialization
o_tempCndcValues = [];

% default values
global g_decArgo_tempDef;
global g_decArgo_tempCountsDef;

% convert counts to values
o_tempCndcValues = a_tempCndcCounts;
idDef = find(a_tempCndcCounts == g_decArgo_tempCountsDef);
o_tempCndcValues(idDef) = ones(length(idDef), 1)*g_decArgo_tempDef;
idNoDef = find(a_tempCndcCounts ~= g_decArgo_tempCountsDef);
o_tempCndcValues(idNoDef) = o_tempCndcValues(idNoDef)/1000;

return
