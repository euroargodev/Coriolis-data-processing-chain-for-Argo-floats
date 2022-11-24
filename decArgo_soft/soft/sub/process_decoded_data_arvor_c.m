% ------------------------------------------------------------------------------
% Process decoded data into Argo dedicated structures.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal] = ...
%    process_decoded_data_arvor_c( ...
%    a_decodedDataTab, a_launchDate, a_decoderId, ...
%    a_tabProfiles, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_tabNcTechIndex, a_tabNcTechVal)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_launchDate     : launch date
%   a_decoderId      : float decoder Id
%   a_tabProfiles    : input decoded profiles
%   a_tabTrajNMeas   : input decoded trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input decoded trajectory N_CYCLE data
%   a_tabNcTechIndex : input decoded technical index information
%   a_tabNcTechVal   : input decoded technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output decoded profiles
%   o_tabTrajNMeas   : output decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : output decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : output decoded technical index information
%   o_tabNcTechVal   : output decoded technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal] = ...
   process_decoded_data_arvor_c( ...
   a_decodedDataTab, a_launchDate, a_decoderId, ...
   a_tabProfiles, ...
   a_tabTrajNMeas, a_tabTrajNCycle, ...
   a_tabNcTechIndex, a_tabNcTechVal)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

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


% no data to process
if (isempty(a_decodedDataTab))
   return
end

g_decArgo_generateNcFlag = 1;

% set information on current cycle
g_decArgo_cycleNum = unique([a_decodedDataTab.cyNum]);
deepCycleFlag =  unique([a_decodedDataTab.deep]);

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
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: %d; Cy %d : %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
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

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {219, 220} % Arvor-C 5.3 & 5.301
      
      % get decoded data
      [tabTech, ~, dataCTD, ~, ~, ~, ~, ~] = ...
         get_decoded_data(a_decodedDataTab, a_decoderId);
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 2:25)] = sensor_2_value_for_pressure_204_to_209_219_220(dataCTD(:, 2:25));
         [dataCTD(:, 26:49)] = sensor_2_value_for_temp_204_to_214_217_219_220_222_to_224(dataCTD(:, 26:49));
         if (a_decoderId == 219)
            [dataCTD(:, 50:73)] = sensor_2_value_for_salinity_219(dataCTD(:, 50:73));
         else
            [dataCTD(:, 50:73)] = sensor_2_value_for_salinity_210_to_214_217_220_222_to_224(dataCTD(:, 50:73));
         end
      end
      
      % create ascending profile
      [ascProfPres, ascProfPresTrans, ascProfTemp, ascProfSal] = create_prv_profile_219_220(dataCTD);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentStartDate, ...
         descentEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDatess] = ...
         compute_prv_dates_219_220(tabTech, deepCycleFlag, lastMsgDateOfPrevCycle, a_launchDate);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_219_220(tabTech);
         
         % print dated data in CSV file
         print_dates_in_csv_file_219_220( ...
            cycleStartDate, ...
            descentStartDate, ...
            descentEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDatess);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_219_220( ...
            ascProfPres, ascProfPresTrans, ascProfTemp, ascProfSal);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_219_220( ...
               ascProfPres, ascProfTemp, ascProfSal, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               ascentEndDate, transStartDate, tabTech);
            
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
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_219_220( ...
            g_decArgo_cycleNum, deepCycleFlag, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentStartDate, descentEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            tabTech, ...
            tabProfiles);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
         tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % store information on received Iridium packet types
         if (deepCycleFlag == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % store NetCDF technical data
         store_tech_data_for_nc_219_220(tabTech);

         tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
         tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in process_decoded_data_arvor_c for decoderId #%d\n', ...
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
end

return
