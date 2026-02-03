% ------------------------------------------------------------------------------
% Convert sensor counts to physical values for current.
%
% SYNTAX :
%  [o_value] = sensor_2_value_for_apex_apf9_current(a_sensorValue)
%
% INPUT PARAMETERS :
%   a_sensorValue : current counts
%
% OUTPUT PARAMETERS :
%   o_value : current values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/23/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_value] = sensor_2_value_for_apex_apf9_current(a_sensorValue)

o_value = a_sensorValue*4.052 - 3.606;

return
