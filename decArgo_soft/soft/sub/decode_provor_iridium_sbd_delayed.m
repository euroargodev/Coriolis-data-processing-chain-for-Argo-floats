% ------------------------------------------------------------------------------
% Decode PROVOR Iridium Ice float with Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = ...
%    decode_provor_iridium_sbd_delayed( ...
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
%   10/16/2017 - RNU - creation
%   12/17/2018 - RNU - new version : read data / decode data / create decoding
%                                    buffers / process decoded data
%                                    according to decoding buffers
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = ...
   decode_provor_iridium_sbd_delayed( ...
   a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
   a_launchDate, a_refDay, a_floatEndDate)

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

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabelBis;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% SBD sub-directories
global g_decArgo_spoolDirectory;
global g_decArgo_archiveDirectory;
global g_decArgo_archiveSbdDirectory;
global g_decArgo_historyDirectory;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% decoder configuration values
global g_decArgo_generateNcTraj;
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

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;
g_decArgo_julD2FloatDayOffset = a_refDay;

% for some (oldest) float versions the prelude and the first deep cycle have the
% same number 0. We cannot manage this in the TRAJ files and choose to add 1 to
% cycle numbers transmitted by the float (except for the prelude phase cycle
% number (0))
global g_decArgo_firstDeepCycleDone;
g_decArgo_firstDeepCycleDone = 0;

% number of the previous decoded cycle
global g_decArgo_cycleNumPrev;
g_decArgo_cycleNumPrev = -1;

% last float reset date
global g_decArgo_floatLastResetDate;
g_decArgo_floatLastResetDate = -1;

% offset in cycle number (in case of reset of the float)
global g_decArgo_cycleNumOffset;
g_decArgo_cycleNumOffset = 0;

% shift to apply to transmitted cycle number (see 6901248)
global g_decArgo_cycleNumShift;
g_decArgo_cycleNumShift = 0;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;
g_decArgo_cycleNumListForIce = [];
g_decArgo_cycleNumListIceDetected = [];

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;
g_decArgo_7TypePacketReceivedCyNum = [];

% date of last ICE detection
global g_decArgo_lastDetectionDate;
g_decArgo_lastDetectionDate = [];

% float configuration
global g_decArgo_floatConfig;

% clock offset management
global g_decArgo_clockOffset;
g_decArgo_clockOffset = get_clock_offset_prv_ir_init_struct;

% delay to recover config messages before launch date
global g_decArgo_maxIntervalToRecoverConfigMessageBeforeLaunchDate;

% from
% - decId 223 for Arvor
% - decId 221 for Arvor Deep
% configuration parameters are not transmitted each cycle
% consequently we must update the configuration of the second deep cycle with
% initial parameters, this should be done once (except if alterneated profil or
% auto-increment flag are set)
global  g_decArgo_doneOnceFlag;
g_decArgo_doneOnceFlag = 0;


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' num2str(a_floatImei) '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'archive' directory used to store the received mail files
% - a 'archive/sbd' directory used to store the received SBD files
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

% inits for output NetCDF file
decArgoConfParamNames = [];
ncConfParamNames = [];
if (isempty(g_decArgo_outputCsvFileId))
   
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   g_decArgo_outputNcParamLabelBis = [];
   
   % create the configuration parameter names for the META NetCDF file
   [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_ir_sbd(a_decoderId);
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Info type'];
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
if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_generateNcTraj ~= 0))
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
ignore_duplicated_mail_files(g_decArgo_spoolDirectory, g_decArgo_archiveDirectory);

% retrieve information on spool directory contents
[tabAllFileNames, ~, tabAllFileDates, ~] = get_list_files_info_ir_sbd('spool', '');

fprintf('\nDEC_INFO: decoding %d mail files\n', length(tabAllFileNames));

% read email files and decode data
decodedDataTab = [];
for idSpoolFile = 1:length(tabAllFileNames)
   
   curMailFile = tabAllFileNames{idSpoolFile};
   curMailFileDate = tabAllFileDates(idSpoolFile);
   
   % move the current file into the buffer directory
   add_to_list_ir_sbd(curMailFile, 'buffer');
   remove_from_list_ir_sbd(curMailFile, 'spool', 0, 1);
   
   % extract the attachement
   [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
      curMailFile, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
   if (attachmentFound == 0)
      remove_from_list_ir_sbd(curMailFile, 'buffer', 1, 1);
      continue
   end
   
   % decode SBD file
   sbdFileName = regexprep(curMailFile, '.txt', '.sbd');
   decodedData = decode_sbd_file(sbdFileName, curMailFileDate, a_decoderId, a_launchDate);
   decodedDataTab = [decodedDataTab decodedData];
   
   % move the current file into the archive directory
   % (and delete the associated SBD files)
   remove_from_list_ir_sbd(curMailFile, 'buffer', 1, 1);
end

if (isempty(decodedDataTab))
   fprintf('DEC_INFO: Float #%d: No data\n', ...
      g_decArgo_floatNum);
   rmdir(g_decArgo_archiveSbdDirectory, 's');
   return
end

fprintf('\nDEC_INFO: creating buffers\n');

% create decoding buffers
decodedDataTab = create_decoding_buffers(decodedDataTab, a_decoderId);

if (isempty(decodedDataTab))
   fprintf('DEC_INFO: Float #%d: No data\n', ...
      g_decArgo_floatNum);
   rmdir(g_decArgo_archiveSbdDirectory, 's');
   return
end

fprintf('\nDEC_INFO: processing decoded data\n');

% process decoded data
bufferList = [decodedDataTab.rankByCycle];
% if (isempty(g_decArgo_outputCsvFileId))
% process the data according to cycle number (i.e. buffer number)
%    bufferList = [decodedDataTab.rankByCycle];
% else
%    bufferList = [decodedDataTab.rankByDate];
% end
bufferNumList = setdiff(unique(bufferList), -1);
for bufNum = bufferNumList
   idSbd = find(bufferList == bufNum);
   [o_tabProfiles, ...
      o_tabTrajNMeas, o_tabTrajNCycle, ...
      o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = process_decoded_data( ...
      decodedDataTab(idSbd), a_refDay, a_decoderId, ...
      o_tabProfiles, ...
      o_tabTrajNMeas, o_tabTrajNCycle, ...
      o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
end

% finalize NetCDF output
if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files
   
   % fill Iridium profile locations with interpolated positions
   % (profile locations have been computed cycle by cycle, we will check if
   % some Iridium profile locations can not be replaced by interpolated locations
   % of the surface trajectory)
   [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(g_decArgo_gpsData, o_tabProfiles);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
      update_output_cycle_number_ir_sbd( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas);
   
   % clean FMT, LMT and GPS locations and set TET
   [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_sbd( ...
      o_tabTrajNMeas, o_tabTrajNCycle, a_decoderId);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);
   
   % add ICE detected flag in TECH variables and finalize TECH data
   [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_ir_sbd( ...
      o_tabNcTechIndex, o_tabNcTechVal, a_decoderId);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_sbd( ...
      decArgoConfParamNames, ncConfParamNames, a_decoderId);
   
   % perform DOXY adjustment
   [o_tabProfiles] = compute_rt_adjusted_param(o_tabProfiles, a_launchDate, 0);

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

rmdir(g_decArgo_archiveSbdDirectory, 's');

return
