% ------------------------------------------------------------------------------
% Decode PROVOR Iridium float with Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, ...
%    o_structConfig] = ...
%    decode_provor_iridium_sbd2( ...
%    a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
%    a_launchDate, a_refDay, a_floatSoftVersion, a_floatEndDate, a_floatDmFlag)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_cycleFileNameList : list of mail files to be decoded
%   a_decoderId         : float decoder Id
%   a_floatImei         : float IMEI
%   a_launchDate        : launch date
%   a_refDay            : reference day (day of the first descent)
%   a_floatSoftVersion  : version of the float's software
%   a_floatEndDate      : end date of the data to process
%   a_floatDmFlag       : float DM flag
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, ...
   o_structConfig] = ...
   decode_provor_iridium_sbd2( ...
   a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
   a_launchDate, a_refDay, a_floatSoftVersion, a_floatEndDate, a_floatDmFlag)

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
global g_decArgo_archiveDmDirectory;
global g_decArgo_tmpDirectory;

% arrays to store rough information on received data
global g_decArgo_0TypeReceivedData;
global g_decArgo_250TypeReceivedData;
global g_decArgo_253TypeReceivedData;
global g_decArgo_254TypeReceivedData;
global g_decArgo_255TypeReceivedData;

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

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% processed data loaded flag
global g_decArgo_processedDataLoadedFlag;
g_decArgo_processedDataLoadedFlag = 0;

% report information structure
global g_decArgo_reportStruct;

% already processed rsync log information
global g_decArgo_floatWmoUnderProcessList;
global g_decArgo_rsyncLogFileUnderProcessList;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 0;

% array to store GPS data
global g_decArgo_gpsData;

% no sampled data mode
global g_decArgo_noDataFlag;
g_decArgo_noDataFlag = 0;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;
g_decArgo_iridiumMailData = [];

% array to store ko sensor states
global g_decArgo_koSensorState;
g_decArgo_koSensorState = [];

% cycle phases
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseEndOfLife;


% global g_decArgo_nbBuffToProcess;
% g_decArgo_nbBuffToProcess = 5;


% verbose mode flag
VERBOSE_MODE_BUFF = 1;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDurationIrSbd2;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDurationIrSbd2/24;

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
% - a 'archive_dm' directory used to store the DM processed SBD files
% - a 'mat' directory used to store information between sessions of the decoder
% (RT version only)
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
g_decArgo_archiveDmDirectory = [floatIriDirName 'archive_dm/'];
if ~(exist(g_decArgo_archiveDmDirectory, 'dir') == 7)
   mkdir(g_decArgo_archiveDmDirectory);
end
g_decArgo_tmpDirectory = [floatIriDirName 'mat/'];
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
   
   if (g_decArgo_generateNcMeta ~= 0)
      % create the configuration parameter names for the META NetCDF file
      [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_ir_sbd2(a_decoderId);
   end
   
   % in RT load the processed data stored in the temp directory of the float
   if (g_decArgo_realtimeFlag == 1)
      [o_tabProfiles, ...
         o_tabTrajNMeas, o_tabTrajNCycle, ...
         o_tabNcTechIndex, o_tabNcTechVal] = load_processed_data_ir_rudics_sbd2;
   end
end

% inits for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   header = ['WMO #; Cycle #; Profil #; Phase; Info type'];
   fprintf(g_decArgo_outputCsvFileId, '%s\n', header);
   print_phase_help_ir_sbd2;
end

% initialize float configuration
if (g_decArgo_processedDataLoadedFlag == 0)
   % initialize float parameter configuration
   init_float_config_ir_sbd2(a_launchDate, a_decoderId);
end

% add launch position and time in the TRAJ NetCDF file
if (g_decArgo_processedDataLoadedFlag == 0)
   if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_generateNcTraj ~= 0))
      o_tabTrajNMeas = add_launch_data_ir_sbd2;
   end
end

if (a_floatDmFlag == 0)
   
   if (g_decArgo_delayedModeFlag == 1)
      
      fprintf('WARNING: Float #%d is expected to be processed in Real Time Mode\n', ...
         a_floatNum);
      o_tabProfiles = [];
      o_tabTrajNMeas = [];
      o_tabTrajNCycle = [];
      o_tabNcTechIndex = [];
      o_tabNcTechVal = [];
      o_structConfig = [];
      return;
      
   else
      
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
               fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
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
      
      % ignore duplicated mail files (move duplicates in the archive directory)
      ignore_duplicated_mail_files(g_decArgo_spoolDirectory, g_decArgo_archiveDirectory);
      
      % retrieve information on spool directory contents
      [tabAllFileNames, ~, tabAllFileDates, tabAllFileSizes] = get_dir_files_info_ir_sbd( ...
         g_decArgo_spoolDirectory, a_floatImei, 'txt', '');
      
      % process the mail files of the spool directory in chronological order
      for idSpoolFile = 1:length(tabAllFileNames)
         
         % move the next file into the buffer directory
         move_files_ir_sbd(tabAllFileNames(idSpoolFile), g_decArgo_spoolDirectory, g_decArgo_bufferDirectory, 0, 0);
         
         % extract the attachement
         [mailContents, attachmentFound] = read_mail_and_extract_attachment(tabAllFileNames{idSpoolFile}, g_decArgo_bufferDirectory);
         g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
         if (attachmentFound == 0)
            move_files_ir_sbd(tabAllFileNames(idSpoolFile), g_decArgo_bufferDirectory, g_decArgo_archiveDirectory, 1, 0);
            fprintf('BUFF_INFO: Float #%d: Mail file without SBD: %s\n', ...
               g_decArgo_floatNum, ...
               tabAllFileNames{idSpoolFile});
            continue;
         end
         
         % delete duplicated SBD files (EX: 69001632, MOMSN=988)
         %    delete_duplicated_sbd_files(g_decArgo_bufferDirectory, g_decArgo_archiveDirectory);
         
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
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % process the 'old' files
         if (VERBOSE_MODE_BUFF == 1)
            for iFile = 1:length(tabOldFileNames)
               fprintf('BUFF_WARNING: Float #%d: processing ''old'' file %s (#%d of the %d files in the set)\n', ...
                  g_decArgo_floatNum, ...
                  tabOldFileNames{iFile}, iFile, length(tabOldFileNames));
            end
         end
         
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal] = ...
            decode_sbd_files( ...
            tabOldFileNames, tabOldFileDates, tabOldFileSizes, ...
            a_decoderId, a_launchDate, a_refDay, a_floatSoftVersion, a_floatDmFlag);
         
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
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % check if the 'new' files can be processed
         
         % initialize information arrays
         g_decArgo_0TypeReceivedData = [];
         g_decArgo_250TypeReceivedData = [];
         g_decArgo_253TypeReceivedData = [];
         g_decArgo_254TypeReceivedData = [];
         g_decArgo_255TypeReceivedData = [];
                  
         % store the SBD data
         sbdDataDate = [];
         sbdDataData = [];
         for idBufFile = 1:length(tabNewFileNames)
            
            sbdFileName = tabNewFileNames{idBufFile};
            sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
            sbdFileDate = tabNewFileDates(idBufFile);
            sbdFileSize = tabNewFileSizes(idBufFile);
            
            if (sbdFileSize > 0)
               
               if (rem(sbdFileSize, 140) == 0)
                  fId = fopen(sbdFilePathName, 'r');
                  if (fId == -1)
                     fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
                        g_decArgo_floatNum, ...
                        sbdFilePathName);
                  end
                  
                  [sbdData, sbdDataCount] = fread(fId);
                  
                  fclose(fId);
                  
                  sbdData = reshape(sbdData, 140, size(sbdData, 1)/140)';
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
               
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               
               case {301} % Remocean FLBB
                  
                  % decode transmitted data
                  [cyProfPhaseList, ...
                     dataCTD, dataOXY, dataFLBB, ...
                     sensorTechCTD, sensorTechOPTODE, sensorTechFLBB, ...
                     sensorParam, ...
                     floatPres, ...
                     tabTech, floatProgTech, floatProgParam] = ...
                     decode_prv_data_ir_sbd2_301(sbdDataData, sbdDataDate, 0);
                  
                  % check if the buffer contents can be processed
                  [okToProcess, cycleProfToProcess] = is_buffer_completed_ir_sbd2_301;

                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  
               case {302, 303} % Arvor CM
                  
                  % decode sensor data and associated technical data (0, 250, 252 and
                  % 253 msg types)
                  [cyProfPhaseList, ...
                     dataCTD, dataOXY, dataFLNTU, dataCYCLOPS, dataSEAPOINT, ...
                     sensorTechCTD, sensorTechOPTODE, sensorTechFLNTU, ...
                     sensorTechCYCLOPS, sensorTechSEAPOINT, ...
                     sensorParam, ...
                     floatPres, ...
                     tabTech, floatProgTech, floatProgParam] = ...
                     decode_prv_data_ir_sbd2_302_303(sbdDataData, sbdDataDate, 0);
                  
                  % check if the buffer contents can be processed
                  [okToProcess, cycleProfToProcess] = is_buffer_completed_ir_sbd2_302_303;
      
               otherwise
                  fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
                     g_decArgo_floatNum, ...
                     a_decoderId);
            end
                        
            if ((okToProcess == 1) || ...
                  ((idSpoolFile == length(tabAllFileDates) && (g_decArgo_realtimeFlag == 0))))
               
               % process the 'new' files
               if (VERBOSE_MODE_BUFF == 1)
                  if ((okToProcess == 1) || (idSpoolFile < length(tabAllFileDates)))
                     fprintf('BUFF_INFO: Float #%d: Processing %d SBD files:\n', ...
                        g_decArgo_floatNum, ...
                        length(tabNewFileNames));
                  else
                     fprintf('BUFF_INFO: Float #%d: Last step => processing buffer contents, %d SBD files\n', ...
                        g_decArgo_floatNum, ...
                        length(tabNewFileNames));
                  end
                  for idF = 1:length(tabNewFileNames)
                     fprintf('BUFF_INFO:    - File #%d: %s\n', ...
                        idF, tabNewFileNames{idF});
                  end
                  if (size(cycleProfToProcess, 2) > 1)
                     for idM = 1:size(cycleProfToProcess, 1)
                        cycle = cycleProfToProcess(idM, 1);
                        profile = cycleProfToProcess(idM, 2);
                        fprintf('BUFF_INFO:    => Float #%d: Processing cycle #%d profile #%d\n', ...
                           g_decArgo_floatNum, ...
                           cycle, profile);
                     end
                  elseif (cycleProfToProcess == g_decArgo_phaseSurfWait)
                     fprintf('BUFF_INFO:    => Float #%d: Processing surface data\n', ...
                        g_decArgo_floatNum);
                  elseif (cycleProfToProcess == g_decArgo_phaseEndOfLife)
                     fprintf('BUFF_INFO:    => Float #%d: Processing EOL data\n', ...
                        g_decArgo_floatNum);
                  end
               end
               
               [tabProfiles, ...
                  tabTrajNMeas, tabTrajNCycle, ...
                  tabNcTechIndex, tabNcTechVal] = ...
                  decode_sbd_files( ...
                  tabNewFileNames, tabNewFileDates, tabNewFileSizes, ...
                  a_decoderId, a_launchDate, a_refDay, a_floatSoftVersion, a_floatDmFlag);
               
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
   end
else
   
   % this float must be processed in DM
   
   if (g_decArgo_realtimeFlag == 1)
      
      fprintf('WARNING: Float #%d is expected to be processed in Delayed Mode\n', ...
         a_floatNum);
      o_tabProfiles = [];
      o_tabTrajNMeas = [];
      o_tabTrajNCycle = [];
      o_tabNcTechIndex = [];
      o_tabNcTechVal = [];
      o_structConfig = [];
      return;
      
   else
      
      fprintf('INFO: Float #%d processed in Delayed Mode\n', ...
         a_floatNum);
      
      if (g_decArgo_delayedModeFlag == 1)
         
         mailFiles = dir([g_decArgo_archiveDirectory '/' sprintf('*_%d_*.txt', ...
            a_floatImei)]);
         
         if (isempty(mailFiles))
            
            % duplicate the Iridium mail files colleted with rsync into the
            % archive directory
            fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
            fprintf('RSYNC_INFO: Duplicating %d Iridium mail files from rsync dir to float archive dir\n', ...
               length(fileIdList));
            
            for idF = 1:length(fileIdList)
               
               mailFilePathName = [g_decArgo_dirInputRsyncData '/' ...
                  g_decArgo_rsyncFloatSbdFileList{fileIdList(idF)}];
               
               [pathstr, mailFileName, ext] = fileparts(mailFilePathName);
               
               copy_files_ir({[mailFileName ext]}, pathstr, g_decArgo_archiveDirectory);
            end
            
            fprintf('RSYNC_INFO: duplication done ...\n');
            
            % split archive directory Iridium mail files
            split_mail_files(g_decArgo_archiveDirectory, g_decArgo_archiveDmDirectory);
         end
      else
         
         sbdFiles = dir([g_decArgo_archiveDmDirectory '/' sprintf('%d_*.sbd', ...
            a_floatImei)]);
         
         if (isempty(sbdFiles))
            
            % split archive directory Iridium mail files
            split_mail_files(g_decArgo_archiveDirectory, g_decArgo_archiveDmDirectory);
         end
      end
      
      % read the buffer list file
      [sbdFileNameList, sbdFileRank, sbdFileDate, sbdFileCyNum, sbdFileProfNum] = ...
         read_buffer_list(a_floatNum, g_decArgo_archiveDmDirectory);
      
      if (isempty(sbdFileNameList))
         
         [sbdFileNameList, sbdFileRank, sbdFileDate, sbdFileCyNum, sbdFileProfNum] = ...
            create_buffers(g_decArgo_archiveDmDirectory, a_launchDate, a_floatEndDate, '', '');
      end
      
      if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1) || ...
            (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc == 1)))
         % initialize data structure to store report information
         g_decArgo_reportStruct = get_report_init_struct(a_floatNum, '');
      end
      
      % retrieve information on Iridium mail files useful contents stored in the
      % archive_dm directory
      [mailFileNameList, ~, mailFileDate, ~] = get_dir_files_info_ir_sbd( ...
         g_decArgo_archiveDmDirectory, a_floatImei, 'txt', '');
      
      uRank = sort(unique(sbdFileRank));
      uRank = uRank(find(uRank > 0));
      for idRk = 1:length(uRank)
         rankNum = uRank(idRk);
         idFile = find(sbdFileRank == rankNum);
         
         fprintf('BUFFER #%d: processing %d sbd files\n', rankNum, length(idFile));
         
         cyNum = sbdFileCyNum(idFile);
         profNum = sbdFileProfNum(idFile);
         idDel = find(cyNum == -1);
         cyNum(idDel) = [];
         profNum(idDel) = [];
         cyProfNum = [cyNum' profNum'];
         uCyProfNum = unique(cyProfNum, 'rows');
         for id = 1:size(uCyProfNum, 1)
            cy = uCyProfNum(id, 1);
            prof = uCyProfNum(id, 2);
            fprintf('   -> Float #%d: Processing cycle #%d profile #%d\n', ...
               g_decArgo_floatNum, ...
               cy, prof);
         end
         
         % collect mail information
         
         % list the mail files to consider
         if (idRk == 1)
            firstDate = a_launchDate;
            lastDate = max(sbdFileDate(idFile));
            idMailFile = find((mailFileDate >= firstDate) & (mailFileDate <= lastDate));
         else
            firstDate = lastDate;
            lastDate = max(sbdFileDate(idFile));
            idMailFile = find((mailFileDate > firstDate) & (mailFileDate <= lastDate));
         end
         
         % read mail file contents
         for idMF = 1:length(idMailFile)
            [mailContents] = read_mail(mailFileNameList{idMailFile(idMF)}, g_decArgo_archiveDmDirectory);
            g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
         end
         
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal] = ...
            decode_sbd_files( ...
            sbdFileNameList(idFile), sbdFileDate(idFile), ones(1, length(idFile))*140, ...
            a_decoderId, a_launchDate, a_refDay, a_floatSoftVersion, a_floatDmFlag);
         
         %          g_decArgo_nbBuffToProcess = g_decArgo_nbBuffToProcess - 1;
         %          if (g_decArgo_nbBuffToProcess < 0)
         %             return;
         %          end
         
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
         
      end
   end
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files

   % assign second Iridium session to end of previous cycle and merge first/last
   % msg and location times
   if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_generateNcTraj ~= 0))
      [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_sbd2( ...
         o_tabTrajNMeas, o_tabTrajNCycle);
   end
   
   % add interpolated profile locations
   [o_tabProfiles] = fill_empty_profile_locations_ir_sbd2(o_tabProfiles, g_decArgo_gpsData, ...
      o_tabTrajNMeas, o_tabTrajNCycle);
   
   % cut CTD profile at the cut-off pressure of the CTD pump
   [o_tabProfiles] = cut_ctd_profile_ir_sbd2(o_tabProfiles);
   
   % create output float configuration
   [o_structConfig] = create_output_float_config_ir_sbd2(decArgoConfParamNames, ncConfParamNames, a_decoderId);
   
   % add configuration number and output cycle number
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = add_configuration_number_ir_rudics_sbd2( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle);
   
   % set QC parameters to '3' when the sensor state is ko
   [o_tabProfiles, o_tabTrajNMeas] = update_qc_from_sensor_state_ir_rudics_sbd2( ...
      o_tabProfiles, o_tabTrajNMeas);
   
   % set JULD_QC and POSITION_QC to '3' when the profile has been created after
   % a buffer anomaly (more than one profile for a given profile number)
   [o_tabProfiles] = check_profile_ir_rudics_sbd2(o_tabProfiles);
   
   if (g_decArgo_realtimeFlag == 1)
      % in RT save the processed data in the temp directory of the float
      save_processed_data_ir_rudics_sbd2(o_tabProfiles, ...
         o_tabTrajNMeas, o_tabTrajNCycle, ...
         o_tabNcTechIndex, o_tabNcTechVal);
      
      % in RT save the list of already processed rsync log files in the temp
      % directory of the float
      idEq = find(g_decArgo_floatWmoUnderProcessList == a_floatNum);
      write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, ...
         g_decArgo_rsyncLogFileUnderProcessList{idEq});
   end
   
   % update NetCDF technical data (add a column to store output cycle numbers)
   o_tabNcTechIndex = update_technical_data_iridium_rudics_sbd2(o_tabNcTechIndex);
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
%    a_decoderId, a_launchDate, a_refDay, a_floatSoftVersion, a_floatDmFlag)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList  : list of SBD file names
%   a_sbdFileNameList  : list of SBD file dates
%   a_sbdFileNameList  : list of SBD file sizes
%   a_decoderId        : float decoder Id
%   a_launchDate       : launch date
%   a_refDay           : reference day (day of the first descent)
%   a_floatSoftVersion : version of the float's software
%   a_floatDmFlag      : float DM flag
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal] = ...
   decode_sbd_files( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
   a_decoderId, a_launchDate, a_refDay, a_floatSoftVersion, a_floatDmFlag)

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
g_decArgo_cycleNum = '';

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;

% SBD sub-directories
global g_decArgo_bufferDirectory;

% array to store GPS data
global g_decArgo_gpsData;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


% no data to process
if (isempty(a_sbdFileNameList))
   return;
end

% read the SBD file data
sbdDataDate = [];
sbdDataData = [];
for idFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idFile};
   if (a_floatDmFlag == 1)
      sbdFilePathName = sbdFileName;
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   
   if (a_sbdFileSizeList(idFile) > 0)
      
      if (rem(a_sbdFileSizeList(idFile), 140) == 0)
         fId = fopen(sbdFilePathName, 'r');
         if (fId == -1)
            fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
               g_decArgo_floatNum, ...
               sbdFilePathName);
         end
         
         [sbdData, sbdDataCount] = fread(fId);
         
         fclose(fId);
         
         sbdData = reshape(sbdData, 140, size(sbdData, 1)/140)';
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
      fprintf(g_decArgo_outputCsvFileId, '%d; -; -; %s; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: %d\n', ...
         g_decArgo_floatNum, get_phase_name(-1), ...
         idFile, a_sbdFileNameList{idFile}, ...
         a_sbdFileSizeList(idFile), a_sbdFileSizeList(idFile)/140);
   end
end

% decode the data

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {301} % Remocean FLBB
      
      % decode sensor data and associated technical data (0, 250, 252 and
      % 253 msg types)
      [cyProfPhaseList, ...
         dataCTD, dataOXY, dataFLBB, ...
         sensorTechCTD, sensorTechOPTODE, sensorTechFLBB, ...
         sensorParamEmpty, ...
         floatPres, ...
         tabTech, floatProgTechEmpty, floatProgParamEmpty] = ...
         decode_prv_data_ir_sbd2_301(sbdDataData, sbdDataDate, 1);
      
      % assign the current configuration to the decoded cycles and
      % profiles
      set_float_config_ir_sbd2(cyProfPhaseList, a_floatSoftVersion, a_decoderId);
      
      % keep only new GPS locations (acquired during a surface phase)
      [tabTech] = clean_gps_data_ir_rudics_sbd2(tabTech);
      
      % store GPS data
      store_gps_data_ir_rudics_sbd2(tabTech);
      
      % assign a cycle and profile numbers to Iridium mails currently processed
      update_mail_data_ir_sbd2(a_sbdFileNameList, cyProfPhaseList);
      
      % add dates to drift measurements
      [dataCTD, dataOXY, dataFLBB] = ...
         add_drift_meas_dates_ir_sbd2_301(dataCTD, dataOXY, dataFLBB);
      
      % set drift of float RTC
      floatClockDrift = 0;
      
      % compute the main dates of the cycle
      [cycleStartDate, buoyancyRedStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, descentToProfEndDate, ...
         ascentStartDate, ascentEndDate, ...
         transStartDate, ...
         firstEmerAscentDate] = ...
         compute_prv_dates_ir_rudics_sbd2(tabTech, ...
         floatClockDrift, a_refDay);
      
      % decode configuration data (251, 254 and 255 msg types)
      [cyProfPhaseListConfig, ...
         dataCTDEmpty, dataOXYEmpty, dataFLBBEmpty, ...
         sensorTechCTDEmpty, sensorTechOPTODEEmpty, sensorTechFLBBEmpty, ...
         sensorParam, ...
         floatPresEmpty, ...
         tabTechEmpty, floatProgTech, floatProgParam] = ...
         decode_prv_data_ir_sbd2_301(sbdDataData, sbdDataDate, 2);
      
      cyProfPhaseList = [cyProfPhaseList; cyProfPhaseListConfig];
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
               
         % print decoded data in CSV file
         print_info_in_csv_file_ir_sbd2( ...
            a_decoderId, ...
            cyProfPhaseList, ...
            dataCTD, dataOXY, dataFLBB, [], [], [], ...
            sensorTechCTD, sensorTechOPTODE, sensorTechFLBB, [], [], [], ...
            sensorParam, ...
            floatPres, ...
            tabTech, floatProgTech, floatProgParam);
         
         % print dated data in CSV file
         if (~isempty(tabTech))
            print_dates_in_csv_file_ir_sbd2( ...
               cycleStartDate, buoyancyRedStartDate, ...
               descentToParkStartDate, ...
               firstStabDate, firstStabPres, ...
               descentToParkEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, ...
               transStartDate, ...
               dataCTD, dataOXY, dataFLBB, [], [], [], ...
               g_decArgo_gpsData);
         end
         
      else
      
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         [tabProfiles, tabDrift] = process_profiles_ir_sbd2( ...
            a_decoderId, ...
            cyProfPhaseList, ...
            dataCTD, dataOXY, dataFLBB, [], [], [], ...
            descentToParkStartDate, ascentEndDate, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            sensorTechCTD, sensorTechOPTODE, sensorTechFLBB, [], [], []);
         
         % add the vertical sampling scheme from configuration
         % information
         [tabProfiles] = add_vertical_sampling_scheme_ir_sbd2(tabProfiles);
         
         % merge profile measurements (raw and averaged measurements of
         % a given profile)
         [tabProfiles] = merge_profile_meas_ir_rudics_sbd2(tabProfiles);
         
         % compute derived parameters of the profiles
         [tabProfiles] = compute_profile_derived_parameters_ir_sbd2(tabProfiles, a_decoderId);
         
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
                  fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
                     idP, prof.profileNumber, prof.direction, ...
                     profLength, paramList(1:end-1));
               end
            else
               fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            end
         end
         
         o_tabProfiles = [o_tabProfiles tabProfiles];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % merge drift measurements (raw and averaged measurements of
         % the park phase)
         [tabDrift] = merge_profile_meas_ir_rudics_sbd2(tabDrift);
         
         % compute derived parameters of the park phase
         [tabDrift] = compute_drift_derived_parameters_ir_sbd2(tabDrift, a_decoderId);
         
         % collect trajectory data for TRAJ NetCDF file
         [tabTrajIndex, tabTrajData] = collect_trajectory_data_ir_rudics_sbd2( ...
            tabProfiles, tabDrift, ...
            floatProgTech, floatProgParam, ...
            floatPres, tabTech, a_refDay, ...
            cycleStartDate, buoyancyRedStartDate, ...
            descentToParkStartDate, ...
            descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            firstEmerAscentDate, ...
            sensorTechCTD);
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_ir_rudics_sbd2( ...
            cyProfPhaseList, tabTrajIndex, tabTrajData);
         
         o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % process technical data for TECH NetCDF file
         process_technical_data_ir_sbd2( ...
            a_decoderId, cyProfPhaseList, ...
            sensorTechCTD, sensorTechOPTODE, sensorTechFLBB, [], [], [], ...
            tabTech, a_refDay);
         
         % filter useless technical data
         filter_technical_data_ir_rudics_sbd2;
         
         if (~isempty(g_decArgo_outputNcParamIndex))
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         end
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
            
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {302, 303} % Arvor CM
      
      % decode sensor data and associated technical data (0, 250, 252 and
      % 253 msg types)
      [cyProfPhaseList, ...
         dataCTD, dataOXY, dataFLNTU, dataCYCLOPS, dataSEAPOINT, ...
         sensorTechCTD, sensorTechOPTODE, sensorTechFLNTU, ...
         sensorTechCYCLOPS, sensorTechSEAPOINT, ...
         sensorParamEmpty, ...
         floatPres, ...
         tabTech, floatProgTechEmpty, floatProgParamEmpty] = ...
         decode_prv_data_ir_sbd2_302_303(sbdDataData, sbdDataDate, 1);
      
      % assign the current configuration to the decoded cycles and
      % profiles
      set_float_config_ir_sbd2(cyProfPhaseList, a_floatSoftVersion, a_decoderId);
      
      % keep only new GPS locations (acquired during a surface phase)
      [tabTech] = clean_gps_data_ir_rudics_sbd2(tabTech);
      
      % store GPS data
      store_gps_data_ir_rudics_sbd2(tabTech);
      
      % assign a cycle and profile numbers to Iridium mails currently processed
      update_mail_data_ir_sbd2(a_sbdFileNameList, cyProfPhaseList);

      % add dates to drift measurements
      [dataCTD, dataOXY, dataFLNTU, dataCYCLOPS, dataSEAPOINT] = ...
         add_drift_meas_dates_ir_sbd2_302_303(dataCTD, dataOXY, dataFLNTU, dataCYCLOPS, dataSEAPOINT);
      
      % set drift of float RTC
      floatClockDrift = 0;
      
      % compute the main dates of the cycle
      [cycleStartDate, buoyancyRedStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, descentToProfEndDate, ...
         ascentStartDate, ascentEndDate, ...
         transStartDate, ...
         firstEmerAscentDate] = ...
         compute_prv_dates_ir_rudics_sbd2(tabTech, ...
         floatClockDrift, a_refDay);
      
      % decode configuration data (251, 254 and 255 msg types)
      [cyProfPhaseListConfig, ...
         dataCTDEmpty, dataOXYEmpty, dataFLNTUEmpty, dataCYCLOPSEmpty, dataSEAPOINTEmpty, ...
         sensorTechCTDEmpty, sensorTechOPTODEEmpty, sensorTechFLNTUEmpty, ...
         sensorTechCYCLOPSEmpty, sensorTechSEAPOINTEmpty, ...
         sensorParam, ...
         floatPresEmpty, ...
         tabTechEmpty, floatProgTech, floatProgParam] = ...
         decode_prv_data_ir_sbd2_302_303(sbdDataData, sbdDataDate, 2);

      cyProfPhaseList = [cyProfPhaseList; cyProfPhaseListConfig];
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file

         % print decoded data in CSV file
         print_info_in_csv_file_ir_sbd2( ...
            a_decoderId, ...
            cyProfPhaseList, ...
            dataCTD, dataOXY, [], dataFLNTU, dataCYCLOPS, dataSEAPOINT, ...
            sensorTechCTD, sensorTechOPTODE, [], sensorTechFLNTU, ...
            sensorTechCYCLOPS, sensorTechSEAPOINT, ...
            sensorParam, ...
            floatPres, ...
            tabTech, floatProgTech, floatProgParam);
         
         % print dated data in CSV file
         if (~isempty(tabTech))
            print_dates_in_csv_file_ir_sbd2( ...
               cycleStartDate, buoyancyRedStartDate, ...
               descentToParkStartDate, ...
               firstStabDate, firstStabPres, ...
               descentToParkEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, ...
               transStartDate, ...
               dataCTD, dataOXY, [], dataFLNTU, dataCYCLOPS, dataSEAPOINT, ...
               g_decArgo_gpsData);
         end
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         [tabProfiles, tabDrift] = process_profiles_ir_sbd2( ...
            a_decoderId, ...
            cyProfPhaseList, ...
            dataCTD, dataOXY, [], dataFLNTU, dataCYCLOPS, dataSEAPOINT, ...
            descentToParkStartDate, ascentEndDate, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            sensorTechCTD, sensorTechOPTODE, [], sensorTechFLNTU, ...
            sensorTechCYCLOPS, sensorTechSEAPOINT);
         
         % add the vertical sampling scheme from configuration
         % information
         % we use the RUDICS Matlab function to create the VSS
         [tabProfiles] = add_vertical_sampling_scheme_ir_rudics(tabProfiles);
         
         % merge profile measurements (raw and averaged measurements of a given
         % profile)
         [tabProfiles] = merge_profile_meas_ir_rudics_sbd2(tabProfiles);
         
         % compute derived parameters of the profiles
         [tabProfiles] = compute_profile_derived_parameters_ir_sbd2(tabProfiles, a_decoderId);
         
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
                  fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
                     idP, prof.profileNumber, prof.direction, ...
                     profLength, paramList(1:end-1));
               end
            else
               fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            end
         end
         
         o_tabProfiles = [o_tabProfiles tabProfiles];
            
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % merge drift measurements (raw and averaged measurements of the park phase)
         [tabDrift] = merge_profile_meas_ir_rudics_sbd2(tabDrift);
         
         % compute derived parameters of the park phase
         [tabDrift] = compute_drift_derived_parameters_ir_sbd2(tabDrift, a_decoderId);
         
         % collect trajectory data for TRAJ NetCDF file
         [tabTrajIndex, tabTrajData] = collect_trajectory_data_ir_rudics_sbd2( ...
            tabProfiles, tabDrift, ...
            floatProgTech, floatProgParam, ...
            floatPres, tabTech, a_refDay, ...
            cycleStartDate, buoyancyRedStartDate, ...
            descentToParkStartDate, ...
            descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            firstEmerAscentDate, ...
            sensorTechCTD);
         
         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle] = process_trajectory_data_ir_rudics_sbd2( ...
            cyProfPhaseList, tabTrajIndex, tabTrajData);
         
         o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
         o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % process technical data for TECH NetCDF file
         process_technical_data_ir_sbd2( ...
            a_decoderId, cyProfPhaseList, ...
            sensorTechCTD, sensorTechOPTODE, [], sensorTechFLNTU, ...
            sensorTechCYCLOPS, sensorTechSEAPOINT, ...
            tabTech, a_refDay);
         
         % filter useless technical data
         filter_technical_data_ir_rudics_sbd2;
         
         if (~isempty(g_decArgo_outputNcParamIndex))
            o_tabNcTechIndex = [o_tabNcTechIndex; g_decArgo_outputNcParamIndex];
            o_tabNcTechVal = [o_tabNcTechVal g_decArgo_outputNcParamValue];
         end
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
