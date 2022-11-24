% ------------------------------------------------------------------------------
% Decode PROVOR Iridium float with RUDICS SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = ...
%    decode_provor_iridium_rudics_cts4_delayed( ...
%    a_floatNum, a_cycleList, a_decoderId, a_floatLoginName, ...
%    a_launchDate, a_refDay)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_cycleList      : list of cycles to be decoded
%   a_decoderId      : float decoder Id
%   a_floatLoginName : float name
%   a_launchDate     : launch date
%   a_refDay         : reference day (day of the first descent)
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
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = ...
   decode_provor_iridium_rudics_cts4_delayed( ...
   a_floatNum, a_cycleList, a_decoderId, a_floatLoginName, ...
   a_launchDate, a_refDay)

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
g_decArgo_cycleNum = [];

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

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% SBD sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_historyDirectory;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% decoder configuration values
global g_decArgo_generateNcTraj;
global g_decArgo_generateNcMeta;
global g_decArgo_dirInputRsyncData;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% mode processing flags
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 0;

% array to store GPS data
global g_decArgo_gpsData;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;
g_decArgo_julD2FloatDayOffset = [];

% no sampled data mode
global g_decArgo_noDataFlag;
g_decArgo_noDataFlag = 0;

% array to store ko sensor states
global g_decArgo_koSensorState;
g_decArgo_koSensorState = [];

% configuration values
global g_decArgo_applyRtqc;

% array to store configuration parameters of a second Iridium session (that
% should not be used immediatly)
global g_decArgo_floatProgTab;
g_decArgo_floatProgTab = [];

% float configuration
global g_decArgo_floatConfig;


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' a_floatLoginName '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'archive' directory used to store the received SBD files
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

% initialize float parameter configuration
init_float_config_prv_ir_rudics_cts4(a_launchDate, a_decoderId);
if (isempty(g_decArgo_floatConfig))
   return
end

% add launch position and time in the TRAJ NetCDF file
if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_generateNcTraj ~= 0))
   o_tabTrajNMeas = add_launch_data_ir_rudics;
end

% inits for output NetCDF file
decArgoConfParamNames = [];
ncConfParamNames = [];
if (isempty(g_decArgo_outputCsvFileId))
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   g_decArgo_outputNcParamLabelBis = [];
   
   if (g_decArgo_generateNcMeta ~= 0)
      % create the configuration parameter names for the META NetCDF file
      [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_ir_rudics_cts4(a_decoderId);
   end
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Profil #; Phase; Info type'];
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
   print_phase_help_ir_rudics;
end

if (~g_decArgo_realtimeFlag)
   
   % move the SBD files associated with the a_cycleList cycles into the
   % spool directory
   nbFiles = 0;
   for idCy = 1:length(a_cycleList)
      
      cycleNum = a_cycleList(idCy);
      sbdCyFiles = [ ...
         dir([g_decArgo_archiveDirectory '/' sprintf('*_%s_%05d.b64', ...
         a_floatLoginName, cycleNum)]); ...
         dir([g_decArgo_archiveDirectory '/' sprintf('*_%s_%05d.bin', ...
         a_floatLoginName, cycleNum)])];
      
      for idFile = 1:length(sbdCyFiles)
         
         sbdCyFileName = sbdCyFiles(idFile).name;
         
         cyIrJulD = datenum(sbdCyFileName(1:13), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
         if (cyIrJulD < a_launchDate)
            fprintf('BUFF_WARNING: Float #%d: input file "%s" ignored because dated before float launch date (%s)\n', ...
               g_decArgo_floatNum, ...
               sbdCyFileName, julian_2_gregorian_dec_argo(a_launchDate));
            continue
         end
         
         add_to_list_ir_rudics(sbdCyFileName, 'spool');
         nbFiles = nbFiles + 1;
      end
   end
   
   fprintf('BUFF_INFO: %d SBD files moved from float archive dir to float spool dir\n', nbFiles);
else
   
   % new SBD files have been collected with rsync, we are going to decode
   % all (archived and newly received) SBD files
   
   % duplicate the SBD files colleted with rsync into the archive directory
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   fprintf('RSYNC_INFO: Duplicating %d input files from rsync dir to float archive dir\n', ...
      length(fileIdList));
   
   for idF = 1:length(fileIdList)
      
      sbdFilePathName = [g_decArgo_dirInputRsyncData '/' ...
         g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
      [pathstr, sbdFileName, ext] = fileparts(sbdFilePathName);
      duplicate_files_ir_cts4({[sbdFileName ext]}, pathstr, g_decArgo_archiveDirectory);
   end
   
   % move the SBD files from archive to the spool directory
   fileList = [dir([g_decArgo_archiveDirectory '*.b64']); ...
      dir([g_decArgo_archiveDirectory '*.bin'])];
   if (~isempty(fileList))
      fprintf('BUFF_INFO: Moving %d SBD files from float archive dir to float spool dir\n', ...
         length(fileList));
      
      nbFiles = 0;
      for idF = 1:length(fileList)
         
         sbdFileName = fileList(idF).name;
         cyIrJulD = datenum(sbdFileName(1:13), 'yymmdd_HHMMSS') - g_decArgo_janFirst1950InMatlab;
         
         if (cyIrJulD < a_launchDate)
            fprintf('BUFF_WARNING: Float #%d: input file "%s" ignored because dated before float launch date (%s)\n', ...
               g_decArgo_floatNum, ...
               sbdFileName, julian_2_gregorian_dec_argo(a_launchDate));
            continue
         end
         
         add_to_list_ir_rudics(sbdFileName, 'spool');
         nbFiles = nbFiles + 1;
      end
      
      fprintf('BUFF_INFO: %d SBD files moved from float archive dir to float spool dir\n', nbFiles);
   end
end

if ((g_decArgo_realtimeFlag) || ...
      (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc)))
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, '');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve information on spool directory contents
[tabAllFileNames, ~, tabAllFileDates, ~] = get_list_files_info_ir_rudics('spool', '');

fprintf('\nDEC_INFO: decoding %d SBD files\n', length(tabAllFileNames));

% matFileName = [num2str(g_decArgo_floatNum) '_decodedDataTab.mat'];
% if (exist(matFileName, 'file') == 2)
%    load(matFileName);
% else

% read email files and decode data
decodedDataTab = [];
for idSpoolFile = 1:length(tabAllFileNames)
   
   sbdFileName = tabAllFileNames{idSpoolFile};
   sbdFileDate = tabAllFileDates(idSpoolFile);
   
   % move the next file into the buffer directory
   add_to_list_ir_rudics(sbdFileName, 'buffer');
   remove_from_list_ir_rudics(sbdFileName, 'spool', 0);
   
   % decode SBD file
   decodedData = decode_sbd_file_cts4(sbdFileName, sbdFileDate, a_decoderId);
   decodedDataTab = cat(2, decodedDataTab, decodedData);
   
   % move the processed 'new' files into the archive directory
   remove_from_list_ir_rudics(sbdFileName, 'buffer', 1);
end

%    save(matFileName, 'decodedDataTab');
% end

if (isempty(decodedDataTab))
   fprintf('DEC_INFO: Float #%d: No data\n', ...
      g_decArgo_floatNum);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\nDEC_INFO: creating buffers\n');

% create decoding buffers
decodedDataTab = create_decoding_buffers_cts4(decodedDataTab, a_decoderId);

if (isempty(decodedDataTab))
   fprintf('DEC_INFO: Float #%d: No data\n', ...
      g_decArgo_floatNum);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\nDEC_INFO: processing decoded data\n');

% process decoded data
bufferList = [decodedDataTab.rankByCycle];
bufferNumList = setdiff(unique(bufferList), -1);
for bufNum = bufferNumList
   idSbd = find(bufferList == bufNum);
   [o_tabProfiles, ...
      o_tabTrajNMeas, o_tabTrajNCycle, ...
      o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
      process_decoded_data_cts4( ...
      decodedDataTab(idSbd), a_refDay, a_decoderId, ...
      o_tabProfiles, ...
      o_tabTrajNMeas, o_tabTrajNCycle, ...
      o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
end

% finalize NetCDF output
if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files
   
   % assign second Iridium session to end of previous cycle and merge first/last
   % msg and location times
   [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_sbd2( ...
      o_tabTrajNMeas, o_tabTrajNCycle, a_decoderId);
   
   % add interpolated profile locations
   [o_tabProfiles] = fill_empty_profile_locations_ir_rudics(o_tabProfiles, g_decArgo_gpsData, ...
      o_tabTrajNMeas, o_tabTrajNCycle);
   
   % cut CTD profile at the cut-off pressure of the CTD pump
   [o_tabProfiles] = cut_ctd_profile_ir_rudics(o_tabProfiles);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_rudics_cts4(decArgoConfParamNames, ncConfParamNames, a_decoderId);
   
   % add configuration number and output cycle number
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
      add_configuration_number_ir_rudics_sbd2( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);
   
   % set QC parameters to '3' when the sensor state is ko
   [o_tabProfiles, o_tabTrajNMeas] = update_qc_from_sensor_state_ir_rudics_sbd2( ...
      o_tabProfiles, o_tabTrajNMeas);
   
   % set JULD_QC and POSITION_QC to '3' when the profile has been created after
   % a buffer anomaly (more than one profile for a given profile number)
   [o_tabProfiles] = check_profile_ir_rudics_sbd2(o_tabProfiles);
   
   % perform DOXY, CHLA and NITRATE adjustment
   [o_tabProfiles] = compute_rt_adjusted_param(o_tabProfiles, a_launchDate, 1);
   
   if (g_decArgo_realtimeFlag == 1)
      
      % save the list of already processed rsync log files in the history
      % directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'processed', ...
         g_decArgo_rsyncLogFileUnderProcessList);
      
      % save the list of used rsync log files in the history directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'used', ...
         unique(g_decArgo_rsyncLogFileUsedList));
   end
   
   % update NetCDF technical data (add a column to store output cycle numbers)
   o_tabNcTechIndex = update_technical_data_iridium_rudics_sbd2(o_tabNcTechIndex);
end

return
