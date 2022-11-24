% ------------------------------------------------------------------------------
% Convert sensor counts values for frequency output of SBE 43 IDO sensor.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_frequencyDoxy(a_sensorValue, a_frequencyDoxyDef)
%
% INPUT PARAMETERS :
%   a_sensorValue      : input frequency counts
%   a_frequencyDoxyDef : frequency default value
%
% OUTPUT PARAMETERS :
%   o_value : output frequency values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_frequencyDoxy(a_sensorValue, a_frequencyDoxyDef)

o_value = a_frequencyDoxyDef;

if ~((a_sensorValue == hex2dec('F000')) || (a_sensorValue == hex2dec('EFFF')) || (a_sensorValue == hex2dec('F001')))
   if (a_sensorValue < hex2dec('EFFF'))
      o_value = a_sensorValue;
   else
      o_value = twos_complement_dec_argo(a_sensorValue, 16);
   end
end


return
