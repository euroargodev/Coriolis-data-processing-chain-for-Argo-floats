% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for CTD current.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf11_ctd_current(a_sensorValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue : CTD current counts
% 
% OUTPUT PARAMETERS :
%   o_value : CTD current values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf11_ctd_current(a_sensorValue)

o_value = a_sensorValue*(0.05/4096.0)*1000.0;

return
