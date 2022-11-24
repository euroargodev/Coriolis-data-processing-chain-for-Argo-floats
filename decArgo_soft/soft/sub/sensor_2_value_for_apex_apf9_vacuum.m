% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for vacuum.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_vacuum(a_sensorValue)
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
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_vacuum(a_sensorValue)

o_value = a_sensorValue*0.293 - 29.767;

return
