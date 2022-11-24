% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for air pump current.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_air_pump_current(a_sensorValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue : air pump current counts
% 
% OUTPUT PARAMETERS :
%   o_value : air pump current values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_air_pump_current(a_sensorValue)

o_value = a_sensorValue*(0.5/4096.0)*1000.0;

return
