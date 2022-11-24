% ------------------------------------------------------------------------------
% Convert sensor counts values for R phase.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_rPhaseDoxy(a_sensorValue, a_rPhaseDoxyDef)
%
% INPUT PARAMETERS :
%   a_sensorValue   : input R phase counts
%   a_rPhaseDoxyDef : R phase default value
%
% OUTPUT PARAMETERS :
%   o_value : output R phase values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/09/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_rPhaseDoxy(a_sensorValue, a_rPhaseDoxyDef)

% RPHASE_DOXY is coded on 6 bits, the conversion equation has been retrieved
% from DANA Swift's code

o_value = a_rPhaseDoxyDef;

if ~((a_sensorValue == hex2dec('3E')) || (a_sensorValue == hex2dec('3D')) || (a_sensorValue == hex2dec('00')))
   o_value = (a_sensorValue/10) + 2.6;
end

return
