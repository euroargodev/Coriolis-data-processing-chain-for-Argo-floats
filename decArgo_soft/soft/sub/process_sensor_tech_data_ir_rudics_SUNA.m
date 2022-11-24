% ------------------------------------------------------------------------------
% Process SUNA sensor technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_sensor_tech_data_ir_rudics_SUNA( ...
%    a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechSUNA)
%
% INPUT PARAMETERS :
%   a_cycleNum       : cycle number of the packet
%   a_profNum        : profile number of the packet
%   a_dataIndex      : index of the packet
%   a_sensorTechSUNA : SUNA technical data
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
function process_sensor_tech_data_ir_rudics_SUNA( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechSUNA)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


% unpack the input data
a_sensorTechSUNANbPackDesc = a_sensorTechSUNA{1};
a_sensorTechSUNANbPackDrift = a_sensorTechSUNA{2};
a_sensorTechSUNANbPackAsc = a_sensorTechSUNA{3};
a_sensorTechSUNANbMeasDescZ1 = a_sensorTechSUNA{4};
a_sensorTechSUNANbMeasDescZ2 = a_sensorTechSUNA{5};
a_sensorTechSUNANbMeasDescZ3 = a_sensorTechSUNA{6};
a_sensorTechSUNANbMeasDescZ4 = a_sensorTechSUNA{7};
a_sensorTechSUNANbMeasDescZ5 = a_sensorTechSUNA{8};
a_sensorTechSUNANbMeasDrift = a_sensorTechSUNA{9};
a_sensorTechSUNANbMeasAscZ1 = a_sensorTechSUNA{10};
a_sensorTechSUNANbMeasAscZ2 = a_sensorTechSUNA{11};
a_sensorTechSUNANbMeasAscZ3 = a_sensorTechSUNA{12};
a_sensorTechSUNANbMeasAscZ4 = a_sensorTechSUNA{13};
a_sensorTechSUNANbMeasAscZ5 = a_sensorTechSUNA{14};
a_sensorTechSUNASensorState = a_sensorTechSUNA{15};
a_sensorTechSUNASensorSerialNum = a_sensorTechSUNA{16};
a_sensorTechSUNAAPFSampCounter = a_sensorTechSUNA{17};
a_sensorTechSUNAAPFPowerCycleCounter = a_sensorTechSUNA{18};
a_sensorTechSUNAAPFErrorCounter = a_sensorTechSUNA{19};
a_sensorTechSUNAAPFSupplyVoltage = a_sensorTechSUNA{20};
a_sensorTechSUNAAPFSupplyCurrent = a_sensorTechSUNA{21};
a_sensorTechSUNAAPFOutPixelBegin = a_sensorTechSUNA{22};
a_sensorTechSUNAAPFOutPixelEnd = a_sensorTechSUNA{23};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechSUNANbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechSUNANbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   % Nb packets for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      200];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbPackDesc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      201];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbPackDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      202];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbPackAsc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins in zone <Z> for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasDescZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasDescZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasDescZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasDescZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasDescZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      204];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb bins in zone <Z> for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasAscZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasAscZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasAscZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasAscZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNANbMeasAscZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Sensor state
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      206];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNASensorState(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Suna'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
      
   % APF: sample counter
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum -1 211];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFSampCounter(idP, 3);   
   
   % APF: power cycle counter
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum -1 212];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFPowerCycleCounter(idP, 3);   

   % APF: error counter
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum -1 213];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFErrorCounter(idP, 3);   

   % APF: supply voltage
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum -1 214];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFSupplyVoltage(idP, 3);   
   
   % APF: supply current
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum -1 215];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFSupplyCurrent(idP, 3);   
   
   % APF: output pixel begin (META-CONF)
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   %       250 a_cycleNum a_profNum -1 216];
   %    g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFOutPixelBegin(idP, 3);

   % APF: output pixel end (META-CONF)
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   %       250 a_cycleNum a_profNum -1 217];
   %    g_decArgo_outputNcParamValue{end+1} = a_sensorTechSUNAAPFOutPixelEnd(idP, 3);

end

return;
