% ------------------------------------------------------------------------------
% Process trajectory data (store times in the TRAJ structures).
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_time_apx( ...
%    a_addLaunchData, a_floatSurfData, ...
%    a_timeData, a_presOffsetData, a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_addLaunchData  : flag to add float launch time and position
%   a_floatSurfData  : float surface data structure
%   a_timeData       : updated cycle time data structure
%   a_presOffsetData : updated pressure offset data structure
%   a_tabTrajNMeas   : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle  : N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_time_apx( ...
   a_addLaunchData, a_floatSurfData, ...
   a_timeData, a_presOffsetData, a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

% global measurement codes
global g_MC_Launch;
global g_MC_DST;
global g_MC_DescProf;
global g_MC_DET;
global g_MC_PST;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
global g_MC_PET;
global g_MC_DDET;
global g_MC_AST;
global g_MC_DownTimeEnd;
global g_MC_AST_Float;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;

% global time status
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;

% to store information on adjustments
global g_decArgo_paramTrajAdjInfo;
global g_decArgo_paramTrajAdjId;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT LAUNCH TIME AND POSITION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (a_addLaunchData == 1)
   
   % structure to store N_MEASUREMENT data
   trajNMeasStruct = get_traj_n_meas_init_struct(-1, -1);
      
   measStruct = create_one_meas_surface(g_MC_Launch, ...
      a_floatSurfData.launchDate, ...
      a_floatSurfData.launchLon, ...
      a_floatSurfData.launchLat, ...
      ' ', ' ', 0, 0);
   
   trajNMeasStruct.surfOnly = 1;
   
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CYCLE TIME
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cycleNumList = unique([a_timeData.cycleNum]);
for idC = 1:length(cycleNumList)
   cycleNum = cycleNumList(idC);
   
   % retrieve current cycle times
   idCycleStruct = find([a_timeData.cycleNum] == cycleNum);
   cycleTimeStruct = a_timeData.cycleTime(idCycleStruct);
   
   % retrieve structure to store N_MEASUREMENT data
   idTrajNMeasStruct = find([a_tabTrajNMeas.cycleNumber] == cycleNum);
   if (isempty(idTrajNMeasStruct))
      trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);
      o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
      idTrajNMeasStruct = length(o_tabTrajNMeas);
   end
   trajNMeasStruct = o_tabTrajNMeas(idTrajNMeasStruct);

   % retrieve structure to store N_CYCLE data
   idTrajNCyStruct = find([o_tabTrajNCycle.cycleNumber] == cycleNum);
   if (isempty(idTrajNCyStruct))
      trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);
      o_tabTrajNCycle = [o_tabTrajNCycle; trajNCycleStruct];
      idTrajNCyStruct = length(o_tabTrajNCycle);
   end
   trajNCycleStruct = o_tabTrajNCycle(idTrajNCyStruct);
   
   idF = find(a_presOffsetData.cycleNumAdjPres == cycleNum, 1);
   if (~isempty(idF))
      presOffset = a_presOffsetData.presOffset(idF);
      
      param = 'PRES';
      equation = 'PRES_ADJUSTED = PRES - Surface Pressure';
      coefficient = ['For cycle #' num2str(cycleNum) ': Surface Pressure = ' num2str(presOffset) ' dbar'];
      comment = 'Pressure adjusted in real time by using pressure offset at the sea surface';
      
      g_decArgo_paramTrajAdjInfo = [g_decArgo_paramTrajAdjInfo;
         g_decArgo_paramTrajAdjId 0 cycleNum ...
         {param} {equation} {coefficient} {comment} {''}];
      g_decArgo_paramTrajAdjId = g_decArgo_paramTrajAdjId + 1;
   end
   
   % determine DATA_MODE for the current cycle
   cycleDataMode = 'R';
   if (any([a_presOffsetData.cycleNumAdjPres] == cycleNum) || ...
         ~isempty(cycleTimeStruct.clockOffset))
      cycleDataMode = 'A';
   end
   trajNCycleStruct.dataMode = cycleDataMode;
   
   if (cycleDataMode == 'R')
      % this cycle is not adjusted
      idGpsLoc = find([trajNMeasStruct.tabMeas.measCode] == g_MC_Surface);
      for idLoc = 1:length(idGpsLoc)
         trajNMeasStruct.tabMeas(idGpsLoc(idLoc)).juldAdj = '';
         trajNMeasStruct.tabMeas(idGpsLoc(idLoc)).juldAdjStatus = '';
         trajNMeasStruct.tabMeas(idGpsLoc(idLoc)).juldAdjQc = '';
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store time information
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % clock offset
   if (~isempty(cycleTimeStruct.clockOffset))
      trajNCycleStruct.clockOffset = cycleTimeStruct.clockOffset;
   end
   
   % Descent Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_DST, ...
      cycleTimeStruct.descentStartTime, ...
      cycleTimeStruct.descentStartTimeAdj, ...
      cycleTimeStruct.descentStartTimeStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldDescentStart = nCycleTime;
      trajNCycleStruct.juldDescentStartStatus = cycleTimeStruct.descentStartTimeStatus;
   end
      
   % descent pressure marks
   descPresMark = cycleTimeStruct.descPresMark;
   if (~isempty(descPresMark))
      
      for idPM = 1:length(descPresMark.dates)
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            g_MC_DescProf, ...
            descPresMark.dates(idPM), ...
            descPresMark.datesAdj(idPM), ...
            descPresMark.datesStatus(idPM));
         if (isempty(measStruct))
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_DescProf;
         end
         measStruct.paramList = descPresMark.paramList;
         measStruct.paramDataMode = descPresMark.paramDataMode;
         measStruct.paramData = descPresMark.data(idPM, :);
         if (~isempty(descPresMark.dataAdj))
            measStruct.paramDataAdj = descPresMark.dataAdj(idPM, :);
         end
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end

   % Park End Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_PET, ...
      cycleTimeStruct.parkEndTime, ...
      cycleTimeStruct.parkEndTimeAdj, ...
      cycleTimeStruct.parkEndTimeStatus);
   if (~isempty(measStruct))
      % add PET meas
      if (~isempty(trajNMeasStruct.tabMeas))
         idDriftMeas = find(([trajNMeasStruct.tabMeas.measCode] == g_MC_DriftAtPark) & ...
            ([trajNMeasStruct.tabMeas.sensorNumber] < 1000));
         if (~isempty(idDriftMeas))
            measStruct.paramList = trajNMeasStruct.tabMeas(idDriftMeas).paramList;
            measStruct.paramDataMode = trajNMeasStruct.tabMeas(idDriftMeas).paramDataMode;
            measStruct.paramData = trajNMeasStruct.tabMeas(idDriftMeas).paramData;
            measStruct.paramDataAdj = trajNMeasStruct.tabMeas(idDriftMeas).paramDataAdj;
            
            % update drift meas with associated date
            trajNMeasStruct.tabMeas(idDriftMeas) = measStruct;
            trajNMeasStruct.tabMeas(idDriftMeas).measCode = g_MC_DriftAtPark;
         end
      end
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      trajNCycleStruct.juldParkEnd = nCycleTime;
      trajNCycleStruct.juldParkEndStatus = cycleTimeStruct.parkEndTimeStatus;
   end

   % Deep Descent End Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_DDET, ...
      cycleTimeStruct.deepDescentEndTime, ...
      cycleTimeStruct.deepDescentEndTimeAdj, ...
      cycleTimeStruct.deepDescentEndTimeStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldDeepDescentEnd = nCycleTime;
      trajNCycleStruct.juldDeepDescentEndStatus = cycleTimeStruct.deepDescentEndTimeStatus;
   end
   
   % Down Time End
   [measStruct, ~] = create_one_meas_float_time_bis( ...
      g_MC_DownTimeEnd, ...
      cycleTimeStruct.downTimeEnd, ...
      cycleTimeStruct.downTimeEndAdj, ...
      cycleTimeStruct.downTimeEndStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % Ascent Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_AST, ...
      cycleTimeStruct.ascentStartTime, ...
      cycleTimeStruct.ascentStartTimeAdj, ...
      cycleTimeStruct.ascentStartTimeStatus);
   if (~isempty(measStruct))
      % AST PTS measurements can be already stored (if the float provides it)
      % add AST time to this item
      idMeas = find([trajNMeasStruct.tabMeas.measCode] == g_MC_AST);
      if (isempty(idMeas))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      else
         measStruct.paramList = trajNMeasStruct.tabMeas(idMeas).paramList;
         measStruct.paramDataMode = trajNMeasStruct.tabMeas(idMeas).paramDataMode;
         measStruct.paramData = trajNMeasStruct.tabMeas(idMeas).paramData;
         measStruct.paramDataAdj = trajNMeasStruct.tabMeas(idMeas).paramDataAdj;
         trajNMeasStruct.tabMeas(idMeas) = measStruct;
      end
      
      trajNCycleStruct.juldAscentStart = nCycleTime;
      trajNCycleStruct.juldAscentStartStatus = cycleTimeStruct.ascentStartTimeStatus;
   end
   
   % Ascent Start Time from float
   [measStruct, ~] = create_one_meas_float_time_bis( ...
      g_MC_AST_Float, ...
      cycleTimeStruct.ascentStartTimeFloat, ...
      cycleTimeStruct.ascentStartTimeFloatAdj, ...
      cycleTimeStruct.ascentStartTimeFloatStatus);
   if (~isempty(measStruct))
      % duplicate AST PTS measurements stored with MC = g_MC_AST (if the float
      % provides it)
      idMeas = find([trajNMeasStruct.tabMeas.measCode] == g_MC_AST);
      if (~isempty(idMeas))
         measStruct.paramList = trajNMeasStruct.tabMeas(idMeas).paramList;
         measStruct.paramDataMode = trajNMeasStruct.tabMeas(idMeas).paramDataMode;
         measStruct.paramData = trajNMeasStruct.tabMeas(idMeas).paramData;
         measStruct.paramDataAdj = trajNMeasStruct.tabMeas(idMeas).paramDataAdj;
      end   
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % Ascent End Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_AET, ...
      cycleTimeStruct.ascentEndTime, ...
      cycleTimeStruct.ascentEndTimeAdj, ...
      cycleTimeStruct.ascentEndTimeStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldAscentEnd = nCycleTime;
      trajNCycleStruct.juldAscentEndStatus = cycleTimeStruct.ascentEndTimeStatus;
   end

   % Ascent End Time from float
   [measStruct, ~] = create_one_meas_float_time_bis( ...
      g_MC_AET_Float, ...
      cycleTimeStruct.ascentEndTimeFloat, ...
      cycleTimeStruct.ascentEndTimeFloatAdj, ...
      cycleTimeStruct.ascentEndTimeFloatStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % Transmission Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_TST, ...
      cycleTimeStruct.transStartTime, ...
      cycleTimeStruct.transStartTimeAdj, ...
      cycleTimeStruct.transStartTimeStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldTransmissionStart = nCycleTime;
      trajNCycleStruct.juldTransmissionStartStatus = cycleTimeStruct.transStartTimeStatus;
   end

   % Transmission Start Time from float
   [measStruct, ~] = create_one_meas_float_time_bis( ...
      g_MC_TST_Float, ...
      cycleTimeStruct.transStartTimeFloat, ...
      cycleTimeStruct.transStartTimeFloatAdj, ...
      cycleTimeStruct.transStartTimeFloatStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   % Transmission End Time
   [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
      g_MC_TET, ...
      cycleTimeStruct.transEndTime, ...
      cycleTimeStruct.transEndTimeAdj, ...
      cycleTimeStruct.transEndTimeStatus);
   if (~isempty(measStruct))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldTransmissionEnd = nCycleTime;
      trajNCycleStruct.juldTransmissionEndStatus = cycleTimeStruct.transEndTimeStatus;
   end
   
   % First Message Time
   if (cycleTimeStruct.firstMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_FMT, ...
         cycleTimeStruct.firstMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], ~isempty(cycleTimeStruct.clockOffset));
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
      trajNCycleStruct.juldFirstMessage = cycleTimeStruct.firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
   end
   
   % Last Message Time
   if (cycleTimeStruct.lastMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_LMT, ...
         cycleTimeStruct.lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], ~isempty(cycleTimeStruct.clockOffset));
      
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldLastMessage = cycleTimeStruct.lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % check that all expected MC are present
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % measurement codes expected to be in each cycle for these floats
   % (primary and secondary MC experienced by APF9 Apex Argos floats)
   expMcList = [ ...
      g_MC_DST ...
      g_MC_DET ...
      g_MC_PST ...
      g_MC_PET ...
      g_MC_DDET ...
      g_MC_AST ...
      g_MC_AET ...
      g_MC_TST ...
      g_MC_TET ...
      ];
   
   firstDeepCycle = 1;
   if (cycleNum >= firstDeepCycle)
      measCodeList = unique([trajNMeasStruct.tabMeas.measCode]);
      
      % add MCs so that all expected ones will be present
      mcList = setdiff(expMcList, measCodeList);
      measData = [];
      for idMc = 1:length(mcList)
         measStruct = create_one_meas_float_time(mcList(idMc), -1, g_JULD_STATUS_9, 0);
         measData = [measData; measStruct];
         
         [trajNCycleStruct] = set_status_of_n_cycle_juld(trajNCycleStruct, mcList(idMc), g_JULD_STATUS_9);
      end
      
      % store the data
      if (~isempty(measData))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store press offset for the cycle measurements
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % add press offset data to each meas
   idPOCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == cycleNum);
   if (~isempty(idPOCycleStruct))
      %       [trajNMeasStruct.tabMeas.presOffset] = deal(a_presOffsetData.presOffset(idPOCycleStruct));
      %
      %       % descent pressure marks have a 1 bar precision
      %       idF = find([trajNMeasStruct.tabMeas.measCode] == g_MC_DescProf);
      %       if (~isempty(idF))
      %          [trajNMeasStruct.tabMeas(idF).presOffset] = deal(round(a_presOffsetData.presOffset(idPOCycleStruct)/10));
      %       end
      %
      %       % standard deviation should not be adjusted
      %       idF = find([trajNMeasStruct.tabMeas.measCode] == g_MC_DriftAtParkStd);
      %       if (~isempty(idF))
      %          [trajNMeasStruct.tabMeas(idF).presOffset] = deal('');
      %       end
      
      % update data mode
      trajNCycleStruct.dataMode = 'A';

   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % store updated data
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   o_tabTrajNMeas(idTrajNMeasStruct) = trajNMeasStruct;
   o_tabTrajNCycle(idTrajNCyStruct) = trajNCycleStruct;

end

return
