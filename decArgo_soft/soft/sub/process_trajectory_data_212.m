% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = process_trajectory_data_212( ...
%    a_cycleNum, a_deepCycle, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_cycleStartDate, ...
%    a_descentToParkStartDate, a_firstStabDate, a_firstStabPres, a_descentToParkEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_firstGroundingDate, a_firstGroundingPres, ...
%    a_secondGroundingDate, a_secondGroundingPres, ...
%    a_tabTech1, a_tabTech2, ...
%    a_tabProfiles, ...
%    a_parkDate, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
%    a_nearSurfDate, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
%    a_inAirDate, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal, ...
%    a_evAct, a_pumpAct, a_iceDetected, a_decoderId)
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
%   a_secondGroundingDate    : second grounding date
%   a_secondGroundingPres    : second grounding pressure
%   a_tabTech1               : decoded data of technical msg #1
%   a_tabTech2               : decoded data of technical msg #2
%   a_tabProfiles            : profiles data
%   a_parkDate               : drift meas dates
%   a_parkTransDate          : drift meas transmitted date flags
%   a_parkPres               : drift meas PRES
%   a_parkTemp               : drift meas TEMP
%   a_parkSal                : drift meas PSAL
%   a_nearSurfDate           : "near surface" profile dates
%   a_nearSurfTransDate      : "near surface" profile transmitted date flags
%   a_nearSurfPres           : "near surface" profile PRES
%   a_nearSurfTemp           : "near surface" profile TEMP
%   a_nearSurfSal            : "near surface" profile PSAL
%   a_inAirDate              : "in air" profile dates
%   a_inAirTransDate         : "in air" profile transmitted date flags
%   a_inAirPres              : "in air" profile PRES
%   a_inAirTemp              : "in air" profile TEMP
%   a_inAirSal               : "in air" profile PSAL
%   a_evAct                  : decoded hydraulic (EV) data
%   a_pumpAct                : decoded hydraulic (pump) data
%   a_iceDetected            : ice detected flag
%   a_decoderId              : float decoder Id
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
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = process_trajectory_data_212( ...
   a_cycleNum, a_deepCycle, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleStartDate, ...
   a_descentToParkStartDate, a_firstStabDate, a_firstStabPres, a_descentToParkEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_transStartDate, ...
   a_firstGroundingDate, a_firstGroundingPres, ...
   a_secondGroundingDate, a_secondGroundingPres, ...
   a_tabTech1, a_tabTech2, ...
   a_tabProfiles, ...
   a_parkDate, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
   a_nearSurfDate, a_nearSurfTransDate, a_nearSurfPres, a_nearSurfTemp, a_nearSurfSal, ...
   a_inAirDate, a_inAirTransDate, a_inAirPres, a_inAirTemp, a_inAirSal, ...
   a_evAct, a_pumpAct, a_iceDetected, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_TST;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;
global g_MC_InAirSeriesOfMeas;

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

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


ID_OFFSET = 1;

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

% retrieve technical message #1 data
tabTech1 = [];
if (~isempty(a_tabTech1))
   idF1 = find(a_tabTech1(:, 1) == 0);
   if (length(idF1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #1 in the buffer => using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(idF1));
   end
   tabTech1 = a_tabTech1(idF1(end), :);
end

% retrieve technical message #2 data
tabTech2 = [];
if (~isempty(a_tabTech2))
   idF2 = find(a_tabTech2(:, 1) == 4);
   if (length(idF2) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #2 in the buffer => using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(idF2));
   end
   tabTech2 = a_tabTech2(idF2(end), :);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IN AIR MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tabMeasStructInAir = [];
if (~isempty(a_inAirDate))
   
   % create the parameters
   paramPres = get_netcdf_param_attributes('PRES');
   paramTemp = get_netcdf_param_attributes('TEMP');
   paramSal = get_netcdf_param_attributes('PSAL');
   
   % convert decoder default values to netCDF fill values
   a_inAirPres(find(a_inAirPres == g_decArgo_presDef)) = paramPres.fillValue;
   a_inAirTemp(find(a_inAirTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
   a_inAirSal(find(a_inAirSal == g_decArgo_salDef)) = paramSal.fillValue;
   
   for idMeas = 1:length(a_inAirPres)
      
      if (a_inAirDate(idMeas) ~= g_decArgo_dateDef)
         if (a_inAirTransDate(idMeas) == 0)
            measTimeStatus = g_JULD_STATUS_1;
         else
            measTimeStatus = g_JULD_STATUS_2;
         end
         measStruct = create_one_meas_float_time(g_MC_InAirSeriesOfMeas, a_inAirDate(idMeas), measTimeStatus, floatClockDrift);
      else
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_InAirSeriesOfMeas;
      end
      
      % add parameter variables to the structure
      measStruct.paramList = [paramPres paramTemp paramSal];
      
      % add parameter data to the structure
      measStruct.paramData = [a_inAirPres(idMeas) a_inAirTemp(idMeas) a_inAirSal(idMeas)];
      
      tabMeasStructInAir = [tabMeasStructInAir; measStruct];
   end
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
      paramPres.resolution = single(1);
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
      
      % convert decoder default values to netCDF fill values
      a_parkPres(find(a_parkPres == g_decArgo_presDef)) = paramPres.fillValue;
      a_parkTemp(find(a_parkTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      a_parkSal(find(a_parkSal == g_decArgo_salDef)) = paramSal.fillValue;
      
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
         
         % add parameter variables to the structure
         measStruct.paramList = [paramPres paramTemp paramSal];
         
         % add parameter data to the structure
         measStruct.paramData = [a_parkPres(idMeas) a_parkTemp(idMeas) a_parkSal(idMeas)];
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      
      % RPP measurements
      idForMean = find(~((a_parkPres == paramPres.fillValue) | ...
         (a_parkTemp == paramTemp.fillValue) | ...
         (a_parkSal == paramSal.fillValue)));
      if (~isempty(idForMean))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_RPP;
         measStruct.paramList = [paramPres paramTemp paramSal];
         measStruct.paramData = [mean(a_parkPres(idForMean)) ...
            mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean))];
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IN AIR MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   if (~isempty(a_nearSurfDate))
      
      % create the parameters
      paramPres = get_netcdf_param_attributes('PRES');
      paramTemp = get_netcdf_param_attributes('TEMP');
      paramSal = get_netcdf_param_attributes('PSAL');
      
      % convert decoder default values to netCDF fill values
      a_nearSurfPres(find(a_nearSurfPres == g_decArgo_presDef)) = paramPres.fillValue;
      a_nearSurfTemp(find(a_nearSurfTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
      a_nearSurfSal(find(a_nearSurfSal == g_decArgo_salDef)) = paramSal.fillValue;
      
      for idMeas = 1:length(a_nearSurfPres)
         
         if (a_nearSurfDate(idMeas) ~= g_decArgo_dateDef)
            if (a_nearSurfTransDate(idMeas) == 0)
               measTimeStatus = g_JULD_STATUS_1;
            else
               measTimeStatus = g_JULD_STATUS_2;
            end
            measStruct = create_one_meas_float_time(g_MC_InAirSeriesOfMeas, a_nearSurfDate(idMeas), measTimeStatus, floatClockDrift);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_InAirSeriesOfMeas;
         end
         
         % add parameter variables to the structure
         measStruct.paramList = [paramPres paramTemp paramSal];
         
         % add parameter data to the structure
         measStruct.paramData = [a_nearSurfPres(idMeas) a_nearSurfTemp(idMeas) a_nearSurfSal(idMeas)];
         
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end
   
   if (~isempty(tabMeasStructInAir))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabMeasStructInAir];
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % HYDRAULIC ACTIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   tabDate = [];
   tabPres = [];
   tabDur = [];
   tabType = [];
   if (~isempty(a_cycleStartDate))
      
      for idP = 1:size(a_evAct, 1)
         tabDate = [tabDate; a_evAct(idP, 3) + g_decArgo_julD2FloatDayOffset];
         tabPres = [tabPres; a_evAct(idP, 4)];
         tabDur = [tabDur; a_evAct(idP, 5)];
         tabType = [tabType; 6];
      end
         
      for idP = 1:size(a_pumpAct, 1)
         tabDate = [tabDate; a_pumpAct(idP, 3) + g_decArgo_julD2FloatDayOffset];
         tabPres = [tabPres; a_pumpAct(idP, 4)];
         tabDur = [tabDur; a_pumpAct(idP, 5)];
         tabType = [tabType; 7];
      end
      
      if (~isempty(tabDate))
         % sort the actions in chronological order
         [tabDate, idSorted] = sort(tabDate);
         tabPres = tabPres(idSorted);
         tabDur = tabDur(idSorted);
         tabType = tabType(idSorted);

         descentToParkEndDate = g_decArgo_dateDef;
         if (~isempty(a_descentToParkEndDate))
            descentToParkEndDate = a_descentToParkEndDate;
         end
         descentToProfStartDate = g_decArgo_dateDef;
         if (~isempty(a_descentToProfStartDate))
            descentToProfStartDate = a_descentToProfStartDate;
         end

         if (~isempty(a_transStartDate))
            
            tabRefDates = [ ...
               a_cycleStartDate descentToParkEndDate; ...
               descentToParkEndDate descentToProfStartDate; ...
               descentToProfStartDate a_descentToProfEndDate; ...
               a_descentToProfEndDate a_ascentStartDate; ...
               a_ascentStartDate a_transStartDate];
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
                     
                     measStruct = create_one_meas_float_time(tabMc(idS), tabDate(idF(idP)), g_JULD_STATUS_2, floatClockDrift);
                     paramPres = get_netcdf_param_attributes('PRES');
                     paramPres.resolution = single(1);
                     measStruct.paramList = paramPres;
                     measStruct.paramData = tabPres(idF(idP));
                     
                     trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
                     
                     measStruct = create_one_meas_float_time(tabMc(idS), tabDate(idF(idP)), g_JULD_STATUS_2, floatClockDrift);
                     if (tabType(idF(idP)) == 6)
                        param = get_netcdf_param_attributes('VALVE_ACTION_DURATION');
                     else
                        param = get_netcdf_param_attributes('PUMP_ACTION_DURATION');
                     end
                     measStruct.paramList = param;
                     measStruct.paramData = tabDur(idF(idP));
                     
                     o_tabTechNMeas.tabMeas = [o_tabTechNMeas.tabMeas; measStruct];
                  end
               end
            end
         else
            
            % ice detected
            tabRefDates = [ ...
               a_cycleStartDate descentToParkEndDate; ...
               descentToParkEndDate descentToProfStartDate; ...
               descentToProfStartDate a_descentToProfEndDate; ...
               a_descentToProfEndDate a_ascentStartDate; ...
               a_ascentStartDate g_decArgo_dateDef];
            tabMc = [ ...
               g_MC_SpyInDescToPark;...
               g_MC_SpyAtPark;...
               g_MC_SpyInDescToProf;...
               g_MC_SpyAtProf;...
               g_MC_SpyInAscProf];
            
            % structure to store N_MEASUREMENT technical data
            o_tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);
            
            for idS = 1:length(tabMc)
               idF = [];
               if (idS < length(tabMc))
                  if ((tabRefDates(idS, 1) ~= g_decArgo_dateDef) && (tabRefDates(idS, 2) ~= g_decArgo_dateDef))
                     idF = find((tabDate >= tabRefDates(idS, 1)) & (tabDate < tabRefDates(idS, 2)));
                  end
               else
                  if (tabRefDates(idS, 1) ~= g_decArgo_dateDef)
                     idF = find(tabDate >= tabRefDates(idS, 1));
                  end
               end
               
               for idP = 1:length(idF)
                  
                  measStruct = create_one_meas_float_time(tabMc(idS), tabDate(idF(idP)), g_JULD_STATUS_2, floatClockDrift);
                  paramPres = get_netcdf_param_attributes('PRES');
                  paramPres.resolution = single(1);
                  measStruct.paramList = paramPres;
                  measStruct.paramData = tabPres(idF(idP));
                  
                  trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
                  
                  measStruct = create_one_meas_float_time(tabMc(idS), tabDate(idF(idP)), g_JULD_STATUS_2, floatClockDrift);
                  if (tabType(idF(idP)) == 6)
                     param = get_netcdf_param_attributes('VALVE_ACTION_DURATION');
                  else
                     param = get_netcdf_param_attributes('PUMP_ACTION_DURATION');
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
   
   if (~isempty(tabTech1))
      
      % max pressure in descent to parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(19+ID_OFFSET);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(23+ID_OFFSET);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(24+ID_OFFSET);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % max pressure in descent to profile depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(31+ID_OFFSET);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(36+ID_OFFSET);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(37+ID_OFFSET);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
   end
      
   if (~isempty(tabTech2) && (a_iceDetected == 0))
      
      % last pumped CTD measurement
      pres = sensor_2_value_for_pressure_202_210_to_214(tabTech2(15+ID_OFFSET));
      temp = sensor_2_value_for_temperature_204_to_214(tabTech2(16+ID_OFFSET));
      psal = sensor_2_value_for_salinity_210_to_214(tabTech2(17+ID_OFFSET));
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
   end
   
   % grounding information
   grounded = 'N';
   if (~isempty(a_firstGroundingPres))
      if (~isempty(a_firstGroundingDate))
         measStruct = create_one_meas_float_time(g_MC_Grounded, a_firstGroundingDate, g_JULD_STATUS_2, floatClockDrift);
      else
         measStruct = get_traj_one_meas_init_struct();
      end
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_firstGroundingPres;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      grounded = 'Y';
   end
   if (~isempty(a_secondGroundingPres))
      if (~isempty(a_secondGroundingDate))
         measStruct = create_one_meas_float_time(g_MC_Grounded, a_secondGroundingDate, g_JULD_STATUS_2, floatClockDrift);
      else
         measStruct = get_traj_one_meas_init_struct();
      end
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_secondGroundingPres;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      grounded = 'Y';
   end
   % surface grounding
   if (~isempty(tabTech1) && (tabTech1(12+ID_OFFSET) == 1))
      grounded = 'Y';
   end
      
   trajNCycleStruct.grounded = grounded;
   
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
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IN AIR MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   if (~isempty(tabMeasStructInAir))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabMeasStructInAir];
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
configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
if (~isempty(configMissionNumber))
   if (a_cycleNum > 0) % we don't assign any configuration to cycle #0 data
      trajNCycleStruct.configMissionNumber = configMissionNumber;
   end
elseif (trajNCycleStruct.surfOnly == 1)
   % we don't know what should be the configuration number during a surface
   % cycle after a reset of the float => we keep the previous one
   cyNum = a_cycleNum - 1;
   while (cyNum >= 0)
      configMissionNumber = get_config_mission_number_ir_sbd(cyNum);
      if (~isempty(configMissionNumber))
         trajNCycleStruct.configMissionNumber = configMissionNumber;
         break;
      end
      cyNum = cyNum - 1;
   end
end

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return;
