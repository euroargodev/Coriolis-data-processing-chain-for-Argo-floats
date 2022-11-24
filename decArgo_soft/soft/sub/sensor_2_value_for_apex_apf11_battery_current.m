% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for battery current.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_battery_current(a_sensorValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue : battery current counts
% 
% OUTPUT PARAMETERS :
%   o_value : battery current values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_battery_current(a_sensorValue)

o_value = a_sensorValue*0.07813;

return
