% ------------------------------------------------------------------------------
% Convert sensor counts values for B phase.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_bPhaseDoxy(a_sensorValue, a_bPhaseDoxyDef)
%
% INPUT PARAMETERS :
%   a_sensorValue   : input B phase counts
%   a_bPhaseDoxyDef : B phase default value
%
% OUTPUT PARAMETERS :
%   o_phaseValues : output B phase values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_bPhaseDoxy(a_sensorValue, a_bPhaseDoxyDef)

o_value = a_bPhaseDoxyDef;

if ~((a_sensorValue == hex2dec('FFD')) || (a_sensorValue == hex2dec('FFE')) || (a_sensorValue == hex2dec('000')))
   o_value = (a_sensorValue/100) + 23;
end

return
