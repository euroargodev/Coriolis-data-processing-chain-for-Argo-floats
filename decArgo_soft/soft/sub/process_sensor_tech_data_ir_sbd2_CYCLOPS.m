% ------------------------------------------------------------------------------
% Process FLNTU sensor technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_sensor_tech_data_ir_sbd2_CYCLOPS( ...
%    a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechCYCLOPS)
%
% INPUT PARAMETERS :
%   a_cycleNum          : cycle number of the packet
%   a_profNum           : profile number of the packet
%   a_dataIndex         : index of the packet
%   a_sensorTechCYCLOPS : CYCLOPS technical data
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
function process_sensor_tech_data_ir_sbd2_CYCLOPS( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechCYCLOPS)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


% unpack the input data
a_sensorTechCYCLOPSNbPackDesc = a_sensorTechCYCLOPS{1};
a_sensorTechCYCLOPSNbPackDrift = a_sensorTechCYCLOPS{2};
a_sensorTechCYCLOPSNbPackAsc = a_sensorTechCYCLOPS{3};
a_sensorTechCYCLOPSNbMeasDescZ1 = a_sensorTechCYCLOPS{4};
a_sensorTechCYCLOPSNbMeasDescZ2 = a_sensorTechCYCLOPS{5};
a_sensorTechCYCLOPSNbMeasDescZ3 = a_sensorTechCYCLOPS{6};
a_sensorTechCYCLOPSNbMeasDescZ4 = a_sensorTechCYCLOPS{7};
a_sensorTechCYCLOPSNbMeasDescZ5 = a_sensorTechCYCLOPS{8};
a_sensorTechCYCLOPSNbMeasDrift = a_sensorTechCYCLOPS{9};
a_sensorTechCYCLOPSNbMeasAscZ1 = a_sensorTechCYCLOPS{10};
a_sensorTechCYCLOPSNbMeasAscZ2 = a_sensorTechCYCLOPS{11};
a_sensorTechCYCLOPSNbMeasAscZ3 = a_sensorTechCYCLOPS{12};
a_sensorTechCYCLOPSNbMeasAscZ4 = a_sensorTechCYCLOPS{13};
a_sensorTechCYCLOPSNbMeasAscZ5 = a_sensorTechCYCLOPS{14};
a_sensorTechCYCLOPSSensorState = a_sensorTechCYCLOPS{15};
a_sensorTechCYCLOPSAverageSampleMax = a_sensorTechCYCLOPS{16};
a_sensorTechCYCLOPSPoint1Volt = a_sensorTechCYCLOPS{17};
a_sensorTechCYCLOPSPoint1ChloroA = a_sensorTechCYCLOPS{18};
a_sensorTechCYCLOPSPoint2Volt = a_sensorTechCYCLOPS{19};
a_sensorTechCYCLOPSPoint2ChloroA = a_sensorTechCYCLOPS{20};
a_sensorTechCYCLOPSOpenDrainOutputUsed = a_sensorTechCYCLOPS{21};
a_sensorTechCYCLOPSOpenDrainOutputState = a_sensorTechCYCLOPS{22};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechCYCLOPSNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechCYCLOPSNbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   % Nb packets for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1200];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbPackDesc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1201];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbPackDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1202];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbPackAsc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins in zone <Z> for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasDescZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasDescZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasDescZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasDescZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasDescZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1204];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb bins in zone <Z> for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasAscZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasAscZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasAscZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasAscZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSNbMeasAscZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Sensor state
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      1206];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCYCLOPSSensorState(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Cyclops'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

end

return
