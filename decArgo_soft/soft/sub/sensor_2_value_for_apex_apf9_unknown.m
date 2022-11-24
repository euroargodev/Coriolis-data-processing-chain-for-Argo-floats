% ------------------------------------------------------------------------------
% Convert sensor counts values for UNKNOWN parameter.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_unknown(a_sensorValue, a_defaultValue)
%
% INPUT PARAMETERS :
%   a_sensorValue   : UNKNOWN parameter counts
%   a_defaultValue : UNKNOWN parameter default value
%
% OUTPUT PARAMETERS :
%   o_phaseValues : UNKNOWN parameter values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_unknown(a_sensorValue, a_defaultValue)

o_value = a_defaultValue;

if ~((a_sensorValue == hex2dec('FFD')) || (a_sensorValue == hex2dec('FFE')) || (a_sensorValue == hex2dec('000')))
   o_value = a_sensorValue;
end

return
