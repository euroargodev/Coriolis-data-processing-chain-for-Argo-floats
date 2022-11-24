% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for salinity.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_salinity(a_sensorValue, a_salDef)
%
% INPUT PARAMETERS :
%   a_sensorValue : salinity counts
%   a_salDef      : salinity default value
%
% OUTPUT PARAMETERS :
%   o_value : salinity value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_salinity(a_sensorValue, a_salDef)

o_value = a_salDef;

if ~((a_sensorValue == hex2dec('EFFF')) || (a_sensorValue == hex2dec('F000')) || (a_sensorValue == hex2dec('F001')))
   if (a_sensorValue < hex2dec('EFFF'))
      o_value = a_sensorValue/1000;
   else
      o_value = twos_complement_dec_argo(a_sensorValue, 16)/1000;
   end
end

return
