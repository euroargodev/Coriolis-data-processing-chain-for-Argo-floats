% ------------------------------------------------------------------------------
% Retrieve the list of sensors mounted on a given APEX APF11 float.
%
% SYNTAX :
%  [o_sensorList] = get_sensor_list_apex_apf11(a_floatNum)
%
% INPUT PARAMETERS :
%   a_floatNum : WMO number of the concerned float
%
% OUTPUT PARAMETERS :
%   o_sensorList : list of sensors mounted on the float
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sensorList] = get_sensor_list_apex_apf11(a_floatNum)

o_sensorList = [];

% get the list of sensors for this float
switch a_floatNum
   case { ...
         3901988, ...
         }
      o_sensorList = [{'CTD'}];
   case { ...
         3901667, ...
         3901668, ...
         3901669, ...
         }
      o_sensorList = [{'CTD'}; {'OPTODE'}; {'TRANSISTOR_PH'}];
   otherwise
      fprintf('ERROR: Unknown sensor list for float #%d => nothing done for this float\n', a_floatNum);
end

return;
