% ------------------------------------------------------------------------------
% Process trajectory data.
%
% SYNTAX :
% [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
%   process_trajectory_data_40x( ...
%   a_cycleNum, a_deepCycle, ...
%   a_gpsData, a_iridiumMailData, ...
%   a_cycleTimeData, ...
%   a_selfTest, a_tech1, a_tech2, a_eol, ...
%   a_tabProfiles, a_parkDriftProf, a_desc2ProfProf, a_profDriftProf, a_inAirProf)
%
% INPUT PARAMETERS :
%   a_cycleNum        : current cycle number
%   a_deepCycle       : deep cycle flag
%   a_gpsData         : GPS data
%   a_iridiumMailData : Iridium mail contents
%   a_cycleTimeData   : cycle timings structure
%   a_selfTest        : self test tech data
%   a_tech1           : tech #1 data
%   a_tech2           : tech #2 data
%   a_eol             : EOL tech data
%   a_tabProfiles     : desc2park and asc profiles data
%   a_parkDriftProf   : parkDrift profile data
%   a_desc2ProfProf   : desc2Prof profile data
%   a_profDriftProf   : profDrift profile data
%   a_inAirProf       : inAir profile data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas    : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle   : N_CYCLE trajectory data
%   o_tabTechNMeas    : N_MEASUREMENT technical data
%   o_tabTechAuxNMeas : N_MEASUREMENT AUX technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/29/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
   process_trajectory_data_40x( ...
   a_cycleNum, a_deepCycle, ...
   a_gpsData, a_iridiumMailData, ...
   a_cycleTimeData, ...
   a_selfTest, a_tech1, a_tech2, a_eol, ...
   a_tabProfiles, a_parkDriftProf, a_desc2ProfProf, a_profDriftProf, a_inAirProf)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];
o_tabTechAuxNMeas = [];

% global measurement codes
global g_MC_CycleStartBis;
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
global g_MC_DriftAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_AscProfDeepestBin;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_TST;
global g_MC_Surface;
global g_MC_TET;
global g_MC_Grounded;
global g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;

% global time status
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_9;

% RPP status
global g_RPP_STATUS_1;

% default values
global g_decArgo_ncDateDef;

% float configuration
global g_decArgo_floatConfig;


% structure to store N_MEASUREMENT data
trajNMeasStruct = get_traj_n_meas_init_struct(a_cycleNum, -1);

% structure to store N_CYCLE data
trajNCycleStruct = get_traj_n_cycle_init_struct(a_cycleNum, -1);

% structure to store N_MEASUREMENT technical data
tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);
tabTechAuxNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);

% clock drift
floatClockDriftSec = '';
clockDriftKnown = ~isempty(a_cycleTimeData.cycleClockOffset);
if (clockDriftKnown == 1)
   floatClockDriftSec = a_cycleTimeData.cycleClockOffset(3);
end

paramJuld = get_netcdf_param_attributes('JULD');
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramPsal = get_netcdf_param_attributes('PSAL');

param200003 = get_netcdf_param_attributes('VOLUME_OilVolumeTransferredToAscentWhenGrounded_cm^3'); % TECH_TIME
% param200003 = get_netcdf_param_attributes('TECH_AUX_VOLUME_OilVolumeTransferredToAscentWhenGrounded_cm^3'); % TECH_AUX_TIME
param800202 = get_netcdf_param_attributes('TECH_AUX_VOLUME_PumpOilVolumeTransferred_cm^3');
param800302 = get_netcdf_param_attributes('TECH_AUX_VOLUME_ValveOilVolumeTransferred_cm^3');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% POSITIONING SYSTEM AND TRANSMISSION SYSTEM TIMES AND LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% First/last Message Time
% not available yet, set in process_delayed_data_pfv2

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
trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; surfaceLocData];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IRIDIUM LOCATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% not available yet, set in process_delayed_data_pfv2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IN AIR MEASUREMENTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for idProf = 1:length(a_inAirProf)
   inAirProf = a_inAirProf(idProf);

   for idMeas = 1:size(inAirProf.data, 1)
      if (~isempty(inAirProf.dates) && ...
            (inAirProf.dates(idMeas) ~= paramJuld.fillValue))
         if (inAirProf.datesTransFlag(idMeas) == 0)
            measTimeStatus = g_JULD_STATUS_1;
         else
            measTimeStatus = g_JULD_STATUS_2;
         end
         if (~isempty(inAirProf.datesAdj) && ...
               (inAirProf.datesAdj(idMeas) ~= paramJuld.fillValue))
            measTimeAdj = inAirProf.datesAdj(idMeas);
         else
            measTimeAdj = nan;
         end
         [measStruct, ~] = create_one_meas_float_time_pfv2( ...
            g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST, ...
            inAirProf.dates(idMeas), measTimeStatus, measTimeAdj);
      else
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_InAirSeriesOfMeasPartOfSurfaceSequenceRelativeToTST;
      end

      % add parameter variables to the structure
      measStruct.paramList = inAirProf.paramList;
      measStruct.paramData = inAirProf.data(idMeas, :);
      if (~isempty(inAirProf.dataAdj))
         measStruct.paramDataAdj = inAirProf.dataAdj(idMeas, :);
      end

      trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   end
end

% clock offset
if (~isempty(floatClockDriftSec))
   trajNCycleStruct.clockOffset = floatClockDriftSec/86400;
   trajNCycleStruct.dataMode = 'A';
else
   trajNCycleStruct.dataMode = 'R';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% miscellaneous measurements from technical message

if (~isempty(a_tech2) && ~isempty(a_tech2{3}))

   % grounding information
   grounded = 'N';
   if (~isempty(a_cycleTimeData.groundingDate))
      for idG = 1:length(a_cycleTimeData.groundingDate)

         [measStruct, ~] = create_one_meas_float_time_pfv2( ...
            g_MC_Grounded, ...
            a_cycleTimeData.groundingDate(idG), g_JULD_STATUS_2, a_cycleTimeData.groundingDateAdj(idG));

         paramPresGrd = paramPres;
         paramPresGrd.resolution = single(0.1);
         measStruct.paramList = paramPresGrd;
         measStruct.paramData = a_cycleTimeData.groundingPres(idG);

         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

         measStruct.paramList = param200003;
         measStruct.paramData = a_cycleTimeData.groundingOil(idG);

         tabTechNMeas.tabMeas = [tabTechNMeas.tabMeas; measStruct];
      end

      grounded = 'Y';
   end

   trajNCycleStruct.grounded = grounded;
end

if (a_deepCycle == 1)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % FLOAT CYCLE TIMES
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   

   % for PFV2, nan is the default value in a_cycleTimeData for date and date Adj,
   % except for gpsDate, eolStartDate, groundingDate and emergencyAscentDate

   % Cycle Start Time (i.e. buoyancy reduction start time for this float type)
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_CycleStartBis, ...
      a_cycleTimeData.cycleStartDate, g_JULD_STATUS_2, a_cycleTimeData.cycleStartDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

   trajNCycleStruct.juldCycleStart = nCycleTime;
   trajNCycleStruct.juldCycleStartStatus = g_JULD_STATUS_2;
   
   % Descent Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_DST, ...
      a_cycleTimeData.descentToParkStartDate, g_JULD_STATUS_2, a_cycleTimeData.descentToParkStartDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldDescentStart = nCycleTime;
   trajNCycleStruct.juldDescentStartStatus = g_JULD_STATUS_2;
   
   % First Stabilization Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_FST, ...
      a_cycleTimeData.firstStabDate, g_JULD_STATUS_2, a_cycleTimeData.firstStabDateAdj);
   if (~isnan(a_cycleTimeData.firstStabPres))
      paramPresFst = paramPres;
      paramPresFst.resolution = single(0.1);
      measStruct.paramList = paramPresFst;
      measStruct.paramData = a_cycleTimeData.firstStabPres;
   end
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldFirstStab = nCycleTime;
   trajNCycleStruct.juldFirstStabStatus = g_JULD_STATUS_2;

   % Park Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_PST, ...
      a_cycleTimeData.descentToParkEndDate, g_JULD_STATUS_2, a_cycleTimeData.descentToParkEndDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldParkStart = nCycleTime;
   trajNCycleStruct.juldParkStartStatus = g_JULD_STATUS_2;

   % Park End Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_PET, ...
      a_cycleTimeData.descentToProfStartDate, g_JULD_STATUS_2, a_cycleTimeData.descentToProfStartDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldParkEnd = nCycleTime;
   trajNCycleStruct.juldParkEndStatus = g_JULD_STATUS_2;

   % Deep Park Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_DPST, ...
      a_cycleTimeData.descentToProfEndDate, g_JULD_STATUS_2, a_cycleTimeData.descentToProfEndDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldDeepParkStart = nCycleTime;
   trajNCycleStruct.juldDeepParkStartStatus = g_JULD_STATUS_2;

   % Ascent Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_AST, ...
      a_cycleTimeData.ascentStartDate, g_JULD_STATUS_2, a_cycleTimeData.ascentStartDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldAscentStart = nCycleTime;
   trajNCycleStruct.juldAscentStartStatus = g_JULD_STATUS_2;

   % Ascent End Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_AET, ...
      a_cycleTimeData.ascentEndDate, g_JULD_STATUS_2, a_cycleTimeData.ascentEndDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldAscentEnd = nCycleTime;
   trajNCycleStruct.juldAscentEndStatus = g_JULD_STATUS_2;

   % Transmission Start Time
   [measStruct, nCycleTime] = create_one_meas_float_time_pfv2( ...
      g_MC_TST, ...
      a_cycleTimeData.transStartDate, g_JULD_STATUS_2, a_cycleTimeData.transStartDateAdj);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldTransmissionStart = nCycleTime;
   trajNCycleStruct.juldTransmissionStartStatus = g_JULD_STATUS_2;

   % Transmission End Time
   % temporary set to nan (because mandatory) and updated in process_delayed_data_pfv2
   [measStruct, ~] = create_one_meas_float_time_pfv2( ...
      g_MC_TET, ...
      nan, g_JULD_STATUS_9, nan);
   trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
   
   trajNCycleStruct.juldTransmissionEnd = g_decArgo_ncDateDef;
   trajNCycleStruct.juldTransmissionEndStatus = g_JULD_STATUS_9;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROFILE DATED BINS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   for idProf = 1:length(a_tabProfiles)
      profile = a_tabProfiles(idProf);

      if (~isempty(profile.dates))
         if (profile.direction == 'A')
            measCode = g_MC_AscProf;
         else
            measCode = g_MC_DescProf;
         end

         for idMeas = 1:size(profile.data, 1)
            if (profile.dates(idMeas) ~= paramJuld.fillValue)
               if (~isempty(profile.datesAdj) && ...
                     (profile.datesAdj(idMeas) ~= paramJuld.fillValue))
                  measTimeAdj = profile.datesAdj(idMeas);
               else
                  measTimeAdj = nan;
               end
               [measStruct, ~] = create_one_meas_float_time_pfv2( ...
                  measCode, ...
                  profile.dates(idMeas), g_JULD_STATUS_2, measTimeAdj);

               % add parameter variables to the structure
               measStruct.paramList = profile.paramList;
               measStruct.paramData = profile.data(idMeas, :);
               if (~isempty(profile.dataAdj))
                  measStruct.paramDataAdj = profile.dataAdj(idMeas, :);
               end

               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MEASUREMENTS SAMPLED DURING THE DRIFT AT PARKING DEPTH
   % AND
   % REPRESENTATIVE PARKING MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   for idProf = 1:length(a_parkDriftProf)
      parkDriftProf = a_parkDriftProf(idProf);

      for idMeas = 1:size(parkDriftProf.data, 1)
         if (~isempty(parkDriftProf.dates) && ...
               (parkDriftProf.dates(idMeas) ~= paramJuld.fillValue))
            if (parkDriftProf.datesTransFlag(idMeas) == 0)
               measTimeStatus = g_JULD_STATUS_1;
            else
               measTimeStatus = g_JULD_STATUS_2;
            end
            if (~isempty(parkDriftProf.datesAdj) && ...
                  (parkDriftProf.datesAdj(idMeas) ~= paramJuld.fillValue))
               measTimeAdj = parkDriftProf.datesAdj(idMeas);
            else
               measTimeAdj = nan;
            end
            [measStruct, ~] = create_one_meas_float_time_pfv2( ...
               g_MC_DriftAtPark, ...
               parkDriftProf.dates(idMeas), measTimeStatus, measTimeAdj);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_DriftAtPark;
         end

         % add parameter variables to the structure
         measStruct.paramList = parkDriftProf.paramList;
         measStruct.paramData = parkDriftProf.data(idMeas, :);
         if (~isempty(parkDriftProf.dataAdj))
            measStruct.paramDataAdj = parkDriftProf.dataAdj(idMeas, :);
         end

         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end

      % compute the RPP
      if (parkDriftProf.payloadSensorNumber ~= 2)
         idPres = find(strcmp({parkDriftProf.paramList.name}, 'PRES'));
         idTemp = find(strcmp({parkDriftProf.paramList.name}, 'TEMP'));
         idPsal = find(strcmp({parkDriftProf.paramList.name}, 'PSAL'));
         if (~isempty(idPres) && ~isempty(idTemp) && ~isempty(idPsal))

            idForMean = find((parkDriftProf.data(:, idPres) ~= paramPres.fillValue) & ...
               (parkDriftProf.data(:, idTemp) ~= paramTemp.fillValue) & ...
               (parkDriftProf.data(:, idPsal) ~= paramPsal.fillValue));
            if (~isempty(idForMean))

               measStruct = get_traj_one_meas_init_struct();
               measStruct.measCode = g_MC_RPP;
               measStruct.paramList = [paramPres paramTemp paramPsal];
               measStruct.paramData = mean([ ...
                  parkDriftProf.data(idForMean, idPres), ...
                  parkDriftProf.data(idForMean, idTemp), ...
                  parkDriftProf.data(idForMean, idPsal)], 1);

               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

               trajNCycleStruct.repParkPres = measStruct.paramData(1);
               trajNCycleStruct.repParkPresStatus = g_RPP_STATUS_1;
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MEASUREMENTS SAMPLED DURING THE DESCENT TO PROF PHASE
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   for idProf = 1:length(a_desc2ProfProf)
      desc2ProfProf = a_desc2ProfProf(idProf);

      for idMeas = 1:size(desc2ProfProf.data, 1)
         if (~isempty(desc2ProfProf.dates) && ...
               (desc2ProfProf.dates(idMeas) ~= paramJuld.fillValue))
            if (~isempty(desc2ProfProf.datesAdj) && ...
                  (desc2ProfProf.datesAdj(idMeas) ~= paramJuld.fillValue))
               measTimeAdj = desc2ProfProf.datesAdj(idMeas);
            else
               measTimeAdj = nan;
            end
            [measStruct, ~] = create_one_meas_float_time_pfv2( ...
               g_MC_Desc2Prof, ...
               desc2ProfProf.dates(idMeas), g_JULD_STATUS_2, measTimeAdj);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_Desc2Prof;
         end

         % add parameter variables to the structure
         measStruct.paramList = desc2ProfProf.paramList;
         measStruct.paramData = desc2ProfProf.data(idMeas, :);
         if (~isempty(desc2ProfProf.dataAdj))
            measStruct.paramDataAdj = desc2ProfProf.dataAdj(idMeas, :);
         end

         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MEASUREMENTS SAMPLED DURING THE DRIFT AT PROFILE DEPTH
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   for idProf = 1:length(a_profDriftProf)
      profDriftProf = a_profDriftProf(idProf);

      for idMeas = 1:size(profDriftProf.data, 1)
         if (~isempty(profDriftProf.dates) && ...
               (profDriftProf.dates(idMeas) ~= paramJuld.fillValue))
            if (profDriftProf.datesTransFlag(idMeas) == 0)
               measTimeStatus = g_JULD_STATUS_1;
            else
               measTimeStatus = g_JULD_STATUS_2;
            end
            if (~isempty(profDriftProf.datesAdj) && ...
                  (profDriftProf.datesAdj(idMeas) ~= paramJuld.fillValue))
               measTimeAdj = profDriftProf.datesAdj(idMeas);
            else
               measTimeAdj = nan;
            end
            [measStruct, ~] = create_one_meas_float_time_pfv2( ...
               g_MC_DriftAtProf, ...
               profDriftProf.dates(idMeas), measTimeStatus, measTimeAdj);
         else
            measStruct = get_traj_one_meas_init_struct();
            measStruct.measCode = g_MC_DriftAtProf;
         end

         % add parameter variables to the structure
         measStruct.paramList = profDriftProf.paramList;
         measStruct.paramData = profDriftProf.data(idMeas, :);
         if (~isempty(profDriftProf.dataAdj))
            measStruct.paramDataAdj = profDriftProf.dataAdj(idMeas, :);
         end

         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % SPY MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   if (~isempty(a_tech2) && (~isempty(a_tech2{4}) || ~isempty(a_tech2{5})))

         % assign a MC to each cycle timing
         phaseDates = [];
         phaseMeasCode = [];
         if (~isnan(a_cycleTimeData.descentToParkStartDate))
            phaseDates = [phaseDates a_cycleTimeData.descentToParkStartDate];
            phaseMeasCode = [phaseMeasCode g_MC_DST];
         end
         if (~isnan(a_cycleTimeData.descentToParkEndDate))
            phaseDates = [phaseDates a_cycleTimeData.descentToParkEndDate];
            phaseMeasCode = [phaseMeasCode g_MC_PST];
         end
         if (~isnan(a_cycleTimeData.descentToProfStartDate))
            phaseDates = [phaseDates a_cycleTimeData.descentToProfStartDate];
            phaseMeasCode = [phaseMeasCode g_MC_PET];
         end
         if (~isnan(a_cycleTimeData.descentToProfEndDate))
            phaseDates = [phaseDates a_cycleTimeData.descentToProfEndDate];
            phaseMeasCode = [phaseMeasCode g_MC_DPST];
         end
         if (~isnan(a_cycleTimeData.ascentStartDate))
            phaseDates = [phaseDates a_cycleTimeData.ascentStartDate];
            phaseMeasCode = [phaseMeasCode g_MC_AST];
         end
         if (~isnan(a_cycleTimeData.ascentEndDate))
            phaseDates = [phaseDates a_cycleTimeData.ascentEndDate];
            phaseMeasCode = [phaseMeasCode g_MC_AET];
         end
         if (~isnan(a_cycleTimeData.transStartDate))
            phaseDates = [phaseDates a_cycleTimeData.transStartDate];
            phaseMeasCode = [phaseMeasCode g_MC_TST];
         end
         [phaseDates, idSort] = sort(phaseDates);
         phaseMeasCode = phaseMeasCode(idSort);
   end

   if (~isempty(a_tech2) && ~isempty(a_tech2{5}))

      tabTechSpy = a_tech2{5};

      % sort spy measurements according to their dates
      spyJuld = [tabTechSpy.julD];
      [~, idSort] = sort(spyJuld);
      tabTechSpy = tabTechSpy(idSort);
      spyJuld = [tabTechSpy.julD];
      spyJuldAdj = [tabTechSpy.julDAdj];

      % assign a MC to each set of spy measurements
      for idPhase = 1:length(phaseDates)

         if (idPhase  == 1)
            idData = find(spyJuld <= phaseDates(idPhase));
         else
            idData = find((spyJuld > phaseDates(idPhase-1)) & ...
               (spyJuld <= phaseDates(idPhase)));
         end
         measCode = phaseMeasCode(idPhase) - 10;

         for idM = 1:length(idData)
            idMeas = idData(idM);

            if (~isempty(spyJuldAdj) && ~isnan(spyJuldAdj(idMeas)))
               measTimeAdj = spyJuldAdj(idMeas);
            else
               measTimeAdj = nan;
            end
            [measStruct, ~] = create_one_meas_float_time_pfv2( ...
               measCode, ...
               spyJuld(idMeas), g_JULD_STATUS_2, measTimeAdj);

            paramPresSpy = paramPres;
            paramPresSpy.resolution = single(0.1);
            measStruct.paramList = paramPresSpy;
            measStruct.paramData = tabTechSpy(idMeas).pres;

            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % HYDRAULIC ACTIONS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   if (~isempty(a_tech2) && ~isempty(a_tech2{4}))

      tabTechBuoy = a_tech2{4};

      % sort buoy measurements according to their dates
      buoyJuld = [tabTechBuoy.julD];
      [~, idSort] = sort(buoyJuld);
      tabTechBuoy = tabTechBuoy(idSort);
      buoyJuld = [tabTechBuoy.julD];
      buoyJuldAdj = [tabTechBuoy.julDAdj];

      % assign a MC to each set of buoy measurements
      for idPhase = 1:length(phaseDates)

         if (idPhase  == 1)
            idData = find(buoyJuld <= phaseDates(idPhase));
         else
            idData = find((buoyJuld > phaseDates(idPhase-1)) & ...
               (buoyJuld <= phaseDates(idPhase)));
         end
         measCode = phaseMeasCode(idPhase) - 11;

         for idM = 1:length(idData)
            idMeas = idData(idM);

            if (~isempty(buoyJuldAdj) && ~isnan(buoyJuldAdj(idMeas)))
               measTimeAdj = buoyJuldAdj(idMeas);
            else
               measTimeAdj = nan;
            end
            [measStruct, ~] = create_one_meas_float_time_pfv2( ...
               measCode, ...
               buoyJuld(idMeas), g_JULD_STATUS_2, measTimeAdj);

            paramPresBuoy = paramPres;
            paramPresBuoy.resolution = single(0.1);
            measStruct.paramList = paramPresBuoy;
            measStruct.paramData = tabTechBuoy(idMeas).pres;

            trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];

            if (tabTechBuoy(idMeas).techId == 800200)
               paramBuoy = param800202;
            elseif (tabTechBuoy(idMeas).techId == 800300)
               paramBuoy = param800302;
            end
            measStruct.paramList = paramBuoy;
            measStruct.paramData = tabTechBuoy(idMeas).oil;

            tabTechAuxNMeas.tabMeas = [tabTechAuxNMeas.tabMeas; measStruct];
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % MISCELLANEOUS MEASUREMENTS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % deepest bin of the descending and ascending profiles

   if (~isempty(a_tabProfiles))
      for dir = 'DA'
         profList = find([a_tabProfiles.direction] == dir);
         if (~isempty(profList))

            if (dir == 'A')
               measCode = g_MC_AscProfDeepestBin;
            else
               measCode = g_MC_DescProfDeepestBin;
            end

            presMax = nan;
            profPresMax = nan;
            levPresMax = nan;
            for idProf = 1:length(profList)
               profile = a_tabProfiles(profList(idProf));
               idPres = find(strcmp({profile.paramList.name}, 'PRES'));
               if (~isempty(idPres))
                  profPres = profile.data(:, idPres);
                  idNotDef = find(profPres ~= paramPres.fillValue);
                  if (dir == 'A')
                     idDeepest = idNotDef(1);
                  else
                     idDeepest = idNotDef(end);
                  end
                  if (isnan(presMax) || (profile.data(idDeepest, idPres) > presMax))
                     presMax = profile.data(idDeepest, idPres);
                     profPresMax = profile;
                     levPresMax = idDeepest;
                  end
               end
            end

            if (~isnan(presMax))

               if (~isempty(profPresMax.dates) && ...
                     (profPresMax.dates(levPresMax) ~= paramJuld.fillValue))
                  if (~isempty(profPresMax.datesAdj) && ...
                        (profPresMax.datesAdj(levPresMax) ~= paramJuld.fillValue))
                     measTimeAdj = profPresMax.datesAdj(levPresMax);
                  else
                     measTimeAdj = nan;
                  end
                  [measStruct, ~] = create_one_meas_float_time_pfv2( ...
                     measCode, ...
                     profPresMax.dates(levPresMax), g_JULD_STATUS_2, measTimeAdj);
               else
                  measStruct = get_traj_one_meas_init_struct();
                  measStruct.measCode = measCode;
               end

               % add parameter variables to the structure
               measStruct.paramList = profPresMax.paramList;
               measStruct.paramData = profPresMax.data(levPresMax, :);
               if (~isempty(profPresMax.dataAdj))
                  measStruct.paramDataAdj = profPresMax.dataAdj(levPresMax, :);
               end

               trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % miscellaneous measurements from technical message

   if (~isempty(a_tech2) && ~isempty(a_tech2{3}))

      tabTechTraj = a_tech2{3};

      % max pressure in descent to parking depth
      idF = find([tabTechTraj.techId] == 100503);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDescToPark;
         paramPresCur = paramPres;
         paramPresCur.resolution = single(0.1);
         measStruct.paramList = paramPresCur;
         measStruct.paramData = tabTechTraj(idF).pres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end

      % min/max pressure in drift at parking depth
      idF = find([tabTechTraj.techId] == 100901);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MinPresInDriftAtPark;
         paramPresCur = paramPres;
         paramPresCur.resolution = single(0.1);
         measStruct.paramList = paramPresCur;
         measStruct.paramData = tabTechTraj(idF).pres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      idF = find([tabTechTraj.techId] == 100902);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDriftAtPark;
         paramPresCur = paramPres;
         paramPresCur.resolution = single(0.1);
         measStruct.paramList = paramPresCur;
         measStruct.paramData = tabTechTraj(idF).pres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end

      % max pressure in descent to profile depth
      idF = find([tabTechTraj.techId] == 100703);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDescToProf;
         paramPresCur = paramPres;
         paramPresCur.resolution = single(0.1);
         measStruct.paramList = paramPresCur;
         measStruct.paramData = tabTechTraj(idF).pres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end

      % min/max pressure in drift at profile depth
      idF = find([tabTechTraj.techId] == 101101);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MinPresInDriftAtProf;
         paramPresCur = paramPres;
         paramPresCur.resolution = single(0.1);
         measStruct.paramList = paramPresCur;
         measStruct.paramData = tabTechTraj(idF).pres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end
      idF = find([tabTechTraj.techId] == 101102);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_MaxPresInDriftAtProf;
         paramPresCur = paramPres;
         paramPresCur.resolution = single(0.1);
         measStruct.paramList = paramPresCur;
         measStruct.paramData = tabTechTraj(idF).pres;
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end

      % last pumped CTD measurement
      idF = find([tabTechTraj.techId] == 500000);
      if (~isempty(idF))
         measStruct = get_traj_one_meas_init_struct();
         measStruct.measCode = g_MC_LastAscPumpedCtd;
         measStruct.paramList = [paramPres paramTemp paramPsal];
         measStruct.paramData = [tabTechTraj(idF).pres, tabTechTraj(idF).temp, tabTechTraj(idF).psal];
         trajNMeasStruct.tabMeas = [trajNMeasStruct.tabMeas; measStruct];
      end      
   end

else

   trajNMeasStruct.surfOnly = 1;
   trajNCycleStruct.surfOnly = 1;

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
if (isempty(tabTechNMeas.tabMeas))
   tabTechNMeas = [];
end
o_tabTechNMeas = tabTechNMeas;
if (isempty(tabTechAuxNMeas.tabMeas))
   tabTechAuxNMeas = [];
end
o_tabTechAuxNMeas = tabTechAuxNMeas;

return
