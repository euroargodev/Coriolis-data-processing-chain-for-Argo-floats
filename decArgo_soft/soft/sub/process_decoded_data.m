% ------------------------------------------------------------------------------
% Process decoded data into Argo dedicated structures.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%    process_decoded_data( ...
%    a_decodedDataTab, a_refDay, a_decoderId, ...
%    a_tabProfiles, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_refDay         : reference day
%   a_decoderId      : float decoder Id
%   a_tabProfiles    : input decoded profiles
%   a_tabTrajNMeas   : input decoded trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input decoded trajectory N_CYCLE data
%   a_tabNcTechIndex : input decoded technical index information
%   a_tabNcTechVal   : input decoded technical data
%   a_tabTechNMeas   : input decoded technical PARAM data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output decoded profiles
%   o_tabTrajNMeas   : output decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : output decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : output decoded technical index information
%   o_tabNcTechVal   : output decoded technical data
%   o_tabTechNMeas   : output decoded technical PARAM data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/17/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   process_decoded_data( ...
   a_decodedDataTab, a_refDay, a_decoderId, ...
   a_tabProfiles, ...
   a_tabTrajNMeas, a_tabTrajNCycle, ...
   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;
o_tabTechNMeas = a_tabTechNMeas;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% generate nc flag
global g_decArgo_generateNcFlag;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;
g_decArgo_firstDeepCycleNumber = 1;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% clock offset management
global g_decArgo_clockOffset;

% from
% - decId 223 for Arvor
% - decId 221 for Arvor Deep
% - decId 225 for Provor
% configuration parameters are not transmitted each cycle
% consequently we must update the configuration of the second deep cycle with
% initial parameters, this should be done once (except if alterneated profil or
% auto-increment flag are set)
global  g_decArgo_doneOnceFlag;

% to store ICE data used to simulate ICE algorithm
global g_decArgo_iceData;

% to store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag is
% not the same as the final one)
global g_decArgo_cycleTimeData;


% no data to process
if (isempty(a_decodedDataTab))
   return
end

g_decArgo_generateNcFlag = 1;

% set information on current cycle
g_decArgo_cycleNum = unique([a_decodedDataTab.cyNum]);
deepCycleFlag =  unique([a_decodedDataTab.deep]);
if (~any([a_decodedDataTab.reset] == 1))
   resetDetectedFlag = 0;
else
   resetDetectedFlag = 1;
end
julD2FloatDayOffset = setdiff(unique([a_decodedDataTab.julD2FloatDayOffset]), -1);
if (~isempty(julD2FloatDayOffset))
   g_decArgo_julD2FloatDayOffset = julD2FloatDayOffset;
end

if (g_decArgo_realtimeFlag == 1)
   % update the reports structure cycle list
   g_decArgo_reportStruct = add_cycle_number_in_report_struct(g_decArgo_reportStruct, g_decArgo_cycleNum);
end

% print SBD file description for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))

   fileNameList = unique({a_decodedDataTab.fileName}, 'stable');
   for idFile = 1:length(fileNameList)
      idForFile = find(strcmp({a_decodedDataTab.fileName}, fileNameList{idFile}));
      packTypeList = [a_decodedDataTab(idForFile).packType];
      cyInfoStr = '';
      uPackTypeList = unique(packTypeList);
      for idP = 1:length(uPackTypeList)
         cyInfoStr = [cyInfoStr sprintf('#%d ', uPackTypeList(idP))];
         if (length(find(packTypeList == uPackTypeList(idP))) > 1)
            cyInfoStr = [cyInfoStr sprintf('(%d) ', length(find(packTypeList == uPackTypeList(idP))))];
         end
      end
      fprintf(g_decArgo_outputCsvFileId, '%d; -; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: %d; Cy %d : %s\n', ...
         g_decArgo_floatNum, ...
         idFile, fileNameList{idFile}, 100*length(idForFile), length(idForFile), ...
         g_decArgo_cycleNum, cyInfoStr(1:end-1));
   end
end

fprintf('DEC_INFO: Float #%d Cycle #%d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

% process decoded data

tabBuffProfiles = [];
tabBuffTrajNMeas = [];
tabBuffTrajNCycle = [];
tabBuffNcTechIndex = [];
tabBuffNcTechVal = [];
tabBuffTechNMeas = [];

switch (a_decoderId)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {212} % Arvor-ARN-Ice Iridium 5.45

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, ~, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTD(:, 63:77));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_212_222_231(dataCTD, g_decArgo_julD2FloatDayOffset);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
         create_prv_profile_212_222_231(dataCTD, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_212_214_217( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_212(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_212_214_217( ...
            cycleTimeData, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            nearSurfDate, nearSurfPres, ...
            inAirDate, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_204_205_210_to_212( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205_210_to_212( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205_210_to_212( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210_to_217( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            [], [], [], [], ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            [], [], [], []);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_212_214_217_218(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_212_214_217(floatParam1, floatParam2);

      else

         % output NetCDF files

         % specific
         % not used because not efficient enough
         % if (g_decArgo_floatNum == 6901929)
         %    if (g_decArgo_cycleNum > 271)
         % 
         %       % adjust badly dated times
         %       [descProfDate, parkDate, ascProfDate, nearSurfDate, inAirDate, ...
         %          evAct, pumpAct] = adjust_time_prv_ir( ...
         %          descProfDate, parkDate, ascProfDate, nearSurfDate, inAirDate, ...
         %          evAct, pumpAct, cycleTimeData);
         %    end
         % end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))

            [tabProfiles] = process_profiles_212( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_212( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_210_to_212(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_212_214_217_222_223_225_232(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {214, 217}
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTD(:, 63:77));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTDO(:, 17:23));
         [dataCTDO(:, 24:30)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTDO(:, 24:30));
         [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTDO(:, 31:37));
         [dataCTDO(:, 38:51)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 38:51));
         [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 52:58));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_214_217_223_225_232(dataCTD, dataCTDO, g_decArgo_julD2FloatDayOffset);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_214_217_223_225_232(dataCTD, dataCTDO, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      if (~isempty(dataCTDO))

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
      end

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_212_214_217( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_214_217(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_212_214_217( ...
            cycleTimeData, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            nearSurfDate, nearSurfPres, ...
            inAirDate, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);

         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);

         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210_to_217( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_212_214_217_218(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_212_214_217(floatParam1, floatParam2);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_214_217( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_214_217( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_213_214_217(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_212_214_217_222_223_225_232(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {216} % Arvor-Deep-Ice Iridium 5.65 (IFREMER version)

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, ~] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if (~isempty(floatParam1))
         update_float_config_ir_sbd_delayed(floatParam1, g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 63:77));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTDO(:, 17:23));
         [dataCTDO(:, 24:30)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 24:30));
         [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 31:37));
         [dataCTDO(:, 38:51)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 38:51));
         [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 52:58));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_to_203_215_216_218_221_228(dataCTD, dataCTDO, 2);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_215_216_218_221_228(dataCTD, dataCTDO, 2);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      if (~isempty(dataCTDO))

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
      end

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_216_218( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_216(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_215_216( ...
            cycleTimeData, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            nearSurfDate, nearSurfPres, ...
            inAirDate, inAirPres, ...
            evAct, pumpAct, 3);

         % print descending profile in CSV file
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);

         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);

         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210_to_217( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_201_to_203_215_216(evAct, pumpAct, 3);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_216(floatParam1);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_216_218_228( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_216( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_201_to_203_215_216_218_228_229(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_216(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {218} % Arvor-Deep-Ice Iridium 5.66 (NKE version)

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 63:77));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTDO(:, 17:23));
         [dataCTDO(:, 24:30)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 24:30));
         [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 31:37));
         [dataCTDO(:, 38:51)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 38:51));
         [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 52:58));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_to_203_215_216_218_221_228(dataCTD, dataCTDO, 2);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_215_216_218_221_228(dataCTD, dataCTDO, 2);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      if (~isempty(dataCTDO))

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
      end

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);
      
      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_216_218( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_218(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_218( ...
            cycleTimeData, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            nearSurfDate, nearSurfPres, ...
            inAirDate, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);

         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);

         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_218( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210_to_217( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_212_214_217_218(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_218(floatParam1, floatParam2);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_216_218_228( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_218( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_201_to_203_215_216_218_228_229(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_218(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {221} % Arvor-Deep-Ice Iridium 5.67

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 63:77));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTDO(:, 17:23));
         [dataCTDO(:, 24:30)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 24:30));
         [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 31:37));
         [dataCTDO(:, 38:51)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 38:51));
         [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 52:58));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_to_203_215_216_218_221_228(dataCTD, dataCTDO, 2);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_215_216_218_221_228(dataCTD, dataCTDO, 2);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      if (~isempty(dataCTDO))

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
      end

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_221_228_229( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_221(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_221_222_223_225_228_232( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_221_222_223_225_228_232( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_221_222_223_225_228_232( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_221_222_223_225_228_232( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirDateAdj, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_221_230(floatParam1, floatParam2);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_221( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_221( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_221_230(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_221(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {222}
      % Arvor-ARN-Ice Iridium 5.47

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, ~, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTD(:, 63:77));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_212_222_231(dataCTD, g_decArgo_julD2FloatDayOffset);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
         create_prv_profile_212_222_231(dataCTD, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_222_to_227_231_232( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_222_223_225_232(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_221_222_223_225_228_232( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            [], [], [], []);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_221_222_223_225_228_232( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            [], [], [], []);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_221_222_223_225_228_232( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            [], [], [], []);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_221_222_223_225_228_232( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            [], [], [], [], ...
            inAirDate, inAirDateAdj, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            [], [], [], []);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         if (a_decoderId == 222)
            print_float_prog_param_in_csv_file_222_223_225(floatParam1, floatParam2);
         else
            print_float_prog_param_in_csv_file_232(floatParam1, floatParam2);
         end

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))

            [tabProfiles] = process_profiles_222_223_225_231_232( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               [], [], [], [], ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               [], [], [], [], ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_222_223_225_231_232( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            [], [], [], [], ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, ...
            [], [], [], [], ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, ...
            [], [], [], [], ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_222_to_227_231_232(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_212_214_217_222_223_225_232(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {223, 225}
      % Arvor-ARN-DO-Ice Iridium 5.48
      % Provor-ARN-DO-Ice Iridium 5.76

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTD(:, 63:77));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTDO(:, 17:23));
         [dataCTDO(:, 24:30)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTDO(:, 24:30));
         [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTDO(:, 31:37));
         [dataCTDO(:, 38:51)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 38:51));
         [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 52:58));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_214_217_223_225_232(dataCTD, dataCTDO, g_decArgo_julD2FloatDayOffset);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_214_217_223_225_232(dataCTD, dataCTDO, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      if (~isempty(dataCTDO))

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
      end

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_222_to_227_231_232( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_222_223_225_232(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_221_222_223_225_228_232( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_221_222_223_225_228_232( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_221_222_223_225_228_232( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_221_222_223_225_228_232( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirDateAdj, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_222_223_225(floatParam1, floatParam2);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_222_223_225_231_232( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_222_223_225_231_232( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_222_to_227_231_232(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_212_214_217_222_223_225_232(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {224, 226, 227}
      % Arvor-ARN-Ice RBR Iridium 5.49
      % Arvor-ARN-Ice RBR 1 Hz Iridium 5.51
      % Arvor-ARN-Ice RBR 1 Hz + auto corrected PSAL Iridium 5.52

      % get decoded data
      [tabTech1, tabTech2, ...
         ~, ~, ...
         dataCTDRbr, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTDRbr))
         [dataCTDRbr(:, 25:35)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTDRbr(:, 25:35));
         [dataCTDRbr(:, 36:46)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTDRbr(:, 36:46));
         [dataCTDRbr(:, 47:57)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTDRbr(:, 47:57));
         idF = find(ismember(dataCTDRbr(:, 1), [15, 16, 17, 18, 19]));
         [dataCTDRbr(idF, 58:68)] = sensor_2_value_for_temp_cndc_224_226_227_229(dataCTDRbr(idF, 58:68));
         idF = find(ismember(dataCTDRbr(:, 1), [25, 27, 28, 29, 30]));
         [dataCTDRbr(idF, 58:68)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTDRbr(idF, 58:68));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, parkSalCor, parkTempCndc] = ...
         create_prv_drift_224_226_227(dataCTDRbr, g_decArgo_julD2FloatDayOffset);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, descProfSalCor, descProfTempCndc, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfSalCor, ascProfTempCndc, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, nearSurfSalCor, nearSurfTempCndc, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, inAirSalCor, inAirTempCndc] = ...
         create_prv_profile_224_226_227(dataCTDRbr, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_222_to_227_231_232( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_224_226_227_231(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_224_226_227_229_231( ...
            descProfDate, descProfDateAdj, ...
            descProfPres, descProfTemp, descProfSal, descProfSalCor, descProfTempCndc, ...
            [], [], [], []);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_224_226_227_229_231( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, parkSalCor, parkTempCndc, ...
            [], [], [], []);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_224_226_227_229_231( ...
            ascProfDate, ascProfDateAdj, ...
            ascProfPres, ascProfTemp, ascProfSal, ascProfSalCor, ascProfTempCndc, ...
            [], [], [], []);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_224_226_227_231( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, nearSurfSalCor, nearSurfTempCndc, ...
            [], [], [], [], ...
            inAirDate, inAirDateAdj, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, inAirSalCor, inAirTempCndc, ...
            [], [], [], []);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         if (a_decoderId == 224)
            % Arvor-ARN-Ice RBR Iridium 5.49
            print_float_prog_param_in_csv_file_224(floatParam1, floatParam2);
         elseif ((a_decoderId == 226) || (a_decoderId == 227))
            % Arvor-ARN-Ice RBR 1 Hz Iridium 5.51
            % Arvor-ARN-Ice RBR 1 Hz + auto corrected PSAL Iridium 5.52
            print_float_prog_param_in_csv_file_226_227_231(floatParam1, floatParam2, a_decoderId);
         end

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTDRbr))

            [tabProfiles] = process_profiles_224_226_227_229( ...
               descProfDate, descProfDateAdj, ...
               descProfPres, descProfTemp, descProfSal, descProfSalCor, descProfTempCndc, ...
               [], [], [], [], ...
               ascProfDate, ascProfDateAdj, ...
               ascProfPres, ascProfTemp, ascProfSal, ascProfSalCor, ascProfTempCndc, ...
               [], [], [], [], ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_224_226_227( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, parkSalCor, parkTempCndc, ...
            [], [], [], [], ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, nearSurfSalCor, nearSurfTempCndc, ...
            [], [], [], [], ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, inAirSalCor, inAirTempCndc, ...
            [], [], [], [], ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_222_to_227_231_232(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_224_226_227(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {228} % Arvor-Deep-Ice Iridium 5.68 (3T prototype)

      % get decoded data
      [tabTech1, tabTech2, tabTech3, ...
         dataCTD, dataCTD3T, ...
         evAct, pumpAct, ...
         floatParam1, floatParam3T] = ...
         get_decoded_data_228(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam3T))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam3T}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTD(:, 63:77));
      end

      if (~isempty(dataCTD3T))
         [dataCTD3T(:, 11:14)] = sensor_2_value_for_pressure_3T_228_2T_229(dataCTD3T(:, 11:14));
         [dataCTD3T(:, 15:18)] = sensor_2_value_for_temperature_3T_228_2T_229(dataCTD3T(:, 15:18));
         [dataCTD3T(:, 19:22)] = sensor_2_value_for_salinity_3T_228_2T_229(dataCTD3T(:, 19:22));

         [dataCTD3T(:, 23:26)] = sensor_2_value_for_pressure_3T_228_2T_229(dataCTD3T(:, 23:26));
         [dataCTD3T(:, 27:30)] = sensor_2_value_for_temperature_3T_228_2T_229(dataCTD3T(:, 27:30));
         [dataCTD3T(:, 31:34)] = sensor_2_value_for_salinity_3T_228_2T_229(dataCTD3T(:, 31:34));

         [dataCTD3T(:, 35:38)] = sensor_2_value_for_pressure_3T_228_2T_229(dataCTD3T(:, 35:38));
         [dataCTD3T(:, 39:42)] = sensor_2_value_for_temperature_3T_228_2T_229(dataCTD3T(:, 39:42));
         [dataCTD3T(:, 43:46)] = sensor_2_value_for_salinity_3T_228_2T_229(dataCTD3T(:, 43:46));
         [dataCTD3T(:, 47:50)] = sensor_2_value_for_temp_cndc_3T_228_2T_229(dataCTD3T(:, 47:50));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         ~, ~, ~] = ...
         create_prv_drift_201_to_203_215_216_218_221_228(dataCTD, [], 2);

      [parkDate3T, parkTransDate3T, ...
         parkPresSbe41, parkTempSbe41, parkSalSbe41, ...
         parkPresSbe61, parkTempSbe61, parkSalSbe61, ...
         parkPresRbr, parkTempRbr, parkSalRbr, parkTempCndcRbr] = ...
         create_prv_drift_3T_228(dataCTD3T, 2);
      if (~isempty(parkDate3T))
         fprintf('ERROR: Float #%d Cycle #%d: 3T drift data not considered yet\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum);
      end

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_221_228_229( ...
         tabTech1, tabTech2, deepCycleFlag, 0, a_refDay, g_decArgo_cycleNum);
      
      % correct dates of dataCTD3T descending profiles data which is not
      % consistent
      if (~isempty(dataCTD3T))
         if ~((g_decArgo_floatNum == 6903073) && (g_decArgo_cycleNum == 42)) % specific: for cycle #42 of float 6903073, the inconsistencies cannot be fix with day number offset
            iddesc = find(dataCTD3T(:, 1) == 23);
            if (~isempty(iddesc))
               tabDate = dataCTD3T(iddesc, 3);
               tabPres = dataCTD3T(iddesc, 11);
               [~, idSort] = sort(tabPres);
               tabDate = tabDate(idSort);
               offset = 0;
               while ((tabDate(1) + g_decArgo_julD2FloatDayOffset - offset) > cycleTimeData.cycleStartDate)
                  offset = offset + 1;
               end
               tabDate = tabDate - offset + 1;
               for id = 2:length(tabDate)
                  if (tabDate(id) < tabDate(id-1))
                     tabDate(id) = tabDate(id) + ceil(tabDate(id-1)-tabDate(id));
                  end
               end
               if (any(diff(idSort) ~= 1))
                  fprintf('ERROR: Float #%d Cycle #%d: 3T descending data not consistent\n', ...
                     g_decArgo_floatNum, ...
                     g_decArgo_cycleNum);
               end
               dataCTD3T(iddesc, 3) = tabDate;
            end
         end
      end

      % correct dates of dataCTD3T ascending profiles data which is not
      % consistent
      if (~isempty(dataCTD3T))
         idAsc = find(dataCTD3T(:, 1) == 25);
         if (~isempty(idAsc))
            tabDate = dataCTD3T(idAsc, 3);
            tabPres = dataCTD3T(idAsc, 11);
            [~, idSort] = sort(tabPres);
            tabDate = tabDate(idSort);
            offset = 0;
            while ((tabDate(1) + g_decArgo_julD2FloatDayOffset + offset) < cycleTimeData.transStartDate)
               offset = offset + 1;
            end
            tabDate = tabDate + offset - 1;
            for id = 2:length(tabDate)
               if (tabDate(id) > tabDate(id-1))
                  tabDate(id) = tabDate(id) - ceil(tabDate(id)-tabDate(id-1));
               end
            end
            if (all(diff(idSort) == -1))
               tabDate = flipud(tabDate);
            else
               fprintf('ERROR: Float #%d Cycle #%d: 3T ascending data not consistent\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum);
            end
            dataCTD3T(idAsc, 3) = tabDate;
         end
      end

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ~, ~, ~, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ~, ~, ~, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         ~, ~, ~, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         ~, ~, ~] = ...
         create_prv_profile_215_216_218_221_228(dataCTD, [], 2);

      [descProfDate3T, ...
         descProfPresSbe41, descProfTempSbe41, descProfSalSbe41, ...
         descProfPresSbe61, descProfTempSbe61, descProfSalSbe61, ...
         descProfPresRbr, descProfTempRbr, descProfSalRbr, descProfTempCndcRbr, ...
         ascProfDate3T, ...
         ascProfPresSbe41, ascProfTempSbe41, ascProfSalSbe41, ...
         ascProfPresSbe61, ascProfTempSbe61, ascProfSalSbe61, ...
         ascProfPresRbr, ascProfTempRbr, ascProfSalRbr, ascProfTempCndcRbr] = ...
         create_prv_profile_3T_228(dataCTD3T, 2);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         parkDate3TAdj, descProfDate3TAdj, ascProfDate3TAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir_228( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         parkDate3T, descProfDate3T, ascProfDate3T, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_228(tabTech1, tabTech2, tabTech3, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_228( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            descProfDate3T, descProfDate3TAdj, descProfPresSbe41, ...
            parkDate, parkDateAdj, parkPres, ...
            parkDate3T, parkDate3TAdj, parkPresSbe41, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            ascProfDate3T, ascProfDate3TAdj, ascProfPresSbe41, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct, 3);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_221_222_223_225_228_232( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            [], [], [], []);

         print_descending_profile_in_csv_file_3T_228( ...
            descProfDate3T, descProfDate3TAdj, ...
            descProfPresSbe41, descProfTempSbe41, descProfSalSbe41, ...
            descProfPresSbe61, descProfTempSbe61, descProfSalSbe61, ...
            descProfPresRbr, descProfTempRbr, descProfSalRbr, descProfTempCndcRbr);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_221_222_223_225_228_232( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            [], [], [], []);

         print_drift_measurements_in_csv_file_3T_228( ...
            parkDate3T, parkDate3TAdj, parkTransDate3T, ...
            parkPresSbe41, parkTempSbe41, parkSalSbe41, ...
            parkPresSbe61, parkTempSbe61, parkSalSbe61, ...
            parkPresRbr, parkTempRbr, parkSalRbr, parkTempCndcRbr);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_221_222_223_225_228_232( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            [], [], [], []);

         print_ascending_profile_in_csv_file_3T_228( ...
            ascProfDate3T, ascProfDate3TAdj, ...
            ascProfPresSbe41, ascProfTempSbe41, ascProfSalSbe41, ...
            ascProfPresSbe61, ascProfTempSbe61, ascProfSalSbe61, ...
            ascProfPresRbr, ascProfTempRbr, ascProfSalRbr, ascProfTempCndcRbr);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_221_222_223_225_228_232( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            [], [], [], [], ...
            inAirDate, inAirDateAdj, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            [], [], [], []);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_228_229(evAct, pumpAct, 3);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_228(floatParam1, floatParam3T);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_216_218_228( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               [], [], [], [], ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               [], [], [], [], ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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
         end

         tabProfiles3T = [];
         if ~(isempty(descProfDate3T) && isempty(ascProfDate3T))

            [tabProfiles3T] = process_profiles_3T_228( ...
               descProfDate3T, parkDate3TAdj, ...
               descProfPresSbe41, descProfTempSbe41, descProfSalSbe41, ...
               descProfPresSbe61, descProfTempSbe61, descProfSalSbe61, ...
               descProfPresRbr, descProfTempRbr, descProfSalRbr, descProfTempCndcRbr, ...
               ascProfDate3T, ascProfDate3TAdj, ...
               ascProfPresSbe41, ascProfTempSbe41, ascProfSalSbe41, ...
               ascProfPresSbe61, ascProfTempSbe61, ascProfSalSbe61, ...
               ascProfPresRbr, ascProfTempRbr, ascProfSalRbr, ascProfTempCndcRbr, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, tabTech2, tabTech3, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles3T] = add_vertical_sampling_scheme_3T_2T_228_229(tabProfiles3T);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles3T))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles3T));
                  for idP = 1:length(tabProfiles3T)
                     prof = tabProfiles3T(idP);
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
         end

         % when SBE41 sensor is used in both cases (vector management and
         % sensors comparison) we only keep sensor comparison data
         if (~isempty(tabProfiles3T))
            tabProfiles = tabProfiles3T;
         end

         tabBuffProfiles = [tabBuffProfiles tabProfiles];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_228_229( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, tabTech3, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            evAct, pumpAct, a_decoderId);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_201_to_203_215_216_218_228_229(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_228_229(tabTech2, deepCycleFlag, a_decoderId);
         store_tech3_data_for_nc_228(tabTech3, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {229} % Arvor-Deep-Ice Iridium 5.69 (2T prototype)

      % get decoded data
      [tabTech1, tabTech2, tabTech3, ...
         dataCTDRbr, dataCTD2T, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2T] = ...
         get_decoded_data_229(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2T))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2T}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTDRbr))
         [dataCTDRbr(:, 25:35)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTDRbr(:, 25:35));
         [dataCTDRbr(:, 36:46)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDRbr(:, 36:46));
         [dataCTDRbr(:, 47:57)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDRbr(:, 47:57));
         [dataCTDRbr(:, 58:68)] = sensor_2_value_for_temp_cndc_224_226_227_229(dataCTDRbr(:, 58:68));
      end

      if (~isempty(dataCTD2T))
         [dataCTD2T(:, 15:20)] = sensor_2_value_for_pressure_3T_228_2T_229(dataCTD2T(:, 15:20));
         [dataCTD2T(:, 21:26)] = sensor_2_value_for_temperature_3T_228_2T_229(dataCTD2T(:, 21:26));
         [dataCTD2T(:, 27:32)] = sensor_2_value_for_salinity_3T_228_2T_229(dataCTD2T(:, 27:32));
         [dataCTD2T(:, 33:38)] = sensor_2_value_for_temp_cndc_3T_228_2T_229(dataCTD2T(:, 33:38));

         [dataCTD2T(:, 39:44)] = sensor_2_value_for_pressure_3T_228_2T_229(dataCTD2T(:, 39:44));
         [dataCTD2T(:, 45:50)] = sensor_2_value_for_temperature_3T_228_2T_229(dataCTD2T(:, 45:50));
         [dataCTD2T(:, 51:56)] = sensor_2_value_for_salinity_3T_228_2T_229(dataCTD2T(:, 51:56));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, parkTempCndc] = ...
         create_prv_drift_229(dataCTDRbr, g_decArgo_julD2FloatDayOffset);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_221_228_229( ...
         tabTech1, tabTech2, deepCycleFlag, 0, a_refDay, g_decArgo_cycleNum);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, descProfTempCndc, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ascProfTempCndc] = ...
         create_prv_profile_229(dataCTDRbr, g_decArgo_julD2FloatDayOffset);

      [descProfDate2T, ...
         descProfPresRbr, descProfTempRbr, descProfSalRbr, descProfTempCndcRbr, ...
         descProfPresSbe61, descProfTempSbe61, descProfSalSbe61, ...
         ascProfDate2T, ...
         ascProfPresRbr, ascProfTempRbr, ascProfSalRbr, ascProfTempCndcRbr, ...
         ascProfPresSbe61, ascProfTempSbe61, ascProfSalSbe61] = ...
         create_prv_profile_2T_229(dataCTD2T, 2);

      % correct dates of dataCTD2T descending and ascending profiles (the day is
      % erroneous)
      [descProfDate2T, ascProfDate2T] = create_prv_profile_dates_2T_229( ...
         descProfDate2T, ascProfDate2T, cycleTimeData);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         descProfDate2TAdj, ascProfDate2TAdj, ...
         evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir_229( ...
         parkDate, descProfDate, ascProfDate, ...
         descProfDate2T, ascProfDate2T, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_229(tabTech1, tabTech2, tabTech3, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_229( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            descProfDate2T, descProfDate2TAdj, descProfPresRbr, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            ascProfDate2T, ascProfDate2TAdj, ascProfPresRbr, ...
            evAct, pumpAct, 3);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_224_226_227_229_231( ...
            descProfDate, descProfDateAdj, ...
            descProfPres, descProfTemp, descProfSal, [], descProfTempCndc, ...
            [], [], [], []);

         print_descending_profile_in_csv_file_2T_229( ...
            descProfDate2T, descProfDate2TAdj, ...
            descProfPresRbr, descProfTempRbr, descProfSalRbr, descProfTempCndcRbr, ...
            descProfPresSbe61, descProfTempSbe61, descProfSalSbe61);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_224_226_227_229_231( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, [], parkTempCndc, ...
            [], [], [], []);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_224_226_227_229_231( ...
            ascProfDate, ascProfDateAdj, ...
            ascProfPres, ascProfTemp, ascProfSal, [], ascProfTempCndc, ...
            [], [], [], []);

         print_ascending_profile_in_csv_file_2T_229( ...
            ascProfDate2T, ascProfDate2TAdj, ...
            ascProfPresRbr, ascProfTempRbr, ascProfSalRbr, ascProfTempCndcRbr, ...
            ascProfPresSbe61, ascProfTempSbe61, ascProfSalSbe61);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_228_229(evAct, pumpAct, 3);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_229(floatParam1, floatParam2T);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_224_226_227_229( ...
               descProfDate, descProfDateAdj, ...
               descProfPres, descProfTemp, descProfSal, [], descProfTempCndc, ...
               [], [], [], [], ...
               ascProfDate, ascProfDateAdj, ...
               ascProfPres, ascProfTemp, ascProfSal, [], ascProfTempCndc, ...
               [], [], [], [], ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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
         end

         tabProfiles2T = [];
         if ~(isempty(descProfDate2T) && isempty(ascProfDate2T))

            [tabProfiles2T] = process_profiles_2T_229( ...
               descProfDate2T, descProfDate2TAdj, ...
               descProfPresRbr, descProfTempRbr, descProfSalRbr, descProfTempCndcRbr, ...
               descProfPresSbe61, descProfTempSbe61, descProfSalSbe61, ...
               ascProfDate2T, ascProfDate2TAdj, ...
               ascProfPresRbr, ascProfTempRbr, ascProfSalRbr, ascProfTempCndcRbr, ...
               ascProfPresSbe61, ascProfTempSbe61, ascProfSalSbe61, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, tabTech2, tabTech3, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles2T] = add_vertical_sampling_scheme_3T_2T_228_229(tabProfiles2T);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles2T))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles2T));
                  for idP = 1:length(tabProfiles2T)
                     prof = tabProfiles2T(idP);
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
         end

         % when RBR sensor is used in both cases (vector management and
         % sensors comparison) we only keep sensor comparison data
         if (~isempty(tabProfiles2T))
            tabProfiles = tabProfiles2T;
         end

         tabBuffProfiles = [tabBuffProfiles tabProfiles];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_228_229( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, tabTech3, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            evAct, pumpAct, a_decoderId);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_201_to_203_215_216_218_228_229(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_228_229(tabTech2, deepCycleFlag, a_decoderId);
         store_tech3_data_for_nc_229(tabTech3, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {230} % Arvor-Deep-Ice Iridium 5.77 (2DO)

      % get decoded data
      [tabTech1, tabTech2, ...
         ~, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTDO))
         [dataCTDO(:, 11:14)] = sensor_2_value_for_pressure_201_203_215_216_218_221_228_229_230(dataCTDO(:, 11:14));
         [dataCTDO(:, 15:18)] = sensor_2_value_for_temp_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 15:18));
         [dataCTDO(:, 19:22)] = sensor_2_value_for_salinity_2xx_1_to_3_15_16_18_21_28_29_30(dataCTDO(:, 19:22));
         [dataCTDO(:, 23:26)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 23:26));
         [dataCTDO(:, 27:30)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 27:30));
         [dataCTDO(:, 31:34)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 31:34));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
         parkTempCountDoxy, parkCountDoxy, parkLedFlashingCountDoxy] = ...
         create_prv_drift_230(dataCTDO, 2);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         descProfTempCountDoxy, descProfCountDoxy, descProfLedFlashingCountDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         ascProfTempCountDoxy, ascProfCountDoxy, ascProfLedFlashingCountDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         nearSurfTempCountDoxy, nearSurfCountDoxy, nearSurfLedFlashingCountDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
         inAirTempCountDoxy, inAirCountDoxy, inAirLedFlashingCountDoxy] = ...
         create_prv_profile_230(dataCTDO, 2);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      descProfDoxy2 = [];
      descProfTempDoxy2 = [];
      parkDoxy2 = [];
      parkTempDoxy2 = [];
      ascProfDoxy2 = [];
      ascProfTempDoxy2 = [];
      nearSurfPpoxDoxy2 = [];
      nearSurfTempDoxy2 = [];
      inAirPpoxDoxy2 = [];
      inAirTempDoxy2 = [];
      if (~isempty(dataCTDO))

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % DOXY processing for AANDERAA_OPTODE_4330 sensor

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % DOXY processing for AROD_FT

         [descProfTempDoxy2] = compute_TEMP_DOXY_JAC_230(descProfTempCountDoxy);
         [descProfDoxy2] = compute_DOXY_JAC_230(descProfCountDoxy, descProfLedFlashingCountDoxy, ...
            descProfPres, descProfTemp, descProfSal);

         [parkTempDoxy2] = compute_TEMP_DOXY_JAC_230(parkTempCountDoxy);
         [parkDoxy2] = compute_DOXY_JAC_230(parkCountDoxy, parkLedFlashingCountDoxy, ...
            parkPres, parkTemp, parkSal);

         [ascProfTempDoxy2] = compute_TEMP_DOXY_JAC_230(ascProfTempCountDoxy);
         [ascProfDoxy2] = compute_DOXY_JAC_230(ascProfCountDoxy, ascProfLedFlashingCountDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         [nearSurfTempDoxy2] = compute_TEMP_DOXY_JAC_230(nearSurfTempCountDoxy);
         [nearSurfPpoxDoxy2] = compute_PPOX_DOXY_JAC_230(nearSurfCountDoxy, nearSurfLedFlashingCountDoxy, ...
            nearSurfPres, nearSurfTemp, nearSurfSal);

         [inAirTempDoxy2] = compute_TEMP_DOXY_JAC_230(inAirTempCountDoxy);
         [inAirPpoxDoxy2] = compute_PPOX_DOXY_JAC_230(inAirCountDoxy, inAirLedFlashingCountDoxy, ...
            inAirPres, inAirTemp, inAirSal);       
      end

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_230( ...
         tabTech1, tabTech2, deepCycleFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_230(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_230( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
            descProfTempCountDoxy, descProfCountDoxy, descProfLedFlashingCountDoxy, descProfTempDoxy2, descProfDoxy2);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_230( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            parkTempCountDoxy, parkCountDoxy, parkLedFlashingCountDoxy, parkTempDoxy2, parkDoxy2);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_230( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
            ascProfTempCountDoxy, ascProfCountDoxy, ascProfLedFlashingCountDoxy, ascProfTempDoxy2, ascProfDoxy2);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_230( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            nearSurfTempCountDoxy, nearSurfCountDoxy, nearSurfLedFlashingCountDoxy, nearSurfTempDoxy2, nearSurfPpoxDoxy2, ...
            inAirDate, inAirDateAdj, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            inAirTempCountDoxy, inAirCountDoxy, inAirLedFlashingCountDoxy, inAirTempDoxy2, inAirPpoxDoxy2);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_221_230(floatParam1, floatParam2);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))

            [tabProfiles] = process_profiles_230( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               descProfTempCountDoxy, descProfCountDoxy, descProfLedFlashingCountDoxy, descProfTempDoxy2, descProfDoxy2, ...            
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               ascProfTempCountDoxy, ascProfCountDoxy, ascProfLedFlashingCountDoxy, ascProfTempDoxy2, ascProfDoxy2, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_230( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            parkTempCountDoxy, parkCountDoxy, parkLedFlashingCountDoxy, parkTempDoxy2, parkDoxy2, ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            nearSurfTempCountDoxy, nearSurfCountDoxy, nearSurfLedFlashingCountDoxy, nearSurfTempDoxy2, nearSurfPpoxDoxy2, ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            inAirTempCountDoxy, inAirCountDoxy, inAirLedFlashingCountDoxy, inAirTempDoxy2, inAirPpoxDoxy2, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_221_230(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_230(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {231}
      % Arvor-ARN-Ice SBE Iridium 5.53

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, ~, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTD(:, 63:77));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_212_222_231(dataCTD, g_decArgo_julD2FloatDayOffset);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
         create_prv_profile_212_222_231(dataCTD, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_222_to_227_231_232( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_224_226_227_231(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_224_226_227_229_231( ...
            descProfDate, descProfDateAdj, ...
            descProfPres, descProfTemp, descProfSal, [], [], ...
            [], [], [], []);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_224_226_227_229_231( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, [], [], ...
            [], [], [], []);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_224_226_227_229_231( ...
            ascProfDate, ascProfDateAdj, ...
            ascProfPres, ascProfTemp, ascProfSal, [], [], ...
            [], [], [], []);

         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_224_226_227_231( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, [], [], ...
            [], [], [], [], ...
            inAirDate, inAirDateAdj, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, [], [], ...
            [], [], [], []);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_226_227_231(floatParam1, floatParam2, a_decoderId);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))

            [tabProfiles] = process_profiles_222_223_225_231_232( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               [], [], [], [], ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               [], [], [], [], ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_222_223_225_231_232( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            [], [], [], [], ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, ...
            [], [], [], [], ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, ...
            [], [], [], [], ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_222_to_227_231_232(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_231(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {232}
      % Arvor-ARN-Ice Iridium 5.54

      % get decoded data
      [tabTech1, tabTech2, ...
         dataCTD, dataCTDO, ...
         ~, ~, ...
         evAct, pumpAct, ...
         floatParam1, floatParam2] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);

      % assign the current configuration to the current deep cycle
      if ((g_decArgo_cycleNum > 0) && ((deepCycleFlag == 1) || (resetDetectedFlag == 1)))
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);

         % update the configuration (even if no param packets are received)
         if (g_decArgo_doneOnceFlag ~= 1)
            update_float_config_ir_sbd_delayed([{[]} {[]}], g_decArgo_cycleNum, a_decoderId);
         end
      end

      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
      end
      if (g_decArgo_cycleNum == -1)
         % only consider parameter packets for cycle number -1
         return
      end

      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);

      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTD(:, 33:47));
         [dataCTD(:, 48:62)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTD(:, 48:62));
         [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTD(:, 63:77));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_2xx_2_10_to_14_17_22_to_27_31_32(dataCTDO(:, 17:23));
         [dataCTDO(:, 24:30)] = sensor_2_value_for_temp_2xx_4_to_14_17_19_20_22_to_27_31_32(dataCTDO(:, 24:30));
         [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_2xx_10_to_14_17_20_22_to_27_31_32(dataCTDO(:, 31:37));
         [dataCTDO(:, 38:51)] = sensor_2_value_for_C1C2phase_ir_sbd_2xx(dataCTDO(:, 38:51));
         [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_ir_sbd_2xx(dataCTDO(:, 52:58));
      end

      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_214_217_223_225_232(dataCTD, dataCTDO, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_214_217_223_225_232(dataCTD, dataCTDO, deepCycleFlag, g_decArgo_julD2FloatDayOffset);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfPpoxDoxy = [];
      inAirPpoxDoxy = [];
      if (~isempty(dataCTDO))

         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_to_218_221_223_225_230_232( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);

         % compute PPOX_DOXY from C1PHASE_DOXY and C2PHASE_DOXY using the Stern-Volmer equation
         [nearSurfPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            nearSurfPres, nearSurfTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
         [inAirPpoxDoxy] = compute_PPOX_DOXY_213_to_218_221_223_225_230_232( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            g_decArgo_c1C2PhaseDoxyDef, g_decArgo_c1C2PhaseDoxyDef, g_decArgo_tempDoxyDef, ...
            inAirPres, inAirTemp, ...
            g_decArgo_presDef, g_decArgo_tempDef, ...
            g_decArgo_doxyDef);
      end

      % store ICE information
      [iceAscentAbortedFlag] = store_ice_information_arvor( ...
         tabTech1, tabTech2, deepCycleFlag, ascProfPres, nearSurfPres, inAirPres, a_decoderId);

      % compute the main dates of the cycle
      [cycleTimeData] = compute_prv_dates_222_to_227_231_232( ...
         tabTech1, tabTech2, deepCycleFlag, iceAscentAbortedFlag, a_refDay, g_decArgo_cycleNum);

      % apply clock offset adjustment
      [parkDateAdj, descProfDateAdj, ascProfDateAdj, ...
         nearSurfDateAdj, inAirDateAdj, evAct, pumpAct, cycleTimeData] = adjust_clock_offset_prv_ir( ...
         parkDate, descProfDate, ascProfDate, nearSurfDate, inAirDate, ...
         evAct, pumpAct, ...
         cycleTimeData, g_decArgo_clockOffset);

      % store cycleTimeData for ICE floats (in case the RT iceAscentAbortedFlag
      % is not the same as the final one)
      if (~isempty(g_decArgo_iceData))
         g_decArgo_cycleTimeData{end+1} = cycleTimeData;
      end

      if (~isempty(g_decArgo_outputCsvFileId))

         % output CSV file

         % print float technical messages in CSV file
         print_tech_data_in_csv_file_222_223_225_232(tabTech1, tabTech2, deepCycleFlag);

         % print dated data in CSV file
         print_dates_in_csv_file_221_to_227_230_231_232( ...
            cycleTimeData, ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            nearSurfDate, nearSurfDateAdj, nearSurfPres, ...
            inAirDate, inAirDateAdj, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_descending_profile_in_csv_file_221_222_223_225_228_232( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);

         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_221_222_223_225_228_232( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);

         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_221_222_223_225_228_232( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_221_222_223_225_228_232( ...
            nearSurfDate, nearSurfDateAdj, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirDateAdj, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_2xx_21_22_23_25_to_27_30_31_32(evAct, pumpAct);

         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_232(floatParam1, floatParam2);

      else

         % output NetCDF files

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file

         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD) || ~isempty(dataCTDO))

            [tabProfiles] = process_profiles_222_223_225_231_232( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleTimeData, ...
               tabTech2, a_decoderId);

            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);

            print = 0;
            if (print == 1)
               if (~isempty(tabProfiles))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
                  for idP = 1:length(tabProfiles)
                     prof = tabProfiles(idP);
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

            tabBuffProfiles = [tabBuffProfiles tabProfiles];
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_222_223_225_231_232( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleTimeData, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, ...
            nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfPpoxDoxy, ...
            inAirDate, inAirTransDate, ...
            inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirPpoxDoxy, ...
            evAct, pumpAct);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);

         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file

         % store information on received Iridium packet types
         store_received_packet_type_info_for_nc(a_decoderId, deepCycleFlag);

         % store NetCDF technical data
         store_tech1_data_for_nc_222_to_227_231_232(tabTech1, deepCycleFlag);
         store_tech2_data_for_nc_212_214_217_222_223_225_232(tabTech2, deepCycleFlag);

         % store additional technical decoding information (for TECH_AUX
         % file)
         store_misc_tech_data_for_nc_212_214_216_to_218_222_to_232(a_decodedDataTab, a_decoderId);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];

      end

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in process_decoded_data for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% output parameters
if (isempty(g_decArgo_outputCsvFileId))
   if (~isempty(tabBuffProfiles))
      o_tabProfiles = [o_tabProfiles tabBuffProfiles];
   end
   if (~isempty(tabBuffTrajNMeas))
      o_tabTrajNMeas = [o_tabTrajNMeas tabBuffTrajNMeas];
   end
   if (~isempty(tabBuffTrajNCycle))
      o_tabTrajNCycle = [o_tabTrajNCycle tabBuffTrajNCycle];
   end
   if (~isempty(tabBuffNcTechIndex))
      o_tabNcTechIndex = [o_tabNcTechIndex; tabBuffNcTechIndex];
   end
   if (~isempty(tabBuffNcTechVal))
      o_tabNcTechVal = [o_tabNcTechVal; tabBuffNcTechVal'];
   end
   if (~isempty(tabBuffTechNMeas))
      o_tabTechNMeas = [o_tabTechNMeas tabBuffTechNMeas];
   end
end

return
