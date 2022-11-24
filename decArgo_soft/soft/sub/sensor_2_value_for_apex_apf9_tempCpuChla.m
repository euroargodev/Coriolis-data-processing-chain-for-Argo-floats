% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for TEMP_CPU_CHLA.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_tempCpuChla(a_sensorValue, a_defaultValue)
%
% INPUT PARAMETERS :
%   a_sensorValue  : TEMP_CPU_CHLA counts
%   a_defaultValue : TEMP_CPU_CHLA default value
%
% OUTPUT PARAMETERS :
%   o_value : TEMP_CPU_CHLA values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_tempCpuChla(a_sensorValue, a_defaultValue)

o_value = a_defaultValue;

if ~((a_sensorValue == hex2dec('80')) || (a_sensorValue == hex2dec('7F')) || (a_sensorValue == hex2dec('81')))
   if (a_sensorValue > hex2dec('80'))
      o_value = a_sensorValue - 256;
   else
      o_value = a_sensorValue;
   end
   o_value = o_value + 512;
end

return
