% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for DOXY temperature.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_tempDoxy(a_sensorValue, a_tempDoxyDef)
%
% INPUT PARAMETERS :
%   a_sensorValue : DOXY temperature counts
%   a_tempDoxyDef : DOXY temperature default value
%
% OUTPUT PARAMETERS :
%   o_value : DOXY temperature values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_tempDoxy(a_sensorValue, a_tempDoxyDef)

o_value = a_tempDoxyDef;

if ~((a_sensorValue == hex2dec('FFE')) || (a_sensorValue == hex2dec('FFD')) || (a_sensorValue == hex2dec('000')))
   o_value = (a_sensorValue/100) - 3;
end

return
