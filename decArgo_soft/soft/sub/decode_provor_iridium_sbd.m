% ------------------------------------------------------------------------------
% Decode PROVOR Iridium float with Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, ...
%    o_structConfig] = ...
%    decode_provor_iridium_sbd( ...
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
%   o_structConfig   : NetCDF float configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, ...
   o_structConfig] = ...
   decode_provor_iridium_sbd( ...
   a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
   a_launchDate, a_refDay, a_floatEndDate)

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

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabelBis;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% SBD sub-directories
global g_decArgo_spoolDirectory;
global g_decArgo_bufferDirectory;
global g_decArgo_archiveDirectory;
global g_decArgo_tmpDirectory;

% arrays to store rough information on received data
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8Or11Or14TypePacketExpected;
global g_decArgo_nbOf1Or8Or11Or14TypePacketReceived;
global g_decArgo_nbOf2Or9Or12Or15TypePacketExpected;
global g_decArgo_nbOf2Or9Or12Or15TypePacketReceived;
global g_decArgo_nbOf3Or10Or13Or16TypePacketExpected;
global g_decArgo_nbOf3Or10Or13Or16TypePacketReceived;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketExpected;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketExpected;
global g_decArgo_nbOf14Or12TypePacketReceived;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% decoder configuration values
global g_decArgo_generateNcTraj;
global g_decArgo_generateNcMeta;
global g_decArgo_dirInputRsyncData;
global g_decArgo_applyRtqc;

% float configuration
global g_decArgo_floatConfig;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatLoginNameList;
global g_decArgo_rsyncFloatSbdFileList;

% RT processing flag
global g_decArgo_realtimeFlag;

% processed data loaded flag
global g_decArgo_processedDataLoadedFlag;
g_decArgo_processedDataLoadedFlag = 0;

% report information structure
global g_decArgo_reportStruct;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 0;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;
g_decArgo_iridiumMailData = [];

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

% already processed rsync log information
global g_decArgo_floatWmoUnderProcessList;
global g_decArgo_rsyncLogFileUnderProcessList;

% verbose mode flag
VERBOSE_MODE_BUFF = 1;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDuration/24;

% array to store information on already decoded SBD files
global g_decArgo_sbdInfo;
g_decArgo_sbdInfo = [];


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' num2str(a_floatImei) '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'spool' directory used to select the SBD files that will be processed
% during the current session of the decoder
% - a 'buffer' directory used to gather the SBD files expected for a given cycle
% - a 'archive' directory used to store the processed SBD files
g_decArgo_spoolDirectory = [floatIriDirName 'spool/'];
if ~(exist(g_decArgo_spoolDirectory, 'dir') == 7)
   mkdir(g_decArgo_spoolDirectory);
end
g_decArgo_bufferDirectory = [floatIriDirName 'buffer/'];
if ~(exist(g_decArgo_bufferDirectory, 'dir') == 7)
   mkdir(g_decArgo_bufferDirectory);
end
g_decArgo_archiveDirectory = [floatIriDirName 'archive/'];
if ~(exist(g_decArgo_archiveDirectory, 'dir') == 7)
   mkdir(g_decArgo_archiveDirectory);
end
g_decArgo_tmpDirectory = [floatIriDirName 'rsync_log_processed/'];
if ~(exist(g_decArgo_tmpDirectory, 'dir') == 7)
   mkdir(g_decArgo_tmpDirectory);
end

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

% initialize float configuration
if (g_decArgo_processedDataLoadedFlag == 0)
   % initialize float parameter configuration
   init_float_config_ir_sbd(a_launchDate, a_decoderId);
end

% print DOXY coef in the output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   print_calib_coef_in_csv(a_decoderId);
end

% add launch position and time in the TRAJ NetCDF file
if (g_decArgo_processedDataLoadedFlag == 0)
   if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_generateNcTraj ~= 0))
      o_tabTrajNMeas = add_launch_data_ir_sbd;
   end
end

if (g_decArgo_realtimeFlag == 0)
   
   % move the mail files associated with the a_cycleList cycles into the spool
   % directory
   nbFiles = 0;
   for idFile = 1:length(a_cycleFileNameList)
      
      mailFileName = a_cycleFileNameList{idFile};
      cyIrJulD = datenum([mailFileName(4:11) mailFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      if (cyIrJulD < a_launchDate)
         fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
            g_decArgo_floatNum, ...
            mailFileName, julian_2_gregorian_dec_argo(a_launchDate));
         continue
      end
      
      if (a_floatEndDate ~= g_decArgo_dateDef)
         if (cyIrJulD > a_floatEndDate)
            fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
               g_decArgo_floatNum, ...
               mailFileName, julian_2_gregorian_dec_argo(a_floatEndDate));
            continue
         end
      end
      
      move_files_ir_sbd({mailFileName}, g_decArgo_archiveDirectory, g_decArgo_spoolDirectory, 0, 0);
      nbFiles = nbFiles + 1;
   end
   
   fprintf('BUFF_INFO: %d Iridium mail files moved from float archive dir to float spool dir\n', nbFiles);
else
   
   % new mail files have been collected with rsync, we are going to decode
   % all (archived and newly received) mail files
   
   % some mail files can be present in the buffer (if the final buffer was not
   % completed during the previous run of the RT decoder)
   % move the mail files from buffer to the archive directory (and delete the
   % associated SBD files)
   fileList = dir([g_decArgo_bufferDirectory '*.txt']);
   if (~isempty(fileList))
      fprintf('BUFF_INFO: Moving %d Iridium mail files from float buffer dir to float archive dir (and deleting associated SBD files)\n', ...
         length(fileList));
      for idF = 1:length(fileList)
         fileName = fileList(idF).name;
         move_files_ir_sbd({fileName}, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 0, 1);
      end
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
         
         if (cyIrJulD < a_launchDate)
            fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
               g_decArgo_floatNum, ...
               mailFileName, julian_2_gregorian_dec_argo(a_launchDate));
            continue
         end
         
         if (a_floatEndDate ~= g_decArgo_dateDef)
            if (cyIrJulD > a_floatEndDate)
               fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
                  g_decArgo_floatNum, ...
                  mailFileName, julian_2_gregorian_dec_argo(a_floatEndDate));
               continue
            end
         end
         
         move_files_ir_sbd({mailFileName}, g_decArgo_archiveDirectory, g_decArgo_spoolDirectory, 0, 0);
         nbFiles = nbFiles + 1;
      end
      
      fprintf('BUFF_INFO: %d Iridium mail files moved from float archive dir to float spool dir\n', nbFiles);
   end
   
   % duplicate the Iridium mail files colleted with rsync into the spool
   % directory
   fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
   fprintf('RSYNC_INFO: Duplicating %d Iridium mail files from rsync dir to float spool dir\n', ...
      length(fileIdList));
   
   nbFiles = 0;
   for idF = 1:length(fileIdList)
      
      mailFilePathName = [g_decArgo_dirInputRsyncData '/' ...
         g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
      
      [pathstr, mailFileName, ext] = fileparts(mailFilePathName);
      cyIrJulD = datenum([mailFileName(4:11) mailFileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
      
      if (cyIrJulD < a_launchDate)
         fprintf('RSYNC_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
            g_decArgo_floatNum, ...
            mailFileName, julian_2_gregorian_dec_argo(a_launchDate));
         continue
      end
      
      if (a_floatEndDate ~= g_decArgo_dateDef)
         if (cyIrJulD > a_floatEndDate)
            fprintf('RSYNC_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
               g_decArgo_floatNum, ...
               mailFileName, julian_2_gregorian_dec_argo(a_floatEndDate));
            continue
         end
      end
      
      copy_files_ir({[mailFileName ext]}, pathstr, g_decArgo_spoolDirectory);
      nbFiles = nbFiles + 1;
   end
   
   fprintf('RSYNC_INFO: %d Iridium mail files duplicated\n', nbFiles);
end

if ((g_decArgo_realtimeFlag == 1) || ...
      (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc == 1)))
   % initialize data structure to store report information
   g_decArgo_reportStruct = get_report_init_struct(a_floatNum, '');
end

% retrieve information on spool directory contents
[tabAllFileNames, ~, tabAllFileDates, ~] = get_dir_files_info_ir_sbd( ...
   g_decArgo_spoolDirectory, a_floatImei, 'txt', '');

% process the mail files of the spool directory in chronological order
for idSpoolFile = 1:length(tabAllFileNames)
   
   % move the next file into the buffer directory
   move_files_ir_sbd(tabAllFileNames(idSpoolFile), g_decArgo_spoolDirectory, g_decArgo_bufferDirectory, 0, 0);
   
   % extract the attachement
   [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
      tabAllFileNames{idSpoolFile}, g_decArgo_bufferDirectory, g_decArgo_bufferDirectory);
   g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
   if (attachmentFound == 0)
      move_files_ir_sbd(tabAllFileNames(idSpoolFile), g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 0);
      if (idSpoolFile < length(tabAllFileNames))
         continue;
      end
   end
   
   % delete duplicated SBD files (EX: 69001632, MOMSN=988)
   delete_duplicated_sbd_files(g_decArgo_bufferDirectory, g_decArgo_archiveDirectory);
   
   % process the files of the buffer directory
   
   % retrieve information on the files in the buffer
   [tabFileNames, ~, tabFileDates, tabFileSizes] = get_dir_files_info_ir_sbd( ...
      g_decArgo_bufferDirectory, a_floatImei, 'sbd', '');
   
   % create the 'old' and 'new' file lists
   tabOldFileNames = [];
   tabOldFileDates = [];
   tabOldFileSizes = [];
   idOld = [];
   if (~isempty(find(tabFileDates < tabAllFileDates(idSpoolFile)-MIN_SUB_CYCLE_DURATION_IN_DAYS, 1)))
      idOld = find((tabFileDates < tabFileDates(1)+MIN_SUB_CYCLE_DURATION_IN_DAYS));
      if (~isempty(idOld))
         tabOldFileNames = tabFileNames(idOld);
         tabOldFileDates = tabFileDates(idOld);
         tabOldFileSizes = tabFileSizes(idOld);
      end
   end
   
   idNew = setdiff(1:length(tabFileNames), idOld);
   tabNewFileNames = tabFileNames(idNew);
   tabNewFileDates = tabFileDates(idNew);
   tabNewFileSizes = tabFileSizes(idNew);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % process the 'old' files
   if (VERBOSE_MODE_BUFF == 1)
      for iFile = 1:length(tabOldFileNames)
         fprintf('BUFF_WARNING: Float #%d: processing ''old'' file %s (#%d of the %d files in the set)\n', ...
            g_decArgo_floatNum, ...
            tabOldFileNames{iFile}, iFile, length(tabOldFileNames));
      end
   end
   
   if (~isempty(tabOldFileNames))
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal] = ...
         decode_sbd_files( ...
         tabOldFileNames, tabOldFileDates, tabOldFileSizes, ...
         a_decoderId, a_launchDate, 0);
      
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
      
      % move the processed 'old' files into the archive directory (and delete the
      % associated SBD files)
      move_files_ir_sbd(tabOldFileNames, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 1);
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % check if the 'new' files can be processed
   
   % initialize information arrays
   g_decArgo_0TypePacketReceivedFlag = 0;
   g_decArgo_4TypePacketReceivedFlag = 0;
   g_decArgo_5TypePacketReceivedFlag = 0;
   g_decArgo_nbOf1Or8Or11Or14TypePacketExpected = -1;
   g_decArgo_nbOf1Or8Or11Or14TypePacketReceived = 0;
   g_decArgo_nbOf2Or9Or12Or15TypePacketExpected = -1;
   g_decArgo_nbOf2Or9Or12Or15TypePacketReceived = 0;
   g_decArgo_nbOf3Or10Or13Or16TypePacketExpected = -1;
   g_decArgo_nbOf3Or10Or13Or16TypePacketReceived = 0;
   g_decArgo_nbOf1Or8TypePacketExpected = -1;
   g_decArgo_nbOf1Or8TypePacketReceived = 0;
   g_decArgo_nbOf2Or9TypePacketExpected = -1;
   g_decArgo_nbOf2Or9TypePacketReceived = 0;
   g_decArgo_nbOf3Or10TypePacketExpected = -1;
   g_decArgo_nbOf3Or10TypePacketReceived = 0;
   g_decArgo_nbOf13Or11TypePacketExpected = -1;
   g_decArgo_nbOf13Or11TypePacketReceived = 0;
   g_decArgo_nbOf14Or12TypePacketExpected = -1;
   g_decArgo_nbOf14Or12TypePacketReceived = 0;
   
   
   % store the SBD data
   sbdDataDate = [];
   sbdDataData = [];
   for idBufFile = 1:length(tabNewFileNames)
      
      sbdFileName = tabNewFileNames{idBufFile};
      %       fprintf('SBD file : %s\n', sbdFileName);
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
      sbdFileDate = tabNewFileDates(idBufFile);
      sbdFileSize = tabNewFileSizes(idBufFile);
      
      if (sbdFileSize > 0)
         
         if (rem(sbdFileSize, 100) == 0)
            fId = fopen(sbdFilePathName, 'r');
            if (fId == -1)
               fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
                  g_decArgo_floatNum, ...
                  sbdFilePathName);
            end
            
            [sbdData, sbdDataCount] = fread(fId);
            
            fclose(fId);
            
            sbdData = reshape(sbdData, 100, size(sbdData, 1)/100)';
            for idMsg = 1:size(sbdData, 1)
               data = sbdData(idMsg, :);
               if (~isempty(find(data ~= 0, 1)))
                  sbdDataData = [sbdDataData; data];
                  sbdDataDate = [sbdDataDate; sbdFileDate];
               end
            end
         else
            fprintf('DEC_WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
               g_decArgo_floatNum, ...
               sbdFileSize, ...
               sbdFilePathName);
         end
         
      end
   end
   
   % roughly check the received data
   if (~isempty(sbdDataData))
      
      switch (a_decoderId)
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         
         case {201, 203} % Arvor-deep 4000
            
            % decode the collected data
            [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_201_203(sbdDataData, sbdDataDate, 0, a_decoderId);
            
            g_decArgo_nbOf1Or8TypePacketExpected = 0;
            g_decArgo_nbOf2Or9TypePacketExpected = 0;
            g_decArgo_nbOf3Or10TypePacketExpected = 0;
            g_decArgo_nbOf13Or11TypePacketExpected = 0;
            g_decArgo_nbOf14Or12TypePacketExpected = 0;
            
         case {202} % Arvor-deep 3500
            
            % decode the collected data
            [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_202(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
            g_decArgo_nbOf1Or8TypePacketExpected = 0;
            g_decArgo_nbOf2Or9TypePacketExpected = 0;
            g_decArgo_nbOf3Or10TypePacketExpected = 0;
            g_decArgo_nbOf13Or11TypePacketExpected = 0;
            g_decArgo_nbOf14Or12TypePacketExpected = 0;
            
         case {204} % Arvor Iridium 5.4
            
            % decode the collected data
            [tabTech, dataCTD, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_204(sbdDataData, sbdDataDate, 0);
            
            % type 5 packets are not concerned by this decoder
            g_decArgo_5TypePacketReceivedFlag = 1;
            
            g_decArgo_nbOf1Or8TypePacketExpected = 0;
            g_decArgo_nbOf2Or9TypePacketExpected = 0;
            g_decArgo_nbOf3Or10TypePacketExpected = 0;
            g_decArgo_nbOf13Or11TypePacketExpected = 0;
            g_decArgo_nbOf14Or12TypePacketExpected = 0;
            
         case {205} % Arvor Iridium 5.41 & 5.42
            
            % decode the collected data
            [tabTech, dataCTD, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_205(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
            % type 5 packets are not concerned by this decoder
            g_decArgo_5TypePacketReceivedFlag = 1;
            
            g_decArgo_nbOf1Or8TypePacketExpected = 0;
            g_decArgo_nbOf2Or9TypePacketExpected = 0;
            g_decArgo_nbOf3Or10TypePacketExpected = 0;
            g_decArgo_nbOf13Or11TypePacketExpected = 0;
            g_decArgo_nbOf14Or12TypePacketExpected = 0;
            
         case {206, 207, 208} % Provor-DO Iridium 5.71 & 5.7 & 5.72
            
            % decode the collected data
            [tabTech, dataCTDO, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_206_207_208(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
            % type 5 packets are not concerned by this decoder
            g_decArgo_5TypePacketReceivedFlag = 1;
            
            g_decArgo_nbOf1Or8TypePacketExpected = 0;
            g_decArgo_nbOf2Or9TypePacketExpected = 0;
            g_decArgo_nbOf3Or10TypePacketExpected = 0;
            g_decArgo_nbOf13Or11TypePacketExpected = 0;
            g_decArgo_nbOf14Or12TypePacketExpected = 0;
            
         case {209} % Arvor-2DO Iridium 5.73
            
            % decode the collected data
            [tabTech, dataCTDO, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_209(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
            % type 4 packets are not concerned by this decoder
            g_decArgo_4TypePacketReceivedFlag = 1;
            
            g_decArgo_nbOf1Or8TypePacketExpected = 0;
            g_decArgo_nbOf2Or9TypePacketExpected = 0;
            g_decArgo_nbOf3Or10TypePacketExpected = 0;
            g_decArgo_nbOf13Or11TypePacketExpected = 0;
            g_decArgo_nbOf14Or12TypePacketExpected = 0;
            
         case {210} % Arvor-ARN Iridium
            
            % decode the collected data
            [tabTech1, tabTech2, dataCTD, evAct, pumpAct, floatParam, deepCycle] = ...
               decode_prv_data_ir_sbd_210(sbdDataData, sbdDataDate, 0);
            
            g_decArgo_nbOf1Or8Or11Or14TypePacketExpected = 0;
            g_decArgo_nbOf2Or9Or12Or15TypePacketExpected = 0;
            g_decArgo_nbOf3Or10Or13Or16TypePacketExpected = 0;
            
         otherwise
            fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
               g_decArgo_floatNum, ...
               a_decoderId);
      end
      
      % check if the buffer contents can be processed
      [okToProcess] = is_buffer_completed_ir_sbd(0, a_decoderId);
      %       fprintf('Buffer completed : %d\n', okToProcess);
      
      if ((okToProcess == 1) || (idSpoolFile == length(tabAllFileDates)))
         
         % process the 'new' files
         if (VERBOSE_MODE_BUFF == 1)
            if ((okToProcess == 1) || (idSpoolFile < length(tabAllFileDates)))
               fprintf('BUFF_INFO: Float #%d: Processing %d SBD files: ', ...
                  g_decArgo_floatNum, ...
                  length(tabNewFileNames));
            else
               % the buffer contents is processed:
               % - in DM to process all received data from the float
               % - in RT to process all received data for the current rsync run
               % (if additionnal data will be received next rsync run, it will
               % be procecced together with the preceeding ones)
               fprintf('BUFF_INFO: Float #%d: Last step => processing buffer contents (all received data), %d SBD files ', ...
                  g_decArgo_floatNum, ...
                  length(tabNewFileNames));
            end
         end
         
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal] = ...
            decode_sbd_files( ...
            tabNewFileNames, tabNewFileDates, tabNewFileSizes, ...
            a_decoderId, a_launchDate, okToProcess);
         
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
         
         % move the processed 'new' files into the archive directory (and delete
         % the associated SBD files)
         move_files_ir_sbd(tabNewFileNames, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 1);
      end
      
   end
   
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files
   
   % fill Iridium profile locations with interpolated positions
   % (profile locations have been computed cycle by cycle, we will check if
   % some Iridium profile locations can not be replaced by interpolated locations
   % of the surface trajectory)
   [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(g_decArgo_gpsData, o_tabProfiles);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = update_output_cycle_number_ir_sbd( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);
   
   % clean FMT, LMT and GPS locations and set TET
   [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_sbd( ...
      o_tabTrajNMeas, o_tabTrajNCycle, a_decoderId);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_sbd(decArgoConfParamNames, ncConfParamNames);
   
   if (g_decArgo_realtimeFlag == 1)
      
      % in RT save the list of already processed rsync lo files in the temp
      % directory of the float
      idEq = find(g_decArgo_floatWmoUnderProcessList == a_floatNum);
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, ...
         g_decArgo_rsyncLogFileUnderProcessList{idEq});
   end
end

return;

% ------------------------------------------------------------------------------
% Decode one set of Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal] = ...
%    decode_sbd_files( ...
%    a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
%    a_decoderId, a_launchDate, a_completedBuffer)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList  : list of SBD file names
%   a_sbdFileDateList  : list of SBD file dates
%   a_sbdFileSizeList  : list of SBD file sizes
%   a_decoderId        : float decoder Id
%   a_launchDate       : launch date
%   a_completedBuffer  : completed buffer flag (1 if the buffer is complete)
%
% OUTPUT PARAMETERS :
%   o_tabProfiles        : decoded profiles
%   o_tabTrajNMeas       : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle      : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex     : decoded technical index information
%   o_tabNcTechVal       : decoded technical data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal] = ...
   decode_sbd_files( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
   a_decoderId, a_launchDate, a_completedBuffer)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];

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

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;

% SBD sub-directories
global g_decArgo_bufferDirectory;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;
g_decArgo_firstDeepCycleNumber = 1;

% flag used to add 1 to cycle numbers
global g_decArgo_firstDeepCycleDone;

% number of the previous decoded cycle
global g_decArgo_cycleNumPrev;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


% no data to process
if (isempty(a_sbdFileNameList))
   return;
end

% read the SBD file data
sbdDataDate = [];
sbdDataData = [];
for idFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idFile};
   sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   
   if (a_sbdFileSizeList(idFile) > 0)
      
      if (rem(a_sbdFileSizeList(idFile), 100) == 0)
         fId = fopen(sbdFilePathName, 'r');
         if (fId == -1)
            fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
               g_decArgo_floatNum, ...
               sbdFilePathName);
         end
         
         [sbdData, sbdDataCount] = fread(fId);
         
         fclose(fId);
         
         sbdData = reshape(sbdData, 100, size(sbdData, 1)/100)';
         for idMsg = 1:size(sbdData, 1)
            data = sbdData(idMsg, :);
            if (~isempty(find(data ~= 0, 1)))
               sbdDataData = [sbdDataData; data];
               sbdDataDate = [sbdDataDate; a_sbdFileDateList(idFile)];
            end
         end
      else
         fprintf('DEC_WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
            g_decArgo_floatNum, ...
            a_sbdFileSizeList(idFile), ...
            sbdFilePathName);
      end
      
   end
   
   % output CSV file
   if (~isempty(g_decArgo_outputCsvFileId))
      fprintf(g_decArgo_outputCsvFileId, '%d; -; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: %d\n', ...
         g_decArgo_floatNum, ...
         idFile, a_sbdFileNameList{idFile}, ...
         a_sbdFileSizeList(idFile), a_sbdFileSizeList(idFile)/100);
   end
end

% decode the data

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {201, 203} % Arvor-deep 4000
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_201_203(sbdDataData, sbdDataDate, 1, a_decoderId);
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((deepCycle == 1) || (g_decArgo_cycleNum == g_decArgo_firstDeepCycleNumber-1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_201_203(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_201_202_203(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_201_202_203(dataCTD(:, 62:76));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_201_203(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_201_202_203(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_201_202_203(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_for_C1C2Phase_doxy_201_202_203_206_to_209(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_202_203(dataCTD, dataCTDO);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy] = ...
         create_prv_profile_201_202_203(dataCTD, dataCTDO);
      
      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      if (~isempty(dataCTDO))
         [descProfDoxy] = compute_DOXY_201_203_206_209( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);
      end
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         eolStartDate, ...
         firstGroundingDate, firstGroundingPres, ...
         secondGroundingDate, secondGroundingPres, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_201_202_203(tabTech);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_201_203(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_201_202_203( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            eolStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            evAct, pumpAct);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_201_202_203_206_207_208( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_201_202_203_206_207_208( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_201_202_203_206_207_208( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_201_202_203(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_201_203(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(dataCTD) && isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_201_203( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_201_203( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            evAct, pumpAct, a_decoderId);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {202} % Arvor-deep 3500
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_202(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      if ((deepCycle == 0) && ...
            (g_decArgo_cycleNumPrev ~= -1) && ...
            (g_decArgo_cycleNumPrev ~= g_decArgo_cycleNum))
         % a new cycle number is a deep cycle even if the float didn't dive
         % (Ex: 6901031 #3)
         deepCycle = 1;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      if (deepCycle == 1)
         g_decArgo_firstDeepCycleDone = 1;
      end
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((deepCycle == 1) || (g_decArgo_cycleNum == g_decArgo_firstDeepCycleNumber-1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_202_210(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_201_202_203(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_201_202_203(dataCTD(:, 62:76));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_202_210(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_201_202_203(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_201_202_203(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_for_C1C2Phase_doxy_201_202_203_206_to_209(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_202_203(dataCTD, dataCTDO);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy] = ...
         create_prv_profile_201_202_203(dataCTD, dataCTDO);
      
      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      if (~isempty(dataCTDO))
         [descProfDoxy] = compute_DOXY_202_207( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_202_207( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_202_207( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);
      end
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         eolStartDate, ...
         firstGroundingDate, firstGroundingPres, ...
         secondGroundingDate, secondGroundingPres, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_201_202_203(tabTech);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_202(tabTech);
         
         % print dated data in CSV file
         print_dates_in_csv_file_201_202_203( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            eolStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            evAct, pumpAct);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_201_202_203_206_207_208( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_201_202_203_206_207_208( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_201_202_203_206_207_208( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_201_202_203(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_202(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(dataCTD) && isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_202( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_202( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            evAct, pumpAct, a_decoderId);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {204} % Arvor Iridium 5.4
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech, dataCTD, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_204(sbdDataData, sbdDataDate, 1);
      
      if (a_completedBuffer == 0)
         if (isempty(tabTech) && ~isempty(dataCTD))
            [cycleNumber] = estimate_cycle_number(dataCTD, g_decArgo_cycleNum, g_decArgo_julD2FloatDayOffset);
            g_decArgo_cycleNum = cycleNumber;
            fprintf('cyle #%d\n', g_decArgo_cycleNum);
         end
      end
      
      if ((deepCycle == 0) && ...
            (g_decArgo_cycleNumPrev ~= -1) && ...
            (g_decArgo_cycleNumPrev ~= g_decArgo_cycleNum))
         % a new cycle number is a deep cycle even if the float didn't dive
         deepCycle = 1;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      if (deepCycle == 1)
         g_decArgo_firstDeepCycleDone = 1;
      end
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if (deepCycle == 1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == g_decArgo_firstDeepCycleNumber-1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_204_to_209(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_210(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_204_to_209(dataCTD(:, 62:76));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal] = ...
         create_prv_profile_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         firstGroundingDate, firstGroundingPres, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres, refDay] = ...
         compute_prv_dates_204_to_209(tabTech, deepCycle, g_decArgo_julD2FloatDayOffset, lastMsgDateOfPrevCycle, a_launchDate, dataCTD);
      if (refDay ~= g_decArgo_julD2FloatDayOffset)
         
         g_decArgo_julD2FloatDayOffset = refDay;
         
         % create drift data set
         [parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal] = ...
            create_prv_drift_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
         
         % create descending and ascending profiles
         [descProfDate, descProfPres, descProfTemp, descProfSal, ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal] = ...
            create_prv_profile_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
      end
      
      % output CSV file
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_204(tabTech);
         
         % print dated data in CSV file
         print_dates_in_csv_file_204_to_209( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            firstGroundingDate, firstGroundingPres, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_204_205( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_204(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_204_205( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_204_205( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {205} % Arvor Iridium 5.41 & 5.42
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech, dataCTD, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_205(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      if (a_completedBuffer == 0)
         if (isempty(tabTech) && ~isempty(dataCTD))
            [cycleNumber] = estimate_cycle_number(dataCTD, g_decArgo_cycleNum, g_decArgo_julD2FloatDayOffset);
            g_decArgo_cycleNum = cycleNumber;
            fprintf('cyle #%d\n', g_decArgo_cycleNum);
         end
      end
      
      if ((deepCycle == 0) && ...
            (g_decArgo_cycleNumPrev ~= -1) && ...
            (g_decArgo_cycleNumPrev ~= g_decArgo_cycleNum))
         % a new cycle number is a deep cycle even if the float didn't dive
         deepCycle = 1;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      if (deepCycle == 1)
         g_decArgo_firstDeepCycleDone = 1;
      end
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if (deepCycle == 1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == g_decArgo_firstDeepCycleNumber-1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_204_to_209(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_210(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_204_to_209(dataCTD(:, 62:76));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal] = ...
         create_prv_profile_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         firstGroundingDate, firstGroundingPres, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres, refDay] = ...
         compute_prv_dates_204_to_209(tabTech, deepCycle, g_decArgo_julD2FloatDayOffset, lastMsgDateOfPrevCycle, a_launchDate, dataCTD);
      if (refDay ~= g_decArgo_julD2FloatDayOffset)
         
         g_decArgo_julD2FloatDayOffset = refDay;
         
         % create drift data set
         [parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal] = ...
            create_prv_drift_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
         
         % create descending and ascending profiles
         [descProfDate, descProfPres, descProfTemp, descProfSal, ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal] = ...
            create_prv_profile_204_205(dataCTD, g_decArgo_julD2FloatDayOffset);
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_205_to_209(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_204_to_209( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            firstGroundingDate, firstGroundingPres, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_204_205( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_205(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_204_205( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_204_205( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {206, 207, 208} % Provor-DO Iridium 5.71 & 5.7 & 5.72
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech, dataCTDO, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_206_207_208(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      if (a_completedBuffer == 0)
         if (isempty(tabTech) && ~isempty(dataCTDO))
            [cycleNumber] = estimate_cycle_number(dataCTDO, g_decArgo_cycleNum, g_decArgo_julD2FloatDayOffset);
            g_decArgo_cycleNum = cycleNumber;
            fprintf('cyle #%d\n', g_decArgo_cycleNum);
         end
      end
      
      if ((deepCycle == 0) && ...
            (g_decArgo_cycleNumPrev ~= -1) && ...
            (g_decArgo_cycleNumPrev ~= g_decArgo_cycleNum))
         % a new cycle number is a deep cycle even if the float didn't dive
         deepCycle = 1;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      if (deepCycle == 1)
         g_decArgo_firstDeepCycleDone = 1;
      end
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if (deepCycle == 1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == g_decArgo_firstDeepCycleNumber-1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_204_to_210(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_for_C1C2Phase_doxy_201_202_203_206_to_209(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_206_207_208(dataCTDO, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy] = ...
         create_prv_profile_206_207_208(dataCTDO, g_decArgo_julD2FloatDayOffset);
      
      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      if (~isempty(dataCTDO))
         switch (a_decoderId)
            case {206}
               % Provor-DO Iridium 5.71
               % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
               [descProfDoxy] = compute_DOXY_201_203_206_209( ...
                  descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
                  descProfPres, descProfTemp, descProfSal);
               [parkDoxy] = compute_DOXY_201_203_206_209( ...
                  parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
                  parkPres, parkTemp, parkSal);
               [ascProfDoxy] = compute_DOXY_201_203_206_209( ...
                  ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
                  ascProfPres, ascProfTemp, ascProfSal);
            case {207}
               % Provor-DO Iridium 5.7
               % C1/2PHASE_DOXY -> DOXY using first method: "the Aanderaa standard calibration"
               [descProfDoxy] = compute_DOXY_202_207( ...
                  descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
                  descProfPres, descProfTemp, descProfSal);
               [parkDoxy] = compute_DOXY_202_207( ...
                  parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
                  parkPres, parkTemp, parkSal);
               [ascProfDoxy] = compute_DOXY_202_207( ...
                  ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
                  ascProfPres, ascProfTemp, ascProfSal);
            case {208}
               % Provor-DO Iridium 5.72
               % C1/2PHASE_DOXY -> DOXY using second method: "the Aanderaa standard calibration + 2-point adjustment"
               [descProfDoxy] = compute_DOXY_208( ...
                  descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
                  descProfPres, descProfTemp, descProfSal);
               [parkDoxy] = compute_DOXY_208( ...
                  parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
                  parkPres, parkTemp, parkSal);
               [ascProfDoxy] = compute_DOXY_208( ...
                  ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
                  ascProfPres, ascProfTemp, ascProfSal);
            otherwise
               fprintf('ERROR: Nothing implemented yet to compute DOXY for decoderId #%d\n', ...
                  a_decoderId);
               return;
         end
      end
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         firstGroundingDate, firstGroundingPres, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres, refDay] = ...
         compute_prv_dates_204_to_209(tabTech, deepCycle, g_decArgo_julD2FloatDayOffset, lastMsgDateOfPrevCycle, a_launchDate, dataCTDO);
      if (refDay ~= g_decArgo_julD2FloatDayOffset)
         
         g_decArgo_julD2FloatDayOffset = refDay;
         
         % create drift data set
         [parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
            create_prv_drift_206_207_208(dataCTDO, g_decArgo_julD2FloatDayOffset);
         
         % create descending and ascending profiles
         [descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy] = ...
            create_prv_profile_206_207_208(dataCTDO, g_decArgo_julD2FloatDayOffset);
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_205_to_209(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_204_to_209( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            firstGroundingDate, firstGroundingPres, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_201_202_203_206_207_208( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_201_202_203_206_207_208( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_201_202_203_206_207_208( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_206_to_209(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_206_207_208( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_206_207_208( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, a_decoderId);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {209} % Arvor-2DO Iridium 5.73
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech, dataCTDO, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_209(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      if (a_completedBuffer == 0)
         if (isempty(tabTech) && ~isempty(dataCTDO))
            [cycleNumber] = estimate_cycle_number_209(dataCTDO, g_decArgo_cycleNum, g_decArgo_julD2FloatDayOffset);
            g_decArgo_cycleNum = cycleNumber;
            fprintf('cyle #%d\n', g_decArgo_cycleNum);
         end
      end
      
      if ((deepCycle == 0) && ...
            (g_decArgo_cycleNumPrev ~= -1) && ...
            (g_decArgo_cycleNumPrev ~= g_decArgo_cycleNum))
         % a new cycle number is a deep cycle even if the float didn't dive
         deepCycle = 1;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      if (deepCycle == 1)
         g_decArgo_firstDeepCycleDone = 1;
      end
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if (deepCycle == 1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == g_decArgo_firstDeepCycleNumber-1)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTDO))
         
         optodeType = unique(dataCTDO(:, end));
         switch (optodeType)
            case 2
               % CTD only
               [dataCTDO(:, 32:46)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 32:46));
               [dataCTDO(:, 47:61)] = sensor_2_value_for_temperature_204_to_210(dataCTDO(:, 47:61));
               [dataCTDO(:, 62:76)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 62:76));
            case 1
               % CTD + Aanderaa 4330
               [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 16:22));
               [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_204_to_210(dataCTDO(:, 23:29));
               [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 30:36));
               [dataCTDO(:, 37:50)] = sensor_2_value_for_C1C2Phase_doxy_201_202_203_206_to_209(dataCTDO(:, 37:50));
               [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 51:57));
            case 4
               % CTD + SBE 63
               [dataCTDO(:, 20:28)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 20:28));
               [dataCTDO(:, 29:37)] = sensor_2_value_for_temperature_204_to_210(dataCTDO(:, 29:37));
               [dataCTDO(:, 38:46)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 38:46));
               [dataCTDO(:, 47:55)] = sensor_2_value_for_phase_delay_doxy_209(dataCTDO(:, 47:55));
               [dataCTDO(:, 56:64)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 56:64));
            case 5
               % CTD + Aanderaa 4330 + SBE 63
               [dataCTDO(:, 12:16)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 12:16));
               [dataCTDO(:, 17:21)] = sensor_2_value_for_temperature_204_to_210(dataCTDO(:, 17:21));
               [dataCTDO(:, 22:26)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 22:26));
               [dataCTDO(:, 27:36)] = sensor_2_value_for_C1C2Phase_doxy_201_202_203_206_to_209(dataCTDO(:, 27:36));
               [dataCTDO(:, 37:41)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 37:41));
               [dataCTDO(:, 42:46)] = sensor_2_value_for_phase_delay_doxy_209(dataCTDO(:, 42:46));
               [dataCTDO(:, 47:51)] = sensor_2_value_for_temp_doxy_201_202_203_206_to_209(dataCTDO(:, 47:51));
            otherwise
               fprintf('WARNING: Nothing done yet for optode type #%d\n', ...
                  optodeType);
         end
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxyAa, ...
         parkPhaseDelayDoxy, parkTempDoxySbe] = ...
         create_prv_drift_209(dataCTDO, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxyAa, ...
         descProfPhaseDelayDoxy, descProfTempDoxySbe, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxyAa, ...
         ascProfPhaseDelayDoxy, ascProfTempDoxySbe] = ...
         create_prv_profile_209(dataCTDO, g_decArgo_julD2FloatDayOffset);
      
      % compute DOXY
      descProfDoxyAa = [];
      parkDoxyAa = [];
      ascProfDoxyAa = [];
      descProfDoxySbe = [];
      parkDoxySbe = [];
      ascProfDoxySbe = [];
      if (~isempty(dataCTDO))
         % Aanderaa
         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         if (~isempty(descProfC1PhaseDoxy))
            [descProfDoxyAa] = compute_DOXY_201_203_206_209( ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxyAa, ...
               descProfPres, descProfTemp, descProfSal);
         end
         if (~isempty(parkC1PhaseDoxy))
            [parkDoxyAa] = compute_DOXY_201_203_206_209( ...
               parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxyAa, ...
               parkPres, parkTemp, parkSal);
         end
         if (~isempty(ascProfC1PhaseDoxy))
            [ascProfDoxyAa] = compute_DOXY_201_203_206_209( ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxyAa, ...
               ascProfPres, ascProfTemp, ascProfSal);
         end
         % SBE
         if (~isempty(descProfPhaseDelayDoxy))
            [descProfDoxySbe] = compute_DOXY_SBE_209_2002( ...
               descProfPhaseDelayDoxy, descProfTempDoxySbe, ...
               descProfPres, descProfTemp, descProfSal);
         end
         if (~isempty(parkPhaseDelayDoxy))
            [parkDoxySbe] = compute_DOXY_SBE_209_2002( ...
               parkPhaseDelayDoxy, parkTempDoxySbe, ...
               parkPres, parkTemp, parkSal);
         end
         if (~isempty(ascProfPhaseDelayDoxy))
            [ascProfDoxySbe] = compute_DOXY_SBE_209_2002( ...
               ascProfPhaseDelayDoxy, ascProfTempDoxySbe, ...
               ascProfPres, ascProfTemp, ascProfSal);
         end
      end
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         firstGroundingDate, firstGroundingPres, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres, refDay] = ...
         compute_prv_dates_204_to_209(tabTech, deepCycle, g_decArgo_julD2FloatDayOffset, lastMsgDateOfPrevCycle, a_launchDate, dataCTDO);
      if (refDay ~= g_decArgo_julD2FloatDayOffset)
         
         g_decArgo_julD2FloatDayOffset = refDay;
         
         % create drift data set
         [parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxyAa, ...
            parkPhaseDelayDoxy, parkTempDoxySbe] = ...
            create_prv_drift_209(dataCTDO, g_decArgo_julD2FloatDayOffset);
         
         % create descending and ascending profiles
         [descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxyAa, ...
            descProfPhaseDelayDoxy, descProfTempDoxySbe, ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxyAa, ...
            ascProfPhaseDelayDoxy, ascProfTempDoxySbe] = ...
            create_prv_profile_209(dataCTDO, g_decArgo_julD2FloatDayOffset);
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_205_to_209(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_204_to_209( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            firstGroundingDate, firstGroundingPres, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_209( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxyAa, descProfDoxyAa, ...
            descProfPhaseDelayDoxy, descProfTempDoxySbe, descProfDoxySbe);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_209( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxyAa, parkDoxyAa, ...
            parkPhaseDelayDoxy, parkTempDoxySbe, parkDoxySbe);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_209( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxyAa, ascProfDoxyAa, ...
            ascProfPhaseDelayDoxy, ascProfTempDoxySbe, ascProfDoxySbe);
         
         % print surface data in CSV file
         %          print_surface_data_in_csv_file_209( ...
         %             ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         %             ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxyAa, surfDoxyAa, ...
         %             ascProfPhaseDelayDoxy, ascProfTempDoxySbe, surfDoxySbe);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_206_to_209(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_209( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxyAa, descProfDoxyAa, ...
               descProfPhaseDelayDoxy, descProfTempDoxySbe, descProfDoxySbe, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxyAa, ascProfDoxyAa, ...
               ascProfPhaseDelayDoxy, ascProfTempDoxySbe, ascProfDoxySbe, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_209( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxyAa, parkDoxyAa, ...
            parkPhaseDelayDoxy, parkTempDoxySbe, parkDoxySbe, ...
            a_decoderId);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {210} % Arvor-ARN Iridium
      
      if (a_completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      % decode the collected data
      [tabTech1, tabTech2, dataCTD, evAct, pumpAct, floatParam, irSessionNum] = ...
         decode_prv_data_ir_sbd_210(sbdDataData, sbdDataDate, 1);
                  
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((g_decArgo_cycleNum > 0) && (irSessionNum == 1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if ((g_decArgo_cycleNum == 0) && (irSessionNum == 1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
            
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_202_210(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_210(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_210(dataCTD(:, 62:76));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_210(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
         create_prv_profile_210(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % compute the main dates of the cycle
      [cycleStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, ...
         descentToProfEndDate, ...
         ascentStartDate, ...
         ascentEndDate, ...
         transStartDate, ...
         gpsDate, ...
         lastResetDate, ...
         firstGroundingDate, firstGroundingPres, ...
         secondGroundingDate, secondGroundingPres, ...
         eolStartDate, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres, ...
         deepCycle] = ...
         compute_prv_dates_210(tabTech1, tabTech2, irSessionNum);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_210(tabTech1, tabTech2, deepCycle);
         
         % print dated data in CSV file
         print_dates_in_csv_file_210( ...
            cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            eolStartDate, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            descProfDate, descProfPres, ...
            parkDate, parkPres, ...
            ascProfDate, ascProfPres, ...
            nearSurfDate, nearSurfPres, ...
            inAirDate, inAirPres, ...
            evAct, pumpAct);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_204_205( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_210(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_210(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_210( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDate, ascentEndDate, transStartDate, tabTech2, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
            
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
            
            o_tabProfiles = [o_tabProfiles tabProfiles];
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_210( ...
            g_decArgo_cycleNum, deepCycle, irSessionNum, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            cycleStartDate, ...
            descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            tabTech1, tabTech2, ...
            tabProfiles, ...
            parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            evAct, pumpAct, a_decoderId);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % store NetCDF technical data
         if (irSessionNum == 1)
            
            % store NetCDF technical data
            store_tech1_data_for_nc_210(tabTech1, deepCycle);
            store_tech2_data_for_nc_210(tabTech2, deepCycle);
            
            % update NetCDF technical data
            update_technical_data_argos_sbd(a_decoderId);
            
            % TEMPORARY CODE
            idDel = find(ismember(g_decArgo_outputNcParamIndex(:, 5), ...
               [133, 134, 203, 204, 210, 211, 229, 230, 237, 238, 239]));
            g_decArgo_outputNcParamIndex(idDel, :) = [];
            g_decArgo_outputNcParamValue(idDel) = [];
            
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
         end
         
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
