% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_209( ...
%    a_cycleNum, a_deepCycle, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_cycleStartDate, ...
%    a_descentToParkStartDate, a_firstStabDate, a_firstStabPres, a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_firstGroundingDate, a_firstGroundingPres, ...
%    a_tabTech, ...
%    a_tabProfiles, ...
%    a_parkDate, a_parkTransDate, ...
%    a_parkPres, a_parkTemp, a_parkSal, ...
%    a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxyAa, a_parkDoxyAa, ...
%    a_parkPhaseDelayDoxy, a_parkTempDoxySbe, a_parkDoxySbe, ...
%    a_decoderId)
%
% INPUT PARAMETERS :
%   a_cycleNum               : current cycle number
%   a_deepCycle              : deep cycle flag
%   a_gpsData                : GPS data
%   a_iridiumMailData        : Iridium mail contents
%   a_cycleStartDate         : cycle start date
%   a_descentToParkStartDate : descent to park start date
%   a_firstStabDate          : first stabilisation date
%   a_firstStabPres          : first stabilisation pressure
%   a_descentToParkEndDate   : descent to park end date
%   a_descentToProfStartDate : descent to profile start date
%   a_descentToProfEndDate   : descent to profile end date
%   a_ascentStartDate        : ascent start date
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%   a_firstGroundingDate     : first grounding date
%   a_firstGroundingPres     : first grounding pressure
%   a_tabTech                : technical data
%   a_tabProfiles            : profiles data
%   a_parkDate               : drift meas dates
%   a_parkTransDate          : drift meas transmitted date flags
%   a_parkPres               : drift meas PRES
%   a_parkTemp               : drift meas TEMP
%   a_parkSal                : drift meas PSAL
%   a_parkC1PhaseDoxy        : drift meas C1PHASE_DOXY
%   a_parkC2PhaseDoxy        : drift meas C2PHASE_DOXY
%   a_parkTempDoxyAa         : drift meas TEMP_DOXY (Aanderaa sensor)
%   a_parkDoxyAa             : drift meas DOXY (Aanderaa sensor)
%   a_parkPhaseDelayDoxy     : drift meas PHASE_DELAY_DOXY
%   a_parkTempDoxySbe        : drift meas TEMP_DOXY2 (SBE sensor)
%   a_parkDoxySbe            : drift meas DOXY2 (SBE sensor)
%   a_decoderId              : float decoder Id
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
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_209( ...
   a_cycleNum, a_deepCycle, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleStartDate, ...
   a_descentToParkStartDate, a_firstStabDate, a_firstStabPres, a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_transStartDate, ...
   a_firstGroundingDate, a_firstGroundingPres, ...
   a_tabTech, ...
   a_tabProfiles, ...
   a_parkDate, a_parkTransDate, ...
   a_parkPres, a_parkTemp, a_parkSal, ...
   a_parkC1PhaseDoxy, a_parkC2PhaseDoxy, a_parkTempDoxyAa, a_parkDoxyAa, ...
   a_parkPhaseDelayDoxy, a_parkTempDoxySbe, a_parkDoxySbe, ...
   a_decoderId)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_DriftAtPark;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_MaxPresInDescToProf;
global g_MC_DPST;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_TST;
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
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% clock drift is supposed to be 0
floatClockDrift = 0;

% retrieve technical message data
tabTech = [];
if (~isempty(a_tabTech))
   if (size(a_tabTech, 1) > 1)
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
         g_decArgo_argosLonDef, [], [], [], [], 1);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldFirstMessage = firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
   end
   
   % GPS locations
   for idpos = 1:length(gpsCyLocDate)
      measStruct = create_one_meas_surface(g_MC_Surface, ...
         gpsCyLocDate(idpos), ...
         gpsCyLocLon(idpos), ...
         gpsCyLocLat(idpos), ...
         'G', ...
         ' ', ...
         num2str(gpsCyLocQc(idpos)), 1);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   if (~isempty(gpsCyLocDate))
      trajNCycleStruct.juldFirstLocation = gpsCyLocDate(1);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      trajNCycleStruct.juldLastLocation = gpsCyLocDate(end);
      trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
   end
   
   % Last Message Time
   if (lastMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_LMT, ...
         lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], 1);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldLastMessage = lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % FLOAT CYCLE TIMES
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % clock offset
   trajNCycleStruct.clockOffset = floatClockDrift;
   trajNCycleStruct.dataMode = 'A';
   
   % Cycle Start Time (i.e. buoyancy reduction start time for this float type)
   cycleStartDate = a_cycleStartDate;
   if (isempty(cycleStartDate))
      cycleStartDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_CycleStart, cycleStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (cycleStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldCycleStart = cycleStartDate;
      trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;
   end
   
   % Descent Start Time
   descentToParkStartDate = a_descentToParkStartDate;
   if (isempty(descentToParkStartDate))
      descentToParkStartDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_DST, descentToParkStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (descentToParkStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldDescentStart = descentToParkStartDate;
      trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
   end
   
   % First Stabilization Time
   firstStabDate = a_firstStabDate;
   if (isempty(firstStabDate))
      firstStabDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_FST, firstStabDate, g_JULD_STATUS_2, floatClockDrift);
   if (firstStabDate ~= g_decArgo_dateDef)
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_firstStabPres;
   end
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (firstStabDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldFirstStab = firstStabDate;
      trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;
   end
   
   % Park Start Time
   descentToParkEndDate = a_descentToParkEndDate;
   if (isempty(descentToParkEndDate))
      descentToParkEndDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_PST, descentToParkEndDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (descentToParkEndDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldParkStart = descentToParkEndDate;
      trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
   end
   
   % Park End Time
   descentToProfStartDate = a_descentToProfStartDate;
   if (isempty(descentToProfStartDate))
      descentToProfStartDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_PET, descentToProfStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (descentToProfStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldParkEnd = descentToProfStartDate;
      trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
   end
   
   % Deep Park Start Time
   descentToProfEndDate = a_descentToProfEndDate;
   if (isempty(descentToProfEndDate))
      descentToProfEndDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_DPST, descentToProfEndDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (descentToProfEndDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldDeepParkStart = descentToProfEndDate;
      trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;
   end
   
   % Ascent Start Time
   ascentStartDate = a_ascentStartDate;
   if (isempty(ascentStartDate))
      ascentStartDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_AST, ascentStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (ascentStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldAscentStart = ascentStartDate;
      trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
   end
   
   % Ascent End Time
   ascentEndDate = a_ascentEndDate;
   if (isempty(ascentEndDate))
      ascentEndDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_AET, ascentEndDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (ascentEndDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldAscentEnd = ascentEndDate;
      trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
   end
   
   % Transmission Start Time
   transStartDate = a_transStartDate;
   if (isempty(transStartDate))
      transStartDate = g_decArgo_dateDef;
   end
   measStruct = create_one_meas_float_time(g_MC_TST, transStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (transStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldTransmissionStart = transStartDate;
      trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_2;
   end
   
   % Transmission End Time
   measStruct = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
   trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;
   
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
      dateFillValue = profile.dateList.fillValue;
      
      for idMeas = 1:length(profDates)
         if (profDates(idMeas) ~= dateFillValue)
            measStruct = create_one_meas_float_time(measCode, profDates(idMeas), g_JULD_STATUS_2, floatClockDrift);
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
      paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
      paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
      paramTempDoxyAa = get_netcdf_param_attributes('TEMP_DOXY');
      paramDoxyAA = get_netcdf_param_attributes('DOXY');
      paramPhaseDelayDoxy = get_netcdf_param_attributes('PHASE_DELAY_DOXY');
      paramTempDoxySbe = get_netcdf_param_attributes('TEMP_DOXY2');
      paramDoxySbe = get_netcdf_param_attributes('DOXY2');

      % convert decoder default values to netCDF fill values
      a_parkPres(find(a_parkPres == g_decArgo_presDef)) = paramPres.fillValue;
      a_parkTemp(find(a_parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      a_parkSal(find(a_parkSal == g_decArgo_salDef)) = paramSal.fillValue;
      if (~isempty(a_parkC1PhaseDoxy))
         a_parkC1PhaseDoxy(find(a_parkC1PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef)) = paramC1PhaseDoxy.fillValue;
         a_parkC2PhaseDoxy(find(a_parkC2PhaseDoxy == g_decArgo_c1C2PhaseDoxyDef)) = paramC2PhaseDoxy.fillValue;
         a_parkTempDoxyAa(find(a_parkTempDoxyAa == g_decArgo_tempDoxyDef)) = paramTempDoxyAa.fillValue;
         a_parkDoxyAa(find(a_parkDoxyAa == g_decArgo_doxyDef)) = paramDoxyAA.fillValue;
      end
      if (~isempty(a_parkPhaseDelayDoxy))
         a_parkPhaseDelayDoxy(find(a_parkPhaseDelayDoxy == g_decArgo_phaseDelayDoxyDef)) = paramPhaseDelayDoxy.fillValue;
         a_parkTempDoxySbe(find(a_parkTempDoxySbe == g_decArgo_tempDoxyDef)) = paramTempDoxySbe.fillValue;
         a_parkDoxySbe(find(a_parkDoxySbe == g_decArgo_doxyDef)) = paramDoxySbe.fillValue;
      end
      
      for idMeas = 1:length(a_parkPres)
         
         if (a_parkDate(idMeas) ~= g_decArgo_dateDef)
            if (a_parkTransDate(idMeas) == 0)
               measTimeStatus = g_JULD_STATUS_1;
            else
               measTimeStatus = g_JULD_STATUS_2;
            end
            measStruct = create_one_meas_float_time(g_MC_DriftAtPark, a_parkDate(idMeas), measTimeStatus, floatClockDrift);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_DriftAtPark;
         end
         
         if (~isempty(a_parkC1PhaseDoxy) && ~isempty(a_parkPhaseDelayDoxy))
            % add parameter variables to the structure
            measStruct.paramList = [paramPres paramTemp paramSal ...
               paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxyAa paramDoxyAA ...
               paramPhaseDelayDoxy paramTempDoxySbe paramDoxySbe];
            
            % add parameter data to the structure
            measStruct.paramData = [a_parkPres(idMeas) a_parkTemp(idMeas) a_parkSal(idMeas) ...
               a_parkC1PhaseDoxy(idMeas) a_parkC2PhaseDoxy(idMeas) a_parkTempDoxyAa(idMeas) a_parkDoxyAa(idMeas) ...
               a_parkPhaseDelayDoxy(idMeas) a_parkTempDoxySbe(idMeas) a_parkDoxySbe(idMeas)];
         elseif (~isempty(a_parkC1PhaseDoxy))
            % add parameter variables to the structure
            measStruct.paramList = [paramPres paramTemp paramSal ...
               paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxyAa paramDoxyAA];
            
            % add parameter data to the structure
            measStruct.paramData = [a_parkPres(idMeas) a_parkTemp(idMeas) a_parkSal(idMeas) ...
               a_parkC1PhaseDoxy(idMeas) a_parkC2PhaseDoxy(idMeas) a_parkTempDoxyAa(idMeas) a_parkDoxyAa(idMeas)];
         elseif (~isempty(a_parkPhaseDelayDoxy))
            % add parameter variables to the structure
            measStruct.paramList = [paramPres paramTemp paramSal ...
               paramPhaseDelayDoxy paramTempDoxySbe paramDoxySbe];
            
            % add parameter data to the structure
            measStruct.paramData = [a_parkPres(idMeas) a_parkTemp(idMeas) a_parkSal(idMeas) ...
               a_parkPhaseDelayDoxy(idMeas) a_parkTempDoxySbe(idMeas) a_parkDoxySbe(idMeas)];
         else
            % add parameter variables to the structure
            measStruct.paramList = [paramPres paramTemp paramSal];
            
            % add parameter data to the structure
            measStruct.paramData = [a_parkPres(idMeas) a_parkTemp(idMeas) a_parkSal(idMeas)];
         end
               
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % RPP measurements
      if (~isempty(a_parkC1PhaseDoxy) && ~isempty(a_parkPhaseDelayDoxy))
         idForMean = find(~( ...
            (a_parkPres == paramPres.fillValue) | ...
            (a_parkTemp == paramTemp.fillValue) | ...
            (a_parkSal == paramSal.fillValue) | ...
            (a_parkC1PhaseDoxy == paramC1PhaseDoxy.fillValue) | ...
            (a_parkC2PhaseDoxy == paramC2PhaseDoxy.fillValue) | ...
            (a_parkTempDoxyAa == paramTempDoxyAa.fillValue) | ...
            (a_parkPhaseDelayDoxy == paramPhaseDelayDoxy.fillValue) | ...
            (a_parkTempDoxySbe == paramTempDoxySbe.fillValue)));
         if (~isempty(idForMean))
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_RPP;
            measStruct.paramList = [paramPres paramTemp paramSal ...
               paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxyAa paramDoxyAA ...
               paramPhaseDelayDoxy paramTempDoxySbe paramDoxySbe];
            measStruct.paramData = [ ...
               mean(a_parkPres(idForMean)) mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean)) ...
               mean(a_parkC1PhaseDoxy(idForMean)) mean(a_parkC2PhaseDoxy(idForMean)) mean(a_parkTempDoxyAa(idForMean)) mean(a_parkDoxyAa(idForMean)) ...
               mean(a_parkPhaseDelayDoxy(idForMean)) mean(a_parkTempDoxySbe(idForMean)) mean(a_parkDoxySbe(idForMean))];
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
            trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
         end
      elseif (~isempty(a_parkC1PhaseDoxy))
         idForMean = find(~( ...
            (a_parkPres == paramPres.fillValue) | ...
            (a_parkTemp == paramTemp.fillValue) | ...
            (a_parkSal == paramSal.fillValue) | ...
            (a_parkC1PhaseDoxy == paramC1PhaseDoxy.fillValue) | ...
            (a_parkC2PhaseDoxy == paramC2PhaseDoxy.fillValue) | ...
            (a_parkTempDoxyAa == paramTempDoxyAa.fillValue)));
         if (~isempty(idForMean))
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_RPP;
            measStruct.paramList = [paramPres paramTemp paramSal ...
               paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxyAa paramDoxyAA];
            measStruct.paramData = [ ...
               mean(a_parkPres(idForMean)) mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean)) ...
               mean(a_parkC1PhaseDoxy(idForMean)) mean(a_parkC2PhaseDoxy(idForMean)) mean(a_parkTempDoxyAa(idForMean)) mean(a_parkDoxyAa(idForMean))];
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
            trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
         end
      elseif (~isempty(a_parkPhaseDelayDoxy))
         idForMean = find(~( ...
            (a_parkPres == paramPres.fillValue) | ...
            (a_parkTemp == paramTemp.fillValue) | ...
            (a_parkSal == paramSal.fillValue) | ...
            (a_parkPhaseDelayDoxy == paramPhaseDelayDoxy.fillValue) | ...
            (a_parkTempDoxySbe == paramTempDoxySbe.fillValue)));
         if (~isempty(idForMean))
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_RPP;
            measStruct.paramList = [paramPres paramTemp paramSal ...
               paramPhaseDelayDoxy paramTempDoxySbe paramDoxySbe];
            measStruct.paramData = [ ...
               mean(a_parkPres(idForMean)) mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean)) ...
               mean(a_parkPhaseDelayDoxy(idForMean)) mean(a_parkTempDoxySbe(idForMean)) mean(a_parkDoxySbe(idForMean))];
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
            trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
         end
      else
         idForMean = find(~( ...
            (a_parkPres == paramPres.fillValue) | ...
            (a_parkTemp == paramTemp.fillValue) | ...
            (a_parkSal == paramSal.fillValue)));
         if (~isempty(idForMean))
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_RPP;
            measStruct.paramList = [paramPres paramTemp paramSal];
            measStruct.paramData = [ ...
               mean(a_parkPres(idForMean)) mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean))];
            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            
            trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
            trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
         end
      end

   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IN AIR MEASUREMENT
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % the unpumped part of the profile should not be duplicated in the TRAJ file
   % anymore (whatever the value of CONFIG_OptodeMeasurementsInAir_LOGICAL is)
   % see specification in "NOTE ON “NEAR SURFACE” AND “IN AIR” DATA PROCESSING IN
   % THE CORIOLIS MATLAB DECODER" (V1.0 dated 29/06/2018)
   
   %    for idProf = 1:length(a_tabProfiles)
   %       profile = a_tabProfiles(idProf);
   %       if ((profile.direction == 'A') && any(strfind(profile.vertSamplingScheme, 'unpumped')))
   %
   %          [inAirMeasProfile] = create_in_air_meas_profile(a_decoderId, profile);
   %
   %          if (~isempty(inAirMeasProfile))
   %
   %             inAirMeasDates = inAirMeasProfile.dates;
   %             dateFillValue = inAirMeasProfile.dateList.fillValue;
   %
   %             for idMeas = 1:length(inAirMeasDates)
   %                if (inAirMeasDates(idMeas) ~= dateFillValue)
   %                   measStruct = create_one_meas_float_time(g_MC_InAirSeriesOfMeas, inAirMeasDates(idMeas), g_JULD_STATUS_2, floatClockDrift);
   %                else
   %                   measStruct = get_traj_one_meas_init_struct();
   %                   measStruct.measCode = g_MC_InAirSeriesOfMeas;
   %                end
   %                measStruct.paramList = inAirMeasProfile.paramList;
   %                measStruct.paramData = inAirMeasProfile.data(idMeas, :);
   %                trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   %             end
   %          end
   %       end
   %    end
      
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
            dateFillValue = profile.dateList.fillValue;
            
            if (profDates(idDeepest) ~= dateFillValue)
               measStruct = create_one_meas_float_time(measCode, profDates(idDeepest), g_JULD_STATUS_2, floatClockDrift);
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
   
   if (~isempty(a_tabTech))
      
      % max pressure in descent to parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(12);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(15);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(16);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % max pressure in descent to profile depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(23);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(28);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech(29);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % last pumped CTD measurement
      pres = sensor_2_value_for_pressure_204_to_209_219_220(tabTech(41));
      temp = sensor_2_value_for_temp_204_to_214_217_219_220_222_to_225(tabTech(42));
      psal = tabTech(43)/1000;
      if (any([pres temp psal] ~= 0))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_LastAscPumpedCtd;
         
         paramPres = get_netcdf_param_attributes('PRES');
         paramTemp = get_netcdf_param_attributes('TEMP');
         paramSal = get_netcdf_param_attributes('PSAL');
         measStruct.paramList = [paramPres paramTemp paramSal];
         
         measStruct.paramData = [pres temp psal];
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % grounding information
      grounded = 'N';
      if (~isempty(a_firstGroundingDate))
         measStruct = create_one_meas_float_time(g_MC_Grounded, a_firstGroundingDate, g_JULD_STATUS_2, floatClockDrift);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = a_firstGroundingPres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
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
         g_decArgo_argosLonDef, [], [], [], [], 1);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldFirstMessage = firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
   end
   
   % GPS locations
   for idpos = 1:length(gpsCyLocDate)
      measStruct = create_one_meas_surface(g_MC_Surface, ...
         gpsCyLocDate(idpos), ...
         gpsCyLocLon(idpos), ...
         gpsCyLocLat(idpos), ...
         'G', ...
         ' ', ...
         num2str(gpsCyLocQc(idpos)), 1);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   if (~isempty(gpsCyLocDate))
      trajNCycleStruct.juldFirstLocation = gpsCyLocDate(1);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      trajNCycleStruct.juldLastLocation = gpsCyLocDate(end);
      trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
   end
   
   % Last Message Time
   if (lastMsgTime ~= g_decArgo_dateDef)
      measStruct = create_one_meas_surface(g_MC_LMT, ...
         lastMsgTime, ...
         g_decArgo_argosLonDef, [], [], [], [], 1);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.juldLastMessage = lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
   end
   
   trajNMeasStruct.surfOnly = 1;

   % clock offset
   trajNCycleStruct.clockOffset = floatClockDrift;
   trajNCycleStruct.dataMode = 'A';

   trajNCycleStruct.surfOnly = 1;
end

% add configuration mission number
if (a_cycleNum > 0) % we don't assign any configuration to cycle #0 data
   configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   if (~isempty(configMissionNumber))
      trajNCycleStruct.configMissionNumber = configMissionNumber;
   end
end

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return
