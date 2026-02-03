% ------------------------------------------------------------------------------
% Decode Arvor PFV2 float with Iridium SBD transmission.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas, ...
%    o_structConfig] = ...
%    decode_arvor_pfv2_iridium_sbd( ...
%    a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
%    a_launchDate, a_refDay, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_cycleFileNameList : list of mail files to be decoded
%   a_decoderId         : float decoder Id
%   a_floatImei         : float IMEI
%   a_launchDate        : launch date
%   a_refDay            : reference day
%   a_floatEndDate      : end date of the data to process
%
% OUTPUT PARAMETERS :
%   o_tabProfiles     : decoded profiles
%   o_tabTrajNMeas    : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle   : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex  : decoded technical index information
%   o_tabNcTechVal    : decoded technical data
%   o_tabTechNMeas    : decoded technical N_MEASUREMENT data
%   o_tabTechAuxNMeas : decoded technical N_MEASUREMENT AUX data
%   o_structConfig    : NetCDF float configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/14/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas, ...
   o_structConfig] = ...
   decode_arvor_pfv2_iridium_sbd( ...
   a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
   a_launchDate, a_refDay, a_floatEndDate)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechNMeas = [];
o_tabTechAuxNMeas = [];
o_structConfig = [];

% current float WMO number
global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% SBD sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_archiveSbdDirectory;
global g_decArgo_archiveDataGzDirectory
global g_decArgo_archiveDataDirectory
global g_decArgo_historyDirectory;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% decoder configuration values
global g_decArgo_dirInputRsyncData;
global g_decArgo_applyRtqc;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 0;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% float configuration
global g_decArgo_floatConfig;

% clock offset management
global g_decArgo_clockOffset;
g_decArgo_clockOffset = get_clock_offset_prv_ir_init_struct;

% TET management
global g_decArgo_transTimes;
g_decArgo_transTimes = get_pfv2_trans_times_init_struct;

% delay to recover config messages before launch date
global g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;

% mission, loop and cycle management
global g_decArgo_missionLoopCycle;
g_decArgo_missionLoopCycle = get_pfv2_mission_loop_cycle_init_struct;

% unique counter for techTime.groupId
global g_decArgo_tecTimeGroupCpt;
g_decArgo_tecTimeGroupCpt = 0;

% management of meta-data transmitted in TECH files
global g_decArgo_metaFromTech
g_decArgo_metaFromTech = get_pfv2_meta_from_tech_init_struct;

% debug mode (to avoid creating float files from SBD)
global g_decArgo_pfv2DebugMode
g_decArgo_pfv2DebugMode = 0;


if (g_decArgo_pfv2DebugMode)
   fprintf('\n*********************************************************************\n');
   fprintf('DEC_INFO: processing float in DEBUG mode (using existing float files)\n');
   fprintf('*********************************************************************\n\n');
end

% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' num2str(a_floatImei) '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'archive' directory used to store the received mail files
% - a 'archive/sbd' directory used to store the received SBD files
% - a 'archive/data_gz' directory used to store the float zipped files
% - a 'archive/data' directory used to store the float files
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
if (exist(g_decArgo_archiveSbdDirectory, 'dir') == 7)
   rmdir(g_decArgo_archiveSbdDirectory, 's');
end
mkdir(g_decArgo_archiveSbdDirectory);
g_decArgo_archiveDataGzDirectory = [floatIriDirName 'archive/data_gz/'];
if (exist(g_decArgo_archiveDataGzDirectory, 'dir') == 7)
   rmdir(g_decArgo_archiveDataGzDirectory, 's');
end
mkdir(g_decArgo_archiveDataGzDirectory);
g_decArgo_archiveDataDirectory = [floatIriDirName 'archive/data/'];
if (~g_decArgo_pfv2DebugMode)
   if (exist(g_decArgo_archiveDataDirectory, 'dir') == 7)
      rmdir(g_decArgo_archiveDataDirectory, 's');
   end
   mkdir(g_decArgo_archiveDataDirectory);
else
   if ~(exist(g_decArgo_archiveDataDirectory, 'dir') == 7)
      mkdir(g_decArgo_archiveDataDirectory);
   end
end

% inits for output NetCDF file
decArgoConfParamNames = [];
ncConfParamNames = [];
ncConfParamIds = [];
if (isempty(g_decArgo_outputCsvFileId))
   
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   
   % create the configuration parameter names for the META NetCDF file
   [decArgoConfParamNames, ncConfParamNames, ncConfParamIds] = create_config_param_names_pfv2;
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = 'WMO #; Mission #; Cycle #; Info type';
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% initialize float parameter configuration
init_float_config_ir_sbd(a_launchDate, a_decoderId);
if (isempty(g_decArgo_floatConfig))
   return
end

% print DOXY coef in the output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   print_calib_coef_in_csv(a_decoderId);
end

% add launch position and time in the TRAJ NetCDF file
if (isempty(g_decArgo_outputCsvFileId))
   o_tabTrajNMeas = add_launch_data_ir_sbd;
end

if (~g_decArgo_realtimeFlag)
   
   % move the mail files associated with the a_cycleList cycles into the spool
   % directory
   nbFiles = 0;
   for idFile = 1:length(a_cycleFileNameList)
      
      mailFileName = a_cycleFileNameList{idFile};
      cyIrJulD = datenum([mailFileName(4:11) mailFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      if (cyIrJulD < a_launchDate - g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate)
         fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
            g_decArgo_floatNum, ...
            mailFileName, julian_2_gregorian_dec_argo(a_launchDate));
         continue
      elseif (cyIrJulD < a_launchDate)
         fprintf('BUFF_WARNING: Float #%d: mail file "%s" processed for parameter packets only\n', ...
            g_decArgo_floatNum, ...
            mailFileName);
      end

      if (a_floatEndDate ~= g_decArgo_dateDef)

         cyIrJulD = datenum([mailFileName(4:11) mailFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
         if (cyIrJulD > a_floatEndDate)
            fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
               g_decArgo_floatNum, ...
               mailFileName, julian_2_gregorian_dec_argo(a_floatEndDate));
            continue
         end
      end
      
      add_to_list_ir_sbd(mailFileName, 'spool');
      nbFiles = nbFiles + 1;
   end
   
   fprintf('BUFF_INFO: %d Iridium mail files moved from float archive dir to float spool dir\n', nbFiles);
else
   
   % new mail files have been collected with rsync, we are going to decode
   % all (archived and newly received) mail files
   
   % duplicate the Iridium mail files colleted with rsync into the archive
   % directory
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   fprintf('RSYNC_INFO: Duplicating %d Iridium mail files from rsync dir to float archive dir\n', ...
      length(fileIdList));
   
   for idF = 1:length(fileIdList)
      mailFilePathName = [g_decArgo_dirInputRsyncData '/' ...
         g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
      [pathstr, mailFileName, ext] = fileparts(mailFilePathName);
      duplicate_files_ir({[mailFileName ext]}, pathstr, g_decArgo_archiveDirectory);
   end
   
   % move the mail files from archive to the spool directory
   fileList = dir([g_decArgo_archiveDirectory '*.txt']);
   if (~isempty(fileList))
      fprintf('BUFF_INFO: Moving %d Iridium mail files from float archive dir to float spool dir\n', ...
         length(fileList));
      
      nbFiles = 0;
      for idF = 1:length(fileList)
         
         mailFileName = fileList(idF).name;
         cyIrJulD = datenum([mailFileName(4:11) mailFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
         
         if (cyIrJulD < a_launchDate - g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate)
            fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
               g_decArgo_floatNum, ...
               mailFileName, julian_2_gregorian_dec_argo(a_launchDate));
            continue
         elseif (cyIrJulD < a_launchDate)
            fprintf('BUFF_WARNING: Float #%d: mail file "%s" processed for parameter packets only\n', ...
               g_decArgo_floatNum, ...
               mailFileName);
         end
         
         if (a_floatEndDate ~= g_decArgo_dateDef)
            if (cyIrJulD > a_floatEndDate)
               fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
                  g_decArgo_floatNum, ...
                  mailFileName, julian_2_gregorian_dec_argo(a_floatEndDate));
               continue
            end
         end
         
         add_to_list_ir_sbd(mailFileName, 'spool');
         nbFiles = nbFiles + 1;
      end
      
      fprintf('BUFF_INFO: %d Iridium mail files moved from float archive dir to float spool dir\n', nbFiles);
   end
end

if ((g_decArgo_realtimeFlag) || ...
      (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc)))
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, '');
end

% ignore duplicated mail files (move duplicates in the archive directory)
ignore_duplicated_mail_files;

% retrieve information on spool directory contents
[tabMailFileName, ~, tabMailFileDate, ~] = get_list_files_info_ir_sbd('spool', '');

fprintf('\nDEC_INFO: processing %d mail files\n', length(tabMailFileName));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% read email file, store Iridium information and extract attachment (SBD file)

mailContentsTab = repmat(get_iridium_mail_init_struct(''), 1, length(tabMailFileName));
cptMailCont = 1;
mailWithSbd = [];
for idSpoolFile = 1:length(tabMailFileName)
   
   curMailFile = tabMailFileName{idSpoolFile};
      
   % move the current file into the buffer directory
   add_to_list_ir_sbd(curMailFile, 'buffer');
   remove_from_list_ir_sbd(curMailFile, 'spool', 0, 1);
   
   % extract the attachement
   [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
      curMailFile, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   if (~isempty(mailContents))
      mailContentsTab(cptMailCont) = mailContents;
      cptMailCont = cptMailCont + 1;
   end
   if (attachmentFound == 1)
      mailWithSbd = [mailWithSbd idSpoolFile];
   end
   
   % move the current file into the archive directory
   % (and delete the associated SBD files)
   remove_from_list_ir_sbd(curMailFile, 'buffer', 1, 1);
end
mailContentsTab(cptMailCont:end) = [];
g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContentsTab];

fprintf('DEC_INFO: %d sbd files received\n', length(mailWithSbd));

fprintf('\nDEC_INFO: generating float files\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create float files from SBD

% fileInfo : float file information
% 1: float HEX base file Name
% 2: float final file name
% 3: zip file size
% 4: final file size
% 5: SBD file information (1: SBD file name, 2: SBD file date, 3: SBD file size, 4: data file size)

fileInfo = create_data_files_pfv2(tabMailFileName(mailWithSbd), tabMailFileDate(mailWithSbd), ...
   g_decArgo_archiveSbdDirectory, ...
   g_decArgo_archiveDataDirectory, g_decArgo_archiveDataGzDirectory);

if (isempty(fileInfo))
   fprintf('DEC_INFO: Float #%d: No data\n', ...
      g_decArgo_floatNum);
   rmdir(g_decArgo_archiveSbdDirectory, 's');
   rmdir(g_decArgo_archiveDataGzDirectory, 's');
   rmdir(g_decArgo_archiveDataDirectory, 's');
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% decode float files

% floatData : float data information
% 1: fileType
%    (10: selfTest, 11: tech_1, 12: tech_2, 13: eol,
%     20: desc2Park, 21: parkDrift, 22: desc2Prof, 23: profDrift, 24: asc, 25: inAir,
%     30: config, 40: command
%     -1: erroneous file (inconsistent name))
% 2: missionNum
% 3: cycleNum
% 4: fileName
% 5: tabTechEvt or tabTech or sensorNum or confLabels
% 6: tabTechTime or formatNum or confValues
% 7: tabTechTraj or measData
% 8: tabTechBuoy
% 9: tabTechSpy
% 10: selfTestDate or settingDate or cycleLastDate
% 11: float HEX base file Name
% 12: float final file name
% 13: zip file size
% 14: final file size
% 15: SBD file information (1: SBD file name, 2: SBD file date, 3: SBD file size, 4: data file size

floatData = decode_pfv2_data_files(fileInfo, a_decoderId);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create decoding buffers

% buffers : buffers information
% 1: index to float data array
% 2: rank
% 3: cycleNum
% 4: buffer completed
% 5: data type
% 6: sensor #1 data flag
% 7 to 12: nb meas from sensor #1 for phases #0 to #5
% 13: sensor #2 data flag
% 14 to 19: nb meas from sensor #2 for phases #0 to #5
% 20: sensor #3 data flag
% 21 to 26: nb meas from sensor #3 for phases #0 to #5

floatBuffers = create_decoding_buffers_pfv2(floatData, a_decoderId);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process decoded data

if (~isempty(g_decArgo_outputCsvFileId))

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % check meta-data transmitted in TECH file against BDD contents
   check_pfv2_tech_vs_bdd;

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % print file transmission information
   print_pfv2_file_trans_info(floatData);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % print ALL received data for CSV output
   for idFile = 1:size(floatData, 1)
      switch(floatData{idFile, 1})
         case {10, 11, 12, 13}
            print_pfv2_tech_data_in_csv([floatData(idFile, :)]);
         case {20, 21, 22, 23, 24, 25}
            print_pfv2_meas_data_in_csv([floatData(idFile, :)]);
         case {30}
            idPrev = find([floatData{1:idFile-1, 1}] == 30, 1, 'last');
            if (isempty(idPrev))
               print_pfv2_conf_data_in_csv([floatData(idFile, :)]);
            else
               print_pfv2_conf_diff_data_in_csv([floatData(idFile, :)], [floatData(idPrev, :)]);
            end
      end
   end

else
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % process ONLY COMPLETED received data for NetCDF output
   bufferList = floatBuffers(:, 2);
   bufferNumList = setdiff(unique(bufferList), -1);
   for bufNum = bufferNumList'
      idFile = find(bufferList == bufNum);
      cycleNum = unique(floatBuffers(idFile, 3));
      deepCycleFlag = unique(floatBuffers(idFile, 5));
      if (unique(floatBuffers(idFile, 4)) == 1)
         [o_tabProfiles, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            o_tabNcTechIndex, o_tabNcTechVal, ...
            o_tabTechNMeas, o_tabTechAuxNMeas] = process_decoded_data_pfv2( ...
            floatData(floatBuffers(idFile, 1), :), cycleNum, deepCycleFlag, a_decoderId, ...
            o_tabProfiles, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            o_tabNcTechIndex, o_tabNcTechVal, ...
            o_tabTechNMeas, o_tabTechAuxNMeas);
      else
         fprintf('DEC_INFO: Float #%d Cycle #%d: UNCOMPLETED BUFFER - data ignored (%d files)\n', ...
            g_decArgo_floatNum, cycleNum, length(idFile));
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % process delayed information (TET, FMT, LMT, Iridium fixes, profiles
   % location) and update TRAJ and PROF data
   [o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles] = ...
      process_delayed_data_pfv2(o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % sort trajectory data structures according to the predefined measurement
   % code order
   o_tabTrajNMeas = sort_trajectory_data_pfv2(o_tabTrajNMeas);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % finalize NetCDF output

   % add interpolated/extrapolated profile locations
   o_tabProfiles = fill_empty_profile_locations_ir_sbd(g_decArgo_gpsData, o_tabProfiles);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
      update_output_cycle_number_ir_sbd( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas, o_tabTechAuxNMeas);
   
   % add MTIME in profiles
   o_tabProfiles = add_mtime_in_profile(o_tabProfiles);

   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);

   % finalize TECH data
   [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_pfv2(o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, o_tabTechAuxNMeas);

   % create output float configuration
   [o_structConfig] = create_output_float_config_pfv2(decArgoConfParamNames, ncConfParamNames, ncConfParamIds);
   
   % perform PARAMETER adjustment
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
      compute_rt_adjusted_param(o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, a_launchDate, 0, a_decoderId);

   if (g_decArgo_generateNcTraj32 ~= 0)
      % report profile PARAMETER adjustments in TRAJ data
      [o_tabTrajNMeas, o_tabTrajNCycle] = report_rt_adjusted_profile_data_in_trajectory( ...
         o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles);
   end
   
   if (g_decArgo_realtimeFlag)
      
      % save the list of already processed rsync log files in the history
      % directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'processed', ...
         g_decArgo_rsyncLogFileUnderProcessList);
      
      % save the list of used rsync log files in the history directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'used', ...
         unique(g_decArgo_rsyncLogFileUsedList));
   end

end

% remove temporary directories
rmdir(g_decArgo_archiveSbdDirectory, 's');
rmdir(g_decArgo_archiveDataGzDirectory, 's');
if (isempty(g_decArgo_outputCsvFileId))
   if (~g_decArgo_pfv2DebugMode)
      rmdir(g_decArgo_archiveDataDirectory, 's');
   end
end

return
