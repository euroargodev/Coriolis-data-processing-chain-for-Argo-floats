% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_30( ...
%    a_cycleNum, ...
%    a_addLaunchData, a_floatSurfData, ...
%    a_floatClockDrift, ...
%    a_cycleStartDate, a_descentStartDate, ...
%    a_firstStabDate, a_firstStabPres, a_descentEndDate, ...
%    a_descentToProfStartDate, a_descentToProfEndDate, ...
%    a_ascentStartDate, a_ascentEndDate, a_transStartDate, ...
%    a_firstGroundingDate, a_firstGroundingPres, ...
%    a_cycleProfiles, ...
%    a_parkDate, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
%    a_tabTech1, a_tabTech2, a_decoderId, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_cycleNum               : current cycle number
%   a_addLaunchData          : flag to add float launch time and position
%   a_floatSurfData          : float surface data structure
%   a_floatClockDrift        : float clock drift
%   a_cycleStartDate         : cycle start date
%   a_descentStartDate       : descent start date
%   a_firstStabDate          : first stabilisation date
%   a_firstStabPres          : first stabilisation pressure (dbar)
%   a_descentEndDate         : descent end date
%   a_descentToProfStartDate : descent to profile start date
%   a_descentToProfEndDate   : descent to profile end date
%   a_ascentStartDate        : ascent start date
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%   a_firstGroundingDate     : first grounding date
%   a_firstGroundingPres     : first grounding pressure
%   a_cycleProfiles          : profiles data
%   a_parkDate               : date of parking measurements
%   a_parkTransDate          : transmitted (=1) or computed (=0) date of parking
%                              measurements
%   a_parkPres               : parking pressure measurements
%   a_parkTemp               : parking temperature measurements
%   a_parkSal                : parking salinity measurements
%   a_tabTech1               : technical #1 data
%   a_tabTech2               : technical #2 data
%   a_decoderId              : float decoder Id
%   a_deepCycle              : deep cycle flag
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
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_30( ...
   a_cycleNum, ...
   a_addLaunchData, a_floatSurfData, ...
   a_floatClockDrift, ...
   a_cycleStartDate, a_descentStartDate, ...
   a_firstStabDate, a_firstStabPres, a_descentEndDate, ...
   a_descentToProfStartDate, a_descentToProfEndDate, ...
   a_ascentStartDate, a_ascentEndDate, a_transStartDate, ...
   a_firstGroundingDate, a_firstGroundingPres, ...
   a_cycleProfiles, ...
   a_parkDate, a_parkTransDate, a_parkPres, a_parkTemp, a_parkSal, ...
   a_tabTech1, a_tabTech2, a_decoderId, a_deepCycle)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% global measurement codes
global g_MC_Launch;
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
global g_decArgo_dateDef;
global g_decArgo_ncDateDef;
global g_decArgo_argosLonDef;
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


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
      ' ', ' ', '0');
   
   trajNMeasStruct.surfOnly = 1;
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
end

% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% surface data for the current cycle
cycleSurfData = a_floatSurfData.cycleData(end);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POSITIONING SYSTEM AND TRANSMISSION SYSTEM TIMES AND LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First Message Time
if (cycleSurfData.firstMsgTime ~= g_decArgo_dateDef)
   measStruct = create_one_meas_surface(g_MC_FMT, ...
      cycleSurfData.firstMsgTime, ...
      g_decArgo_argosLonDef, [], [], [], []);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldFirstMessage = cycleSurfData.firstMsgTime;
   trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
end

% Argos locations
for idpos = 1:length(cycleSurfData.argosLocDate)
   measStruct = create_one_meas_surface(g_MC_Surface, ...
      cycleSurfData.argosLocDate(idpos), ...
      cycleSurfData.argosLocLon(idpos), ...
      cycleSurfData.argosLocLat(idpos), ...
      cycleSurfData.argosLocAcc(idpos), ...
      cycleSurfData.argosLocSat(idpos), ...
      cycleSurfData.argosLocQc(idpos));
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
end

if (~isempty(cycleSurfData.argosLocDate))
   trajNCycleStruct.juldFirstLocation = cycleSurfData.argosLocDate(1);
   trajNCycleStruct.juldFirstLocationStatus = g_JULD_STATUS_4;
   
   trajNCycleStruct.juldLastLocation = cycleSurfData.argosLocDate(end);
   trajNCycleStruct.juldLastLocationStatus = g_JULD_STATUS_4;
end

% Last Message Time
if (cycleSurfData.lastMsgTime ~= g_decArgo_dateDef)
   measStruct = create_one_meas_surface(g_MC_LMT, ...
      cycleSurfData.lastMsgTime, ...
      g_decArgo_argosLonDef, [], [], [], []);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldLastMessage = cycleSurfData.lastMsgTime;
   trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FLOAT CYCLE TIMES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% round float drift to minutes
floatClockDrift = [];
if (~isempty(a_floatClockDrift))
   floatClockDrift = round(a_floatClockDrift*1440)/1440;
   
   trajNCycleStruct.clockOffset = floatClockDrift;
   trajNCycleStruct.dataMode = 'A';
end

if (a_deepCycle == 1)
   
   % Cycle Start Time
   measStruct = create_one_meas_float_time(g_MC_CycleStart, a_cycleStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_cycleStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldCycleStart = a_cycleStartDate;
      trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;
   end
   
   % Descent Start Time
   measStruct = create_one_meas_float_time(g_MC_DST, a_descentStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_descentStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldDescentStart = a_descentStartDate;
      trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
   end
   
   % First Stabilization Time
   measStruct = create_one_meas_float_time(g_MC_FST, a_firstStabDate, g_JULD_STATUS_2, floatClockDrift);
   if (a_firstStabDate ~= g_decArgo_dateDef)
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_firstStabPres;
   end
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_firstStabDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldFirstStab = a_firstStabDate;
      trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;
   end
   
   % Park Start Time
   measStruct = create_one_meas_float_time(g_MC_PST, a_descentEndDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_descentEndDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldParkStart = a_descentEndDate;
      trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
   end
   
   % Park End Time
   measStruct = create_one_meas_float_time(g_MC_PET, a_descentToProfStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_descentToProfStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldParkEnd = a_descentToProfStartDate;
      trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
   end
   
   % Deep Park Start Time
   measStruct = create_one_meas_float_time(g_MC_DPST, a_descentToProfEndDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_descentToProfEndDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldDeepParkStart = a_descentToProfEndDate;
      trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;
   end
   
   % Ascent Start Time
   measStruct = create_one_meas_float_time(g_MC_AST, a_ascentStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_ascentStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldAscentStart = a_ascentStartDate;
      trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;
   end
   
   % Ascent End Time
   measStruct = create_one_meas_float_time(g_MC_AET, a_ascentEndDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_ascentEndDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldAscentEnd = a_ascentEndDate;
      trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;
   end
   
   % Transmission Start Time
   measStruct = create_one_meas_float_time(g_MC_TST, a_transStartDate, g_JULD_STATUS_2, floatClockDrift);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   if (a_transStartDate ~= g_decArgo_dateDef)
      trajNCycleStruct.juldTransmissionStart = a_transStartDate;
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
   
   for idProf = 1:length(a_cycleProfiles)
      profile = a_cycleProfiles(idProf);
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
      paramPres.resolution = single(1);
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
         (a_parkTemp == paramTemp.fillValue) | (a_parkSal == paramSal.fillValue)));
      if (~isempty(idForMean))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_RPP;
         measStruct.paramList = [paramPres paramTemp paramSal];
         measStruct.paramData = [mean(a_parkPres(idForMean)) mean(a_parkTemp(idForMean)) mean(a_parkSal(idForMean))];
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         
         trajNCycleStruct.repParkPres = mean(a_parkPres(idForMean));
         trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
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
   for idProf = 1:length(a_cycleProfiles)
      profile = a_cycleProfiles(idProf);
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
   
   if (~isempty(a_tabTech2))
      
      % max pressure in descent to parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_tabTech2(10);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_tabTech2(12);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_tabTech2(13);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % max pressure in descent to profile depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_tabTech2(16);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_tabTech2(17);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(10);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_tabTech2(18);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
   
   if (~isempty(a_tabTech1))
      
      % grounding information
      grounded = 'N';
      if (a_firstGroundingDate ~= g_decArgo_dateDef)
         measStruct = create_one_meas_float_time(g_MC_Grounded, a_firstGroundingDate, g_JULD_STATUS_2, floatClockDrift);
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = a_firstGroundingPres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         grounded = 'Y';
      end
      % surface grounding
      if (a_tabTech1(5) == 1)
         grounded = 'Y';
      end
      
      trajNCycleStruct.grounded = grounded;
      
   end
end

% check that all expected MC are present

% measurement codes expected to be in each cycle for these floats (primary and
% secondary MC experienced by Provor Argos floats)
expMcList = [ ...
   g_MC_DST ...
   g_MC_FST ...
   g_MC_PST ...
   g_MC_PET ...
   g_MC_DPST ...
   g_MC_AST ...
   g_MC_AET ...
   g_MC_TST ...
   g_MC_TET ...
   ];

if (get_default_prelude_duration(a_decoderId) == 0)
   firstDeepCycle = 0;
else
   firstDeepCycle = 1;
end
if (a_cycleNum >= firstDeepCycle)
   measCodeList = unique([trajNMeasStruct.tabMeas.measCode]);
   
   % add MCs so that all expected ones will be present
   mcList = setdiff(expMcList, measCodeList);
   measData = [];
   for idMc = 1:length(mcList)
      measStruct = create_one_meas_float_time(mcList(idMc), -1, g_JULD_STATUS_9, 0);
      measData = [measData; measStruct];
   end
   
   % store the data
   if (~isempty(measData))
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measData];
   end
end

% configuration mission number
configMissionNumber = get_config_mission_number_argos( ...
   a_cycleNum, [], a_decoderId);
if (~isempty(configMissionNumber))
   trajNCycleStruct.configMissionNumber = configMissionNumber;
end

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return;
