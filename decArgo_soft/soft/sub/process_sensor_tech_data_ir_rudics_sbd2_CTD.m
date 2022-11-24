% ------------------------------------------------------------------------------
% Process CTD sensor technical data for TECH NetCDF file.
% 
% SYNTAX :
%  process_sensor_tech_data_ir_rudics_sbd2_CTD( ...
%    a_decoderId, a_cycleNum, a_profNum, a_dataIndexList, ...
%    a_sensorTechCTD)
% 
% INPUT PARAMETERS :
%   a_decoderId     : float decoder Id
%   a_cycleNum      : cycle number of the packet
%   a_profNum       : profile number of the packet
%   a_dataIndex     : index of the packet
%   a_sensorTechCTD : CTD technical data
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
function process_sensor_tech_data_ir_rudics_sbd2_CTD( ...
   a_decoderId, a_cycleNum, a_profNum, a_dataIndexList, ...
   a_sensorTechCTD)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;


% unpack the input data
a_sensorTechCTDNbPackDesc = a_sensorTechCTD{1};
a_sensorTechCTDNbPackDrift = a_sensorTechCTD{2};
a_sensorTechCTDNbPackAsc = a_sensorTechCTD{3};
a_sensorTechCTDNbMeasDescZ1 = a_sensorTechCTD{4};
a_sensorTechCTDNbMeasDescZ2 = a_sensorTechCTD{5};
a_sensorTechCTDNbMeasDescZ3 = a_sensorTechCTD{6};
a_sensorTechCTDNbMeasDescZ4 = a_sensorTechCTD{7};
a_sensorTechCTDNbMeasDescZ5 = a_sensorTechCTD{8};
a_sensorTechCTDNbMeasDrift = a_sensorTechCTD{9};
a_sensorTechCTDNbMeasAscZ1 = a_sensorTechCTD{10};
a_sensorTechCTDNbMeasAscZ2 = a_sensorTechCTD{11};
a_sensorTechCTDNbMeasAscZ3 = a_sensorTechCTD{12};
a_sensorTechCTDNbMeasAscZ4 = a_sensorTechCTD{13};
a_sensorTechCTDNbMeasAscZ5 = a_sensorTechCTD{14};
a_sensorTechCTDSensorState = a_sensorTechCTD{15};
a_sensorTechCTDOffsetPres = a_sensorTechCTD{16};
a_sensorTechCTDSubPres = a_sensorTechCTD{17};
a_sensorTechCTDSubTemp = a_sensorTechCTD{18};
a_sensorTechCTDSubSal = a_sensorTechCTD{19};

% select the data (according to a_cycleNum and a_profNum)
idPack = find((a_sensorTechCTDNbPackDesc(a_dataIndexList, 1) == a_cycleNum) & ...
   (a_sensorTechCTDNbPackDesc(a_dataIndexList, 2) == a_profNum));

for id = 1:length(idPack)
   idP = a_dataIndexList(idPack(id));

   % Nb packets for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      200];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbPackDesc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      201];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbPackDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb packets for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      202];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbPackAsc(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins in zone <Z> for descent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasDescZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasDescZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasDescZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasDescZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      203];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasDescZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;

   % Nb bins for drift
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      204];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasDrift(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Nb bins in zone <Z> for ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasAscZ1(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'1'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasAscZ2(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'2'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasAscZ3(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'3'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasAscZ4(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'4'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      205];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDNbMeasAscZ5(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'} {'<Z>'} {'5'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Sensor state
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      250 a_cycleNum a_profNum ...
      g_decArgo_outputNcParamLabelInfoCounter*-1 ...
      206];
   g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDSensorState(idP, 3);
   g_decArgo_outputNcParamLabelInfo{g_decArgo_outputNcParamLabelInfoCounter} = [{'<Sensor>'} {'CTD'}];
   g_decArgo_outputNcParamLabelInfoCounter = g_decArgo_outputNcParamLabelInfoCounter + 1;
   
   % Pressure offset
   if ((a_decoderId ~= 302) && (a_decoderId ~= 303))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
         250 a_cycleNum a_profNum -1 207];
      g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDOffsetPres(idP, 3);
   else
      % for Arvor CM float, the pressure offset technical label depends on
      % CONFIG_PC_0_1_14 configuration parameter of the current cycle
      [configPC0114] = config_get_value_ir_rudics_sbd2(a_cycleNum, a_profNum, 'CONFIG_PC_0_1_14');
      if (~isempty(configPC0114) && ~isnan(configPC0114) && (configPC0114 == 1))
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
            250 a_cycleNum a_profNum -1 209];
         g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDOffsetPres(idP, 3);
      else
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
            250 a_cycleNum a_profNum -1 207];
         g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDOffsetPres(idP, 3);
      end
   end

   % "Subsurface" P
   if (any([a_sensorTechCTDSubPres(idP, 3) ...
         a_sensorTechCTDSubTemp(idP, 3) ...
         a_sensorTechCTDSubSal(idP, 3)] ~= 0))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
         250 a_cycleNum a_profNum -1 208];
      g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDSubPres(idP, 3);
      
      % the two following items have moved to TRAJ file
      %    % "Subsurface" T
      %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      %       250 a_cycleNum a_profNum -1 209];
      %    g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDSubTemp(idP, 3);
      %
      %    % "Subsurface" S
      %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      %       250 a_cycleNum a_profNum -1 210];
      %    g_decArgo_outputNcParamValue{end+1} = a_sensorTechCTDSubSal(idP, 3);
   end
end

return
