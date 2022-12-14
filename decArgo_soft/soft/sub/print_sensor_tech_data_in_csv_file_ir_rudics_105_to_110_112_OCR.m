% ------------------------------------------------------------------------------
% Print OCR sensor technical data in output CSV file.
%
% SYNTAX :
%  print_sensor_tech_data_in_csv_file_ir_rudics_105_to_110_112_OCR( ...
%    a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechOCR)
%
% INPUT PARAMETERS :
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_dataIndex     : index of the packet
%   a_sensorTechOCR : OCR technical data
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
function print_sensor_tech_data_in_csv_file_ir_rudics_105_to_110_112_OCR( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechOCR)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% unpack the input data
a_sensorTechOCRNbPackDesc = a_sensorTechOCR{1};
a_sensorTechOCRNbPackDrift = a_sensorTechOCR{2};
a_sensorTechOCRNbPackAsc = a_sensorTechOCR{3};
a_sensorTechOCRNbMeasDescZ1 = a_sensorTechOCR{4};
a_sensorTechOCRNbMeasDescZ2 = a_sensorTechOCR{5};
a_sensorTechOCRNbMeasDescZ3 = a_sensorTechOCR{6};
a_sensorTechOCRNbMeasDescZ4 = a_sensorTechOCR{7};
a_sensorTechOCRNbMeasDescZ5 = a_sensorTechOCR{8};
a_sensorTechOCRNbMeasDrift = a_sensorTechOCR{9};
a_sensorTechOCRNbMeasAscZ1 = a_sensorTechOCR{10};
a_sensorTechOCRNbMeasAscZ2 = a_sensorTechOCR{11};
a_sensorTechOCRNbMeasAscZ3 = a_sensorTechOCR{12};
a_sensorTechOCRNbMeasAscZ4 = a_sensorTechOCR{13};
a_sensorTechOCRNbMeasAscZ5 = a_sensorTechOCR{14};
a_sensorTechOCRSensorState = a_sensorTechOCR{15};
a_sensorTechOCRSensorSerialNum = a_sensorTechOCR{16};
a_sensorTechOCRCoefLambda380A0 = a_sensorTechOCR{17};
a_sensorTechOCRCoefLambda380A1 = a_sensorTechOCR{18};
a_sensorTechOCRCoefLambda380Lm = a_sensorTechOCR{19};
a_sensorTechOCRCoefLambda412A0 = a_sensorTechOCR{20};
a_sensorTechOCRCoefLambda412A1 = a_sensorTechOCR{21};
a_sensorTechOCRCoefLambda412Lm = a_sensorTechOCR{22};
a_sensorTechOCRCoefLambda490A0 = a_sensorTechOCR{23};
a_sensorTechOCRCoefLambda490A1 = a_sensorTechOCR{24};
a_sensorTechOCRCoefLambda490Lm = a_sensorTechOCR{25};
a_sensorTechOCRCoefParA0 = a_sensorTechOCR{26};
a_sensorTechOCRCoefParA1 = a_sensorTechOCR{27};
a_sensorTechOCRCoefParLm = a_sensorTechOCR{28};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechOCRNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechOCRNbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb packets for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbPackDesc(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb packets for drift; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbPackDrift(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb packets for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbPackAsc(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 1 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasDescZ1(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 2 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasDescZ2(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 3 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasDescZ3(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 4 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasDescZ4(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 5 for descent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasDescZ5(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins for drift; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasDrift(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 1 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasAscZ1(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 2 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasAscZ2(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 3 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasAscZ3(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 4 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasAscZ4(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Nb bins in zone 5 for ascent; %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRNbMeasAscZ5(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Sensor state indicator (1:Ok, 0:Ko); %d\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRSensorState(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; Sensor serial num; %g\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      a_sensorTechOCRSensorSerialNum(idP, 3));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A0Lambda380; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda380A0(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A1Lambda380; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda380A1(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; LmLambda380; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda380Lm(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A0Lambda412; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda412A0(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A1Lambda412; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda412A1(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; LmLambda412; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda412Lm(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A0Lambda490; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda490A0(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A1Lambda490; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda490A1(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; LmLambda490; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefLambda490Lm(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A0PAR; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefParA0(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; A1PAR; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefParA1(idP, 3)));
   fprintf(g_decArgo_outputCsvFileId, '%d; %d; %d; %s; OCR tech; LmPAR; %s\n', ...
      g_decArgo_floatNum, a_cycleNum, a_profNum, get_phase_name(-1), ...
      num_2_str(a_sensorTechOCRCoefParLm(idP, 3)));
end

return
