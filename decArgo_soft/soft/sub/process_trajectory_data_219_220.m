% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_219_220( ...
%    a_cycleNum, a_deepCycle, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_cycleStartDate, ...
%    a_descentToParkStartDate, a_descentToParkEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, ...
%    a_transStartDate, ...
%    a_tabTech, ...
%    a_tabProfiles)
%
% INPUT PARAMETERS :
%   a_cycleNum               : current cycle number
%   a_deepCycle              : deep cycle flag
%   a_gpsData                : GPS data
%   a_iridiumMailData        : Iridium mail contents
%   a_cycleStartDate         : cycle start date
%   a_descentToParkStartDate : descent to park start date
%   a_descentToParkEndDate   : descent to park end date
%   a_ascentStartDate        : ascent start date
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%   a_tabTech                : technical data
%   a_tabProfiles            : profiles data
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
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_219_220( ...
   a_cycleNum, a_deepCycle, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleStartDate, ...
   a_descentToParkStartDate, a_descentToParkEndDate, ...
   a_ascentStartDate, a_ascentEndDate, ...
   a_transStartDate, ...
   a_tabTech, ...
   a_tabProfiles)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% global measurement codes
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_PST;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_AET;
global g_MC_TST;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_TET;
global g_MC_Grounded;

% global time status
global g_JULD_STATUS_2;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% default values
global g_decArgo_ncDateDef;
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% clock drift is supposed to be 0
floatClockDrift = 0;

% retrieve technical message data
tabTechDeep = [];
if (~isempty(a_tabTech))
   idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 1));
   if (length(idF) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(idF));
   end
   if (~isempty(idF))
      tabTechDeep = a_tabTech(idF(end), :);
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
         num2str(gpsCyLocQc(idpos)), 1);
      surfaceLocData = [surfaceLocData; measStruct];
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   iridiumCyLocDate = [];
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
               1);
            surfaceLocData = [surfaceLocData; measStruct];
         end
      end
      iridiumCyLocDate = [a_iridiumMailData(idFixForCycle).timeOfSessionJuld];
   end
   
   % sort the surface locations by date
   if (~isempty(surfaceLocData))
      surfaceLocDates = [surfaceLocData.juld];
      [~, idSort] = sort(surfaceLocDates);
      surfaceLocData = surfaceLocData(idSort);
      
      % store the data
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; surfaceLocData];
      surfaceLocData = [];
   end
   
   if (~isempty(gpsCyLocDate) || ~isempty(iridiumCyLocDate))
      locDates = [gpsCyLocDate' iridiumCyLocDate];
      
      trajNCycleStruct.juldFirstLocation = min(locDates);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      trajNCycleStruct.juldLastLocation = max(locDates);
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
   % MISCELLANEOUS MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % deepest bin of the ascending profile
   tabAscDeepestBin = [];
   tabAscDeepestBinPres = [];
   for idProf = 1:length(a_tabProfiles)
      profile = a_tabProfiles(idProf);
      
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
            
            idDeepest = idNotDef(1);
            
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_AscProfDeepestBin;
            
            % add parameter variables to the structure
            measStruct.paramList = profile.paramList;
            
            % add parameter data to the structure
            measStruct.paramData = profile.data(idDeepest, :);
            
            tabAscDeepestBin = [tabAscDeepestBin; measStruct];
            tabAscDeepestBinPres = [tabAscDeepestBinPres; profile.data(idDeepest, idPres)];
         end
      end
   end
   
   if (~isempty(tabAscDeepestBin))
      [~, idMax] = max(tabAscDeepestBinPres);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; tabAscDeepestBin(idMax)];
   end
   
   % miscellaneous measurements from technical message
   
   if (~isempty(tabTechDeep))
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTechDeep(9);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTechDeep(10);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % grounding information
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_Grounded;
      paramPres = get_netcdf_param_attributes('PRES');
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTechDeep(8);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      trajNCycleStruct.grounded = 'Y';
      
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
         num2str(gpsCyLocQc(idpos)), 1);
      surfaceLocData = [surfaceLocData; measStruct];
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   iridiumCyLocDate = [];
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
               1);
            surfaceLocData = [surfaceLocData; measStruct];
         end
      end
      iridiumCyLocDate = [a_iridiumMailData(idFixForCycle).timeOfSessionJuld];
   end
   
   % sort the surface locations by date
   if (~isempty(surfaceLocData))
      surfaceLocDates = [surfaceLocData.juld];
      [~, idSort] = sort(surfaceLocDates);
      surfaceLocData = surfaceLocData(idSort);
      
      % store the data
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; surfaceLocData];
      surfaceLocData = [];
   end
   
   if (~isempty(gpsCyLocDate) || ~isempty(iridiumCyLocDate))
      locDates = [gpsCyLocDate' iridiumCyLocDate];
      
      trajNCycleStruct.juldFirstLocation = min(locDates);
      trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
      
      trajNCycleStruct.juldLastLocation = max(locDates);
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
trajNCycleStruct.configMissionNumber = 1;

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return
