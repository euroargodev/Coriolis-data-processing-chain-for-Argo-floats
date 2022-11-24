% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for battery voltage.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_battery_voltage(a_sensorValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue : battery voltage counts
% 
% OUTPUT PARAMETERS :
%   o_value : battery voltage values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_battery_voltage(a_sensorValue)

o_value = a_sensorValue*(18.0/4096.0);

return
