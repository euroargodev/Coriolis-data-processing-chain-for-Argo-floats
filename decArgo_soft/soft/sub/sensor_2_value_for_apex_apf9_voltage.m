% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for voltage.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_voltage(a_sensorValue)
%
% INPUT PARAMETERS :
%   a_sensorValue : voltage counts
%
% OUTPUT PARAMETERS :
%   o_value : voltage values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_voltage(a_sensorValue)

o_value = a_sensorValue*0.077 + 0.486;

return
