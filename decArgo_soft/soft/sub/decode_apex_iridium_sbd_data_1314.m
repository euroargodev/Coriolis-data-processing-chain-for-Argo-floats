% ------------------------------------------------------------------------------
% Decode APEX Iridium SBD data.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, ...
%    o_structConfig] = decode_apex_iridium_sbd_data_1314( ...
%    a_floatNum, a_decoderId, a_floatImei, ...
%    a_floatLaunchDate, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_decoderId       : float decoder Id
%   a_floatImei       : float Rudics Id
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
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, ...
   o_structConfig] = decode_apex_iridium_sbd_data_1314( ...
   a_floatNum, a_decoderId, a_floatImei, ...
   a_floatLaunchDate, a_floatEndDate)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_structConfig = [];

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

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

% configuration creation flag
global g_decArgo_configDone;
g_decArgo_configDone = 0;

% cycle timings storage
global g_decArgo_timeData;
g_decArgo_timeData = get_apx_ir_float_time_init_struct;

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
global g_decArgo_archiveSbdDirectory;
global g_decArgo_archiveAsciiDirectory;
global g_decArgo_archiveAsciiRawDirectory;

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

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


REPROCESS = 1; % to skip .log and .msg generation step (in debug mode)

% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' sprintf('%04d', a_floatImei) '_' num2str(a_floatNum) '/'];
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
g_decArgo_archiveSbdDirectory = [floatIriDirName 'archive/sbd/'];
if (REPROCESS == 1)
   if (exist(g_decArgo_archiveSbdDirectory, 'dir') == 7)
      rmdir(g_decArgo_archiveSbdDirectory, 's');
   end
   mkdir(g_decArgo_archiveSbdDirectory);
end
g_decArgo_archiveAsciiRawDirectory = [floatIriDirName 'archive/ascii_raw/'];
if (REPROCESS == 1)
   if (exist(g_decArgo_archiveAsciiRawDirectory, 'dir') == 7)
      rmdir(g_decArgo_archiveAsciiRawDirectory, 's');
   end
   mkdir(g_decArgo_archiveAsciiRawDirectory);
end
g_decArgo_archiveAsciiDirectory = [floatIriDirName 'archive/ascii/'];
if (REPROCESS == 1)
   if (exist(g_decArgo_archiveAsciiDirectory, 'dir') == 7)
      rmdir(g_decArgo_archiveAsciiDirectory, 's');
   end
   mkdir(g_decArgo_archiveAsciiDirectory);
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Info type; File type; Info #'];
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% initialize RT offset and DO calibration coefficients from JSON meta-data file
[floatRudicsId, stopFlag] = init_float_config_apx_ir(a_decoderId);
if (stopFlag)
   return
end

% print DOXY and FLBB coef in the output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   print_calib_coef_in_csv_file(a_decoderId);
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
   [decArgoConfParamNames, ncConfParamNames, ncConfParamIds] = create_config_param_names_apx_ir(a_decoderId);
end

if (g_decArgo_realtimeFlag == 1)
   
   % if new mail files have been collected with rsync, we are going to decode
   % all (archived and newly received) mail files
   
   % duplicate the Iridium mail files colleted with rsync from the
   % DIR_INPUT_RSYNC_DATA to the IRIDIUM_DATA_DIRECTORY
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   fprintf('RSYNC_INFO: Duplicating %d Iridium mail files from rsync dir to float archive dir\n', ...
      length(fileIdList));
   
   for idF = 1:length(fileIdList)
      mailFilePathName = [g_decArgo_dirInputRsyncData '/' ...
         g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
      [pathstr, mailFileName, ext] = fileparts(mailFilePathName);
      duplicate_files_ir({[mailFileName ext]}, pathstr, g_decArgo_archiveDirectory);
   end
   
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, '');
end
   
% create list of mail files to decode
realtimeFlagTmp = g_decArgo_realtimeFlag;
g_decArgo_realtimeFlag = 0;
[cycleFileNameList, ~] = get_float_cycle_list(a_floatNum, num2str(a_floatImei), a_floatLaunchDate, a_decoderId);
g_decArgo_realtimeFlag = realtimeFlagTmp;

% store mail file information and extract attachment
nbMailFiles = 0;
mailContentsTab = repmat(get_iridium_mail_init_struct(''), 1, length(cycleFileNameList));
cptMailCont = 1;
for idFile = 1:length(cycleFileNameList)
   
   mailFileName = cycleFileNameList{idFile};
   cyIrJulD = datenum([mailFileName(4:11) mailFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   if (cyIrJulD < a_floatLaunchDate)
      fprintf('DEC_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
         g_decArgo_floatNum, ...
         mailFileName, julian_2_gregorian_dec_argo(a_floatLaunchDate));
      continue
   end
   
   if (a_floatEndDate ~= g_decArgo_dateDef)
      if (cyIrJulD > a_floatEndDate)
         fprintf('DEC_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
            g_decArgo_floatNum, ...
            mailFileName, julian_2_gregorian_dec_argo(a_floatEndDate));
         continue
      end
   end
   
   nbMailFiles = nbMailFiles + 1;
   
   % extract the attachement
   if (REPROCESS == 1)
      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         mailFileName, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   else
      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         mailFileName, g_decArgo_archiveDirectory, []);
   end
   if (~isempty(mailContents))
      mailContentsTab(cptMailCont) = mailContents;
      cptMailCont = cptMailCont + 1;
   end

   if (g_decArgo_realtimeFlag == 1)
      % update the report structure
      g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles {mailFileName}];
   end
   
end
mailContentsTab(cptMailCont:end) = [];
g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContentsTab];

fprintf('DEC_INFO: %d Iridium mail files to process\n', nbMailFiles);

% convert SBD files to raw .msg and .log ASCII files
[nbSbdFiles, nbAsciiFiles] = convert_sbd_files_apex_iridium_sbd(g_decArgo_archiveSbdDirectory, g_decArgo_archiveAsciiRawDirectory);
fprintf('DEC_INFO: %d SBD files to process\n', nbSbdFiles);
fprintf('DEC_INFO: %d raw .msg or .log files to process\n', nbAsciiFiles);

% rename (and concat if needed) raw .msg and .log ASCII files so that they
% can be processed by the decoder
[nbMsgFiles, nbLogFiles] = duplicate_files_ir_sbd_apx( ...
   a_floatNum, a_decoderId, a_floatLaunchDate, a_floatEndDate, ...
   g_decArgo_archiveAsciiRawDirectory, g_decArgo_archiveAsciiDirectory);
fprintf('DEC_INFO: %d final .msg and %d final .log files to process\n', nbMsgFiles, nbLogFiles);

% retrieve RTC offset information from all existing log files
[g_decArgo_clockOffset, cycleList] = get_clock_offset_apx_ir_sbd_apf9(a_floatNum, ...
   a_floatImei, floatRudicsId, a_decoderId);

if (g_decArgo_realtimeFlag == 1)
   % update the report structure
   g_decArgo_reportStruct = add_cycle_number_in_report_struct(g_decArgo_reportStruct, cycleList);
end

% decode msg and log file of the cycle list
for idCy = 1:length(cycleList)
   
   cycleNum = cycleList(idCy);
   g_decArgo_cycleNum = cycleNum;
      
   fprintf('Cycle #%d\n', cycleNum);
   
   % retrieve the files of the current cycle
   [msgFileList, logFileList] = get_files_iridium_apx( ...
      a_floatNum, floatRudicsId, cycleNum, g_decArgo_archiveAsciiDirectory);
   
   % decode the files of the current cycle
   
   % 090215
   if (ismember(a_decoderId, [1314]))
      
      [miscInfoMsg, miscInfoLog, ...
         configInfoMsg, configInfoLog, techInfo, techData, ...
         surfDataLog, ...
         gpsDataLog, gpsInfoLog, ...
         pMarkDataMsg, pMarkDataLog, ...
         driftData, parkData, parkDataEng, ...
         profLrData, profHrData, profEndDateMsg, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, surfDataMsg, ...
         gpsDataMsg, gpsInfoMsg, ...
         timeDataLog, ...
         g_decArgo_presOffsetData] = ...
         decode_apx_ir(msgFileList, logFileList, g_decArgo_presOffsetData, a_decoderId);
      
      % create the configuration and assign it to the current cycle
      create_float_config_apx_ir(configInfoLog, configInfoMsg, a_decoderId);
      
      % compute additional dates
      timeDataLog = compute_additional_times_apx_ir(timeDataLog, driftData, a_decoderId);
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle (from .msg file) and check that those of the previous
      % cycle (from .log file) are already stored
      techData = store_gps_data_apx_ir(gpsDataLog, gpsDataMsg, g_decArgo_cycleNum, techData);
      
      % apply pressure adjustment
      [surfPresInfo, surfDataLog, ...
         pMarkDataMsg, pMarkDataLog, ...
         driftData, parkData, parkDataEng, ...
         profLrData, profHrData, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, surfDataMsg, ...
         timeDataLog, ...
         g_decArgo_presOffsetData] = ...
         adjust_pres_from_surf_offset_apx_ir(surfDataLog, ...
         pMarkDataMsg, pMarkDataLog, ...
         driftData, parkData, parkDataEng, ...
         profLrData, profHrData, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, surfDataMsg, ...
         timeDataLog, ...
         g_decArgo_presOffsetData);
      
      % compute derived parameters
      [surfDataLog, ...
         driftData, parkData, parkDataEng, ...
         profLrData, profHrData, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, surfDataMsg, ...
         timeDataLog] = ...
         compute_derived_parameters_apx_ir(surfDataLog, ...
         driftData, parkData, parkDataEng, ...
         profLrData, profHrData, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, surfDataMsg, ...
         timeDataLog, ...
         a_decoderId);
      
      % apply clock offset adjustment
      [surfDataLog, ...
         pMarkDataLog, ...
         driftData, parkData, ...
         profLrData, ...
         profEndAdjDateMsg, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, ...
         timeDataLog] = ...
         adjust_clock_offset_apx_ir(surfDataLog, ...
         pMarkDataLog, ...
         driftData, parkData, ...
         profLrData, ...
         profEndDateMsg, ...
         nearSurfData, ...
         surfDataBladderDeflated, surfDataBladderInflated, ...
         timeDataLog, ...
         g_decArgo_clockOffset);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         print_file_info_in_csv_file(msgFileList, logFileList);
         
         print_misc_info_in_csv_file(configInfoMsg, 'Msg');
         print_misc_info_in_csv_file(configInfoLog, 'Log');
         
         print_misc_info_in_csv_file(techInfo, 'Msg');
         print_misc_info_in_csv_file(surfPresInfo, 'Surf. P');
         print_sampled_measurements_in_csv_file_apx_ir(surfDataLog, 'Surf. (evts)', 'Log', -1);
         print_gps_fix_in_csv_file(gpsDataLog, 'Log', -1);
         print_misc_info_in_csv_file(miscInfoMsg, 'Msg');
         print_misc_info_in_csv_file(miscInfoLog, 'Log');
         print_sampled_measurements_in_csv_file_apx_ir(pMarkDataMsg, 'PMark', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(pMarkDataLog, 'PMark (evts)', 'Log', 0);
         print_sampled_measurements_in_csv_file_apx_ir(driftData, 'Drift', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(parkData, 'Park', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(parkDataEng, 'Park (eng)', 'Msg', 0);
         if (~isempty(timeDataLog) && ~isempty(timeDataLog.parkEndMeas))
            print_sampled_measurements_in_csv_file_apx_ir(timeDataLog.parkEndMeas, 'Park (evts)', 'Log', 0);
         end
         print_sampled_measurements_in_csv_file_apx_ir(profLrData, 'Profile LR', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(profHrData, 'Profile HR', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(nearSurfData, 'Near surf.', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(surfDataBladderDeflated, 'Surf. blad. defl.', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(surfDataBladderInflated, 'Surf. blad. infl.', 'Msg', 0);
         print_sampled_measurements_in_csv_file_apx_ir(surfDataMsg, 'Surf.', 'Msg', 0);
         print_gps_fix_in_csv_file(gpsDataMsg, 'Msg', 0);
         
         print_clock_offset_in_csv_file(g_decArgo_clockOffset);
         print_dates_in_csv_file_apx_ir(surfDataLog, ...
            pMarkDataLog, ...
            driftData, parkData, ...
            profLrData, ...
            nearSurfData, ...
            surfDataBladderDeflated, surfDataBladderInflated, ...
            timeDataLog, ...
            profEndDateMsg, profEndAdjDateMsg, ...
            gpsDataLog, gpsDataMsg);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         [cycleProfile] = process_apx_ir_profile(profLrData, profHrData, nearSurfData, ...
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
         [o_tabTrajNMeas, o_tabTrajNCycle] = process_trajectory_data_apx_ir( ...
            g_decArgo_cycleNum, ...
            surfDataLog, ...
            pMarkDataMsg, pMarkDataLog, ...
            driftData, parkData, parkDataEng, ...
            profLrData, profHrData, ...
            nearSurfData, ...
            surfDataBladderDeflated, surfDataBladderInflated, surfDataMsg, ...
            timeDataLog, g_decArgo_gpsData, ...
            profEndDateMsg, profEndAdjDateMsg, ...
            g_decArgo_clockOffset, g_decArgo_presOffsetData, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            (~isempty(configInfoMsg) || ~isempty(configInfoLog)), ...
            a_decoderId);
         
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
         
      end
   else
      fprintf('WARNING: Float #%d Cycle #%d: Nothing done yet in decode_apex_iridium_sbd_data_1314 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         a_decoderId);
   end
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % set cycle numbers to Iridium mail files data
   update_mail_data_apx_ir_sbd(o_tabTrajNMeas);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = update_output_cycle_number_argos( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);

   % add Iridium location in trajectory data
   [o_tabTrajNMeas, o_tabTrajNCycle] = ...
      add_iridium_locations_in_trajectory_data( ...
      o_tabTrajNMeas, o_tabTrajNCycle, g_decArgo_iridiumMailData);
   
   % sort trajectory data structures according to the predefined
   % measurement code order
   o_tabTrajNMeas = sort_trajectory_data(o_tabTrajNMeas, a_decoderId);
   
   % add profile date and location information
   o_tabProfiles = add_profile_date_and_location_apx_ir_sbd( ...
      o_tabProfiles, g_decArgo_gpsData, g_decArgo_iridiumMailData, o_tabTrajNMeas, o_tabTrajNCycle);

   % add interpolated/extrapolated profile locations
   o_tabProfiles = fill_empty_profile_locations_ir_sbd(g_decArgo_gpsData, o_tabProfiles);

   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_apx_ir( ...
      decArgoConfParamNames, ncConfParamNames, ncConfParamIds, a_decoderId);
   
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
