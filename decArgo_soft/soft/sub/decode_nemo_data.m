% ------------------------------------------------------------------------------
% Decode NEMO .profile data.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, ...
%    o_structConfig] = decode_nemo_data( ...
%    a_floatNum, a_cycleList, ...
%    a_decoderId, a_floatRudicsId, a_floatLaunchDate, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_cycleList       : list of cycles to be decoded
%   a_decoderId       : float decoder Id
%   a_floatRudicsId   : float Rudics Id
%   a_floatLaunchDate : float launch date
%   a_floatEndDate    : float end decoding date
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
%   01/31/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, ...
   o_structConfig] = decode_nemo_data( ...
   a_floatNum, a_cycleList, ...
   a_decoderId, a_floatRudicsId, a_floatLaunchDate, a_floatEndDate)

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

% global default values
global g_decArgo_dateDef;

% float configuration
global g_decArgo_floatConfig;
g_decArgo_floatConfig = [];

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% pressure offset storage
global g_decArgo_presOffsetData;

% clock offset storage
global g_decArgo_clockOffset;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium data
global g_decArgo_iridiumData;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_historyDirectory;

% mode processing flags
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1; % since there is no buffer we can process the data each time a new file has been collecte by rsync

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% decoder configuration values
global g_decArgo_dirInputRsyncData;

% storage of META-DATA information (to update data base) - CSV decoder only
global g_decArgo_metaDataAll;
g_decArgo_metaDataAll = [];

% store PRELUDE TECH data only once
global g_decArgo_done;
g_decArgo_done = 0;


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' sprintf('%04d', a_floatRudicsId) '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'archive' directory used to store the received ASCII files
% IN RT MODE:
% - a 'history_of_processed_data' directory used to store the information on
% previous processings
g_decArgo_archiveDirectory = [floatIriDirName 'archive/'];
if ~(exist(g_decArgo_archiveDirectory, 'dir') == 7)
   mkdir(g_decArgo_archiveDirectory);
end
if (g_decArgo_realtimeFlag)
   g_decArgo_historyDirectory = [floatIriDirName 'history_of_processed_data/'];
   if ~(exist(g_decArgo_historyDirectory, 'dir') == 7)
      mkdir(g_decArgo_historyDirectory);
   end
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = 'WMO #; Cycle #; Info type';
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% initialize RT offset and DO calibration coefficients from JSON meta-data file
init_float_config_nemo(a_decoderId);

% add launch position and time in the TRAJ NetCDF file
if (isempty(g_decArgo_outputCsvFileId))
   o_tabTrajNMeas = add_launch_data_ir_rudics;
end

% inits for output NetCDF file
decArgoConfParamNames = [];
ncConfParamNames = [];
if (isempty(g_decArgo_outputCsvFileId))
   
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   
   % create the configuration parameter names for the META NetCDF file
   [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_nemo(a_decoderId);
end

if (g_decArgo_realtimeFlag)
   
   % if new files have been collected with rsync, we will duplicate and rename
   % them from the DIR_INPUT_RSYNC_DATA to the IRIDIUM_DATA_DIRECTORY before
   % decoding all the IRIDIUM_DATA_DIRECTORY files
   
   % duplicate the files colleted with rsync into the archive directory
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   fprintf('RSYNC_INFO: Duplicating %d .profile files from rsync dir to float archive dir\n', ...
      length(fileIdList));
   
   duplicate_files_ir_nemo(a_floatNum, g_decArgo_rsyncFloatSbdFileList(fileIdList), g_decArgo_dirInputRsyncData, floatIriDirName);
      
   % create list of cycles to decode
   [a_cycleList, ~] = get_float_cycle_list(a_floatNum, num2str(a_floatRudicsId), a_floatLaunchDate, a_decoderId);
   
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, a_cycleList);
end

% retrieve RTC offset and PRES offset from all existing .profile files
% (and collect GPS & Iridium fixes in dedicated global variables)
% .profile files
[g_decArgo_clockOffset, g_decArgo_presOffsetData] = ...
   get_clock_and_pres_offset_nemo(a_floatNum, a_floatRudicsId, g_decArgo_archiveDirectory);

if (0)
   % plot gps time - float surface time adjusted
   idF = find(~isnan(g_decArgo_clockOffset.clockOffsetJuldUtc) & ~isnan(g_decArgo_clockOffset.xmit_surface_start_time));
   delta = g_decArgo_clockOffset.clockOffsetJuldUtc(idF) - ...
      (g_decArgo_clockOffset.startupDate + g_decArgo_clockOffset.xmit_surface_start_time(idF)/86400 - g_decArgo_clockOffset.clockOffsetCounterValue(idF)/86400);
   plot(delta*86400);
   pause
   return
end

% decode .profile files of the cycle list
for idCy = 1:length(a_cycleList)
   
   cycleNum = a_cycleList(idCy);
   g_decArgo_cycleNum = cycleNum;
   
   fprintf('Cycle #%d\n', cycleNum);
   
   % cycle timings storage
   cycleTimeData = get_nemo_float_time_init_struct(cycleNum);

   % retrieve the files of the current cycle
   profileFile = get_nemo_profile_file(a_floatNum, a_floatRudicsId, cycleNum, g_decArgo_archiveDirectory);
   if (g_decArgo_realtimeFlag == 1)
      % update the report structure
      g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles {profileFile}];
   end
   
   % decode the .profile file of the current cycle
   [metaInfo, metaData, configInfo, techInfo, techData, ...
      timeInfo, timeData, parkData, rafosData, profileData] = ...
      decode_nemo_profile_file(profileFile);
   
   % process cycle times
   [cycleTimeData, profileData] = process_cycle_times_nemo( ...
      cycleTimeData, timeData, rafosData, profileData);
   
   % apply pressure adjustment
   [surfPresInfo, parkData, rafosData, profileData, ...
      cycleTimeData, ...
      g_decArgo_presOffsetData] = ...
      adjust_pres_from_surf_offset_nemo(parkData, rafosData, profileData, ...
      cycleTimeData, ...
      g_decArgo_presOffsetData);

   % apply clock offset adjustment
   [clockOffsetInfo, cycleClockOffsetCounter, cycleClockOffsetRtc, rafosData, profileData, cycleTimeData] = ...
      adjust_clock_offset_nemo(rafosData, profileData, cycleTimeData, ...
      g_decArgo_clockOffset);

   % add dates to drift measurements
   [cycleTimeData, parkData] = add_drift_meas_dates_nemo(cycleTimeData, parkData);

   if (~isempty(g_decArgo_outputCsvFileId))
      
      % output CSV file
      print_file_info_in_csv_file_nemo(profileFile);
      
      print_misc_info_in_csv_file_nemo(metaInfo);
      print_misc_info_in_csv_file_nemo(configInfo);
      print_misc_info_in_csv_file_nemo(techInfo);
      print_misc_info_in_csv_file_nemo(timeInfo);
      print_misc_info_in_csv_file_nemo(surfPresInfo);
      print_misc_info_in_csv_file_nemo(clockOffsetInfo);
      
      print_sampled_measurements_rafos_in_csv_file_nemo(rafosData);
      print_sampled_measurements_in_csv_file_nemo(parkData, 'Park');
      print_sampled_measurements_in_csv_file_nemo(profileData, 'Profile');
      
      print_gps_fix_in_csv_file_nemo(g_decArgo_gpsData, cycleNum);
      print_iridium_fix_in_csv_file_nemo(g_decArgo_iridiumData, cycleNum);
      
      print_dates_in_csv_file_nemo(cycleTimeData);
      
   else
      
      % output NetCDF files
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % PROF NetCDF file
      
      % process profile data for PROF NetCDF file
      [cycleProfile] = process_nemo_profile(profileData, ...
         cycleNum, g_decArgo_presOffsetData, ...
         cycleTimeData, g_decArgo_gpsData, g_decArgo_iridiumData);
      
      print = 0;
      if (print == 1)
         if (~isempty(cycleProfile))
            fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
               g_decArgo_floatNum, cycleNum, length(cycleProfile));
            for idP = 1:length(cycleProfile)
               prof = cycleProfile(idP);
               paramList = prof.paramList;
               paramList = sprintf('%s ', paramList.name);
               profLength = size(prof.data, 1);
               fprintf('   ->%2d: dir = %c length = %d param =(%s)\n', ...
                  idP, prof.direction, ...
                  profLength, paramList(1:end-1));
            end
         else
            fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
               g_decArgo_floatNum, cycleNum);
         end
      end
      
      o_tabProfiles = [o_tabProfiles cycleProfile];
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TRAJ NetCDF file
      
      % process trajectory data for TRAJ NetCDF file
      [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_nemo( ...
         cycleNum, ...
         cycleTimeData, techData, ...
         parkData, rafosData, profileData, ...
         cycleClockOffsetCounter, cycleClockOffsetRtc, g_decArgo_presOffsetData, ...
         g_decArgo_gpsData, g_decArgo_iridiumData, ...
         o_tabTrajNMeas, o_tabTrajNCycle);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % TECH NetCDF file
      
      % store technical data for output NetCDF files
      store_tech_data_for_nc_nemo(techData);
      
      % update NetCDF technical data
      update_technical_data_argos_sbd(a_decoderId);
      
      o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
      o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
      
      g_decArgo_outputNcParamIndex = [];
      g_decArgo_outputNcParamValue = [];

   end
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % sort trajectory data structures according to the predefined
   % measurement code order
   o_tabTrajNMeas = sort_trajectory_data(o_tabTrajNMeas, a_decoderId);

   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = update_output_cycle_number_argos( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_nemo( ...
      decArgoConfParamNames, ncConfParamNames);
   
   if (g_decArgo_realtimeFlag == 1)
            
      % save the list of already processed rsync log files in the history
      % directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'processed', ...
         g_decArgo_rsyncLogFileUnderProcessList);
      
      % save the list of used rsync log files in the history directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'used', ...
         unique(g_decArgo_rsyncLogFileUsedList));
   end
   
   % check cycle durations
   %    if (0)
   %       cycleList = unique([o_tabProfiles.cycleNumber]);
   %       for idCy = 2:length(cycleList)
   %          idCur = find([o_tabProfiles.cycleNumber] == cycleList(idCy), 1, 'first');
   %          idPrev = find([o_tabProfiles.cycleNumber] == cycleList(idCy)-1, 1, 'first');
   %          if ((~isempty(idCur) && (o_tabProfiles(idCur).date ~= g_decArgo_dateDef)) && ...
   %                (~isempty(idPrev) && (o_tabProfiles(idPrev).date ~= g_decArgo_dateDef)))
   %             fprintf('DEC_INFO: Float #%d Cycle #%d: Duration %d hours\n', ...
   %                g_decArgo_floatNum, cycleList(idCy), ...
   %                round((o_tabProfiles(idCur).date - o_tabProfiles(idPrev).date)*24));
   %          end
   %       end
   %    end
   
else
         
   % CSV decoder
         
   % check collected meta-data data against float meta-data stored in the
   % JSON file and provide needed updates
   check_meta_data_nemo;
   
end

return
