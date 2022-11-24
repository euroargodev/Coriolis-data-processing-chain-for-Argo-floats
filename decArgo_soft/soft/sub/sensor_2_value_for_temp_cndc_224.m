% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for salinity corrections.
%
% SYNTAX :
%  [o_tempCndcValues] = sensor_2_value_for_temp_cndc_224(a_tempCndcCounts)
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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tempCndcValues] = sensor_2_value_for_temp_cndc_224(a_tempCndcCounts)

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
o_tempCndcValues(idNoDef) = twos_complement_dec_argo(o_tempCndcValues(idNoDef), 16)/1000 - 5;

return
