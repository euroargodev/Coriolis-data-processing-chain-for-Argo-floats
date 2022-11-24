% ------------------------------------------------------------------------------
% Process FLNTU sensor technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_sensor_tech_data_ir_sbd2_SEAPOINT( ...
%    a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechSEAPOINT)
%
% INPUT PARAMETERS :
%   a_cycleNum           : cycle number of the packet
%   a_profNum            : profile number of the packet
%   a_dataIndex          : index of the packet
%   a_sensorTechSEAPOINT : SEAPOINT technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function process_sensor_tech_data_ir_sbd2_SEAPOINT( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechSEAPOINT)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


% unpack the input data
a_sensorTechSEAPOINTNbPackDesc = a_sensorTechSEAPOINT{1};
a_sensorTechSEAPOINTNbPackDrift = a_sensorTechSEAPOINT{2};
a_sensorTechSEAPOINTNbPackAsc = a_sensorTechSEAPOINT{3};
a_sensorTechSEAPOINTNbMeasDescZ1 = a_sensorTechSEAPOINT{4};
a_sensorTechSEAPOINTNbMeasDescZ2 = a_sensorTechSEAPOINT{5};
a_sensorTechSEAPOINTNbMeasDescZ3 = a_sensorTechSEAPOINT{6};
a_sensorTechSEAPOINTNbMeasDescZ4 = a_sensorTechSEAPOINT{7};
a_sensorTechSEAPOINTNbMeasDescZ5 = a_sensorTechSEAPOINT{8};
a_sensorTechSEAPOINTNbMeasDrift = a_sensorTechSEAPOINT{9};
a_sensorTechSEAPOINTNbMeasAscZ1 = a_sensorTechSEAPOINT{10};
a_sensorTechSEAPOINTNbMeasAscZ2 = a_sensorTechSEAPOINT{11};
a_sensorTechSEAPOINTNbMeasAscZ3 = a_sensorTechSEAPOINT{12};
a_sensorTechSEAPOINTNbMeasAscZ4 = a_sensorTechSEAPOINT{13};
a_sensorTechSEAPOINTNbMeasAscZ5 = a_sensorTechSEAPOINT{14};
a_sensorTechSEAPOINTSensorState = a_sensorTechSEAPOINT{15};
a_sensorTechSEAPOINTAverageSampleMax = a_sensorTechSEAPOINT{16};
a_sensorTechSEAPOINTPoint1Volt = a_sensorTechSEAPOINT{17};
a_sensorTechSEAPOINTPoint1ChloroA = a_sensorTechSEAPOINT{18};
a_sensorTechSEAPOINTPoint2Volt = a_sensorTechSEAPOINT{19};
a_sensorTechSEAPOINTPoint2ChloroA = a_sensorTechSEAPOINT{20};
a_sensorTechSEAPOINTOpenDrainOutputUsed = a_sensorTechSEAPOINT{21};
a_sensorTechSEAPOINTOpenDrainOutputState = a_sensorTechSEAPOINT{22};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechSEAPOINTNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechSEAPOINTNbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   % Nb packets for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      200];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbPackDesc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      201];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbPackDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      202];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbPackAsc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins in zone <Z> for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasDescZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasDescZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasDescZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasDescZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasDescZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      204];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb bins in zone <Z> for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasAscZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasAscZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasAscZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasAscZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTNbMeasAscZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Sensor state
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      206];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSEAPOINTSensorState(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Seapoint'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

end

return
