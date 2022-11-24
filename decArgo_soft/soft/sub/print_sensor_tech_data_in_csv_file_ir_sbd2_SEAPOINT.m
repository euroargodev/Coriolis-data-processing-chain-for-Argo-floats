% ------------------------------------------------------------------------------
% Print SEAPOINT sensor technical data in output CSV file.
%
% SYNTAX :
%  print_sensor_tech_data_in_csv_file_ir_sbd2_SEAPOINT( ...
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
function print_sensor_tech_data_in_csv_file_ir_sbd2_SEAPOINT( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechSEAPOINT)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

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
a_sensorTechSEAPOINTAvgSampMax = a_sensorTechSEAPOINT{16};
a_sensorTechSEAPOINTCalib1Volts = a_sensorTechSEAPOINT{17};
a_sensorTechSEAPOINTCalib1PhysicalValue = a_sensorTechSEAPOINT{18};
a_sensorTechSEAPOINTCalib2Volts = a_sensorTechSEAPOINT{19};
a_sensorTechSEAPOINTCalib2PhysicalValue = a_sensorTechSEAPOINT{20};
a_sensorTechSEAPOINTOpenDrainOutputUsedForSensorGain = a_sensorTechSEAPOINT{21};
a_sensorTechSEAPOINTOpenDrainOutputState = a_sensorTechSEAPOINT{22};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechSEAPOINTNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechSEAPOINTNbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb packets for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbPackDesc(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb packets for drift; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbPackDrift(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb packets for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbPackAsc(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 1 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasDescZ1(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 2 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasDescZ2(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 3 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasDescZ3(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 4 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasDescZ4(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 5 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasDescZ5(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins for drift; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasDrift(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 1 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasAscZ1(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 2 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasAscZ2(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 3 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasAscZ3(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 4 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasAscZ4(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Nb bins in zone 5 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTNbMeasAscZ5(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Sensor state indicator (1:Ok, 0:Ko); %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTSensorState(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Average sample max; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTAvgSampMax(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Calib point #1: ADC value; %g\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTCalib1Volts(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Calib point #1: physical value; %g\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTCalib1PhysicalValue(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Calib point #2: ADC value; %g\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTCalib2Volts(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Calib point #2: physical value; %g\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTCalib2PhysicalValue(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Open drain output used for sensor gain; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTOpenDrainOutputUsedForSensorGain(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; SEAPOINT tech; Open drain output state; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechSEAPOINTOpenDrainOutputState(idP, 3));
end

return;