% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = process_trajectory_data_2002( ...
%    a_cycleNum, a_deepCycle, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_tabTech, ...
%    a_tabProfiles, ...
%    a_parkDate, a_parkDateAdj, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
%    a_parkTempDoxy, a_parkPhaseDelayDoxy, a_parkDoxy, ...
%    a_dataHydrau)
%
% INPUT PARAMETERS :
%   a_cycleNum           : current cycle number
%   a_deepCycle          : deep cycle flag
%   a_gpsData            : GPS data
%   a_iridiumMailData    : Iridium mail contents
%   a_tabTech            : technical data
%   a_tabProfiles        : profiles data
%   a_parkDate           : drift meas dates
%   a_parkDateAdj        : drift meas adjusted dates
%   a_parkTransDate      : drift meas transmitted date flags
%   a_parkPres           : drift meas PRES
%   a_parkTemp           : drift meas TEMP
%   a_parkSal            : drift meas PSAL
%   a_parkTempDoxy       : drift meas TEMP_DOXY
%   a_parkPhaseDelayDoxy : drift meas PHASE_DELAY_DOXY
%   a_parkDoxy           : drift meas DOXY
%   a_dataHydrau         : decoded hydraulic data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : N_CYCLE trajectory data
%   o_tabTechNMeas  : N_MEASUREMENT technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = process_trajectory_data_2002( ...
   a_cycleNum, a_deepCycle, ...
   a_gpsData, a_iridiumMailData, ...
   a_tabTech, ...
   a_tabProfiles, ...
   a_parkDate, a_parkDateAdj, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
   a_parkTempDoxy, a_parkPhaseDelayDoxy, a_parkDoxy, ...
   a_dataHydrau)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];

% global measurement codes
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_PressureOffset
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DET;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_DownTimeEnd;
global g_MC_AST_Float;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_MedianValueInAscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

% global time status
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% RPP status
global g_RPP_STATUS_1;

% default values
global g_decArgo_ncDateDef;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_doxyDef;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% flag to detect a second Iridium session
global g_decArgo_ackPacket;

% cycle timings storage
global g_decArgo_timeData;

% QC flag values (char)
global g_decArgo_qcStrMissing;

% final EOL flag (float in EOL mode and cycle number set to 256 by the decoder)
global g_decArgo_finalEolMode;


ID_OFFSET = 1;

% we don't update GPS position QC for TRAJ data (it is done when processing
% profile data (to locate the profils) but in EOL mode there is no need to do it
% because we will apply RTQC to TRAJ file)

% cycle timmings of the current cycle
cycleTimeStruct = [];
if (~isempty(g_decArgo_timeData))
   idCycleStruct = find([g_decArgo_timeData.cycleNum] == a_cycleNum);
   if (~isempty(idCycleStruct))
      cycleTimeStruct = g_decArgo_timeData.cycleTime(idCycleStruct(end)); % we should use the last one (for cycle numbers > 255)
   end
end

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% clock drift known
clockDriftKnown = 0;
if (~isempty(cycleTimeStruct) && ~isempty(cycleTimeStruct.clockDrift))
   clockDriftKnown = 1;
end

% retrieve technical message data
tabTech = [];
if (~isempty(a_tabTech))
   if ((g_decArgo_finalEolMode == 0) && (size(a_tabTech, 1) > 1))
      fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         size(a_tabTech, 1));
   end
   tabTech = a_tabTech(end, :);
end

if (a_deepCycle == 1)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % POSITIONING SYSTEM AND TRANSMISSION SYSTEM TIMES AND LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   [firstMsgTime, lastMsgTime] = ...
      compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, a_cycleNum);
   
   % First Message Time
   if (firstMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_FMT, ...
         firstMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldFirstMessage = firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % GPS LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   surfaceLocData = [];
   
   % unpack GPS data
   gpsLocCycleNum = a_gpsData{1};
   gpsLocDate = a_gpsData{4};
   gpsLocLon = a_gpsData{5};
   gpsLocLat = a_gpsData{6};
   gpsLocQc = a_gpsData{7};
   
   % GPS data for the current cycle
   idF = find(gpsLocCycleNum == a_cycleNum);
   gpsCyLocDate = gpsLocDate(idF);
   gpsCyLocLon = gpsLocLon(idF);
   gpsCyLocLat = gpsLocLat(idF);
   gpsCyLocQc = gpsLocQc(idF);

   for idpos = 1:length(gpsCyLocDate)
      measStruct = create_one_meas_surface(g_MC_Surface, ...
         gpsCyLocDate(idpos), ...
         gpsCyLocLon(idpos), ...
         gpsCyLocLat(idpos), ...
         'G', ...
         ' ', ...
         num2str(gpsCyLocQc(idpos)), ...
         clockDriftKnown);
      measStruct.juldStatus = g_JULD_STATUS_2;
      if (clockDriftKnown)
         measStruct.juld = measStruct.juld + (cycleTimeStruct.gpsTime-cycleTimeStruct.gpsTimeAdj);
         measStruct.juldAdjStatus = g_JULD_STATUS_2;
      end
      
      surfaceLocData = [surfaceLocData; measStruct];
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   if (~isempty(a_iridiumMailData))
      idFixForCycle = find([a_iridiumMailData.cycleNumber] == a_cycleNum);
      for idFix = idFixForCycle
         if (a_iridiumMailData(idFix).cepRadius ~= 0)
            measStruct = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
               a_iridiumMailData(idFix).timeOfSessionJuld, ...
               a_iridiumMailData(idFix).unitLocationLon, ...
               a_iridiumMailData(idFix).unitLocationLat, ...
               'I', ...
               0, ... % no need to set a Qc, it will be set during RTQC
               a_iridiumMailData(idFix).cepRadius*1000, ...
               a_iridiumMailData(idFix).cepRadius*1000, ...
               '', ...
               ' ', ...
               clockDriftKnown);
            surfaceLocData = [surfaceLocData; measStruct];
         end
      end
   end
   
   if (~isempty(surfaceLocData))
      % sort the surface locations by date
      if (clockDriftKnown)
         surfaceLocDates = [surfaceLocData.juldAdj];
      else
         surfaceLocDates = [surfaceLocData.juld];
      end
      [surfaceLocDates, idSort] = sort(surfaceLocDates);
      surfaceLocData = surfaceLocData(idSort);
      
      % store the data
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; surfaceLocData];
      
      trajNCycleStruct.juldFirstLocation = surfaceLocDates(1);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      trajNCycleStruct.juldLastLocation = surfaceLocDates(end);
      trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
      
      surfaceLocData = [];
   end
   
   % Last Message Time
   if (lastMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_LMT, ...
         lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldLastMessage = lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % FLOAT CYCLE TIMES
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % clock offset
   if (clockDriftKnown)
      trajNCycleStruct.clockOffset = cycleTimeStruct.clockDrift;
      trajNCycleStruct.dataMode = 'A';
   else
      trajNCycleStruct.dataMode = 'R';
   end
   
   % Cycle Start Time (i.e. buoyancy reduction start time for this float type)
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.cycleStartTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_CycleStart, ...
         cycleTimeStruct.cycleStartTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldCycleStart = nCycleTime;
         trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Descent Start Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.descentToParkStartTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_DST, ...
         cycleTimeStruct.descentToParkStartTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldDescentStart = nCycleTime;
         trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % First Stabilization Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.firstStabilizationTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_FST, ...
         cycleTimeStruct.firstStabilizationTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(10);
         measStruct.paramList = paramPres;
         measStruct.paramData = cycleTimeStruct.firstStabilizationPres;
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldFirstStab = nCycleTime;
         trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;
      end
   end
   
   % Park Start Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.descentToParkEndTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_PST, ...
         cycleTimeStruct.descentToParkEndTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldParkStart = nCycleTime;
         trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Park End Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.descentToProfStartTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_PET, ...
         cycleTimeStruct.descentToProfStartTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldParkEnd = nCycleTime;
         trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
      end
   end
   
   % Deep Park Start Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.descentToProfEndTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_DPST, ...
         cycleTimeStruct.descentToProfEndTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldDeepParkStart = nCycleTime;
         trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Ascent Start Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.ascentStartTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_AST, ...
         cycleTimeStruct.ascentStartTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentStart = nCycleTime;
         trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
      end
   end
   
   % Ascent End Time
   if (~isempty(cycleTimeStruct))
      timeAdj = g_decArgo_dateDef;
      if (~isempty(cycleTimeStruct.clockDrift))
         timeAdj = cycleTimeStruct.ascentEndTimeAdj;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
         g_MC_AET, ...
         cycleTimeStruct.ascentEndTime, ...
         timeAdj, ...
         g_JULD_STATUS_2);
      if (~isempty(measStruct))
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.juldAscentEnd = nCycleTime;
         trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
      end
   end
   
   % Transmission Start Time
   measStruct = create_one_meas_float_time(g_MC_TST, -1, g_JULD_STATUS_9, cycleTimeStruct.clockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldTransmissionStart = g_decArgo_ncDateDef;
   trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_9;
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROFILE DATED BINS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   for idProf = 1:length(a_tabProfiles)
      profile = a_tabProfiles(idProf);
      if (profile.direction == 'A')
         measCode = g_MC_AscProf;
      else
         measCode = g_MC_DescProf;
      end
      
      profDates = profile.dates;
      profDatesAdj = profile.datesAdj;
      dateFillValue = profile.dateList.fillValue;
      
      for idMeas = 1:length(profDates)
         if (profDates(idMeas) ~= dateFillValue)
            timeAdj = g_decArgo_dateDef;
            if (~isempty(cycleTimeStruct.clockDrift))
               timeAdj = profDatesAdj(idMeas);
            end
            [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
               measCode, ...
               profDates(idMeas), ...
               timeAdj, ...
               g_JULD_STATUS_2);
            measStruct.paramList = profile.paramList;
            measStruct.paramData = profile.data(idMeas, :);
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MEASUREMENTS SAMPLED DURING THE DRIFT AT PARKING DEPTH
   % AND
   % REPRESENTATIVE PARKING MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   if (~isempty(a_parkPres))
      
      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
      paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY');
      paramDoxy = get_netcdf_param_attributes('DOXY');
      
      % convert decoder default values to netCDF fill values
      a_parkPres(find(a_parkPres == g_decArgo_presDef)) = paramPres.fillValue;
      a_parkTemp(find(a_parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      a_parkSal(find(a_parkSal == g_decArgo_salDef)) = paramSal.fillValue;
      a_parkTempDoxy(find(a_parkTempDoxy == g_decArgo_tempDoxyDef)) = paramTempDoxy.fillValue;
      a_parkPhaseDelayDoxy(find(a_parkPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
      a_parkDoxy(find(a_parkDoxy == g_decArgo_doxyDef)) = paramDoxy.fillValue;
      
      for idMeas = 1:length(a_parkPres)
         
         if (a_parkDate(idMeas) ~= g_decArgo_dateDef)
            timeAdj = g_decArgo_dateDef;
            if (~isempty(cycleTimeStruct.clockDrift))
               timeAdj = a_parkDateAdj(idMeas);
            end
            if (a_parkTransDate(idMeas) == 0)
               measTimeStatus = g_JULD_STATUS_1;
            else
               measTimeStatus = g_JULD_STATUS_2;
            end
            [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
               g_MC_DriftAtPark, ...
               a_parkDate(idMeas), ...
               timeAdj, ...
               measTimeStatus);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_DriftAtPark;
         end
         
         % add parameter variables to the structure
         measStruct.paramList = [paramPres paramTemp paramSal ...
            paramTempDoxy paramPhaseDelayDoxy paramDoxy];
         
         % add parameter data to the structure
         measStruct.paramData = [a_parkPres(idMeas) a_parkTemp(idMeas) a_parkSal(idMeas) ...
            a_parkTempDoxy(idMeas) a_parkPhaseDelayDoxy(idMeas) a_parkDoxy(idMeas)];
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % RPP measurements
      idForMean = find(~((a_parkPres == paramPres.fillValue) | ...
         (a_parkTemp == paramTemp.fillValue) | ...
         (a_parkSal == paramSal.fillValue) | ...
         (a_parkTempDoxy == paramTempDoxy.fillValue) | ...
         (a_parkPhaseDelayDoxy == paramPhaseDelayDoxy.fillValue) | ...
         (a_parkDoxy == paramDoxy.fillValue)));
      if (~isempty(idForMean))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_RPP;
         measStruct.paramList = [paramPres paramTemp paramSal ...
            paramTempDoxy paramPhaseDelayDoxy paramDoxy];
         measStruct.paramData = [mean(a_parkPres(idForMean)) ...
            mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean)) ...
            mean(a_parkTempDoxy(idForMean)) mean(a_parkPhaseDelayDoxy(idForMean)) mean(a_parkDoxy(idForMean))];
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % HYDRAULIC ACTIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   tabDate = [];
   tabDateAdj = [];
   tabPres = [];
   tabDur = [];
   tabType = [];
   if (~isempty(a_dataHydrau) && (cycleTimeStruct.cycleStartTime ~= g_decArgo_dateDef))
      
      for idH = 1:size(a_dataHydrau, 1)
         data = a_dataHydrau(idH, :);
         tabDate = [tabDate; data(4)/24 + cycleTimeStruct.cycleStartTime];
         if (~isempty(cycleTimeStruct.clockDrift))
            clockOffset = get_nva_clock_offset(tabDate(end), g_decArgo_cycleNum, [], [], []);
            % round clock offset to 6 minutes
            clockOffset = round(clockOffset*1440/6)*6/1440;
            tabDateAdj = [tabDateAdj; tabDate(end) - clockOffset];
         else
            tabDateAdj = [tabDateAdj; g_decArgo_dateDef];
         end
         tabPres = [tabPres; data(3)*10];
         if (data(5) == hex2dec('ffff'))
            % valve action
            tabDur = [tabDur; data(6)/10];
            tabType = [tabType; 0];
         else
            % pump action
            tabDur = [tabDur; data(5)*10];
            tabType = [tabType; 1];
         end
      end
      
      if (~isempty(tabDate))
         % sort the actions in chronological order
         [tabDate, idSorted] = sort(tabDate);
         tabDateAdj = tabDateAdj(idSorted);
         tabPres = tabPres(idSorted);
         tabDur = tabDur(idSorted);
         tabType = tabType(idSorted);
         
         if ~((length(unique(tabPres)) == 1) && (unique(tabPres) == 0) && (cycleTimeStruct.descentToParkEndTimeAdj == g_decArgo_dateDef))
            
            % nominal case
            tabRefDates = [ ...
               cycleTimeStruct.cycleStartTimeAdj cycleTimeStruct.descentToParkEndTimeAdj; ...
               cycleTimeStruct.descentToParkEndTimeAdj cycleTimeStruct.descentToProfStartTimeAdj; ...
               cycleTimeStruct.descentToProfStartTimeAdj cycleTimeStruct.descentToProfEndTimeAdj; ...
               cycleTimeStruct.descentToProfEndTimeAdj cycleTimeStruct.ascentStartTimeAdj; ...
               cycleTimeStruct.ascentStartTimeAdj cycleTimeStruct.gpsTimeAdj];
            
            tabMc = [ ...
               g_MC_SpyInDescToPark;...
               g_MC_SpyAtPark;...
               g_MC_SpyInDescToProf;...
               g_MC_SpyAtProf;...
               g_MC_SpyInAscProf];
            
            % structure to store N_MEASUREMENT technical data
            o_tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);
            
            for idS = 1:length(tabMc)
               if ((tabRefDates(idS, 1) ~= g_decArgo_dateDef) && (tabRefDates(idS, 2) ~= g_decArgo_dateDef))
                  idF = find((tabDate >= tabRefDates(idS, 1)) & (tabDate < tabRefDates(idS, 2)));
                  for idP = 1:length(idF)
                     
                     [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
                        tabMc(idS), ...
                        tabDate(idF(idP)), ...
                        tabDateAdj(idF(idP)), ...
                        g_JULD_STATUS_2);
                     paramPres = get_netcdf_param_attributes('PRES');
                     paramPres.resolution = single(1);
                     measStruct.paramList = paramPres;
                     measStruct.paramData = tabPres(idF(idP));
                     
                     trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
                     
                     [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
                        tabMc(idS), ...
                        tabDate(idF(idP)), ...
                        tabDateAdj(idF(idP)), ...
                        g_JULD_STATUS_2);
                     if (tabType(idF(idP)) == 0)
                        param = get_netcdf_param_attributes('VALVE_ACTION_DURATION');
                        param.resolution = single(0.1);
                     else
                        param = get_netcdf_param_attributes('PUMP_ACTION_DURATION');
                        param.resolution = single(10);
                     end
                     measStruct.paramList = param;
                     measStruct.paramData = tabDur(idF(idP));
                     
                     o_tabTechNMeas.tabMeas = [o_tabTechNMeas.tabMeas; measStruct];
                  end
               end
            end
            if (isempty(o_tabTechNMeas.tabMeas))
               o_tabTechNMeas = [];
            end
         else
            
            % structure to store N_MEASUREMENT technical data
            o_tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);
            
            % the float didn't succeed to dive (ex: 6903181)
            for idP = 1:length(tabDate)
               
               [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
                  g_MC_SpyInDescToPark, ...
                  tabDate(idP), ...
                  tabDateAdj(idP), ...
                  g_JULD_STATUS_2);
               paramPres = get_netcdf_param_attributes('PRES');
               paramPres.resolution = single(1);
               measStruct.paramList = paramPres;
               measStruct.paramData = tabPres(idP);
               
               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
               
               [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
                  g_MC_SpyInDescToPark, ...
                  tabDate(idP), ...
                  tabDateAdj(idP), ...
                  g_JULD_STATUS_2);
               if (tabType(idP) == 0)
                  param = get_netcdf_param_attributes('VALVE_ACTION_DURATION');
                  param.resolution = single(0.1);
               else
                  param = get_netcdf_param_attributes('PUMP_ACTION_DURATION');
                  param.resolution = single(10);
               end
               measStruct.paramList = param;
               measStruct.paramData = tabDur(idP);
               
               o_tabTechNMeas.tabMeas = [o_tabTechNMeas.tabMeas; measStruct];
            end
         end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MISCELLANEOUS MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % deepest bin of the descending and ascending profiles
   tabDescDeepestBin = [];
   tabDescDeepestBinPres = [];
   tabAscDeepestBin = [];
   tabAscDeepestBinPres = [];
   for idProf = 1:length(a_tabProfiles)
      profile = a_tabProfiles(idProf);
      if (profile.direction == 'A')
         measCode = g_MC_AscProfDeepestBin;
      else
         measCode = g_MC_DescProfDeepestBin;
      end
      
      idPres = 1;
      while ~((idPres > length(profile.paramList)) || ...
            (strcmp(profile.paramList(idPres).name, 'PRES') == 1))
         idPres = idPres + 1;
      end
      
      if (idPres <= length(profile.paramList))
         
         profPresData = profile.data(:, idPres);
         presFillValue = profile.paramList(idPres).fillValue;
         
         idNotDef = find(profPresData ~= presFillValue);
         if (~isempty(idNotDef))
            
            if (profile.direction == 'A')
               idDeepest = idNotDef(1);
            else
               idDeepest = idNotDef(end);
            end
            
            profDates = profile.dates;
            profDatesAdj = profile.datesAdj;
            dateFillValue = profile.dateList.fillValue;
            
            if (profDates(idDeepest) ~= dateFillValue)
               timeAdj = g_decArgo_dateDef;
               if (~isempty(cycleTimeStruct.clockDrift))
                  timeAdj = profDatesAdj(idDeepest);
               end
               [measStruct, nCycleTime] = create_one_meas_float_time_bis( ...
                  measCode, ...
                  profDates(idDeepest), ...
                  timeAdj, ...
                  g_JULD_STATUS_2);
            else
               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = measCode;
            end
            
            % add parameter variables to the structure
            measStruct.paramList = profile.paramList;
            
            % add parameter data to the structure
            measStruct.paramData = profile.data(idDeepest, :);
            
            if (profile.direction == 'A')
               tabAscDeepestBin = [tabAscDeepestBin; measStruct];
               tabAscDeepestBinPres = [tabAscDeepestBinPres; profile.data(idDeepest, idPres)];
            else
               tabDescDeepestBin = [tabDescDeepestBin; measStruct];
               tabDescDeepestBinPres = [tabDescDeepestBinPres; profile.data(idDeepest, idPres)];
            end
         end
      end
   end
   
   if (~isempty(tabDescDeepestBin))
      [~, idMax] = max(tabDescDeepestBinPres);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabDescDeepestBin(idMax)];
   end
   
   if (~isempty(tabAscDeepestBin))
      [~, idMax] = max(tabAscDeepestBinPres);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabAscDeepestBin(idMax)];
   end
   
   % miscellaneous measurements from technical message
   
   if (~isempty(tabTech))
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(16+ID_OFFSET)*10;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(17+ID_OFFSET)*10;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % max pressure in descent to profile depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(18+ID_OFFSET)*10;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % grounding information
      if (tabTech(29+ID_OFFSET) == 0)
         grounded = 'N';
      else
         grounded = 'Y';
      end
      trajNCycleStruct.grounded = grounded;
      
   end
   
else
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % POSITIONING SYSTEM AND TRANSMISSION SYSTEM TIMES AND LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   [firstMsgTime, lastMsgTime] = ...
      compute_first_last_msg_time_from_iridium_mail(a_iridiumMailData, a_cycleNum);
   
   % First Message Time
   if (firstMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_FMT, ...
         firstMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldFirstMessage = firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % GPS LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   surfaceLocData = [];
   
   % unpack GPS data
   gpsLocCycleNum = a_gpsData{1};
   gpsLocDate = a_gpsData{4};
   gpsLocLon = a_gpsData{5};
   gpsLocLat = a_gpsData{6};
   gpsLocQc = a_gpsData{7};
   
   % GPS data for the current cycle
   idF = find(gpsLocCycleNum == a_cycleNum);
   gpsCyLocDate = gpsLocDate(idF);
   gpsCyLocLon = gpsLocLon(idF);
   gpsCyLocLat = gpsLocLat(idF);
   gpsCyLocQc = gpsLocQc(idF);

   cycleTimeStructBis = [];
   if (~isempty(g_decArgo_timeData))
      idCycleStructBis = find([g_decArgo_timeData.cycleNum] == a_cycleNum);
      if (~isempty(idCycleStructBis))
         cycleTimeStructBis = g_decArgo_timeData.cycleTime(idCycleStructBis);
      end
   end
   for idpos = 1:length(gpsCyLocDate)
      measStruct = create_one_meas_surface(g_MC_Surface, ...
         gpsCyLocDate(idpos), ...
         gpsCyLocLon(idpos), ...
         gpsCyLocLat(idpos), ...
         'G', ...
         ' ', ...
         num2str(gpsCyLocQc(idpos)), 1);
      idF = find([cycleTimeStructBis.gpsTimeAdj] == gpsCyLocDate(idpos));
      if (length(idF) > 1)
         [~, idMin] = min(abs(idpos - idF));
         idF = idF(idMin);
      end
      measStruct.juldStatus = g_JULD_STATUS_2;
      if (~isempty(cycleTimeStructBis(idF).clockDrift))
         measStruct.juld = measStruct.juld + (cycleTimeStructBis(idF).gpsTime-cycleTimeStructBis(idF).gpsTimeAdj);
         measStruct.juldAdjStatus = g_JULD_STATUS_2;
      else
         measStruct.juldAdj = '';
         measStruct.juldAdjStatus = '';
         measStruct.juldAdjQc = '';
      end
      
      surfaceLocData = [surfaceLocData; measStruct];
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   if (~isempty(a_iridiumMailData))
      idFixForCycle = find([a_iridiumMailData.cycleNumber] == a_cycleNum);
      for idFix = idFixForCycle
         if (a_iridiumMailData(idFix).cepRadius ~= 0)
            measStruct = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
               a_iridiumMailData(idFix).timeOfSessionJuld, ...
               a_iridiumMailData(idFix).unitLocationLon, ...
               a_iridiumMailData(idFix).unitLocationLat, ...
               'I', ...
               0, ... % no need to set a Qc, it will be set during RTQC
               a_iridiumMailData(idFix).cepRadius*1000, ...
               a_iridiumMailData(idFix).cepRadius*1000, ...
               '', ...
               ' ', ...
               clockDriftKnown);
            surfaceLocData = [surfaceLocData; measStruct];
         end
      end
   end
   
   if (~isempty(surfaceLocData))
      % sort the surface locations by date
      if (~isempty(cycleTimeStruct.clockDrift))
         surfaceLocDates = [surfaceLocData.juldAdj];
      else
         surfaceLocDates = [surfaceLocData.juld];
      end
      [surfaceLocDates, idSort] = sort(surfaceLocDates);
      surfaceLocData = surfaceLocData(idSort);
      
      % store the data
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; surfaceLocData];
      
      trajNCycleStruct.juldFirstLocation = surfaceLocDates(1);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      trajNCycleStruct.juldLastLocation = surfaceLocDates(end);
      trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
      
      surfaceLocData = [];
   end
   
   % Last Message Time
   if (lastMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_LMT, ...
         lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], 1);
      if (isempty(cycleTimeStruct.clockDrift))
         measStruct.juldAdj = '';
         measStruct.juldAdjStatus = '';
         measStruct.juldAdjQc = '';
      end
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldLastMessage = lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
   end
   
   %    if (g_decArgo_ackPacket == 1)
   trajNMeasStruct.surfOnly = 1;
   %    end
   
   % clock offset
   if (~isempty(cycleTimeStruct) && ~isempty(cycleTimeStruct.clockDrift))
      trajNCycleStruct.clockOffset = cycleTimeStruct.clockDrift;
      trajNCycleStruct.dataMode = 'A';
   else
      trajNCycleStruct.dataMode = 'R';
   end
   
   %    if (g_decArgo_ackPacket == 1)
   trajNCycleStruct.surfOnly = 1;
   %    end
end

% Transmission End Time
measStruct = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, cycleTimeStruct.clockDrift);
trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;

% add configuration mission number
if (a_cycleNum > 0) % we don't assign any configuration to cycle #0 data
   configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   if (~isempty(configMissionNumber))
      trajNCycleStruct.configMissionNumber = configMissionNumber;
   else
      % we don't know what is the configuration number of this cycle
      % => we keep the previous one
      cyNum = a_cycleNum - 1;
      while (cyNum >= 0)
         configMissionNumber = get_config_mission_number_ir_sbd(cyNum);
         if (~isempty(configMissionNumber))
            trajNCycleStruct.configMissionNumber = configMissionNumber;
            break
         end
         cyNum = cyNum - 1;
      end
   end
end

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return
