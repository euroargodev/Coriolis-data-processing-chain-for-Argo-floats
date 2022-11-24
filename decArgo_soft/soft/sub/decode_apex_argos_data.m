% ------------------------------------------------------------------------------
% Decode APEX Argos messages.
%
% SYNTAX :
% function [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, ...
%    o_structConfig] = decode_apex_argos_data( ...
%    a_floatNum, a_cycleList, a_excludedCycleList, ...
%    a_decoderId, a_floatArgosId, ...
%    a_frameLength, a_floatSurfData, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum            : float WMO number
%   a_cycleList           : list of cycles to be decoded
%   a_excludedCycleList   : list of not decoded existing cycles
%   a_decoderId           : float decoder Id
%   a_floatArgosId        : float PTT number
%   a_frameLength         : Argos data frame length
%   a_floatSurfData       : float surface data structure
%   a_floatEndDate      : end date of the data to process
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
%   07/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, ...
   o_structConfig] = decode_apex_argos_data( ...
   a_floatNum, a_cycleList, a_excludedCycleList, ...
   a_decoderId, a_floatArgosId, ...
   a_frameLength, a_floatSurfData, a_floatEndDate)

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

% configuration creation flag
global g_decArgo_configDone;
g_decArgo_configDone = 0;

% cycle timings storage
global g_decArgo_timeData;
g_decArgo_timeData = get_apx_float_time_init_struct(a_decoderId);

% pressure offset storage
global g_decArgo_presOffsetData;
g_decArgo_presOffsetData = get_apx_pres_offset_init_struct;


% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Info type; Msg #'];
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% inits for output NetCDF file
decArgoConfParamNames = [];
ncConfParamNames = [];
if (isempty(g_decArgo_outputCsvFileId))
   
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   
   % create the configuration parameter names for the META NetCDF file
   [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_apx_argos(a_decoderId);
end

% retrieve the list of bytes to freeze for this decoder Id
[testMsgBytesToFreeze, dataMsgBytesToFreeze] = get_bytes_to_freeze(a_decoderId);

% decode each Argos file of the cycle list
for idCy = 1:length(a_cycleList)
   
   cycleNum = a_cycleList(idCy);
   g_decArgo_cycleNum = cycleNum;
   
   fprintf('Cycle #%d\n', cycleNum);
   
   % update the float surface data structure with the previous excluded cycles
   if (~isempty(find((a_excludedCycleList < cycleNum) & ...
         (a_excludedCycleList > a_floatSurfData.updatedForCycleNumber), 1)))
      [a_floatSurfData] = update_previous_cycle_surf_data( ...
         a_floatSurfData, a_floatArgosId, a_floatNum, a_frameLength, ...
         a_excludedCycleList, cycleNum);
   end
   
   % get the Argos file name(s) for this cycle
   [argosPathFileName, ~] = get_argos_path_file_name(a_floatArgosId, a_floatNum, cycleNum, a_floatEndDate);
   if (isempty(argosPathFileName))
      fprintf('INFO: Float #%d Cycle #%d: not processed according to float end date restriction\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      continue;
   end
   
   % read the Argos file and select the data
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataData, argosDataUsed, argosDataDate, sensorData, sensorDate] = ...
      get_apx_data(argosPathFileName{:}, cycleNum, a_decoderId, a_floatArgosId, ...
      a_frameLength, testMsgBytesToFreeze, dataMsgBytesToFreeze);
   
   % retrieve the previous cycle surface information
   [prevCycleNum, lastLocDate, lastLocLon, lastLocLat, lastMsgDate] = ...
      get_previous_cycle_surf_data(a_floatSurfData, cycleNum);
   
   % compute the JAMSTEC QC for the cycle locations
   lastLocDateOfPrevCycle = g_decArgo_dateDef;
   lastLocLonOfPrevCycle = g_decArgo_argosLonDef;
   lastLocLatOfPrevCycle = g_decArgo_argosLatDef;
   if (~isempty(prevCycleNum))
      if (prevCycleNum == cycleNum-1)
         lastLocDateOfPrevCycle = lastLocDate;
         lastLocLonOfPrevCycle = lastLocLon;
         lastLocLatOfPrevCycle = lastLocLat;
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
   cycleSurfData.argosLocDate = argosLocDate;
   cycleSurfData.argosLocLon = argosLocLon;
   cycleSurfData.argosLocLat = argosLocLat;
   cycleSurfData.argosLocAcc = argosLocAcc;
   cycleSurfData.argosLocSat = argosLocSat;
   cycleSurfData.argosLocQc = argosLocQc;
   
   % update the float surface data structure
   a_floatSurfData.cycleNumbers = [a_floatSurfData.cycleNumbers cycleNum];
   a_floatSurfData.cycleData = [a_floatSurfData.cycleData cycleSurfData];
   a_floatSurfData.updatedForCycleNumber = cycleNum;
   
   % decode the selected data according to decoder Id
   
   switch (a_decoderId)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
      case {1001} % 071412
         
         [miscInfo, auxInfo, profData, parkData, metaData, techData, trajData, ...
            timeInfo, g_decArgo_timeData, g_decArgo_presOffsetData] = ...
            decode_apx_1(argosDataData, argosDataUsed, argosDataDate, sensorData, sensorDate, ...
            cycleNum, g_decArgo_timeData, g_decArgo_presOffsetData, a_decoderId);
         
         % create the configuration
         if (g_decArgo_configDone == 0)
            create_float_config_apx_argos(metaData, a_decoderId);
         end
         
         % apply pressure adjustment
         [miscInfo, profData, parkData, g_decArgo_timeData, g_decArgo_presOffsetData] = ...
            adjust_pres_from_surf_offset(miscInfo, profData, parkData, g_decArgo_timeData, ...
            cycleNum, g_decArgo_presOffsetData);
         
         % compute the times of the cycle
         finalStep = 0;
         if ((idCy == length(a_cycleList)) || ~isempty(g_decArgo_outputCsvFileId))
            %          if ((idCy == length(a_cycleList)))
            finalStep = 1;
         end
         g_decArgo_timeData = compute_apx_times(g_decArgo_timeData, timeInfo, cycleNum, ...
            argosDataData, argosDataUsed, argosDataDate, cycleSurfData, a_decoderId, finalStep);
         
         % update surface times in the float surface data structure
         a_floatSurfData = update_surf_data(a_floatSurfData, g_decArgo_timeData, cycleNum);
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            print_misc_info_in_csv_file(miscInfo);
            print_park_data_in_csv_file(parkData);
            print_prof_data_in_csv_file(profData);
            print_aux_info_in_csv_file(auxInfo);
            print_aux_data_in_csv_file(g_decArgo_timeData);
            print_time_data_in_csv_file(g_decArgo_timeData, ...
               argosLocDate, argosLocLon, argosLocLat, ...
               argosLocAcc, argosLocSat, argosLocQc);
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            % process profile data for PROF NetCDF file
            [cycleProfile] = process_apx_profile(profData, cycleNum, ...
               g_decArgo_timeData, g_decArgo_presOffsetData, a_floatSurfData, a_decoderId);
            
            print = 0;
            if (print == 1)
               if (~isempty(cycleProfile))
                  fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, length(cycleProfile));
                  for idP = 1:length(cycleProfile)
                     prof = cycleProfile(idP);
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
            
            o_tabProfiles = [o_tabProfiles cycleProfile];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
            
            % add the float launch position and date
            if (isempty(o_tabTrajNMeas))
               addLaunchData = 1;
            else
               addLaunchData = 0;
            end
            
            % process trajectory data for TRAJ NetCDF file
            % (store all but times in the TRAJ structures)
            [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_1001( ...
               cycleNum, ...
               addLaunchData, a_floatSurfData, ...
               trajData, parkData, profData, g_decArgo_timeData, g_decArgo_presOffsetData, a_decoderId);
            
            o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
            o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % store technical data for output NetCDF files
            store_tech_data_for_nc_1001(techData);
            
            % update NetCDF technical data
            update_technical_data_argos_sbd(a_decoderId);
            
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
         
      otherwise
         fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apex_argos_data for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            a_decoderId);
   end
   
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files
   
   % fill empty profile locations with interpolated positions
   % (profile locations have been computed cycle by cycle, we will check if
   % some empty profile locations can not be determined using interpolations of the
   % surface trajectory)
   [o_tabProfiles] = fill_empty_profile_locations_argos(a_floatSurfData, o_tabProfiles);
   
   % process trajectory data for TRAJ NetCDF file
   % (store times in the TRAJ structures)
   
   % add the float launch position and date
   if (isempty(o_tabTrajNMeas))
      addLaunchData = 1;
   else
      addLaunchData = 0;
   end
   [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_time_1001( ...
      addLaunchData, a_floatSurfData, ...
      g_decArgo_timeData, g_decArgo_presOffsetData, o_tabTrajNMeas, o_tabTrajNCycle);
   
   % sort trajectory data structures according to the predefined measurement
   % code order
   [o_tabTrajNMeas] = sort_trajectory_data(o_tabTrajNMeas, a_decoderId);

   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = update_output_cycle_number_argos( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);
      
   % create output float configuration
   [o_structConfig] = create_output_float_config_argos(decArgoConfParamNames, ncConfParamNames);
   
end

return;
