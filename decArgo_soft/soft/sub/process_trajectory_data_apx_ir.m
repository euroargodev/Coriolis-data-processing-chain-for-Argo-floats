% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_apx_ir( ...
%    a_cycleNum, ...
%    a_surfDataLog, ...
%    a_pMarkDataMsg, a_pMarkDataLog, ...
%    a_driftData, a_parkData, a_parkDataEng, ...
%    a_profLrData, a_profHrData, ...
%    a_nearSurfData, ...
%    a_surfDataBladderDeflated, a_surfDataBladderInflated, a_surfDataMsg, ...
%    a_timeDataLog, a_gpsData, ...
%    a_profEndDateMsg, a_profEndAdjDateMsg, ...
%    a_clockOffsetData, o_presOffsetData, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_configExistFlag, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cycleNum                : current cycle number
%   a_surfDataLog             : surf data from log file
%   a_pMarkDataMsg            : P marks from msg file
%   a_pMarkDataLog            : P marks from log file
%   a_driftData               : drift data
%   a_parkData                : park data
%   a_parkDataEng             : park data from engineering data
%   a_profLrData              : profile LR data
%   a_profHrData              : profile HR data
%   a_nearSurfData            : NS data
%   a_surfDataBladderDeflated : surface data (bladder deflated)
%   a_surfDataBladderInflated : surface data (bladder inflated)
%   a_surfDataMsg             : surface data from engineering data
%   a_timeDataLog             : cycle timings from log file
%   a_gpsData                 : GPS data
%   a_profEndDateMsg          : profile end date
%   a_profEndAdjDateMsg       : profile end adjusted date
%   a_clockOffsetData         : clock offset information
%   a_presOffsetData          : input pressure offset information
%   a_tabTrajNMeas            : input traj N_MEAS data
%   a_tabTrajNCycle           : input traj N_CYCLE data
%   a_configExistFlag         : existing configuration flag
%   a_decoderId               : float decoder Id
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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_apx_ir( ...
   a_cycleNum, ...
   a_surfDataLog, ...
   a_pMarkDataMsg, a_pMarkDataLog, ...
   a_driftData, a_parkData, a_parkDataEng, ...
   a_profLrData, a_profHrData, ...
   a_nearSurfData, ...
   a_surfDataBladderDeflated, a_surfDataBladderInflated, a_surfDataMsg, ...
   a_timeDataLog, a_gpsData, ...
   a_profEndDateMsg, a_profEndAdjDateMsg, ...
   a_clockOffsetData, o_presOffsetData, ...
   a_tabTrajNMeas, a_tabTrajNCycle, ...
   a_configExistFlag, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_DescProf;
global g_MC_DET;
global g_MC_PST;
global g_MC_DriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_AET;
global g_MC_TST;
global g_MC_Surface;
global g_MC_TET;

global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
global g_MC_InAirSingleMeasRelativeToTST;
global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;

% RPP status
global g_RPP_STATUS_1;
global g_RPP_STATUS_4;

% default values
global g_decArgo_dateDef;

% float configuration
global g_decArgo_floatConfig;


% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);
trajNCycleStruct.grounded = 'U'; % grounding status is unknown

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLOCK OFFSET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve clock offset for this cycle
floatClockDrift = [];
if (~isempty(a_clockOffsetData.clockOffsetCycleNum))
   idF = find(a_clockOffsetData.clockSetCycleNum >= a_cycleNum);
   if (~isempty(idF))
      idF = idF(1);
   else
      if (any(a_clockOffsetData.clockOffsetCycleNum{end} == a_cycleNum))
         idF = length(a_clockOffsetData.clockOffsetCycleNum);
      else
         % RTC offset information not received yet for this cycle
      end
   end
   if (~isempty(idF))
      clockOffsetValue = a_clockOffsetData.clockOffsetValue{idF};
      clockOffsetCycleNum = a_clockOffsetData.clockOffsetCycleNum{idF};
      idCy = find(clockOffsetCycleNum == a_cycleNum, 1);
      if (~isempty(idCy))
         floatClockDrift = clockOffsetValue(idCy);
      else
         [clockOffsetCycleNumBis, idUnique, ~] = unique(clockOffsetCycleNum);
         clockOffsetValueBis = clockOffsetValue(idUnique);
         clockOffsetCycle = interp1q(clockOffsetCycleNumBis', clockOffsetValueBis', a_cycleNum);
         if (~isnan(clockOffsetCycle))
            floatClockDrift = floor(clockOffsetCycle); % adjustments rounded to 1 second
         end
      end
   end
end

% clock offset
clockDriftKnown = 0;
if (~isempty(floatClockDrift))
   trajNCycleStruct.clockOffset = floatClockDrift/86400;
   clockDriftKnown = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PRES OFFSET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve PRES offset for this cycle
presOffset = [];
idF = find(o_presOffsetData.cycleNumAdjPres == a_cycleNum, 1);
if (~isempty(idF))
   presOffset = o_presOffsetData.presOffset(idF);
end

% data mode
if (~isempty(floatClockDrift) || ~isempty(presOffset))
   trajNCycleStruct.dataMode = 'A';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT CYCLE TIMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cycleStartDate = g_decArgo_dateDef;
cycleStartAdjDate = g_decArgo_dateDef;
aetSet = 0;
if (~isempty(a_timeDataLog))
   
   % Cycle Start Time
   if (~isempty(a_timeDataLog.cycleStartDate))
      time = a_timeDataLog.cycleStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.cycleStartAdjDate))
         timeAdj = a_timeDataLog.cycleStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_CycleStart, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldCycleStart = nCycleTime;
         trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;
      end
      cycleStartDate = time;
      cycleStartAdjDate = timeAdj;
   end
   
   % Descent Start Time
   if (~isempty(a_timeDataLog.descentStartDate))
      time = a_timeDataLog.descentStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.descentStartAdjDate))
         timeAdj = a_timeDataLog.descentStartAdjDate;
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
   elseif (~isempty(a_timeDataLog.descentStartDateBis))
      time = a_timeDataLog.descentStartDateBis;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.descentStartAdjDateBis))
         timeAdj = a_timeDataLog.descentStartAdjDateBis;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_DST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_3);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldDescentStart = nCycleTime;
         trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_3;
      end
   end
   
   % Descent End Time
   if (~isempty(a_timeDataLog.descentEndDate))
      time = a_timeDataLog.descentEndDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.descentEndAdjDate))
         timeAdj = a_timeDataLog.descentEndAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_DET, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         idDrift = find(a_driftData.dates == a_timeDataLog.descentEndDate);
         measStruct.paramList = a_driftData.paramList;
         measStruct.paramDataMode = a_driftData.paramDataMode;
         measStruct.paramData = a_driftData.data(idDrift, :);
         if (~isempty(a_driftData.dataAdj))
            measStruct.paramDataAdj = a_driftData.dataAdj(idDrift, :);
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldDescentEnd = nCycleTime;
         trajNCycleStruct.juldDescentEndStatus = g_JULD_STATUS_2;
      end
   end  
   
   % Park Start Time
   if (~isempty(a_timeDataLog.parkStartDate))
      time = a_timeDataLog.parkStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.parkStartAdjDate))
         timeAdj = a_timeDataLog.parkStartAdjDate;
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
   if (~isempty(a_timeDataLog.parkEndDate))
      time = a_timeDataLog.parkEndDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.parkEndAdjDate))
         timeAdj = a_timeDataLog.parkEndAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_PET, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldParkEnd = nCycleTime;
         trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
      end
   elseif (fix(a_decoderId/100) == 12) % for Navis floats only
      if (~isempty(a_timeDataLog.parkEndDateBis))
         time = a_timeDataLog.parkEndDateBis;
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_timeDataLog.parkEndAdjDateBis))
            timeAdj = a_timeDataLog.parkEndAdjDateBis;
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
            g_MC_PET, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_3);
         if (~isempty(measStruct))
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.juldParkEnd = nCycleTime;
            trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_3;
         end
      end
   end
   
   % Ascent Start Time
   if (~isempty(a_timeDataLog.ascentStartDate))
      time = a_timeDataLog.ascentStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.ascentStartAdjDate))
         timeAdj = a_timeDataLog.ascentStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_AST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         if (~isempty(a_timeDataLog.ascentStartPres))
            measStruct.paramList = get_netcdf_param_attributes('PRES');
            measStruct.paramData = a_timeDataLog.ascentStartPres;
            if (~isempty(a_timeDataLog.ascentStartAdjPres))
               measStruct.paramDataAdj = a_timeDataLog.ascentStartAdjPres;
               measStruct.paramDataMode = 'A';
            end
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentStart = nCycleTime;
         trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Ascent End Time
   if (~isempty(a_timeDataLog.ascentEndDate))
      time = a_timeDataLog.ascentEndDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.ascentEndAdjDate))
         timeAdj = a_timeDataLog.ascentEndAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_AET, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         if (~isempty(a_timeDataLog.ascentEndPres))
            measStruct.paramList = get_netcdf_param_attributes('PRES');
            measStruct.paramData = a_timeDataLog.ascentEndPres;
            if (~isempty(a_timeDataLog.ascentEndAdjPres))
               measStruct.paramDataAdj = a_timeDataLog.ascentEndAdjPres;
               measStruct.paramDataMode = 'A';
            end
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentEnd = nCycleTime;
         trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
         aetSet = 1;
      end
   end
   if (aetSet == 0)
      if (~isempty(a_timeDataLog.ascentEnd2Date))
         time = a_timeDataLog.ascentEnd2Date;
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_timeDataLog.ascentEnd2AdjDate))
            timeAdj = a_timeDataLog.ascentEnd2AdjDate;
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
            aetSet = 1;
         end
      end
   end
   
   % Transmission Start Time (OF THE PREVIOUS CYCLE!)
   if (~isempty(a_timeDataLog.transStartDate))
      time = a_timeDataLog.transStartDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.transStartAdjDate))
         timeAdj = a_timeDataLog.transStartAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_TST, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         if (a_cycleNum > 0)
            if (isempty(o_tabTrajNMeas) || ~any([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0)))
               % no N_MEAS array for the previous cycle
                              
               % create N_MEAS array
               trajNMeasStructNew = get_traj_n_meas_init_struct(max(a_cycleNum-1, 0), -1);
               trajNMeasStructNew.tabMeas = [trajNMeasStructNew.tabMeas; measStruct];
               
               % create N_CYCLE array
               trajNCycleStructNew = get_traj_n_cycle_init_struct(max(a_cycleNum-1, 0), -1);
               trajNCycleStructNew.grounded = 'U'; % grounding status is unknown
               if (~isempty(a_timeDataLog.transStartAdjDate))
                  trajNCycleStructNew.clockOffset = time - timeAdj;
                  trajNCycleStructNew.dataMode = 'A';
               end
               trajNCycleStructNew.juldTransmissionStart = nCycleTime;
               trajNCycleStructNew.juldTransmissionStartStatus = g_JULD_STATUS_2;
               
               % add configuration mission number
               if (max(a_cycleNum-1, 0) > 0) % we don't assign any configuration to cycle #0 data
                  idF = find(g_decArgo_floatConfig.USE.CYCLE <= max(a_cycleNum-1, 0));
                  if (~isempty(idF))
                     configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_floatConfig.USE.CYCLE(idF(end)));
                     if (~isempty(configMissionNumber))
                        trajNCycleStructNew.configMissionNumber = configMissionNumber;
                     end
                  end
               end
               
               o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStructNew];
               o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStructNew];
            else
               idCyNMeas = find([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0));
               if (~isempty(o_tabTrajNMeas(idCyNMeas).tabMeas))
                  idTST = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_TST);
                  if (~isempty(idTST))
                     o_tabTrajNMeas(idCyNMeas).tabMeas(idTST) = measStruct;
                  else
                     o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                  end
               else
                  o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
               end
               
               idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
               o_tabTrajNCycle(idCyNCycle).juldTransmissionStart = nCycleTime;
               o_tabTrajNCycle(idCyNCycle).juldTransmissionStartStatus = g_JULD_STATUS_2;
            end
         else
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.juldTransmissionStart = nCycleTime;
            trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_2;
         end
      end
   end
   
   % Transmission End Time (OF THE PREVIOUS CYCLE!)
   if (~isempty(a_timeDataLog.transEndDate))
      time = a_timeDataLog.transEndDate;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_timeDataLog.transEndAdjDate))
         timeAdj = a_timeDataLog.transEndAdjDate;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_TET, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         if (a_cycleNum > 0)
            if (isempty(o_tabTrajNMeas) || ~any([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0)))
               % no N_MEAS array for the previous cycle
               
               % create N_MEAS array
               trajNMeasStructNew = get_traj_n_meas_init_struct(max(a_cycleNum-1, 0), -1);
               trajNMeasStructNew.tabMeas = [trajNMeasStructNew.tabMeas; measStruct];
               
               % create N_CYCLE array
               trajNCycleStructNew = get_traj_n_cycle_init_struct(max(a_cycleNum-1, 0), -1);
               trajNCycleStructNew.grounded = 'U'; % grounding status is unknown
               if (~isempty(a_timeDataLog.transStartAdjDate))
                  trajNCycleStructNew.clockOffset = time - timeAdj;
                  trajNCycleStructNew.dataMode = 'A';
               end
               trajNCycleStructNew.juldTransmissionEnd = nCycleTime;
               trajNCycleStructNew.juldTransmissionEndStatus = g_JULD_STATUS_2;
               
               % add configuration mission number
               if (max(a_cycleNum-1, 0) > 0) % we don't assign any configuration to cycle #0 data
                  idF = find(g_decArgo_floatConfig.USE.CYCLE <= max(a_cycleNum-1, 0));
                  if (~isempty(idF))
                     configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_floatConfig.USE.CYCLE(idF(end)));
                     if (~isempty(configMissionNumber))
                        trajNCycleStructNew.configMissionNumber = configMissionNumber;
                     end
                  end
               end
               
               o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStructNew];
               o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStructNew];
            else
               idCyNMeas = find([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0));
               if (~isempty(o_tabTrajNMeas(idCyNMeas).tabMeas))
                  idTET = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_TET);
                  if (~isempty(idTET))
                     o_tabTrajNMeas(idCyNMeas).tabMeas(idTET) = measStruct;
                  else
                     o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                  end
               else
                  o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
               end
               
               idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
               o_tabTrajNCycle(idCyNCycle).juldTransmissionEnd = nCycleTime;
               o_tabTrajNCycle(idCyNCycle).juldTransmissionEndStatus = g_JULD_STATUS_2;
            end
         else
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.juldTransmissionEnd = nCycleTime;
            trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_2;
         end
      end      
   end
end

if (aetSet == 0)
   if (~isempty(a_profEndDateMsg))
      time = a_profEndDateMsg;
      timeAdj = g_decArgo_dateDef;
      if (~isempty(a_profEndAdjDateMsg))
         timeAdj = a_profEndAdjDateMsg;
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
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCENDING PRES MARKS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% P marks from 'log' file have a better resolution and are precisely dated by
% the float => first choice
% if not received, we use P marks from 'msg' file

if (~isempty(a_pMarkDataLog))
   if (isempty(a_pMarkDataLog.datesAdj))
      a_pMarkDataLog.datesAdj = ones(size(a_pMarkDataLog.dates))*g_decArgo_dateDef;
   else
      a_pMarkDataLog.datesAdj(find(a_pMarkDataLog.datesAdj == a_pMarkDataLog.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   for idPM = 1:length(a_pMarkDataLog.dates)
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_DescProf, ...
         a_pMarkDataLog.dates(idPM), ...
         a_pMarkDataLog.datesAdj(idPM), ...
         g_JULD_STATUS_2);
      measStruct.paramList = a_pMarkDataLog.paramList;
      measStruct.paramDataMode = a_pMarkDataLog.paramDataMode;
      measStruct.paramData = a_pMarkDataLog.data(idPM, :);
      if (~isempty(a_pMarkDataLog.dataAdj))
         measStruct.paramDataAdj = a_pMarkDataLog.dataAdj(idPM, :);
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
elseif (~isempty(a_pMarkDataMsg))
   pMarkDataMsg = a_pMarkDataMsg;
   if (iscell(a_pMarkDataMsg))
      % same set of meas in case of multiple transmissions
      pMarkDataMsg = a_pMarkDataMsg{1};
   end
   
   for idPM = 1:length(pMarkDataMsg.data)
      time = g_decArgo_dateDef;
      timeAdj = g_decArgo_dateDef;
      if (cycleStartDate ~= g_decArgo_dateDef)
         if (idPM > 1)
            time = cycleStartDate + (idPM-1)/24;
            if (cycleStartAdjDate ~= g_decArgo_dateDef)
               timeAdj = cycleStartAdjDate + (idPM-1)/24;
            end
         end
      end
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_DescProf, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_3);
      if (isempty(measStruct))
         % not dated information
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_DescProf;
      end
      measStruct.paramList = pMarkDataMsg.paramList;
      measStruct.paramDataMode = pMarkDataMsg.paramDataMode;
      measStruct.paramData = pMarkDataMsg.data(idPM, :);
      if (~isempty(pMarkDataMsg.dataAdj))
         measStruct.paramDataAdj = pMarkDataMsg.dataAdj(idPM, :);
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEASUREMENTS SAMPLED DURING THE DRIFT AT PARKING DEPTH
% AND
% REPRESENTATIVE PARKING MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rppSet = 0;
if (~isempty(a_driftData))
   if (isempty(a_driftData.datesAdj))
      a_driftData.datesAdj = ones(size(a_driftData.dates))*g_decArgo_dateDef;
   else
      a_driftData.datesAdj(find(a_driftData.datesAdj == a_driftData.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   for idMeas = 1:length(a_driftData.dates)
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_DriftAtPark, ...
         a_driftData.dates(idMeas), ...
         a_driftData.datesAdj(idMeas), ...
         g_JULD_STATUS_2);
      measStruct.paramList = a_driftData.paramList;
      measStruct.paramDataMode = a_driftData.paramDataMode;
      measStruct.paramData = a_driftData.data(idMeas, :);
      if (~isempty(a_driftData.dataAdj))
         measStruct.paramDataAdj = a_driftData.dataAdj(idMeas, :);
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % RPP measurements
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_RPP;
   for idParam = 1:length(a_driftData.paramList)
      paramData = a_driftData.data(:, idParam);
      paramData(find(paramData == a_driftData.paramList(idParam).fillValue)) = [];
      paramDataAdj = [];
      if (~isempty(a_driftData.dataAdj))
         paramDataAdj = a_driftData.dataAdj(:, idParam);
         paramDataAdj(find(paramData == a_driftData.paramList(idParam).fillValue)) = [];
      end
      if (~isempty(paramData))
         measStruct.paramList = [measStruct.paramList a_driftData.paramList(idParam)];
         if (~isempty(a_driftData.paramDataMode))
            measStruct.paramDataMode = [measStruct.paramDataMode a_driftData.paramDataMode(idParam)];
         end
         measStruct.paramData = [measStruct.paramData mean(paramData)];
         if (~isempty(paramDataAdj))
            measStruct.paramDataAdj = [measStruct.paramDataAdj mean(paramDataAdj)];
         end
      end
   end
   if (~isempty(measStruct.paramList))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      idPres = find(strcmp({measStruct.paramList.name}, 'PRES') == 1);
      if (~isempty(idPres))
         if (~isempty(measStruct.paramDataAdj))
            trajNCycleStruct.repParkPres = measStruct.paramDataAdj(idPres);
         else
            trajNCycleStruct.repParkPres = measStruct.paramData(idPres);
         end
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
         rppSet = 1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MEASUREMENT SAMPLED AT THE END OF THE DRIFT AT PARKING DEPTH
% AND
% REPRESENTATIVE PARKING MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Park meas from 'msg' file has a better resolution (in P at least) but it is
% not dated (we use the PET from 'log' file) => first choice
% if not received, we use Park meas from 'log' file
% as Park meas from engineering data is after Park meas in the 'msg' file we
% never use it

% retrieve Park End Time if already stored
measStruct = [];
if (~isempty(trajNMeasStruct.tabMeas))
   idPET = find([trajNMeasStruct.tabMeas.measCode] == g_MC_PET);
   if (~isempty(idPET))
      measStruct = trajNMeasStruct.tabMeas(idPET);
   end
end
if (isempty(measStruct))
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_PET;
end

if (~isempty(a_parkData))
   measStruct.paramList = a_parkData.paramList;
   measStruct.paramDataMode = a_parkData.paramDataMode;
   measStruct.paramData = a_parkData.data;
   measStruct.paramDataAdj = a_parkData.dataAdj;
elseif ((~isempty(a_timeDataLog)) && (~isempty(a_timeDataLog.parkEndMeas)))
   measStruct.paramList = a_timeDataLog.parkEndMeas.paramList;
   measStruct.paramDataMode = a_timeDataLog.parkEndMeas.paramDataMode;
   measStruct.paramData = a_timeDataLog.parkEndMeas.data;
   measStruct.paramDataAdj = a_timeDataLog.parkEndMeas.dataAdj;
end

if (~isempty(measStruct.paramList))
   if (~isempty(idPET))
      trajNMeasStruct.tabMeas(idPET) = measStruct;
   else
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   if (~rppSet)
      % RPP measurement
      measStructRpp = get_traj_one_meas_init_struct();
      measStructRpp.measCode = g_MC_RPP;
      measStructRpp.paramList = measStruct.paramList;
      measStructRpp.paramDataMode = measStruct.paramDataMode;
      measStructRpp.paramData = measStruct.paramData;
      measStructRpp.paramDataAdj = measStruct.paramDataAdj;
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructRpp];
      
      idPres = find(strcmp({measStructRpp.paramList.name}, 'PRES') == 1);
      if (~isempty(idPres))
         if (~isempty(measStructRpp.paramDataAdj))
            trajNCycleStruct.repParkPres = measStructRpp.paramDataAdj(idPres);
         else
            trajNCycleStruct.repParkPres = measStructRpp.paramData(idPres);
         end
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_4;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PROFILE DATED BINS (Navis only)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ((~isempty(a_profLrData)) && (~isempty(a_profLrData.dates)))
   if (isempty(a_profLrData.datesAdj))
      a_profLrData.datesAdj = ones(size(a_profLrData.dates))*g_decArgo_dateDef;
   else
      a_profLrData.datesAdj(find(a_profLrData.datesAdj == a_profLrData.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   for idLev = 1:length(a_profLrData.dates)
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_AscProf, ...
         a_profLrData.dates(idLev), ...
         a_profLrData.datesAdj(idLev), ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         measStruct.paramList = a_profLrData.paramList;
         measStruct.paramDataMode = a_profLrData.paramDataMode;
         measStruct.paramData = a_profLrData.data(idLev, :);
         if (~isempty(a_profLrData.dataAdj))
            measStruct.paramDataAdj = a_profLrData.dataAdj(idLev, :);
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ASCENDING PROFILE DEEPEST BIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pMaxLrValue = [];
pMaxLrId = [];
if (~isempty(a_profLrData))
   idPres = find(strcmp({a_profLrData.paramList.name}, 'PRES') == 1);
   if (~isempty(idPres))
      presData = a_profLrData.data(:, idPres);
      presData(find(presData == a_profLrData.paramList(idPres).fillValue)) = [];
      if (~isempty(presData))
         pMaxLrValue = max(presData);
         pMaxLrId = find(a_profLrData.data(:, idPres) == pMaxLrValue, 1);
      end
   end
end
pMaxHrValue = [];
pMaxHrId = [];
if (~isempty(a_profHrData))
   
   % remove NB_SAMPLE parameter
   idNbSample  = find(strcmp({a_profHrData.paramList.name}, 'NB_SAMPLE') == 1, 1);
   if (~isempty(idNbSample))
      a_profHrData.paramList(idNbSample) = [];
      if (~isempty(a_profHrData.paramDataMode))
         a_profHrData.paramDataMode(idNbSample) = [];
      end
      a_profHrData.data(:, idNbSample) = [];
      if (~isempty(a_profHrData.dataAdj))
         a_profHrData.dataAdj(:, idNbSample) = [];
      end
   end
   
   idPres = find(strcmp({a_profHrData.paramList.name}, 'PRES') == 1);
   if (~isempty(idPres))
      presData = a_profHrData.data(:, idPres);
      presData(find(presData == a_profHrData.paramList(idPres).fillValue)) = [];
      if (~isempty(presData))
         pMaxHrValue = max(presData);
         pMaxHrId = find(a_profHrData.data(:, idPres) == pMaxHrValue, 1);
      end
   end
end
finalProf = [];
finalId = [];
if (~isempty(pMaxLrValue) && ~isempty(pMaxHrValue))
   if (pMaxLrValue > pMaxHrValue)
      finalProf = a_profLrData;
      finalId = pMaxLrId;
   else
      finalProf = a_profHrData;
      finalId = pMaxHrId;
   end
elseif (~isempty(pMaxLrValue))
   finalProf = a_profLrData;
   finalId = pMaxLrId;
elseif (~isempty(pMaxHrValue))
   finalProf = a_profHrData;
   finalId = pMaxHrId;
end
if (~isempty(finalProf))
   if (~isempty(finalProf.dates))
      if (isempty(finalProf.datesAdj))
         finalProf.datesAdj = ones(size(finalProf.dates))*g_decArgo_dateDef;
      else
         finalProf.datesAdj(find(finalProf.datesAdj == finalProf.dateList.fillValue)) = g_decArgo_dateDef;
      end
      
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_AscProfDeepestBin, ...
         finalProf.dates(finalId), ...
         finalProf.datesAdj(finalId), ...
         g_JULD_STATUS_2);
      if (isempty(measStruct))
         % not dated information
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_AscProfDeepestBin;
      end
      measStruct.paramList = finalProf.paramList;
      measStruct.paramDataMode = finalProf.paramDataMode;
      measStruct.paramData = finalProf.data(finalId, :);
      if (~isempty(finalProf.dataAdj))
         measStruct.paramDataAdj = finalProf.dataAdj(finalId, :);
      end
   else
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_AscProfDeepestBin;
      measStruct.paramList = finalProf.paramList;
      measStruct.paramDataMode = finalProf.paramDataMode;
      measStruct.paramData = finalProf.data(finalId, :);
      if (~isempty(finalProf.dataAdj))
         measStruct.paramDataAdj = finalProf.dataAdj(finalId, :);
      end
   end
   
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NEAR SURFACE MEASUREMENTS (Navis only)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_nearSurfData))
   % same set of meas in case of multiple transmissions
   nearSurfData = a_nearSurfData{1};
   
   if (isempty(nearSurfData.datesAdj))
      nearSurfData.datesAdj = ones(size(nearSurfData.dates))*g_decArgo_dateDef;
   else
      nearSurfData.datesAdj(find(nearSurfData.datesAdj == nearSurfData.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   for idM = 1:length(nearSurfData.dates)
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST, ...
         nearSurfData.dates(idM), ...
         nearSurfData.datesAdj(idM), ...
         g_JULD_STATUS_2);
      if (isempty(measStruct))
         % not dated information
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;
      end
      measStruct.paramList = nearSurfData.paramList;
      measStruct.paramDataMode = nearSurfData.paramDataMode;
      measStruct.paramData = nearSurfData.data(idM, :);
      if (~isempty(nearSurfData.dataAdj))
         measStruct.paramDataAdj = nearSurfData.dataAdj(idM, :);
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SURFACE MEASUREMENTS (Apex only)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Surface meas from 'log' file are dated => first choice
% if not received, we use Surface meas from 'msg' file

% surface measurements (from 'log' file, i.e. OF THE PREVIOUS CYCLE)
if (~isempty(a_surfDataLog))
   if (isempty(a_surfDataLog.datesAdj))
      a_surfDataLog.datesAdj = ones(size(a_surfDataLog.dates))*g_decArgo_dateDef;
   else
      a_surfDataLog.datesAdj(find(a_surfDataLog.datesAdj == a_surfDataLog.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   if (a_cycleNum > 0)
      if (isempty(o_tabTrajNMeas) || ~any([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0)))
         % no N_MEAS array for the previous cycle
   
         % create N_MEAS array
         trajNMeasStructNew = get_traj_n_meas_init_struct(max(a_cycleNum-1, 0), -1);
         % store surface meas
         for idM = 1:length(a_surfDataLog.dates)
            [measStruct, ~] = create_one_meas_float_time_bis( ...
               g_MC_InAirSingleMeasRelativeToTST, ...
               a_surfDataLog.dates(idM), ...
               a_surfDataLog.datesAdj(idM), ...
               g_JULD_STATUS_2);
            if (isempty(measStruct))
               % not dated information
               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = g_MC_InAirSingleMeasRelativeToTST;
            end
            measStruct.paramList = a_surfDataLog.paramList;
            measStruct.paramDataMode = a_surfDataLog.paramDataMode;
            measStruct.paramData = a_surfDataLog.data(idM, :);
            if (~isempty(a_surfDataLog.dataAdj))
               measStruct.paramDataAdj = a_surfDataLog.dataAdj(idM, :);
            end
            
            trajNMeasStructNew.tabMeas = [trajNMeasStructNew.tabMeas; measStruct];
         end
         
         % create N_CYCLE array
         trajNCycleStructNew = get_traj_n_cycle_init_struct(max(a_cycleNum-1, 0), -1);
         trajNCycleStructNew.grounded = 'U'; % grounding status is unknown
         if (~isempty(a_surfDataLog.dates) && ~isempty(a_surfDataLog.datesAdj))
            trajNCycleStructNew.clockOffset = a_surfDataLog.dates(1) - a_surfDataLog.datesAdj(1);
            trajNCycleStructNew.dataMode = 'A';
         end
         if (~isempty(a_surfDataLog.dataAdj))
            trajNCycleStructNew.dataMode = 'A';
         end

         % add configuration mission number
         if (max(a_cycleNum-1, 0) > 0) % we don't assign any configuration to cycle #0 data
            idF = find(g_decArgo_floatConfig.USE.CYCLE <= max(a_cycleNum-1, 0));
            if (~isempty(idF))
               configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_floatConfig.USE.CYCLE(idF(end)));
               if (~isempty(configMissionNumber))
                  trajNCycleStructNew.configMissionNumber = configMissionNumber;
               end
            end
         end
         
         o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStructNew];
         o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStructNew];
      else
         idCyNMeas = find([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0));
         
         % remove existing surface meas (from 'msg' file)
         if (~isempty(o_tabTrajNMeas(idCyNMeas).tabMeas))
            idIASOM = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_InAirSingleMeasRelativeToTST);
            if (~isempty(idIASOM))
               idNoDate = find(cellfun(@isempty, {o_tabTrajNMeas(idCyNMeas).tabMeas(idIASOM).juld}));
               o_tabTrajNMeas(idCyNMeas).tabMeas(idIASOM(idNoDate)) = [];
            end
         end
         
         % store surface meas
         for idM = 1:length(a_surfDataLog.dates)
            [measStruct, ~] = create_one_meas_float_time_bis( ...
               g_MC_InAirSingleMeasRelativeToTST, ...
               a_surfDataLog.dates(idM), ...
               a_surfDataLog.datesAdj(idM), ...
               g_JULD_STATUS_2);
            if (isempty(measStruct))
               % not dated information
               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = g_MC_InAirSingleMeasRelativeToTST;
            end
            measStruct.paramList = a_surfDataLog.paramList;
            measStruct.paramDataMode = a_surfDataLog.paramDataMode;
            measStruct.paramData = a_surfDataLog.data(idM, :);
            if (~isempty(a_surfDataLog.dataAdj))
               measStruct.paramDataAdj = a_surfDataLog.dataAdj(idM, :);
            end
            
            o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
         end
      end
   else
      % store surface meas
      for idM = 1:length(a_surfDataLog.dates)
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            g_MC_InAirSingleMeasRelativeToTST, ...
            a_surfDataLog.dates(idM), ...
            a_surfDataLog.datesAdj(idM), ...
            g_JULD_STATUS_2);
         if (isempty(measStruct))
            % not dated information
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_InAirSingleMeasRelativeToTST;
         end
         measStruct.paramList = a_surfDataLog.paramList;
         measStruct.paramDataMode = a_surfDataLog.paramDataMode;
         measStruct.paramData = a_surfDataLog.data(idM, :);
         if (~isempty(a_surfDataLog.dataAdj))
            measStruct.paramDataAdj = a_surfDataLog.dataAdj(idM, :);
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
end

% surface measurements (from 'msg' file, i.e. OF THE CURRENT CYCLE)
if (~isempty(a_surfDataMsg))
   for idS = 1:length(a_surfDataMsg)
      surfDataMsg = a_surfDataMsg{idS};
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_InAirSingleMeasRelativeToTST;
      measStruct.paramList = surfDataMsg.paramList;
      measStruct.paramDataMode = surfDataMsg.paramDataMode;
      measStruct.paramData = surfDataMsg.data;
      measStruct.paramDataAdj = surfDataMsg.dataAdj;
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SURFACE MEASUREMENTS (Navis only)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_surfDataBladderDeflated))
   % same set of meas in case of multiple transmissions
   surfDataBladderDeflated = a_surfDataBladderDeflated{1};
   
   if (isempty(surfDataBladderDeflated.datesAdj))
      surfDataBladderDeflated.datesAdj = ones(size(surfDataBladderDeflated.dates))*g_decArgo_dateDef;
   else
      surfDataBladderDeflated.datesAdj(find(surfDataBladderDeflated.datesAdj == surfDataBladderDeflated.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   for idM = 1:length(surfDataBladderDeflated.dates)
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST, ...
         surfDataBladderDeflated.dates(idM), ...
         surfDataBladderDeflated.datesAdj(idM), ...
         g_JULD_STATUS_2);
      if (isempty(measStruct))
         % not dated information
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
      end
      measStruct.paramList = surfDataBladderDeflated.paramList;
      measStruct.paramDataMode = surfDataBladderDeflated.paramDataMode;
      measStruct.paramData = surfDataBladderDeflated.data(idM, :);
      if (~isempty(surfDataBladderDeflated.dataAdj))
         measStruct.paramDataAdj = surfDataBladderDeflated.dataAdj(idM, :);
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStructAux = measStruct;
      measStructAux.sensorNumber = 101;
      idPres = find(strcmp({measStructAux.paramList.name}, 'PRES') == 1);
      measStructAux.paramList = measStructAux.paramList(idPres);
      if (~isempty(measStructAux.paramDataMode))
         measStructAux.paramDataMode = measStructAux.paramDataMode(idPres);
      end
      measStructAux.paramData = measStructAux.paramData(idPres);
      if (~isempty(measStructAux.paramDataAdj))
         measStructAux.paramDataAdj = measStructAux.paramDataAdj(idPres);
      end
      paramBladderInflatedFlag = get_netcdf_param_attributes('BLADDER_INFLATED_FLAG');
      measStructAux.paramList = [measStructAux.paramList paramBladderInflatedFlag];
      if (~isempty(measStructAux.paramDataMode))
         measStructAux.paramDataMode = [measStructAux.paramDataMode ' '];
      end
      measStructAux.paramData = [measStructAux.paramData zeros(size(measStructAux.paramData, 1))];
      if (~isempty(measStructAux.paramDataAdj))
         measStructAux.paramDataAdj = [measStructAux.paramDataAdj repmat(paramBladderInflatedFlag.fillValue, size(measStructAux.paramData, 1), 1)];
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
   end
end

if (~isempty(a_surfDataBladderInflated))
   % same set of meas in case of multiple transmissions
   surfDataBladderInflated = a_surfDataBladderInflated{1};
   
   if (isempty(surfDataBladderInflated.datesAdj))
      surfDataBladderInflated.datesAdj = ones(size(surfDataBladderInflated.dates))*g_decArgo_dateDef;
   else
      surfDataBladderInflated.datesAdj(find(surfDataBladderInflated.datesAdj == surfDataBladderInflated.dateList.fillValue)) = g_decArgo_dateDef;
   end
   
   for idM = 1:length(surfDataBladderInflated.dates)
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST, ...
         surfDataBladderInflated.dates(idM), ...
         surfDataBladderInflated.datesAdj(idM), ...
         g_JULD_STATUS_2);
      if (isempty(measStruct))
         % not dated information
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
      end
      measStruct.paramList = surfDataBladderInflated.paramList;
      measStruct.paramDataMode = surfDataBladderInflated.paramDataMode;
      measStruct.paramData = surfDataBladderInflated.data(idM, :);
      if (~isempty(surfDataBladderInflated.dataAdj))
         measStruct.paramDataAdj = surfDataBladderInflated.dataAdj(idM, :);
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStructAux = measStruct;
      measStructAux.sensorNumber = 101;
      idPres = find(strcmp({measStructAux.paramList.name}, 'PRES') == 1);
      measStructAux.paramList = measStructAux.paramList(idPres);
      if (~isempty(measStructAux.paramDataMode))
         measStructAux.paramDataMode = measStructAux.paramDataMode(idPres);
      end
      measStructAux.paramData = measStructAux.paramData(idPres);
      if (~isempty(measStructAux.paramDataAdj))
         measStructAux.paramDataAdj = measStructAux.paramDataAdj(idPres);
      end
      paramBladderInflatedFlag = get_netcdf_param_attributes('BLADDER_INFLATED_FLAG');
      measStructAux.paramList = [measStructAux.paramList paramBladderInflatedFlag];
      if (~isempty(measStructAux.paramDataMode))
         measStructAux.paramDataMode = [measStructAux.paramDataMode ' '];
      end
      measStructAux.paramData = [measStructAux.paramData ones(size(measStructAux.paramData, 1))];
      if (~isempty(measStructAux.paramDataAdj))
         measStructAux.paramDataAdj = [measStructAux.paramDataAdj repmat(paramBladderInflatedFlag.fillValue, size(measStructAux.paramData, 1), 1)];
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GPS LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% GPS LOCATIONS management should be at the end because when we recover an
% unseen cycle we have no way to retrieve cycle DATA_MODE from GPS times =>
% always 'R'
% but if TST has also been recovered, the cycle is created and its DATA_MODE
% already set => the recovered GPS fixes can be added to the recovered cycle

% unpack GPS data
gpsLocCycleNum = a_gpsData{1};
gpsLocDate = a_gpsData{4};
gpsLocLon = a_gpsData{5};
gpsLocLat = a_gpsData{6};
gpsLocQc = a_gpsData{7};

% GPS data for the previous cycle
if (a_cycleNum > 0)
   idF = find(gpsLocCycleNum == max(a_cycleNum-1, 0));
   if (~isempty(idF))
      gpsLocDatePrevCy = gpsLocDate(idF);
      gpsLocLonPrevCy = gpsLocLon(idF);
      gpsLocLatPrevCy = gpsLocLat(idF);
      gpsLocQcPrevCy = gpsLocQc(idF);
      
      if (~isempty(o_tabTrajNMeas))
         idCyNMeas = find([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0));
         if (~isempty(idCyNMeas))
            if (~isempty(o_tabTrajNMeas(idCyNMeas).tabMeas))
               idSurf = find([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_Surface);
               if (~isempty(idSurf))
                  
                  % retrieve data mode of previous cycle
                  idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
                  if (isempty(o_tabTrajNCycle(idCyNCycle).clockOffset))
                     clockDriftKnownPrevCy = 0;
                  else
                     clockDriftKnownPrevCy = 1;
                  end
                  
                  % check that all GPS fixes are already stored in N_MEAS
                  newOne = 0;
                  for idFix = 1:length(gpsLocDatePrevCy)
                     if (~any((gpsLocDatePrevCy(idFix) == [o_tabTrajNMeas(idCyNMeas).tabMeas(idSurf).juld]) & ...
                           (gpsLocLonPrevCy(idFix) == [o_tabTrajNMeas(idCyNMeas).tabMeas(idSurf).longitude]) & ...
                           (gpsLocLatPrevCy(idFix) == [o_tabTrajNMeas(idCyNMeas).tabMeas(idSurf).latitude])))
                        
                        measStruct = create_one_meas_surface(g_MC_Surface, ...
                           gpsLocDatePrevCy(idFix), ...
                           gpsLocLonPrevCy(idFix), ...
                           gpsLocLatPrevCy(idFix), ...
                           'G', ...
                           ' ', ...
                           num2str(gpsLocQcPrevCy(idFix)), ...
                           clockDriftKnownPrevCy);
                        o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                        newOne = 1;
                     end
                  end
                  
                  % update N_CYCLE
                  if (newOne)                     
                     o_tabTrajNCycle(idCyNCycle).juldFirstLocation = min(gpsLocDatePrevCy);
                     o_tabTrajNCycle(idCyNCycle).juldFirstLocationStatus = g_JULD_STATUS_4;
                     
                     o_tabTrajNCycle(idCyNCycle).juldLastLocation = max(gpsLocDatePrevCy);
                     o_tabTrajNCycle(idCyNCycle).juldLastLocationStatus = g_JULD_STATUS_4;
                  end
               else
                  
                  % retrieve data mode of previous cycle
                  idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
                  if (isempty(o_tabTrajNCycle(idCyNCycle).clockOffset))
                     clockDriftKnownPrevCy = 0;
                  else
                     clockDriftKnownPrevCy = 1;
                  end
                  
                  % store GPS fixes in N_MEAS
                  for idFix = 1:length(gpsLocDatePrevCy)
                     measStruct = create_one_meas_surface(g_MC_Surface, ...
                        gpsLocDatePrevCy(idFix), ...
                        gpsLocLonPrevCy(idFix), ...
                        gpsLocLatPrevCy(idFix), ...
                        'G', ...
                        ' ', ...
                        num2str(gpsLocQcPrevCy(idFix)), ...
                        clockDriftKnownPrevCy);
                     o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                  end
                  
                  % update N_CYCLE
                  o_tabTrajNCycle(idCyNCycle).juldFirstLocation = min(gpsLocDatePrevCy);
                  o_tabTrajNCycle(idCyNCycle).juldFirstLocationStatus = g_JULD_STATUS_4;
                  
                  o_tabTrajNCycle(idCyNCycle).juldLastLocation = max(gpsLocDatePrevCy);
                  o_tabTrajNCycle(idCyNCycle).juldLastLocationStatus = g_JULD_STATUS_4;
               end
            else
               
               % retrieve data mode of previous cycle
               idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
               if (isempty(o_tabTrajNCycle(idCyNCycle).clockOffset))
                  clockDriftKnownPrevCy = 0;
               else
                  clockDriftKnownPrevCy = 1;
               end
               
               % store GPS fixes in N_MEAS
               for idFix = 1:length(gpsLocDatePrevCy)
                  measStruct = create_one_meas_surface(g_MC_Surface, ...
                     gpsLocDatePrevCy(idFix), ...
                     gpsLocLonPrevCy(idFix), ...
                     gpsLocLatPrevCy(idFix), ...
                     'G', ...
                     ' ', ...
                     num2str(gpsLocQcPrevCy(idFix)), ...
                     clockDriftKnownPrevCy);
                  o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
               end
               
               % update N_CYCLE               
               o_tabTrajNCycle(idCyNCycle).juldFirstLocation = min(gpsLocDatePrevCy);
               o_tabTrajNCycle(idCyNCycle).juldFirstLocationStatus = g_JULD_STATUS_4;
               
               o_tabTrajNCycle(idCyNCycle).juldLastLocation = max(gpsLocDatePrevCy);
               o_tabTrajNCycle(idCyNCycle).juldLastLocationStatus = g_JULD_STATUS_4;
            end
         else
            
            % no N_MEAS array for the previous cycle
            
            % create N_MEAS array
            trajNMeasStructNew = get_traj_n_meas_init_struct(max(a_cycleNum-1, 0), -1);
            % store GPS fixes in N_MEAS
            for idFix = 1:length(gpsLocDatePrevCy)
               measStruct = create_one_meas_surface(g_MC_Surface, ...
                  gpsLocDatePrevCy(idFix), ...
                  gpsLocLonPrevCy(idFix), ...
                  gpsLocLatPrevCy(idFix), ...
                  'G', ...
                  ' ', ...
                  num2str(gpsLocQcPrevCy(idFix)), 0); % the clock offset is unknown !
               trajNMeasStructNew.tabMeas = [trajNMeasStructNew.tabMeas; measStruct];
            end
            
            % create N_CYCLE array
            trajNCycleStructNew = get_traj_n_cycle_init_struct(max(a_cycleNum-1, 0), -1);
            trajNCycleStructNew.grounded = 'U'; % grounding status is unknown
            % update N_CYCLE
            trajNCycleStructNew.juldFirstLocation = min(gpsLocDatePrevCy);
            trajNCycleStructNew.juldFirstLocationStatus = g_JULD_STATUS_4;
            
            trajNCycleStructNew.juldLastLocation = max(gpsLocDatePrevCy);
            trajNCycleStructNew.juldLastLocationStatus = g_JULD_STATUS_4;
            
            % add configuration mission number
            if (max(a_cycleNum-1, 0) > 0) % we don't assign any configuration to cycle #0 data
               idF = find(g_decArgo_floatConfig.USE.CYCLE <= max(a_cycleNum-1, 0));
               if (~isempty(idF))
                  configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_floatConfig.USE.CYCLE(idF(end)));
                  if (~isempty(configMissionNumber))
                     trajNCycleStructNew.configMissionNumber = configMissionNumber;
                  end
               end
            end
            
            o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStructNew];
            o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStructNew];
         end
      end
   end
end

% GPS data for the current cycle
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
      num2str(gpsCyLocQc(idFix)), ...
      clockDriftKnown);
   
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

if (~isempty(gpsCyLocDate))
   trajNCycleStruct.juldFirstLocation = min(gpsCyLocDate);
   trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
   
   trajNCycleStruct.juldLastLocation = max(gpsCyLocDate);
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
   if (a_configExistFlag)
      configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
      if (~isempty(configMissionNumber))
         trajNCycleStruct.configMissionNumber = configMissionNumber;
      end
   else
      % no configuration has been received, we use the previous one
      idF = find(g_decArgo_floatConfig.USE.CYCLE <= a_cycleNum);
      configMissionNumber = get_config_mission_number_ir_sbd(g_decArgo_floatConfig.USE.CYCLE(idF(end)));
      if (~isempty(configMissionNumber))
         trajNCycleStruct.configMissionNumber = configMissionNumber;
      end
   end
end

% output data
if (~isempty(trajNMeasStruct.tabMeas))
   o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
   o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStruct];
end

return
