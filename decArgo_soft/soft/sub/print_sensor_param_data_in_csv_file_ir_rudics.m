% ------------------------------------------------------------------------------
% Print sensor parameter data in output CSV file.
%
% SYNTAX :
%  print_sensor_param_data_in_csv_file_ir_rudics( ...
%    a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
%    a_sensorParam)
%
% INPUT PARAMETERS :
%   a_cyProfPhaseList      : information (cycle #, prof #, phase #) on each
%                            received packet
%   a_cyProfPhaseIndexList : index list of the data to print
%   a_sensorParam          : sensor parameter data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function print_sensor_param_data_in_csv_file_ir_rudics( ...
   a_cyProfPhaseList, a_cyProfPhaseIndexList, ...
   a_sensorParam)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% unpack the input data
a_sensorParamModSensorNum = a_sensorParam{1};
a_sensorParamParamType = a_sensorParam{2};
a_sensorParamParamNum = a_sensorParam{3};
a_sensorParamOldVal = a_sensorParam{4};
a_sensorParamNewVal = a_sensorParam{5};

% packet type 251

% index list of the data
typeDataList = find(a_cyProfPhaseList(:, 1) == 251);
dataIndexList = [];
for id = 1:length(a_cyProfPhaseIndexList)
   dataIndexList = [dataIndexList; find(typeDataList == a_cyProfPhaseIndexList(id))];
end

% print the sensor parameter data
fprintf(g_decArgo_outputCsvFileId, '%d; %d; -; %s; Sensor param; Mod. sensor #; Param type; Param #; Old value; New value\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, get_phase_name(-1));

data = [];
for idL = 1:length(dataIndexList)
   data = [data; ...
      a_sensorParamModSensorNum(dataIndexList(idL), :)' ...
      a_sensorParamParamType(dataIndexList(idL), :)' ...
      a_sensorParamParamNum(dataIndexList(idL), :)' ...
      a_sensorParamOldVal(dataIndexList(idL), :)' ...
      a_sensorParamNewVal(dataIndexList(idL), :)'];
end
 
for idL = 1:size(data, 1)
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; -; %s; Sensor param; %d; %d; %d; %g; %g\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum, get_phase_name(-1), ...
   data(idL, :));
end

return
