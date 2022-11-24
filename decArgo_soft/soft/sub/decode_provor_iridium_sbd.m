% ------------------------------------------------------------------------------
% Decode PROVOR Iridium float with Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
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
%   o_tabTechNMeas   : decoded technical N_MEASUREMENT data
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
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas, ...
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
o_tabTechNMeas = [];
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

% last float reset date
global g_decArgo_floatLastResetDate;
g_decArgo_floatLastResetDate = -1;

% offset in cycle number (in case of reset of the float)
global g_decArgo_cycleNumOffset;
g_decArgo_cycleNumOffset = 0;

% shift to apply to transmitted cycle number (see 6901248)
global g_decArgo_cycleNumShift;
g_decArgo_cycleNumShift = 0;

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% verbose mode flag
VERBOSE_MODE_BUFF = 1;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDuration/24;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;
g_decArgo_7TypePacketReceivedCyNum = [];


% create the float directory
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' num2str(a_floatImei) '_' num2str(a_floatNum) '/'];
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end

% create sub-directories:
% - a 'archive' directory used to store the received mail files
% WHEN USING VIRTUAL BUFFERS:
% - a 'archive/sbd' directory used to store the received SBD files
% WHEN USING DIRECTORY BUFFERS:
% - a 'spool' directory used to select the SBD files that will be processed
% during the current session of the decoder
% - a 'buffer' directory used to gather the SBD files expected for a given cycle
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
if (g_decArgo_virtualBuff)
   g_decArgo_archiveSbdDirectory = [floatIriDirName 'archive/sbd/'];
   if (exist(g_decArgo_archiveSbdDirectory, 'dir') == 7)
      rmdir(g_decArgo_archiveSbdDirectory, 's');
   end
   mkdir(g_decArgo_archiveSbdDirectory);
else
   g_decArgo_spoolDirectory = [floatIriDirName 'spool/'];
   if ~(exist(g_decArgo_spoolDirectory, 'dir') == 7)
      mkdir(g_decArgo_spoolDirectory);
   end
   g_decArgo_bufferDirectory = [floatIriDirName 'buffer/'];
   if ~(exist(g_decArgo_bufferDirectory, 'dir') == 7)
      mkdir(g_decArgo_bufferDirectory);
   end
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

% initialize float parameter configuration
init_float_config_ir_sbd(a_launchDate, a_decoderId);

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
      
      if (g_decArgo_virtualBuff)
         add_to_list(mailFileName, 'spool');
      else
         move_files_ir_sbd({mailFileName}, g_decArgo_archiveDirectory, g_decArgo_spoolDirectory, 0, 0);
      end
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
   
   % some mail files can be present in the buffer (if the final buffer was not
   % completed during the previous run of the RT decoder)
   % move the mail files from buffer to the archive directory (and delete the
   % associated SBD files)
   if (~g_decArgo_virtualBuff)
      fileList = dir([g_decArgo_bufferDirectory '*.txt']);
      if (~isempty(fileList))
         fprintf('BUFF_INFO: Moving %d Iridium mail files from float buffer dir to float archive dir (and deleting associated SBD files)\n', ...
            length(fileList));
         for idF = 1:length(fileList)
            fileName = fileList(idF).name;
            move_files_ir_sbd({fileName}, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 0, 1);
         end
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
         
         if (g_decArgo_virtualBuff)
            add_to_list(mailFileName, 'spool');
         else
            move_files_ir_sbd({mailFileName}, g_decArgo_archiveDirectory, g_decArgo_spoolDirectory, 0, 0);
         end
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

if (g_decArgo_realtimeFlag)
   
   % process mail files according to stored buffers

   % read the buffer list file
   [mailFileNameList, mailFileRank, ~, ~, ~] = ...
      read_buffer_list(a_floatNum, g_decArgo_historyDirectory, '', 0);
   
   uRank = sort(unique(mailFileRank));
   for idRk = 1:length(uRank)
      rankNum = uRank(idRk);
      idFileList = find(mailFileRank == rankNum);
      
      fprintf('BUFFER #%d: processing %d sbd files\n', rankNum, length(idFileList));
      
      for idF = 1:length(idFileList)
         
         % move the next file into the buffer directory
         if (g_decArgo_virtualBuff)
            add_to_list(mailFileNameList{idFileList(idF)}, 'buffer');
            remove_from_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'spool', 0);
         else
            move_files_ir_sbd(mailFileNameList(idFileList(idF)), ...
               g_decArgo_spoolDirectory, g_decArgo_bufferDirectory, 0, 0);
         end
         
         % extract the attachement
         if (g_decArgo_virtualBuff)
            [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
               mailFileNameList{idFileList(idF)}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
         else
            [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
               mailFileNameList{idFileList(idF)}, g_decArgo_bufferDirectory, g_decArgo_bufferDirectory);
         end
         g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
         if (attachmentFound == 0)
            if (g_decArgo_virtualBuff)
               remove_from_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'buffer', 1);
            else
               move_files_ir_sbd(mailFileNameList(idFileList(idF)), g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 0);
            end
         end
      end
      
      % process the files of the buffer directory
      
      % retrieve information on the files in the buffer
      if (g_decArgo_virtualBuff)
         [tabFileNames, ~, tabFileDates, tabFileSizes] = ...
            get_list_files_info_ir_sbd('buffer', '');
      else
         [tabFileNames, ~, tabFileDates, tabFileSizes] = ...
            get_dir_files_info_ir_sbd(g_decArgo_bufferDirectory, a_floatImei, 'sbd', '');
      end
      
      % process the buffer files
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
         decode_sbd_files( ...
         tabFileNames, tabFileDates, tabFileSizes, ...
         a_decoderId, a_launchDate, [], a_refDay);
      
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
      
      % move the processed files into the archive directory (and delete
      % the associated SBD files)
      if (g_decArgo_virtualBuff)
         remove_from_list_ir_sbd(tabFileNames, 'buffer', 1);
      else
         move_files_ir_sbd(tabFileNames, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 1);
      end
   end
end

% retrieve information on spool directory contents
if (g_decArgo_virtualBuff)
   [tabAllFileNames, ~, tabAllFileDates, ~] = ...
      get_list_files_info_ir_sbd('spool', '');
else
   [tabAllFileNames, ~, tabAllFileDates, ~] = ...
      get_dir_files_info_ir_sbd(g_decArgo_spoolDirectory, a_floatImei, 'txt', '');
end

% process the mail files of the spool directory in chronological order
if (g_decArgo_realtimeFlag)
   bufferRank = 1;
   if (~isempty(mailFileRank))
      bufferRank = max(mailFileRank) + 1;
   end
   bufferMailFileNames = [];
   bufferMailFileDates = [];
end
for idSpoolFile = 1:length(tabAllFileNames)
   
   if (g_decArgo_realtimeFlag)
      bufferMailFileNames{end+1} = tabAllFileNames{idSpoolFile};
      bufferMailFileDates(end+1) = tabAllFileDates(idSpoolFile);
   end
   
   % move the next file into the buffer directory
   if (g_decArgo_virtualBuff)
      add_to_list(tabAllFileNames{idSpoolFile}, 'buffer');
      remove_from_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'spool', 0);
   else
      move_files_ir_sbd(tabAllFileNames(idSpoolFile), g_decArgo_spoolDirectory, g_decArgo_bufferDirectory, 0, 0);
   end
   
   % extract the attachement
   if (g_decArgo_virtualBuff)
      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         tabAllFileNames{idSpoolFile}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   else
      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         tabAllFileNames{idSpoolFile}, g_decArgo_bufferDirectory, g_decArgo_bufferDirectory);
   end
   g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
   if (attachmentFound == 0)
      if (g_decArgo_virtualBuff)
         remove_from_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'buffer', 1);
      else
         move_files_ir_sbd(tabAllFileNames(idSpoolFile), g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 0);
      end
      if (idSpoolFile < length(tabAllFileNames))
         continue;
      end
   end
      
   % process the files of the buffer directory
   
   % retrieve information on the files in the buffer
   if (g_decArgo_virtualBuff)
      [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
         'buffer', '');
   else
      [tabFileNames, ~, tabFileDates, tabFileSizes] = get_dir_files_info_ir_sbd( ...
         g_decArgo_bufferDirectory, a_floatImei, 'sbd', '');
   end
   
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
      if (g_decArgo_realtimeFlag)
         idOld2 = find((bufferMailFileDates < tabFileDates(1)+MIN_SUB_CYCLE_DURATION_IN_DAYS));
         if (~isempty(idOld2))
            write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, bufferMailFileNames(idOld2), bufferRank);
            bufferRank = bufferRank + 1;
            bufferMailFileNames(idOld2) = [];
            bufferMailFileDates(idOld2) = [];
         end
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
         tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
         decode_sbd_files( ...
         tabOldFileNames, tabOldFileDates, tabOldFileSizes, ...
         a_decoderId, a_launchDate, 0, a_refDay);
      
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
      
      % move the processed 'old' files into the archive directory (and delete the
      % associated SBD files)
      if (g_decArgo_virtualBuff)
         remove_from_list_ir_sbd(tabOldFileNames, 'buffer', 1);
      else
         move_files_ir_sbd(tabOldFileNames, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 1);
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % check if the 'new' files can be processed
   
   % store the SBD data
   sbdDataDate = [];
   sbdDataData = [];
   for idBufFile = 1:length(tabNewFileNames)
      
      sbdFileName = tabNewFileNames{idBufFile};
      %       fprintf('SBD file : %s\n', sbdFileName);
      if (g_decArgo_virtualBuff)
         sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
      else
         sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
      end
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
            decode_prv_data_ir_sbd_201_203(sbdDataData, sbdDataDate, 0, a_decoderId);
            
         case {202} % Arvor-deep 3500
            
            % decode the collected data
            decode_prv_data_ir_sbd_202(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
         case {204} % Arvor Iridium 5.4
            
            % decode the collected data
            decode_prv_data_ir_sbd_204(sbdDataData, sbdDataDate, 0);
            
         case {205} % Arvor Iridium 5.41 & 5.42

            % decode the collected data
            decode_prv_data_ir_sbd_205(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
                        
         case {206, 207, 208} % Provor-DO Iridium 5.71 & 5.7 & 5.72
            
            % decode the collected data
            decode_prv_data_ir_sbd_206_207_208(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
         case {209} % Arvor-2DO Iridium 5.73
            
            % decode the collected data
            decode_prv_data_ir_sbd_209(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
            
         case {210, 211} % Arvor-ARN Iridium
            
            % decode the collected data
            decode_prv_data_ir_sbd_210_211(sbdDataData, sbdDataDate, 0, a_decoderId);
            
         case {212} % Arvor-ARN-Ice Iridium
            
            % decode the collected data
            decode_prv_data_ir_sbd_212(sbdDataData, sbdDataDate, 0);
            
         case {213} % Provor-ARN-DO Iridium 5.74
            
            % decode the collected data
            decode_prv_data_ir_sbd_213(sbdDataData, sbdDataDate, 0);
            
         case {214} % % Provor-ARN-DO-Ice Iridium 5.75
            
            % decode the collected data
            decode_prv_data_ir_sbd_214(sbdDataData, sbdDataDate, 0);
            
         case {215} % Arvor-deep 4000 with "Near Surface" & "In Air" measurements
   
            % decode the collected data
            decode_prv_data_ir_sbd_215(sbdDataData, sbdDataDate, 0);            

         otherwise
            fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
               g_decArgo_floatNum, ...
               a_decoderId);
      end
      
      % check if the buffer contents can be processed
      [okToProcess] = is_buffer_completed_ir_sbd(0, a_decoderId);
      %       fprintf('Buffer completed : %d\n', okToProcess);
      
      if ((okToProcess) || ...
            ((idSpoolFile == length(tabAllFileDates) && (~g_decArgo_realtimeFlag))))
               
         if (g_decArgo_realtimeFlag)
            if (okToProcess)
               write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, bufferMailFileNames, bufferRank);
               bufferRank = bufferRank + 1;
               bufferMailFileNames = [];
               bufferMailFileDates = [];
            end
         end
         
         % process the 'new' files
         if (VERBOSE_MODE_BUFF)
            if ((okToProcess) || (idSpoolFile < length(tabAllFileDates)))
               fprintf('BUFF_INFO: Float #%d: Processing %d SBD files: ', ...
                  g_decArgo_floatNum, ...
                  length(tabNewFileNames));
            else
               % the buffer contents is processed:
               % - in DM to process all received data from the float
               % - in RT to process all received data for the current rsync run
               % (if additionnal data will be received next rsync run, it will
               % be procecced together with the preceeding ones)
               fprintf('BUFF_INFO: Float #%d: Last step => processing buffer contents (all received data), %d SBD files\n', ...
                  g_decArgo_floatNum, ...
                  length(tabNewFileNames));
            end
         end
         
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechNMeas] = ...
            decode_sbd_files( ...
            tabNewFileNames, tabNewFileDates, tabNewFileSizes, ...
            a_decoderId, a_launchDate, okToProcess, a_refDay);
         
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
         
         % move the processed 'new' files into the archive directory (and delete
         % the associated SBD files)
         if (g_decArgo_virtualBuff)
            remove_from_list_ir_sbd(tabNewFileNames, 'buffer', 1);
         else
            move_files_ir_sbd(tabNewFileNames, g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 1);
         end
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
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
      update_output_cycle_number_ir_sbd( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas);
   
   % clean FMT, LMT and GPS locations and set TET
   [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_sbd( ...
      o_tabTrajNMeas, o_tabTrajNCycle, a_decoderId);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_sbd( ...
      decArgoConfParamNames, ncConfParamNames, a_decoderId);
   
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

if (g_decArgo_virtualBuff)
   rmdir(g_decArgo_archiveSbdDirectory, 's');
end

return;

% ------------------------------------------------------------------------------
% Decode one set of Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%    decode_sbd_files( ...
%    a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
%    a_decoderId, a_launchDate, a_completedBuffer, a_refDay)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList  : list of SBD file names
%   a_sbdFileDateList  : list of SBD file dates
%   a_sbdFileSizeList  : list of SBD file sizes
%   a_decoderId        : float decoder Id
%   a_launchDate       : launch date
%   a_completedBuffer  : completed buffer flag (1 if the buffer is complete)
%   a_refDay           : reference day
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : decoded profiles
%   o_tabTrajNMeas   : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : decoded technical index information
%   o_tabNcTechVal   : decoded technical data
%   o_tabTechNMeas   : decoded technical PARAM data
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
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   decode_sbd_files( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
   a_decoderId, a_launchDate, a_completedBuffer, a_refDay)

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
global g_decArgo_archiveSbdDirectory;

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

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;


% no data to process
if (isempty(a_sbdFileNameList))
   return;
end

% read the SBD file data
sbdDataDate = [];
sbdDataData = [];
for idFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idFile};
   if (g_decArgo_virtualBuff)
      sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   
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
      
      % decode the collected data
      [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_201_203(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone, a_decoderId);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end         
         
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_201_203_215(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_201_to_203_215(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_201_to_203_215(dataCTD(:, 62:76));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_201_203_215(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_201_to_203_215(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_201_to_203_215(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_to_203_215(dataCTD, dataCTDO);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy] = ...
         create_prv_profile_201_to_203(dataCTD, dataCTDO);
      
      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      if (~isempty(dataCTDO))
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
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
         compute_prv_dates_201_to_203_215(tabTech, a_refDay);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_201_203_215(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_201_to_203( ...
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
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_201_to_203_215(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_201_203(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(dataCTD) && isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_201_203_215( ...
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_201_203( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
                  
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {202} % Arvor-deep 3500
      
      % decode the collected data
      [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_202(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end         
         
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_202_210_to_214(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_201_to_203_215(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_201_to_203_215(dataCTD(:, 62:76));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_202_210_to_214(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_201_to_203_215(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_201_to_203_215(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_to_203_215(dataCTD, dataCTDO);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy] = ...
         create_prv_profile_201_to_203(dataCTD, dataCTDO);
      
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
         compute_prv_dates_201_to_203_215(tabTech, a_refDay);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_202(tabTech);
         
         % print dated data in CSV file
         print_dates_in_csv_file_201_to_203( ...
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
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_201_to_203_215(evAct, pumpAct);
         
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_202( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];

         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {204} % Arvor Iridium 5.4
      
      % decode the collected data
      [tabTech, dataCTD, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_204(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end         
         
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      if (completedBuffer == 0)
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_204_to_209(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_214(dataCTD(:, 47:61));
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
         print_descending_profile_in_csv_file_204_205_210_to_212( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205_210_to_212( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205_210_to_212( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {205} % Arvor Iridium 5.41 & 5.42

      % decode the collected data
      [tabTech, dataCTD, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_205(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end         
         
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      if (completedBuffer == 0)
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_204_to_209(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_214(dataCTD(:, 47:61));
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
         print_descending_profile_in_csv_file_204_205_210_to_212( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205_210_to_212( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205_210_to_212( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {206, 207, 208} % Provor-DO Iridium 5.71 & 5.7 & 5.72
      
      % decode the collected data
      [tabTech, dataCTDO, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_206_207_208(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end         
         
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      if (completedBuffer == 0)
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % retrieve the last message time of the previous cycle
      [~, lastMsgDateOfPrevCycle] = ...
         compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum-1);
      
      % convert counts to physical values
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_206_to_208_213_214(dataCTDO, g_decArgo_julD2FloatDayOffset, a_decoderId);
      
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
               [descProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
                  descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
                  descProfPres, descProfTemp, descProfSal);
               [parkDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
                  parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
                  parkPres, parkTemp, parkSal);
               [ascProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
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
            create_prv_drift_206_to_208_213_214(dataCTDO, g_decArgo_julD2FloatDayOffset, a_decoderId);
         
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
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
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
            
            [tabProfiles] = process_profiles_206_to_208_213_214( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {209} % Arvor-2DO Iridium 5.73
      
      % decode the collected data
      [tabTech, dataCTDO, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_209(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end
      
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
      
      if (completedBuffer == 0)
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
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
               [dataCTDO(:, 47:61)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 47:61));
               [dataCTDO(:, 62:76)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 62:76));
            case 1
               % CTD + Aanderaa 4330
               [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 16:22));
               [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 23:29));
               [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 30:36));
               [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
               [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
            case 4
               % CTD + SBE 63
               [dataCTDO(:, 20:28)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 20:28));
               [dataCTDO(:, 29:37)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 29:37));
               [dataCTDO(:, 38:46)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 38:46));
               [dataCTDO(:, 47:55)] = sensor_2_value_for_phase_delay_doxy_209(dataCTDO(:, 47:55));
               [dataCTDO(:, 56:64)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 56:64));
            case 5
               % CTD + Aanderaa 4330 + SBE 63
               [dataCTDO(:, 12:16)] = sensor_2_value_for_pressure_204_to_209(dataCTDO(:, 12:16));
               [dataCTDO(:, 17:21)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 17:21));
               [dataCTDO(:, 22:26)] = sensor_2_value_for_salinity_204_to_209(dataCTDO(:, 22:26));
               [dataCTDO(:, 27:36)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 27:36));
               [dataCTDO(:, 37:41)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:41));
               [dataCTDO(:, 42:46)] = sensor_2_value_for_phase_delay_doxy_209(dataCTDO(:, 42:46));
               [dataCTDO(:, 47:51)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 47:51));
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
            [descProfDoxyAa] = compute_DOXY_201_203_206_209_213_214_215( ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxyAa, ...
               descProfPres, descProfTemp, descProfSal);
         end
         if (~isempty(parkC1PhaseDoxy))
            [parkDoxyAa] = compute_DOXY_201_203_206_209_213_214_215( ...
               parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxyAa, ...
               parkPres, parkTemp, parkSal);
         end
         if (~isempty(ascProfC1PhaseDoxy))
            [ascProfDoxyAa] = compute_DOXY_201_203_206_209_213_214_215( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {210, 211} % Arvor-ARN Iridium
      
      % decode the collected data
      [tabTech1, tabTech2, dataCTD, evAct, pumpAct, floatParam, irSessionNum, deepCycle] = ...
         decode_prv_data_ir_sbd_210_211(sbdDataData, sbdDataDate, 1, a_decoderId);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end
      
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
                        
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((g_decArgo_cycleNum > 0) && (deepCycle == 1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end

      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
            
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_202_210_to_214(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_214(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_210_to_214(dataCTD(:, 62:76));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_210_to_212(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
         create_prv_profile_210_to_212(dataCTD, g_decArgo_julD2FloatDayOffset);
      
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
         firstEmergencyAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_210_to_214(tabTech1, tabTech2, deepCycle, a_refDay);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_210_211(tabTech1, tabTech2, deepCycle);
         
         % print dated data in CSV file
         print_dates_in_csv_file_210_to_214( ...
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
         print_descending_profile_in_csv_file_204_205_210_to_212( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205_210_to_212( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205_210_to_212( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210_to_212( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_210_to_214(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_210_211(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_210_to_212( ...
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_210_to_212( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % store NetCDF technical data
         store_tech1_data_for_nc_210_to_214(tabTech1, deepCycle);
         store_tech2_data_for_nc_210_211_213(tabTech2, deepCycle);
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         % TEMPORARY CODE
         %             idDel = find(ismember(g_decArgo_outputNcParamIndex(:, 5), ...
         %                [133, 134, 203, 204, 210, 211, 229, 230, 237, 238, 239]));
         %             g_decArgo_outputNcParamIndex(idDel, :) = [];
         %             g_decArgo_outputNcParamValue(idDel) = [];
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {212} % Arvor-ARN-Ice Iridium
      
      % decode the collected data
      [tabTech1, tabTech2, dataCTD, evAct, pumpAct, floatParam1, floatParam2, ...
         irSessionNum, deepCycle] = ...
         decode_prv_data_ir_sbd_212(sbdDataData, sbdDataDate, 1);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end
      
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
                        
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((g_decArgo_cycleNum > 0) && (deepCycle == 1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd([{floatParam1} {floatParam2}], a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
            
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_202_210_to_214(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_204_to_214(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_210_to_214(dataCTD(:, 62:76));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_prv_drift_210_to_212(dataCTD, g_decArgo_julD2FloatDayOffset);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
         create_prv_profile_210_to_212(dataCTD, g_decArgo_julD2FloatDayOffset);
      
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
         firstEmergencyAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_210_to_214(tabTech1, tabTech2, deepCycle, a_refDay);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_212(tabTech1, tabTech2, deepCycle);
         
         % print dated data in CSV file
         print_dates_in_csv_file_210_to_214( ...
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
         print_descending_profile_in_csv_file_204_205_210_to_212( ...
            descProfDate, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_204_205_210_to_212( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_204_205_210_to_212( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_210_to_212( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_210_to_214(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_212_214(floatParam1, floatParam2);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_210_to_212( ...
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_210_to_212( ...
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
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % store NetCDF technical data
         store_tech1_data_for_nc_210_to_214(tabTech1, deepCycle);
         store_tech2_data_for_nc_212_214(tabTech2, deepCycle);
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         % TEMPORARY CODE
         %             idDel = find(ismember(g_decArgo_outputNcParamIndex(:, 5), ...
         %                [133, 134, 203, 204, 210, 211, 229, 230, 237, 238, 239]));
         %             g_decArgo_outputNcParamIndex(idDel, :) = [];
         %             g_decArgo_outputNcParamValue(idDel) = [];
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {213} % Provor-ARN-DO Iridium 5.74
      
      % decode the collected data
      [tabTech1, tabTech2, dataCTDO, evAct, pumpAct, floatParam, irSessionNum, deepCycle] = ...
         decode_prv_data_ir_sbd_213(sbdDataData, sbdDataDate, 1);

      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end
      
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
                        
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((g_decArgo_cycleNum > 0) && (deepCycle == 1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatParam))
         update_float_config_ir_sbd(floatParam, a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);      
      
      % convert counts to physical values
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_202_210_to_214(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_210_to_214(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_206_to_208_213_214(dataCTDO, g_decArgo_julD2FloatDayOffset, a_decoderId);
      
      % create descending and ascending profiles      
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_213_214(dataCTDO, g_decArgo_julD2FloatDayOffset);
      
      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfDoxy = [];
      inAirDoxy = [];
      if (~isempty(dataCTDO))
         
         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);
         [nearSurfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            nearSurfPres, nearSurfTemp, nearSurfSal);
         
         % if the optode is not mounted on an additional stick, we compute DOXY
         % for IN AIR mesurements
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         optodeInAirMeasFlag = get_config_value('CONFIG_PX04_', configNames, configValues);
         if (isempty(optodeInAirMeasFlag) || (optodeInAirMeasFlag == 0))
            [inAirDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
               inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
               inAirPres, inAirTemp, inAirSal);
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
         lastResetDate, ...
         firstGroundingDate, firstGroundingPres, ...
         secondGroundingDate, secondGroundingPres, ...
         eolStartDate, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_210_to_214(tabTech1, tabTech2, deepCycle, a_refDay);

      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_213(tabTech1, tabTech2, deepCycle);

         % print dated data in CSV file
         print_dates_in_csv_file_210_to_214( ...
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
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_213_to_215( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_210_to_214(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_213(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_206_to_208_213_214( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_213_214( ...
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
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy, ...
            evAct, pumpAct, a_decoderId);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % store NetCDF technical data
         store_tech1_data_for_nc_210_to_214(tabTech1, deepCycle);
         store_tech2_data_for_nc_210_211_213(tabTech2, deepCycle);
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {214} % Provor-ARN-DO-Ice Iridium
      
      % decode the collected data
      [tabTech1, tabTech2, dataCTDO, evAct, pumpAct, floatParam1, floatParam2, ...
         irSessionNum, deepCycle] = ...
         decode_prv_data_ir_sbd_214(sbdDataData, sbdDataDate, 1);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end
      
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
      end
                        
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
      end
      
      % assign the current configuration to the decoded cycle
      if ((g_decArgo_cycleNum > 0) && (deepCycle == 1))
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if ~(isempty(floatParam1) && isempty(floatParam2))
         update_float_config_ir_sbd([{floatParam1} {floatParam2}], a_decoderId);
      end
      
      % assign the configuration received during the prelude to this cycle
      if (g_decArgo_cycleNum == 0)
         set_float_config_ir_sbd(g_decArgo_cycleNum);
      end
      
      % store GPS data and compute JAMSTEC QC for the GPS locations of the
      % current cycle
      store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
            
      % convert counts to physical values
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_202_210_to_214(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_210_to_214(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_206_to_208_213_214(dataCTDO, g_decArgo_julD2FloatDayOffset, a_decoderId);

      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_213_214(dataCTDO, g_decArgo_julD2FloatDayOffset);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfDoxy = [];
      inAirDoxy = [];
      if (~isempty(dataCTDO))
         
         % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);
         [nearSurfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            nearSurfPres, nearSurfTemp, nearSurfSal);
         
         % if the optode is not mounted on an additional stick, we compute DOXY
         % for IN AIR mesurements
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         optodeInAirMeasFlag = get_config_value('CONFIG_PX04_', configNames, configValues);
         if (isempty(optodeInAirMeasFlag) || (optodeInAirMeasFlag == 0))
            [inAirDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
               inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
               inAirPres, inAirTemp, inAirSal);
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
         lastResetDate, ...
         firstGroundingDate, firstGroundingPres, ...
         secondGroundingDate, secondGroundingPres, ...
         eolStartDate, ...
         firstEmergencyAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_210_to_214(tabTech1, tabTech2, deepCycle, a_refDay);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_214(tabTech1, tabTech2, deepCycle);
         
         % print dated data in CSV file
         print_dates_in_csv_file_210_to_214( ...
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
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_213_to_215( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy);
         
         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_210_to_214(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_212_214(floatParam1, floatParam2);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTDO))
                        
            [tabProfiles] = process_profiles_206_to_208_213_214( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_213_214( ...
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
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy, ...
            evAct, pumpAct, a_decoderId);

         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % store NetCDF technical data
         store_tech1_data_for_nc_210_to_214(tabTech1, deepCycle);
         store_tech2_data_for_nc_212_214(tabTech2, deepCycle);
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
         
         % TEMPORARY CODE
         %             idDel = find(ismember(g_decArgo_outputNcParamIndex(:, 5), ...
         %                [133, 134, 203, 204, 210, 211, 229, 230, 237, 238, 239]));
         %             g_decArgo_outputNcParamIndex(idDel, :) = [];
         %             g_decArgo_outputNcParamValue(idDel) = [];
         
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {215} % Arvor-deep 4000 with "Near Surface" & "In Air" measurements
      
      % decode the collected data
      [tabTech, dataCTD, dataCTDO, evAct, pumpAct, floatParam, deepCycle] = ...
         decode_prv_data_ir_sbd_215(sbdDataData, sbdDataDate, 1, a_decoderId);
      
      completedBuffer = a_completedBuffer;
      if (isempty(completedBuffer))
         % decode from buffer list mode
         completedBuffer = is_buffer_completed_ir_sbd(0, a_decoderId);
      end         
         
      if (completedBuffer == 0)
         % print what is missing in the buffer
         is_buffer_completed_ir_sbd(1, a_decoderId);
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
      store_gps_data_ir_sbd(tabTech, g_decArgo_cycleNum, a_decoderId);
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd(a_sbdFileNameList);
      
      % convert counts to physical values
      if (~isempty(dataCTD))
         [dataCTD(:, 32:46)] = sensor_2_value_for_pressure_201_203_215(dataCTD(:, 32:46));
         [dataCTD(:, 47:61)] = sensor_2_value_for_temperature_201_to_203_215(dataCTD(:, 47:61));
         [dataCTD(:, 62:76)] = sensor_2_value_for_salinity_201_to_203_215(dataCTD(:, 62:76));
      end
      if (~isempty(dataCTDO))
         [dataCTDO(:, 16:22)] = sensor_2_value_for_pressure_201_203_215(dataCTDO(:, 16:22));
         [dataCTDO(:, 23:29)] = sensor_2_value_for_temperature_201_to_203_215(dataCTDO(:, 23:29));
         [dataCTDO(:, 30:36)] = sensor_2_value_for_salinity_201_to_203_215(dataCTDO(:, 30:36));
         [dataCTDO(:, 37:50)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 37:50));
         [dataCTDO(:, 51:57)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 51:57));
      end
      
      % create drift data set
      [parkDate, parkTransDate, ...
         parkPres, parkTemp, parkSal, ...
         parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
         create_prv_drift_201_to_203_215(dataCTD, dataCTDO);
      
      % create descending and ascending profiles
      [descProfDate, descProfPres, descProfTemp, descProfSal, ...
         descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
         ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
         ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
         nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
         nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
         inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
         inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
         create_prv_profile_215(dataCTD, dataCTDO);

      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      nearSurfDoxy = [];
      inAirDoxy = [];
      if (~isempty(dataCTDO))
         [descProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);
         [nearSurfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            nearSurfPres, nearSurfTemp, nearSurfSal);
         [inAirDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
            inAirPres, inAirTemp, inAirSal);
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
         compute_prv_dates_201_to_203_215(tabTech, a_refDay);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_201_203_215(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_215( ...
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
            nearSurfDate, nearSurfPres, ...
            inAirDate, inAirPres, ...
            evAct, pumpAct);

         % print descending profile in CSV file
         print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
         
         % print "near surface" and "in air" measurements in CSV file
         print_in_air_meas_in_csv_file_213_to_215( ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy);

         % print EV and pump data in CSV file
         print_hydraulic_data_in_csv_file_201_to_203_215(evAct, pumpAct);
         
         % print float parameters in CSV file
         print_float_prog_param_in_csv_file_215(floatParam);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if ~(isempty(descProfPres) && isempty(ascProfPres))
            
            [tabProfiles] = process_profiles_201_203_215( ...
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
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_215( ...
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
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy, ...
            evAct, pumpAct, a_decoderId);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
         
         o_tabTrajNMeas = [o_tabTrajNMeas; tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle; tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % store information on received Iridium packet types
         if (deepCycle == 1)
            store_received_packet_type_info_for_nc(a_decoderId);
         end
         
         % update NetCDF technical data
         update_technical_data_argos_sbd(a_decoderId);
                  
         o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
         o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end      
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
