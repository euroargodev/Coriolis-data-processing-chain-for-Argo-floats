% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for air bladder pressure.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_air_bladder_pressure(a_sensorValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue : air bladder pressure counts
% 
% OUTPUT PARAMETERS :
%   o_value : air bladder pressure values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_air_bladder_pressure(a_sensorValue)

o_value = a_sensorValue*(20.852/4096.0);

return
