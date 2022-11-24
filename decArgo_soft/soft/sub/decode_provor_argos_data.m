
% ------------------------------------------------------------------------------
% Decode PROVOR Argos messages.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, ...
%    o_structConfig] = decode_provor_argos_data( ...
%    a_floatNum, a_cycleList, a_excludedCycleList, ...
%    a_decoderId, a_floatArgosId, ...
%    a_frameLength, a_cycleTime, a_driftSamplingPeriod, ...
%    a_delay, a_refDay, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum            : float WMO number
%   a_cycleList           : list of cycles to be decoded
%   a_excludedCycleList   : list of not decoded existing cycles
%   a_decoderId           : float decoder Id
%   a_floatArgosId        : float PTT number
%   a_frameLength         : Argos data frame length
%   a_cycleTime           : cycle duration
%   a_driftSamplingPeriod : sampling period during drift phase (in hours)
%   a_delay               : DELAI parameter (in hours)
%   a_refDay              : reference day (day of the first descent)
%   a_floatEndDate        : end date of the data to process
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : decoded profiles
%   o_tabTrajNMeas   : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : decoded technical index information
%   o_tabNcTechVal   : decoded technical data
%   o_structConfig   : NetCDF float configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, ...
   o_structConfig] = decode_provor_argos_data( ...
   a_floatNum, a_cycleList, a_excludedCycleList, ...
   a_decoderId, a_floatArgosId, ...
   a_frameLength, a_cycleTime, a_driftSamplingPeriod, ...
   a_delay, a_refDay, a_floatEndDate)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_structConfig = [];

% current float WMO number
global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_presDef;

% configuration creation flag
global g_decArgo_configDone;
g_decArgo_configDone = 0;

% float configuration
global g_decArgo_floatConfig;

% array to store surface data of Argos floats
global g_decArgo_floatSurfData;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;

% Argos error ellipses storage
global g_decArgo_addErrorEllipses;


% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Info type'];
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% initialize float configuration
init_float_config_prv_argos(a_decoderId);
if (~ismember(a_decoderId, [30 32]))
   if (isempty(g_decArgo_floatConfig))
      return
   end
end

% inits for output NetCDF file
decArgoConfParamNames = [];
ncConfParamNames = [];
if (isempty(g_decArgo_outputCsvFileId))
   
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   
   % TRAJ and PROF NetCDF file (we need REPETITION_RATE information to
   % fill CONFIG_MISSION_NUMBER of the TRAJ file)
   % retrieve REPETITION_RATE from json meta-data file
   wantedMetaNames = [ ...
      {'CONFIG_REPETITION_RATE'} ...
      ];
   [repRateMetaData] = get_meta_data_from_json_file(a_floatNum, wantedMetaNames);
   
   % create the configuration parameter names for the META NetCDF file
   [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_argos(a_decoderId);
else
   
   % print DOXY coef in the output CSV file
   print_calib_coef_in_csv(a_decoderId);
end

% get the list of bits to freeze for this decoder Id
[bitsToFreeze] = get_bits_to_freeze(a_decoderId);

% decode each Argos file of the cycle list
for idCy = 1:length(a_cycleList)
   
   % main dates of the cycle
   cycleStartDate = g_decArgo_dateDef;
   descentStartDate = g_decArgo_dateDef;
   firstStabDate = g_decArgo_dateDef;
   firstStabPres = g_decArgo_presDef;
   descentEndDate = g_decArgo_dateDef;
   descentToProfStartDate = g_decArgo_dateDef;
   descentToProfEndDate = g_decArgo_dateDef;
   ascentStartDate = g_decArgo_dateDef;
   ascentEndDate = g_decArgo_dateDef;
   transStartDate = g_decArgo_dateDef;
   firstGroundingDate = g_decArgo_dateDef;
   firstGroundingPres = g_decArgo_presDef;
   firstEmergencyAscentDate = g_decArgo_dateDef;
   firstEmergencyAscentPres = g_decArgo_presDef;

   cycleNum = a_cycleList(idCy);
   g_decArgo_cycleNum = cycleNum;
   
   fprintf('Cycle #%d\n', cycleNum);
   
   % update the float surface data structure with the previous excluded cycles
   if (~isempty(find((a_excludedCycleList < cycleNum) & ...
         (a_excludedCycleList > g_decArgo_floatSurfData.updatedForCycleNumber), 1)))
      [g_decArgo_floatSurfData] = update_previous_cycle_surf_data( ...
         g_decArgo_floatSurfData, a_floatArgosId, a_floatNum, a_frameLength, ...
         a_excludedCycleList, cycleNum);
   end
   
   % get the Argos file name(s) for this cycle
   [argosPathFileName, unused] = get_argos_path_file_name(a_floatArgosId, a_floatNum, cycleNum, a_floatEndDate);
   if (isempty(argosPathFileName))
      fprintf('INFO: Float #%d Cycle #%d: not processed according to float end date restriction\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      continue
   end
   
   % read the Argos file and select the data
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataDate, argosDataData, sensors, sensorDates, ...
      lastArgosCtdMsgDate, ...
      surfTempDate, surfTempVal] = ...
      get_prv_data(argosPathFileName, a_floatArgosId, a_frameLength, bitsToFreeze, a_decoderId);

   % retrieve the previous cycle surface information
   [prevCycleNum, lastLocDate, lastLocLon, lastLocLat, lastMsgDate] = ...
      get_previous_cycle_surf_data(g_decArgo_floatSurfData, cycleNum);
   
   % compute the JAMSTEC QC for the cycle locations
   lastLocDateOfPrevCycle = g_decArgo_dateDef;
   lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
   lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
   lastArgosMsgDateOfPrevCycle = g_decArgo_dateDef;
   if (~isempty(prevCycleNum))
      if (prevCycleNum == cycleNum-1)
         lastLocDateOfPrevCycle = lastLocDate;
         lastLocLonOfPrevCycle = lastLocLon;
         lastLocLatOfPrevCycle = lastLocLat;
         lastArgosMsgDateOfPrevCycle = lastMsgDate;
      end
   end
   [argosLocQc] = compute_jamstec_qc( ...
      argosLocDate, argosLocLon, argosLocLat, argosLocAcc, ...
      lastLocDateOfPrevCycle, lastLocLonOfPrevCycle, lastLocLatOfPrevCycle, []);
   
   % initialize the cycle surface data structure
   cycleSurfData = get_cycle_surf_data_init_struct;
   
   % store the cycle surface data in the structure
   cycleSurfData.firstMsgTime = min([argosLocDate; argosDataDate]);
   cycleSurfData.lastMsgTime = max([argosLocDate; argosDataDate]);
   cycleSurfData.lastCtdMsgTime = lastArgosCtdMsgDate;
   cycleSurfData.argosLocDate = argosLocDate;
   cycleSurfData.argosLocLon = argosLocLon;
   cycleSurfData.argosLocLat = argosLocLat;
   cycleSurfData.argosLocAcc = argosLocAcc;
   cycleSurfData.argosLocSat = argosLocSat;
   cycleSurfData.argosLocQc = argosLocQc;
   
   % update the float surface data structure
   g_decArgo_floatSurfData.cycleNumbers = [g_decArgo_floatSurfData.cycleNumbers cycleNum];
   g_decArgo_floatSurfData.cycleData = [g_decArgo_floatSurfData.cycleData cycleSurfData];
   g_decArgo_floatSurfData.updatedForCycleNumber = cycleNum;
     
   % decode the selected data according to decoder Id
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      case {1, 3, 11, 12, 17, 24, 31} % V4.2 & V4.5 & V4.21 & V4.22 & V4.51 & V4.23 & V4.53
         
         % decode CTD and technical messages
         [tabProfCTD, tabDriftCTD, tabTech, floatClockDrift, meanParkPres, maxProfPres] = ...
            decode_prv_data_1_3_11_12_17_24_31(sensors, sensorDates, a_decoderId);
         
         if (~isempty(tabTech))
            
            % pressure associated with the first stabilization time
            firstStabPres = tabTech(4);
            
            % determine the main dates of the cycle
            [descentStartDate, firstStabDate, descentEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, transStartDate] = ...
               compute_prv_dates_1_3_4_11_12_17_19_24_25_27_to_29_31( ...
               tabTech, floatClockDrift, ...
               g_decArgo_floatSurfData.launchDate, a_refDay, a_cycleTime, ...
               a_driftSamplingPeriod, meanParkPres, maxProfPres, ...
               g_decArgo_floatSurfData.cycleData(end).firstMsgTime, ...
               g_decArgo_floatSurfData.cycleData(end).lastCtdMsgTime, ...
               lastArgosMsgDateOfPrevCycle, ...
               a_decoderId);
            
            % in ASFAR mode don't consider descending dates of the first cycle
            if ((a_decoderId == 31) && (cycleNum == 1))
               descentStartDate = g_decArgo_dateDef;
               firstStabDate = g_decArgo_dateDef;
               descentEndDate = g_decArgo_dateDef;
               descentToProfStartDate = g_decArgo_dateDef;
               descentToProfEndDate = g_decArgo_dateDef;
               
               % pressure associated with the first stabilization time
               firstStabPres = g_decArgo_presDef;
            end
            
            % create drift data set
            nbDriftMeas = tabTech(18);
            if ((a_decoderId == 3) || (a_decoderId == 17) || ...
                  (a_decoderId == 24) || (a_decoderId == 31))
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
                  create_prv_drift_3_17_24_31(tabDriftCTD, nbDriftMeas, ...
                  descentStartDate, floatClockDrift, ...
                  descentEndDate, descentToProfStartDate, ...
                  a_driftSamplingPeriod);
            else
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
                  create_prv_drift_1_11_12(tabDriftCTD, nbDriftMeas, a_refDay, ...
                  descentEndDate, descentToProfStartDate, ...
                  ascentStartDate, a_driftSamplingPeriod);
            end
            
            if (isempty(parkDate))
               % determination of drift measurement dates failed
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
                  create_prv_drift_without_dates_1_3_11_12_17_24_30_31(tabDriftCTD);
            end
            
         else
            
            if (~isempty(tabDriftCTD))
               fprintf('WARNING: Float #%d Cycle #%d: technical message not received - unable to define drift measurements order\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            elseif (~isempty(tabProfCTD))
               fprintf('WARNING: Float #%d Cycle #%d: technical message not received\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            end
            
            % float clock drift can't be determined
            floatClockDrift = [];
            
            % the main dates of the cycle can't be determined
            
            % create drift data set
            [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
               create_prv_drift_without_dates_1_3_11_12_17_24_30_31(tabDriftCTD);
         end
         
         % create descending and ascending profiles
         [descProfOcc, descProfDate, descProfPres, descProfTemp, descProfSal, ...
            ascProfOcc, ascProfDate, ascProfPres, ascProfTemp, ascProfSal] = ...
            create_prv_profile_1_3_11_12_17_24_29_30_31(tabProfCTD, tabTech, descentStartDate, ascentStartDate);
         
         % convert counts to physical values
         [descProfPres] = sensor_2_value_for_pressure_argos(descProfPres);
         [parkPres] = sensor_2_value_for_pressure_argos(parkPres);
         [ascProfPres] = sensor_2_value_for_pressure_argos(ascProfPres);
         [descProfTemp] = sensor_2_value_for_temperature_argos(descProfTemp);
         [parkTemp] = sensor_2_value_for_temperature_argos(parkTemp);
         [ascProfTemp] = sensor_2_value_for_temperature_argos(ascProfTemp);
         [descProfSal] = sensor_2_value_for_salinity_argos(descProfSal);
         [parkSal] = sensor_2_value_for_salinity_argos(parkSal);
         [ascProfSal] = sensor_2_value_for_salinity_argos(ascProfSal);
         
         % take float clock drift into account to correct float dates
         if (~isempty(floatClockDrift))
            [descentStartDate] = add_clock_drift_in_date(descentStartDate, floatClockDrift);
            [firstStabDate] = add_clock_drift_in_date(firstStabDate, floatClockDrift);
            [descentEndDate] = add_clock_drift_in_date(descentEndDate, floatClockDrift);
            [descentToProfStartDate] = add_clock_drift_in_date(descentToProfStartDate, floatClockDrift);
            [descentToProfEndDate] = add_clock_drift_in_date(descentToProfEndDate, floatClockDrift);
            [ascentStartDate] = add_clock_drift_in_date(ascentStartDate, floatClockDrift);
            [ascentEndDate] = add_clock_drift_in_date(ascentEndDate, floatClockDrift);
            [transStartDate] = add_clock_drift_in_date(transStartDate, floatClockDrift);
            
            [descProfDate] = add_clock_drift_in_date(descProfDate, floatClockDrift);
            [parkDate] = add_clock_drift_in_date(parkDate, floatClockDrift);
            [ascProfDate] = add_clock_drift_in_date(ascProfDate, floatClockDrift);
         end
         
         % store surface times in the float surface data structure
         [g_decArgo_floatSurfData] = set_surf_data(g_decArgo_floatSurfData, cycleNum, ...
            descentStartDate, ascentEndDate, transStartDate);
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            if (~isempty(tabTech))
               print_dates_in_csv_file_1_3_4_11_12_17_19_24_25_27_to_29_31( ...
                  floatClockDrift, lastArgosMsgDateOfPrevCycle, ...
                  descentStartDate, firstStabDate, firstStabPres, descentEndDate, ...
                  descentToProfStartDate, descentToProfEndDate, ascentStartDate, ...
                  ascentEndDate, transStartDate, argosLocDate, argosDataDate, ...
                  descProfDate, descProfPres, ...
                  parkDate, parkTransDate, parkPres, ...
                  ascProfDate, ascProfPres);
            end
            print_descending_profile_in_csv_file_1_3_11_12_17_24_30_31( ...
               descProfOcc, descProfDate, ...
               descProfPres, descProfTemp, descProfSal);
            print_drift_measurements_in_csv_file_1_3_11_12_17_24_30_31( ...
               parkOcc, parkDate, parkTransDate, ...
               parkPres, parkTemp, parkSal);
            print_ascending_profile_in_csv_file_1_3_11_12_17_24_30_31( ...
               ascProfOcc, ascProfDate, ...
               ascProfPres, ascProfTemp, ascProfSal);         
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            % process profile data for PROF NetCDF file
            [cycleProfiles] = process_profiles_1_3_11_12_17_24_30_31( ...
               g_decArgo_floatSurfData, cycleNum, ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               repRateMetaData, a_decoderId, tabTech);
            
            % add the vertical sampling scheme from configuration information
            [cycleProfiles] = add_vertical_sampling_scheme_argos(cycleProfiles, a_decoderId);
            
            print = 0;
            if (print == 1)
               if (~isempty(cycleProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(cycleProfiles));
                  for idP = 1:length(cycleProfiles)
                     prof = cycleProfiles(idP);
                     paramList = prof.paramList;
                     paramList = sprintf('%s ', paramList.name);
                     profLength = size(prof.data, 1);
                     fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
                        idP, prof.profileNumber, prof.direction, ...
                        profLength, paramList(1:end-1));
                  end
               else
                  fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            o_tabProfiles = [o_tabProfiles cycleProfiles];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
            
            addLaunchData = 0;
            if (isempty(o_tabTrajNMeas))
               % add the float launch position and date
               addLaunchData = 1;
            end
            
            % process trajectory data for TRAJ NetCDF file
            [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_1_3_11_12_17_24_31( ...
               cycleNum, ...
               addLaunchData, g_decArgo_floatSurfData, ...
               floatClockDrift, ...
               descentStartDate, firstStabDate,  firstStabPres, descentEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, transStartDate, ...
               cycleProfiles, ...
               parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
               tabTech, repRateMetaData, a_decoderId);
            
            % sort trajectory data structures according to the predefined
            % measurement code order
            [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
            
            o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
            o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % update NetCDF technical data
            update_technical_data_argos_sbd(a_decoderId);
            
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {4, 19, 25, 27, 28, 29} % DO V4.4 & V4.41 & V4.43 & V4.42 & V4.44 & V4.45
         
         % decode CTDO and technical messages
         if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
            [tabProfCTDO, tabDriftCTDO, tabTech, floatClockDrift, meanParkPres, maxProfPres] = ...
               decode_prv_data_4_19_25(sensors, sensorDates, a_decoderId);
         else
            [tabProfCTDO, tabDriftCTDO, tabTech, floatClockDrift, meanParkPres, maxProfPres] = ...
               decode_prv_data_27_28_29(sensors, sensorDates, a_decoderId);
         end

         if (~isempty(tabTech))
            
            % pressure associated with the first stabilization time
            firstStabPres = tabTech(4);
            
            % determine the main dates of the cycle
            [descentStartDate, firstStabDate, descentEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, transStartDate] = ...
               compute_prv_dates_1_3_4_11_12_17_19_24_25_27_to_29_31( ...
               tabTech, floatClockDrift, ...
               g_decArgo_floatSurfData.launchDate, a_refDay, a_cycleTime, ...
               a_driftSamplingPeriod, meanParkPres, maxProfPres, ...
               g_decArgo_floatSurfData.cycleData(end).firstMsgTime, ...
               g_decArgo_floatSurfData.cycleData(end).lastCtdMsgTime, ...
               lastArgosMsgDateOfPrevCycle, ...
               a_decoderId);            
            
            % create drift data set
            nbDriftMeas = tabTech(18);
            if (a_decoderId == 25)
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_25(tabDriftCTDO, nbDriftMeas, ...
                  descentStartDate, floatClockDrift, ...
                  descentEndDate, descentToProfStartDate, ...
                  a_driftSamplingPeriod);
            elseif ((a_decoderId == 27) || (a_decoderId == 28) || (a_decoderId == 29))
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_27_28_29(tabDriftCTDO, nbDriftMeas, ...
                  descentStartDate, floatClockDrift, ...
                  descentEndDate, descentToProfStartDate, ...
                  a_driftSamplingPeriod);
            else
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_4_19(tabDriftCTDO, nbDriftMeas, a_refDay, ...
                  descentEndDate, descentToProfStartDate, ...
                  ascentStartDate, a_driftSamplingPeriod);
            end
            
            if (isempty(parkDate))
               % determination of drift measurement dates failed
               if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
                  [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                     create_prv_drift_without_dates_4_19_25(tabDriftCTDO);
               else
                  [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                     create_prv_drift_without_dates_27_28_29_32(tabDriftCTDO);
               end
            end
            
         else
            
            if (~isempty(tabDriftCTDO))
               fprintf('WARNING: Float #%d Cycle #%d: technical message not received - unable to define drift measurements order\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            elseif (~isempty(tabProfCTDO))
               fprintf('WARNING: Float #%d Cycle #%d: technical message not received\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            end
            
            % float clock drift can't be determined
            floatClockDrift = [];
            
            % the main dates of the cycle can't be determined
            
            % create drift data set
            if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_without_dates_4_19_25(tabDriftCTDO);
            else
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_without_dates_27_28_29_32(tabDriftCTDO);
            end
         end
         
         % create descending and ascending profiles
         if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
            [descProfOcc, descProfDate, descProfPres, descProfTemp, descProfSal, descProfRawDoxy, ...
               ascProfOcc, ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy] = ...
               create_prv_profile_4_19_25(tabProfCTDO, tabTech, descentStartDate, ascentStartDate);
         else
            [descProfOcc, descProfDate, descProfPres, descProfTemp, descProfSal, descProfRawDoxy, ...
               ascProfOcc, ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy] = ...
               create_prv_profile_27_28_29_32(tabProfCTDO, tabTech, descentStartDate, ascentStartDate);
         end
         
         % convert counts to physical values
         [descProfPres] = sensor_2_value_for_pressure_argos(descProfPres);
         [parkPres] = sensor_2_value_for_pressure_argos(parkPres);
         [ascProfPres] = sensor_2_value_for_pressure_argos(ascProfPres);
         [descProfTemp] = sensor_2_value_for_temperature_argos(descProfTemp);
         [parkTemp] = sensor_2_value_for_temperature_argos(parkTemp);
         [ascProfTemp] = sensor_2_value_for_temperature_argos(ascProfTemp);
         [descProfSal] = sensor_2_value_for_salinity_argos(descProfSal);
         [parkSal] = sensor_2_value_for_salinity_argos(parkSal);
         [ascProfSal] = sensor_2_value_for_salinity_argos(ascProfSal);
         
         if ((a_decoderId == 27) || (a_decoderId == 28) || (a_decoderId == 29))
            [descProfRawDoxy] = sensor_2_value_for_tphase_doxy_27_28_29_32(descProfRawDoxy);
            [parkRawDoxy] = sensor_2_value_for_tphase_doxy_27_28_29_32(parkRawDoxy);
            [ascProfRawDoxy] = sensor_2_value_for_tphase_doxy_27_28_29_32(ascProfRawDoxy);
         end
         
         if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
            [descProfDoxy] = compute_DOXY_4_19_25(descProfRawDoxy, descProfPres, descProfTemp, descProfSal);
            [parkDoxy] = compute_DOXY_4_19_25(parkRawDoxy, parkPres, parkTemp, parkSal);
            [ascProfDoxy] = compute_DOXY_4_19_25(ascProfRawDoxy, ascProfPres, ascProfTemp, ascProfSal);
         elseif (a_decoderId == 27)
            [descProfDoxy] = compute_DOXY_27_32(descProfRawDoxy, descProfPres, descProfTemp, descProfSal);
            [parkDoxy] = compute_DOXY_27_32(parkRawDoxy, parkPres, parkTemp, parkSal);
            [ascProfDoxy] = compute_DOXY_27_32(ascProfRawDoxy, ascProfPres, ascProfTemp, ascProfSal);
         elseif (a_decoderId == 28)
            [descProfDoxy] = compute_DOXY_28(descProfRawDoxy, descProfPres, descProfTemp, descProfSal);
            [parkDoxy] = compute_DOXY_28(parkRawDoxy, parkPres, parkTemp, parkSal);
            [ascProfDoxy] = compute_DOXY_28(ascProfRawDoxy, ascProfPres, ascProfTemp, ascProfSal);
         elseif (a_decoderId == 29)
            [descProfDoxy] = compute_DOXY_29(descProfRawDoxy, descProfPres, descProfTemp, descProfSal);
            [parkDoxy] = compute_DOXY_29(parkRawDoxy, parkPres, parkTemp, parkSal);
            [ascProfDoxy] = compute_DOXY_29(ascProfRawDoxy, ascProfPres, ascProfTemp, ascProfSal);
         end
         
         % take float clock drift into account to correct float dates
         if (~isempty(floatClockDrift))
            [descentStartDate] = add_clock_drift_in_date(descentStartDate, floatClockDrift);
            [firstStabDate] = add_clock_drift_in_date(firstStabDate, floatClockDrift);
            [descentEndDate] = add_clock_drift_in_date(descentEndDate, floatClockDrift);
            [descentToProfStartDate] = add_clock_drift_in_date(descentToProfStartDate, floatClockDrift);
            [descentToProfEndDate] = add_clock_drift_in_date(descentToProfEndDate, floatClockDrift);
            [ascentStartDate] = add_clock_drift_in_date(ascentStartDate, floatClockDrift);
            [ascentEndDate] = add_clock_drift_in_date(ascentEndDate, floatClockDrift);
            [transStartDate] = add_clock_drift_in_date(transStartDate, floatClockDrift);
            
            [descProfDate] = add_clock_drift_in_date(descProfDate, floatClockDrift);
            [parkDate] = add_clock_drift_in_date(parkDate, floatClockDrift);
            [ascProfDate] = add_clock_drift_in_date(ascProfDate, floatClockDrift);
         end
         
         % store surface times in the float surface data structure
         [g_decArgo_floatSurfData] = set_surf_data(g_decArgo_floatSurfData, cycleNum, ...
            descentStartDate, ascentEndDate, transStartDate);
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            if (~isempty(tabTech))
               print_dates_in_csv_file_1_3_4_11_12_17_19_24_25_27_to_29_31( ...
                  floatClockDrift, lastArgosMsgDateOfPrevCycle, ...
                  descentStartDate, firstStabDate, firstStabPres, descentEndDate, ...
                  descentToProfStartDate, descentToProfEndDate, ascentStartDate, ...
                  ascentEndDate, transStartDate, argosLocDate, argosDataDate, ...
                  descProfDate, descProfPres, ...
                  parkDate, parkTransDate, parkPres, ...
                  ascProfDate, ascProfPres);
            end
            if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
               print_descending_profile_in_csv_file_4_19_25( ...
                  descProfOcc, descProfDate, ...
                  descProfPres, descProfTemp, descProfSal, descProfRawDoxy, descProfDoxy);
               print_drift_measurements_in_csv_file_4_19_25( ...
                  parkOcc, parkDate, parkTransDate, ...
                  parkPres, parkTemp, parkSal, parkRawDoxy, parkDoxy);
               print_ascending_profile_in_csv_file_4_19_25( ...
                  ascProfOcc, ascProfDate, ...
                  ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy, ascProfDoxy);
            else
               print_descending_profile_in_csv_file_27_28_29_32( ...
                  descProfOcc, descProfDate, ...
                  descProfPres, descProfTemp, descProfSal, descProfRawDoxy, descProfDoxy);
               print_drift_measurements_in_csv_file_27_28_29_32( ...
                  parkOcc, parkDate, parkTransDate, ...
                  parkPres, parkTemp, parkSal, parkRawDoxy, parkDoxy);
               print_ascending_profile_in_csv_file_27_28_29_32( ...
                  ascProfOcc, ascProfDate, ...
                  ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy, ascProfDoxy);
            end
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            % process profile data for PROF NetCDF file
            if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
               [cycleProfiles] = process_profiles_4_19_25( ...
                  g_decArgo_floatSurfData, cycleNum, ...
                  descProfDate, descProfPres, descProfTemp, descProfSal, descProfRawDoxy, descProfDoxy, ...
                  ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy, ascProfDoxy, ...
                  repRateMetaData, a_decoderId, tabTech);
            else
               [cycleProfiles] = process_profiles_27_28_29_32( ...
                  g_decArgo_floatSurfData, cycleNum, ...
                  descProfDate, descProfPres, descProfTemp, descProfSal, descProfRawDoxy, descProfDoxy, ...
                  ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy, ascProfDoxy, ...
                  repRateMetaData, a_decoderId, tabTech);
            end
            
            % add the vertical sampling scheme from configuration information
            [cycleProfiles] = add_vertical_sampling_scheme_argos(cycleProfiles, a_decoderId);
            
            print = 0;
            if (print == 1)
               if (~isempty(cycleProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(cycleProfiles));
                  for idP = 1:length(cycleProfiles)
                     prof = cycleProfiles(idP);
                     paramList = prof.paramList;
                     paramList = sprintf('%s ', paramList.name);
                     profLength = size(prof.data, 1);
                     fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
                        idP, prof.profileNumber, prof.direction, ...
                        profLength, paramList(1:end-1));
                  end
               else
                  fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
            end
            
            o_tabProfiles = [o_tabProfiles cycleProfiles];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
            
            addLaunchData = 0;
            if (isempty(o_tabTrajNMeas))
               % add the float launch position and date
               addLaunchData = 1;
            end
            
            % process trajectory data for TRAJ NetCDF file
            if ((a_decoderId == 4) || (a_decoderId == 19) || (a_decoderId == 25))
               [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_4_19_25( ...
                  cycleNum, ...
                  addLaunchData, g_decArgo_floatSurfData, ...
                  floatClockDrift, ...
                  descentStartDate, firstStabDate,  firstStabPres, descentEndDate, ...
                  descentToProfStartDate, descentToProfEndDate, ...
                  ascentStartDate, ascentEndDate, transStartDate, ...
                  cycleProfiles, ...
                  parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy, parkDoxy, ...
                  tabTech, repRateMetaData, a_decoderId);
            else
               [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_27_28_29( ...
                  cycleNum, ...
                  addLaunchData, g_decArgo_floatSurfData, ...
                  floatClockDrift, ...
                  descentStartDate, firstStabDate,  firstStabPres, descentEndDate, ...
                  descentToProfStartDate, descentToProfEndDate, ...
                  ascentStartDate, ascentEndDate, transStartDate, ...
                  cycleProfiles, ...
                  parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy, parkDoxy, ...
                  tabTech, repRateMetaData, a_decoderId);
            end
            
            % sort trajectory data structures according to the predefined
            % measurement code order
            [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
            
            o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
            o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % update NetCDF technical data
            update_technical_data_argos_sbd(a_decoderId);
            
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {30} % V4.52
         
         % decode CTD and technical messages
         [tabProfCTD, tabDriftCTD, tabTech1, tabTech2, tabParam, ...
            deepCycle, floatClockDrift, meanParkPres, maxProfPres] = ...
            decode_prv_data_30(sensors, sensorDates);
         
         if (g_decArgo_configDone == 0)
            create_float_config_argos(tabParam, a_decoderId);
            if (isempty(g_decArgo_floatConfig))
               return
            end
         end
         
         % update and assign the current configuration to the decoded cycle
         set_float_config_argos(g_decArgo_cycleNum, 1);

         cycleProfiles = [];
         parkDate = [];
         parkTransDate = [];
         parkPres = [];
         parkTemp = [];
         parkSal = [];

         if (deepCycle == 1)
            
            % pressure associated with some cycle timings
            if (~isempty(tabTech1))
               firstGroundingPres = tabTech1(14);
               firstEmergencyAscentPres = tabTech1(45);
            end
            if (~isempty(tabTech2))
               firstStabPres = tabTech2(9);
            end
            
            if (~isempty(tabTech2))
               
               % determine the main dates of the cycle
               [cycleStartDate, descentStartDate, firstStabDate, descentEndDate, ...
                  descentToProfStartDate, descentToProfEndDate, ...
                  ascentStartDate, ascentEndDate, transStartDate, ...
                  firstGroundingDate, firstEmergencyAscentDate] = ...
                  compute_prv_dates_30_32( ...
                  tabTech2, tabTech1, floatClockDrift, ...
                  g_decArgo_floatSurfData.launchDate, a_refDay, ...
                  meanParkPres, maxProfPres, ...
                  g_decArgo_floatSurfData.cycleData(end).firstMsgTime, ...
                  g_decArgo_floatSurfData.cycleData(end).lastCtdMsgTime, ...
                  lastArgosMsgDateOfPrevCycle);
               
               % create drift data set
               nbDriftMeas = [];
               if (~isempty(tabTech1))
                  nbDriftMeas = tabTech1(30);
               end
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
                  create_prv_drift_30(tabDriftCTD, nbDriftMeas, ...
                  descentStartDate, floatClockDrift, ...
                  descentEndDate, descentToProfStartDate, ...
                  a_driftSamplingPeriod);
               
               if (isempty(parkDate))
                  % determination of drift measurement dates failed
                  [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
                     create_prv_drift_without_dates_1_3_11_12_17_24_30_31(tabDriftCTD);
               end
               
            else
               
               if (~isempty(tabDriftCTD))
                  fprintf('WARNING: Float #%d Cycle #%d: technical message not received - unable to define drift measurements order\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               elseif (~isempty(tabProfCTD))
                  fprintf('WARNING: Float #%d Cycle #%d: technical message not received\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
               
               % float clock drift can't be determined
               floatClockDrift = [];
               
               % the main dates of the cycle can't be determined
               
               % create drift data set
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal] = ...
                  create_prv_drift_without_dates_1_3_11_12_17_24_30_31(tabDriftCTD);
            end
            
            % create descending and ascending profiles
            [descProfOcc, descProfDate, descProfPres, descProfTemp, descProfSal, ...
               ascProfOcc, ascProfDate, ascProfPres, ascProfTemp, ascProfSal] = ...
               create_prv_profile_1_3_11_12_17_24_29_30_31(tabProfCTD, tabTech2, descentStartDate, ascentStartDate);
            
            % convert counts to physical values
            [descProfPres] = sensor_2_value_for_pressure_argos(descProfPres);
            [parkPres] = sensor_2_value_for_pressure_argos(parkPres);
            [ascProfPres] = sensor_2_value_for_pressure_argos(ascProfPres);
            [descProfTemp] = sensor_2_value_for_temperature_argos(descProfTemp);
            [parkTemp] = sensor_2_value_for_temperature_argos(parkTemp);
            [ascProfTemp] = sensor_2_value_for_temperature_argos(ascProfTemp);
            [descProfSal] = sensor_2_value_for_salinity_argos(descProfSal);
            [parkSal] = sensor_2_value_for_salinity_argos(parkSal);
            [ascProfSal] = sensor_2_value_for_salinity_argos(ascProfSal);
            
            % take float clock drift into account to correct float dates
            if (~isempty(floatClockDrift))
               [cycleStartDate] = add_clock_drift_in_date(cycleStartDate, floatClockDrift);
               [descentStartDate] = add_clock_drift_in_date(descentStartDate, floatClockDrift);
               [firstStabDate] = add_clock_drift_in_date(firstStabDate, floatClockDrift);
               [descentEndDate] = add_clock_drift_in_date(descentEndDate, floatClockDrift);
               [descentToProfStartDate] = add_clock_drift_in_date(descentToProfStartDate, floatClockDrift);
               [descentToProfEndDate] = add_clock_drift_in_date(descentToProfEndDate, floatClockDrift);
               [ascentStartDate] = add_clock_drift_in_date(ascentStartDate, floatClockDrift);
               [ascentEndDate] = add_clock_drift_in_date(ascentEndDate, floatClockDrift);
               [transStartDate] = add_clock_drift_in_date(transStartDate, floatClockDrift);
               [firstGroundingDate] = add_clock_drift_in_date(firstGroundingDate, floatClockDrift);
               [firstEmergencyAscentDate] = add_clock_drift_in_date(firstEmergencyAscentDate, floatClockDrift);
               
               [descProfDate] = add_clock_drift_in_date(descProfDate, floatClockDrift);
               [parkDate] = add_clock_drift_in_date(parkDate, floatClockDrift);
               [ascProfDate] = add_clock_drift_in_date(ascProfDate, floatClockDrift);
            end
            
            % store surface times in the float surface data structure
            [g_decArgo_floatSurfData] = set_surf_data(g_decArgo_floatSurfData, cycleNum, ...
               descentStartDate, ascentEndDate, transStartDate);
            
         end
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            if (deepCycle == 1)
               if (~isempty(tabTech2))
                  print_dates_in_csv_file_30_32( ...
                     floatClockDrift, lastArgosMsgDateOfPrevCycle, ...
                     cycleStartDate, descentStartDate, ...
                     firstStabDate, firstStabPres, descentEndDate, ...
                     descentToProfStartDate, descentToProfEndDate, ascentStartDate, ...
                     ascentEndDate, transStartDate, argosLocDate, argosDataDate, ...
                     firstGroundingDate, firstGroundingPres, ...
                     firstEmergencyAscentDate, firstEmergencyAscentPres, ...
                     descProfDate, descProfPres, ...
                     parkDate, parkTransDate, parkPres, ...
                     ascProfDate, ascProfPres);
               end
               print_descending_profile_in_csv_file_1_3_11_12_17_24_30_31( ...
                  descProfOcc, descProfDate, ...
                  descProfPres, descProfTemp, descProfSal);
               print_drift_measurements_in_csv_file_1_3_11_12_17_24_30_31( ...
                  parkOcc, parkDate, parkTransDate, ...
                  parkPres, parkTemp, parkSal);
               print_ascending_profile_in_csv_file_1_3_11_12_17_24_30_31( ...
                  ascProfOcc, ascProfDate, ...
                  ascProfPres, ascProfTemp, ascProfSal);
            end
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            if (deepCycle == 1)
               
               % process profile data for PROF NetCDF file
               [cycleProfiles] = process_profiles_1_3_11_12_17_24_30_31( ...
                  g_decArgo_floatSurfData, cycleNum, ...
                  descProfDate, descProfPres, descProfTemp, descProfSal, ...
                  ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
                  repRateMetaData, a_decoderId, tabTech1);
               
               % add the vertical sampling scheme from configuration information
               [cycleProfiles] = add_vertical_sampling_scheme_argos(cycleProfiles, a_decoderId);
               
               print = 0;
               if (print == 1)
                  if (~isempty(cycleProfiles))
                     fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, length(cycleProfiles));
                     for idP = 1:length(cycleProfiles)
                        prof = cycleProfiles(idP);
                        paramList = prof.paramList;
                        paramList = sprintf('%s ', paramList.name);
                        profLength = size(prof.data, 1);
                        fprintf('   ->%2d: dir=%c length=%d param=(%s)\n', ...
                           idP, prof.direction, ...
                           profLength, paramList(1:end-1));
                     end
                  else
                     fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                  end
               end
               
               o_tabProfiles = [o_tabProfiles cycleProfiles];
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
               
            addLaunchData = 0;
            if (isempty(o_tabTrajNMeas))
               % add the float launch position and date
               addLaunchData = 1;
            end
            
            % process trajectory data for TRAJ NetCDF file
            [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_30( ...
               cycleNum, ...
               addLaunchData, g_decArgo_floatSurfData, ...
               floatClockDrift, ...
               cycleStartDate, descentStartDate, ...
               firstStabDate,  firstStabPres, descentEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, transStartDate, ...
               firstGroundingDate, firstGroundingPres, ...
               cycleProfiles, ...
               parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
               tabTech1, tabTech2, a_decoderId, deepCycle);
            
            % sort trajectory data structures according to the predefined
            % measurement code order
            [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
            
            o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
            o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
                           
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % update NetCDF technical data
            update_technical_data_argos_sbd(a_decoderId);
            
            % remove the transmission start time of the previous cycle if it
            % already exists
            if (~isempty(o_tabNcTechIndex))
               if (~isempty(find((o_tabNcTechIndex(:, 2) == g_decArgo_cycleNum-1) & (o_tabNcTechIndex(:, 5) == 1210), 1)))
                  idDel = find((g_decArgo_outputNcParamIndex(:, 2) == g_decArgo_cycleNum-1) & (g_decArgo_outputNcParamIndex(:, 5) == 1215), 1);
                  g_decArgo_outputNcParamIndex(idDel, :) = [];
                  g_decArgo_outputNcParamValue(idDel) = [];
               end
            end
            
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
      case {32} % V4.54
         
         % decode CTD and technical messages
         [tabProfCTDO, tabDriftCTDO, tabTech1, tabTech2, tabParam, ...
            deepCycle, floatClockDrift, meanParkPres, maxProfPres] = ...
            decode_prv_data_32(sensors, sensorDates);
         
         if (g_decArgo_configDone == 0)
            create_float_config_argos(tabParam, a_decoderId);
            if (isempty(g_decArgo_floatConfig))
               return
            end
         end
         
         % update and assign the current configuration to the decoded cycle
         set_float_config_argos(g_decArgo_cycleNum, 1);

         cycleProfiles = [];
         parkDate = [];
         parkTransDate = [];
         parkPres = [];
         parkTemp = [];
         parkSal = [];
         parkRawDoxy = [];
         parkDoxy = [];
         if (deepCycle == 1)
            
            % pressure associated with some cycle timings
            if (~isempty(tabTech1))
               firstGroundingPres = tabTech1(14);
               firstEmergencyAscentPres = tabTech1(45);
            end
            if (~isempty(tabTech2))
               firstStabPres = tabTech2(9);
            end
            
            if (~isempty(tabTech2))
               
               % determine the main dates of the cycle
               [cycleStartDate, descentStartDate, firstStabDate, descentEndDate, ...
                  descentToProfStartDate, descentToProfEndDate, ...
                  ascentStartDate, ascentEndDate, transStartDate, ...
                  firstGroundingDate, firstEmergencyAscentDate] = ...
                  compute_prv_dates_30_32( ...
                  tabTech2, tabTech1, floatClockDrift, ...
                  g_decArgo_floatSurfData.launchDate, a_refDay, ...
                  meanParkPres, maxProfPres, ...
                  g_decArgo_floatSurfData.cycleData(end).firstMsgTime, ...
                  g_decArgo_floatSurfData.cycleData(end).lastCtdMsgTime, ...
                  lastArgosMsgDateOfPrevCycle);
               
               % create drift data set
               nbDriftMeas = [];
               if (~isempty(tabTech1))
                  nbDriftMeas = tabTech1(30);
               end
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_32(tabDriftCTDO, nbDriftMeas, ...
                  descentStartDate, floatClockDrift, ...
                  descentEndDate, descentToProfStartDate, ...
                  a_driftSamplingPeriod);
               
               if (isempty(parkDate))
                  % determination of drift measurement dates failed
                  [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                     create_prv_drift_without_dates_27_28_29_32(tabDriftCTDO);
               end
               
            else
               
               if (~isempty(tabDriftCTDO))
                  fprintf('WARNING: Float #%d Cycle #%d: technical message not received - unable to define drift measurements order\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               elseif (~isempty(tabProfCTDO))
                  fprintf('WARNING: Float #%d Cycle #%d: technical message not received\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
               end
               
               % float clock drift can't be determined
               floatClockDrift = [];
               
               % the main dates of the cycle can't be determined
               
               % create drift data set
               [parkOcc, parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy] = ...
                  create_prv_drift_without_dates_27_28_29_32(tabDriftCTDO);
            end
            
            % create descending and ascending profiles
            [descProfOcc, descProfDate, descProfPres, descProfTemp, descProfSal, descProfRawDoxy, ...
               ascProfOcc, ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy] = ...
               create_prv_profile_27_28_29_32(tabProfCTDO, tabTech2, descentStartDate, ascentStartDate);
            
            % convert counts to physical values
            [descProfPres] = sensor_2_value_for_pressure_argos(descProfPres);
            [parkPres] = sensor_2_value_for_pressure_argos(parkPres);
            [ascProfPres] = sensor_2_value_for_pressure_argos(ascProfPres);
            [descProfTemp] = sensor_2_value_for_temperature_argos(descProfTemp);
            [parkTemp] = sensor_2_value_for_temperature_argos(parkTemp);
            [ascProfTemp] = sensor_2_value_for_temperature_argos(ascProfTemp);
            [descProfSal] = sensor_2_value_for_salinity_argos(descProfSal);
            [parkSal] = sensor_2_value_for_salinity_argos(parkSal);
            [ascProfSal] = sensor_2_value_for_salinity_argos(ascProfSal);
            [descProfRawDoxy] = sensor_2_value_for_tphase_doxy_27_28_29_32(descProfRawDoxy);
            [parkRawDoxy] = sensor_2_value_for_tphase_doxy_27_28_29_32(parkRawDoxy);
            [ascProfRawDoxy] = sensor_2_value_for_tphase_doxy_27_28_29_32(ascProfRawDoxy);

            % compute DOXY
            [descProfDoxy] = compute_DOXY_27_32(descProfRawDoxy, descProfPres, descProfTemp, descProfSal);
            [parkDoxy] = compute_DOXY_27_32(parkRawDoxy, parkPres, parkTemp, parkSal);
            [ascProfDoxy] = compute_DOXY_27_32(ascProfRawDoxy, ascProfPres, ascProfTemp, ascProfSal);
            
            % take float clock drift into account to correct float dates
            if (~isempty(floatClockDrift))
               [cycleStartDate] = add_clock_drift_in_date(cycleStartDate, floatClockDrift);
               [descentStartDate] = add_clock_drift_in_date(descentStartDate, floatClockDrift);
               [firstStabDate] = add_clock_drift_in_date(firstStabDate, floatClockDrift);
               [descentEndDate] = add_clock_drift_in_date(descentEndDate, floatClockDrift);
               [descentToProfStartDate] = add_clock_drift_in_date(descentToProfStartDate, floatClockDrift);
               [descentToProfEndDate] = add_clock_drift_in_date(descentToProfEndDate, floatClockDrift);
               [ascentStartDate] = add_clock_drift_in_date(ascentStartDate, floatClockDrift);
               [ascentEndDate] = add_clock_drift_in_date(ascentEndDate, floatClockDrift);
               [transStartDate] = add_clock_drift_in_date(transStartDate, floatClockDrift);
               [firstGroundingDate] = add_clock_drift_in_date(firstGroundingDate, floatClockDrift);
               [firstEmergencyAscentDate] = add_clock_drift_in_date(firstEmergencyAscentDate, floatClockDrift);
               
               [descProfDate] = add_clock_drift_in_date(descProfDate, floatClockDrift);
               [parkDate] = add_clock_drift_in_date(parkDate, floatClockDrift);
               [ascProfDate] = add_clock_drift_in_date(ascProfDate, floatClockDrift);
            end
            
            % store surface times in the float surface data structure
            [g_decArgo_floatSurfData] = set_surf_data(g_decArgo_floatSurfData, cycleNum, ...
               descentStartDate, ascentEndDate, transStartDate);
            
         end
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            if (deepCycle == 1)
               if (~isempty(tabTech2))
                  print_dates_in_csv_file_30_32( ...
                     floatClockDrift, lastArgosMsgDateOfPrevCycle, ...
                     cycleStartDate, descentStartDate, ...
                     firstStabDate, firstStabPres, descentEndDate, ...
                     descentToProfStartDate, descentToProfEndDate, ascentStartDate, ...
                     ascentEndDate, transStartDate, argosLocDate, argosDataDate, ...
                     firstGroundingDate, firstGroundingPres, ...
                     firstEmergencyAscentDate, firstEmergencyAscentPres, ...
                     descProfDate, descProfPres, ...
                     parkDate, parkTransDate, parkPres, ...
                     ascProfDate, ascProfPres);
               end
               print_descending_profile_in_csv_file_27_28_29_32( ...
                  descProfOcc, descProfDate, ...
                  descProfPres, descProfTemp, descProfSal, descProfRawDoxy, descProfDoxy);
               print_drift_measurements_in_csv_file_27_28_29_32( ...
                  parkOcc, parkDate, parkTransDate, ...
                  parkPres, parkTemp, parkSal, parkRawDoxy, parkDoxy);
               print_ascending_profile_in_csv_file_27_28_29_32( ...
                  ascProfOcc, ascProfDate, ...
                  ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy, ascProfDoxy);
            end
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            if (deepCycle == 1)
               
               % process profile data for PROF NetCDF file
               [cycleProfiles] = process_profiles_27_28_29_32( ...
                  g_decArgo_floatSurfData, cycleNum, ...
                  descProfDate, descProfPres, descProfTemp, descProfSal, descProfRawDoxy, descProfDoxy, ...
                  ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfRawDoxy, ascProfDoxy, ...
                  repRateMetaData, a_decoderId, tabTech1);
               
               % add the vertical sampling scheme from configuration information
               [cycleProfiles] = add_vertical_sampling_scheme_argos(cycleProfiles, a_decoderId);
               
               print = 0;
               if (print == 1)
                  if (~isempty(cycleProfiles))
                     fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum, length(cycleProfiles));
                     for idP = 1:length(cycleProfiles)
                        prof = cycleProfiles(idP);
                        paramList = prof.paramList;
                        paramList = sprintf('%s ', paramList.name);
                        profLength = size(prof.data, 1);
                        fprintf('   ->%2d: dir=%c length=%d param=(%s)\n', ...
                           idP, prof.direction, ...
                           profLength, paramList(1:end-1));
                     end
                  else
                     fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                  end
               end
               
               o_tabProfiles = [o_tabProfiles cycleProfiles];
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
               
            addLaunchData = 0;
            if (isempty(o_tabTrajNMeas))
               % add the float launch position and date
               addLaunchData = 1;
            end
            
            % process trajectory data for TRAJ NetCDF file
            [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_32( ...
               cycleNum, ...
               addLaunchData, g_decArgo_floatSurfData, ...
               floatClockDrift, ...
               cycleStartDate, descentStartDate, ...
               firstStabDate,  firstStabPres, descentEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, transStartDate, ...
               firstGroundingDate, firstGroundingPres, ...
               cycleProfiles, ...
               parkDate, parkTransDate, parkPres, parkTemp, parkSal, parkRawDoxy, parkDoxy, ...
               tabTech1, tabTech2, a_decoderId, deepCycle);
            
            % sort trajectory data structures according to the predefined
            % measurement code order
            [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
            
            o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
            o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
                           
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % update NetCDF technical data
            update_technical_data_argos_sbd(a_decoderId);
            
            % remove the transmission start time of the previous cycle if it
            % already exists
            if (~isempty(o_tabNcTechIndex))
               if (~isempty(find((o_tabNcTechIndex(:, 2) == g_decArgo_cycleNum-1) & (o_tabNcTechIndex(:, 5) == 1210), 1)))
                  idDel = find((g_decArgo_outputNcParamIndex(:, 2) == g_decArgo_cycleNum-1) & (g_decArgo_outputNcParamIndex(:, 5) == 1215), 1);
                  g_decArgo_outputNcParamIndex(idDel, :) = [];
                  g_decArgo_outputNcParamValue(idDel) = [];
               end
            end
            
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_provor_argos_data for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            a_decoderId);
   end
   
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files
   
   % if trajectory data is empty (no transmission from the float) add float
   % launch date and position in trajectory data structure
   if (isempty(o_tabTrajNMeas))
      o_tabTrajNMeas = add_launch_data_in_traj(g_decArgo_floatSurfData);
   end
   
   % fill empty profile locations with interpolated positions
   % (profile locations have been computed cycle by cycle, we will check if
   % some empty profile locations can not be determined using interpolations of the
   % surface trajectory)
   [o_tabProfiles] = fill_empty_profile_locations_argos(g_decArgo_floatSurfData, o_tabProfiles);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = update_output_cycle_number_argos( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);
   
   if (g_decArgo_addErrorEllipses == 1)
      % add Argos error ellipses
      [o_tabTrajNMeas] = add_argos_error_ellipses(a_floatArgosId, o_tabTrajNMeas);
   end
   
   % perform PARAMETER adjustment
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
      compute_rt_adjusted_param(o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, g_decArgo_floatSurfData.launchDate, 0, a_decoderId);

   if (g_decArgo_generateNcTraj32 ~= 0)
      % report profile PARAMETER adjustments in TRAJ data
      [o_tabTrajNMeas, o_tabTrajNCycle] = report_rt_adjusted_profile_data_in_trajectory( ...
         o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles);
   end
   
   % set TET as cycle start time of the next cycle (only for post 2013 firmware)
   [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_argos( ...
      o_tabTrajNMeas, o_tabTrajNCycle);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);

   % create output float configuration
   [o_structConfig] = create_output_float_config_argos(decArgoConfParamNames, ncConfParamNames, a_decoderId);
   
end

return
