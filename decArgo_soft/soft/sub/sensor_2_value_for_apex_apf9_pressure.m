% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for (2 bytes coded) pressure.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_pressure(a_sensorValue, a_presDef)
%
% INPUT PARAMETERS :
%   a_sensorValue : pressure counts
%   a_presDef     : pressure default value
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
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_pressure(a_sensorValue, a_presDef)

o_value = a_presDef;

if ~((a_sensorValue == hex2dec('7FFF')) || (a_sensorValue == hex2dec('8000')) || (a_sensorValue == hex2dec('8001')))
   if (a_sensorValue < hex2dec('7FFF'))
      o_value = a_sensorValue/10;
   else
      o_value = twos_complement_dec_argo(a_sensorValue, 16)/10;
   end
end

return
