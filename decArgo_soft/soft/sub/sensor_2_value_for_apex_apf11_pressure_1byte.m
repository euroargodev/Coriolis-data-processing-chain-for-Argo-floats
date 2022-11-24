% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for (1 byte coded) pressure.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_pressure_1byte(a_sensorValue)
%
% INPUT PARAMETERS :
%   a_sensorValue : pressure counts
%
% OUTPUT PARAMETERS :
%   o_value : pressure values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_pressure_1byte(a_sensorValue)

if (a_sensorValue > 127)
   o_value = (256 - a_sensorValue)*(-1);
else
   o_value = a_sensorValue;
end
o_value = o_value/10;

return
