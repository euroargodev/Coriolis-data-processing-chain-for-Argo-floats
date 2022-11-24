% ------------------------------------------------------------------------------
% Process OCR sensor technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_sensor_tech_data_ir_rudics_OCR( ...
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
%   02/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function process_sensor_tech_data_ir_rudics_OCR( ...
   a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechOCR)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


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
a_sensorTechOCRCoefLambda1A0 = a_sensorTechOCR{17};
a_sensorTechOCRCoefLambda1A1 = a_sensorTechOCR{18};
a_sensorTechOCRCoefLambda1Lm = a_sensorTechOCR{19};
a_sensorTechOCRCoefLambda2A0 = a_sensorTechOCR{20};
a_sensorTechOCRCoefLambda2A1 = a_sensorTechOCR{21};
a_sensorTechOCRCoefLambda2Lm = a_sensorTechOCR{22};
a_sensorTechOCRCoefLambda3A0 = a_sensorTechOCR{23};
a_sensorTechOCRCoefLambda3A1 = a_sensorTechOCR{24};
a_sensorTechOCRCoefLambda3Lm = a_sensorTechOCR{25};
a_sensorTechOCRCoefParA0 = a_sensorTechOCR{26};
a_sensorTechOCRCoefParA1 = a_sensorTechOCR{27};
a_sensorTechOCRCoefParLm = a_sensorTechOCR{28};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechOCRNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechOCRNbPackDesc(a_dataIndexList, 2) == a_profNum));

% OCR sensor TECH are transmitted twice (to provide calibration coefficients
% with the required resolution)
if (length(idPack) == 2)
   if ((size(unique(a_sensorTechOCRNbPackDesc, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbPackDrift, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbPackAsc, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasDescZ1, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasDescZ2, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasDescZ3, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasDescZ4, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasDescZ5, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasDrift, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasAscZ1, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasAscZ2, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasAscZ3, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasAscZ4, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRNbMeasAscZ5, 'rows'), 1) == 1) && ...
         (size(unique(a_sensorTechOCRSensorState, 'rows'), 1) == 1))
      idPack = idPack(1);
   end
end

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   % Nb packets for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      200];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbPackDesc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      201];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbPackDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      202];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbPackAsc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins in zone <Z> for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasDescZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasDescZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasDescZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasDescZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasDescZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      204];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb bins in zone <Z> for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasAscZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasAscZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasAscZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasAscZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRNbMeasAscZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Sensor state
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      206];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechOCRSensorState(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'Ocr'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
end

return
