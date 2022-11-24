% ------------------------------------------------------------------------------
% Read the file containing the sensors mounted on he floats (one line per
% sensor).
%
% SYNTAX :
%  [o_wmoSensorList, o_nameSensorList] = get_sensor_list(a_sensorListFileName)
%
% INPUT PARAMETERS :
%   a_sensorListFileName : list of sensors mounted on floats
%
% OUTPUT PARAMETERS :
%   o_wmoSensorList  : floats WMO number
%   o_nameSensorList : floats senssor names
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_wmoSensorList, o_nameSensorList] = get_sensor_list(a_sensorListFileName)

% output parameters initialization
o_wmoSensorList = [];
o_nameSensorList = [];


if ~(exist(a_sensorListFileName, 'file') == 2)
   fprintf('ERROR: Float information file not found: %s\n', a_sensorListFileName);
   return
end

fId = fopen(a_sensorListFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', a_sensorListFileName);
end

data = textscan(fId, '%d %s');

o_wmoSensorList = data{1}(:);
o_nameSensorList = data{2}(:);

fclose(fId);

return
