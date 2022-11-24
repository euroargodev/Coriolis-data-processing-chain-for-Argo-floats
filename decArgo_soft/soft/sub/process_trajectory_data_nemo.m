% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_nemo( ...
%    a_cycleNum, ...
%    a_cycleTimeData, a_techData, ...
%    a_parkData, a_rafosData, a_profileData, ...
%    a_clockOffsetCounterData, a_clockOffsetRtcData, a_presOffsetData, ...
%    a_gpsData, a_iridiumData, ...
%    a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_cycleNum               : current cycle number
%   a_cycleTimeData          : cycle time data structure
%   a_techData               : technical data
%   a_parkData               : park data
%   a_rafosData              : RAFOS data
%   a_profileData            : profile data
%   a_clockOffsetCounterData : clock offset for counter based times
%   a_clockOffsetRtcData     : clock offset for RTC based times
%   a_presOffsetData         : pressure offset data structure
%   a_gpsData                : GPS fix information
%   a_iridiumData            : Iridium fix information
%   a_tabTrajNMeas           : input traj N_MEAS data
%   a_tabTrajNCycle          : input traj N_CYCLE data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output traj N_MEAS data
%   o_tabTrajNCycle : output traj N_CYCLE data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_nemo( ...
   a_cycleNum, ...
   a_cycleTimeData, a_techData, ...
   a_parkData, a_rafosData, a_profileData, ...
   a_clockOffsetCounterData, a_clockOffsetRtcData, a_presOffsetData, ...
   a_gpsData, a_iridiumData, ...
   a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% global measurement codes
global g_MC_DST;
global g_MC_PST;
global g_MC_DriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_MaxPresInDescToProf;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_MedianValueInAscProf;
global g_MC_AET;
global g_MC_TST;
global g_MC_Surface;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;

% RPP status
global g_RPP_STATUS_1;

% default values
global g_decArgo_dateDef;


% if (a_cycleNum == 24)
%    a=1
% end

paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);
trajNCycleStruct.grounded = 'U'; % grounding status is unknown

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLOCK OFFSET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clock offset
if (~isempty(a_clockOffsetRtcData))
   trajNCycleStruct.clockOffset = a_clockOffsetRtcData/86400;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRES OFFSET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve PRES offset for this cycle
presOffset = [];
idF = find(a_presOffsetData.cycleNumAdjPres == a_cycleNum, 1);
if (~isempty(idF))
   presOffset = a_presOffsetData.presOffset(idF);
end

% data mode
if (~isempty(a_clockOffsetRtcData) || ~isempty(presOffset))
   trajNCycleStruct.dataMode = 'A';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MISC TECH DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve misc TECH information to be stored in the TRAJ file
techParkingPressureMedian = [];
techParkingPressureMedianAdj = [];
techDepthPressureMax = [];
techDepthPressureMaxAdj = [];
techDepthPressure = [];
techDepthPressureAdj = [];
techIceDetectionTempMedian = [];
if (~isempty(a_techData))
   
   techData = [a_techData{:}];
   idF = find(strcmp({techData.label}, 'xmit_parking_pressure_median'));
   if (~isempty(idF))
      techParkingPressureMedian = str2double(techData(idF).value);
      if (~isempty(presOffset))
         techParkingPressureMedianAdj = techParkingPressureMedian - presOffset;
      end
   end
   idF = find(strcmp({techData.label}, 'xmit_depth_pressure_max'));
   if (~isempty(idF))
      techDepthPressureMax = str2double(techData(idF).value);
      if (~isempty(presOffset))
         techDepthPressureMaxAdj = techDepthPressureMax - presOffset;
      end
   end
   idF = find(strcmp({techData.label}, 'xmit_depth_pressure'));
   if (~isempty(idF))
      techDepthPressure = str2double(techData(idF).value);
      if (~isempty(presOffset))
         techDepthPressureAdj = techDepthPressure - presOffset;
      end
   end
   idF = find(strcmp({techData.label}, 'xmit_ice_detection_temp_median'));
   if (~isempty(idF))
      techIceDetectionTempMedian = str2double(techData(idF).value);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT CYCLE TIMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_cycleTimeData))
   
   % Descent Start Time
   if (~isempty(a_cycleTimeData.descentStartDate))
      time = a_cycleTimeData.descentStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.descentStartAdjDate))
         timeAdj = a_cycleTimeData.descentStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_DST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldDescentStart = nCycleTime;
         trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Park Start Time
   if (~isempty(a_cycleTimeData.parkStartDate))
      time = a_cycleTimeData.parkStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.parkStartAdjDate))
         timeAdj = a_cycleTimeData.parkStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_PST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldParkStart = nCycleTime;
         trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Park End Time
   if (~isempty(a_cycleTimeData.upcastStartDate))
      time = a_cycleTimeData.upcastStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.upcastStartAdjDate))
         timeAdj = a_cycleTimeData.upcastStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_PET, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         if (~isempty(techParkingPressureMedian))
            measStruct.paramList = paramPres;
            measStruct.paramData = techParkingPressureMedian;
            if (~isempty(techParkingPressureMedianAdj))
               measStruct.paramDataAdj = techParkingPressureMedianAdj;
               measStruct.paramDataMode = 'A';
            end
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldParkEnd = nCycleTime;
         trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
      end
   end   
   
   % Ascent Start Time
   if (~isempty(a_cycleTimeData.ascentStartDate))
      time = a_cycleTimeData.ascentStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.ascentStartAdjDate))
         timeAdj = a_cycleTimeData.ascentStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_AST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         if (~isempty(techDepthPressure))
            measStruct.paramList = paramPres;
            measStruct.paramData = techDepthPressure;
            if (~isempty(techDepthPressureAdj))
               measStruct.paramDataAdj = techDepthPressureAdj;
               measStruct.paramDataMode = 'A';
            end
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentStart = nCycleTime;
         trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Ascent End Time
   if (~isempty(a_cycleTimeData.ascentEndDate))
      time = a_cycleTimeData.ascentEndDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.ascentEndAdjDate))
         timeAdj = a_cycleTimeData.ascentEndAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_AET, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentEnd = nCycleTime;
         trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
      end
   end
   
   % Transmission Start Time
   if (~isempty(a_cycleTimeData.surfaceStartDate))
      time = a_cycleTimeData.surfaceStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.surfaceStartAdjDate))
         timeAdj = a_cycleTimeData.surfaceStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_TST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentEnd = nCycleTime;
         trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MISC TECH DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% max PRES during mission
if (~isempty(techDepthPressureMax))
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_MaxPresInDescToProf;
   measStruct.paramList = paramPres;
   measStruct.paramData = techDepthPressureMax;
   if (~isempty(techDepthPressureMaxAdj))
      measStruct.paramDataAdj = techDepthPressureMaxAdj;
      measStruct.paramDataMode = 'A';
   end
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

% median of the mixed-layer temperature
if (~isempty(techIceDetectionTempMedian))
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_MedianValueInAscProf;
   measStruct.paramList = paramTemp;
   measStruct.paramData = techIceDetectionTempMedian;
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEASUREMENTS SAMPLED DURING THE DRIFT AT PARKING DEPTH
% AND
% REPRESENTATIVE PARKING MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

measStructRpp = [];

% parking measurements
if (~isempty(a_parkData) && ~isempty(a_parkData.data))
   for idMeas = 1:size(a_parkData.data, 1)
      if (isempty(a_parkData.dates))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_DriftAtPark;
      else
         time = a_parkData.dates(idMeas);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_parkData.datesAdj))
            timeAdj = a_parkData.datesAdj(idMeas);
         end
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            g_MC_DriftAtPark, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_3);
      end
      if (~isempty(measStruct))
         measStruct.paramList = a_parkData.paramList;
         measStruct.paramDataMode = a_parkData.paramDataMode;
         measStruct.paramData = a_parkData.data(idMeas, :);
         if (~isempty(a_parkData.dataAdj))
            measStruct.paramDataAdj = a_parkData.dataAdj(idMeas, :);
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
   
   % RPP measurements
   measStructRpp = get_traj_one_meas_init_struct();
   measStructRpp.measCode = g_MC_RPP;
   for idParam = 1:length(a_parkData.paramList)
      paramData = a_parkData.data(:, idParam);
      paramData(find(paramData == a_parkData.paramList(idParam).fillValue)) = [];
      paramDataAdj = [];
      if (~isempty(a_parkData.dataAdj))
         paramDataAdj = a_parkData.dataAdj(:, idParam);
         paramDataAdj(find(paramDataAdj == a_parkData.paramList(idParam).fillValue)) = [];
      end
      if (~isempty(paramData))
         measStructRpp.paramList = [measStructRpp.paramList a_parkData.paramList(idParam)];
         if (~isempty(a_parkData.paramDataMode))
            measStructRpp.paramDataMode = [measStructRpp.paramDataMode a_parkData.paramDataMode(idParam)];
         end
         measStructRpp.paramData = [measStructRpp.paramData {paramData}];
         if (~isempty(a_parkData.dataAdj))
            measStructRpp.paramDataAdj = [measStructRpp.paramDataAdj {paramDataAdj}];
            if (~isempty(paramDataAdj))
               if (~isempty(measStructRpp.paramDataMode))
                  measStructRpp.paramDataMode(end) = 'A';
               end
            end
         end
      end
   end
end

% RAFOS measurements
if (~isempty(a_rafosData) && ~isempty(a_rafosData.data))
   for idMeas = 1:length(a_rafosData.dates)
      if (a_rafosData.dates(idMeas) ~= a_rafosData.dateList.fillValue)
         time = a_rafosData.dates(idMeas);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_rafosData.datesAdj))
            timeAdj = a_rafosData.datesAdj(idMeas);
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
            g_MC_DriftAtPark, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStruct))
            measCoreStruct = measStruct;
            idPres = find(strcmp({a_rafosData.paramList.name}, 'PRES') == 1, 1);
            idTemp = find(strcmp({a_rafosData.paramList.name}, 'TEMP') == 1, 1);
            idPsal = find(strcmp({a_rafosData.paramList.name}, 'PSAL') == 1, 1);
            measCoreStruct.paramList = a_rafosData.paramList([idPres idTemp idPsal]);
            measCoreStruct.paramData = a_rafosData.data(idMeas, [idPres idTemp idPsal]);
            if (~isempty(a_rafosData.dataAdj))
               measCoreStruct.paramDataAdj = a_rafosData.dataAdj(idMeas, [idPres idTemp idPsal]);
            end
            if (~isempty(a_rafosData.paramDataMode))
               measCoreStruct.paramDataMode = a_rafosData.paramDataMode([idPres idTemp idPsal]);
               idF = find(measCoreStruct.paramDataMode == 'A');
               for idP = idF
                  if (measCoreStruct.paramDataAdj(1, idP) == measCoreStruct.paramList(idP).fillValue)
                     measCoreStruct.paramDataMode(idP) = ' ';
                  end
               end
               if (all(measCoreStruct.paramDataMode == ' '))
                  measCoreStruct.paramDataMode = [];
                  measCoreStruct.paramDataAdj = [];
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measCoreStruct];
            
            measAuxStruct = measStruct;
            measAuxStruct.sensorNumber = 101; % for TRAJ_AUX
            idStatus = find(strcmp({a_rafosData.paramList.name}, 'RAFOS_STATUS') == 1, 1);
            idCor = find(strcmp({a_rafosData.paramList.name}, 'COR') == 1, 1);
            idToa = find(strcmp({a_rafosData.paramList.name}, 'TOA') == 1, 1);
            measAuxStruct.paramList = a_rafosData.paramList([idPres idStatus idCor idToa]);
            measAuxStruct.paramNumberWithSubLevels = [3 4];
            measAuxStruct.paramNumberOfSubLevels = [6 6];
            measAuxStruct.paramData = a_rafosData.data(idMeas, [idPres idStatus idCor:idCor+5 idToa+5:idToa+5+5]);
            if (~isempty(a_rafosData.dataAdj))
               measAuxStruct.paramDataAdj = a_rafosData.dataAdj(idMeas, [idPres idStatus idCor:idCor+5 idToa+5:idToa+5+5]);
            end
            if (~isempty(a_rafosData.paramDataMode))
               measAuxStruct.paramDataMode = a_rafosData.paramDataMode([idPres idStatus idCor idToa]);
               idF = find(measAuxStruct.paramDataMode == 'A');
               for idP = idF
                  if (measAuxStruct.paramDataAdj(1, idP) == measAuxStruct.paramList(idP).fillValue)
                     measAuxStruct.paramDataMode(idP) = ' ';
                  end
               end
               if (all(measAuxStruct.paramDataMode == ' '))
                  measAuxStruct.paramDataMode = [];
                  measAuxStruct.paramDataAdj = [];
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measAuxStruct];
         end
      end
   end
   
   % RPP measurements
   if (isempty(measStructRpp))
      measStructRpp = get_traj_one_meas_init_struct();
      measStructRpp.measCode = g_MC_RPP;
   end
   
   rafosCParamList = [{'PRES'} {'TEMP'} {'PSAL'}];
   for idParam = 1:length(rafosCParamList)
      paramName = rafosCParamList{idParam};
      idParamInRafos = find(strcmp({a_rafosData.paramList.name}, paramName) == 1, 1);
      if (~isempty(idParamInRafos))
         paramData = a_rafosData.data(:, idParamInRafos);
         paramData(find(paramData == a_rafosData.paramList(idParamInRafos).fillValue)) = [];
         paramDataAdj = [];
         if (~isempty(a_rafosData.dataAdj))
            paramDataAdj = a_rafosData.dataAdj(:, idParamInRafos);
            paramDataAdj(find(paramDataAdj == a_rafosData.paramList(idParamInRafos).fillValue)) = [];
         end
         if (~isempty(paramData))
            idParamInRpp = [];
            if (~isempty(measStructRpp.paramList))
               idParamInRpp = find(strcmp({measStructRpp.paramList.name}, paramName) == 1, 1);
            end
            if (isempty(idParamInRpp))
               newParam = get_netcdf_param_attributes(paramName);
               measStructRpp.paramList = [measStructRpp.paramList newParam];
               if (~isempty(measStructRpp.paramDataMode))
                  measStructRpp.paramDataMode = [measStructRpp.paramDataMode ' '];
               elseif (~isempty(a_rafosData.paramDataMode))
                  measStructRpp.paramDataMode = repmat(' ', 1, length(measStructRpp.paramList));
               end
               measStructRpp.paramData = [measStructRpp.paramData {paramData}];
               if (~isempty(measStructRpp.paramDataAdj))
                  measStructRpp.paramDataAdj = [measStructRpp.paramDataAdj {paramDataAdj}];
                  if (~isempty(paramDataAdj))
                     if (~isempty(measStructRpp.paramDataMode))
                        measStructRpp.paramDataMode(end) = 'A';
                     end
                  end
               end
            else
               paramDataAll = measStructRpp.paramData{idParamInRpp};
               paramDataAll = [paramDataAll; paramData];
               measStructRpp.paramData{idParamInRpp} = paramDataAll;
               if (~isempty(paramDataAdj))
                  paramDataAdjAll = measStructRpp.paramDataAdj{idParamInRpp};
                  paramDataAdjAll = [paramDataAdjAll; paramDataAdj];
                  measStructRpp.paramDataAdj{idParamInRpp} = paramDataAdjAll;
                  if (~isempty(measStructRpp.paramDataMode))
                     measStructRpp.paramDataMode(idParamInRpp) = 'A';
                  end
               end
            end
         end
      end
   end
end

% RPP
if (~isempty(measStructRpp))
   for idParam = 1:length(measStructRpp.paramList)
      measStructRpp.paramData{idParam} = mean(measStructRpp.paramData{idParam});
      if (~isempty(measStructRpp.paramDataAdj))
         if (~isempty(measStructRpp.paramDataAdj{idParam}))
            measStructRpp.paramDataAdj{idParam} = double(mean(measStructRpp.paramDataAdj{idParam}));
         else
            measStructRpp.paramDataAdj{idParam} = double(measStructRpp.paramList(idParam).fillValue);
         end
      end
   end
   measStructRpp.paramData = cell2mat(measStructRpp.paramData);
   measStructRpp.paramDataAdj = cell2mat(measStructRpp.paramDataAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructRpp];
   
   idPres = find(strcmp({measStructRpp.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      if (~isempty(measStructRpp.paramDataAdj))
         trajNCycleStruct.repParkPres = measStructRpp.paramDataAdj(idPres);
      else
         trajNCycleStruct.repParkPres = measStructRpp.paramData(idPres);
      end
   end
   trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROFILE DATED BINS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_profileData))
   for idLev = 1:length(a_profileData.dates)
      if (a_profileData.dates(idLev) ~= a_profileData.dateList.fillValue)
         time = a_profileData.dates(idLev);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_profileData.datesAdj))
            timeAdj = a_profileData.datesAdj(idLev);
         end
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            g_MC_AscProf, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStruct))
            measStruct.paramList = a_profileData.paramList;
            measStruct.paramDataMode = a_profileData.paramDataMode;
            measStruct.paramData = a_profileData.data(idLev, :);
            if (~isempty(a_profileData.dataAdj))
               measStruct.paramDataAdj = a_profileData.dataAdj(idLev, :);
            end
            
            idF1 = find(strcmp({measStruct.paramList.name}, 'LIGHT442') == 1, 1);
            idF2 = find(strcmp({measStruct.paramList.name}, 'LIGHT550') == 1, 1);
            idF3 = find(strcmp({measStruct.paramList.name}, 'LIGHT676') == 1, 1);
            idDel = [idF1 idF2 idF3];
            if (~isempty(idDel))
               measAuxStruct = measStruct;
               
               measStruct.paramList(idDel) = [];
               if (~isempty(measStruct.paramDataMode))
                  measStruct.paramDataMode(idDel) = [];
               end
               measStruct.paramData(:, idDel) = [];
               if (~isempty(a_profileData.dataAdj))
                  measStruct.paramDataAdj(:, idDel) = [];
               end
               
               measAuxStruct.sensorNumber = 101; % for TRAJ_AUX
               idPres = find(strcmp({measAuxStruct.paramList.name}, 'PRES') == 1, 1);
               idKeep = [idPres idDel];
               measAuxStruct.paramList = measAuxStruct.paramList(idKeep);
               if (~isempty(measAuxStruct.paramDataMode))
                  measAuxStruct.paramDataMode = measAuxStruct.paramDataMode(idKeep);
               end
               measAuxStruct.paramData = measAuxStruct.paramData(:, idKeep);
               if (~isempty(a_profileData.dataAdj))
                  measAuxStruct.paramDataAdj = measAuxStruct.paramDataAdj(:, idKeep);
               end
               
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measAuxStruct];
            end            

            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASCENDING PROFILE DEEPEST BIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_profileData))
   idPres = find(strcmp({a_profileData.paramList.name}, 'PRES') == 1, 1);
   if (~isempty(idPres))
      presData = a_profileData.data(:, idPres);
      idNoDef = find(presData ~= a_profileData.paramList(idPres).fillValue);
      presData = presData(idNoDef);
      if (~isempty(presData))
         [~, idMax] = max(presData);
         if (~isempty(a_profileData.dates))
            time = a_profileData.dates(idNoDef(idMax));
            timeAdj = g_decArgo_dateDef;
            if (~isempty(a_profileData.datesAdj))
               timeAdj = a_profileData.datesAdj(idNoDef(idMax));
            end
            [measStruct, ~] = create_one_meas_float_time_bis( ...
               g_MC_AscProfDeepestBin, ...
               time, ...
               timeAdj, ...
               g_JULD_STATUS_2);
            if (isempty(measStruct))
               % not dated information
               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = g_MC_AscProfDeepestBin;
            end
            measStruct.paramList = a_profileData.paramList;
            measStruct.paramDataMode = a_profileData.paramDataMode;
            measStruct.paramData = a_profileData.data(idNoDef(idMax), :);
            if (~isempty(a_profileData.dataAdj))
               measStruct.paramDataAdj = a_profileData.dataAdj(idNoDef(idMax), :);
            end
            
            idF1 = find(strcmp({measStruct.paramList.name}, 'LIGHT442') == 1, 1);
            idF2 = find(strcmp({measStruct.paramList.name}, 'LIGHT550') == 1, 1);
            idF3 = find(strcmp({measStruct.paramList.name}, 'LIGHT676') == 1, 1);
            idDel = [idF1 idF2 idF3];
            if (~isempty(idDel))
               measAuxStruct = measStruct;
               
               measStruct.paramList(idDel) = [];
               if (~isempty(measStruct.paramDataMode))
                  measStruct.paramDataMode(idDel) = [];
               end
               measStruct.paramData(:, idDel) = [];
               if (~isempty(a_profileData.dataAdj))
                  measStruct.paramDataAdj(:, idDel) = [];
               end
               
               measAuxStruct.sensorNumber = 101;
               idPres = find(strcmp({measAuxStruct.paramList.name}, 'PRES') == 1, 1);
               idKeep = [idPres idDel];
               measAuxStruct.paramList = measAuxStruct.paramList(idKeep);
               if (~isempty(measAuxStruct.paramDataMode))
                  measAuxStruct.paramDataMode = measAuxStruct.paramDataMode(idKeep);
               end
               measAuxStruct.paramData = measAuxStruct.paramData(:, idKeep);
               if (~isempty(a_profileData.dataAdj))
                  measAuxStruct.paramDataAdj = measAuxStruct.paramDataAdj(:, idKeep);
               end
               
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measAuxStruct];
            end                        
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_AscProfDeepestBin;
            measStruct.paramList = a_profileData.paramList;
            measStruct.paramDataMode = a_profileData.paramDataMode;
            measStruct.paramData = a_profileData.data(idNoDef(idMax), :);
            if (~isempty(a_profileData.dataAdj))
               measStruct.paramDataAdj = a_profileData.dataAdj(idNoDef(idMax), :);
            end
            
            idF1 = find(strcmp({measStruct.paramList.name}, 'LIGHT442') == 1, 1);
            idF2 = find(strcmp({measStruct.paramList.name}, 'LIGHT550') == 1, 1);
            idF3 = find(strcmp({measStruct.paramList.name}, 'LIGHT676') == 1, 1);
            idDel = [idF1 idF2 idF3];
            if (~isempty(idDel))
               measAuxStruct = measStruct;
               
               measStruct.paramList(idDel) = [];
               if (~isempty(measStruct.paramDataMode))
                  measStruct.paramDataMode(idDel) = [];
               end
               measStruct.paramData(:, idDel) = [];
               if (~isempty(a_profileData.dataAdj))
                  measStruct.paramDataAdj(:, idDel) = [];
               end
               
               measAuxStruct.sensorNumber = 101;
               idPres = find(strcmp({measAuxStruct.paramList.name}, 'PRES') == 1, 1);
               idKeep = [idPres idDel];
               measAuxStruct.paramList = measAuxStruct.paramList(idKeep);
               if (~isempty(measAuxStruct.paramDataMode))
                  measAuxStruct.paramDataMode = measAuxStruct.paramDataMode(idKeep);
               end
               measAuxStruct.paramData = measAuxStruct.paramData(:, idKeep);
               if (~isempty(a_profileData.dataAdj))
                  measAuxStruct.paramDataAdj = measAuxStruct.paramDataAdj(:, idKeep);
               end
               
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measAuxStruct];
            end
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GPS LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% unpack GPS data
gpsLocCycleNum = a_gpsData{1};
gpsLocDate = a_gpsData{4};
gpsLocLon = a_gpsData{5};
gpsLocLat = a_gpsData{6};
gpsLocQc = a_gpsData{7};

idF = find(gpsLocCycleNum == a_cycleNum);
gpsCyLocDate = gpsLocDate(idF);
gpsCyLocLon = gpsLocLon(idF);
gpsCyLocLat = gpsLocLat(idF);
gpsCyLocQc = gpsLocQc(idF);

for idFix = 1:length(gpsCyLocDate)
   measStruct = create_one_meas_surface(g_MC_Surface, ...
      gpsCyLocDate(idFix), ...
      gpsCyLocLon(idFix), ...
      gpsCyLocLat(idFix), ...
      'G', ...
      ' ', ...
      num2str(gpsCyLocQc(idFix)), 1);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IRIDIUM LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iridiumCyLocDate = [];
if (~isempty(a_iridiumData))
   idFixForCycle = find([a_iridiumData.cycleNumber] == a_cycleNum);
   for idFix = idFixForCycle
      if (a_iridiumData(idFix).cepRadius ~= 0)
         measStruct = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
            a_iridiumData(idFix).timeOfSessionJuld, ...
            a_iridiumData(idFix).unitLocationLon, ...
            a_iridiumData(idFix).unitLocationLat, ...
            'I', ...
            0, ...
            a_iridiumData(idFix).cepRadius*1000, ...
            a_iridiumData(idFix).cepRadius*1000, ...
            '', ...
            ' ', ...
            1);
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
   iridiumCyLocDate = [a_iridiumData(idFixForCycle).timeOfSessionJuld];
end

if (~isempty(gpsCyLocDate) || ~isempty(iridiumCyLocDate))
   locDates = [gpsCyLocDate' iridiumCyLocDate];

   trajNCycleStruct.juldFirstLocation = min(locDates);
   trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
   
   trajNCycleStruct.juldLastLocation = max(locDates);
   trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FINALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(trajNMeasStruct.tabMeas))
   if (trajNCycleStruct.dataMode == 'A')
      idF = find(~cellfun(@isempty, {trajNMeasStruct.tabMeas.juld}) & ...
         cellfun(@isempty, {trajNMeasStruct.tabMeas.juldAdj}));
      for idM = 1:length(idF)
         trajNMeasStruct.tabMeas(idF(idM)).juldAdj = trajNMeasStruct.tabMeas(idF(idM)).juld;
         trajNMeasStruct.tabMeas(idF(idM)).juldAdjStatus = trajNMeasStruct.tabMeas(idF(idM)).juldStatus;
         trajNMeasStruct.tabMeas(idF(idM)).juldAdjQc = trajNMeasStruct.tabMeas(idF(idM)).juldQc;
      end
   end
end

% add configuration mission number
if (a_cycleNum > 0) % we don't assign any configuration to cycle #0 data
   configMissionNumber = get_config_mission_number_nemo(a_cycleNum);
   if (~isempty(configMissionNumber))
      trajNCycleStruct.configMissionNumber = configMissionNumber;
   end
end

% output data
if (~isempty(trajNMeasStruct.tabMeas))
   o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
   o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStruct];
end

return
