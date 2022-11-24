% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for FLUORESCENCE_CHLA.
% 
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_fluorescenceChla(a_sensorValue, a_defaultValue)
% 
% INPUT PARAMETERS :
%   a_sensorValue  : FLUORESCENCE_CHLA counts
%   a_defaultValue : FLUORESCENCE_CHLA default value
% 
% OUTPUT PARAMETERS :
%   o_value : FLUORESCENCE_CHLA values
% 
% EXAMPLES :
% 
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_fluorescenceChla(a_sensorValue, a_defaultValue)

o_value = a_defaultValue;

if ~((a_sensorValue == hex2dec('FFE')) || (a_sensorValue == hex2dec('FFD')) || (a_sensorValue == hex2dec('000')))
   o_value = a_sensorValue;
end

return
