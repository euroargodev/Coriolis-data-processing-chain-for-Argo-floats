% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = process_trajectory_data_228_229( ...
%    a_cycleNum, a_deepCycle, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_cycleTimeData, ...
%    a_tabTech1, a_tabTech2, a_tabTech3, ...
%    a_tabProfiles, ...
%    a_parkDate, a_parkTransDate, ...
%    a_parkPres, a_parkTemp, a_parkSal, ...
%    a_evAct, a_pumpAct, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cycleNum        : current cycle number
%   a_deepCycle       : deep cycle flag
%   a_gpsData         : GPS data
%   a_iridiumMailData : Iridium mail contents
%   a_cycleTimeData   : cycle timings structure
%   a_tabTech1        : decoded data of technical msg #1
%   a_tabTech2        : decoded data of technical msg #2
%   a_tabTech3        : decoded data of technical msg #3
%   a_tabProfiles     : profiles data
%   a_parkDate        : drift meas dates
%   a_parkTransDate   : drift meas transmitted date flags
%   a_parkPres        : drift meas PRES
%   a_parkTemp        : drift meas TEMP
%   a_parkSal         : drift meas PSAL
%   a_evAct           : decoded hydraulic (EV) data
%   a_pumpAct         : decoded hydraulic (pump) data
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : N_CYCLE trajectory data
%   o_tabTechNMeas  : N_MEASUREMENT technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/14/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = process_trajectory_data_228_229( ...
   a_cycleNum, a_deepCycle, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleTimeData, ...
   a_tabTech1, a_tabTech2, a_tabTech3, ...
   a_tabProfiles, ...
   a_parkDate, a_parkTransDate, ...
   a_parkPres, a_parkTemp, a_parkSal, ...
   a_evAct, a_pumpAct, a_decoderId)

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
global g_decArgo_presCountsDef;
global g_decArgo_durationDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% float configuration
global g_decArgo_floatConfig;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% clock drift is provided in seconds
floatClockDriftSec = [];
floatClockDriftMin = [];
clockDriftKnown = ~isempty(a_cycleTimeData.cycleClockOffset);
if (clockDriftKnown == 1)
   floatClockDriftSec = a_cycleTimeData.cycleClockOffset/86400;
   floatClockDriftMin = round(floatClockDriftSec/60)/1440;
end

% retrieve technical message #1 data
tabTech1 = [];
if (~isempty(a_tabTech1))
   idF1 = find(a_tabTech1(:, 1) == 0);
   if (length(idF1) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #1 in the buffer - using the last one\n', ...
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
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #2 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(idF2));
   end
   tabTech2 = a_tabTech2(idF2(end), :);
end

% retrieve technical message #3 data
tabTech3 = [];
if (~isempty(a_tabTech3))
   idF3 = find(a_tabTech3(:, 1) == 26);
   if (length(idF3) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message #3 in the buffer - using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(idF3));
   end
   tabTech3 = a_tabTech3(idF3(end), :);
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

   surfaceLocData = repmat(get_traj_one_meas_init_struct, length(gpsCyLocDate), 1);
   for idpos = 1:length(gpsCyLocDate)
      surfaceLocData(idpos) = create_one_meas_surface(g_MC_Surface, ...
         gpsCyLocDate(idpos), ...
         gpsCyLocLon(idpos), ...
         gpsCyLocLat(idpos), ...
         'G', ...
         ' ', ...
         num2str(gpsCyLocQc(idpos)), 1);
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   iridiumCyLocDate = [];
   if (~isempty(a_iridiumMailData))
      idFixForCycle = find([a_iridiumMailData.cycleNumber] == a_cycleNum);
      cpt = length(surfaceLocData) + 1;
      surfaceLocData = cat(1, ...
         surfaceLocData, ...
         repmat(get_traj_one_meas_init_struct, length(idFixForCycle), 1));
      for idFix = idFixForCycle
         if (a_iridiumMailData(idFix).cepRadius ~= 0)
            surfaceLocData(cpt) = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
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
            cpt = cpt + 1;
         end
      end
      surfaceLocData(cpt:end) = [];
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
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      trajNCycleStruct.juldLastMessage = lastMsgTime;
      trajNCycleStruct.juldLastMessageStatus = g_JULD_STATUS_4;
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % FLOAT CYCLE TIMES
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % clock offset
   if (~isempty(floatClockDriftSec))
      trajNCycleStruct.clockOffset = floatClockDriftSec;
      trajNCycleStruct.dataMode = 'A';
   else
      trajNCycleStruct.dataMode = 'R';
   end

   % Cycle Start Time (i.e. buoyancy reduction start time for this float type)
   cycleStartDate = a_cycleTimeData.cycleStartDate;
   if (isempty(cycleStartDate))
      cycleStartDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_CycleStart, cycleStartDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldCycleStart = nCycleTime;
   trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;

   % Descent Start Time
   descentToParkStartDate = a_cycleTimeData.descentToParkStartDate;
   if (isempty(descentToParkStartDate))
      descentToParkStartDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_DST, descentToParkStartDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldDescentStart = nCycleTime;
   trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;

   % First Stabilization Time
   firstStabDate = a_cycleTimeData.firstStabDate;
   if (isempty(firstStabDate))
      firstStabDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_FST, firstStabDate, g_JULD_STATUS_2, floatClockDriftMin);
   if (firstStabDate ~= g_decArgo_dateDef)
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_cycleTimeData.firstStabPres;
   end
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldFirstStab = nCycleTime;
   trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;

   % Park Start Time
   descentToParkEndDate = a_cycleTimeData.descentToParkEndDate;
   if (isempty(descentToParkEndDate))
      descentToParkEndDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_PST, descentToParkEndDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldParkStart = nCycleTime;
   trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;

   % Park End Time
   descentToProfStartDate = a_cycleTimeData.descentToProfStartDate;
   if (isempty(descentToProfStartDate))
      descentToProfStartDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_PET, descentToProfStartDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldParkEnd = nCycleTime;
   trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;

   % Deep Park Start Time
   descentToProfEndDate = a_cycleTimeData.descentToProfEndDate;
   if (isempty(descentToProfEndDate))
      descentToProfEndDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_DPST, descentToProfEndDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldDeepParkStart = nCycleTime;
   trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;

   % Ascent Start Time
   ascentStartDate = a_cycleTimeData.ascentStartDate;
   if (isempty(ascentStartDate))
      ascentStartDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_AST, ascentStartDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldAscentStart = nCycleTime;
   trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;

   % Ascent End Time
   ascentEndDate = a_cycleTimeData.ascentEndDate;
   if (isempty(ascentEndDate))
      ascentEndDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_AET, ascentEndDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldAscentEnd = nCycleTime;
   trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;

   % Transmission Start Time
   transStartDate = a_cycleTimeData.transStartDate;
   if (isempty(transStartDate))
      transStartDate = g_decArgo_dateDef;
   end
   [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
      g_MC_TST, transStartDate, g_JULD_STATUS_2, floatClockDriftMin);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldTransmissionStart = nCycleTime;
   trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_2;

   % Transmission End Time
   measStruct = create_one_meas_float_time(g_MC_TET, -1, g_JULD_STATUS_9, floatClockDriftMin);
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
            [measStruct, ~] = create_one_meas_float_time_ter(...
               measCode, profDates(idMeas), g_JULD_STATUS_2, floatClockDriftSec);
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
            [measStruct, ~] = create_one_meas_float_time_ter(...
               g_MC_DriftAtPark, a_parkDate(idMeas), measTimeStatus, floatClockDriftSec);
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
   % HYDRAULIC ACTIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   tabDate = [];
   tabPres = [];
   tabDur = [];
   tabType = [];

   if (~isempty(a_evAct))

      for idP = 1:size(a_evAct, 1)

         data = a_evAct(idP, :);
         for idPoint = 1:15
            if ~((data(idPoint+2) == g_decArgo_dateDef) && ...
                  (data(idPoint+2+30) == g_decArgo_presCountsDef) && ...
                  (data(idPoint+2+45) == g_decArgo_durationDef))

               tabDate = [tabDate; data(idPoint+2) + g_decArgo_julD2FloatDayOffset];
               tabPres = [tabPres; data(idPoint+2+30)];
               tabDur = [tabDur; data(idPoint+2+45)];
               tabType = [tabType; data(1)];
            else
               break
            end
         end
      end
   end
   if (~isempty(a_pumpAct))
      for idP = 1:size(a_pumpAct, 1)

         data = a_pumpAct(idP, :);
         for idPoint = 1:15
            if ~((data(idPoint+2) == g_decArgo_dateDef) && ...
                  (data(idPoint+2+30) == g_decArgo_presCountsDef) && ...
                  (data(idPoint+2+45) == g_decArgo_durationDef))

               tabDate = [tabDate; data(idPoint+2) + g_decArgo_julD2FloatDayOffset];
               tabPres = [tabPres; data(idPoint+2+30)];
               tabDur = [tabDur; data(idPoint+2+45)];
               tabType = [tabType; data(1)];
            else
               break
            end
         end
      end
   end

   if (~isempty(tabDate))
      % sort the actions in chronological order
      [tabDate, idSorted] = sort(tabDate);
      tabPres = tabPres(idSorted);
      tabDur = tabDur(idSorted);
      tabType = tabType(idSorted);

      cycleStartDate = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.cycleStartDate))
         cycleStartDate = a_cycleTimeData.cycleStartDate;
      end
      descentToParkEndDate = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.descentToParkEndDate))
         descentToParkEndDate = a_cycleTimeData.descentToParkEndDate;
      end
      descentToProfStartDate = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.descentToProfStartDate))
         descentToProfStartDate = a_cycleTimeData.descentToProfStartDate;
      end
      descentToProfEndDate = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.descentToProfEndDate))
         descentToProfEndDate = a_cycleTimeData.descentToProfEndDate;
      end
      ascentStartDate = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.ascentStartDate))
         ascentStartDate = a_cycleTimeData.ascentStartDate;
      end
      transStartDate = g_decArgo_dateDef;
      if (~isempty(a_cycleTimeData.transStartDate))
         transStartDate = a_cycleTimeData.transStartDate;
      end

      tabRefDates = [ ...
         cycleStartDate descentToParkEndDate; ...
         descentToParkEndDate descentToProfStartDate; ...
         descentToProfStartDate descentToProfEndDate; ...
         descentToProfEndDate ascentStartDate; ...
         ascentStartDate transStartDate];
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

         if (transStartDate ~= g_decArgo_dateDef)
            % no ice detected
            if ((tabRefDates(idS, 1) ~= g_decArgo_dateDef) && (tabRefDates(idS, 2) ~= g_decArgo_dateDef))
               idF = find((tabDate >= tabRefDates(idS, 1)) & (tabDate < tabRefDates(idS, 2)));
            end
         else
            % ice detected
            if (idS < length(tabMc))
               if ((tabRefDates(idS, 1) ~= g_decArgo_dateDef) && (tabRefDates(idS, 2) ~= g_decArgo_dateDef))
                  idF = find((tabDate >= tabRefDates(idS, 1)) & (tabDate < tabRefDates(idS, 2)));
               end
            else
               if (tabRefDates(idS, 1) ~= g_decArgo_dateDef)
                  idF = find(tabDate >= tabRefDates(idS, 1));
               end
            end
         end

         for idP = 1:length(idF)

            [measStruct, ~] = create_one_meas_float_time_ter(...
               tabMc(idS), tabDate(idF(idP)), g_JULD_STATUS_2, floatClockDriftMin);
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(1);
            measStruct.paramList = paramPres;
            measStruct.paramData = tabPres(idF(idP));

            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

            [measStruct, ~] = create_one_meas_float_time_ter(...
               tabMc(idS), tabDate(idF(idP)), g_JULD_STATUS_2, floatClockDriftMin);
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
      if (isempty(o_tabTechNMeas.tabMeas))
         o_tabTechNMeas = [];
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
               [measStruct, ~] = create_one_meas_float_time_ter(...
                  measCode, profDates(idDeepest), g_JULD_STATUS_2, floatClockDriftSec);
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
      measStruct.paramData = tabTech1(17);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(21);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtPark;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(22);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      % max pressure in descent to profile depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDescToProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(29);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      % min/max pressure in drift at parking depth
      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MinPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(34);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      measStruct = get_traj_one_meas_init_struct();
      measStruct.measCode = g_MC_MaxPresInDriftAtProf;
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = tabTech1(35);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   end

   if (~isempty(tabTech2) && (a_cycleTimeData.iceAscentAbortedFlag == 0))
      % last pumped CTD measurement

      % TECH3 INFORMATION NOT USED (NOT RELIABLE)
      % if (~isempty(tabTech3))
      %    pres = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(tabTech2(11));
      %    temp = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(tabTech2(12));
      %    psal = tabTech2(13)/1000;
      %    if (any([pres temp psal] ~= 0))
      %       pres2 = sensor_2_value_for_pressure_3T_228_2T_229(tabTech3(46));
      %       temp2 = sensor_2_value_for_temperature_3T_228_2T_229(tabTech3(47));
      %       psal2 = sensor_2_value_for_salinity_3T_228_2T_229(tabTech3(48));
      %       pres3 = sensor_2_value_for_pressure_3T_228_2T_229(tabTech3(49));
      %       temp3 = sensor_2_value_for_temperature_3T_228_2T_229(tabTech3(50));
      %       psal3 = sensor_2_value_for_salinity_3T_228_2T_229(tabTech3(51));
      %       tempCndc = sensor_2_value_for_temperature_3T_228_2T_229(tabTech3(52));
      %
      %       measStruct = get_traj_one_meas_init_struct();
      %       measStruct.measCode = g_MC_LastAscPumpedCtd;
      %       paramPres = get_netcdf_param_attributes('PRES');
      %       paramTemp = get_netcdf_param_attributes('TEMP');
      %       paramSal = get_netcdf_param_attributes('PSAL');
      %       paramPres2 = get_netcdf_param_attributes('PRES_2');
      %       paramTemp2 = get_netcdf_param_attributes('TEMP_2');
      %       paramSal2 = get_netcdf_param_attributes('PSAL_2');
      %       paramPres3 = get_netcdf_param_attributes('PRES_3');
      %       paramTemp3 = get_netcdf_param_attributes('TEMP_3');
      %       paramSal3 = get_netcdf_param_attributes('PSAL_3');
      %       paramTempCndc = get_netcdf_param_attributes('TEMP_CNDC');
      %       measStruct.paramList = [paramPres paramTemp paramSal ...
      %          paramPres2 paramTemp2 paramSal2 ...
      %          paramPres3 paramTemp3 paramSal3 paramTempCndc];
      %
      %       measStruct.paramData = [pres temp psal pres2 temp2 psal2 pres3 temp3 psal3 tempCndc];
      %
      %       trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      %    end
      % else

      % the provided information is not reliable for decId 229 (RBR sensor)
      if (a_decoderId == 228)
         pres = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(tabTech2(11));
         temp = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(tabTech2(12));
         psal = tabTech2(13)/1000;
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
      % end
   end

   % grounding information
   grounded = 'N';
   if (~isempty(a_cycleTimeData.firstGroundingPres))
      if (~isempty(a_cycleTimeData.firstGroundingDate))
         [measStruct, ~] = create_one_meas_float_time_ter( ...
            g_MC_Grounded, a_cycleTimeData.firstGroundingDate, ...
            g_JULD_STATUS_2, floatClockDriftMin);
      else
         measStruct = get_traj_one_meas_init_struct();
      end
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_cycleTimeData.firstGroundingPres;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      grounded = 'Y';
   end
   if (~isempty(a_cycleTimeData.secondGroundingPres))
      if (~isempty(a_cycleTimeData.secondGroundingDate))
         [measStruct, ~] = create_one_meas_float_time_ter( ...
            g_MC_Grounded, a_cycleTimeData.secondGroundingDate, ...
            g_JULD_STATUS_2, floatClockDriftMin);
      else
         measStruct = get_traj_one_meas_init_struct();
      end
      paramPres = get_netcdf_param_attributes('PRES');
      paramPres.resolution = single(1);
      measStruct.paramList = paramPres;
      measStruct.paramData = a_cycleTimeData.secondGroundingPres;
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      grounded = 'Y';
   end
   % surface grounding
   if (~isempty(tabTech1) && (tabTech1(10) == 1))
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
         g_decArgo_argosLonDef, [], [], [], [], clockDriftKnown);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      trajNCycleStruct.juldFirstMessage = firstMsgTime;
      trajNCycleStruct.juldFirstMessageStatus = g_JULD_STATUS_4;
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % GPS LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % unpack GPS data
   gpsLocCycleNum = g_decArgo_gpsData{1};
   gpsLocDate = g_decArgo_gpsData{4};
   gpsLocLon = g_decArgo_gpsData{5};
   gpsLocLat = g_decArgo_gpsData{6};
   gpsLocQc = g_decArgo_gpsData{7};
   gpsLocInTrajFlag = g_decArgo_gpsData{13};

   idF = find((gpsLocCycleNum == a_cycleNum) & (gpsLocInTrajFlag == 0));
   gpsCyLocDate = gpsLocDate(idF);
   gpsCyLocLon = gpsLocLon(idF);
   gpsCyLocLat = gpsLocLat(idF);
   gpsCyLocQc = gpsLocQc(idF);

   surfaceLocData = repmat(get_traj_one_meas_init_struct, length(gpsCyLocDate), 1);
   for idpos = 1:length(gpsCyLocDate)
      surfaceLocData(idpos) = create_one_meas_surface(g_MC_Surface, ...
         gpsCyLocDate(idpos), ...
         gpsCyLocLon(idpos), ...
         gpsCyLocLat(idpos), ...
         'G', ...
         ' ', ...
         num2str(gpsCyLocQc(idpos)), 1);
   end

   gpsLocInTrajFlag(idF) = 1; % to be sure each new location is computed only once
   g_decArgo_gpsData{13} = gpsLocInTrajFlag;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % IRIDIUM LOCATIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   iridiumCyLocDate = [];
   if (~isempty(g_decArgo_iridiumMailData))
      idFixForCycle = find(([g_decArgo_iridiumMailData.cycleNumber] == a_cycleNum) & ...
         ([g_decArgo_iridiumMailData.locInTrajFlag] == 0));
      if (~isempty(idFixForCycle))
         cpt = length(surfaceLocData) + 1;
         surfaceLocData = cat(1, ...
            surfaceLocData, ...
            repmat(get_traj_one_meas_init_struct, length(idFixForCycle), 1));
         for idFix = idFixForCycle
            if (g_decArgo_iridiumMailData(idFix).cepRadius ~= 0)
               surfaceLocData(cpt) = create_one_meas_surface_with_error_ellipse(g_MC_Surface, ...
                  g_decArgo_iridiumMailData(idFix).timeOfSessionJuld, ...
                  g_decArgo_iridiumMailData(idFix).unitLocationLon, ...
                  g_decArgo_iridiumMailData(idFix).unitLocationLat, ...
                  'I', ...
                  0, ... % no need to set a Qc, it will be set during RTQC
                  g_decArgo_iridiumMailData(idFix).cepRadius*1000, ...
                  g_decArgo_iridiumMailData(idFix).cepRadius*1000, ...
                  '', ...
                  ' ', ...
                  1);
               cpt = cpt + 1;
            end
         end
         surfaceLocData(cpt:end) = [];
         iridiumCyLocDate = [g_decArgo_iridiumMailData(idFixForCycle).timeOfSessionJuld];
         [g_decArgo_iridiumMailData(idFixForCycle).locInTrajFlag] = deal(1); % to be sure each new location is computed only once
      end
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % grounding information
   grounded = 'N';

   if (~isempty(tabTech1) && (tabTech1(10) == 1)) % if the "grounded at surface flag" is set to 1
      grounded = 'Y';
      if (~isempty(a_cycleTimeData.firstGroundingPres))
         if (~isempty(a_cycleTimeData.firstGroundingDate))
            [measStruct, ~] = create_one_meas_float_time_ter(...
               g_MC_Grounded, a_cycleTimeData.firstGroundingDate, ...
               g_JULD_STATUS_2, floatClockDriftMin);
         else
            measStruct = get_traj_one_meas_init_struct();
         end
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = a_cycleTimeData.firstGroundingPres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      if (~isempty(a_cycleTimeData.secondGroundingPres))
         if (~isempty(a_cycleTimeData.secondGroundingDate))
            [measStruct, ~] = create_one_meas_float_time_ter(...
               g_MC_Grounded, a_cycleTimeData.secondGroundingDate, ...
               g_JULD_STATUS_2, floatClockDriftMin);
         else
            measStruct = get_traj_one_meas_init_struct();
         end
         paramPres = get_netcdf_param_attributes('PRES');
         paramPres.resolution = single(1);
         measStruct.paramList = paramPres;
         measStruct.paramData = a_cycleTimeData.secondGroundingPres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end

   trajNCycleStruct.grounded = grounded;

   if (trajNCycleStruct.grounded == 'Y')

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % FLOAT CYCLE TIMES
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

      % clock offset
      if (~isempty(floatClockDriftSec))
         trajNCycleStruct.clockOffset = floatClockDriftSec;
         trajNCycleStruct.dataMode = 'A';
      else
         trajNCycleStruct.dataMode = 'R';
      end

      % Cycle Start Time (i.e. buoyancy reduction start time for this float type)
      cycleStartDate = a_cycleTimeData.cycleStartDate;
      if (isempty(cycleStartDate))
         cycleStartDate = g_decArgo_dateDef;
      end
      [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
         g_MC_CycleStart, cycleStartDate, g_JULD_STATUS_2, floatClockDriftMin);
      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

      trajNCycleStruct.juldCycleStart = nCycleTime;
      trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;

      % First/second grounding phase (2:buoyancy reduction 3:descent to park 4:park drift 5:descent to prof 6:prof drift)
      % last grounding phase occurred after "buoyancy reduction" phase
      if (~isempty(tabTech2) && ...
            ((tabTech2(17) == 1) && (tabTech2(21) > 2) || ...
            (tabTech2(17) > 1) && (tabTech2(26) > 2)))

         % Descent Start Time
         descentToParkStartDate = a_cycleTimeData.descentToParkStartDate;
         if (isempty(descentToParkStartDate))
            descentToParkStartDate = g_decArgo_dateDef;
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
            g_MC_DST, descentToParkStartDate, g_JULD_STATUS_2, floatClockDriftMin);
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

         trajNCycleStruct.juldDescentStart = nCycleTime;
         trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;

         % First Stabilization Time
         firstStabDate = a_cycleTimeData.firstStabDate;
         if (isempty(firstStabDate))
            firstStabDate = g_decArgo_dateDef;
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
            g_MC_FST, firstStabDate, g_JULD_STATUS_2, floatClockDriftMin);
         if (firstStabDate ~= g_decArgo_dateDef)
            paramPres = get_netcdf_param_attributes('PRES');
            paramPres.resolution = single(1);
            measStruct.paramList = paramPres;
            measStruct.paramData = a_cycleTimeData.firstStabPres;
         end
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

         trajNCycleStruct.juldFirstStab = nCycleTime;
         trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;
      end

      % First/second grounding phase (2:buoyancy reduction 3:descent to park 4:park drift 5:descent to prof 6:prof drift)
      % last grounding phase occurred after "descent to park" phase
      if (~isempty(tabTech2) && ...
            ((tabTech2(17) == 1) && (tabTech2(21) > 3) || ...
            (tabTech2(17) > 1) && (tabTech2(26) > 3)))

         % Park Start Time
         descentToParkEndDate = a_cycleTimeData.descentToParkEndDate;
         if (isempty(descentToParkEndDate))
            descentToParkEndDate = g_decArgo_dateDef;
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
            g_MC_PST, descentToParkEndDate, g_JULD_STATUS_2, floatClockDriftMin);
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

         trajNCycleStruct.juldParkStart = nCycleTime;
         trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;
      end

      % First/second grounding phase (2:buoyancy reduction 3:descent to park 4:park drift 5:descent to prof 6:prof drift)
      % last grounding phase occurred after "park drift" phase
      if (~isempty(tabTech2) && ...
            ((tabTech2(17) == 1) && (tabTech2(21) > 4) || ...
            (tabTech2(17) > 1) && (tabTech2(26) > 4)))

         % Park End Time
         descentToProfStartDate = a_cycleTimeData.descentToProfStartDate;
         if (isempty(descentToProfStartDate))
            descentToProfStartDate = g_decArgo_dateDef;
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
            g_MC_PET, descentToProfStartDate, g_JULD_STATUS_2, floatClockDriftMin);
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

         trajNCycleStruct.juldParkEnd = nCycleTime;
         trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;
      end

      % First/second grounding phase (2:buoyancy reduction 3:descent to park 4:park drift 5:descent to prof 6:prof drift)
      % last grounding phase occurred after "descent to prof" phase
      if (~isempty(tabTech2) && ...
            ((tabTech2(17) == 1) && (tabTech2(21) > 5) || ...
            (tabTech2(17) > 1) && (tabTech2(26) > 5)))

         % Deep Park Start Time
         descentToProfEndDate = a_cycleTimeData.descentToProfEndDate;
         if (isempty(descentToProfEndDate))
            descentToProfEndDate = g_decArgo_dateDef;
         end
         [measStruct, nCycleTime] = create_one_meas_float_time_ter(...
            g_MC_DPST, descentToProfEndDate, g_JULD_STATUS_2, floatClockDriftMin);
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

         trajNCycleStruct.juldDeepParkStart = nCycleTime;
         trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;
      end
   else
      trajNMeasStruct.surfOnly = 1;
      trajNCycleStruct.surfOnly = 1;
   end
end

% add configuration mission number
if (any(g_decArgo_floatConfig.USE.CYCLE == a_cycleNum))
   configMissionNumber = get_config_mission_number_ir_sbd(a_cycleNum);
   if (~isempty(configMissionNumber))
      if (a_cycleNum > 0) % we don't assign any configuration to cycle #0 data
         trajNCycleStruct.configMissionNumber = configMissionNumber;
      end
   end
elseif (trajNCycleStruct.surfOnly == 1)
   % we don't know what should be the configuration number during a surface
   % cycle after a reset of the float => we keep the previous one
   cyNum = a_cycleNum - 1;
   while (cyNum >= 0)
      if (any(g_decArgo_floatConfig.USE.CYCLE == cyNum))
         configMissionNumber = get_config_mission_number_ir_sbd(cyNum);
         if (~isempty(configMissionNumber))
            trajNCycleStruct.configMissionNumber = configMissionNumber;
            break
         end
      end
      cyNum = cyNum - 1;
   end
end

% output data
o_tabTrajNMeas = [o_tabTrajNMeas; trajNMeasStruct];
o_tabTrajNCycle = trajNCycleStruct;

return
