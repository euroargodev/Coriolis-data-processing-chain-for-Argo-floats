% ------------------------------------------------------------------------------
% Convert sensor counts values for T phase.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_tPhaseDoxy(a_sensorValue, a_tPhaseDoxyDef)
%
% INPUT PARAMETERS :
%   a_sensorValue   : input T phase counts
%   a_tPhaseDoxyDef : T phase default value
%
% OUTPUT PARAMETERS :
%   o_value : output T phase values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_tPhaseDoxy(a_sensorValue, a_tPhaseDoxyDef)

% TPHASE_DOXY is coded on 14 bits, the conversion equation has been retrieved
% from DANA Swift's code

o_value = a_tPhaseDoxyDef;

if ~((a_sensorValue == hex2dec('3FFE')) || (a_sensorValue == hex2dec('3FFD')) || (a_sensorValue == hex2dec('0000')))
   o_value = (a_sensorValue/250) + 10;
end

return
