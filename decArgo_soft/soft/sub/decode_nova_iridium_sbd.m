% ------------------------------------------------------------------------------
% Decode NOVA Iridium float with Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechAuxNMeas, ...
%    o_structConfig] = ...
%    decode_nova_iridium_sbd( ...
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
%   o_tabTechAuxNMeas : decoded technical N_MEASUREMENT AUX data
%   o_structConfig    : NetCDF float configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechAuxNMeas, ...
   o_structConfig] = ...
   decode_nova_iridium_sbd( ...
   a_floatNum, a_cycleFileNameList, a_decoderId, a_floatImei, ...
   a_launchDate, a_refDay, a_floatEndDate)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
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

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabelBis;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;
global g_decArgo_processRemainingBuffers;

% SBD sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_archiveSbdDirectory;
global g_decArgo_historyDirectory;

% arrays to store rough information on received data
global g_decArgo_1TypePacketReceived;
global g_decArgo_5TypePacketReceived;
global g_decArgo_nbOf2To4TypePacketExpected;
global g_decArgo_nbOf10To29TypePacketExpected;
global g_decArgo_nbOf30To49TypePacketExpected;
global g_decArgo_nbOf50To55TypePacketExpected;
global g_decArgo_nbOf2To4TypePacketReceived;
global g_decArgo_nbOf10To29TypePacketReceived;
global g_decArgo_nbOf30To49TypePacketReceived;
global g_decArgo_nbOf50To55TypePacketReceived;

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

% for some (oldest) float versions the prelude and the first deep cycle have the
% same number 0. We cannot manage this in the TRAJ files and choose to add 1 to
% cycle numbers transmitted by the float (except for the prelude phase cycle
% number (0))
global g_decArgo_firstDeepCycleDone;
g_decArgo_firstDeepCycleDone = 0;

% number of the previous decoded cycle
global g_decArgo_cycleNumPrev;
g_decArgo_cycleNumPrev = -1;

% offset to consider for cycle numbers
global g_decArgo_cycleNumOffset;
g_decArgo_cycleNumOffset = 0;

% prelude ended flag
global g_decArgo_preludeDoneFlag;
g_decArgo_preludeDoneFlag = 0;

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDuration/24;

% verbose mode flag
VERBOSE_MODE_BUFF = 1;

% cycle timings storage
global g_decArgo_timeData;
g_decArgo_timeData = [];

% pre-decoding data storage
global g_decArgo_preDecodedData;
g_decArgo_preDecodedData = [];

% final EOL flag (float in EOL mode and cycle number set to 256 by the decoder)
global g_decArgo_finalEolMode;
g_decArgo_finalEolMode = 0;

% float configuration
global g_decArgo_floatConfig;

% TRAJ 3.2 file generation flag
global g_decArgo_generateNcTraj32;


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
[tabAllFileNames, ~, tabAllFileDates, ~] = get_list_files_info_ir_sbd('spool', '');

% decode all received housekeeping messages to collect SBDT information
fprintf('INFO: Float #%d: First decoding of all housekeeping messages to collect SBDT information\n', ...
   g_decArgo_floatNum);

% extract the attachement of the mail files of the spool directory and store
% them in the buffer directory
for idSpoolFile = 1:length(tabAllFileNames)
   
   % extract the attachement
   [~, attachmentFound] = read_mail_and_extract_attachment( ...
      tabAllFileNames{idSpoolFile}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   if (attachmentFound == 1)
      add_to_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'buffer');
   end
end

% retrieve information on buffer directory contents
[tabAllSbdFileNames, ~, ~, tabAllSbdFileSizes] = get_list_files_info_ir_sbd('buffer', '');

% store the SBDT information of all received housekeeping messages
g_decArgo_preDecodedData = [];
g_decArgo_preDecodedData.cycleNum = [];
g_decArgo_preDecodedData.sbdt = [];
for idBufFile = 1:length(tabAllSbdFileNames)
   
   sbdFileName = tabAllSbdFileNames{idBufFile};
   sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   sbdFileSize = tabAllSbdFileSizes(idBufFile);
   
   if (sbdFileSize > 0)
      
      fId = fopen(sbdFilePathName, 'r');
      if (fId == -1)
         fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
            g_decArgo_floatNum, ...
            sbdFilePathName);
      end
      
      [sbdData, sbdDataCount] = fread(fId);
      
      fclose(fId);
      
      info = get_bits(1, 8, sbdData);
      if (info == 1)
         
         switch (a_decoderId)
            
            case {2001, 2002} % Nova 1.0, Dova 2.0
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [ ...
                  8 ...
                  repmat(16, 1, 7) ...
                  repmat(8, 1, 12) ...
                  16 8 16 8 16 8 8 ...
                  16 16 repmat(8, 1, 10) 32 32 8 16 8 8 8 16 8 8 8 16 8 ...
                  ];
               % get item bits
               tabTech = get_bits(firstBit, tabNbBits, sbdData);
               
               g_decArgo_preDecodedData.cycleNum = [g_decArgo_preDecodedData.cycleNum tabTech(32)];
               g_decArgo_preDecodedData.sbdt = [g_decArgo_preDecodedData.sbdt 2*tabTech(52)];
               
            case {2003} % Nova 0.9
               
               % first item bit number
               firstBit = 1;
               % item bit lengths
               tabNbBits = [ ...
                  8 16 ...
                  repmat(8, 1, 6) ...
                  repmat(8, 1, 12) ...
                  16 8 16 8 16 8 8 ...
                  16 16 repmat(8, 1, 9) 32 32 repmat(8, 1, 11) ...
                  ];
               % get item bits
               tabTech = get_bits(firstBit, tabNbBits, sbdData);
               
               g_decArgo_preDecodedData.cycleNum = [g_decArgo_preDecodedData.cycleNum tabTech(32)];
               g_decArgo_preDecodedData.sbdt = [g_decArgo_preDecodedData.sbdt 2*tabTech(51)];
               
         end
      end
      
      delete(sbdFilePathName);
      remove_from_list_ir_sbd(tabAllSbdFileNames{idBufFile}, 'buffer', 0, 0);
   end
end
g_decArgo_preDecodedData.used = zeros(size(g_decArgo_preDecodedData.cycleNum));
if (~isempty(g_decArgo_preDecodedData.cycleNum))
   % the first SBDT is not used, it is stored with cycleNum == 255 if it came
   % from the PRELUDE (should be set as used so that it will not be used for a
   % possible cycle #255)
   g_decArgo_preDecodedData.used(1) = 1;
end

if (g_decArgo_realtimeFlag)
   
   % process mail files according to stored buffers
   
   % read the buffer list file
   [mailFileNameList, mailFileRank] = read_buffer_list(a_floatNum, g_decArgo_historyDirectory);
   
   uRank = sort(unique(mailFileRank));
   for idRk = 1:length(uRank)
      rankNum = uRank(idRk);
      idFileList = find(mailFileRank == rankNum);
      
      fprintf('BUFFER #%d: processing %d sbd files\n', rankNum, length(idFileList));
      
      for idF = 1:length(idFileList)
         
         % move the next file into the buffer directory
         add_to_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'buffer');
         remove_from_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'spool', 0, 0);
         
         % extract the attachement
         [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
            mailFileNameList{idFileList(idF)}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
         g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
         if (attachmentFound == 0)
            remove_from_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'buffer', 1, 0);
         end
      end
      
      % process the files of the buffer directory
      
      % retrieve information on the files in the buffer
      [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd('buffer', '');
      
      % check if the EOL anomaly occured in this buffer
      
      % read SBD data
      [~, sbdDataData] = read_nova_iridium_sbd( ...
         tabFileNames, tabFileDates, tabFileSizes, 0);
      
      % manage EOL anomaly (housekeeping packets of different cycle numbers
      % and expecting 1 hydraulic packet never transmitted Ex: 6903192)
      eolAnomaly = 0;
      
      if (~isempty(sbdDataData) && (length(find(sbdDataData(:, 1) == 1)) > 1) && (~any(sbdDataData(:, 1) ~= 1)))
         
         cycleNumbers = decode_cycle_number_nva_data_ir_sbd(sbdDataData);
         if (length(unique(cycleNumbers)) > 1)
            
            uCycleNumbers = unique(cycleNumbers);
            fprintf('INFO: Float #%d cycle #%d: EOL anomaly detected (cycle #%d housekeeping packet in the same buffer)\n', ...
               g_decArgo_floatNum, uCycleNumbers(1), uCycleNumbers(2));
            eolAnomaly = 1;
         end
      end
      
      if (~eolAnomaly)
         
         % process all buffer files
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas] = ...
            decode_sbd_files( ...
            tabFileNames, tabFileDates, tabFileSizes, ...
            a_decoderId, a_launchDate, []);
      else
         
         % process the first file of the buffer
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas] = ...
            decode_sbd_files( ...
            tabFileNames(1), tabFileDates(1), tabFileSizes(1), ...
            a_decoderId, a_launchDate, []);
      end
      
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
      if (~isempty(tabTechAuxNMeas))
         o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
      end
      
      % move the processed files into the archive directory (and delete
      % the associated SBD files)
      if (~eolAnomaly)
         remove_from_list_ir_sbd(tabFileNames, 'buffer', 1, 0);
      else
         remove_from_list_ir_sbd(tabFileNames(1), 'buffer', 1, 0);
      end
   end
end

% retrieve information on spool directory contents
[tabAllFileNames, ~, tabAllFileDates, ~] = get_list_files_info_ir_sbd('spool', '');

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
   
   % specific
   if (g_decArgo_floatNum == 6903283)
      if(strcmp(tabAllFileNames{idSpoolFile}, 'co_20190816T065643Z_300234062954200_001370_000000_4000.txt'))
         % 6903283 #(2+1), #(3+1) ... #(84+1), #(255+1), #(256+1)
         % float reset after #85
         % #256 is surface cycle with cycle #255
         % #257 is deep cycle with cycle #0 contaioning data of cycle #86
         % we cannot use the #256 transmission => the corresponding GPS fix is
         % not considered
         % note that the dates of cycle #86 are not consistent due to float
         % erroneous time (cycle start date)
         continue
      end
   end
   
   if (g_decArgo_realtimeFlag)
      bufferMailFileNames{end+1} = tabAllFileNames{idSpoolFile};
      bufferMailFileDates(end+1) = tabAllFileDates(idSpoolFile);
   end
   
   % move the next file into the buffer directory
   add_to_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'buffer');
   remove_from_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'spool', 0, 0);
   
   % extract the attachement
   [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
      tabAllFileNames{idSpoolFile}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
   if (attachmentFound == 0)
      remove_from_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'buffer', 1, 0);
      if (idSpoolFile < length(tabAllFileNames))
         continue
      end
   end
   
   if (g_decArgo_finalEolMode ~= 1)
      
      % nominal case
      
      % process the files of the buffer directory
      
      % retrieve information on the files in the buffer
      [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd('buffer', '');
      
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
            tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas] = ...
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
         if (~isempty(tabTechAuxNMeas))
            o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
         end
         %       end
         
         % move the processed 'old' files into the archive directory (and delete the
         % associated SBD files)
         remove_from_list_ir_sbd(tabOldFileNames, 'buffer', 1, 0);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % check if the 'new' files can be processed
      
      % initialize information arrays
      g_decArgo_1TypePacketReceived = 0;
      g_decArgo_5TypePacketReceived = 0;
      g_decArgo_nbOf2To4TypePacketExpected = -1;
      g_decArgo_nbOf10To29TypePacketExpected = -1;
      g_decArgo_nbOf30To49TypePacketExpected = -1;
      g_decArgo_nbOf50To55TypePacketExpected = -1;
      g_decArgo_nbOf2To4TypePacketReceived = 0;
      g_decArgo_nbOf10To29TypePacketReceived = 0;
      g_decArgo_nbOf30To49TypePacketReceived = 0;
      g_decArgo_nbOf50To55TypePacketReceived = 0;
      
      % read SBD data
      [sbdDataDate, sbdDataData] = read_nova_iridium_sbd( ...
         tabNewFileNames, tabNewFileDates, tabNewFileSizes, 0);
      
      % roughly check the received data
      if (~isempty(sbdDataData))
         
         switch (a_decoderId)
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            case {2001} % Nova 1.0
               
               % decode the collected data
               decode_nva_data_ir_sbd_2001(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
               
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               
            case {2002} % Dova 2.0
               
               % decode the collected data
               decode_nva_data_ir_sbd_2002(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
               
               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               
            case {2003} % Nova 0.9
               
               % decode the collected data
               decode_nva_data_ir_sbd_2003(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
               
            otherwise
               fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
                  g_decArgo_floatNum, ...
                  a_decoderId);
         end
         
         % check if the buffer contents can be processed
         [okToProcess] = is_buffer_completed_ir_sbd_nva(0, a_decoderId);
         %       fprintf('Buffer completed : %d\n', okToProcess);
         
         if ((okToProcess) || ...
               ((idSpoolFile == length(tabAllFileDates) && g_decArgo_processRemainingBuffers)))
            
            if (g_decArgo_realtimeFlag)
               if (okToProcess)
                  write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, bufferMailFileNames, bufferRank);
                  bufferRank = bufferRank + 1;
                  bufferMailFileNames = [];
                  bufferMailFileDates = [];
               end
            end
            
            % process the 'new' files
            if (VERBOSE_MODE_BUFF == 1)
               if ((okToProcess == 1) || (idSpoolFile < length(tabAllFileDates)))
                  fprintf('BUFF_INFO: Float #%d: Processing %d SBD files:\n', ...
                     g_decArgo_floatNum, ...
                     length(tabNewFileNames));
               else
                  fprintf('BUFF_INFO: Float #%d: Last step - processing buffer contents, %d SBD files:\n', ...
                     g_decArgo_floatNum, ...
                     length(tabNewFileNames));
               end
            end
            
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas] = ...
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
            if (~isempty(tabTechAuxNMeas))
               o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
            end
            
            % move the processed 'new' files into the archive directory (and delete
            % the associated SBD files)
            remove_from_list_ir_sbd(tabNewFileNames, 'buffer', 1, 0);
            
         else
            
            % manage EOL anomaly (housekeeping packets of different cycle numbers
            % and expecting 1 hydraulic packet never transmitted Ex: 6903192)
            eolAnomaly = 0;
            
            if ((length(find(sbdDataData(:, 1) == 1)) > 1) && (~any(sbdDataData(:, 1) ~= 1)))
               
               cycleNumbers = decode_cycle_number_nva_data_ir_sbd(sbdDataData);
               if (length(unique(cycleNumbers)) > 1)
                  
                  uCycleNumbers = unique(cycleNumbers);
                  fprintf('INFO: Float #%d cycle #%d: EOL anomaly detected (cycle #%d housekeeping packet in the same buffer)\n', ...
                     g_decArgo_floatNum, uCycleNumbers(1), uCycleNumbers(2));
                  eolAnomaly = 1;
               end
            end
            
            if (eolAnomaly)
               
               if (g_decArgo_realtimeFlag)
                  idF = find(strcmp(regexprep(tabNewFileNames(1), '.sbd', '.txt'), bufferMailFileNames));
                  write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, bufferMailFileNames(1:idF), bufferRank);
                  bufferRank = bufferRank + 1;
                  bufferMailFileNames(1:idF) = [];
                  bufferMailFileDates(1:idF) = [];
               end
               
               [tabProfiles, ...
                  tabTrajNMeas, tabTrajNCycle, ...
                  tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas] = ...
                  decode_sbd_files( ...
                  tabNewFileNames(1), tabNewFileDates(1), tabNewFileSizes(1), ...
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
               if (~isempty(tabTechAuxNMeas))
                  o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
               end
               
               % move the processed 'new' files into the archive directory (and delete
               % the associated SBD files)
               remove_from_list_ir_sbd(tabNewFileNames(1), 'buffer', 1, 0);
            end
         end
      end
      
   else
      
      % when final EOL mode is detected we process all remaining files together
      
      if (idSpoolFile == length(tabAllFileNames))
         
         % retrieve information on the files in the buffer
         [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd('buffer', '');
         
         % store buffer information
         if (g_decArgo_realtimeFlag)
            write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, bufferMailFileNames, bufferRank);
            % bufferRank = bufferRank + 1; % following ones should have the same rank
            bufferMailFileNames = [];
            bufferMailFileDates = [];
         end
         
         % process all the remaining files
         if (VERBOSE_MODE_BUFF == 1)
            fprintf('BUFF_INFO: Float #%d: Final EOL mode detected - processing %d SBD files:\n', ...
               g_decArgo_floatNum, ...
               length(tabFileNames));
         end
         
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas] = ...
            decode_sbd_files( ...
            tabFileNames, tabFileDates, tabFileSizes, ...
            a_decoderId, a_launchDate, 1);
         
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
         if (~isempty(tabTechAuxNMeas))
            o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
         end
         
         % move the processed files into the archive directory (and delete
         % the associated SBD files)
         remove_from_list_ir_sbd(tabFileNames, 'buffer', 1, 0);
      end
   end
end

if (isempty(g_decArgo_outputCsvFileId))
   
   % output NetCDF files
   
   % add interpolated/extrapolated profile locations
   [o_tabProfiles] = fill_empty_profile_locations_ir_sbd(g_decArgo_gpsData, o_tabProfiles);
   
   % update the output cycle number in the structures
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, ~, o_tabTechAuxNMeas] = ...
      update_output_cycle_number_ir_sbd( ...
      o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, [], o_tabTechAuxNMeas);
   
   % perform PARAMETER adjustment
   [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle] = ...
      compute_rt_adjusted_param(o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, a_launchDate, 0, a_decoderId);
   
   if (g_decArgo_generateNcTraj32 ~= 0)
      % report profile PARAMETER adjustments in TRAJ data
      [o_tabTrajNMeas, o_tabTrajNCycle] = report_rt_adjusted_profile_data_in_trajectory( ...
         o_tabTrajNMeas, o_tabTrajNCycle, o_tabProfiles);
   end
   
   % add unseen cycles, clean FMT, LMT and GPS locations and set TST and TET
   [o_tabTrajNMeas, o_tabTrajNCycle] = finalize_trajectory_data_ir_sbd_nva( ...
      o_tabTrajNMeas, o_tabTrajNCycle, a_decoderId);
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistent
   [o_tabTrajNMeas, o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNMeas, o_tabTrajNCycle);
   
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

rmdir(g_decArgo_archiveSbdDirectory, 's');

return

% ------------------------------------------------------------------------------
% Decode one set of Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechAuxNMeas] = ...
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
%   o_tabProfiles     : decoded profiles
%   o_tabTrajNMeas    : decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle   : decoded trajectory N_CYCLE data
%   o_tabNcTechIndex  : decoded technical index information
%   o_tabNcTechVal    : decoded technical data
%   o_tabTechAuxNMeas : decoded technical PARAM AUX data
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
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechAuxNMeas] = ...
   decode_sbd_files( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
   a_decoderId, a_launchDate, a_completedBuffer)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabNcTechIndex = [];
o_tabNcTechVal = [];
o_tabTechAuxNMeas = [];

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

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% arrays to store rough information on received data
global g_decArgo_1TypePacketReceived;
global g_decArgo_5TypePacketReceived;
global g_decArgo_nbOf2To4TypePacketExpected;
global g_decArgo_nbOf10To29TypePacketExpected;
global g_decArgo_nbOf30To49TypePacketExpected;
global g_decArgo_nbOf50To55TypePacketExpected;
global g_decArgo_nbOf2To4TypePacketReceived;
global g_decArgo_nbOf10To29TypePacketReceived;
global g_decArgo_nbOf30To49TypePacketReceived;
global g_decArgo_nbOf50To55TypePacketReceived;
global g_decArgo_ackPacket;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1;

% flag used to add 1 to cycle numbers
global g_decArgo_firstDeepCycleDone;

% number of the previous decoded cycle
global g_decArgo_cycleNumPrev;


% no data to process
if (isempty(a_sbdFileNameList))
   return
end

% read the SBD file data
[sbdDataDate, sbdDataData] = read_nova_iridium_sbd( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, 1);

% decode the data

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {2001, 2003} % Nova 1.0 & 0.9
      
      if (isempty(a_completedBuffer) || (a_completedBuffer == 0))
         
         % initialize information arrays
         g_decArgo_1TypePacketReceived = 0;
         g_decArgo_5TypePacketReceived = 0;
         g_decArgo_nbOf2To4TypePacketExpected = -1;
         g_decArgo_nbOf10To29TypePacketExpected = -1;
         g_decArgo_nbOf30To49TypePacketExpected = -1;
         g_decArgo_nbOf50To55TypePacketExpected = -1;
         g_decArgo_nbOf2To4TypePacketReceived = 0;
         g_decArgo_nbOf10To29TypePacketReceived = 0;
         g_decArgo_nbOf30To49TypePacketReceived = 0;
         g_decArgo_nbOf50To55TypePacketReceived = 0;
         
         % roughly check the received data
         if (a_decoderId == 2001)
            decode_nva_data_ir_sbd_2001(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
         else
            decode_nva_data_ir_sbd_2003(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
         end
         
         if (isempty(a_completedBuffer))
            % print what is missing in the buffer
            is_buffer_completed_ir_sbd_nva(1, a_decoderId);
         else
            is_buffer_completed_ir_sbd_nva(0, a_decoderId);
         end
      end
      
      % decode the collected data
      g_decArgo_cycleNum = -1;
      if (a_decoderId == 2001)
         [tabTech, dataCTD, dataHydrau, dataAck, deepCycle] = ...
            decode_nva_data_ir_sbd_2001(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      else
         [tabTech, dataCTD, dataHydrau, dataAck, deepCycle] = ...
            decode_nva_data_ir_sbd_2003(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      end
      if (g_decArgo_cycleNum == -1)
         return
      end
      
      if (g_decArgo_ackPacket == 0)
         fprintf('Cycle #%d\n', g_decArgo_cycleNum);
      else
         fprintf('Acknowledgment packet\n');
         g_decArgo_cycleNum = g_decArgo_cycleNumPrev;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      % assign the current configuration to the decoded cycle
      if (~isempty(deepCycle))
         set_float_config_ir_sbd_nva(g_decArgo_cycleNum, deepCycle);
      end
      
      if (deepCycle == 1)
         if (g_decArgo_firstDeepCycleDone == 0)
            update_float_config_ir_sbd_nva([]);
         end
         g_decArgo_firstDeepCycleDone = 1;
      end

      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct = add_cycle_number_in_report_struct(g_decArgo_reportStruct, g_decArgo_cycleNum);
      end

      % update float configuration for the next cycles
      if (~isempty(dataAck))
         update_float_config_ir_sbd_nva(dataAck);
      end
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd_nva(a_sbdFileNameList, a_decoderId);
      
      % compute the main dates of the cycle
      if (a_decoderId == 2001)
         [cycleStartDate, cycleStartDateAdj, ...
            descentToParkStartDate, descentToParkStartDateAdj, ...
            firstStabDate, firstStabDateAdj, firstStabPres, ...
            descentToParkEndDate, descentToParkEndDateAdj, ...
            descentToProfStartDate, descentToProfStartDateAdj, ...
            descentToProfEndDate, descentToProfEndDateAdj, ...
            ascentStartDate, ascentStartDateAdj, ...
            ascentEndDate, ascentEndDateAdj, ...
            gpsDate, gpsDateAdj, ...
            firstMessageDate, lastMessageDate, ...
            floatClockDrift] = compute_nva_dates_2001_2002(tabTech, deepCycle);
      else
         [cycleStartDate, cycleStartDateAdj, ...
            descentToParkStartDate, descentToParkStartDateAdj, ...
            firstStabDate, firstStabDateAdj, firstStabPres, ...
            descentToParkEndDate, descentToParkEndDateAdj, ...
            descentToProfStartDate, descentToProfStartDateAdj, ...
            descentToProfEndDate, descentToProfEndDateAdj, ...
            ascentStartDate, ascentStartDateAdj, ...
            ascentEndDate, ascentEndDateAdj, ...
            gpsDate, gpsDateAdj, ...
            firstMessageDate, lastMessageDate, ...
            floatClockDrift] = compute_nva_dates_2003(tabTech, deepCycle);
      end
      
      % store GPS data
      if (a_decoderId == 2001)
         store_gps_data_ir_sbd_nva_2001_2002(tabTech);
      else
         store_gps_data_ir_sbd_nva_2003(tabTech);
      end
      
      % create descending and ascending profiles
      [descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
         ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal] = ...
         create_nva_profile_2001_2003(dataCTD, descentToParkStartDateAdj, ascentStartDateAdj);
      
      % create drift data set
      [parkDate, parkDateAdj, parkTransDate, ...
         parkPres, parkTemp, parkSal] = ...
         create_nva_drift_2001_2003(dataCTD, descentToParkEndDateAdj, descentToProfStartDateAdj, tabTech);
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         if (a_decoderId == 2001)
            print_tech_data_in_csv_file_2001(tabTech, a_decoderId);
         else
            print_tech_data_in_csv_file_2003(tabTech, a_decoderId);
         end
         
         % print dated data in CSV file
         print_dates_in_csv_file_nva( ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            dataHydrau);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_2001_2003( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_2001_2003( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_2001_2003( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal);
         
         % print hydraulic data in CSV file
         print_hydrau_data_in_csv_file_nva(dataHydrau, cycleStartDate, floatClockDrift);
         
         % print acknowlegment data in CSV file
         print_ack_data_in_csv_file_nva(dataAck);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTD))
            
            [tabProfiles] = process_profiles_2001_2003( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDateAdj, ascentEndDateAdj, firstMessageDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd_nva(tabProfiles, a_decoderId);
            
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
         [tabTrajNMeas, tabTrajNCycle, tabTechAuxNMeas] = process_trajectory_data_2001_2003( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkDateAdj, parkTransDate, parkPres, parkTemp, parkSal, ...
            dataHydrau);
         
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
         o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {2002} % Dova 2.0
      
      if (isempty(a_completedBuffer) || (a_completedBuffer == 0))
         
         % initialize information arrays
         g_decArgo_1TypePacketReceived = 0;
         g_decArgo_5TypePacketReceived = 0;
         g_decArgo_nbOf2To4TypePacketExpected = -1;
         g_decArgo_nbOf10To29TypePacketExpected = -1;
         g_decArgo_nbOf30To49TypePacketExpected = -1;
         g_decArgo_nbOf50To55TypePacketExpected = -1;
         g_decArgo_nbOf2To4TypePacketReceived = 0;
         g_decArgo_nbOf10To29TypePacketReceived = 0;
         g_decArgo_nbOf30To49TypePacketReceived = 0;
         g_decArgo_nbOf50To55TypePacketReceived = 0;
         
         % roughly check the received data
         decode_nva_data_ir_sbd_2002(sbdDataData, sbdDataDate, 0, g_decArgo_firstDeepCycleDone);
         
         if (isempty(a_completedBuffer))
            % print what is missing in the buffer
            is_buffer_completed_ir_sbd_nva(1, a_decoderId);
         else
            is_buffer_completed_ir_sbd_nva(0, a_decoderId);
         end
      end
      
      % decode the collected data
      g_decArgo_cycleNum = -1;
      [tabTech, dataCTDO, dataHydrau, dataAck, deepCycle] = ...
         decode_nva_data_ir_sbd_2002(sbdDataData, sbdDataDate, 1, g_decArgo_firstDeepCycleDone);
      if (g_decArgo_cycleNum == -1)
         return
      end
      
      if (~isempty(a_completedBuffer))
         
         if (a_completedBuffer == 0)
            % print what is missing in the buffer
            is_buffer_completed_ir_sbd_nva(1, a_decoderId);
         end
      else
         
         % decode from buffer list mode
         is_buffer_completed_ir_sbd_nva(0, a_decoderId);
      end
      
      if (g_decArgo_ackPacket == 0)
         fprintf('Cycle #%d\n', g_decArgo_cycleNum);
      else
         fprintf('Acknowledgment packet\n');
         g_decArgo_cycleNum = g_decArgo_cycleNumPrev;
      end
      g_decArgo_cycleNumPrev = g_decArgo_cycleNum;
      
      % assign the current configuration to the decoded cycle
      if (~isempty(deepCycle))
         set_float_config_ir_sbd_nva(g_decArgo_cycleNum, deepCycle);
      end
      
      if (deepCycle == 1)
         if (g_decArgo_firstDeepCycleDone == 0)
            update_float_config_ir_sbd_nva([]);
         end
         g_decArgo_firstDeepCycleDone = 1;
      end
      
      if (g_decArgo_realtimeFlag == 1)
         % update the reports structure cycle list
         g_decArgo_reportStruct = add_cycle_number_in_report_struct(g_decArgo_reportStruct, g_decArgo_cycleNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(dataAck))
         update_float_config_ir_sbd_nva(dataAck);
      end
      
      % assign cycle number to Iridium mails currently processed
      update_mail_data_ir_sbd_nva(a_sbdFileNameList, a_decoderId);
      
      % compute the main dates of the cycle
      [cycleStartDate, cycleStartDateAdj, ...
         descentToParkStartDate, descentToParkStartDateAdj, ...
         firstStabDate, firstStabDateAdj, firstStabPres, ...
         descentToParkEndDate, descentToParkEndDateAdj, ...
         descentToProfStartDate, descentToProfStartDateAdj, ...
         descentToProfEndDate, descentToProfEndDateAdj, ...
         ascentStartDate, ascentStartDateAdj, ...
         ascentEndDate, ascentEndDateAdj, ...
         gpsDate, gpsDateAdj, ...
         firstMessageDate, lastMessageDate, ...
         floatClockDrift] = compute_nva_dates_2001_2002(tabTech, deepCycle);
      
      % store GPS data
      store_gps_data_ir_sbd_nva_2001_2002(tabTech);
      
      % create descending and ascending profiles
      [descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, descProfTempDoxy, descProfPhaseDelayDoxy, ...
         ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ascProfTempDoxy, ascProfPhaseDelayDoxy] = ...
         create_nva_profile_2002(dataCTDO, descentToParkStartDateAdj, ascentStartDateAdj);
      
      % create drift data set
      [parkDate, parkDateAdj, parkTransDate, ...
         parkPres, parkTemp, parkSal, parkTempDoxy, parkPhaseDelayDoxy] = ...
         create_nva_drift_2002(dataCTDO, descentToParkEndDateAdj, descentToProfStartDateAdj, tabTech);
      
      % compute DOXY
      descProfDoxy = [];
      parkDoxy = [];
      ascProfDoxy = [];
      if (~isempty(dataCTDO))
         [descProfDoxy] = compute_DOXY_SBE_209_2002( ...
            descProfPhaseDelayDoxy, descProfTempDoxy, ...
            descProfPres, descProfTemp, descProfSal);
         [parkDoxy] = compute_DOXY_SBE_209_2002( ...
            parkPhaseDelayDoxy, parkTempDoxy, ...
            parkPres, parkTemp, parkSal);
         [ascProfDoxy] = compute_DOXY_SBE_209_2002( ...
            ascProfPhaseDelayDoxy, ascProfTempDoxy, ...
            ascProfPres, ascProfTemp, ascProfSal);
      end
      
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print float technical messages in CSV file
         print_tech_data_in_csv_file_2002(tabTech, a_decoderId);
         
         % print dated data in CSV file
         print_dates_in_csv_file_nva( ...
            descProfDate, descProfDateAdj, descProfPres, ...
            parkDate, parkDateAdj, parkPres, ...
            ascProfDate, ascProfDateAdj, ascProfPres, ...
            dataHydrau);
         
         % print descending profile in CSV file
         print_descending_profile_in_csv_file_2002( ...
            descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
            descProfTempDoxy, descProfPhaseDelayDoxy, descProfDoxy);
         
         % print drift measurements in CSV file
         print_drift_measurements_in_csv_file_2002( ...
            parkDate, parkDateAdj, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkTempDoxy, parkPhaseDelayDoxy, parkDoxy);
         
         % print ascending profile in CSV file
         print_ascending_profile_in_csv_file_2002( ...
            ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfTempDoxy, ascProfPhaseDelayDoxy, ascProfDoxy);
         
         % print hydraulic data in CSV file
         print_hydrau_data_in_csv_file_nva(dataHydrau, cycleStartDate, floatClockDrift);
         
         % print acknowlegment data in CSV file
         print_ack_data_in_csv_file_nva(dataAck);
         
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         tabProfiles = [];
         if (~isempty(dataCTDO))
            
            [tabProfiles] = process_profiles_2002( ...
               descProfDate, descProfDateAdj, descProfPres, descProfTemp, descProfSal, ...
               descProfTempDoxy, descProfPhaseDelayDoxy, descProfDoxy, ...
               ascProfDate, ascProfDateAdj, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfTempDoxy, ascProfPhaseDelayDoxy, ascProfDoxy, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               descentToParkStartDateAdj, ascentEndDateAdj, firstMessageDate, tabTech, a_decoderId);
            
            % add the vertical sampling scheme from configuration
            % information
            [tabProfiles] = add_vertical_sampling_scheme_ir_sbd_nva(tabProfiles, a_decoderId);
            
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
         [tabTrajNMeas, tabTrajNCycle, tabTechAuxNMeas] = process_trajectory_data_2002( ...
            g_decArgo_cycleNum, deepCycle, ...
            g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
            tabTech, ...
            tabProfiles, ...
            parkDate, parkDateAdj, parkTransDate, parkPres, parkTemp, parkSal, ...
            parkTempDoxy, parkPhaseDelayDoxy, parkDoxy, ...
            dataHydrau);
         
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
         o_tabTechAuxNMeas = [o_tabTechAuxNMeas tabTechAuxNMeas];
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
