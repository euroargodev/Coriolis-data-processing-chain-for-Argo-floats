% ------------------------------------------------------------------------------
% Check all SBD files transmitted by NKE ICE floats.
%
% SYNTAX :
%   check_provor_sbd_files or check_provor_sbd_files(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of PROVOR floats to be decoded
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/26/2018 - RNU - creation
% ------------------------------------------------------------------------------
function check_provor_sbd_files(varargin)

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% current float WMO number
global g_decArgo_floatNum;

% decoder configuration values
global g_decArgo_iridiumDataDirectory;

% default values
global g_decArgo_dateDef;

% SBD sub-directories
global g_decArgo_archiveDirectory;
global g_decArgo_archiveSbdDirectory;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% offset in cycle number (in case of reset of the float)
global g_decArgo_cycleNumOffset;
g_decArgo_cycleNumOffset = 0;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;

% for debug purpose (check_provor_sbd_files)
global g_decArgo_debugFlag;
g_decArgo_debugFlag = 1;
global g_decArgo_debugResetTimeList;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'IRIDIUM_DATA_DIRECTORY';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};
g_decArgo_iridiumDataDirectory = configVal{3};

if (nargin == 0)
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return;
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_CSV_FILE '/' 'check_provor_sbd_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'check_provor_sbd_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['WMO #; Cycle #; Info type'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   g_decArgo_cycleNumOffset = 0;
   g_decArgo_debugResetTimeList = [];
   floatNum = floatList(idFloat);
   g_decArgo_floatNum = floatNum;
   fprintf('\n%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d => nothing done\n', floatNum);
      continue;
   end
   
   floatArgosId = str2double(char(listArgosId(idF)));
   floatDecId = listDecId(idF);
   floatLaunchDate = listLaunchDate(idF);
   floatEndDate = listEndDate(idF);
   
   floatIriDirName = [g_decArgo_iridiumDataDirectory '/' num2str(floatArgosId) '_' num2str(floatNum) '/'];
   g_decArgo_archiveDirectory = [floatIriDirName 'archive/'];
   g_decArgo_archiveSbdDirectory = [floatIriDirName 'archive/sbd/'];
   if (exist(g_decArgo_archiveSbdDirectory, 'dir') == 7)
      rmdir(g_decArgo_archiveSbdDirectory, 's');
   end
   mkdir(g_decArgo_archiveSbdDirectory);
   
   [tabMailFileNames, ~, tabMailFileDates, ~] = get_dir_files_info_ir_sbd( ...
      g_decArgo_archiveDirectory, floatArgosId, 'txt', floatLaunchDate);
   
   % arrays to collect all transmitted data
   sbdDataDate = [];
   sbdDataData = [];
   for idMailFile = 1:length(tabMailFileNames)
      
      % consider only mail received during float mission
      if (tabMailFileDates(idMailFile) < floatLaunchDate)
         fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated before float launch date (%s)\n', ...
            floatNum, ...
            tabMailFileNames{idMailFile}, julian_2_gregorian_dec_argo(floatLaunchDate));
         continue
      end
      
      if (floatEndDate ~= g_decArgo_dateDef)
         if (tabMailFileDates(idMailFile) > floatLaunchDate)
            fprintf('BUFF_WARNING: Float #%d: mail file "%s" ignored because dated after float end date (%s)\n', ...
               floatNum, ...
               tabMailFileNames{idMailFile}, julian_2_gregorian_dec_argo(floatLaunchDate));
            continue
         end
      end
      
      % extract the attachement
      [mailContents, attachmentFound] = read_mail_and_extract_attachment( ...
         tabMailFileNames{idMailFile}, g_decArgo_archiveDirectory, g_decArgo_archiveSbdDirectory);
      if (attachmentFound == 0)
         fprintf(fidOut, '%d;%s;no attachment\n', floatNum, tabMailFileNames{idMailFile});
         continue;
      end
      
      % read the SBD data
      sbdFileName = regexprep(tabMailFileNames{idMailFile}, '.txt', '.sbd');
      sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
      
      sbdData = [];
      file = dir(sbdFilePathName);
      fileSize = file(1).bytes;
      if (rem(fileSize, 100) == 0)
         fId = fopen(sbdFilePathName, 'r');
         if (fId == -1)
            fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
               floatNum, ...
               sbdFilePathName);
         end
         sbdData = fread(fId);
         fclose(fId);
         
         sbdData = reshape(sbdData, 100, size(sbdData, 1)/100)';
         for idMsg = 1:size(sbdData, 1)
            data = sbdData(idMsg, :);
            if (~isempty(find(data ~= 0, 1)))
               sbdDataData = [sbdDataData; data];
               sbdDataDate = [sbdDataDate; tabMailFileDates(idMailFile)];
            end
         end
      else
         fprintf('DEC_WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes) : %s\n', ...
            floatNum, ...
            fileSize, ...
            sbdFilePathName);
         
         fprintf(fidOut, '%d;%s;unexpected size (%d bytes)\n', ...
            floatNum, tabMailFileNames{idMailFile}, fileSize);
         continue;
      end
      
      [sbdInfoStr, sbdCyList] = get_info_raw_decoding_sbd_file(sbdData, ones(size(sbdData, 1) , 1)*tabMailFileDates(idMailFile), floatDecId);
      fprintf(fidOut, '%d;%s;Size: %d bytes;Nb Packets: %d', ...
         floatNum, tabMailFileNames{idMailFile}, fileSize, fileSize/100);
      fprintf(fidOut, '; %s\n', sbdInfoStr);
      
   end
   
   % roughly check SBD data
   switch (floatDecId)
      
      case {212} % Arvor-ARN-Ice Iridium 5.45
         
         % decode the collected data
         decode_prv_data_ir_sbd_212(sbdDataData, sbdDataDate, 0, []);
         
      case {214, 217}
         % Provor-ARN-DO-Ice Iridium 5.75
         % Arvor-ARN-DO-Ice Iridium 5.46
         
         % decode the collected data
         decode_prv_data_ir_sbd_214_217(sbdDataData, sbdDataDate, 0, []);
         
      case {216} % Arvor-Deep-Ice Iridium 5.65
         
         % decode the collected data
         decode_prv_data_ir_sbd_216(sbdDataData, sbdDataDate, 0, []);
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing implemented yet in check_provor_sbd_files for decoderId #%d\n', ...
            floatNum, ...
            floatDecId);
   end
   
   g_decArgo_7TypePacketReceivedCyNum = [];
   [cycleNumberList, bufferCompletedList] = is_buffer_completed_ir_sbd_delayed(0, [], [], floatDecId);
   
   uCyNumList = unique([0:max(cycleNumberList)]);
   for idCy = 1:length(uCyNumList)
      idForCy = find(cycleNumberList == uCyNumList(idCy));
      if (isempty(idForCy))
         fprintf('Float #%d: Cycle #%d : NO DATA\n', ...
            floatNum, uCyNumList(idCy));
      else
         delayedStr = '';
         if (any(find(cycleNumberList(1:min(idForCy)-1) > uCyNumList(idCy))))
            delayedStr = '-DELAYED- ';
         end
         bufferCompleted = unique(bufferCompletedList(idForCy));
         if (bufferCompleted == 1)
            fprintf('Float #%d: Cycle #%d : %scompleted buffer\n', ...
               floatNum, uCyNumList(idCy), delayedStr);
         else
            fprintf('Float #%d: Cycle #%d : %sNOT COMPLETED BUFFER\n', ...
               floatNum, uCyNumList(idCy), delayedStr);
            
            is_buffer_completed_ir_sbd_delayed(1, [], uCyNumList(idCy), floatDecId);
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received) for a given list of cycle numbers.
%
% SYNTAX :
%  [o_cycleNumberList, o_bufferCompleted] = ...
%    is_buffer_completed_ir_sbd_delayed(a_whyFlag, a_cycleDecodingDoneList, a_decoderId)
%
% INPUT PARAMETERS :
%   a_whyFlag               : print information on incompleted buffers
%   a_cycleDecodingDoneList : list of already decoded cycles
%   a_decoderId             : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cycleNumberList : list of cycle numbers data in the buffer
%   o_cycleNumberList : associated list of completed buffer flags
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleNumberList, o_bufferCompleted] = ...
   is_buffer_completed_ir_sbd_delayed(a_whyFlag, a_cycleDecodingDoneList, a_whyCycle, a_decoderId)

% output parameters initialization
o_cycleNumberList = [];
o_bufferCompleted = [];

% current float WMO number
global g_decArgo_floatNum;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketExpectedFlag;
global g_decArgo_7TypePacketReceivedFlag;
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
global g_decArgo_nbOf6TypePacketReceived;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;

% float configuration
global g_decArgo_floatConfig;

% flag to mention that there is only a parameter packet #2 in the buffer
global g_decArgo_processingOnly7TypePacketFlag;
g_decArgo_processingOnly7TypePacketFlag = [];

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {212, 214, 217}
      % Arvor-ARN-Ice Iridium 5.45
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      % adjust the size of the variables
      g_decArgo_0TypePacketReceivedFlag = [g_decArgo_0TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_0TypePacketReceivedFlag))];
      g_decArgo_4TypePacketReceivedFlag = [g_decArgo_4TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_4TypePacketReceivedFlag))];
      g_decArgo_5TypePacketReceivedFlag = [g_decArgo_5TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_5TypePacketReceivedFlag))];
      g_decArgo_nbOf1Or8TypePacketExpected = [g_decArgo_nbOf1Or8TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketExpected))*-1];
      g_decArgo_nbOf1Or8TypePacketReceived = [g_decArgo_nbOf1Or8TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketReceived))];
      g_decArgo_nbOf2Or9TypePacketExpected = [g_decArgo_nbOf2Or9TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketExpected))*-1];
      g_decArgo_nbOf2Or9TypePacketReceived = [g_decArgo_nbOf2Or9TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketReceived))];
      g_decArgo_nbOf3Or10TypePacketExpected = [g_decArgo_nbOf3Or10TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketExpected))*-1];
      g_decArgo_nbOf3Or10TypePacketReceived = [g_decArgo_nbOf3Or10TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketReceived))];
      g_decArgo_nbOf13Or11TypePacketExpected = [g_decArgo_nbOf13Or11TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketExpected))*-1];
      g_decArgo_nbOf13Or11TypePacketReceived = [g_decArgo_nbOf13Or11TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketReceived))];
      g_decArgo_nbOf14Or12TypePacketExpected = [g_decArgo_nbOf14Or12TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketExpected))*-1];
      g_decArgo_nbOf14Or12TypePacketReceived = [g_decArgo_nbOf14Or12TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketReceived))];
      
      % we must know if parameter packet #2 is expected (and for which cycles)
      
      % we first check if ICE mode is activated
      if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
         
         % if one parameter packet #2 has been received, it means that the ICE mode
         % is activated
         
         % if IC0 = 0, the ice detection algorithm is disabled and parameter #2 packet
         % (type 7) is not sent by the float
         
         % retrieve temporary information
         configTmpCycles = g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES;
         configTmpDates = g_decArgo_floatConfig.DYNAMIC_TMP.DATES;
         configTmpNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
         configTmpValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES;
         
         % retrieve IC0 configuration parameter index
         idIc00PosTmp = find(strncmp('CONFIG_IC00_', configTmpNames, length('CONFIG_IC00_')) == 1, 1);
         
         % retrieve configuration information
         configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
         configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;
         configCycles = g_decArgo_floatConfig.USE.CYCLE;
         configNumbers = g_decArgo_floatConfig.USE.CONFIG;
         [configCycles, idSort] = sort(configCycles);
         configNumbers = configNumbers(idSort);
         
         % retrieve IC0 configuration parameter index
         idIc00Pos = find(strncmp('CONFIG_IC00_', configNames, length('CONFIG_IC00_')) == 1, 1);
         
         if (~isempty(idIc00PosTmp) && ~isempty(idIc00Pos))
            
            g_decArgo_7TypePacketExpectedFlag = ones(size(g_decArgo_cycleList));
            
            % check for each cycle
            for idCy = 1:length(g_decArgo_cycleList)
               
               if (g_decArgo_cycleList(idCy) < g_decArgo_7TypePacketReceivedCyNum)
                  % ICE mode not activated yet
                  g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
               elseif (g_decArgo_cycleList(idCy) == g_decArgo_7TypePacketReceivedCyNum)
                  % cycle of ICE mode activation
                  g_decArgo_7TypePacketExpectedFlag(idCy) = 1;
               elseif (g_decArgo_cycleList(idCy) == g_decArgo_7TypePacketReceivedCyNum+1)
                  % one cycle afer cycle of ICE mode activation
                  % the IC0 value should be retrieved from temporary
                  % configuration
                  idF = find(configTmpCycles == g_decArgo_7TypePacketReceivedCyNum);
                  if (~isempty(idF))
                     [~, idSort] = sort(configTmpDates(idF));
                     iceNoSurfaceDelay = configTmpValues(idIc00PosTmp, idF(idSort(end)));
                     if (iceNoSurfaceDelay == 0)
                        % ice detection algorithm is disabled => parameter packet
                        % #2 is not expected
                        g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
                     end
                  end
               else
                  % ICE mode activated
                  idF = find(configCycles <= g_decArgo_cycleList(idCy));
                  if (~isempty(idF))
                     configNumber = configNumbers(idF(end));
                     iceNoSurfaceDelay = configValues(idIc00Pos, configNumber+1);
                     if (iceNoSurfaceDelay == 0)
                        % ice detection algorithm is disabled => parameter packet
                        % #2 is not expected
                        g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
                     end
                  else
                     % retrieve IC0 configuration value from launch configuration
                     iceNoSurfaceDelay = configValues(idIc00Pos, 1);
                     if (iceNoSurfaceDelay == 0)
                        % ice detection algorithm is disabled => parameter packet #2 is not
                        % expected
                        g_decArgo_7TypePacketExpectedFlag(idCy) = 0;
                     end
                  end
               end
            end
         else
            g_decArgo_7TypePacketExpectedFlag = zeros(size(g_decArgo_cycleList));
            fprintf('WARNING: Float #%d: unable to retrieve IC00 configuration value => ice detection mode is supposed to be disabled\n', ...
               g_decArgo_floatNum);
         end
      else
         % we don't know if the ICE mode is activated
         % we must wait for the first received parameter packet #2
         g_decArgo_7TypePacketExpectedFlag = zeros(size(g_decArgo_cycleList));
      end
      
      if (isempty(g_decArgo_7TypePacketReceivedFlag))
         g_decArgo_7TypePacketReceivedFlag = zeros(size(g_decArgo_cycleList));
      else
         sevenTypePacketReceivedFlag = zeros(size(g_decArgo_cycleList));
         sevenTypePacketReceivedFlag(find(g_decArgo_7TypePacketReceivedFlag == 1)) = 1;
         g_decArgo_7TypePacketReceivedFlag = sevenTypePacketReceivedFlag;
      end
      
      if (a_whyFlag == 0)
         
         o_cycleNumberList = g_decArgo_cycleList;
         o_bufferCompleted = zeros(size(o_cycleNumberList));
         for cyId = 1:length(g_decArgo_cycleList)
            %             if ( ...
            %                   (g_decArgo_0TypePacketReceivedFlag(cyId) == 1) && ...
            %                   (g_decArgo_4TypePacketReceivedFlag(cyId) == 1) && ...
            %                   (g_decArgo_5TypePacketReceivedFlag(cyId) == 1) && ...
            %                   (g_decArgo_7TypePacketExpectedFlag(cyId) == g_decArgo_7TypePacketReceivedFlag(cyId)) && ...
            %                   (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == g_decArgo_nbOf1Or8TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == g_decArgo_nbOf2Or9TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == g_decArgo_nbOf3Or10TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf13Or11TypePacketExpected(cyId) == g_decArgo_nbOf13Or11TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf14Or12TypePacketExpected(cyId) == g_decArgo_nbOf14Or12TypePacketReceived(cyId)))
            if ( ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == g_decArgo_nbOf1Or8TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == g_decArgo_nbOf2Or9TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == g_decArgo_nbOf3Or10TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf13Or11TypePacketExpected(cyId) == g_decArgo_nbOf13Or11TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf14Or12TypePacketExpected(cyId) == g_decArgo_nbOf14Or12TypePacketReceived(cyId)))
               
               % nominal case
               o_bufferCompleted(cyId) = 1;
               %             elseif ( ...
               %                   ~any(g_decArgo_0TypePacketReceivedFlag ~= 0) && ...
               %                   ~any(g_decArgo_4TypePacketReceivedFlag ~= 0) && ...
               %                   ~any(g_decArgo_5TypePacketReceivedFlag ~= 0) && ...
               %                   ~any(g_decArgo_nbOf1Or8TypePacketExpected ~= -1) && ...
               %                   ~any(g_decArgo_nbOf1Or8TypePacketReceived ~= 0) && ...
               %                   ~any(g_decArgo_nbOf2Or9TypePacketExpected ~= -1) && ...
               %                   ~any(g_decArgo_nbOf2Or9TypePacketReceived ~= 0) && ...
               %                   ~any(g_decArgo_nbOf3Or10TypePacketExpected ~= -1) && ...
               %                   ~any(g_decArgo_nbOf3Or10TypePacketReceived ~= 0) && ...
               %                   ~any(g_decArgo_nbOf13Or11TypePacketExpected ~= -1) && ...
               %                   ~any(g_decArgo_nbOf13Or11TypePacketReceived ~= 0) && ...
               %                   ~any(g_decArgo_nbOf14Or12TypePacketExpected ~= -1) && ...
               %                   ~any(g_decArgo_nbOf14Or12TypePacketReceived ~= 0) && ...
               %                   (g_decArgo_7TypePacketExpectedFlag(cyId) == g_decArgo_7TypePacketReceivedFlag(cyId)) && ...
               %                   (isempty(g_decArgo_nbOf6TypePacketReceived) || ...
               %                   (~isempty(g_decArgo_nbOf6TypePacketReceived) && (g_decArgo_nbOf6TypePacketReceived(cyId) == 0))))
            elseif ( ...
                  ~any(g_decArgo_0TypePacketReceivedFlag ~= 0) && ...
                  ~any(g_decArgo_4TypePacketReceivedFlag ~= 0) && ...
                  ~any(g_decArgo_5TypePacketReceivedFlag ~= 0) && ...
                  ~any(g_decArgo_nbOf1Or8TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf1Or8TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf2Or9TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf2Or9TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf3Or10TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf3Or10TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf13Or11TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf13Or11TypePacketReceived ~= 0) && ...
                  ~any(g_decArgo_nbOf14Or12TypePacketExpected ~= -1) && ...
                  ~any(g_decArgo_nbOf14Or12TypePacketReceived ~= 0) && ...
                  (isempty(g_decArgo_nbOf6TypePacketReceived) || ...
                  (~isempty(g_decArgo_nbOf6TypePacketReceived) && (g_decArgo_nbOf6TypePacketReceived(cyId) == 0))))
               
               % buffer with only parameter packet #2
               o_bufferCompleted(cyId) = 1;
               g_decArgo_processingOnly7TypePacketFlag = zeros(size(g_decArgo_cycleList));
               g_decArgo_processingOnly7TypePacketFlag(cyId) = 1;
            end
         end
         
      else
         
         for cyId = 1:length(g_decArgo_cycleList)
            if (g_decArgo_cycleList(cyId) ~= a_whyCycle)
               continue;
            end
            if (isempty(g_decArgo_0TypePacketReceivedFlag) || ...
                  (length(g_decArgo_0TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #1 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_4TypePacketReceivedFlag) || ...
                  (length(g_decArgo_4TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #2 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_5TypePacketReceivedFlag) || ...
                  (length(g_decArgo_5TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Parameter packet #1 is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            %             if (g_decArgo_7TypePacketReceivedFlag(cyId) ~= g_decArgo_7TypePacketExpectedFlag(cyId))
            %                fprintf('BUFF_INFO: Float #%d Cycle #%d: Parameter packet #2 is missing\n', ...
            %                   g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            %             end
            if (isempty(g_decArgo_nbOf1Or8TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf1Or8TypePacketExpected) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketExpected) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == -1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf1Or8TypePacketReceived(cyId) ~= g_decArgo_nbOf1Or8TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf1Or8TypePacketExpected(cyId)-g_decArgo_nbOf1Or8TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf2Or9TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf2Or9TypePacketExpected) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketExpected) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == -1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf2Or9TypePacketReceived(cyId) ~= g_decArgo_nbOf2Or9TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf2Or9TypePacketExpected(cyId)-g_decArgo_nbOf2Or9TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf3Or10TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf3Or10TypePacketExpected) || ...
                  (length(g_decArgo_nbOf3Or10TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf3Or10TypePacketExpected) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == -1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of ascent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf3Or10TypePacketReceived(cyId) ~= g_decArgo_nbOf3Or10TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d ascent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf3Or10TypePacketExpected(cyId)-g_decArgo_nbOf3Or10TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf13Or11TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf13Or11TypePacketExpected) || ...
                  (length(g_decArgo_nbOf13Or11TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf13Or11TypePacketExpected) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_nbOf13Or11TypePacketExpected(cyId) == -1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of near surface data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf13Or11TypePacketReceived(cyId) ~= g_decArgo_nbOf13Or11TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d near surface data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf13Or11TypePacketExpected(cyId)-g_decArgo_nbOf13Or11TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf14Or12TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf14Or12TypePacketExpected) || ...
                  (length(g_decArgo_nbOf14Or12TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf14Or12TypePacketExpected) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_nbOf14Or12TypePacketExpected(cyId) == -1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of in air data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf14Or12TypePacketReceived(cyId) ~= g_decArgo_nbOf14Or12TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d in air data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf14Or12TypePacketExpected(cyId)-g_decArgo_nbOf14Or12TypePacketReceived(cyId));
            end
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {216} % Arvor-Deep-Ice Iridium 5.65
      
      % adjust the size of the variables
      g_decArgo_0TypePacketReceivedFlag = [g_decArgo_0TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_0TypePacketReceivedFlag))];
      g_decArgo_4TypePacketReceivedFlag = [g_decArgo_4TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_4TypePacketReceivedFlag))];
      g_decArgo_5TypePacketReceivedFlag = [g_decArgo_5TypePacketReceivedFlag ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_5TypePacketReceivedFlag))];
      g_decArgo_nbOf1Or8TypePacketExpected = [g_decArgo_nbOf1Or8TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketExpected))*-1];
      g_decArgo_nbOf1Or8TypePacketReceived = [g_decArgo_nbOf1Or8TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf1Or8TypePacketReceived))];
      g_decArgo_nbOf2Or9TypePacketExpected = [g_decArgo_nbOf2Or9TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketExpected))*-1];
      g_decArgo_nbOf2Or9TypePacketReceived = [g_decArgo_nbOf2Or9TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf2Or9TypePacketReceived))];
      g_decArgo_nbOf3Or10TypePacketExpected = [g_decArgo_nbOf3Or10TypePacketExpected ...
         ones(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketExpected))*-1];
      g_decArgo_nbOf3Or10TypePacketReceived = [g_decArgo_nbOf3Or10TypePacketReceived ...
         zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf3Or10TypePacketReceived))];
      %       g_decArgo_nbOf13Or11TypePacketExpected = zeros(1, length(g_decArgo_cycleList))*-1;
      %       g_decArgo_nbOf13Or11TypePacketReceived = [g_decArgo_nbOf13Or11TypePacketReceived ...
      %          zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf13Or11TypePacketReceived))];
      %       g_decArgo_nbOf14Or12TypePacketExpected = zeros(1, length(g_decArgo_cycleList))*-1;
      %       g_decArgo_nbOf14Or12TypePacketReceived = [g_decArgo_nbOf14Or12TypePacketReceived ...
      %          zeros(1, length(g_decArgo_cycleList)-length(g_decArgo_nbOf14Or12TypePacketReceived))];
      
      % we must know if Near Surface or In Air packets are expected at each
      % cycle and, if so, we compute (from PT30 et PT 31) the number of expected
      % Near Surface or In Air packets (3 being the max allowed number); this
      % should be done because we have no information about that (as these
      % counts are not reported in the TECH data)
      %       for cyId = 1:length(g_decArgo_cycleList)
      %          cycleNum = g_decArgo_cycleList(cyId);
      %
      %          % retrieve configuration values
      %          pm16Value = nan;
      %          pt21Value = nan;
      %          pt30Value = nan;
      %          pt31Value = nan;
      %          pt33Value = nan;
      %
      %          % from configuration data
      %          idUsedConf = find(g_decArgo_floatConfig.USE.CYCLE == cycleNum);
      %          if (~isempty(idUsedConf))
      %             configNumber = unique(g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
      %             idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == configNumber);
      %             configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
      %             configValues = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);
      %
      %             idPm16Pos = find(strncmp('CONFIG_PM16', configNames, length('CONFIG_PM16')) == 1, 1);
      %             if (~isempty(idPm16Pos))
      %                pm16Value = configValues(idPm16Pos);
      %             end
      %             idPt21Pos = find(strncmp('CONFIG_PT21', configNames, length('CONFIG_PT21')) == 1, 1);
      %             if (~isempty(idPt21Pos))
      %                pt21Value = configValues(idPt21Pos);
      %             end
      %             idPt30Pos = find(strncmp('CONFIG_PT30', configNames, length('CONFIG_PT30')) == 1, 1);
      %             if (~isempty(idPt30Pos))
      %                pt30Value = configValues(idPt30Pos);
      %             end
      %             idPt31Pos = find(strncmp('CONFIG_PT31', configNames, length('CONFIG_PT31')) == 1, 1);
      %             if (~isempty(idPt31Pos))
      %                pt31Value = configValues(idPt31Pos);
      %             end
      %             idPt33Pos = find(strncmp('CONFIG_PT33', configNames, length('CONFIG_PT33')) == 1, 1);
      %             if (~isempty(idPt33Pos))
      %                pt33Value = configValues(idPt33Pos);
      %             end
      %          end
      %
      %          % from temporary configuration data
      %          if (isnan(pt33Value))
      %             idUsedConf = find(g_decArgo_floatConfig.DYNAMIC_TMP.CYCLES == cycleNum-1);
      %             if (~isempty(idUsedConf))
      %
      %                % retrieve the data of the concerned configuration
      %                configNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
      %                configValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, idUsedConf);
      %
      %                idPm16Pos = find(strncmp('CONFIG_PM16', configNames, length('CONFIG_PM16')) == 1, 1);
      %                if (~isempty(idPm16Pos))
      %                   pm16Value = configValues(idPm16Pos);
      %                end
      %                idPt21Pos = find(strncmp('CONFIG_PT21', configNames, length('CONFIG_PT21')) == 1, 1);
      %                if (~isempty(idPt21Pos))
      %                   pt21Value = configValues(idPt21Pos);
      %                end
      %                idPt30Pos = find(strncmp('CONFIG_PT30', configNames, length('CONFIG_PT30')) == 1, 1);
      %                if (~isempty(idPt30Pos))
      %                   pt30Value = configValues(idPt30Pos);
      %                end
      %                idPt31Pos = find(strncmp('CONFIG_PT31', configNames, length('CONFIG_PT31')) == 1, 1);
      %                if (~isempty(idPt31Pos))
      %                   pt31Value = configValues(idPt31Pos);
      %                end
      %                idPt33Pos = find(strncmp('CONFIG_PT33', configNames, length('CONFIG_PT33')) == 1, 1);
      %                if (~isempty(idPt33Pos))
      %                   pt33Value = configValues(idPt33Pos);
      %                end
      %             end
      %          end
      %
      %          % compute number of expected Near Surface or In Air packets
      %          nbOf14Or12TypePacketExpected = 3;
      %          if (~isnan(pm16Value) && ~isnan(pt21Value) && ~isnan(pt30Value) && ~isnan(pt31Value))
      %             if (pm16Value == 0) % no second iridium session
      %                if (pt21Value == 1)
      %                   % PTSO data
      %                   nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/7), 3);
      %                else
      %                   % PTS data
      %                   nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/15), 3);
      %                end
      %             else % one second Iridium session
      %                if (~ismember(cycleNum, a_cycleDecodingDoneList))
      %                   % it is the transmission session
      %                   if (pt21Value == 1)
      %                      % PTSO data
      %                      nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/7), 3);
      %                   else
      %                      % PTS data
      %                      nbOf14Or12TypePacketExpected = min(ceil(pt31Value*60/pt30Value/15), 3);
      %                   end
      %                else
      %                   % it is the second Iridium session => no Near Surface or In Air packets
      %                   nbOf14Or12TypePacketExpected = 0;
      %                end
      %             end
      %          end
      %
      %          if (~isnan(pt33Value))
      %             if (pt33Value == 0)
      %                g_decArgo_nbOf13Or11TypePacketExpected(cyId) = 0;
      %                g_decArgo_nbOf14Or12TypePacketExpected(cyId) = 0;
      %             elseif (pt33Value == 1)
      %                if (cycleNum == 0)
      %                   g_decArgo_nbOf13Or11TypePacketExpected(cyId) = 0;
      %                   g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
      %                else
      %                   g_decArgo_nbOf13Or11TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
      %                   g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
      %                end
      %             elseif (mod(cycleNum, pt33Value) == 0)
      %                if (cycleNum == 0)
      %                   g_decArgo_nbOf13Or11TypePacketExpected(cyId) = 0;
      %                   g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
      %                else
      %                   g_decArgo_nbOf13Or11TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
      %                   g_decArgo_nbOf14Or12TypePacketExpected(cyId) = nbOf14Or12TypePacketExpected;
      %                end
      %             end
      %          else
      %             fprintf('ERROR: Float #%d: ''CONFIG_PT33'' is not defined for cycle #%d => check configuration data\n', ...
      %                g_decArgo_floatNum, cycleNum);
      %          end
      %       end
      
      if (a_whyFlag == 0)
         
         o_cycleNumberList = g_decArgo_cycleList;
         o_bufferCompleted = zeros(size(o_cycleNumberList));
         for cyId = 1:length(g_decArgo_cycleList)
            %             if ( ...
            %                   (g_decArgo_0TypePacketReceivedFlag(cyId) == 1) && ...
            %                   (g_decArgo_4TypePacketReceivedFlag(cyId) == 1) && ...
            %                   (g_decArgo_5TypePacketReceivedFlag(cyId) == 1) && ...
            %                   (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == g_decArgo_nbOf1Or8TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == g_decArgo_nbOf2Or9TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == g_decArgo_nbOf3Or10TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf13Or11TypePacketExpected(cyId) == g_decArgo_nbOf13Or11TypePacketReceived(cyId)) && ...
            %                   (g_decArgo_nbOf14Or12TypePacketExpected(cyId) == g_decArgo_nbOf14Or12TypePacketReceived(cyId)))
            if ( ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) == 1) && ...
                  (g_decArgo_nbOf1Or8TypePacketExpected(cyId) == g_decArgo_nbOf1Or8TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf2Or9TypePacketExpected(cyId) == g_decArgo_nbOf2Or9TypePacketReceived(cyId)) && ...
                  (g_decArgo_nbOf3Or10TypePacketExpected(cyId) == g_decArgo_nbOf3Or10TypePacketReceived(cyId)))
               
               o_bufferCompleted(cyId) = 1;
            end
         end
         
      else
         
         for cyId = 1:length(g_decArgo_cycleList)
            if (isempty(g_decArgo_0TypePacketReceivedFlag) || ...
                  (length(g_decArgo_0TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_0TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #1 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_4TypePacketReceivedFlag) || ...
                  (length(g_decArgo_4TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_4TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Technical #2 packet is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_5TypePacketReceivedFlag) || ...
                  (length(g_decArgo_5TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
                  (g_decArgo_5TypePacketReceivedFlag(cyId) ~= 1))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: Parameter packet #1 is missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            end
            if (isempty(g_decArgo_nbOf1Or8TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf1Or8TypePacketExpected) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf1Or8TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf1Or8TypePacketReceived(cyId) ~= g_decArgo_nbOf1Or8TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d descent data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf1Or8TypePacketExpected(cyId)-g_decArgo_nbOf1Or8TypePacketReceived(cyId));
            end
            if (isempty(g_decArgo_nbOf2Or9TypePacketReceived) ||...
                  isempty(g_decArgo_nbOf2Or9TypePacketExpected) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketReceived) < length(g_decArgo_cycleList)) || ...
                  (length(g_decArgo_nbOf2Or9TypePacketExpected) < length(g_decArgo_cycleList)))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            elseif (g_decArgo_nbOf2Or9TypePacketReceived(cyId) ~= g_decArgo_nbOf2Or9TypePacketExpected(cyId))
               fprintf('BUFF_INFO: Float #%d Cycle #%d: %d drift data packets are missing\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
                  g_decArgo_nbOf2Or9TypePacketExpected(cyId)-g_decArgo_nbOf2Or9TypePacketReceived(cyId));
            end
            %             if (isempty(g_decArgo_nbOf13Or11TypePacketReceived) ||...
            %                   isempty(g_decArgo_nbOf13Or11TypePacketExpected) || ...
            %                   (length(g_decArgo_nbOf13Or11TypePacketReceived) < length(g_decArgo_cycleList)) || ...
            %                   (length(g_decArgo_nbOf13Or11TypePacketExpected) < length(g_decArgo_cycleList)))
            %                fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of ascent data packets are missing\n', ...
            %                   g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            %             elseif (g_decArgo_nbOf13Or11TypePacketReceived(cyId) ~= g_decArgo_nbOf13Or11TypePacketExpected(cyId))
            %                fprintf('BUFF_INFO: Float #%d Cycle #%d: %d near surface data packets are missing\n', ...
            %                   g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
            %                   g_decArgo_nbOf13Or11TypePacketExpected(cyId)-g_decArgo_nbOf13Or11TypePacketReceived(cyId));
            %             end
            %             if (isempty(g_decArgo_nbOf14Or12TypePacketReceived) ||...
            %                   isempty(g_decArgo_nbOf14Or12TypePacketExpected) || ...
            %                   (length(g_decArgo_nbOf14Or12TypePacketReceived) < length(g_decArgo_cycleList)) || ...
            %                   (length(g_decArgo_nbOf14Or12TypePacketExpected) < length(g_decArgo_cycleList)))
            %                fprintf('BUFF_INFO: Float #%d Cycle #%d: information on number of ascent data packets are missing\n', ...
            %                   g_decArgo_floatNum, g_decArgo_cycleList(cyId));
            %             elseif (g_decArgo_nbOf14Or12TypePacketReceived(cyId) ~= g_decArgo_nbOf14Or12TypePacketExpected(cyId))
            %                fprintf('BUFF_INFO: Float #%d Cycle #%d: %d in air data packets are missing\n', ...
            %                   g_decArgo_floatNum, g_decArgo_cycleList(cyId), ...
            %                   g_decArgo_nbOf14Or12TypePacketExpected(cyId)-g_decArgo_nbOf14Or12TypePacketReceived(cyId));
            %             end
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to explain what is missing in the buffer for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;

% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech1, o_tabTech2, o_dataCTD, o_evAct, o_pumpAct, ...
%    o_floatParam1, o_floatParam2, o_cycleNumberList] = ...
%    decode_prv_data_ir_sbd_212(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)
%
% INPUT PARAMETERS :
%   a_tabData         : data frame to decode
%   a_tabDataDates    : corresponding dates of Iridium SBD
%   a_procLevel       : processing level (0: collect only rough information, 1:
%                       decode the data)
%   a_cycleNumberList : list of cycle to decode
%
% OUTPUT PARAMETERS :
%   o_tabTech1        : decoded data of technical msg #1
%   o_tabTech2        : decoded data of technical msg #2
%   o_dataCTD         : decoded data from CTD
%   o_evAct           : EV decoded data from hydraulic packet
%   o_pumpAct         : pump decoded data from hydraulic packet
%   o_floatParam1     : decoded parameter #1 data
%   o_floatParam2     : decoded parameter #2 data
%   o_cycleNumberList : list of decoded cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, o_dataCTD, o_evAct, o_pumpAct, ...
   o_floatParam1, o_floatParam2, o_cycleNumberList] = ...
   decode_prv_data_ir_sbd_212(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_dataCTD = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam1 = [];
o_floatParam2 = [];
o_cycleNumberList = [];

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_janFirst1950InMatlab;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketReceivedFlag;
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
global g_decArgo_nbOf6TypePacketReceived;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;


% clean duplicates in received data
[a_tabData, a_tabDataDates] = clean_duplicates_in_received_data_212_214( ...
   a_tabData, a_tabDataDates, a_procLevel);

% first decoding to compute cycle number offset
resetTimeList = repmat([-1 -1 -1 -1 -1 0], size(a_tabData, 1), 1); % cycleNumber packType sbdFileDate resetTime fileTransNums cycleNumberOffset
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = a_tabDataDates(idMes);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 16 16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            repmat(8, 1, 12) ...
            8 8 16 8 8 8 16 8 8 16 8 16 8 ...
            repmat(8, 1, 7) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 ...
            8 8 8 8 8 16 16 8 16 16 8 8 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 4) ...
            16 8 16 ...
            repmat(8, 1, 9) 16 repmat(8, 1, 6) ...
            repmat(8, 1, 20) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech2(1);
         
         floatLastResetTime = datenum(sprintf('%02d%02d%02d', tabTech2(46:51)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         resetTimeList(idMes, 1:4) = [cycleNum packType sbdFileDate floatLastResetTime];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            repmat(16, 1, 4) repmat(8, 1, 7) repmat(16, 1, 4) 8 16 16 16 8 8 8 16 16 repmat(8, 1, 6) 16 16 ...
            16 repmat(8, 1, 5) 16 repmat(8, 1, 5) 16 8 16 repmat(8, 1, 9) 16 16 ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 7
         % parameter packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            16 16 8 8 8 16 16 8 8 16 repmat(8, 1, 5)  16 ...
            repmat(8, 1, 66) ...
            ];
         % get item bits
         tabParam2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam2(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 6
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat([8 16 16 16], 1, 13) ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabHy(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

% assign a transmission number to the files in the buffer
tabFileTransNums = set_file_trans_num(resetTimeList(:, 3), 60/1440);
resetTimeList(:, 5) = tabFileTransNums;

% compute the cycle number offet of each data packet
prevReset = [];
for idMes = 1:size(resetTimeList, 1)
   if (resetTimeList(idMes, 4) ~= -1)
      curReset = resetTimeList(idMes, 4);
      if (~isempty(prevReset))
         if (curReset ~= prevReset)
            
            idF = find(resetTimeList(:, 5) < resetTimeList(idMes, 5));
            offset = max(resetTimeList(idF, 1) + resetTimeList(idF, 6)) + 1;
            idF = find(resetTimeList(:, 5) >= resetTimeList(idMes, 5));
            resetTimeList(idF, 6) = offset;
            
            fprintf('\nINFO: Float #%d: Cycle #%d: reset detected (previous last reset date : %s - current last reset date : %s)\n\n', ...
               g_decArgo_floatNum, ...
               resetTimeList(idMes, 1) + resetTimeList(idMes, 6), ...
               julian_2_gregorian_dec_argo(prevReset), ...
               julian_2_gregorian_dec_argo(curReset));
         end
      end
      prevReset = curReset;
   end
end
cycleNumOffsetList = resetTimeList(:, 6);

% initialize information arrays
init_counts_212;

% decode packet data
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 16 16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            repmat(8, 1, 12) ...
            8 8 16 8 8 8 16 8 8 16 8 16 8 ...
            repmat(8, 1, 7) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_0TypePacketReceivedFlag(idFCy) = 1;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 ...
            8 8 8 8 8 16 16 8 16 16 8 8 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 4) ...
            16 8 16 ...
            repmat(8, 1, 9) 16 repmat(8, 1, 6) ...
            repmat(8, 1, 20) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech2(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_4TypePacketReceivedFlag(idFCy) = 1;
         
         g_decArgo_nbOf1Or8TypePacketExpected(length(g_decArgo_nbOf1Or8TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf1Or8TypePacketExpected(idFCy) = tabTech2(3);
         g_decArgo_nbOf2Or9TypePacketExpected(length(g_decArgo_nbOf2Or9TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf2Or9TypePacketExpected(idFCy) = tabTech2(4);
         g_decArgo_nbOf3Or10TypePacketExpected(length(g_decArgo_nbOf3Or10TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf3Or10TypePacketExpected(idFCy) = tabTech2(5);
         g_decArgo_nbOf13Or11TypePacketExpected(length(g_decArgo_nbOf13Or11TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf13Or11TypePacketExpected(idFCy) = tabTech2(6);
         g_decArgo_nbOf14Or12TypePacketExpected(length(g_decArgo_nbOf14Or12TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf14Or12TypePacketExpected(idFCy) = tabTech2(7);
         
         if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
            g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
            g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
            g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
            g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
            g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 0;
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 1)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 2)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 3)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 13)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 14)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            repmat(16, 1, 4) repmat(8, 1, 7) repmat(16, 1, 4) 8 16 16 16 8 8 8 16 16 repmat(8, 1, 6) 16 16 ...
            16 repmat(8, 1, 5) 16 repmat(8, 1, 5) 16 8 16 repmat(8, 1, 9) 16 16 ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_5TypePacketReceivedFlag(idFCy) = 1;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 7
         % parameter packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            16 16 8 8 8 16 16 8 8 16 repmat(8, 1, 5)  16 ...
            repmat(8, 1, 66) ...
            ];
         % get item bits
         tabParam2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam2(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_7TypePacketReceivedFlag(idFCy) = 1;
         
         if (isempty(g_decArgo_7TypePacketReceivedCyNum) || ...
               (g_decArgo_7TypePacketReceivedCyNum > cycleNum))
            g_decArgo_7TypePacketReceivedCyNum = cycleNum;
            fprintf('Float #%d, Cycle #%d: ICE mode activated at cycle %d\n', ...
               g_decArgo_floatNum, cycleNum, ...
               g_decArgo_7TypePacketReceivedCyNum);
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 6
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat([8 16 16 16], 1, 13) ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabHy(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (length(g_decArgo_nbOf6TypePacketReceived) < idFCy)
            g_decArgo_nbOf6TypePacketReceived(idFCy) = 1;
         else
            g_decArgo_nbOf6TypePacketReceived(idFCy) = g_decArgo_nbOf6TypePacketReceived(idFCy) + 1;
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

o_cycleNumberList = g_decArgo_cycleList;

return;

% ------------------------------------------------------------------------------
% Initialize global flags and counters used to decide if a buffer is completed
% or not for a given list of cycles.
%
% SYNTAX :
%  init_counts_212
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_counts_212

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketExpectedFlag;
global g_decArgo_7TypePacketReceivedFlag;
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
global g_decArgo_nbOf6TypePacketReceived;

% initialize information arrays
g_decArgo_cycleList = [];
g_decArgo_0TypePacketReceivedFlag = [];
g_decArgo_4TypePacketReceivedFlag = [];
g_decArgo_5TypePacketReceivedFlag = [];
g_decArgo_7TypePacketExpectedFlag = [];
g_decArgo_7TypePacketReceivedFlag = [];
g_decArgo_nbOf1Or8TypePacketExpected = [];
g_decArgo_nbOf1Or8TypePacketReceived = [];
g_decArgo_nbOf2Or9TypePacketExpected = [];
g_decArgo_nbOf2Or9TypePacketReceived = [];
g_decArgo_nbOf3Or10TypePacketExpected = [];
g_decArgo_nbOf3Or10TypePacketReceived = [];
g_decArgo_nbOf13Or11TypePacketExpected = [];
g_decArgo_nbOf13Or11TypePacketReceived = [];
g_decArgo_nbOf14Or12TypePacketExpected = [];
g_decArgo_nbOf14Or12TypePacketReceived = [];
g_decArgo_nbOf6TypePacketReceived = [];

return;

% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech1, o_tabTech2, o_dataCTD, o_dataCTDO, o_evAct, o_pumpAct, ...
%    o_floatParam1, o_floatParam2, o_cycleNumberList] = ...
%    decode_prv_data_ir_sbd_214_217(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)
%
% INPUT PARAMETERS :
%   a_tabData         : data frame to decode
%   a_tabDataDates    : corresponding dates of Iridium SBD
%   a_procLevel       : processing level (0: collect only rough information, 1:
%                       decode the data)
%   a_cycleNumberList : list of cycle to decode
%
% OUTPUT PARAMETERS :
%   o_tabTech1        : decoded data of technical msg #1
%   o_tabTech2        : decoded data of technical msg #2
%   o_dataCTD         : decoded CTD data
%   o_dataCTDO        : decoded CTDO data
%   o_evAct           : EV decoded data from hydraulic packet
%   o_pumpAct         : pump decoded data from hydraulic packet
%   o_floatParam1     : decoded parameter #1 data
%   o_floatParam2     : decoded parameter #2 data
%   o_cycleNumberList : list of decoded cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/07/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, o_dataCTD, o_dataCTDO, o_evAct, o_pumpAct, ...
   o_floatParam1, o_floatParam2, o_cycleNumberList] = ...
   decode_prv_data_ir_sbd_214_217(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_dataCTD = [];
o_dataCTDO = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam1 = [];
o_floatParam2 = [];
o_cycleNumberList = [];

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_janFirst1950InMatlab;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketReceivedFlag;
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
global g_decArgo_nbOf6TypePacketReceived;

% to detect ICE mode activation (first cycle for which parameter packet #2 has
% been received)
global g_decArgo_7TypePacketReceivedCyNum;

% for debug purpose (check_provor_sbd_files)
global g_decArgo_debugFlag;
global g_decArgo_debugResetTimeList;


% clean duplicates in received data
[a_tabData, a_tabDataDates] = clean_duplicates_in_received_data_212_214( ...
   a_tabData, a_tabDataDates, a_procLevel);

% decode technical packet #2 data to store reset times
resetTimeList = repmat([-1 -1 -1 -1 -1 0], size(a_tabData, 1), 1); % cycleNumber packType sbdFileDate resetTime fileTransNums cycleNumberOffset
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = a_tabDataDates(idMes);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 16 16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            repmat(8, 1, 12) ...
            8 8 16 8 8 8 16 8 8 16 8 16 8 ...
            repmat(8, 1, 7) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 ...
            8 8 8 8 8 16 16 8 16 16 8 8 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 4) ...
            16 8 16 ...
            repmat(8, 1, 9) 16 repmat(8, 1, 6) ...
            repmat(8, 1, 20) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech2(1);
         
         floatLastResetTime = datenum(sprintf('%02d%02d%02d', tabTech2(46:51)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         resetTimeList(idMes, 1:4) = [cycleNum packType sbdFileDate floatLastResetTime];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {8, 9, 10, 11, 12}
         % CTDO packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 42) ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         ctdoValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdoValues(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            repmat(16, 1, 4) repmat(8, 1, 7) repmat(16, 1, 4) 8 16 16 16 8 8 8 16 16 repmat(8, 1, 6) 16 16 ...
            16 repmat(8, 1, 5) 16 repmat(8, 1, 5) 16 8 16 repmat(8, 1, 9) 16 16 ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 7
         % parameter packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            16 16 8 8 8 16 16 8 8 16 repmat(8, 1, 5)  16 ...
            repmat(8, 1, 66) ...
            ];
         % get item bits
         tabParam2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam2(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 6
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat([8 16 16 16], 1, 13) ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabHy(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

% assign a transmission number to the files in the buffer
tabFileTransNums = set_file_trans_num(resetTimeList(:, 3), 60/1440);
resetTimeList(:, 5) = tabFileTransNums;

% compute the cycle number offet of each data packet
prevReset = [];
for idMes = 1:size(resetTimeList, 1)
   if (resetTimeList(idMes, 4) ~= -1)
      curReset = resetTimeList(idMes, 4);
      if (~isempty(prevReset))
         if (curReset ~= prevReset)
            
            idF = find(resetTimeList(:, 5) < resetTimeList(idMes, 5));
            offset = max(resetTimeList(idF, 1) + resetTimeList(idF, 6)) + 1;
            idF = find(resetTimeList(:, 5) >= resetTimeList(idMes, 5));
            resetTimeList(idF, 6) = offset;
            
            fprintf('\nINFO: Float #%d: Cycle #%d: reset detected (previous last reset date : %s - current last reset date : %s)\n\n', ...
               g_decArgo_floatNum, ...
               resetTimeList(idMes, 1) + resetTimeList(idMes, 6), ...
               julian_2_gregorian_dec_argo(prevReset), ...
               julian_2_gregorian_dec_argo(curReset));
         end
      end
      prevReset = curReset;
   end
end
cycleNumOffsetList = resetTimeList(:, 6);

% initialize information arrays
init_counts_214_217;

% decode packet data
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 16 16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            repmat(8, 1, 12) ...
            8 8 16 8 8 8 16 8 8 16 8 16 8 ...
            repmat(8, 1, 7) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_0TypePacketReceivedFlag(idFCy) = 1;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 8 ...
            8 8 8 8 8 16 16 8 16 16 8 8 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 4) ...
            16 8 16 ...
            repmat(8, 1, 9) 16 repmat(8, 1, 6) ...
            repmat(8, 1, 20) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech2(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_4TypePacketReceivedFlag(idFCy) = 1;
         
         if (~isempty(g_decArgo_debugFlag))
            g_decArgo_debugResetTimeList(idFCy) = floatLastResetTime;
         end
         
         g_decArgo_nbOf1Or8TypePacketExpected(length(g_decArgo_nbOf1Or8TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf1Or8TypePacketExpected(idFCy) = tabTech2(3);
         g_decArgo_nbOf2Or9TypePacketExpected(length(g_decArgo_nbOf2Or9TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf2Or9TypePacketExpected(idFCy) = tabTech2(4);
         g_decArgo_nbOf3Or10TypePacketExpected(length(g_decArgo_nbOf3Or10TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf3Or10TypePacketExpected(idFCy) = tabTech2(5);
         g_decArgo_nbOf13Or11TypePacketExpected(length(g_decArgo_nbOf13Or11TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf13Or11TypePacketExpected(idFCy) = tabTech2(6);
         g_decArgo_nbOf14Or12TypePacketExpected(length(g_decArgo_nbOf14Or12TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf14Or12TypePacketExpected(idFCy) = tabTech2(7);
         
         if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
            g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
            g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
            g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
            g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
            g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 0;
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         if (~any(ctdValues(2:end) ~= 0))
            fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
               g_decArgo_floatNum, cycleNum, ...
               packType);
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 1)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 2)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 3)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 13)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 14)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {8, 9, 10, 11, 12}
         % CTDO packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 42) ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         ctdoValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdoValues(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         if (~any(ctdoValues(2:end) ~= 0))
            fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
               g_decArgo_floatNum, cycleNum, ...
               packType);
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 8)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 9)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 10)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 11)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 12)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            repmat(16, 1, 4) repmat(8, 1, 7) repmat(16, 1, 4) 8 16 16 16 8 8 8 16 16 repmat(8, 1, 6) 16 16 ...
            16 repmat(8, 1, 5) 16 repmat(8, 1, 5) 16 8 16 repmat(8, 1, 9) 16 16 ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_5TypePacketReceivedFlag(idFCy) = 1;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 7
         % parameter packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 repmat(8, 1, 7) 16 ...
            16 16 8 8 8 16 16 8 8 16 repmat(8, 1, 5)  16 ...
            repmat(8, 1, 66) ...
            ];
         % get item bits
         tabParam2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam2(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         g_decArgo_7TypePacketReceivedFlag(idFCy) = 1;
         
         if (isempty(g_decArgo_7TypePacketReceivedCyNum) || ...
               (g_decArgo_7TypePacketReceivedCyNum > cycleNum))
            g_decArgo_7TypePacketReceivedCyNum = cycleNum;
            fprintf('Float #%d, Cycle #%d: ICE mode activated at cycle %d\n', ...
               g_decArgo_floatNum, cycleNum, ...
               g_decArgo_7TypePacketReceivedCyNum);
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 6
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat([8 16 16 16], 1, 13) ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabHy(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (length(g_decArgo_nbOf6TypePacketReceived) < idFCy)
            g_decArgo_nbOf6TypePacketReceived(idFCy) = 1;
         else
            g_decArgo_nbOf6TypePacketReceived(idFCy) = g_decArgo_nbOf6TypePacketReceived(idFCy) + 1;
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

o_cycleNumberList = g_decArgo_cycleList;

return;

% ------------------------------------------------------------------------------
% Initialize global flags and counters used to decide if a buffer is completed
% or not for a given list of cycles.
%
% SYNTAX :
%  init_counts_214_217
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_counts_214_217

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_7TypePacketExpectedFlag;
global g_decArgo_7TypePacketReceivedFlag;
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
global g_decArgo_nbOf6TypePacketReceived;

% initialize information arrays
g_decArgo_cycleList = [];
g_decArgo_0TypePacketReceivedFlag = [];
g_decArgo_4TypePacketReceivedFlag = [];
g_decArgo_5TypePacketReceivedFlag = [];
g_decArgo_7TypePacketExpectedFlag = [];
g_decArgo_7TypePacketReceivedFlag = [];
g_decArgo_nbOf1Or8TypePacketExpected = [];
g_decArgo_nbOf1Or8TypePacketReceived = [];
g_decArgo_nbOf2Or9TypePacketExpected = [];
g_decArgo_nbOf2Or9TypePacketReceived = [];
g_decArgo_nbOf3Or10TypePacketExpected = [];
g_decArgo_nbOf3Or10TypePacketReceived = [];
g_decArgo_nbOf13Or11TypePacketExpected = [];
g_decArgo_nbOf13Or11TypePacketReceived = [];
g_decArgo_nbOf14Or12TypePacketExpected = [];
g_decArgo_nbOf14Or12TypePacketReceived = [];
g_decArgo_nbOf6TypePacketReceived = [];

return;

% ------------------------------------------------------------------------------
% Decode PROVOR packet data.
%
% SYNTAX :
%  [o_tabTech1, o_tabTech2, o_dataCTD, o_dataCTDO, o_evAct, o_pumpAct, ...
%    o_floatParam1, o_cycleNumberList, o_firstDateNextBuffer] = ...
%    decode_prv_data_ir_sbd_216(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)
%
% INPUT PARAMETERS :
%   a_tabData         : data frame to decode
%   a_tabDataDates    : corresponding dates of Iridium SBD
%   a_procLevel       : processing level (0: collect only rough information, 1:
%                       decode the data)
%   a_cycleNumberList : list of cycle to decode
%
% OUTPUT PARAMETERS :
%   o_tabTech1        : decoded data of technical msg #1
%   o_tabTech2        : decoded data of technical msg #2
%   o_dataCTD         : decoded CTD data
%   o_dataCTDO        : decoded CTDO data
%   o_evAct           : EV decoded data from hydraulic packet
%   o_pumpAct         : pump decoded data from hydraulic packet
%   o_floatParam1     : decoded parameter #1 data
%   o_cycleNumberList : list of decoded cycle numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/22/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTech1, o_tabTech2, o_dataCTD, o_dataCTDO, o_evAct, o_pumpAct, ...
   o_floatParam1, o_cycleNumberList, o_firstDateNextBuffer] = ...
   decode_prv_data_ir_sbd_216(a_tabData, a_tabDataDates, a_procLevel, a_cycleNumberList)

% output parameters initialization
o_tabTech1 = [];
o_tabTech2 = [];
o_dataCTD = [];
o_dataCTDO = [];
o_evAct = [];
o_pumpAct = [];
o_floatParam1 = [];
o_cycleNumberList = [];
o_firstDateNextBuffer = [];

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_janFirst1950InMatlab;

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;
global g_decArgo_nbOf7TypePacketReceived;


% clean duplicates in received data
[a_tabData, a_tabDataDates] = clean_duplicates_in_received_data_216( ...
   a_tabData, a_tabDataDates, a_procLevel);

% first decoding to compute cycle number offset
resetTimeList = repmat([-1 -1 -1 -1 -1 0], size(a_tabData, 1), 1); % cycleNumber packType sbdFileDate resetTime fileTransNums cycleNumberOffset
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   % date of the SBD file
   sbdFileDate = a_tabDataDates(idMes);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            8 8 8  repmat(8, 1, 9) ...
            8 8 16 8 8 8 16 8 8 16 8 ...
            repmat(8, 1, 2) ...
            repmat(8, 1, 7) ...
            16 8 16 ...
            repmat(8, 1, 4) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 ...
            8 8 8 16 16 8 16 16 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 9) ...
            8 8 ...
            repmat(8, 1, 40) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech2(1);
         
         floatLastResetTime = datenum(sprintf('%02d%02d%02d', tabTech2(35:40)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         
         resetTimeList(idMes, 1:4) = [cycleNum packType sbdFileDate floatLastResetTime];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {8, 9, 10, 11, 12}
         % CTDO packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 42) ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         ctdoValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdoValues(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(8, 1, 6) 16 ...
            16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
            repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 8 8 16 16 16 ...
            16 16 8 8 16 16 8 8 16 8 8 8 8 16 ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(7)-1;
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {6, 7}
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabHy(1);
         
         resetTimeList(idMes, 1:3) = [cycleNum packType sbdFileDate];
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

% assign a transmission number to the files in the buffer
tabFileTransNums = set_file_trans_num(resetTimeList(:, 3), 60/1440);
resetTimeList(:, 5) = tabFileTransNums;

% compute the cycle number offet of each data packet
prevReset = [];
for idMes = 1:size(resetTimeList, 1)
   if (resetTimeList(idMes, 4) ~= -1)
      curReset = resetTimeList(idMes, 4);
      if (~isempty(prevReset))
         if (curReset ~= prevReset)
            
            idF = find(resetTimeList(:, 5) < resetTimeList(idMes, 5));
            offset = max(resetTimeList(idF, 1) + resetTimeList(idF, 6)) + 1;
            idF = find(resetTimeList(:, 5) >= resetTimeList(idMes, 5));
            resetTimeList(idF, 6) = offset;
            
            fprintf('\nINFO: Float #%d: Cycle #%d: reset detected (previous last reset date : %s - current last reset date : %s)\n\n', ...
               g_decArgo_floatNum, ...
               resetTimeList(idMes, 1) + resetTimeList(idMes, 6), ...
               julian_2_gregorian_dec_argo(prevReset), ...
               julian_2_gregorian_dec_argo(curReset));
         end
      end
      prevReset = curReset;
   end
end
cycleNumOffsetList = resetTimeList(:, 6);

% initialize information arrays
init_counts_216;

% decode packet data
for idMes = 1:size(a_tabData, 1)
   % packet type
   packType = a_tabData(idMes, 1);
   
   switch (packType)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 0
         % technical packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 ...
            8 8 8 16 16 16 8 8 ...
            16 16 16 8 8 16 16 ...
            8 8 8 16 16 8 8 ...
            16 16 8 8 16 ...
            8 8 8 8 16 16 ...
            16 16 8 ...
            8 8 8  repmat(8, 1, 9) ...
            8 8 16 8 8 8 16 8 8 16 8 ...
            repmat(8, 1, 2) ...
            repmat(8, 1, 7) ...
            16 8 16 ...
            repmat(8, 1, 4) ...
            ];
         % get item bits
         tabTech1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech1(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         if ~(isempty(g_decArgo_0TypePacketReceivedFlag) || ...
               (length(g_decArgo_0TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
               (g_decArgo_0TypePacketReceivedFlag(idFCy) ~= 1))
            % packet types 0, 4 and 5 are sent again in a possible Iridium
            % session
            continue;
         end
         g_decArgo_0TypePacketReceivedFlag(idFCy) = 1;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 4
         % technical packet #2
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 ...
            8 8 8 16 16 8 16 16 ...
            repmat(16, 1, 6) ...
            8 16 8 16 8 8 16 8 16 8 8 ...
            8 16 16 8 8 ...
            repmat(8, 1, 9) ...
            8 8 ...
            repmat(8, 1, 40) ...
            ];
         % get item bits
         tabTech2 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabTech2(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         if ~(isempty(g_decArgo_4TypePacketReceivedFlag) || ...
               (length(g_decArgo_4TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
               (g_decArgo_4TypePacketReceivedFlag(idFCy) ~= 1))
            % packet types 0, 4 and 5 are sent again in a possible Iridium
            % session
            continue;
         end
         g_decArgo_4TypePacketReceivedFlag(idFCy) = 1;
         
         g_decArgo_nbOf1Or8TypePacketExpected(length(g_decArgo_nbOf1Or8TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf1Or8TypePacketExpected(idFCy) = tabTech2(2);
         g_decArgo_nbOf2Or9TypePacketExpected(length(g_decArgo_nbOf2Or9TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf2Or9TypePacketExpected(idFCy) = tabTech2(3);
         g_decArgo_nbOf3Or10TypePacketExpected(length(g_decArgo_nbOf3Or10TypePacketExpected)+1:idFCy-1) = -1;
         g_decArgo_nbOf3Or10TypePacketExpected(idFCy) = tabTech2(4);
         
         if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
            g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
            g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
            g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
            g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 0;
         end
         if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
            g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 0;
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {1, 2, 3, 13, 14}
         % CTD packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         ctdValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdValues(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         if (~any(ctdValues(2:end) ~= 0))
            fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
               g_decArgo_floatNum, cycleNum, ...
               packType);
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 1)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 2)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 3)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 13)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 14)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {8, 9, 10, 11, 12}
         % CTDO packets
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 8 8 ...
            repmat(16, 1, 42) ...
            repmat(8, 1, 9) ...
            ];
         % get item bits
         ctdoValues = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = ctdoValues(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         if (~any(ctdoValues(2:end) ~= 0))
            fprintf('WARNING: Float #%d, Cycle #%d: One empty packet type #%d has been received\n', ...
               g_decArgo_floatNum, cycleNum, ...
               packType);
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 8)
            if (length(g_decArgo_nbOf1Or8TypePacketReceived) < idFCy)
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf1Or8TypePacketReceived(idFCy) = g_decArgo_nbOf1Or8TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 9)
            if (length(g_decArgo_nbOf2Or9TypePacketReceived) < idFCy)
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf2Or9TypePacketReceived(idFCy) = g_decArgo_nbOf2Or9TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 10)
            if (length(g_decArgo_nbOf3Or10TypePacketReceived) < idFCy)
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf3Or10TypePacketReceived(idFCy) = g_decArgo_nbOf3Or10TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 11)
            if (length(g_decArgo_nbOf13Or11TypePacketReceived) < idFCy)
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf13Or11TypePacketReceived(idFCy) = g_decArgo_nbOf13Or11TypePacketReceived(idFCy) + 1;
            end
         elseif (packType == 12)
            if (length(g_decArgo_nbOf14Or12TypePacketReceived) < idFCy)
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf14Or12TypePacketReceived(idFCy) = g_decArgo_nbOf14Or12TypePacketReceived(idFCy) + 1;
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 5
         % parameter packet #1
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            repmat(8, 1, 6) 16 ...
            16 repmat(8, 1, 6) repmat(16, 1, 4) 8 8 8 16 16 8 ...
            repmat(8, 1, 6) 16 repmat(8, 1, 5) 16 repmat(8, 1, 4) 16 repmat(8, 1, 12) 16 16 8 8 16 16 16 ...
            16 16 8 8 16 16 8 8 16 8 8 8 8 16 ...
            repmat(8, 1, 2) ...
            ];
         % get item bits
         tabParam1 = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabParam1(7)-1 + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         if ~(isempty(g_decArgo_5TypePacketReceivedFlag) || ...
               (length(g_decArgo_5TypePacketReceivedFlag) < length(g_decArgo_cycleList)) || ...
               (g_decArgo_5TypePacketReceivedFlag(idFCy) ~= 1))
            % packet types 0, 4 and 5 are sent again in a possible Iridium
            % session
            continue;
         end
         g_decArgo_5TypePacketReceivedFlag(idFCy) = 1;
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case {6, 7}
         % EV or pump packet
         
         % message data frame
         msgData = a_tabData(idMes, 2:end);
         
         % first item bit number
         firstBit = 1;
         % item bit lengths
         tabNbBits = [ ...
            16 16 16 ...
            repmat(16, 1, 45) ...
            repmat(8, 1, 3) ...
            ];
         % get item bits
         tabHy = get_bits(firstBit, tabNbBits, msgData);
         
         cycleNum = tabHy(1) + cycleNumOffsetList(idMes);
         
         if (~isempty(a_cycleNumberList) && ~ismember(cycleNum, a_cycleNumberList))
            continue;
         end
         
         idFCy = find(g_decArgo_cycleList == cycleNum);
         if (isempty(idFCy))
            idFCy = length(g_decArgo_cycleList) + 1;
            g_decArgo_cycleList(idFCy) = cycleNum;
         end
         
         if (packType == 6)
            if (length(g_decArgo_nbOf6TypePacketReceived) < idFCy)
               g_decArgo_nbOf6TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf6TypePacketReceived(idFCy) = g_decArgo_nbOf6TypePacketReceived(idFCy) + 1;
            end
         else
            if (length(g_decArgo_nbOf7TypePacketReceived) < idFCy)
               g_decArgo_nbOf7TypePacketReceived(idFCy) = 1;
            else
               g_decArgo_nbOf7TypePacketReceived(idFCy) = g_decArgo_nbOf7TypePacketReceived(idFCy) + 1;
            end
         end
         
      otherwise
         fprintf('WARNING: Float #%d: Nothing done yet for packet type #%d\n', ...
            g_decArgo_floatNum, ...
            packType);
   end
end

o_cycleNumberList = g_decArgo_cycleList;

return;

% ------------------------------------------------------------------------------
% Initialize global flags and counters used to decide if a buffer is completed
% or not for a given list of cycles.
%
% SYNTAX :
%  init_counts_216
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/22/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_counts_216

% arrays to store rough information on received data
global g_decArgo_cycleList;
global g_decArgo_0TypePacketReceivedFlag;
global g_decArgo_4TypePacketReceivedFlag;
global g_decArgo_5TypePacketReceivedFlag;
global g_decArgo_nbOf1Or8TypePacketExpected;
global g_decArgo_nbOf1Or8TypePacketReceived;
global g_decArgo_nbOf2Or9TypePacketExpected;
global g_decArgo_nbOf2Or9TypePacketReceived;
global g_decArgo_nbOf3Or10TypePacketExpected;
global g_decArgo_nbOf3Or10TypePacketReceived;
global g_decArgo_nbOf13Or11TypePacketReceived;
global g_decArgo_nbOf14Or12TypePacketReceived;
global g_decArgo_nbOf6TypePacketReceived;
global g_decArgo_nbOf7TypePacketReceived;

% initialize information arrays
g_decArgo_cycleList = [];
g_decArgo_0TypePacketReceivedFlag = [];
g_decArgo_4TypePacketReceivedFlag = [];
g_decArgo_5TypePacketReceivedFlag = [];
g_decArgo_nbOf1Or8TypePacketExpected = [];
g_decArgo_nbOf1Or8TypePacketReceived = [];
g_decArgo_nbOf2Or9TypePacketExpected = [];
g_decArgo_nbOf2Or9TypePacketReceived = [];
g_decArgo_nbOf3Or10TypePacketExpected = [];
g_decArgo_nbOf3Or10TypePacketReceived = [];
g_decArgo_nbOf13Or11TypePacketReceived = [];
g_decArgo_nbOf14Or12TypePacketReceived = [];
g_decArgo_nbOf6TypePacketReceived = [];
g_decArgo_nbOf7TypePacketReceived = [];

return;
