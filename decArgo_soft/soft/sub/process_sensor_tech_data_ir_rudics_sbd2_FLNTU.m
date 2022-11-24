% ------------------------------------------------------------------------------
% Process FLNTU sensor technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_sensor_tech_data_ir_rudics_sbd2_FLNTU( ...
%    a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechFLNTU)
%
% INPUT PARAMETERS :
%   a_cycleNum        : cycle number of the packet
%   a_profNum         : profile number of the packet
%   a_dataIndex       : index of the packet
%   a_sensorTechFLNTU : FLNTU technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function process_sensor_tech_data_ir_rudics_sbd2_FLNTU( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechFLNTU)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


% unpack the input data
a_sensorTechFLNTUNbPackDesc = a_sensorTechFLNTU{1};
a_sensorTechFLNTUNbPackDrift = a_sensorTechFLNTU{2};
a_sensorTechFLNTUNbPackAsc = a_sensorTechFLNTU{3};
a_sensorTechFLNTUNbMeasDescZ1 = a_sensorTechFLNTU{4};
a_sensorTechFLNTUNbMeasDescZ2 = a_sensorTechFLNTU{5};
a_sensorTechFLNTUNbMeasDescZ3 = a_sensorTechFLNTU{6};
a_sensorTechFLNTUNbMeasDescZ4 = a_sensorTechFLNTU{7};
a_sensorTechFLNTUNbMeasDescZ5 = a_sensorTechFLNTU{8};
a_sensorTechFLNTUNbMeasDrift = a_sensorTechFLNTU{9};
a_sensorTechFLNTUNbMeasAscZ1 = a_sensorTechFLNTU{10};
a_sensorTechFLNTUNbMeasAscZ2 = a_sensorTechFLNTU{11};
a_sensorTechFLNTUNbMeasAscZ3 = a_sensorTechFLNTU{12};
a_sensorTechFLNTUNbMeasAscZ4 = a_sensorTechFLNTU{13};
a_sensorTechFLNTUNbMeasAscZ5 = a_sensorTechFLNTU{14};
a_sensorTechFLNTUSensorState = a_sensorTechFLNTU{15};
a_sensorTechFLNTUCoefScaleChloro = a_sensorTechFLNTU{16};
a_sensorTechFLNTUDarkCountChloro = a_sensorTechFLNTU{17};
a_sensorTechFLNTUCoefScaleTurbi = a_sensorTechFLNTU{18};
a_sensorTechFLNTUDarkCountTurbi = a_sensorTechFLNTU{19};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechFLNTUNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechFLNTUNbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   % Nb packets for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      200];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbPackDesc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      201];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbPackDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      202];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbPackAsc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins in zone <Z> for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasDescZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasDescZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasDescZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasDescZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasDescZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      204];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb bins in zone <Z> for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasAscZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasAscZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasAscZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasAscZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUNbMeasAscZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Sensor state
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      206];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechFLNTUSensorState(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Flntu'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

end

return
