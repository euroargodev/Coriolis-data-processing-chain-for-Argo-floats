% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
%    process_trajectory_data_apx_apf11_ir( ...
%    a_cycleNum, ...
%    a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
%    a_profCtdCp, a_profCtdCpH, a_profFlbbCd, a_profOcr504I, a_profRamses, ...
%    a_profRafosRtc, a_profRafos, ...
%    a_gpsData, a_grounding, a_iceDetection, a_buoyancy, ...
%    a_cycleTimeData, ...
%    a_clockOffsetData, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)
%
% INPUT PARAMETERS :
%   a_cycleNum        : current cycle number
%   a_profCtdP        : CTD_P data
%   a_profCtdPt       : CTD_PT data
%   a_profCtdPts      : CTD_PTS data
%   a_profCtdPtsh     : CTD_PTSH data
%   a_profDo          : O2 data
%   a_profCtdCp       : CTD_CP data
%   a_profCtdCpH      : CTD_CP_H data
%   a_profFlbbCd      : FLBB_CD data
%   a_profOcr504I     : OCR_504I data
%   a_profRamses      : RAMSES data
%   a_profRafosRtc    : RAFOS_RTC data
%   a_profRafos       : RAFOS data
%   a_gpsData         : GPS data
%   a_grounding       : grounding data
%   a_iceDetection    : ice detection data
%   a_buoyancy        : buoyancy data
%   a_cycleTimeData   : cycle timings data
%   a_clockOffsetData : clock offset information
%   a_tabTrajNMeas    : input traj N_MEAS data
%   a_tabTrajNCycle   : input traj N_CYCLE data
%   a_tabTechNMeas    : input tech N_MEAS data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output traj N_MEAS data
%   o_tabTrajNCycle : output traj N_CYCLE data
%   o_tabTechNMeas  : output tech N_MEAS data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
   process_trajectory_data_apx_apf11_ir( ...
   a_cycleNum, ...
   a_profCtdP, a_profCtdPt, a_profCtdPts, a_profCtdPtsh, a_profDo, ...
   a_profCtdCp, a_profCtdCpH, a_profFlbbCd, a_profOcr504I, a_profRamses, ...
   a_profRafosRtc, a_profRafos, ...
   a_gpsData, a_grounding, a_iceDetection, a_buoyancy, ...
   a_cycleTimeData, ...
   a_clockOffsetData, ...
   a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabTechNMeas = a_tabTechNMeas;

% global measurement codes
global g_MC_DST;
global g_MC_DET;
global g_MC_PST;
global g_MC_RafosCorrelationStart;
global g_MC_PET;
global g_MC_RPP;
global g_MC_DDET;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_MedianValueInAscProf;
global g_MC_IceThermalDetectionTrue;
global g_MC_ContinuousProfileStartOrStop;
global g_MC_AET;
global g_MC_TST;
global g_MC_Surface;
global g_MC_TET;
global g_MC_Grounded;

global g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;

% RPP status
global g_RPP_STATUS_1;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;

% float configuration
global g_decArgo_floatConfig;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcProbablyGood;

% QC flag values (char)
global g_decArgo_qcStrProbablyGood;


% if (a_cycleNum == 73)
%    a=1
% end

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% structure to store N_MEASUREMENT technical data
techNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CLOCK OFFSET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve clock offset for this cycle
cycleClockOffset = get_clock_offset_value_apx_apf11_ir(a_clockOffsetData, a_cycleTimeData);
trajNCycleStruct.clockOffset = cycleClockOffset/86400;

% data mode
trajNCycleStruct.dataMode = 'A'; % because clock offset is supposed to be set for each cycle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT CYCLE TIMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramGpsTimeToFix = get_netcdf_param_attributes('GPS_TIME_TO_FIX');
paramGpsNbSat = get_netcdf_param_attributes('GPS_NB_SATELLITE');
paramValveFlag = get_netcdf_param_attributes('VALVE_ACTION_FLAG');
paramPumpFlag = get_netcdf_param_attributes('PUMP_ACTION_FLAG');
paramNbSampleIceDetect = get_netcdf_param_attributes('NB_SAMPLE_ICE_DETECTION');
paramRafosCorStartFlag = get_netcdf_param_attributes('RAFOS_CORRELATION_START_FLAG');

descentStartDate = a_cycleTimeData.descentStartDateSci;
descentStartAdjDate = a_cycleTimeData.descentStartAdjDateSci;
descentStartPres = a_cycleTimeData.descentStartPresSci;
descentStartAdjPres = a_cycleTimeData.descentStartAdjPresSci;
descentEndDate = a_cycleTimeData.descentEndDate;
descentEndAdjDate = a_cycleTimeData.descentEndAdjDate;
descentEndPres = a_cycleTimeData.descentEndPres;
descentEndAdjPres = a_cycleTimeData.descentEndAdjPres;
rafosCorStartDate = a_cycleTimeData.rafosCorrelationStartDateSci;
rafosCorStartAdjDate = a_cycleTimeData.rafosCorrelationStartAdjDateSci;
rafosCorStartPres = a_cycleTimeData.rafosCorrelationStartPresSci;
rafosCorStartAdjPres = a_cycleTimeData.rafosCorrelationStartAdjPresSci;
parkStartDate = a_cycleTimeData.parkStartDateSci;
parkStartAdjDate = a_cycleTimeData.parkStartAdjDateSci;
parkStartPres = a_cycleTimeData.parkStartPresSci;
parkStartAdjPres = a_cycleTimeData.parkStartAdjPresSci;
parkEndDate = a_cycleTimeData.parkEndDateSci;
parkEndAdjDate = a_cycleTimeData.parkEndAdjDateSci;
parkEndPres = a_cycleTimeData.parkEndPresSci;
parkEndAdjPres = a_cycleTimeData.parkEndAdjPresSci;
deepDescentEndDate = a_cycleTimeData.deepDescentEndDate;
deepDescentEndAdjDate = a_cycleTimeData.deepDescentEndAdjDate;
deepDescentEndPres = a_cycleTimeData.deepDescentEndPres;
deepDescentEndAdjPres = a_cycleTimeData.deepDescentEndAdjPres;
ascentStartDate = a_cycleTimeData.ascentStartDateSci;
ascentStartAdjDate = a_cycleTimeData.ascentStartAdjDateSci;
ascentStartPres = a_cycleTimeData.ascentStartPresSci;
ascentStartAdjPres = a_cycleTimeData.ascentStartAdjPresSci;
continuousProfileStartDate = a_cycleTimeData.continuousProfileStartDateSci;
continuousProfileStartAdjDate = a_cycleTimeData.continuousProfileStartAdjDateSci;
continuousProfileStartPres = a_cycleTimeData.continuousProfileStartPresSci;
continuousProfileStartAdjPres = a_cycleTimeData.continuousProfileStartAdjPresSci;
continuousProfileEndDate = a_cycleTimeData.continuousProfileEndDateSci;
continuousProfileEndAdjDate = a_cycleTimeData.continuousProfileEndAdjDateSci;
continuousProfileEndPres = a_cycleTimeData.continuousProfileEndPresSci;
continuousProfileEndAdjPres = a_cycleTimeData.continuousProfileEndAdjPresSci;
ascentEndDate = a_cycleTimeData.ascentEndDate;
ascentEndAdjDate = a_cycleTimeData.ascentEndAdjDateSci;
ascentEndPres = a_cycleTimeData.ascentEndPresSci;
ascentEndAdjPres = a_cycleTimeData.ascentEndAdjPresSci;
bladderInflationStartDate = a_cycleTimeData.bladderInflationStartDateSys;
transStartDate = a_cycleTimeData.transStartDate;
transStartAdjDate = a_cycleTimeData.transStartAdjDate;
transEndDate = a_cycleTimeData.transEndDate;
transEndAdjDate = a_cycleTimeData.transEndAdjDate;

% Descent Start Time
if (~isempty(descentStartDate))
   time = descentStartDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(descentStartAdjDate))
      timeAdj = descentStartAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_DST, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStruct))
      if (~isempty(descentStartPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = descentStartPres;
         if (~isempty(descentStartAdjPres))
            measStruct.paramDataAdj = descentStartAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldDescentStart = nCycleTime;
      trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
   end
end

% Descent End Time
if (~isempty(descentEndDate))
   time = descentEndDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(descentEndAdjDate))
      timeAdj = descentEndAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_DET, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_3);
   if (~isempty(measStruct))
      if (~isempty(descentEndPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = descentEndPres;
         if (~isempty(descentEndAdjPres))
            measStruct.paramDataAdj = descentEndAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldDescentEnd = nCycleTime;
      trajNCycleStruct.juldDescentEndStatus = g_JULD_STATUS_3;
   end
end

% Park Start Time
if (~isempty(parkStartDate))
   time = parkStartDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(parkStartAdjDate))
      timeAdj = parkStartAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_PST, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStruct))
      if (~isempty(parkStartPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = parkStartPres;
         if (~isempty(parkStartAdjPres))
            measStruct.paramDataAdj = parkStartAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldParkStart = nCycleTime;
      trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
   end
end

% Park End Time
if (~isempty(parkEndDate))
   time = parkEndDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(parkEndAdjDate))
      timeAdj = parkEndAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_PET, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStruct))
      if (~isempty(parkEndPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = parkEndPres;
         if (~isempty(parkEndAdjPres))
            measStruct.paramDataAdj = parkEndAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldParkEnd = nCycleTime;
      trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
   end
end

% Deep Descent End Time
if (~isempty(deepDescentEndDate))
   time = deepDescentEndDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(deepDescentEndAdjDate))
      timeAdj = deepDescentEndAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_DDET, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_3);
   if (~isempty(measStruct))
      if (~isempty(deepDescentEndPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = deepDescentEndPres;
         if (~isempty(deepDescentEndAdjPres))
            measStruct.paramDataAdj = deepDescentEndAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldDeepDescentEnd = nCycleTime;
      trajNCycleStruct.juldDeepDescentEndStatus = g_JULD_STATUS_3;
   end
end

% Ascent Start Time
if (~isempty(ascentStartDate))
   time = ascentStartDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(ascentStartAdjDate))
      timeAdj = ascentStartAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_AST, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStruct))
      if (~isempty(ascentStartPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = ascentStartPres;
         if (~isempty(ascentStartAdjPres))
            measStruct.paramDataAdj = ascentStartAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldAscentStart = nCycleTime;
      trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
   end
end

% Ascent End Time
if (~isempty(ascentEndDate))
   time = ascentEndDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(ascentEndAdjDate))
      timeAdj = ascentEndAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_AET, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStruct))
      if (~isempty(ascentEndPres))
         measStruct.paramList = paramPres;
         measStruct.paramData = ascentEndPres;
         if (~isempty(ascentEndAdjPres))
            measStruct.paramDataAdj = ascentEndAdjPres;
            measStruct.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldAscentEnd = nCycleTime;
      trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
   end
end

% Transmission Start Time
if (~isempty(transStartDate))
   time = transStartDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(transStartAdjDate))
      timeAdj = transStartAdjDate;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_TST, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldTransmissionStart = nCycleTime;
      trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_2;
   end
end

% Transmission End Time (OF THE PREVIOUS CYCLE!)
if (~isempty(transEndDate))
   time = transEndDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(transEndAdjDate))
      timeAdj = transEndAdjDate;
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
            trajNCycleStructNew.dataMode = 'A';
            if (~isempty(transEndAdjDate))
               trajNCycleStructNew.clockOffset = time - timeAdj;
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
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CTD_P, CTD_PT, CTD_PTS, CTD_PTSH, O2, FLBB_CD, OCR_504I MEASUREMENTS (because
% all are dated) stored with MC-10
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

phaseDates = [];
phaseMeasCode = [];
if (~isempty(transEndDate))
   phaseDates = [phaseDates transEndDate];
   phaseMeasCode = [phaseMeasCode g_MC_TET];
end
if (~isempty(descentStartDate))
   phaseDates = [phaseDates descentStartDate];
   phaseMeasCode = [phaseMeasCode g_MC_DST];
end
if (~isempty(descentEndDate))
   phaseDates = [phaseDates descentEndDate];
   phaseMeasCode = [phaseMeasCode g_MC_DET];
end
if (~isempty(parkStartDate))
   phaseDates = [phaseDates parkStartDate];
   phaseMeasCode = [phaseMeasCode g_MC_PST];
end
if (~isempty(parkEndDate))
   phaseDates = [phaseDates parkEndDate];
   phaseMeasCode = [phaseMeasCode g_MC_PET];
end
if (~isempty(deepDescentEndDate))
   phaseDates = [phaseDates deepDescentEndDate];
   phaseMeasCode = [phaseMeasCode g_MC_DDET];
end
if (~isempty(ascentStartDate))
   phaseDates = [phaseDates ascentStartDate];
   phaseMeasCode = [phaseMeasCode g_MC_AST];
end
if (~isempty(ascentEndDate))
   phaseDates = [phaseDates ascentEndDate];
   phaseMeasCode = [phaseMeasCode g_MC_AET];
end
if (~isempty(bladderInflationStartDate))
   phaseDates = [phaseDates bladderInflationStartDate];
   phaseMeasCode = [phaseMeasCode g_MC_TST];
end
if (~isempty(transStartDate))
   phaseDates = [phaseDates transStartDate];
   phaseMeasCode = [phaseMeasCode g_MC_TST];
end
[phaseDates, idSort] = sort(phaseDates);
phaseMeasCode = phaseMeasCode(idSort);

if (~isempty(phaseDates))
   measList = [{'CTD_P'} {'CTD_PT'} {'CTD_PTS'} {'CTD_PTSH'} {'O2'} {'FLBB_CD'} {'OCR_504I'} {'RAMSES'} {'RAFOS_RTC'} {'RAFOS'}];
   for idML = 1:length(measList)
      doDataFlag = 0;
      switch (measList{idML})
         case 'CTD_P'
            if (isempty(a_profCtdP))
               continue
            end
            profData = a_profCtdP;
         case 'CTD_PT'
            if (isempty(a_profCtdPt))
               continue
            end
            profData = a_profCtdPt;
         case 'CTD_PTS'
            if (isempty(a_profCtdPts))
               continue
            end
            profData = a_profCtdPts;
         case 'CTD_PTSH'
            if (isempty(a_profCtdPtsh))
               continue
            end
            profData = a_profCtdPtsh;
         case 'O2'
            if (isempty(a_profDo))
               continue
            end
            profData = a_profDo;
            doDataFlag = 1;
         case 'FLBB_CD'
            if (isempty(a_profFlbbCd))
               continue
            end
            profData = a_profFlbbCd;
         case 'OCR_504I'
            if (isempty(a_profOcr504I))
               continue
            end
            profData = a_profOcr504I;
         case 'RAMSES'
            if (isempty(a_profRamses))
               continue
            end
            profData = a_profRamses;
         case 'RAFOS_RTC'
            if (isempty(a_profRafosRtc))
               continue
            end
            profData = a_profRafosRtc;
         case 'RAFOS'
            if (isempty(a_profRafos))
               continue
            end
            profData = a_profRafos;
      end
            
      % some CTD_P have no timestamp (see 7900580 #45)
      idDel = find(profData.dates == paramJuld.fillValue);
      if (~isempty(idDel))
         profData.dates(idDel) = [];
         if (~isempty(profData.datesAdj))
            profData.datesAdj(idDel) = [];
         end
         if (~isempty(profData.datesStatus))
            profData.datesStatus(idDel) = [];
         end
         profData.data(idDel, :) = [];
         if (~isempty(profData.dataAdj))
            profData.dataAdj(idDel, :) = [];
         end
         if (~isempty(profData.dataRed))
            profData.dataRed(idDel, :) = [];
         end
      end
      
      if (isempty(profData.dates))
         continue
      end
      
      for idPhase = 1:length(phaseDates)+1
         if (idPhase <= length(phaseDates))
            if (idPhase > 1)
               idData = find((profData.dates > phaseDates(idPhase-1)) & ...
                  (profData.dates <= phaseDates(idPhase)));
            else
               if (a_cycleNum > 0)
                  idData = find(profData.dates <= phaseDates(idPhase));
               else
                  idData = 1:length(profData.dates);
               end
            end
            measCode = phaseMeasCode(idPhase) - 10;
         else
            idData = find(profData.dates > phaseDates(idPhase-1))';
            measCode = g_MC_TET - 10;
         end
         
         if (doDataFlag)
            if (~isempty(bladderInflationStartDate))
               if ((idPhase <= length(phaseDates)) && (phaseDates(idPhase) == bladderInflationStartDate))
                  measCode = g_MC_InWaterSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
               elseif ((idPhase > 1) && (phaseDates(idPhase-1) == bladderInflationStartDate))
                  measCode = g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
               end
            end
         end
         
         %          if (measCode == 590)
         %             a=1
         %          end
         
         for idM = 1:length(idData)
            idMeas = idData(idM);
            time = profData.dates(idMeas);
            
            %             if (strcmp(julian_2_gregorian_dec_argo(time), '2020/02/20 04:24:23'))
            %                a=1
            %             end
            
            timeAdj = g_decArgo_dateDef;
            if (~isempty(profData.datesAdj))
               timeAdj = profData.datesAdj(idMeas);
            end
            [measStruct, ~] = create_one_meas_float_time_bis( ...
               measCode, ...
               time, ...
               timeAdj, ...
               g_JULD_STATUS_2);
            % if DO dates have been estimated by the decoder, set JULD_QC to '2'
            if ((doDataFlag) && (profData.temporaryDates))
               if (~isempty(measStruct.juldQc))
                  measStruct.juldQc = g_decArgo_qcStrProbablyGood;
               end
               if (~isempty(measStruct.juldAdjQc))
                  measStruct.juldAdjQc = g_decArgo_qcStrProbablyGood;
               end
            end

            if (~isempty(measStruct))
               
               measStruct.paramList = profData.paramList;
               measStruct.paramDataMode = profData.paramDataMode;
               measStruct.paramNumberWithSubLevels = profData.paramNumberWithSubLevels;
               measStruct.paramNumberOfSubLevels = profData.paramNumberOfSubLevels;
               measStruct.paramData = profData.data(idMeas, :);
               
               if (ismember(measList{idML}, [{'RAMSES'} {'RAFOS_RTC'} {'RAFOS'}]))
                  measStruct.sensorNumber = 999;
               end
               
               % if DO dates have been estimated by the decoder, set PRES_QC to '2'
               if ((doDataFlag) && (profData.temporaryDates))
                  measStruct.paramDataQc = ones(size(measStruct.paramData))*g_decArgo_qcDef;
                  idPres = find(strcmp({measStruct.paramList.name}, 'PRES'), 1);
                  measStruct.paramDataQc(:, idPres) = g_decArgo_qcProbablyGood;
               end
               
               if (~isempty(profData.dataAdj))
                  measStruct.paramDataAdj = profData.dataAdj(idMeas, :);
                  % if DO dates have been estimated by the decoder, set PRES_QC to '2'
                  if ((doDataFlag) && (profData.temporaryDates))
                     measStruct.paramDataAdjQc = ones(size(measStruct.paramDataAdj))*g_decArgo_qcDef;
                     idPres = find(strcmp({measStruct.paramList.name}, 'PRES'), 1);
                     measStruct.paramDataAdjQc(:, idPres) = g_decArgo_qcProbablyGood;
                  end
                  
                  deleteFlag = 1;
                  for idParam = 1:length(measStruct.paramList)
                     if (measStruct.paramDataMode(idParam) == 'A')
                        paramInfo = get_netcdf_param_attributes(measStruct.paramList(idParam).name);
                        if (measStruct.paramDataAdj(1, idParam) ~= paramInfo.fillValue)
                           deleteFlag = 0;
                           break
                        end
                     end
                  end
                  if (deleteFlag)
                     measStruct.paramDataMode = [];
                     measStruct.paramDataAdj = [];
                  end
               end
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% REPRESENTATIVE PARKING MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(parkStartDate) && ~isempty(parkEndDate))
   
   % RPP measurements
   measStruct = get_traj_one_meas_init_struct();
   measStruct.measCode = g_MC_RPP;
   
   paramList = [];
   paramDataMode = [];
   paramDataStruct = [];
   paramDataAdjStruct = [];
   measList = [{'CTD_P'} {'CTD_PT'} {'CTD_PTS'} {'CTD_PTSH'} {'O2'} {'FLBB_CD'} {'OCR_504I'}];
   for idML = 1:length(measList)
      switch (measList{idML})
         case 'CTD_P'
            if (isempty(a_profCtdP))
               continue
            end
            profData = a_profCtdP;
         case 'CTD_PT'
            if (isempty(a_profCtdPt))
               continue
            end
            profData = a_profCtdPt;
         case 'CTD_PTS'
            if (isempty(a_profCtdPts))
               continue
            end
            profData = a_profCtdPts;
         case 'CTD_PTSH'
            if (isempty(a_profCtdPtsh))
               continue
            end
            profData = a_profCtdPtsh;
         case 'O2'
            if (isempty(a_profDo))
               continue
            end
            profData = a_profDo;
         case 'FLBB_CD'
            if (isempty(a_profFlbbCd))
               continue
            end
            profData = a_profFlbbCd;
         case 'OCR_504I'
            if (isempty(a_profOcr504I))
               continue
            end
            profData = a_profOcr504I;
      end
      
      if (isempty(profData.dates) || ~any(profData.dates ~= paramJuld.fillValue))
         continue
      end
      
      idData = find((profData.dates >= parkStartDate) & ...
         (profData.dates <= parkEndDate));
      
      if (~isempty(idData))
         for idParam = 1:length(profData.paramList)
            paramName = profData.paramList(idParam).name;
            paramData = profData.data(idData, idParam);
            paramData(find(paramData == profData.paramList(idParam).fillValue)) = [];
            paramDataAdj = [];
            if (~isempty(profData.dataAdj))
               paramDataAdj = profData.dataAdj(idData, idParam);
               paramDataAdj(find(paramDataAdj == profData.paramList(idParam).fillValue)) = [];
            end
            if (~isempty(paramData))
               idF = [];
               if (~isempty(paramList))
                  idF = find(strcmp({paramList.name}, paramName));
               end
               if (isempty(idF))
                  paramList = [paramList profData.paramList(idParam)];
                  if (~isempty(profData.paramDataMode))
                     paramDataMode = [paramDataMode profData.paramDataMode(idParam)];
                  else
                     paramDataMode = [paramDataMode ' '];
                  end
                  paramDataStruct.(paramName) = paramData;
                  if (~isempty(paramDataAdj))
                     paramDataAdjStruct.(paramName) = paramDataAdj;
                  end
               else
                  paramDataStruct.(paramName) = [paramDataStruct.(paramName); paramData];
                  if (~isempty(paramDataAdj))
                     paramDataAdjStruct.(paramName) = [paramDataAdjStruct.(paramName); paramDataAdj];
                  end
               end
            end
         end
      end
   end
   
   if (~isempty(paramList))
      measStruct.paramList = paramList;
      measStruct.paramDataMode = paramDataMode;
      for idParam = 1:length(paramList)
         measStruct.paramData = [measStruct.paramData mean(paramDataStruct.(paramList(idParam).name))];
         if (isfield(paramDataAdjStruct, paramList(idParam).name))
            measStruct.paramDataAdj = [measStruct.paramDataAdj mean(paramDataAdjStruct.(paramList(idParam).name))];
         else
            measStruct.paramDataAdj = [measStruct.paramDataAdj paramList(idParam).fillValue];
         end
      end
      if (all(measStruct.paramDataMode == ' '))
         measStruct.paramDataMode = [];
         measStruct.paramDataAdj = [];
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      idPres = find(strcmp({measStruct.paramList.name}, 'PRES') == 1);
      if (~isempty(idPres))
         if (~isempty(measStruct.paramDataAdj))
            trajNCycleStruct.repParkPres = measStruct.paramDataAdj(idPres);
         else
            trajNCycleStruct.repParkPres = measStruct.paramData(idPres);
         end
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEEPEST BIN OF THE ASCENDING PROFILE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(ascentStartDate) && ...
      ~isempty(ascentEndDate))
   
   profMax = [];
   presMax = [];
   presMaxTime = g_decArgo_dateDef;
   presMaxTimeAdj = g_decArgo_dateDef;
   idMax = [];
   measList = [{'CTD_PTS'} {'CTD_PTSH'} {'O2'} {'FLBB_CD'} {'OCR_504I'} {'CTD_CP'} {'CTD_CP_H'}];
   for idML = 1:length(measList)
      switch (measList{idML})
         case 'CTD_PTS'
            if (isempty(a_profCtdPts))
               continue
            end
            profData = a_profCtdPts;
         case 'CTD_PTSH'
            if (isempty(a_profCtdPtsh))
               continue
            end
            profData = a_profCtdPtsh;
         case 'O2'
            if (isempty(a_profDo))
               continue
            end
            profData = a_profDo;
         case 'FLBB_CD'
            if (isempty(a_profFlbbCd))
               continue
            end
            profData = a_profFlbbCd;
         case 'OCR_504I'
            if (isempty(a_profOcr504I))
               continue
            end
            profData = a_profOcr504I;
         case 'CTD_CP'
            if (isempty(a_profCtdCp))
               continue
            end
            profData = a_profCtdCp;
         case 'CTD_CP_H'
            if (isempty(a_profCtdCpH))
               continue
            end
            profData = a_profCtdCpH;
      end
      
      if (isempty(profData.dates))
         idData = 1:size(profData.data, 1);
      else
         idData = find((profData.dates >= ascentStartDate) & ...
            (profData.dates <= ascentEndDate));
      end
      
      if (~isempty(idData))
         idPres = find(strcmp({profData.paramList.name}, 'PRES'));
         if (~isempty(idPres))
            presData = profData.data(idData, idPres);
            idOk = find(presData ~= paramPres.fillValue);
            presData = presData(idOk);
            if (~isempty(presData))
               if (isempty(presMax))
                  [presMax, idMax] = max(presData);
                  profMax = profData;
                  idMax = idData(idOk(idMax));
                  if (isempty(profData.dates))
                     presMaxTime = g_decArgo_dateDef;
                     presMaxTimeAdj = g_decArgo_dateDef;
                  else
                     presMaxTime = profData.dates(idMax);
                     if (~isempty(profData.datesAdj))
                        presMaxTimeAdj = profData.datesAdj(idMax);
                     else
                        presMaxTimeAdj = g_decArgo_dateDef;
                     end
                  end
               elseif (max(presData) > presMax)
                  [presMax, idMax] = max(presData);
                  profMax = profData;
                  idMax = idData(idOk(idMax));
                  if (isempty(profData.dates))
                     presMaxTime = g_decArgo_dateDef;
                     presMaxTimeAdj = g_decArgo_dateDef;
                  else
                     presMaxTime = profData.dates(idMax);
                     if (~isempty(profData.datesAdj))
                        presMaxTimeAdj = profData.datesAdj(idMax);
                     else
                        presMaxTimeAdj = g_decArgo_dateDef;
                     end
                  end
               end
            end
         end
      end
   end
   
   % create the N_MEAS
   if (~isempty(profMax))
      if (~isempty(presMaxTime))
         time = presMaxTime;
         timeAdj = presMaxTimeAdj;
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            g_MC_AscProfDeepestBin, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStruct))
            measStruct.paramList = profMax.paramList;
            measStruct.paramDataMode = profMax.paramDataMode;
            measStruct.paramData = profMax.data(idMax, :);
            if (~isempty(profMax.dataAdj))
               measStruct.paramDataAdj = profMax.dataAdj(idMax, :);
               deleteFlag = 1;
               for idParam = 1:length(measStruct.paramList)
                  if (measStruct.paramDataMode(idParam) == 'A')
                     paramInfo = get_netcdf_param_attributes(measStruct.paramList(idParam).name);
                     if (measStruct.paramDataAdj(1, idParam) ~= paramInfo.fillValue)
                        deleteFlag = 0;
                        break
                     end
                  end
               end
               if (deleteFlag)
                  measStruct.paramDataMode = [];
                  measStruct.paramDataAdj = [];
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
      else
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_AscProfDeepestBin;
         measStruct.paramList = profMax.paramList;
         measStruct.paramDataMode = profMax.paramDataMode;
         measStruct.paramData = profMax.data(idMax, :);
         if (~isempty(profMax.dataAdj))
            measStruct.paramDataAdj = profMax.dataAdj(idMax, :);
            deleteFlag = 1;
            for idParam = 1:length(measStruct.paramList)
               if (measStruct.paramDataMode(idParam) == 'A')
                  paramInfo = get_netcdf_param_attributes(measStruct.paramList(idParam).name);
                  if (measStruct.paramDataAdj(1, idParam) ~= paramInfo.fillValue)
                     deleteFlag = 0;
                     break
                  end
               end
            end
            if (deleteFlag)
               measStruct.paramDataMode = [];
               measStruct.paramDataAdj = [];
            end
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ICE DETECTION DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_iceDetection))
   
   % NOTE that, due to float issue, Ice information may have erroneous
   % timestamps in the system_log (Ex: 6903695 #40) file and then are not dated
   
   % PT measurements of thermal detection algorithm: (JULD, P, T) stored in TRAJ
   % with MC=590
   for idMeas = 1:length(a_iceDetection.thermalDetect.sampleTime)
      time = a_iceDetection.thermalDetect.sampleTime(idMeas);
      timeAdj = a_iceDetection.thermalDetect.sampleTimeAdj(idMeas);
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_AET - 10, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (isempty(measStruct))
         % some Ice events have been recovered from system_log file even without
         % timestamp
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_AET - 10;
      end
      measStruct.paramList = [paramPres paramTemp];
      measStruct.paramData = [a_iceDetection.thermalDetect.samplePres(idMeas) a_iceDetection.thermalDetect.sampleTemp(idMeas)];
      if (a_iceDetection.thermalDetect.samplePresAdj(idMeas) ~= g_decArgo_presDef)
         measStruct.paramDataAdj = [a_iceDetection.thermalDetect.samplePresAdj(idMeas) paramTemp.fillValue];
         measStruct.paramDataMode = 'A ';
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % median value of PT measurements of thermal detection algorithm: (JULD, T)
   % stored in TRAJ with MC=595
   if (~isempty(a_iceDetection.thermalDetect.medianTempTime))
      time = a_iceDetection.thermalDetect.medianTempTime;
      timeAdj = a_iceDetection.thermalDetect.medianTempTimeAdj;
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_MedianValueInAscProf, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (isempty(measStruct))
         % some Ice events have been recovered from system_log file even without
         % timestamp
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MedianValueInAscProf;
      end
      measStruct.paramList = paramTemp;
      measStruct.paramData = a_iceDetection.thermalDetect.medianTemp;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % when thermal detection is TRUE: (JULD, P, NB_SAMPLE_ICE_DETECTION) stored in TRAJ_AUX
   % with MC=599
   if (~isempty(a_iceDetection.thermalDetect.detectTime) && ...
         ~isempty(a_iceDetection.thermalDetect.detectNbSample))
      time = a_iceDetection.thermalDetect.detectTime;
      timeAdj = a_iceDetection.thermalDetect.detectTimeAdj;
      [measStructAux, ~] = create_one_meas_float_time_bis( ...
         g_MC_IceThermalDetectionTrue, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (isempty(measStructAux))
         % some Ice events have been recovered from system_log file even without
         % timestamp
         measStructAux = get_traj_one_meas_init_struct();
         measStructAux.measCode = g_MC_IceThermalDetectionTrue;
      end
      measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
      measStructAux.paramList = [paramPres paramNbSampleIceDetect];
      measStructAux.paramData = [a_iceDetection.thermalDetect.detectPres a_iceDetection.thermalDetect.detectNbSample];
      if (a_iceDetection.thermalDetect.detectPresAdj ~= g_decArgo_presDef)
         measStructAux.paramDataAdj = [a_iceDetection.thermalDetect.detectPresAdj paramNbSampleIceDetect.fillValue];
         measStructAux.paramDataMode = 'A ';
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUOYANCY ACTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_buoyancy))
   
   phaseDates = [];
   phaseMeasCode = [];
   if (~isempty(descentEndDate))
      phaseDates = [phaseDates descentEndDate];
      phaseMeasCode = [phaseMeasCode g_MC_DET];
   end
   if (~isempty(parkStartDate))
      phaseDates = [phaseDates parkStartDate];
      phaseMeasCode = [phaseMeasCode g_MC_PST];
   end
   if (~isempty(parkEndDate))
      phaseDates = [phaseDates parkEndDate];
      phaseMeasCode = [phaseMeasCode g_MC_PET];
   end
   if (~isempty(deepDescentEndDate))
      phaseDates = [phaseDates deepDescentEndDate];
      phaseMeasCode = [phaseMeasCode g_MC_DDET];
   end
   if (~isempty(ascentStartDate))
      phaseDates = [phaseDates ascentStartDate];
      phaseMeasCode = [phaseMeasCode g_MC_AST];
   end
   if (~isempty(ascentEndDate))
      phaseDates = [phaseDates ascentEndDate];
      phaseMeasCode = [phaseMeasCode g_MC_AET];
   end
   if (~isempty(bladderInflationStartDate))
      phaseDates = [phaseDates bladderInflationStartDate];
      phaseMeasCode = [phaseMeasCode g_MC_TST];
   end
   if (~isempty(transStartDate))
      phaseDates = [phaseDates transStartDate];
      phaseMeasCode = [phaseMeasCode g_MC_TST];
   end
   [phaseDates, idSort] = sort(phaseDates);
   phaseMeasCode = phaseMeasCode(idSort);
   
   buoyDates = a_buoyancy(:, 1);
   for idPhase = 1:length(phaseDates)
      if (idPhase > 1)
         idData = find((buoyDates > phaseDates(idPhase-1)) & ...
            (buoyDates <= phaseDates(idPhase)));
      else
         idData = find(buoyDates <= phaseDates(idPhase));
      end
      refMeasCode = phaseMeasCode(idPhase);
      
      for idB = 1:length(idData)
         idBuoy = idData(idB);
         time = buoyDates(idBuoy);
         timeAdj = a_buoyancy(idBuoy, 2);
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            refMeasCode-11, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStruct))
            measStructTechNMeas = measStruct;
            
            measStruct.paramList = paramPres;
            measStruct.paramData = a_buoyancy(idBuoy, 3);
            if (a_buoyancy(idBuoy, 4) ~= g_decArgo_presDef)
               measStruct.paramDataAdj = a_buoyancy(idBuoy, 4);
               measStruct.paramDataMode = 'A';
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            if (a_buoyancy(idBuoy, 5) == 0)
               measStructTechNMeas.paramList = paramValveFlag;
            else
               measStructTechNMeas.paramList = paramPumpFlag;
            end
            measStructTechNMeas.paramData = 1;
            techNMeasStruct.tabMeas = [techNMeasStruct.tabMeas; measStructTechNMeas];
         end
      end
   end
   
   % manage Ice cycles
   if (~isempty(a_cycleTimeData.iceDescentStartDateSci))
      
      for idC = 1:length(a_cycleTimeData.iceDescentStartDateSci)
         
         % Descent Start Time
         time = a_cycleTimeData.iceDescentStartDateSci(idC);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_cycleTimeData.iceDescentStartAdjDateSci(idC)))
            timeAdj = a_cycleTimeData.iceDescentStartAdjDateSci(idC);
         end
         [measStructAux, ~] = create_one_meas_float_time_bis( ...
            g_MC_DST, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStructAux))
            measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
            if (~isempty(descentStartPres))
               measStructAux.paramList = paramPres;
               measStructAux.paramData = a_cycleTimeData.iceDescentStartPresSci(idC);
               if (~isempty(a_cycleTimeData.iceDescentStartAdjPresSci(idC)))
                  measStructAux.paramDataAdj = a_cycleTimeData.iceDescentStartAdjPresSci(idC);
                  measStructAux.paramDataMode = 'A';
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
         end
         
         % Descent End Time
         time = a_cycleTimeData.iceAscentStartDateSci(idC);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_cycleTimeData.iceAscentStartAdjDateSci(idC)))
            timeAdj = a_cycleTimeData.iceAscentStartAdjDateSci(idC);
         end
         [measStructAux, ~] = create_one_meas_float_time_bis( ...
            g_MC_DET, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStructAux))
            measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
            if (~isempty(descentStartPres))
               measStructAux.paramList = paramPres;
               measStructAux.paramData = a_cycleTimeData.iceAscentStartPresSci(idC);
               if (~isempty(a_cycleTimeData.iceAscentStartAdjPresSci(idC)))
                  measStructAux.paramDataAdj = a_cycleTimeData.iceAscentStartAdjPresSci(idC);
                  measStructAux.paramDataMode = 'A';
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
         end
         
         % Ascent Start Time
         time = a_cycleTimeData.iceAscentStartDateSci(idC);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_cycleTimeData.iceAscentStartAdjDateSci(idC)))
            timeAdj = a_cycleTimeData.iceAscentStartAdjDateSci(idC);
         end
         [measStructAux, ~] = create_one_meas_float_time_bis( ...
            g_MC_AST, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStructAux))
            measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
            if (~isempty(descentStartPres))
               measStructAux.paramList = paramPres;
               measStructAux.paramData = a_cycleTimeData.iceAscentStartPresSci(idC);
               if (~isempty(a_cycleTimeData.iceAscentStartAdjPresSci(idC)))
                  measStructAux.paramDataAdj = a_cycleTimeData.iceAscentStartAdjPresSci(idC);
                  measStructAux.paramDataMode = 'A';
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
         end
         
         % Ascent End Time
         time = a_cycleTimeData.iceAscentEndDateSci(idC);
         timeAdj = g_decArgo_dateDef;
         if (~isempty(a_cycleTimeData.iceAscentEndAdjDateSci(idC)))
            timeAdj = a_cycleTimeData.iceAscentEndAdjDateSci(idC);
         end
         [measStructAux, ~] = create_one_meas_float_time_bis( ...
            g_MC_AET, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStructAux))
            measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
            if (~isempty(descentStartPres))
               measStructAux.paramList = paramPres;
               measStructAux.paramData = a_cycleTimeData.iceAscentEndPresSci(idC);
               if (~isempty(a_cycleTimeData.iceAscentEndAdjPresSci(idC)))
                  measStructAux.paramDataAdj = a_cycleTimeData.iceAscentEndAdjPresSci(idC);
                  measStructAux.paramDataMode = 'A';
               end
            end
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GROUNDING INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

grounded = 'N';
if (~isempty(a_grounding))
   
   for idG = 1:size(a_grounding, 1)
      time = a_grounding(idG, 1);
      timeAdj = a_grounding(idG, 2);
      [measStruct, ~] = create_one_meas_float_time_bis( ...
         g_MC_Grounded, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         measStruct.paramList = paramPres;
         measStruct.paramData = a_grounding(idG, 3);
         if (a_grounding(idG, 4) ~= g_decArgo_presDef)
            measStruct.paramDataAdj = a_grounding(idG, 4);
            measStruct.paramDataMode = 'A';
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         grounded = 'Y';
      end
   end
end
trajNCycleStruct.grounded = grounded;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONTINUOUS PROFILE START & STOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Continuous profile start & stop time
if (~isempty(continuousProfileStartDate) && ~isempty(continuousProfileEndDate))
   time = continuousProfileStartDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(continuousProfileStartAdjDate))
      timeAdj = continuousProfileStartAdjDate;
   end
   [measStructAux, ~] = create_one_meas_float_time_bis( ...
      g_MC_ContinuousProfileStartOrStop, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStructAux))
      measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
      if (~isempty(continuousProfileStartPres))
         measStructAux.paramList = paramPres;
         measStructAux.paramData = continuousProfileStartPres;
         if (~isempty(continuousProfileStartAdjPres))
            measStructAux.paramDataAdj = continuousProfileStartAdjPres;
            measStructAux.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
   end
   
   time = continuousProfileEndDate;
   timeAdj = g_decArgo_dateDef;
   if (~isempty(continuousProfileEndAdjDate))
      timeAdj = continuousProfileEndAdjDate;
   end
   [measStructAux, ~] = create_one_meas_float_time_bis( ...
      g_MC_ContinuousProfileStartOrStop, ...
      time, ...
      timeAdj, ...
      g_JULD_STATUS_2);
   if (~isempty(measStructAux))
      measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
      if (~isempty(continuousProfileEndPres))
         measStructAux.paramList = paramPres;
         measStructAux.paramData = continuousProfileEndPres;
         if (~isempty(continuousProfileEndAdjPres))
            measStructAux.paramDataAdj = continuousProfileEndAdjPres;
            measStructAux.paramDataMode = 'A';
         end
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RAFOS CORRELATION START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Rafos correlation start
if (~isempty(rafosCorStartDate))
   
   for idC = 1:length(rafosCorStartDate)
      time = rafosCorStartDate(idC);
      timeAdj = g_decArgo_dateDef;
      if (~isempty(rafosCorStartAdjDate(idC)))
         timeAdj = rafosCorStartAdjDate(idC);
      end
      [measStructAux, ~] = create_one_meas_float_time_bis( ...
         g_MC_RafosCorrelationStart, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStructAux))
         measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
         if (~isempty(rafosCorStartPres))
            measStructAux.paramList = [paramPres paramRafosCorStartFlag];
            measStructAux.paramData = [rafosCorStartPres(idC) 1];
            if (~isempty(rafosCorStartAdjPres(idC)))
               measStructAux.paramDataAdj = [rafosCorStartAdjPres(idC) -1];
               measStructAux.paramDataMode = 'A ';
            end
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
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
if ((size(a_gpsData, 1) == 1) && (length(a_gpsData) == 9)) % launch location only
   gpsLocNbSat = -1;
   gpsLocTimeToFix = -1;
else
   gpsLocNbSat = a_gpsData{10};
   gpsLocTimeToFix = a_gpsData{11};
end

% GPS data for the previous cycle
if (a_cycleNum > 0)
   idF = find(gpsLocCycleNum == max(a_cycleNum-1, 0));
   if (~isempty(idF))
      gpsLocDatePrevCy = gpsLocDate(idF);
      gpsLocLonPrevCy = gpsLocLon(idF);
      gpsLocLatPrevCy = gpsLocLat(idF);
      gpsLocQcPrevCy = gpsLocQc(idF);
      gpsLocNbSatPrevCy = gpsLocNbSat(idF);
      gpsLocTimeToFixPrevCy = gpsLocTimeToFix(idF);
      
      if (~isempty(o_tabTrajNMeas))
         idCyNMeas = find([o_tabTrajNMeas.cycleNumber] == max(a_cycleNum-1, 0));
         if (~isempty(idCyNMeas))
            if (~isempty(o_tabTrajNMeas(idCyNMeas).tabMeas))
               idSurf = find(([o_tabTrajNMeas(idCyNMeas).tabMeas.measCode] == g_MC_Surface) & ...
                  ([o_tabTrajNMeas(idCyNMeas).tabMeas.sensorNumber] < 100));
               if (~isempty(idSurf))
                  
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
                           num2str(gpsLocQcPrevCy(idFix)), 1);
                        o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                        newOne = 1;
                        
                        if ((gpsLocNbSatPrevCy(idFix) ~= -1) && (gpsLocTimeToFixPrevCy(idFix) ~= -1))
                           
                           time = gpsLocDatePrevCy(idFix);
                           timeAdj = gpsLocDatePrevCy(idFix);
                           [measStructAux, ~] = create_one_meas_float_time_bis( ...
                              g_MC_Surface, ...
                              time, ...
                              timeAdj, ...
                              g_JULD_STATUS_4);
                           if (~isempty(measStructAux))
                              measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
                              measStructAux.paramList = [paramGpsTimeToFix paramGpsNbSat];
                              measStructAux.paramData = [gpsLocTimeToFixPrevCy(idFix) gpsLocNbSatPrevCy(idFix)];
                              o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStructAux];
                           end
                        end
                     end
                  end
                  
                  % update N_CYCLE
                  if (newOne)
                     idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
                     
                     o_tabTrajNCycle(idCyNCycle).juldFirstLocation = min(gpsLocDatePrevCy);
                     o_tabTrajNCycle(idCyNCycle).juldFirstLocationStatus = g_JULD_STATUS_4;
                     
                     o_tabTrajNCycle(idCyNCycle).juldLastLocation = max(gpsLocDatePrevCy);
                     o_tabTrajNCycle(idCyNCycle).juldLastLocationStatus = g_JULD_STATUS_4;
                  end
               else
                  
                  % store GPS fixes in N_MEAS
                  for idFix = 1:length(gpsLocDatePrevCy)
                     measStruct = create_one_meas_surface(g_MC_Surface, ...
                        gpsLocDatePrevCy(idFix), ...
                        gpsLocLonPrevCy(idFix), ...
                        gpsLocLatPrevCy(idFix), ...
                        'G', ...
                        ' ', ...
                        num2str(gpsLocQcPrevCy(idFix)), 1);
                     o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                     
                     if ((gpsLocNbSatPrevCy(idFix) ~= -1) && (gpsLocTimeToFixPrevCy(idFix) ~= -1))
                        
                        time = gpsLocDatePrevCy(idFix);
                        timeAdj = gpsLocDatePrevCy(idFix);
                        [measStructAux, ~] = create_one_meas_float_time_bis( ...
                           g_MC_Surface, ...
                           time, ...
                           timeAdj, ...
                           g_JULD_STATUS_4);
                        if (~isempty(measStructAux))
                           measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
                           measStructAux.paramList = [paramGpsTimeToFix paramGpsNbSat];
                           measStructAux.paramData = [gpsLocTimeToFixPrevCy(idFix) gpsLocNbSatPrevCy(idFix)];
                           o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStructAux];
                        end
                     end
                  end
                  
                  % update N_CYCLE
                  idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
                  
                  o_tabTrajNCycle(idCyNCycle).juldFirstLocation = min(gpsLocDatePrevCy);
                  o_tabTrajNCycle(idCyNCycle).juldFirstLocationStatus = g_JULD_STATUS_4;
                  
                  o_tabTrajNCycle(idCyNCycle).juldLastLocation = max(gpsLocDatePrevCy);
                  o_tabTrajNCycle(idCyNCycle).juldLastLocationStatus = g_JULD_STATUS_4;
               end
            else
               
               % store GPS fixes in N_MEAS
               for idFix = 1:length(gpsLocDatePrevCy)
                  measStruct = create_one_meas_surface(g_MC_Surface, ...
                     gpsLocDatePrevCy(idFix), ...
                     gpsLocLonPrevCy(idFix), ...
                     gpsLocLatPrevCy(idFix), ...
                     'G', ...
                     ' ', ...
                     num2str(gpsLocQcPrevCy(idFix)), 1);
                  o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStruct];
                  
                  if ((gpsLocNbSatPrevCy(idFix) ~= -1) && (gpsLocTimeToFixPrevCy(idFix) ~= -1))
                     
                     time = gpsLocDatePrevCy(idFix);
                     timeAdj = gpsLocDatePrevCy(idFix);
                     [measStructAux, ~] = create_one_meas_float_time_bis( ...
                        g_MC_Surface, ...
                        time, ...
                        timeAdj, ...
                        g_JULD_STATUS_4);
                     if (~isempty(measStructAux))
                        measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
                        measStructAux.paramList = [paramGpsTimeToFix paramGpsNbSat];
                        measStructAux.paramData = [gpsLocTimeToFixPrevCy(idFix) gpsLocNbSatPrevCy(idFix)];
                        o_tabTrajNMeas(idCyNMeas).tabMeas = [o_tabTrajNMeas(idCyNMeas).tabMeas; measStructAux];
                     end
                  end
               end
               
               % update N_CYCLE
               idCyNCycle = find([o_tabTrajNCycle.cycleNumber] == max(a_cycleNum-1, 0));
               
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
               
               if ((gpsLocNbSatPrevCy(idFix) ~= -1) && (gpsLocTimeToFixPrevCy(idFix) ~= -1))
                  
                  time = gpsLocDatePrevCy(idFix);
                  timeAdj = gpsLocDatePrevCy(idFix);
                  [measStructAux, ~] = create_one_meas_float_time_bis( ...
                     g_MC_Surface, ...
                     time, ...
                     timeAdj, ...
                     g_JULD_STATUS_4);
                  if (~isempty(measStructAux))
                     measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
                     measStructAux.paramList = [paramGpsTimeToFix paramGpsNbSat];
                     measStructAux.paramData = [gpsLocTimeToFixPrevCy(idFix) gpsLocNbSatPrevCy(idFix)];
                     trajNMeasStructNew.tabMeas = [trajNMeasStructNew.tabMeas; measStructAux];
                  end
               end
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
gpsLocNbSat = gpsLocNbSat(idF);
gpsLocTimeToFix = gpsLocTimeToFix(idF);

for idFix = 1:length(gpsCyLocDate)
   measStruct = create_one_meas_surface(g_MC_Surface, ...
      gpsCyLocDate(idFix), ...
      gpsCyLocLon(idFix), ...
      gpsCyLocLat(idFix), ...
      'G', ...
      ' ', ...
      num2str(gpsCyLocQc(idFix)), 1);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if ((gpsLocNbSat(idFix) ~= -1) && (gpsLocTimeToFix(idFix) ~= -1))
      
      time = gpsCyLocDate(idFix);
      timeAdj = gpsCyLocDate(idFix);
      [measStructAux, ~] = create_one_meas_float_time_bis( ...
         g_MC_Surface, ...
         time, ...
         timeAdj, ...
         g_JULD_STATUS_4);
      if (~isempty(measStructAux))
         measStructAux.sensorNumber = 101; % so that it will be stored in TRAJ_AUX file
         measStructAux.paramList = [paramGpsTimeToFix paramGpsNbSat];
         measStructAux.paramData = [gpsLocTimeToFix(idFix) gpsLocNbSat(idFix)];
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStructAux];
      end
   end
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
   configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   if (~isempty(configMissionNumber))
      trajNCycleStruct.configMissionNumber = configMissionNumber;
   end
end

% output data
if (~isempty(trajNMeasStruct.tabMeas))
   o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
   o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStruct];
   o_tabTechNMeas = [o_tabTechNMeas; techNMeasStruct];
end

return
