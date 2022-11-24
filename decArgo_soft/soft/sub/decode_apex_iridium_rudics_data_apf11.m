% ------------------------------------------------------------------------------
% Decode APEX Iridium Rudics data.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = decode_apex_iridium_rudics_data_apf11( ...
%    a_floatNum, a_cycleList, ...
%    a_decoderId, a_floatRudicsId, ...
%    a_floatLaunchDate, a_floatEndDate)
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
%   o_tabTechNMeas   : decoded technical N_MEASUREMENT data
%   o_structConfig   : NetCDF float configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/06/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = decode_apex_iridium_rudics_data_apf11( ...
   a_floatNum, a_cycleList, ...
   a_decoderId, a_floatRudicsId, ...
   a_floatLaunchDate, a_floatEndDate)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechNMeas = [];
o_structConfig = [];

% current float WMO number
global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% float configuration
global g_decArgo_floatConfig;
g_decArgo_floatConfig = [];

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% cycle timings storage
global g_decArgo_timeData;
g_decArgo_timeData = [];
global g_decArgo_cycleTimeData;
g_decArgo_cycleTimeData = [];

% pressure offset storage
global g_decArgo_presOffsetData;
g_decArgo_presOffsetData = get_apx_pres_offset_init_struct;

% clock offset storage
global g_decArgo_clockOffset;

% array to store GPS data
global g_decArgo_gpsData;

% CTD data of the previous cycle (used for derived parameters processing)
global g_decArgo_floatNumPrev;
g_decArgo_floatNumPrev = -1;
global g_decArgo_cycleNumPrev;
g_decArgo_cycleNumPrev = -1;
global g_decArgo_profLrCtdDataPrev;
g_decArgo_profLrCtdDataPrev = -1;
global g_decArgo_profHrCtdDataPrev;
g_decArgo_profHrCtdDataPrev = -1;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;
global g_decArgo_dirInputRsyncData;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_historyDirectory;
global g_decArgo_archiveFloatFilesDirectory;

% mode processing flags
global g_decArgo_realtimeFlag;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% report information structure
global g_decArgo_reportStruct;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1; % since there is no buffer we can process the data each time a new file has been collecte by rsync

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;
g_decArgo_cycleNumListForIce = [];
g_decArgo_cycleNumListIceDetected = [];

% ice float flag
global g_decArgo_iceFloat;
g_decArgo_iceFloat = 0;


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' a_floatRudicsId '_' num2str(a_floatNum) '/'];
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
g_decArgo_archiveFloatFilesDirectory = [floatIriDirName 'archive/float_files/'];
if (exist(g_decArgo_archiveFloatFilesDirectory, 'dir') == 7)
   rmdir(g_decArgo_archiveFloatFilesDirectory, 's');
end
mkdir(g_decArgo_archiveFloatFilesDirectory);

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Info type; File type'];
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% initialize RT offset and DO calibration coefficients from JSON meta-data file
init_float_config_apx_apf11_ir(a_decoderId);
if (isempty(g_decArgo_floatConfig))
   return
end

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
   [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_apx_ir(a_decoderId);
end

if (g_decArgo_realtimeFlag == 1)
   
   % if new files have been collected with rsync, we will duplicate and rename
   % them from the DIR_INPUT_RSYNC_DATA to the IRIDIUM_DATA_DIRECTORY before
   % decoding all the IRIDIUM_DATA_DIRECTORY files
   
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   fprintf('RSYNC_INFO: Duplicating %d float files from rsync dir to float archive dir\n', ...
      length(fileIdList));
   
   for idF = 1:length(fileIdList)
      floatFilePathName = [g_decArgo_dirInputRsyncData '/' ...
         g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
      [pathStr, floatFileName, ext] = fileparts(floatFilePathName);
      duplicate_files_ir({[floatFileName ext]}, pathStr, g_decArgo_archiveDirectory);
   end
   
   % create list of cycles to decode
   [a_cycleList, ~] = get_float_cycle_list(a_floatNum, a_floatRudicsId, a_floatLaunchDate, a_decoderId);
   
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, a_cycleList);
end

% create list of float files to decode
cycleFileNameList = get_cycle_float_file_list_iridium_rudics_apx_apf11( ...
   a_floatNum, a_floatRudicsId, a_cycleList, a_floatLaunchDate);

% uncompress float files
nbFloatFiles = 0;
for idFile = 1:length(cycleFileNameList)
   
   floatFileName = [g_decArgo_archiveDirectory cycleFileNameList{idFile}];
   gunzip(floatFileName, g_decArgo_archiveFloatFilesDirectory);
   
   nbFloatFiles = nbFloatFiles + 1;
   
   if (g_decArgo_realtimeFlag == 1)
      % update the report structure
      g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles {floatFileName}];
   end
end

fprintf('DEC_INFO: %d float files to process\n', nbFloatFiles);

% retrieve RTC offset information from all existing log files
g_decArgo_clockOffset = get_clock_offset_apx_ir_rudics_apf11(a_floatRudicsId, a_cycleList);

% decode float files of the cycle list
for idCy = 1:length(a_cycleList)
   
   cycleNum = a_cycleList(idCy);
   g_decArgo_cycleNum = cycleNum;
   
   fprintf('Cycle #%d\n', cycleNum);
   
   % cycle timings storage
   cycleTimeData = get_apx_apf11_ir_float_time_init_struct(cycleNum);

   % retrieve the float files of the current cycle
   [scienceLogFileList, vitalsLogFileList, ...
      systemLogFileList, criticalLogFileList, ...
      productionLogFileList] = get_files_iridium_apx_apf11( ...
      a_floatRudicsId, cycleNum, g_decArgo_archiveFloatFilesDirectory);
   
   % decode the files of the current cycle
   if (ismember(a_decoderId, [1121, 1122, 1123]))
      % (2.10.4.R & 2.11.3.R), 2.13.1.R, 2.12.3.R
         
      [miscInfoSci, miscInfoSys, miscEvtsSys, ...
         metaData, missionCfg, sampleCfg, ...
         profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
         profCtdCp, profCtdCpH, profFlbbCd, profOcr504I, ...
         gpsDataSci, gpsDataSys, grounding, iceDetection, buoyancy, ...
         vitalsData, techData, productionData, ...
         cycleTimeData, g_decArgo_presOffsetData] = ...
         decode_apx_apf11_ir(scienceLogFileList, vitalsLogFileList, ...
         systemLogFileList, criticalLogFileList, productionLogFileList, ...
         cycleTimeData, g_decArgo_presOffsetData, a_decoderId);

      % update the configuration and assign it to the current cycle
      update_float_config_apx_apf11_ir(missionCfg, sampleCfg);
      
      % compute additional dates (DESCENT_END_TIME and DEEP_DESCENT_END_TIME)
      cycleTimeData = compute_additional_times_apx_apf11_ir(cycleTimeData, profCtdP);
      
      % process GPS data of previous and current cycle:
      % - merge GPS data from both sources (science_log and system_log files)
      % - store GPS data
      % - compute JAMSTEC QC for the GPS locations
      store_gps_data_apx_apf11_ir(gpsDataSci, gpsDataSys, g_decArgo_cycleNum);
                  
      % apply pressure adjustment
      [profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
         profCtdCp, profCtdCpH, profFlbbCd, profOcr504I, ...
         grounding, iceDetection, buoyancy, cycleTimeData, g_decArgo_presOffsetData] = ...
         adjust_pres_from_surf_offset_apx_apf11_ir( ...
         profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
         profCtdCp, profCtdCpH, profFlbbCd, profOcr504I, ...
         grounding, iceDetection, buoyancy, cycleTimeData, g_decArgo_presOffsetData);
      
      % compute derived parameters
      [profDo, ...
         profCtdPtsh, profCtdCpH, profFlbbCd] = ...
         compute_derived_parameters_apx_apf11_ir( ...
         profCtdPts, profCtdCp, profDo, ...
         profCtdPtsh, profCtdCpH, profFlbbCd, ...
         cycleTimeData, a_decoderId);
      
      % apply clock offset adjustment
      [profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
         profCtdCp, profCtdCpH, profFlbbCd, profOcr504I, ...
         grounding, iceDetection, buoyancy, ...
         vitalsData, ...
         cycleClockOffset, cycleTimeData] = ...
         adjust_clock_offset_apx_apf11_ir( ...
         profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
         profCtdCp, profCtdCpH, profFlbbCd, profOcr504I, ...
         grounding, iceDetection, buoyancy, ...
         vitalsData, ...
         cycleTimeData, ...
         g_decArgo_clockOffset);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % check meta-data VS data base contents
         if (~isempty(metaData))
            check_meta_data_apx_apf11(metaData);
         end
         
         % output CSV file
         print_file_info_in_csv_file_apx_apf11(scienceLogFileList, vitalsLogFileList, ...
            systemLogFileList, criticalLogFileList, productionLogFileList);

         print_event_apx_apf11_in_csv_file(productionData, 'Prod');
         print_event_apx_apf11_in_csv_file(miscEvtsSys, 'Sys');

         print_config_mission_info_apx_apf11_in_csv_file(missionCfg);
         print_config_sample_info_apx_apf11_in_csv_file(sampleCfg);
         
         print_vitals_info_apx_apf11_in_csv_file(vitalsData);
         
         print_misc_info_in_csv_file(miscInfoSci, 'Sci');
         print_misc_info_in_csv_file(miscInfoSys, 'Sys');
         
         print_ice_info_apx_apf11_in_csv_file(iceDetection);
         
         print_time_info_apx_apf11_in_csv_file(cycleTimeData);
         
         %          print_sampled_measurements_in_csv_file_apx_apf11(profCtdP, 'CTD_P');
         print_sampled_measurements_in_csv_file_apx_apf11(profCtdPt, 'CTD_PT');
         print_sampled_measurements_in_csv_file_apx_apf11(profCtdPts, 'CTD_PTS');
         print_sampled_measurements_in_csv_file_apx_apf11(profCtdPtsh, 'CTD_PTSH');
         print_sampled_measurements_in_csv_file_apx_apf11(profDo, 'O2');
         print_sampled_measurements_in_csv_file_apx_apf11(profCtdCp, 'CTD_CP');
         print_sampled_measurements_in_csv_file_apx_apf11(profCtdCpH, 'CTD_CP_H');
         print_sampled_measurements_in_csv_file_apx_apf11(profFlbbCd, 'FLBB_CD');
         print_sampled_measurements_in_csv_file_apx_apf11(profOcr504I, 'OCR_504I');
         
         print_gps_fix_in_csv_file_apx_apf11(g_decArgo_gpsData, g_decArgo_cycleNum-1);
         print_gps_fix_in_csv_file_apx_apf11(g_decArgo_gpsData, g_decArgo_cycleNum);
         
         print_clock_offset_apx_apf11_in_csv_file(cycleClockOffset);
         
         print_dates_apx_apf11_in_csv_file( ...
            profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
            profFlbbCd, profOcr504I, ...
            cycleTimeData, g_decArgo_gpsData, ...
            grounding, buoyancy, vitalsData);
         
      else
         
         % remove the unused entries of the profiles
         [profDo, profFlbbCd] = ...
            remove_parameter_from_profile_apx_apf11_ir(profDo, profFlbbCd);
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         [cycleProfile] = process_apx_apf11_ir_profile( ...
            profCtdPts, profCtdPtsh, profDo, ...
            profCtdCp, profCtdCpH, ...
            profFlbbCd, profOcr504I, ...
            cycleTimeData, ...
            cycleNum, g_decArgo_presOffsetData);
         
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
                  fprintf('   ->%2d: dir = %c length = %d param =(%s)\n', ...
                     idP, prof.direction, ...
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
         
         % process trajectory data for TRAJ NetCDF file
         [o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
            process_trajectory_data_apx_apf11_ir( ...
            cycleNum, ...
            profCtdP, profCtdPt, profCtdPts, profCtdPtsh, profDo, ...
            profCtdCp, profCtdCpH, profFlbbCd, profOcr504I, ...
            g_decArgo_gpsData, grounding, iceDetection, buoyancy, ...
            cycleTimeData, ...
            g_decArgo_clockOffset, ...
            o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % store technical data for output NetCDF files
         store_tech_data_for_nc_apx_ir(techData);
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
         % create time series of technical data
         tabTechNMeas = create_technical_time_series_apx_apf11_ir( ...
            vitalsData, cycleTimeData, iceDetection, g_decArgo_cycleNum);
         
         if (~isempty(tabTechNMeas))
            o_tabTechNMeas = [o_tabTechNMeas; tabTechNMeas];
         end
         
      end
      
      g_decArgo_timeData = [g_decArgo_timeData cycleTimeData];
   else
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apex_iridium_rudics_data_apf11 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
   end
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % sort trajectory data structures according to the predefined
   % measurement code order
   o_tabTrajNMeas = sort_trajectory_data(o_tabTrajNMeas, a_decoderId);
   
   % add profile date and location information
   o_tabProfiles = add_profile_date_and_location_apx_ir_rudics( ...
      o_tabProfiles, g_decArgo_gpsData, o_tabTrajNMeas, o_tabTrajNCycle);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
      update_output_cycle_number_ir_sbd( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas);

   % perform DOXY, CHLA and NITRATE adjustment
   [o_tabProfiles] = compute_rt_adjusted_param(o_tabProfiles, a_floatLaunchDate, 1);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistency
   [o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNCycle, o_tabTrajNMeas);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_apx_ir( ...
      decArgoConfParamNames, ncConfParamNames, a_decoderId);
   
   if (g_decArgo_realtimeFlag == 1)
      
      % save the list of already processed rsync log files in the history
      % directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'processed', ...
         g_decArgo_rsyncLogFileUnderProcessList);
      
      % save the list of used rsync log files in the history directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'used', ...
         unique(g_decArgo_rsyncLogFileUsedList));
   end
   
end

return
