% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for salinity.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_salinity(a_sensorValue)
%
% INPUT PARAMETERS :
%   a_sensorValue : salinity counts
%
% OUTPUT PARAMETERS :
%   o_value : salinity values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_salinity(a_sensorValue)

o_value = a_sensorValue/1000;

return
