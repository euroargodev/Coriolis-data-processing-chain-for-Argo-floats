% ------------------------------------------------------------------------------
% Decode PROVOR CTS5 floats.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
%    o_structConfig] = ...
%    decode_provor_iridium_rudics_cts5( ...
%    a_floatNum, a_cycleList, a_decoderId, a_floatLoginName, ...
%    a_launchDate, a_refDay, a_floatDmFlag)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_cycleList      : list of cycles to be decoded
%   a_decoderId      : float decoder Id
%   a_floatLoginName : float name
%   a_launchDate     : launch date
%   a_refDay         : reference day (day of the first descent)
%   a_floatDmFlag    : float DM flag
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
   o_structConfig] = ...
   decode_provor_iridium_rudics_cts5( ...
   a_floatNum, a_cycleList, a_decoderId, a_floatLoginName, ...
   a_launchDate, a_refDay, a_floatDmFlag)

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

% default values
global g_decArgo_janFirst1950InMatlab;

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
global g_decArgo_generateNcTraj;
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

% global g_decArgo_nbBuffToProcess;
% g_decArgo_nbBuffToProcess = 5;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% number of the first cycle to process
global g_decArgo_firstCycleNumCts5;

% variable to store all useful event data
global g_decArgo_eventData;
g_decArgo_eventData = [];

% decoded event data
global g_decArgo_eventDataTech;
global g_decArgo_eventDataTraj;
global g_decArgo_eventDataMeta;
global g_decArgo_eventDataTime;

% payload configuration file information
global g_decArgo_payloadConfigFile; % date of application and file name
global g_decArgo_payloadConfigFileNum; % file number in the list
global g_decArgo_payloadConfigCy; % associated cycle
global g_decArgo_payloadConfigPtn; % associated pattern
g_decArgo_payloadConfigFile = [];
g_decArgo_payloadConfigFileNum = -1;
g_decArgo_payloadConfigCy = -1;
g_decArgo_payloadConfigPtn = -1;

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
global g_decArgo_dataPayloadCorrectedCycle;
g_decArgo_dataPayloadCorrectedCycle = 0;

% meta-data retrieved from APMT tech files
global g_decArgo_apmtMetaFromTech;
g_decArgo_apmtMetaFromTech = [];

% type of files to consider
global g_decArgo_fileTypeListCts5;
g_decArgo_fileTypeListCts5 = [ ...
   {1} {'*_apmt*.ini'} {'_%u_%u_apmt'} {16} {'_%03d_%02d_apmt*.ini'};...
   {9} {'*_payload*.xml'} {'_%u_%u_payload'} {19} {'_%03d_%02d_payload*.xml'}; ...
   {2} {'_payload*.txt'} {''} {[]} {''}; ...
   {3} {'*_autotest_*.txt'} {'_%u_autotest'} {17} {'_%03d_autotest_*.txt'}; ...
   {4} {'*_technical*.txt'} {'_%u_%u_technical'} {21} {'_%03d_%02d_technical*.txt'}; ...
   {5} {'*_default_*.txt'} {'_%u_%u_default'} {19} {'_%03d_%02d_default_*.txt'}; ...
   {6} {'*_sbe41*.hex'} {'_%u_%u_sbe41'} {17} {'_%03d_%02d_sbe41*.hex'}; ...
   {7} {'*_payload*.bin'} {'_%u_%u_payload'} {19} {'_%03d_%02d_payload*.bin'}; ...
   %    {8} {'_system_*.hex'} {'_system_%u.hex'} {''}; ...
   ];


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
if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_generateNcTraj ~= 0))
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
   return;
   
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
init_float_config_prv_ir_rudics_cts5(a_launchDate, a_decoderId);
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
[floatCycleList, g_decArgo_cyclePatternNumFloat, payloadConfigFiles] = get_cycle_ptn_cts5;

% store payload configuration file information
g_decArgo_payloadConfigFile = cell(length(payloadConfigFiles), 3);
for idFile = 1:length(payloadConfigFiles)
   fileNameInput = payloadConfigFiles{idFile};
   fileDate = datenum([fileNameInput(10:15) fileNameInput(17:22)], 'yymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
   
   g_decArgo_payloadConfigFile{idFile, 1} = fileDate;
   g_decArgo_payloadConfigFile{idFile, 2} = g_decArgo_archiveDirectory;
   g_decArgo_payloadConfigFile{idFile, 3} = fileNameInput;
end

% retrieve event data
ok = get_event_data_cts5(g_decArgo_cyclePatternNumFloat, a_launchDate, a_decoderId);
if (~ok)
   return;
end

% process available files
tabCyclesToProcessAgain = [];
stop = 0;
for idFlCy = 1:length(floatCycleList)
   floatCyNum = floatCycleList(idFlCy);
   
   if (floatCyNum < g_decArgo_firstCycleNumFloat)
      continue;
   end
   
   if (floatCyNum == g_decArgo_firstCycleNumFloat)
      g_decArgo_cycleNum = 0;
   end
   
   %    if (floatCyNum > 20)
   %       a=1
   %       break;
   %    end
   
   % get files to process
   idDel = [];
   expectedFileList = get_expected_file_list(floatCyNum, [], g_decArgo_filePrefixCts5, g_decArgo_firstCycleNumFloat);
   for idFile = 1:length(expectedFileList)
      expectedFileName = expectedFileList{idFile};
      if (isempty(dir([g_decArgo_archiveDirectory '/' expectedFileName(1:end-4) '*' expectedFileName(end-3:end)])))
         if (idFlCy == length(floatCycleList))
            idDel = [idDel idFile];
            if (g_decArgo_realtimeFlag)
               fprintf('INFO: expected file not received yet %s => stop\n', ...
                  expectedFileName);
               stop = 1;
               break;
            else
               fprintf('WARNING: expected file not received yet %s\n', ...
                  expectedFileName);
            end
         else
            fprintf('WARNING: expected file not received %s\n', ...
               expectedFileName);
            idDel = [idDel idFile];
         end
      end
   end
   fileToProcess = expectedFileList;
   fileToProcess(idDel) = [];
   
   if (~isempty(fileToProcess) && (floatCyNum ~= g_decArgo_firstCycleNumFloatNew))
      % anomaly: the float has been reset => we store all associated surface
      % data in a new cycle (similar to cycle #0)
      
      if (isempty(g_decArgo_argoCycleNumForFirstCycleNumFloatNew))
         g_decArgo_cycleNum = g_decArgo_cycleNum + 1;
         fprintf('WARNING: Float #%d: A reset of the float has been detected at float cycle #%d\n', ...
            g_decArgo_floatNum, floatCyNum);
         g_decArgo_argoCycleNumForFirstCycleNumFloatNew = g_decArgo_cycleNum;
         g_decArgo_firstCycleNumFloatNew = floatCyNum;
      else
         if (g_decArgo_argoCycleNumForFirstCycleNumFloatNew ~= g_decArgo_cycleNum)
            g_decArgo_cycleNum = g_decArgo_cycleNum + 1;
            fprintf('WARNING: Float #%d: A reset of the float has been detected at float cycle #%d\n', ...
               g_decArgo_floatNum, floatCyNum);
            g_decArgo_argoCycleNumForFirstCycleNumFloatNew = g_decArgo_cycleNum;
            g_decArgo_firstCycleNumFloatNew = floatCyNum;
         end
      end

      % assign the current configuration to the current cycle and pattern
      %       set_float_config_ir_rudics_cts5(floatCyNum, 0);
   end
      
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
      g_decArgo_eventDataTraj = [];
      g_decArgo_eventDataMeta = [];
      g_decArgo_eventDataTime = [];

      g_decArgo_cycleNumFloat = floatCyNum;
      g_decArgo_cycleNumFloatStr = num2str(floatCyNum);
      g_decArgo_patternNumFloat = [];
      g_decArgo_patternNumFloatStr = '-';
      
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, tabTechNMeas] = decode_files(fileToProcess, a_decoderId, g_decArgo_firstCycleNumCts5);
      
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
      end
      if (~isempty(tabNcTechVal))
         o_tabNcTechVal = [o_tabNcTechVal; tabNcTechVal'];
      end
      if (~isempty(tabTechNMeas))
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
      end
      
      idF = find(g_decArgo_cyclePatternNumFloat(:, 1) == floatCyNum);
      for idFlCyPtn = 1:length(idF)
         floatPtnNum = g_decArgo_cyclePatternNumFloat(idF(idFlCyPtn), 2);
         
         % retrieve useful information from event data
         decode_event_data_cts5(floatCyNum, floatPtnNum);
         
         % get files to process
         idDel = [];
         missingFileList = [];
         expectedFileList = get_expected_file_list(floatCyNum, floatPtnNum, g_decArgo_filePrefixCts5, g_decArgo_firstCycleNumFloat);
         for idFile = 1:length(expectedFileList)
            expectedFileName = expectedFileList{idFile};
            if (isempty(dir([g_decArgo_archiveDirectory '/' expectedFileName(1:end-4) '*' expectedFileName(end-3:end)])))
               if (idFlCy == length(floatCycleList))
                  idDel = [idDel idFile];
                  if (g_decArgo_realtimeFlag)
                     missingFileList{end+1} = expectedFileName;
                     fprintf('WARNING: expected file not received %s\n', ...
                        expectedFileName);
                     idDel = [idDel idFile];
                  else
                     fprintf('WARNING: expected file not received yet %s\n', ...
                        expectedFileName);
                  end
               else
                  fprintf('WARNING: expected file not received %s\n', ...
                     expectedFileName);
                  idDel = [idDel idFile];
               end
            end
         end
         if (g_decArgo_realtimeFlag)
            if (~isempty(missingFileList))
               % EOL files are not necessarily received all
               % Ex: 4901804: the float switched to EOL mode after an emergency
               % ascent but because of ice coverage and full memory all EOL
               % messages were not transmitted (only the last ones and the
               % memorized ones are transmitted).
               if (length(cell2mat(strfind(missingFileList, '_default_'))) == length(missingFileList))
                  missingNum = [];
                  for idFile = 1:length(missingFileList)
                     missingFileName = missingFileList{idFile};
                     idFUs = strfind(missingFileName, '_');
                     missingNum = [missingNum str2num(missingFileName(idFUs(4)+1:end-4))];
                  end
                  existingNum = [];
                  existingFileList = dir([g_decArgo_archiveDirectory '/' missingFileName(1:idFUs(4)) '*']);
                  for idFile = 1:length(existingFileList)
                     existingFileName = existingFileList(idFile).name;
                     idFUs = strfind(existingFileName, '_');
                     existingNum = [existingNum str2num(existingFileName(idFUs(4)+1:idFUs(5)-1))];
                  end
                  if (~any(existingNum > max(missingNum)))
                     fprintf('INFO: expected files not received yet => stop\n');
                     stop = 1;
                     break;
                  end
               else
                  fprintf('INFO: expected files not received yet => stop\n');
                  stop = 1;
                  break;
               end
            end
         end
         fileToProcess = expectedFileList;
         fileToProcess(idDel) = [];
         
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
               tabNcTechIndex, tabNcTechVal, tabTechNMeas] = decode_files(fileToProcess, a_decoderId, g_decArgo_firstCycleNumCts5);
            
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
            end
            if (~isempty(tabNcTechVal))
               o_tabNcTechVal = [o_tabNcTechVal; tabNcTechVal'];
            end
            if (~isempty(tabTechNMeas))
               o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
            end
            
            if (g_decArgo_dataPayloadCorrectedCycle == 1)
               if (~isempty(tabProfiles))
                  % collect cycle number to be re-processed
                  cycleProfileIds = find(([tabProfiles.cycleNumber] == g_decArgo_cycleNumFloat) & ...
                     ([tabProfiles.profileNumber] == g_decArgo_patternNumFloat) & ...
                     ([tabProfiles.outputCycleNumber] == g_decArgo_cycleNum));
                  otherCycleProfileIds = setdiff(1:length(tabProfiles), cycleProfileIds);
                  
                  for idProf = 1:length(otherCycleProfileIds)
                     tabCyclesToProcessAgain = [tabCyclesToProcessAgain;
                        tabProfiles(otherCycleProfileIds(idProf)).cycleNumber ...
                        tabProfiles(otherCycleProfileIds(idProf)).profileNumber];
                  end
               end
               
               if (~isempty(tabTrajNMeas))
                  % collect cycle number to be re-processed
                  cycleNMeasIds = find(([tabTrajNMeas.cycleNumber] == g_decArgo_cycleNumFloat) & ...
                     ([tabTrajNMeas.profileNumber] == g_decArgo_patternNumFloat));
                  otherCycleNMeasIds = setdiff(1:length(tabTrajNMeas), cycleNMeasIds);
                  
                  for idNM = 1:length(otherCycleNMeasIds)
                     tabCyclesToProcessAgain = [tabCyclesToProcessAgain;
                        tabTrajNMeas(otherCycleNMeasIds(idNM)).cycleNumber ...
                        tabTrajNMeas(otherCycleNMeasIds(idNM)).profileNumber];
                  end
               end
               
               if (~isempty(tabTrajNCycle))
                  % collect cycle number to be re-processed
                  cycleNCycleIds = find(([tabTrajNCycle.cycleNumber] == g_decArgo_cycleNumFloat) & ...
                     ([tabTrajNCycle.profileNumber] == g_decArgo_patternNumFloat));
                  otherCycleNCycleIds = setdiff(1:length(tabTrajNCycle), cycleNCycleIds);
                  
                  for idNC = 1:length(otherCycleNCycleIds)
                     tabCyclesToProcessAgain = [tabCyclesToProcessAgain;
                        tabTrajNCycle(otherCycleNCycleIds(idNC)).cycleNumber ...
                        tabTrajNCycle(otherCycleNCycleIds(idNC)).profileNumber];
                  end
               end
               
               tabCyclesToProcessAgain = unique(tabCyclesToProcessAgain, 'rows', 'stable');
            end
         end
      end
   end
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % we should first re-process data from cycles affected to erroneous files
   if (g_decArgo_dataPayloadCorrectedCycle == 1)
      
      for idL = 1:size(tabCyclesToProcessAgain, 1)
         cyNum = tabCyclesToProcessAgain(idL, 1);
         profNum = tabCyclesToProcessAgain(idL, 2);
         
         g_decArgo_cycleNumFloat = cyNum;
         g_decArgo_cycleNumFloatStr = num2str(cyNum);
         g_decArgo_patternNumFloat = profNum;
         g_decArgo_patternNumFloatStr = num2str(profNum);
         
         % reprocess profile data
         idFProfPayload = find(([o_tabProfiles.cycleNumber] == cyNum) & ...
            ([o_tabProfiles.profileNumber] == profNum) & ...
            ([o_tabProfiles.sensorNumber] ~= 0));
         idFProfCtd = find(([o_tabProfiles.cycleNumber] == cyNum) & ...
            ([o_tabProfiles.profileNumber] == profNum) & ...
            ([o_tabProfiles.sensorNumber] == 0));
         
         tabProfilesPayload = o_tabProfiles(idFProfPayload);
         tabProfilesCtd = o_tabProfiles(idFProfCtd);
         o_tabProfiles(idFProfPayload) = [];
         o_tabProfiles(idFProfCtd) = [];
         
         % merge profiles (all data from a given sensor together)
         [tabProfilesPayload] = merge_profile_meas_ir_rudics_cts5_from_payload(tabProfilesPayload);
         
         % add the vertical sampling scheme from configuration information
         [tabProfilesPayload] = add_vertical_sampling_scheme_ir_rudics_cts5_from_payload(tabProfilesPayload);
         
         % compute derived parameters of the profiles
         [tabProfilesCtdAndPayload] = compute_profile_derived_parameters_ir_rudics([tabProfilesPayload tabProfilesCtd], a_decoderId);
         
         o_tabProfiles = [o_tabProfiles tabProfilesCtdAndPayload];
         
         % reprocess trajectory data
         idFNMeas = find(([o_tabTrajNMeas.cycleNumber] == cyNum) & ...
            ([o_tabTrajNMeas.profileNumber] == profNum) & ...
            ([o_tabTrajNMeas.surfOnly] == 0));
         
         % collect trajectory data for TRAJ NetCDF file
         [tabTrajIndex, tabTrajData] = collect_profile_trajectory_data_cts5(tabProfilesCtdAndPayload);
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_cts5(tabTrajIndex, tabTrajData, g_decArgo_firstCycleNumCts5);
         
         % merge N_MEASUREMENT arrays
         [o_tabTrajNMeas(idFNMeas)] = merge_n_measurement_data_cts5(o_tabTrajNMeas(idFNMeas), tabTrajNMeas);
         
      end
      
      [~, idSort] = sort([o_tabProfiles.outputCycleNumber]);
      o_tabProfiles = o_tabProfiles(idSort);
   end
   
   % output NetCDF files
   
   % add interpolated profile locations
   [o_tabProfiles] = fill_empty_profile_locations_ir_rudics(o_tabProfiles, g_decArgo_gpsData, ...
      o_tabTrajNMeas, o_tabTrajNCycle);
   
   % cut CTD profile at the cut-off pressure of the CTD pump
   [o_tabProfiles] = cut_ctd_profile_ir_rudics(o_tabProfiles);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_rudics_cts5;

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
   % consistency
   [o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNCycle, o_tabTrajNMeas);
   
   if (g_decArgo_realtimeFlag == 1)
      
      % save the list of already processed rsync log files in the history
      % directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'processed', ...
         g_decArgo_rsyncLogFileUnderProcessList);
      
      % save the list of used rsync log files in the history directory of the float
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, 'used', ...
         unique(g_decArgo_rsyncLogFileUsedList));
   end
   
   % add float cycle and pattern number to the NetCDF technical data
   [o_tabNcTechIndex, o_tabNcTechVal] = ...
      update_technical_data_ir_rudics_cts5(o_tabNcTechIndex, o_tabNcTechVal, g_decArgo_firstCycleNumCts5);
end

return;

% ------------------------------------------------------------------------------
% Decode a set of PROVOR CTS5 files.
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
%   02/20/2017 - RNU - creation
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

% payload configuration file information
global g_decArgo_payloadConfigFile; % date of application and file name
global g_decArgo_payloadConfigFileNum; % file number in the list
global g_decArgo_payloadConfigCy; % associated cycle
global g_decArgo_payloadConfigPtn; % associated pattern

% prefix of data file names
global g_decArgo_filePrefixCts5;

% type of files to consider
global g_decArgo_fileTypeListCts5;

% due to payload issue, we should store all time information (to assign payload
% data to their correct cycle)
global g_decArgo_trajDataFromApmtTech;
global g_decArgo_dataPayloadCorrectedCycle;

% meta-data retrieved from APMT tech files
global g_decArgo_apmtMetaFromTech;

if (isempty(a_fileNameList))
   return;
end

% set the type of each file
fileNames = a_fileNameList;
fileTypes = zeros(size(fileNames));
for idF = 1:length(fileNames)
   fileName = fileNames{idF};
   if (~isempty(g_decArgo_patternNumFloat))
      typeList = [1 4 5 6 7];
      for idType = typeList
         idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
         [val, count, errmsg, nextindex] = sscanf( ...
            fileName(1:g_decArgo_fileTypeListCts5{idFL, 4}), ...
            [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idFL, 3}]);
         if (isempty(errmsg) && (count == 2))
            if (strcmp(fileName(end-3:end), g_decArgo_fileTypeListCts5{idFL, 2}(end-3:end)))
               fileTypes(idF) = idType;
               break;
            end
         end
      end
   else
      if (strncmp(fileName, g_decArgo_filePrefixCts5, length(g_decArgo_filePrefixCts5)))
         typeList = [3];
         for idType = typeList
            idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
            [val, count, errmsg, nextindex] = sscanf( ...
               fileName(1:g_decArgo_fileTypeListCts5{idFL, 4}), ...
               [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idFL, 3}]);
            if (isempty(errmsg) && (count == 1))
               fileTypes(idF) = idType;
               break;
            end
         end
      elseif (strncmp(fileName, '_payload_', length('_payload_')))
         fileTypes(idF) = 2;
      end
   end
end

% update the configuration only if data has been received
setFloatConfig = 0;
if (ismember(6, fileTypes) || ismember(7, fileTypes))
   setFloatConfig = 1;
end

% the files should be processed in the following order
typeOrderList = [2 3 4 6 7 5 1];
% 2: the payload configuration can be anywhere in the list (because it is
% decoded independantly through a recursive call)
% 3, 4, 6, 7, 5: usual order i.e. tech first, data after and EOL at the end
% 1: last the apmt configuration because it concerns the next cycle and pattern

% process the files
fprintf('DEC_INFO: decoding files:\n');
apmtCtd = [];
payloadData = [];
techDataFromApmtTech = [];
trajDataFromApmtTech = [];
timeDataFromApmtTech = [];
payloadConfigFileOnly = 0;
for typeNum = typeOrderList
   
   if (typeNum == 1)
      % we should set the configuration before decoding apmt configuration
      % (which concerns the next cycle and pattern)
      if (setFloatConfig == 1)
         % assign the current configuration to the current cycle and pattern
         set_float_config_ir_rudics_cts5(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat);
      end
   end
   
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
            case 1
               % '*_apmt*.ini'
               % apmt configuration file
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               
               % read apmt configuration
               apmtConfig = read_apmt_config([fileNameInfo{4} fileNameInfo{1}]);
               
               % update current configuration
               update_float_config_ir_rudics_cts5('A', apmtConfig);
               
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
               
            case 2
               % '_payload*.txt'
               % payload configuration file
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               
               % update current configuration
               update_float_config_ir_rudics_cts5('P', [fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  % read payload configuration
                  payloadConfig = read_payload_config([fileNameInfo{4} fileNameInfo{1}]);
                  
                  % print payload configuration in CSV file
                  print_payload_config_in_csv_file_ir_rudics_cts5(payloadConfig);
                  
                  % print updated configuration in CSV file
                  print_config_in_csv_file_ir_rudics_cts5('Updated_config');
               end
               
               payloadConfigFileOnly = 1;
               
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
               
               % store GPS data
               store_gps_data_ir_rudics_cts5(apmtTech, typeNum);
               
               % process updated payload configuration if any
               cycleStartDate = retrieve_cycle_start_date(apmtTech);
               if (~isempty(cycleStartDate))
                  idConfigFileNum = find(cycleStartDate > [g_decArgo_payloadConfigFile{:, 1}]);
                  if (~isempty(idConfigFileNum))
                     g_decArgo_payloadConfigFileNum = idConfigFileNum;
                     g_decArgo_payloadConfigCy = g_decArgo_cycleNumFloat;
                     g_decArgo_payloadConfigPtn = g_decArgo_patternNumFloat;
                  end
               end
               
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
               
            case 6
               % '*_sbe41*.hex'
               % apmt sensor data
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               apmtCtd = decode_apmt_ctd([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_ctd_data_in_csv_file_ir_rudics_cts5(apmtCtd);
               end
               
            case 7
               % '*_payload*.bin'
               % payload sensor data
               
               if ((g_decArgo_cycleNumFloat == g_decArgo_payloadConfigCy) && ...
                     (g_decArgo_patternNumFloat == g_decArgo_payloadConfigPtn))
                  
                  % decode payload new configuration and print it before associated
                  % payload data
                  tmpCycleNumFloat = g_decArgo_cycleNumFloat;
                  tmpCycleNumFloatStr = g_decArgo_cycleNumFloatStr;
                  tmpPatternNumFloat = g_decArgo_patternNumFloat;
                  tmpPatternNumFloatStr = g_decArgo_patternNumFloatStr;
                  g_decArgo_cycleNumFloat = [];
                  g_decArgo_cycleNumFloatStr = '-';
                  g_decArgo_patternNumFloat = [];
                  g_decArgo_patternNumFloatStr = '-';
                  
                  decode_files(g_decArgo_payloadConfigFile(g_decArgo_payloadConfigFileNum, 3), ...
                     a_decoderId, a_firstCycleNum);
                  g_decArgo_payloadConfigFile(g_decArgo_payloadConfigFileNum, :) = [];
                  
                  g_decArgo_cycleNumFloat = tmpCycleNumFloat;
                  g_decArgo_cycleNumFloatStr = tmpCycleNumFloatStr;
                  g_decArgo_patternNumFloat = tmpPatternNumFloat;
                  g_decArgo_patternNumFloatStr = tmpPatternNumFloatStr;
                  g_decArgo_payloadConfigFileNum = -1;
                  g_decArgo_payloadConfigCy = -1;
                  g_decArgo_payloadConfigPtn = -1;
               end
               
               fprintf('   - %s (%d)\n', fileNamesForType{idFile}, length(fileNameInfo{2}));
               [payloadData, emptyPayloadData] = decode_payload_data([fileNameInfo{4} fileNameInfo{1}]);
               
               if (~isempty(g_decArgo_outputCsvFileId))
                  
                  for idFile2 = 1:length(fileNameInfo{2})
                     fprintf(g_decArgo_outputCsvFileId, '%d; %s; %s; File name; -; %s\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNumFloatStr, g_decArgo_patternNumFloatStr, ...
                        fileNameInfo{2}{idFile2});
                  end
                  
                  print_payload_data_in_csv_file_ir_rudics_cts5(payloadData);
               end
               
            otherwise
               fprintf('WARNING: Nothing define yet to process file: %s\n', ...
                  fileNamesForType{idFile});
         end
      end
      
      fileNames(idFileForType) = [];
      fileTypes(idFileForType) = [];
   end
end

if (~isempty(fileNames))
   fprintf('DEC_WARNING: %d files were not processed\n', ...
      length(fileNames));
end

if (~isempty(g_decArgo_outputCsvFileId))
   
   % print time data in csv file
   print_dates_in_csv_file_ir_rudics_cts5(timeDataFromApmtTech, apmtCtd, payloadData);
end

% output NetCDF data
if (isempty(g_decArgo_outputCsvFileId) && (~payloadConfigFileOnly))
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % PROF NetCDF data
   
   % process profile data from apmt
   tabDrift = [];
   tabDriftRaw = [];
   tabSurf = [];
   tabSurfRaw = [];
   subSurfaceMeas = [];
   presCutOffProf = [];
   if (~isempty(apmtCtd))
      
      % create profiles (as they are transmitted)
      [tabProfiles, tabDriftApmt, subSurfaceMeas, presCutOffProf] = process_profiles_ir_rudics_cts5_from_apmt( ...
         apmtCtd, apmtTimeFromTech, g_decArgo_gpsData);
      tabDrift = [tabDrift tabDriftApmt];
      
      % merge profiles (all data from a given sensor together)
      [tabProfiles] = merge_profile_meas_ir_rudics_cts5_from_apmt(tabProfiles);
      
      % add the vertical sampling scheme from configuration information
      [tabProfiles] = add_vertical_sampling_scheme_ir_rudics_cts5_from_apmt(tabProfiles);
      
      o_tabProfiles = [o_tabProfiles tabProfiles];
   end
   
   % process profile data from payload
   if (~isempty(payloadData) && ~emptyPayloadData)
      
      % create profiles (as they are transmitted)
      [tabProfiles, tabDriftPayload, tabSurf, ...
         tabProfilesRaw, tabDriftRaw, tabSurfRaw] = process_profiles_ir_rudics_cts5_from_payload( ...
         payloadData, apmtTimeFromTech, g_decArgo_gpsData, presCutOffProf, o_tabProfiles, trajDataFromApmtTech);
      tabDrift = [tabDrift tabDriftPayload];
      
      % merge profiles (all data from a given sensor together)
      [tabProfiles] = merge_profile_meas_ir_rudics_cts5_from_payload(tabProfiles);
      
      % add the vertical sampling scheme from configuration information
      [tabProfiles] = add_vertical_sampling_scheme_ir_rudics_cts5_from_payload(tabProfiles);
            
      cycleProfileIds = 1:length(tabProfiles);
      if (g_decArgo_dataPayloadCorrectedCycle == 1)
         cycleProfileIds = find(([tabProfiles.cycleNumber] == g_decArgo_cycleNumFloat) & ...
            ([tabProfiles.profileNumber] == g_decArgo_patternNumFloat) & ...
            ([tabProfiles.outputCycleNumber] == g_decArgo_cycleNum));
      end
      otherCycleProfileIds = setdiff(1:length(tabProfiles), cycleProfileIds);

      o_tabProfiles = [o_tabProfiles tabProfiles(cycleProfileIds)]; % we should first add the CTD profile in the list before computing derived parameters
      
      % compute derived parameters of the profiles
      [o_tabProfiles] = compute_profile_derived_parameters_ir_rudics(o_tabProfiles, a_decoderId);
      
      o_tabProfiles = [o_tabProfiles tabProfiles(otherCycleProfileIds)];

      % we don't process derived parameters for raw data (because we don't have
      % any PRES, only times and sensor outputs) - could be done later if
      % clearly specified

      o_tabProfiles = [o_tabProfiles tabProfilesRaw];
   end
   
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
   [tabTrajIndex, tabTrajData] = collect_trajectory_data_cts5( ...
      o_tabProfiles, [tabDrift tabDriftRaw], [tabSurf tabSurfRaw], trajDataFromApmtTech, subSurfaceMeas);
   
   % process trajectory data for TRAJ NetCDF file
   [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_cts5(tabTrajIndex, tabTrajData, a_firstCycleNum);
   if (g_decArgo_dataPayloadCorrectedCycle == 1)
      
      % N_MEASUREMENT arrays for erroneous cycle numbers are removed => they
      % will be processed again later
      if (~isempty(tabTrajNMeas))
         trajNMeasIds = find(([tabTrajNMeas.cycleNumber] == g_decArgo_cycleNumFloat) & ...
            ([tabTrajNMeas.profileNumber] == g_decArgo_patternNumFloat));
         tabTrajNMeas = tabTrajNMeas(trajNMeasIds);
      end
      
      % N_CYCLE arrays for erroneous cycle numbers are useless => they are
      % ignored
      if (~isempty(tabTrajNCycle))
         trajNCycleIds = find(([tabTrajNCycle.cycleNumber] == g_decArgo_cycleNumFloat) & ...
            ([tabTrajNCycle.profileNumber] == g_decArgo_patternNumFloat));
         tabTrajNCycle = tabTrajNCycle(trajNCycleIds);
      end
   end
   
   o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
   o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % TECH NetCDF file
   
   % collect technical data (and merge Tech and Event technical data)
   [tabNcTechIndex, tabNcTechVal, tabTechNMeas] = collect_technical_data_cts5(techDataFromApmtTech);
   
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

return;

% ------------------------------------------------------------------------------
% Retrieve cycle start date from APMT technical information
%
% SYNTAX :
%  [o_cycleStartDate] = retrieve_cycle_start_date(a_apmtTech)
%
% INPUT PARAMETERS :
%   a_apmtTech : APMT technical information
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate : cycle start date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate] = retrieve_cycle_start_date(a_apmtTech)

% output parameters initialization
o_cycleStartDate = [];

if (isfield(a_apmtTech, 'PROFILE'))
   
   idF = find(strcmp(a_apmtTech.PROFILE.name, 'buoyancy reduction start date'), 1);
   if (~isempty(idF))
      o_cycleStartDate = a_apmtTech.PROFILE.data{idF};
   end
end

return;
