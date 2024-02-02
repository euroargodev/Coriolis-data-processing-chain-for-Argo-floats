% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for salinity corrections.
%
% SYNTAX :
%  [o_tempCndcValues] = sensor_2_value_for_temp_cndc_224_226(a_tempCndcCounts)
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
function [o_tempCndcValues] = sensor_2_value_for_temp_cndc_224_226(a_tempCndcCounts)

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

% issue in TEMP_CNDC coding: we use the range ]27.767 ; 45.000] °C as TEMP_CNDC
% values cannot be in the ]-37.768 ; -20.535] interval
idKo = find(o_tempCndcValues(idNoDef) > 32767 & o_tempCndcValues(idNoDef) <= 50000); % 32767 = hex2dec('7FFF'), 50000 corresponds to 45°C
idOk = find(o_tempCndcValues(idNoDef) <= 32767 | o_tempCndcValues(idNoDef) > 50000);
o_tempCndcValues(idNoDef(idOk)) = twos_complement_dec_argo(o_tempCndcValues(idNoDef(idOk)), 16)/1000 - 5;
o_tempCndcValues(idNoDef(idKo)) = o_tempCndcValues(idNoDef(idKo))/1000 - 5;

return
