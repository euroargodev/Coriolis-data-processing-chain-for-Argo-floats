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

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;
g_decArgo_cycleNumListForIce = [];
g_decArgo_cycleNumListIceDetected = [];

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% minimum duration of a subsurface period
global g_decArgo_minSubSurfaceCycleDuration;
MIN_SUB_CYCLE_DURATION_IN_DAYS = g_decArgo_minSubSurfaceCycleDuration/24;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;
g_decArgo_7TypePacketReceivedCyNum = [];

% date of last ICE detection
global g_decArgo_lastDetectionDate;
g_decArgo_lastDetectionDate = [];

% ICE float firmware
global g_decArgo_floatFirmware;


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
      
      add_to_list(mailFileName, 'spool');
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
         
         add_to_list(mailFileName, 'spool');
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

% if (g_decArgo_realtimeFlag)
%
%    % process mail files according to stored buffers
%
%    % read the buffer list file
%    [mailFileNameList, mailFileRank, mailFileCyNum] = ...
%       read_buffer_list_delayed(a_floatNum, g_decArgo_historyDirectory);
%
%    uRank = sort(unique(mailFileRank));
%    for idRk = 1:length(uRank)
%       rankNum = uRank(idRk);
%       idFileList = find(mailFileRank == rankNum);
%       cycleNumberList = unique(mailFileCyNum(idFileList));
%
%       fprintf('BUFFER #%d: processing %d sbd files\n', rankNum, length(unique(mailFileNameList(idFileList))));
%
%       [~, idUnique, ~] = unique(mailFileNameList(idFileList));
%       idFileList = idFileList(idUnique);
%       for idF = 1:length(idFileList)
%
%          % move the next file into the buffer directory
%          add_to_list(mailFileNameList{idFileList(idF)}, 'buffer');
%          remove_from_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'spool', 0, 1);
%
%          % extract the attachement
%          [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
%             mailFileNameList{idFileList(idF)}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
%          g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
%          if (attachmentFound == 0)
%             remove_from_list_ir_sbd(mailFileNameList{idFileList(idF)}, 'buffer', 1, 1);
%          end
%       end
%
%       % process the files of the buffer directory
%
%       % retrieve information on the files in the buffer
%       [tabFileNames, ~, tabFileDates, tabFileSizes] = ...
%          get_list_files_info_ir_sbd('buffer', '');
%
%       [o_tabProfiles, ...
%          o_tabTrajNMeas, o_tabTrajNCycle, ...
%          o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%          decode_sbd_files_delayed( ...
%          tabFileNames, tabFileDates, tabFileSizes, ...
%          a_decoderId, a_refDay, cycleNumberList, 0, 0, ...
%          o_tabProfiles, ...
%          o_tabTrajNMeas, o_tabTrajNCycle, ...
%          o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
%
%       % move the processed files into the archive directory (and delete
%       % the associated SBD files)
%       remove_from_list_ir_sbd(tabFileNames, 'buffer', 1, 1);
%    end
% end

% retrieve information on spool directory contents
[tabAllFileNames, ~, tabAllFileDates, ~] = ...
   get_list_files_info_ir_sbd('spool', '');

% process the mail files of the spool directory in chronological order
% if (g_decArgo_realtimeFlag)
%    bufferRank = 1;
%    if (~isempty(mailFileRank))
%       bufferRank = max(mailFileRank) + 1;
%    end
%    bufferMailFileNames = [];
% end
cycleDecodingDone = [];
cycleNumberListToIgnore = [];
for idSpoolFile = 1:length(tabAllFileNames)
   
   % move the next file into the buffer directory
   add_to_list(tabAllFileNames{idSpoolFile}, 'buffer');
   remove_from_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'spool', 0, 1);
   
   % extract the attachement
   [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
      tabAllFileNames{idSpoolFile}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
   g_decArgo_iridiumMailData = [g_decArgo_iridiumMailData mailContents];
   if (attachmentFound == 0)
      remove_from_list_ir_sbd(tabAllFileNames{idSpoolFile}, 'buffer', 1, 1);
      %       if (g_decArgo_realtimeFlag)
      %          bufferMailFileNames{end+1} = tabAllFileNames{idSpoolFile};
      %       end
      if (idSpoolFile < length(tabAllFileNames))
         continue;
      end
   end
   
   % process the files of the buffer
   
   % retrieve information on the files in the buffer
   [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
      'buffer', '');
   
   % assign a transmission number to the files in the buffer
   tabFileTransNums = set_file_trans_num(tabFileDates, MIN_SUB_CYCLE_DURATION_IN_DAYS);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % look for missing data (this should theoretically never occur anymore)
   if (length(unique(tabFileTransNums)) == 3)
      
      % retrieve information about the first transmission
      idFilesTrans1 = find(tabFileTransNums == 1);
      [cycleNumberListTrans1, bufferCompletedTrans1, ~] = check_received_sbd_files( ...
         tabFileNames(idFilesTrans1), tabFileDates(idFilesTrans1), tabFileSizes(idFilesTrans1), [], a_decoderId);
      
      % check that missing data of the first transmission have been received in
      % the second transmission
      idFilesTrans1And2 = find((tabFileTransNums == 1) | (tabFileTransNums == 2));
      cycleNumberNotCompletedList = cycleNumberListTrans1(find(bufferCompletedTrans1 == 0));
      [cycleNumberList, bufferCompleted, ~] = check_received_sbd_files( ...
         tabFileNames(idFilesTrans1And2), tabFileDates(idFilesTrans1And2), tabFileSizes(idFilesTrans1And2), cycleNumberNotCompletedList, a_decoderId);
      
      % process cycle numbers of the first transmission
      if (ismember(a_decoderId, [212 214]))
         if (any(bufferCompleted == 0) && ~strcmp(g_decArgo_floatFirmware, '5900A03'))
            cycleNumberNotCompletedList = cycleNumberList(find(bufferCompleted == 0));
            for idCy = 1:length(cycleNumberNotCompletedList)
               
               if (~ismember(cycleNumberNotCompletedList(idCy), cycleDecodingDone))
                  cycleListStr = sprintf('%d,', cycleNumberNotCompletedList);
                  % all data to be transmitted should be received since firmware version
                  % 5900A04
                  fprintf('ERROR: Float #%d: this should never occur (for firmware >= 5900A04): missing data for cycle(s): %s => processing received data\n', ...
                     g_decArgo_floatNum, ...
                     cycleListStr(1:end-1));
               else
                  fprintf('WARNING: Float #%d: additional data received for cycle #%d => ignored\n', ...
                     g_decArgo_floatNum, ...
                     cycleNumberNotCompletedList(idCy));
                  
                  cycleNumberListTrans1 = setdiff(cycleNumberNotCompletedList(idCy), cycleNumberListTrans1);
                  cycleNumberListToIgnore = cycleNumberNotCompletedList;
                  
                  % move the first transmission files into the archive directory
                  % (and delete the associated SBD files)
                  remove_from_list_ir_sbd(tabFileNames(idFilesTrans1), 'buffer', 1, 1);
               end
            end
         end
      end
      
      if (~isempty(cycleNumberListTrans1))
         [o_tabProfiles, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
            decode_sbd_files_delayed( ...
            tabFileNames(idFilesTrans1And2), tabFileDates(idFilesTrans1And2), tabFileSizes(idFilesTrans1And2), ...
            a_decoderId, a_refDay, cycleNumberListTrans1, any(bufferCompleted == 0), 1, ...
            o_tabProfiles, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
         cycleNumberListToIgnore = cycleNumberListTrans1;
         cycleDecodingDone = [cycleDecodingDone cycleNumberListTrans1];
         
         %       if (g_decArgo_realtimeFlag)
         %          bufferMailFileNames = [bufferMailFileNames tabFileNames(idFilesTrans1And2)];
         %          write_buffer_list_ir_sbd_delayed(a_floatNum, bufferRank, bufferMailFileNames, cycleNumberListTrans1);
         %          bufferRank = bufferRank + 1;
         %          bufferMailFileNames = [];
         %       end
         
         % move the first transmission files into the archive directory
         % (and delete the associated SBD files)
         remove_from_list_ir_sbd(tabFileNames(idFilesTrans1), 'buffer', 1, 1);
      end
      
      % retrieve information on the files in the buffer
      [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
         'buffer', '');
      
      % assign a transmission number to the files in the buffer
      tabFileTransNums = set_file_trans_num(tabFileDates, MIN_SUB_CYCLE_DURATION_IN_DAYS);
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (length(unique(tabFileTransNums)) == 2)
      
      % retrieve information about the first transmission
      idFilesTrans1 = find(tabFileTransNums == 1);
      [cycleNumberListTrans1, bufferCompletedTrans1, ~] = check_received_sbd_files( ...
         tabFileNames(idFilesTrans1), tabFileDates(idFilesTrans1), tabFileSizes(idFilesTrans1), [], a_decoderId);
      
      % ignore data of cycleNumberListToIgnore list (they have been already
      % processed)
      idF = find(ismember(cycleNumberListTrans1, cycleNumberListToIgnore) == 1);
      cycleNumberListTrans1(idF) = [];
      bufferCompletedTrans1(idF) = [];
      
      if (~any(bufferCompletedTrans1 == 0))
         
         % the buffer of the first transmission is completed
         [o_tabProfiles, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
            decode_sbd_files_delayed( ...
            tabFileNames(idFilesTrans1), tabFileDates(idFilesTrans1), tabFileSizes(idFilesTrans1), ...
            a_decoderId, a_refDay, cycleNumberListTrans1, 0, 0, ...
            o_tabProfiles, ...
            o_tabTrajNMeas, o_tabTrajNCycle, ...
            o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
         cycleDecodingDone = [cycleDecodingDone cycleNumberListTrans1];
         
         %          if (g_decArgo_realtimeFlag)
         %             bufferMailFileNames = [bufferMailFileNames tabFileNames(idFilesTrans1)];
         %             write_buffer_list_ir_sbd_delayed(a_floatNum, bufferRank, bufferMailFileNames, cycleNumberListTrans1);
         %             bufferRank = bufferRank + 1;
         %             bufferMailFileNames = [];
         %          end
         
         % move the first transmission files into the archive directory
         % (and delete the associated SBD files)
         remove_from_list_ir_sbd(tabFileNames(idFilesTrans1), 'buffer', 1, 1);
         
         % retrieve information on the files in the buffer
         [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
            'buffer', '');
         
         % assign a transmission number to the files in the buffer
         tabFileTransNums = set_file_trans_num(tabFileDates, MIN_SUB_CYCLE_DURATION_IN_DAYS);
         
      else
         
         % the buffer of the first transmission is not completed check with the
         % second transmission data
         idFilesTrans1And2 = find((tabFileTransNums == 1) | (tabFileTransNums == 2));
         [cycleNumberListTrans1And2, bufferCompletedTrans1And2, ~] = check_received_sbd_files( ...
            tabFileNames(idFilesTrans1And2), tabFileDates(idFilesTrans1And2), tabFileSizes(idFilesTrans1And2), cycleNumberListTrans1, a_decoderId);
         
         % ignore data of cycleNumberListToIgnore list (they have been
         % already processed)
         idF = find(ismember(cycleNumberListTrans1And2, cycleNumberListToIgnore) == 1);
         cycleNumberListTrans1And2(idF) = [];
         bufferCompletedTrans1And2(idF) = [];
         
         if (~any(bufferCompletedTrans1And2 == 0))
            
            % the buffer of the first transmission is completed
            [o_tabProfiles, ...
               o_tabTrajNMeas, o_tabTrajNCycle, ...
               o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
               decode_sbd_files_delayed( ...
               tabFileNames(idFilesTrans1And2), tabFileDates(idFilesTrans1And2), tabFileSizes(idFilesTrans1And2), ...
               a_decoderId, a_refDay, cycleNumberListTrans1, 0, 1, ...
               o_tabProfiles, ...
               o_tabTrajNMeas, o_tabTrajNCycle, ...
               o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
            cycleNumberListToIgnore = cycleNumberListTrans1;
            cycleDecodingDone = [cycleDecodingDone cycleNumberListTrans1];
            
            %             if (g_decArgo_realtimeFlag)
            %                bufferMailFileNames = [bufferMailFileNames tabFileNames(idFilesTrans1And2)];
            %                write_buffer_list_ir_sbd_delayed(a_floatNum, bufferRank, bufferMailFileNames, cycleNumberListTrans1);
            %                bufferRank = bufferRank + 1;
            %                bufferMailFileNames = [];
            %             end
            
            % move the first transmission files into the archive directory
            % (and delete the associated SBD files)
            remove_from_list_ir_sbd(tabFileNames(idFilesTrans1), 'buffer', 1, 1);
            
            % retrieve information on the files in the buffer
            [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
               'buffer', '');
            
            % assign a transmission number to the files in the buffer
            tabFileTransNums = set_file_trans_num(tabFileDates, MIN_SUB_CYCLE_DURATION_IN_DAYS);
            
         else
            
            if ((~g_decArgo_realtimeFlag) && (idSpoolFile == length(tabAllFileNames)))
               
               % with the PI decoder process all received data even if the
               % buffer is not completed
               [o_tabProfiles, ...
                  o_tabTrajNMeas, o_tabTrajNCycle, ...
                  o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
                  decode_sbd_files_delayed( ...
                  tabFileNames(idFilesTrans1And2), tabFileDates(idFilesTrans1And2), tabFileSizes(idFilesTrans1And2), ...
                  a_decoderId, a_refDay, cycleNumberListTrans1, 1, 1, ...
                  o_tabProfiles, ...
                  o_tabTrajNMeas, o_tabTrajNCycle, ...
                  o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
               cycleNumberListToIgnore = cycleNumberListTrans1;
               cycleDecodingDone = [cycleDecodingDone cycleNumberListTrans1];
               
               % move the first transmission files into the archive directory
               % (and delete the associated SBD files)
               remove_from_list_ir_sbd(tabFileNames(idFilesTrans1), 'buffer', 1, 1);
               
               % retrieve information on the files in the buffer
               [tabFileNames, ~, tabFileDates, tabFileSizes] = get_list_files_info_ir_sbd( ...
                  'buffer', '');
               
               % assign a transmission number to the files in the buffer
               tabFileTransNums = set_file_trans_num(tabFileDates, MIN_SUB_CYCLE_DURATION_IN_DAYS);
            else
               % the buffer of the first transmission is not completed
               % additional data is needed
               continue;
            end
         end
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (length(unique(tabFileTransNums)) == 1)
      
      % retrieve information about the transmission
      idFilesTrans1 = find(tabFileTransNums == 1);
      [cycleNumberListTrans1, bufferCompletedTrans1, firstDateNextBuffer] = check_received_sbd_files( ...
         tabFileNames(idFilesTrans1), tabFileDates(idFilesTrans1), tabFileSizes(idFilesTrans1), [], a_decoderId);
      
      nbLoops = 1;
      if (~isempty(firstDateNextBuffer))
         nbLoops = 2;
      end
      
      for idL = 1:nbLoops
         
         idFiles = 1:length(idFilesTrans1);
         if (~isempty(firstDateNextBuffer))
            if (idL == 1)
               idFiles = find(tabFileDates(idFilesTrans1) < firstDateNextBuffer);
            else
               idFiles = find(tabFileDates(idFilesTrans1) >= firstDateNextBuffer);
            end
         end
         
         % ignore data of cycleNumberListToIgnore list (they have been already
         % processed)
         idF = find(ismember(cycleNumberListTrans1, cycleNumberListToIgnore) == 1);
         cycleNumberListTrans1(idF) = [];
         bufferCompletedTrans1(idF) = [];
         
         if (~any(bufferCompletedTrans1 == 0))
            
            % the buffer of the transmission is completed
            [o_tabProfiles, ...
               o_tabTrajNMeas, o_tabTrajNCycle, ...
               o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
               decode_sbd_files_delayed( ...
               tabFileNames(idFilesTrans1(idFiles)), tabFileDates(idFilesTrans1(idFiles)), tabFileSizes(idFilesTrans1(idFiles)), ...
               a_decoderId, a_refDay, cycleNumberListTrans1, 0, (length(cycleNumberListTrans1) > 1), ...
               o_tabProfiles, ...
               o_tabTrajNMeas, o_tabTrajNCycle, ...
               o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
            cycleDecodingDone = [cycleDecodingDone cycleNumberListTrans1];
            
            %             if (g_decArgo_realtimeFlag)
            %                bufferMailFileNames = [bufferMailFileNames tabFileNames(idFilesTrans1(idFiles))];
            %                write_buffer_list_ir_sbd_delayed(a_floatNum, bufferRank, bufferMailFileNames, cycleNumberListTrans1);
            %                bufferRank = bufferRank + 1;
            %                bufferMailFileNames = [];
            %             end
            
            % move the first transmission files into the archive directory
            % (and delete the associated SBD files)
            remove_from_list_ir_sbd(tabFileNames(idFilesTrans1(idFiles)), 'buffer', 1, 1);
            
         else
            
            if ((~g_decArgo_realtimeFlag) && (idSpoolFile == length(tabAllFileNames)))
               
               % with the PI decoder process all received data even if the
               % buffer is not completed
               [o_tabProfiles, ...
                  o_tabTrajNMeas, o_tabTrajNCycle, ...
                  o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
                  decode_sbd_files_delayed( ...
                  tabFileNames(idFilesTrans1(idFiles)), tabFileDates(idFilesTrans1(idFiles)), tabFileSizes(idFilesTrans1(idFiles)), ...
                  a_decoderId, a_refDay, cycleNumberListTrans1, 1, (length(cycleNumberListTrans1) > 1), ...
                  o_tabProfiles, ...
                  o_tabTrajNMeas, o_tabTrajNCycle, ...
                  o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas);
               cycleDecodingDone = [cycleDecodingDone cycleNumberListTrans1];
               
               % move the first transmission files into the archive directory
               % (and delete the associated SBD files)
               remove_from_list_ir_sbd(tabFileNames(idFilesTrans1(idFiles)), 'buffer', 1, 1);
            else
               % the buffer of the first transmission is not completed
               % additional data is needed
               continue;
            end
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
   
   % update N_CYCLE arrays so that N_CYCLE and N_MEASUREMENT arrays are
   % consistency
   [o_tabTrajNCycle] = set_n_cycle_vs_n_meas_consistency(o_tabTrajNCycle, o_tabTrajNMeas);
   
   % add ICE detected flag in TECH variables and finalize TECH data
   [o_tabNcTechIndex, o_tabNcTechVal] = finalize_technical_data_ir_sbd( ...
      o_tabNcTechIndex, o_tabNcTechVal, a_decoderId);
   
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

return;
