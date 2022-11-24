% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for vacuum.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_vacuum(a_sensorValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue : vacuum counts
% 
% OUTPUT PARAMETERS :
%   o_value : vacuum values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_vacuum(a_sensorValue)

o_value = a_sensorValue*(10.4302/4096.0);

return
