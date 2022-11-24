% ------------------------------------------------------------------------------
% Decode PROVOR CTS5-USEA floats.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = ...
%    decode_provor_iridium_rudics_cts5_usea( ...
%    a_floatNum, a_decoderId, a_floatLoginName, a_launchDate)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_decoderId      : float decoder Id
%   a_floatLoginName : float name
%   a_launchDate     : launch date
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = ...
   decode_provor_iridium_rudics_cts5_usea( ...
   a_floatNum, a_decoderId, a_floatLoginName, a_launchDate)

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

% number used to group traj information
global g_decArgo_trajItemGroupNum;
g_decArgo_trajItemGroupNum = 1;

% number used to group tech PARAM information
global g_decArgo_techItemGroupNum;
g_decArgo_techItemGroupNum = 1;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabelBis;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% SBD sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_historyDirectory;
global g_decArgo_updatedDirectory;
global g_decArgo_unusedDirectory;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% decoder configuration values
global g_decArgo_dirInputRsyncData;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

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

% no sampled data mode
global g_decArgo_noDataFlag;
g_decArgo_noDataFlag = 0;

% array to store ko sensor states
global g_decArgo_koSensorState;
g_decArgo_koSensorState = [];

% configuration values
global g_decArgo_applyRtqc;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% number of the first cycle to process
global g_decArgo_firstCycleNumCts5;

% variable to store all useful event data
global g_decArgo_eventData;
g_decArgo_eventData = [];

% decoded event data
global g_decArgo_eventDataTech;
global g_decArgo_eventDataParamTech;
global g_decArgo_eventDataTraj;
global g_decArgo_eventDataMeta;
global g_decArgo_eventDataTime;

% existing cycle and pattern numbers
global g_decArgo_cyclePatternNumFloat;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloat;
global g_decArgo_patternNumFloatStr;

% current cycle number
global g_decArgo_cycleNum;

% first float cycle number to consider
global g_decArgo_firstCycleNumFloat;
global g_decArgo_firstCycleNumFloatNew;
global g_decArgo_argoCycleNumForFirstCycleNumFloatNew;
g_decArgo_argoCycleNumForFirstCycleNumFloatNew = [];

% due to payload issue, we should store all time information (to assign payload
% data to their correct cycle)
global g_decArgo_trajDataFromApmtTech;
g_decArgo_trajDataFromApmtTech = [];

% meta-data retrieved from APMT tech files
global g_decArgo_apmtMetaFromTech;
g_decArgo_apmtMetaFromTech = [];

% time data retrieved from APMT tech files
global g_decArgo_apmtTimeFromTech;
g_decArgo_apmtTimeFromTech = [];

% float configuration
global g_decArgo_floatConfig;

% type of files to consider
global g_decArgo_provorCts5UseaFileTypeListAll;
global g_decArgo_fileTypeListCts5;
g_decArgo_fileTypeListCts5 = g_decArgo_provorCts5UseaFileTypeListAll;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' a_floatLoginName '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'archive' directory used to store the received SBD files
% - a 'updated_files' directory used to store old versions of files that have been updated in the rudics server
% - a 'unused_files' directory used to store files that shold not be used (they need to be deleted from the rudics server)
% IN RT MODE:
% - a 'history_of_processed_data' directory used to store the information on
% previous processings
g_decArgo_archiveDirectory = [floatIriDirName 'archive/'];
if ~(exist(g_decArgo_archiveDirectory, 'dir') == 7)
   mkdir(g_decArgo_archiveDirectory);
end
g_decArgo_updatedDirectory = [g_decArgo_archiveDirectory '/updated_files/']; % to store old versions of files that have been updated in the rudics server
if ~(exist(g_decArgo_updatedDirectory, 'dir') == 7)
   mkdir(g_decArgo_updatedDirectory);
end
g_decArgo_unusedDirectory = [g_decArgo_archiveDirectory '/unused_files/']; % to store files that shold not be used (they need to be deleted from the rudics server)
if ~(exist(g_decArgo_unusedDirectory, 'dir') == 7)
   mkdir(g_decArgo_unusedDirectory);
end
if (g_decArgo_realtimeFlag)
   g_decArgo_historyDirectory = [floatIriDirName 'history_of_processed_data/'];
   if ~(exist(g_decArgo_historyDirectory, 'dir') == 7)
      mkdir(g_decArgo_historyDirectory);
   end
end

% create temporary directory to store concatenated files
floatTmpDirName = [g_decArgo_archiveDirectory '/tmp/'];
if (exist(floatTmpDirName, 'dir') == 7)
   rmdir(floatTmpDirName, 's');
end
mkdir(floatTmpDirName);

% inits for output NetCDF file
if (isempty(g_decArgo_outputCsvFileId))
   g_decArgo_outputNcParamIndex = [];
   g_decArgo_outputNcParamValue = [];
   g_decArgo_outputNcParamLabelBis = [];
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   % print CSV header
   header = 'WMO #; Cycle #; Pattern #; File type; Section; Info type';
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
end

% add launch position and time in the TRAJ NetCDF file
if (isempty(g_decArgo_outputCsvFileId))
   o_tabTrajNMeas = add_launch_data_ir_rudics;
end

if (g_decArgo_delayedModeFlag)
   
   fprintf('ERROR: Float #%d is expected to be processed in Real Time Mode\n', ...
      a_floatNum);
   o_tabProfiles = [];
   o_tabTrajNMeas = [];
   o_tabTrajNCycle = [];
   o_tabNcTechIndex = [];
   o_tabNcTechVal = [];
   o_structConfig = [];
   return
   
end

if (g_decArgo_realtimeFlag)
   
   % new files have been collected with rsync, we are going to decode
   % all (archived and newly received) files
   
   % duplicate the files colleted with rsync into the archive directory
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   
   nbFilesTot = 0;
   for idF = 1:length(fileIdList)
      
      sbdFilePathName = [g_decArgo_dirInputRsyncData '/' ...
         g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
      [pathstr, sbdFileName, ext] = fileparts(sbdFilePathName);
      nbFiles = duplicate_files_ir_cts5({[sbdFileName ext]}, pathstr, g_decArgo_archiveDirectory, a_floatNum);
      nbFilesTot = nbFilesTot + nbFiles;
   end
   
   fprintf('RSYNC_INFO: Duplicated %d files from rsync dir to float archive dir\n', ...
      nbFilesTot);
   
   % set file prefix
   g_decArgo_filePrefixCts5 = get_file_prefix_cts5(g_decArgo_archiveDirectory);
end

% initialize float configuration
init_float_config_prv_ir_rudics_cts5_usea(a_decoderId);
if (isempty(g_decArgo_floatConfig))
   return
end

g_decArgo_firstCycleNumFloat = g_decArgo_firstCycleNumCts5;
g_decArgo_firstCycleNumFloatNew = g_decArgo_firstCycleNumCts5;

% print launch configuration in CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   g_decArgo_cycleNumFloatStr = '-';
   g_decArgo_patternNumFloatStr = '-';
   print_config_in_csv_file_ir_rudics_cts5('Launch_config');
end

if ((g_decArgo_realtimeFlag) || (g_decArgo_delayedModeFlag) || ...
      (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc)))
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, '');
end

% find cycle and (cycle,ptn) from available files
% get payload configuration files
[floatCycleList, g_decArgo_cyclePatternNumFloat] = get_cycle_ptn_cts5_usea;

% retrieve event data
ok = get_event_data_cts5(g_decArgo_cyclePatternNumFloat, a_launchDate, a_decoderId);
if (~ok)
   return
end

% process available files
stop = 0;
for idFlCy = 1:length(floatCycleList)
   floatCyNum = floatCycleList(idFlCy);
   
   if (floatCyNum < g_decArgo_firstCycleNumFloat)
      continue
   end
   
   if (floatCyNum == g_decArgo_firstCycleNumFloat)
      g_decArgo_cycleNum = 0;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % get files (without pattern #) to process
   
   fileToProcess = get_received_file_list_usea(floatCyNum, [], g_decArgo_filePrefixCts5);
   
   if (~isempty(fileToProcess))
      fprintf('\nDEC_INFO: Float #%d: Processing cycle #%d (float cycle #%d)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, floatCyNum);
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
   end
   
   if (~stop)
      
      g_decArgo_eventDataTech = [];
      g_decArgo_eventDataParamTech = [];
      g_decArgo_eventDataTraj = [];
      g_decArgo_eventDataMeta = [];
      g_decArgo_eventDataTime = [];

      g_decArgo_cycleNumFloat = floatCyNum;
      g_decArgo_cycleNumFloatStr = num2str(floatCyNum);
      g_decArgo_patternNumFloat = [];
      g_decArgo_patternNumFloatStr = '-';
      
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
         decode_files(fileToProcess, a_decoderId, g_decArgo_firstCycleNumCts5);
      
      if (~isempty(tabProfiles))
         o_tabProfiles = [o_tabProfiles tabProfiles];
      end
      if (~isempty(tabTrajNMeas))
         o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
      end
      if (~isempty(tabTrajNCycle))
         o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
      end
      if (~isempty(tabNcTechIndex))
         o_tabNcTechIndex = [o_tabNcTechIndex; tabNcTechIndex];
         o_tabNcTechVal = [o_tabNcTechVal; tabNcTechVal];
      end
      if (~isempty(tabTechNMeas))
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get files (with pattern #) to process
      idF = find(g_decArgo_cyclePatternNumFloat(:, 1) == floatCyNum);
      for idFlCyPtn = 1:length(idF)
         floatPtnNum = g_decArgo_cyclePatternNumFloat(idF(idFlCyPtn), 2);
         
         % retrieve useful information from event data
         decode_event_data_cts5(floatCyNum, floatPtnNum);
         
         % get files to process
         fileToProcess = get_received_file_list_usea(floatCyNum, floatPtnNum, g_decArgo_filePrefixCts5);
         
         if (~stop)
            
            if (floatPtnNum > 0)
               g_decArgo_cycleNum = g_decArgo_cycleNum + 1;
               
               fprintf('\nDEC_INFO: Float #%d: Processing cycle #%d (float cycle #%d)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, floatCyNum);
               
               if (g_decArgo_realtimeFlag == 1)
                  % update the reports structure cycle list
                  g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
               end
            end
            g_decArgo_patternNumFloat = floatPtnNum;
            g_decArgo_patternNumFloatStr = num2str(floatPtnNum);
            
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
               decode_files(fileToProcess, a_decoderId, g_decArgo_firstCycleNumCts5);
            
            if (~isempty(tabProfiles))
               o_tabProfiles = [o_tabProfiles tabProfiles];
            end
            if (~isempty(tabTrajNMeas))
               o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
            end
            if (~isempty(tabTrajNCycle))
               o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
            end
            if (~isempty(tabNcTechIndex))
               o_tabNcTechIndex = [o_tabNcTechIndex; tabNcTechIndex];
               o_tabNcTechVal = [o_tabNcTechVal; tabNcTechVal];
            end
            if (~isempty(tabTechNMeas))
               o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
            end
         end
      end
   end
end

if (isempty(g_decArgo_outputCsvFileId))

   % output NetCDF files
   
   % add interpolated profile locations
   [o_tabProfiles] = fill_empty_profile_locations_ir_rudics(o_tabProfiles, g_decArgo_gpsData, ...
      o_tabTrajNMeas, o_tabTrajNCycle);
   
   % cut CTD profile at the cut-off pressure of the CTD pump
   [o_tabProfiles] = cut_ctd_profile_ir_rudics(o_tabProfiles);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_rudics_cts5_usea(a_decoderId);
   
   % add configuration number and output cycle number
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
      add_configuration_number_ir_rudics_cts5( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas);
   
   % add MTIME to AUX profiles
   o_tabProfiles = finalize_profile_ir_rudics_cts5(o_tabProfiles);
   
   % merge multiple N_CYCLE and N_MEAS records for a given output cycle number
   % and add not present (but expected for this float family) Measurement Codes
   [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_rudics_cts5( ...
      o_tabTrajNMeas, o_tabTrajNCycle);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);
   
   % perform PARAMETER adjustment
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
      compute_rt_adjusted_param(o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, a_launchDate, 1, a_decoderId);

   if (g_decArgo_generateNcTraj32 ~= 0)
      % report profile PARAMETER adjustments in TRAJ data
      [o_tabTrajNMeas, o_tabTrajNCycle] = report_rt_adjusted_profile_data_in_trajectory( ...
         o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles);
   end

   if (g_decArgo_realtimeFlag == 1)
      
      % save the list of already processed rsync log files in the history
      % directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'processed', ...
         g_decArgo_rsyncLogFileUnderProcessList);
      
      % save the list of used rsync log files in the history directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'used', ...
         unique(g_decArgo_rsyncLogFileUsedList));
   end
   
   % add float cycle and pattern number + Ice detected bit to the NetCDF
   % technical data
   [o_tabNcTechIndex, o_tabNcTechVal] = ...
      update_technical_data_ir_rudics_cts5( ...
      o_tabNcTechIndex, o_tabNcTechVal, g_decArgo_firstCycleNumCts5, a_decoderId);
end

return

% ------------------------------------------------------------------------------
% Decode a set of PROVOR CTS5-USEA files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%    decode_files(a_fileNameList, a_decoderId, a_firstCycleNum)
%
% INPUT PARAMETERS :
%   a_fileNameList  : list of files to decode
%   a_decoderId     : float decoder Id
%   a_firstCycleNum : number of the first cycle to consider
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : decoded profiles
%   o_tabTrajNMeas   : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : decoded technical index information
%   o_tabNcTechVal   : decoded technical data
%   o_tabTechNMeas   : decoded technical N_MEASUREMENT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   decode_files(a_fileNameList, a_decoderId, a_firstCycleNum)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% SBD sub-directories
global g_decArgo_archiveDirectory;

% generate nc flag
global g_decArgo_generateNcFlag;

% array to store GPS data
global g_decArgo_gpsData;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfLife;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_cycleNumFloatStr;
global g_decArgo_patternNumFloat;
global g_decArgo_patternNumFloatStr;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% type of files to consider
global g_decArgo_fileTypeListCts5;

% due to payload issue, we should store all time information (to assign payload
% data to their correct cycle)
global g_decArgo_trajDataFromApmtTech;

% meta-data retrieved from APMT tech files
global g_decArgo_apmtMetaFromTech;

% time data retrieved from APMT tech files
global g_decArgo_apmtTimeFromTech;


if (isempty(a_fileNameList))
   return
end

% set the type of each file
fileNames = a_fileNameList;
fileTypes = zeros(size(fileNames));
for idF = 1:length(fileNames)
   fileName = fileNames{idF};
   if (~isempty(g_decArgo_patternNumFloat))
      typeList = [1 2 4:18]; % types with pattern #
      for idType = typeList
         idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
         if (length(fileName) > g_decArgo_fileTypeListCts5{idFL, 4})
            [val, count, errmsg, nextindex] = sscanf( ...
               fileName(1:g_decArgo_fileTypeListCts5{idFL, 4}), ...
               [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idFL, 3}]);
            if (isempty(errmsg) && (count == 2))
               if (strcmp(fileName(end-3:end), g_decArgo_fileTypeListCts5{idFL, 2}(end-3:end)))
                  fileTypes(idF) = idType;
                  break
               end
            end
         end
      end
   else
      if (strncmp(fileName, g_decArgo_filePrefixCts5, length(g_decArgo_filePrefixCts5)))
         typeList = [3]; % types without pattern #
         for idType = typeList
            idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
            if (length(fileName) > g_decArgo_fileTypeListCts5{idFL, 4})
               [val, count, errmsg, nextindex] = sscanf( ...
                  fileName(1:g_decArgo_fileTypeListCts5{idFL, 4}), ...
                  [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idFL, 3}]);
               if (isempty(errmsg) && (count == 1))
                  fileTypes(idF) = idType;
                  break
               end
            end
         end
      end
   end
end

% do not consider metadata.xml (already used at float declaration)
idXmlFile = find(fileTypes == 2);
fileNames(idXmlFile) = [];
fileTypes(idXmlFile) = [];

% set the configuration only if data has been received
if (~isempty(intersect(fileTypes, 6:17)))
   % we should set the configuration before decoding apmt configuration
   % (which concerns the next cycle and pattern)
   set_float_config_ir_rudics_cts5_usea(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat);
end

% the files should be processed in the following order
typeOrderList = [3 4 6:18 5 1];
% 3, 4, 6 to 18, 5: usual order i.e. tech first, data after and EOL at the end
% 1: last the apmt configuration because it concerns the next cycle and pattern

% process the files
fprintf('DEC_INFO: decoding files:\n');
apmtCtd = [];
apmtDo = [];
apmtEco = [];
apmtOcr = [];
uvpLpmData = [];
uvpBlackData = [];
apmtSbeph = [];
apmtCrover = [];
apmtSuna = [];
opusLightData = [];
opusBlackData = [];
ramsesData = [];
mpeData = [];

techDataFromApmtTech = [];
trajDataFromApmtTech = [];
timeDataFromApmtTech = [];
for typeNum = typeOrderList

   idFileForType = find(fileTypes == typeNum);
   if (~isempty(idFileForType))
      
      fileNamesForType = fileNames(idFileForType);
      for idFile = 1:length(fileNamesForType)
         
         % manage split files
         [~, fileName, fileExtension] = fileparts(fileNamesForType{idFile});
         fileNameInfo = manage_split_files({g_decArgo_archiveDirectory}, ...
            {[fileName '*' fileExtension]}, a_decoderId);
         
         % decode files
         switch (typeNum)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 1
               % '*_apmt*.ini'
               
               % apmt configuration file
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               
               % read apmt configuration
               apmtConfig = read_apmt_config([fileNameInfo{4} fileNameInfo{1}], a_decoderId);
               
               % update current configuration
               update_float_config_ir_rudics_cts5_usea(apmtConfig);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  % print apmt configuration in CSV file
                  print_apmt_config_in_csv_file_ir_rudics_cts5(apmtConfig);
                  
                  % print updated configuration in CSV file
                  print_config_in_csv_file_ir_rudics_cts5('Updated_config');
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {3, 4, 5}
               % '*_autotest_*.txt'
               % '*_technical*.txt'
               % '*_default_*.txt'
               
               % apmt technical information
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               
               [apmtTech, apmtTimeFromTech, ...
                  ncApmtTech, apmtTrajFromTech, apmtMetaFromTech] = ...
                  read_apmt_technical([fileNameInfo{4} fileNameInfo{1}], a_decoderId);
               g_decArgo_apmtMetaFromTech = [g_decArgo_apmtMetaFromTech apmtMetaFromTech];
               if (~isempty(g_decArgo_patternNumFloat))
                  g_decArgo_apmtTimeFromTech = cat(1, g_decArgo_apmtTimeFromTech, ...
                     [g_decArgo_cycleNumFloat g_decArgo_patternNumFloat {apmtTimeFromTech}]);
               end
               
               % store GPS data
               store_gps_data_ir_rudics_cts5(apmtTech, typeNum);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_apmt_tech_in_csv_file_ir_rudics_cts5(apmtTech, typeNum);
                  
                  % store TIME information
                  if (~isempty(apmtTimeFromTech))
                     cycleNumFloat = g_decArgo_cycleNumFloat;
                     patternNumFloat = g_decArgo_patternNumFloat;
                     if (isempty(patternNumFloat))
                        patternNumFloat = 0;
                     end
                     timeDataFromApmtTech = [timeDataFromApmtTech;
                        [cycleNumFloat patternNumFloat {apmtTimeFromTech}]];
                  end
                  
               else
                  
                  % store TECH and TRAJ information
                  if (~isempty(apmtTrajFromTech) || ~isempty(ncApmtTech))
                     cycleNumFloat = g_decArgo_cycleNumFloat;
                     patternNumFloat = g_decArgo_patternNumFloat;
                     if (isempty(patternNumFloat))
                        patternNumFloat = 0;
                     end
                     if (typeNum == 3)
                        cyclePhase = g_decArgo_phasePreMission;
                     elseif (typeNum == 4)
                        cyclePhase = g_decArgo_phaseSatTrans;
                     elseif (typeNum == 5)
                        cyclePhase = g_decArgo_phaseEndOfLife;
                     end
                     if (~isempty(ncApmtTech))
                        techDataFromApmtTech = [techDataFromApmtTech;
                           [cycleNumFloat patternNumFloat cyclePhase {ncApmtTech}]];
                     end
                     if (~isempty(apmtTrajFromTech))
                        trajDataFromApmtTech = [trajDataFromApmtTech;
                           [cycleNumFloat patternNumFloat cyclePhase {apmtTrajFromTech}]];
                        
                        g_decArgo_trajDataFromApmtTech = [g_decArgo_trajDataFromApmtTech;
                           [cycleNumFloat patternNumFloat g_decArgo_cycleNum {apmtTrajFromTech}]];
                     end
                  end
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 6
               % '*_sbe41*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtCtd = decode_apmt_ctd([fileNameInfo{4} fileNameInfo{1}], a_decoderId);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_CTD(apmtCtd);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 7
               % '*_do*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtDo = decode_apmt_do([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_DO(apmtDo);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 8
               % '*_eco*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtEco = decode_apmt_eco([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_ECO(apmtEco);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 9
               % '*_ocr*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtOcr = decode_apmt_ocr([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_OCR(apmtOcr);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {10, 11}
               % '*_uvp6_blk*.hex'
               % '*_uvp6_lpm*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [uvpLpmDataDec, uvpBlackDataDec] = decode_apmt_uvp([fileNameInfo{4} fileNameInfo{1}]);
               if (~isempty(uvpLpmDataDec))
                  uvpLpmData = uvpLpmDataDec;
               end
               if (~isempty(uvpBlackDataDec))
                  uvpBlackData = uvpBlackDataDec;
               end
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_UVP(uvpLpmDataDec, uvpBlackDataDec);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 12
               % '*_crover*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtCrover = decode_apmt_crover([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_CROVER(apmtCrover);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 13
               % '*_sbeph*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtSbeph = decode_apmt_sbeph([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_SBEPH(apmtSbeph);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 14
               % '*_suna*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtSuna = decode_apmt_suna([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_SUNA(apmtSuna);
               end
               
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case {15, 16}
               % '*_opus_blk*.hex'
               % '*_opus_lgt*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [opusLightDataDec, opusBlackDataDec] = decode_apmt_opus([fileNameInfo{4} fileNameInfo{1}]);
               if (~isempty(opusLightDataDec))
                  opusLightData = opusLightDataDec;
               end
               if (~isempty(opusBlackDataDec))
                  opusBlackData = opusBlackDataDec;
               end
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  print_data_in_csv_file_ir_rudics_cts5_OPUS(opusLightDataDec, opusBlackDataDec);
               end
               
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 17
               % '*_ramses*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               ramsesData = decode_apmt_ramses([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_RAMSES(ramsesData);
               end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            case 18
               % '*_mpe*.hex'
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               mpeData = decode_apmt_mpe([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_data_in_csv_file_ir_rudics_cts5_MPE(mpeData);
               end

            otherwise
               fprintf('WARNING: Nothing define yet to process file: %s\n', ...
                  fileNamesForType{idFile});
         end
      end
      
      fileNames(idFileForType) = [];
      fileTypes(idFileForType) = [];
      
      if (isempty(fileNames))
         break
      end
   end
end

if (~isempty(fileNames))
   fprintf('DEC_WARNING: %d files were not processed\n', ...
      length(fileNames));
end

if (~isempty(g_decArgo_outputCsvFileId))
   
   % print time data in csv file
   print_dates_in_csv_file_ir_rudics_cts5_usea( ...
      timeDataFromApmtTech, apmtCtd, apmtDo, apmtEco, apmtOcr, uvpLpmData, uvpBlackData, ...
      apmtSbeph, apmtCrover, apmtSuna, opusLightData, opusBlackData, ramsesData, mpeData);
end

% output NetCDF data
if (isempty(g_decArgo_outputCsvFileId))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROF NetCDF data
   
   % process profile data from apmt
   tabDrift = [];
   tabSurf = [];
   subSurfaceMeas = [];
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtCtd))
      
      % create profiles (as they are transmitted)
      [tabProfilesCtd, tabDriftCtd, tabSurfCtd, subSurfaceMeas] = ...
         process_profile_ir_rudics_cts5_usea_ctd(apmtCtd, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftCtd];
      tabSurf = [tabSurf tabSurfCtd];
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesCtd] = merge_profile_meas_ir_rudics_cts5_usea_ctd(tabProfilesCtd);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesCtd] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_ctd(tabProfilesCtd);
      
      o_tabProfiles = [o_tabProfiles tabProfilesCtd];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtDo))
      
      % create profiles (as they are transmitted)
      [tabProfilesDo, tabDriftDo, tabSurfDo] = ...
         process_profile_ir_rudics_cts5_usea_do(apmtDo, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftDo];
      tabSurf = [tabSurf tabSurfDo];
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesDo] = merge_profile_meas_ir_rudics_cts5_usea_do(tabProfilesDo);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesDo] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesDo);
      
      o_tabProfiles = [o_tabProfiles tabProfilesDo];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtOcr))
      
      % create profiles (as they are transmitted)
      [tabProfilesOcr, tabDriftOcr, tabSurfOcr] = ...
         process_profile_ir_rudics_cts5_usea_ocr(apmtOcr, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftOcr];
      tabSurf = [tabSurf tabSurfOcr];
            
      % merge profiles (all data from a given sensor together)
      [tabProfilesOcr] = merge_profile_meas_ir_rudics_cts5_usea_ocr(tabProfilesOcr);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesOcr] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOcr);
      
      o_tabProfiles = [o_tabProfiles tabProfilesOcr];
   end   
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtEco))
      
      % create profiles (as they are transmitted)
      [tabProfilesEco, tabDriftEco, tabSurfEco] = ...
         process_profile_ir_rudics_cts5_usea_eco(apmtEco, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftEco];
      tabSurf = [tabSurf tabSurfEco];
      
      if (~isempty(tabSurfEco))
         % only OPTODE and OCR sensor surface mesurements are implement in
         % compute_surface_derived_parameters_ir_rudics_cts5
         fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface ECO data processing not implemented yet\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat);
      end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesEco] = merge_profile_meas_ir_rudics_cts5_usea_eco(tabProfilesEco);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesEco] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesEco);
      
      o_tabProfiles = [o_tabProfiles tabProfilesEco];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtSbeph))
      
      % create profiles (as they are transmitted)
      [tabProfilesSbeph, tabDriftSbeph, tabSurfSbeph] = ...
         process_profile_ir_rudics_cts5_usea_sbeph(apmtSbeph, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftSbeph];
      tabSurf = [tabSurf tabSurfSbeph];
      
      if (~isempty(tabSurfSbeph))
         % only OPTODE and OCR sensor surface mesurements are implement in
         % compute_surface_derived_parameters_ir_rudics_cts5
         fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface SBEPH data processing not implemented yet\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat);
      end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesSbeph] = merge_profile_meas_ir_rudics_cts5_usea_sbeph(tabProfilesSbeph);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesSbeph] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesSbeph);
      
      o_tabProfiles = [o_tabProfiles tabProfilesSbeph];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtCrover))
      
      % create profiles (as they are transmitted)
      [tabProfilesCrover, tabDriftCrover, tabSurfCrover] = ...
         process_profile_ir_rudics_cts5_usea_crover(apmtCrover, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftCrover];
      tabSurf = [tabSurf tabSurfCrover];
      
      if (~isempty(tabSurfCrover))
         % only OPTODE and OCR sensor surface mesurements are implement in
         % compute_surface_derived_parameters_ir_rudics_cts5
         fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface CROVER data processing not implemented yet\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat);
      end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesCrover] = merge_profile_meas_ir_rudics_cts5_usea_crover(tabProfilesCrover);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesCrover] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesCrover);
      
      o_tabProfiles = [o_tabProfiles tabProfilesCrover];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(apmtSuna))
      
      % create profiles (as they are transmitted)
      [tabProfilesSuna, tabDriftSuna, tabSurfSuna] = ...
         process_profile_ir_rudics_cts5_usea_suna(apmtSuna, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftSuna];
      tabSurf = [tabSurf tabSurfSuna];
      
      if (~isempty(tabSurfSuna))
         % only OPTODE and OCR sensor surface mesurements are implement in
         % compute_surface_derived_parameters_ir_rudics_cts5
         fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface SUNA data processing not implemented yet\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat);
      end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesSuna] = merge_profile_meas_ir_rudics_cts5_usea_suna(tabProfilesSuna);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesSuna] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesSuna);
      
      o_tabProfiles = [o_tabProfiles tabProfilesSuna];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(uvpLpmData))
      
      % create profiles (as they are transmitted)
      [tabProfilesUvpLpm, tabDriftUvpLpm, tabSurfUvpLpm] = ...
         process_profile_ir_rudics_cts5_usea_uvp_lpm(uvpLpmData, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftUvpLpm];
      tabSurf = [tabSurf tabSurfUvpLpm];
      
      %       if (~isempty(tabSurfUvpLpm))
      %          % only OPTODE and OCR sensor surface mesurements are implement in
      %          % compute_surface_derived_parameters_ir_rudics_cts5
      %          fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface UVP-LPM data processing not implemented yet\n', ...
      %             g_decArgo_floatNum, ...
      %             g_decArgo_cycleNum, ...
      %             g_decArgo_cycleNumFloat, ...
      %             g_decArgo_patternNumFloat);
      %       end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpLpm] = merge_profile_meas_ir_rudics_cts5_usea_uvp_lpm(tabProfilesUvpLpm);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpLpm] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpLpm);
      
      o_tabProfiles = [o_tabProfiles tabProfilesUvpLpm];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(uvpBlackData))
      
      % create profiles (as they are transmitted)
      [tabProfilesUvpBlack, tabDriftUvpBlack, tabSurfUvpBlack] = ...
         process_profile_ir_rudics_cts5_usea_uvp_black(uvpBlackData, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftUvpBlack];
      tabSurf = [tabSurf tabSurfUvpBlack];
      
      %       if (~isempty(tabSurfUvpBlack))
      %          % only OPTODE and OCR sensor surface mesurements are implement in
      %          % compute_surface_derived_parameters_ir_rudics_cts5
      %          fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface UVP-BLACK data processing not implemented yet\n', ...
      %             g_decArgo_floatNum, ...
      %             g_decArgo_cycleNum, ...
      %             g_decArgo_cycleNumFloat, ...
      %             g_decArgo_patternNumFloat);
      %       end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesUvpBlack] = merge_profile_meas_ir_rudics_cts5_usea_uvp_black(tabProfilesUvpBlack);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesUvpBlack] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesUvpBlack);
      
      o_tabProfiles = [o_tabProfiles tabProfilesUvpBlack];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(opusLightData))
      
      % create profiles (as they are transmitted)
      [tabProfilesOpusLight, tabDriftOpusLight, tabSurfOpusLight] = ...
         process_profile_ir_rudics_cts5_usea_opus_light(opusLightData, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftOpusLight];
      tabSurf = [tabSurf tabSurfOpusLight];
      
      %       if (~isempty(tabSurfOpusLight))
      %          % only OPTODE and OCR sensor surface mesurements are implement in
      %          % compute_surface_derived_parameters_ir_rudics_cts5
      %          fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface OPUS-LIGHT data processing not implemented yet\n', ...
      %             g_decArgo_floatNum, ...
      %             g_decArgo_cycleNum, ...
      %             g_decArgo_cycleNumFloat, ...
      %             g_decArgo_patternNumFloat);
      %       end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesOpusLight] = merge_profile_meas_ir_rudics_cts5_usea_opus_light(tabProfilesOpusLight);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesOpusLight] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOpusLight);
      
      o_tabProfiles = [o_tabProfiles tabProfilesOpusLight];
   end   
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(opusBlackData))
      
      % create profiles (as they are transmitted)
      [tabProfilesOpusBlack, tabDriftOpusBlack, tabSurfOpusBlack] = ...
         process_profile_ir_rudics_cts5_usea_opus_black(opusBlackData, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftOpusBlack];
      tabSurf = [tabSurf tabSurfOpusBlack];
      
      %       if (~isempty(tabSurfOpusBlack))
      %          % only OPTODE and OCR sensor surface mesurements are implement in
      %          % compute_surface_derived_parameters_ir_rudics_cts5
      %          fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface OPUS-BLACK data processing not implemented yet\n', ...
      %             g_decArgo_floatNum, ...
      %             g_decArgo_cycleNum, ...
      %             g_decArgo_cycleNumFloat, ...
      %             g_decArgo_patternNumFloat);
      %       end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesOpusBlack] = merge_profile_meas_ir_rudics_cts5_usea_opus_black(tabProfilesOpusBlack);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesOpusBlack] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesOpusBlack);
      
      o_tabProfiles = [o_tabProfiles tabProfilesOpusBlack];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(ramsesData))
      
      % create profiles (as they are transmitted)
      [tabProfilesRamses, tabDriftRamses, tabSurfRamses] = ...
         process_profile_ir_rudics_cts5_usea_ramses(ramsesData, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftRamses];
      tabSurf = [tabSurf tabSurfRamses];
      
      %       if (~isempty(tabSurfRamses))
      %          % only OPTODE and OCR sensor surface mesurements are implement in
      %          % compute_surface_derived_parameters_ir_rudics_cts5
      %          fprintf('DEC_ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): surface RAMSES data processing not implemented yet\n', ...
      %             g_decArgo_floatNum, ...
      %             g_decArgo_cycleNum, ...
      %             g_decArgo_cycleNumFloat, ...
      %             g_decArgo_patternNumFloat);
      %       end
      
      % merge profiles (all data from a given sensor together)
      [tabProfilesRamses] = merge_profile_meas_ir_rudics_cts5_usea_ramses(tabProfilesRamses);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesRamses] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesRamses);
      
      o_tabProfiles = [o_tabProfiles tabProfilesRamses];
   end
   
   %%%%%%%%%%%%%%%%%%%%
   if (~isempty(mpeData))
      
      % create profiles (as they are transmitted)
      [tabProfilesMpe, tabDriftMpe, tabSurfMpe] = ...
         process_profile_ir_rudics_cts5_usea_mpe(mpeData, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftMpe];
      tabSurf = [tabSurf tabSurfMpe];
            
      % merge profiles (all data from a given sensor together)
      [tabProfilesMpe] = merge_profile_meas_ir_rudics_cts5_usea_mpe(tabProfilesMpe);
      
      % add the vertical sampling scheme from configuration information
      [tabProfilesMpe] = add_vertical_sampling_scheme_ir_rudics_cts5_usea_bgc(tabProfilesMpe);
      
      o_tabProfiles = [o_tabProfiles tabProfilesMpe];
   end

   %%%%%%%%%%%%%%%%%%%%
   % compute derived parameters of the profiles
   [o_tabProfiles] = compute_profile_derived_parameters_ir_rudics(o_tabProfiles, a_decoderId);

   print = 0;
   if (print == 1)
      if (~isempty(o_tabProfiles))
         fprintf('DEC_INFO: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): %d profiles for NetCDF file\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            length(o_tabProfiles));
         for idP = 1:length(o_tabProfiles)
            prof = o_tabProfiles(idP);
            paramList = prof.paramList;
            paramList = sprintf('%s ', paramList.name);
            profLength = size(prof.data, 1);
            fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
               idP, prof.profileNumber, prof.direction, ...
               profLength, paramList(1:end-1));
         end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TRAJ NetCDF file
   
   % compute derived parameters of the park phase
   [tabDrift] = compute_drift_derived_parameters_ir_rudics(tabDrift, a_decoderId);
   
   % compute derived parameters of the surface phase
   [tabSurf] = compute_surface_derived_parameters_ir_rudics_cts5(tabSurf, a_decoderId);
   
   % collect trajectory data for TRAJ NetCDF file
   [tabTrajIndex, tabTrajData] = collect_trajectory_data_cts5_usea( ...
      o_tabProfiles, tabDrift, tabSurf, trajDataFromApmtTech, subSurfaceMeas);
   
   % process trajectory data for TRAJ NetCDF file
   [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_cts5_usea( ...
      tabTrajIndex, tabTrajData, a_firstCycleNum);
   
   % sort trajectory data structures according to the predefined
   % measurement code order
   %    [tabTrajNMeas] = sort_trajectory_data_cyprofnum(tabTrajNMeas, a_decoderId);
   
   o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
   o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TECH NetCDF file
   
   % collect technical data (and merge Tech and Event technical data)
   [tabNcTechIndex, tabNcTechVal, tabTechNMeas] = collect_technical_data_cts5_usea(techDataFromApmtTech);
   
   if (~isempty(tabNcTechIndex))
      o_tabNcTechIndex = [o_tabNcTechIndex tabNcTechIndex];
      o_tabNcTechVal = [o_tabNcTechVal tabNcTechVal];
   end
   if (~isempty(tabTechNMeas))
      o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
   end
   
end

if (~isempty(o_tabProfiles) || ~isempty(o_tabTrajNMeas) || ...
      ~isempty(o_tabTrajNCycle) || ~isempty(o_tabNcTechIndex) || ...
      ~isempty(o_tabNcTechVal) || ~isempty(o_tabTechNMeas))
   g_decArgo_generateNcFlag = 1;
end

return
