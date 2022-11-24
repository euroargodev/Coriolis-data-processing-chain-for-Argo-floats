% ------------------------------------------------------------------------------
% For a given list of floats, process the associated Argos cycle files by:
%   1: renaming the files (according to float and cycle numbers)
%   2: moving the file to the apropriate directory.
%
% SYNTAX :
%   move_and_rename_prv_argos_files or move_and_rename_prv_argos_files(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/25/2014 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_prv_argos_files(varargin)

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecPrv_info\ASFAR\ArgosProcessing\in\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecPrv_info\ASFAR\ArgosProcessing\out\';

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\Desktop\Nouveau dossier\cycle\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\Desktop\Nouveau dossier\cycle_out\';

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split_cycle_CORRECT\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split_cycle_FINAL\';

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\V2\OUT_4.54\STEP4\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\V2\OUT_4.54\STEp4_FINAL\';

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\TMP\STEP4\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\TMP\STEP4_FINAL\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% global input parameter information
global g_decArgo_processModeAll;
g_decArgo_processModeAll = 1;
global g_decArgo_inputArgosFile;
global g_decArgo_processModeRedecode;
g_decArgo_processModeRedecode = 0;

% configuration values
global g_decArgo_dirInputHexArgosFileFormat1
g_decArgo_dirInputHexArgosFileFormat1 = DIR_OUTPUT_ARGOS_FILES;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% storage of already computed cycles
global g_util_cycleNumber;
global g_util_firstMsgDate;
global g_util_lastMsgDate;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_JSON_FLOAT_META_DATA_FILE';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};
g_decArgo_dirInputJsonFloatMetaDataFile = configVal{3};

% create the output directories
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
end

if (nargin == 0)
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('File not found: %s\n', floatListFileName);
      return
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

logFile = [DIR_LOG_FILE '/' 'move_and_rename_prv_argos_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   g_util_cycleNumber = [];
   g_util_firstMsgDate = [];
   g_util_lastMsgDate = [];
   
   floatNum = floatList(idFloat);
   g_decArgo_floatNum = floatNum;
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find current float Argos Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d\n', floatNum);
      fprintf('(nothing done)\n');
      continue
   end
   floatArgosId = str2num(listArgosId{idF});
   floatEndDate = listEndDate(idF);

   % select and sort the Argos files of the float
   argosFileNames = [];
   argosFileFirstMsgDate = [];
   dirInputFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   argosFiles = dir([dirInputFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [dirInputFloat '/' argosFileName];
      
      if (length(argosFileName) >= 27)
         
         [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName(1:27), '%d_%d-%d-%d-%d-%d-%d_');
         
         if (isempty(errmsg1) && (count1 == 7))
            
            if (floatEndDate ~= g_decArgo_dateDef)
               
               % check if the file should be considered
               fileDate = datenum(argosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
               if (fileDate > floatEndDate)
                  fprintf('INFO: Date of input file (%s) is after float end decoding date (%s) - file stored without cycle number (i.e. not decoded)\n', ...
                     julian_2_gregorian_dec_argo(fileDate), ...
                     julian_2_gregorian_dec_argo(floatEndDate));
                  g_decArgo_inputArgosFile = argosFilePathName;
                  move_argos_input_file(floatArgosId, fileDate, floatNum, [], 'UUU');
                  continue
               end
            end

            argosFileNames{end+1} = argosFilePathName;
            argosFileFirstMsgDate(end+1) = datenum(argosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - ...
               g_decArgo_janFirst1950InMatlab;
            
         else
            fprintf('ERROR: Not expected file name: %s - file not considered\n', argosFileName);
         end
      else
         fprintf('ERROR: Not expected file name: %s - file not considered\n', argosFileName);
      end
   end
   
   % chronologically sort the files
   [argosFileFirstMsgDate, idSort] = sort(argosFileFirstMsgDate);
   argosFileNames = argosFileNames(idSort);
   
   % process the Argos files of the float
   nbFiles = length(argosFileNames);
   for idFile = 1:nbFiles
      % process one Argos file
      g_decArgo_inputArgosFile = argosFileNames{idFile};
      move_and_rename_file(argosFileNames{idFile}, floatNum, floatArgosId, ...
         floatInformationFileName);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process one Argos cycle file by:
%   1: renaming it (according to float and cycle numbers)
%   2: moving it to the apropriate directory.
%
% SYNTAX :
%  move_and_rename_file(a_argosFileName, a_floatNum, a_argosId, ...
%    a_floatInformationFileName)
%
% INPUT PARAMETERS :
%   a_argosFileName : Argos cycle file name
%   a_floatNum : float WMO number
%   a_argosId : float Argos Id
%   a_floatInformationFileName : name of the float information file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/25/2014 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_file(a_argosFileName, a_floatNum, a_argosId, ...
   a_floatInformationFileName)

% storage of already computed cycles
global g_util_cycleNumber;
global g_util_firstMsgDate;
global g_util_lastMsgDate;

% miscellaneous decoder configuration parameters
global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNumMsgForNotGhost;

% minimum number of float messages for not only ghosts in contents
NB_MSG_MIN = g_decArgo_minNumMsgForNotGhost;

% global input parameter information
global g_decArgo_inputArgosFile;

% minimum duration (in hour) of a non-transmission period to create a new
% cycle
MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE = g_decArgo_minNonTransDurForNewCycle;


% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(a_floatInformationFileName);

idFloat = find(listWmoNum == a_floatNum);

frameLen = listFrameLen(idFloat);
floatDecId = listDecId(idFloat);
floatLaunchDate = listLaunchDate(idFloat);
floatCycleTime = listCycleTime(idFloat);
floatRefDay = listRefDay(idFloat);

% read Argos file
[argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
   argosDataDate, argosDataData] = read_argos_file_fmt1({a_argosFileName}, a_argosId, frameLen);
firstArgosMsgDate = min(argosDataDate);
lastArgosMsgDate = max(argosDataDate);

% store file with only ghost messages without any cycle number
if (isempty(argosDataDate))
   
   % search dates in the file without checking its consistency
   [argosLocDate, argosDataDate] = ...
      read_argos_file_fmt1_rough(a_argosFileName, a_argosId);
   if (~isempty(argosDataDate))
      move_argos_input_file(a_argosId, min(argosDataDate), a_floatNum, [], 'EEE');
   else
      move_argos_input_file(a_argosId, min(argosLocDate), a_floatNum, [], 'EEE');
   end
   fprintf('INFO: File (%s) contains no Argos messages - file stored without cycle number (i.e. not decoded)\n', ...
      a_argosFileName);
   
   return
elseif (length(unique(argosDataDate)) < NB_MSG_MIN)
   
   move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, [], 'GGG');
   fprintf('INFO: File (%s) contains only ghost messages - file stored without cycle number (i.e. not decoded)\n', ...
      a_argosFileName);
   
   return
end

% find the cycle number

% retrieve useful float meta-data
[launchDate, delayBeforeMission, preludeDuration, firstProfileEndDate, cycleDuration, nbCyclesFirstMission] = ...
   get_meta_data_for_cycle_number_determination(a_floatNum, floatDecId, floatLaunchDate, floatCycleTime, floatRefDay);
if (isempty(launchDate))
   fprintf('ERROR: Unable to compute cycle number because of missing meta-data - file stored without cycle number (i.e. not decoded)\n');
   
   move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, [], 'MMM');
   return
end

% estimate the cycle number
cycleNumber = [];
if (lastArgosMsgDate > launchDate)
   if (length(cycleDuration) == 1)
      
      % floats with one cycle duration
      
      if (get_default_prelude_duration(floatDecId) == 0)
         
         % floats with no prelude phase
         
         % try to use already computed cycles
         idPrevCycle = find(g_util_lastMsgDate < firstArgosMsgDate);
         if (~isempty(idPrevCycle))
            idPrevCycle = idPrevCycle(end);
            nbCycles = round((firstArgosMsgDate-g_util_firstMsgDate(idPrevCycle))/cycleDuration);
            if ((nbCycles == 0) && ...
                  ((firstArgosMsgDate-g_util_lastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
               % we consider it is a new cycle if we have had a
               % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
               % transmission
               nbCycles = 1;
            end
            cycleNumber = g_util_cycleNumber(idPrevCycle) + nbCycles;
         end
         
         % use float meta-data
         if (isempty(cycleNumber))
            cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)/cycleDuration);
            %          fprintf('INFO: Cycle number (%d) has been computed from meta-data only\n', cycleNumber);
         end
         
      else
         
         % floats with a prelude phase
         
         % try to use already computed cycles
         idPrevCycle = find(g_util_lastMsgDate < firstArgosMsgDate);
         if (~isempty(idPrevCycle))
            idPrevCycle = idPrevCycle(end);
            if (g_util_cycleNumber(idPrevCycle) == 0)
               cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)/cycleDuration) + 1;
               if ((cycleNumber == 0) && ...
                     ((firstArgosMsgDate-g_util_lastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
                  % we consider it is a new cycle if we have had a
                  % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
                  % transmission
                  cycleNumber = 1;
               end
            else
               nbCycles = round((firstArgosMsgDate-g_util_firstMsgDate(idPrevCycle))/cycleDuration);
               if ((nbCycles == 0) && ...
                     ((firstArgosMsgDate-g_util_lastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
                  % we consider it is a new cycle if we have had a
                  % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
                  % transmission
                  nbCycles = 1;
               end
               cycleNumber = g_util_cycleNumber(idPrevCycle) + nbCycles;
            end
         end
         
         % use float meta-data
         if (isempty(cycleNumber))
            if (firstArgosMsgDate < launchDate + preludeDuration/1440)
               cycleNumber = 0;
            elseif (firstArgosMsgDate < firstProfileEndDate)
               if (abs(firstArgosMsgDate-(launchDate + preludeDuration/1440)) < abs(firstArgosMsgDate-firstProfileEndDate))
                  cycleNumber = 0;
               else
                  cycleNumber = 1;
               end
            else
               cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)/cycleDuration) + 1;
            end
            %          fprintf('INFO: Cycle number (%d) has been computed from meta-data only\n', cycleNumber);
         end
      end
      
   else
      
      % floats with two cycle durations
               
      % these float versions provide the cycle numbers
      decodedCycleNumber = decode_cycle_number(a_argosFileName, ...
         a_floatNum, a_argosId, frameLen, floatDecId);
      
      if (~isempty(decodedCycleNumber) && (decodedCycleNumber ~= -1))
         
         % the cycle number has been decoded from the transmitted data
         if (decodedCycleNumber ~= 0)
            cycleNumber = decodedCycleNumber;
         else
            
            % the cycle number reported by the float is #0
            % it can be the prelude or a EOL, we must use additional dates and
            % information to set the correct cycle number
                        
            % multiple cycle durations only concern floats with a prelude phase
            
            % compute the duration of the cycle #1 (first deep cycle)
            firstDeepCycleDuration = firstProfileEndDate - floatRefDay - ...
               delayBeforeMission/1440 - preludeDuration/1440;
            
            % compute the duration of the transition cycle
            surfTime = firstProfileEndDate - fix(firstProfileEndDate);
            transitionCycleStartDate = surfTime + (nbCyclesFirstMission-1)*cycleDuration(1);
            transitionCycleEndDate = fix(transitionCycleStartDate + cycleDuration(2)) + surfTime;
            transitionCycleDuration = transitionCycleEndDate - transitionCycleStartDate;
            
            % try to use already computed cycles
            idPrevCycle = find(g_util_lastMsgDate < firstArgosMsgDate);
            if (~isempty(idPrevCycle))
               idPrevCycle = idPrevCycle(end);
               
               if (g_util_cycleNumber(idPrevCycle) == 0)
                  
                  refDate = g_util_lastMsgDate(idPrevCycle);
                  dates = [ ...
                     refDate+firstDeepCycleDuration ...
                     repmat(cycleDuration(1), 1, nbCyclesFirstMission-1) ...
                     transitionCycleDuration ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = 1:length(dates);
                  
                  [~, idMin] = min(abs(dates-firstArgosMsgDate));
                  cycleNumber = cycleNumbers(idMin);
                  
               elseif ((g_util_cycleNumber(idPrevCycle) > 0) && (g_util_cycleNumber(idPrevCycle) < nbCyclesFirstMission))
                  
                  refDate = g_util_firstMsgDate(idPrevCycle);
                  dates = [ ...
                     refDate ...
                     repmat(cycleDuration(1), 1, nbCyclesFirstMission-g_util_cycleNumber(idPrevCycle)) ...
                     transitionCycleDuration ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
                  
                  [~, idMin] = min(abs(dates-firstArgosMsgDate));
                  cycleNumber = cycleNumbers(idMin);
                  
               elseif (g_util_cycleNumber(idPrevCycle) == nbCyclesFirstMission)
                  
                  refDate = g_util_firstMsgDate(idPrevCycle);
                  dates = [ ...
                     refDate ...
                     transitionCycleDuration ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
                  
                  [~, idMin] = min(abs(dates-firstArgosMsgDate));
                  cycleNumber = cycleNumbers(idMin);
                  
               else
                  
                  refDate = g_util_firstMsgDate(idPrevCycle);
                  dates = [ ...
                     refDate ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
                  
                  [~, idMin] = min(abs(dates-firstArgosMsgDate));
                  cycleNumber = cycleNumbers(idMin);
                  
               end
               
            else
               
               % use float meta-data
               
               dates = [ ...
                  floatRefDay+delayBeforeMission/1440 ...
                  preludeDuration/1440+firstDeepCycleDuration ...
                  repmat(cycleDuration(1), 1, nbCyclesFirstMission-1) ...
                  transitionCycleDuration ...
                  repmat(cycleDuration(2), 1, 999)];
               for id = 2:length(dates)
                  dates(id) = dates(id) + dates(id-1);
               end
               cycleNumbers = 0:length(dates);
               
               [~, idMin] = min(abs(dates-firstArgosMsgDate));
               cycleNumber = cycleNumbers(idMin);
               
            end
         end
         
      elseif (decodedCycleNumber == -1)
         
         diffArgosDataDates = diff(argosDataDate)*24;

         % the file contains multiple cycles
         [subFileNameList] = split_argos_file(a_argosFileName, a_floatNum, a_argosId);
         if (~isempty(subFileNameList))
            
            fprintf('INFO: Argos cycle file split (%.1f hours without transmission): %s\n', ...
               max(diffArgosDataDates), a_argosFileName);
         else
            fprintf('ERROR: Unable to split Argos cycle file: %s\n', ...
               argosFileName);
         end
         
         for idFile = 1:length(subFileNameList)
            
            cycleNumberFile = [];

            decodedCycleNumber = decode_cycle_number(subFileNameList{idFile}, ...
               a_floatNum, a_argosId, frameLen, floatDecId);
            
            if (~isempty(decodedCycleNumber) && (decodedCycleNumber ~= -1))
               
               % the cycle number has been decoded from the transmitted data
               if (decodedCycleNumber ~= 0)
                  cycleNumberFile = decodedCycleNumber;
               else
                  
                  % the cycle number reported by the float is #0
                  % it can be the prelude or a EOL, we must use additional dates and
                  % information to set the correct cycle number
                  
                  % multiple cycle durations only concern floats with a prelude phase
                  
                  % compute the duration of the cycle #1 (first deep cycle)
                  firstDeepCycleDuration = firstProfileEndDate - floatRefDay - ...
                     delayBeforeMission/1440 - preludeDuration/1440;
                  
                  % compute the duration of the transition cycle
                  surfTime = firstProfileEndDate - fix(firstProfileEndDate);
                  transitionCycleStartDate = surfTime + (nbCyclesFirstMission-1)*cycleDuration(1);
                  transitionCycleEndDate = fix(transitionCycleStartDate + cycleDuration(2)) + surfTime;
                  transitionCycleDuration = transitionCycleEndDate - transitionCycleStartDate;
                  
                  % try to use already computed cycles
                  idPrevCycle = find(g_util_lastMsgDate < firstArgosMsgDate);
                  if (~isempty(idPrevCycle))
                     idPrevCycle = idPrevCycle(end);
                     
                     if (g_util_cycleNumber(idPrevCycle) == 0)
                        
                        refDate = g_util_lastMsgDate(idPrevCycle);
                        dates = [ ...
                           refDate+firstDeepCycleDuration ...
                           repmat(cycleDuration(1), 1, nbCyclesFirstMission-1) ...
                           transitionCycleDuration ...
                           repmat(cycleDuration(2), 1, 999)];
                        for id = 2:length(dates)
                           dates(id) = dates(id) + dates(id-1);
                        end
                        cycleNumbers = 1:length(dates);
                        
                        [~, idMin] = min(abs(dates-firstArgosMsgDate));
                        cycleNumberFile = cycleNumbers(idMin);
                        
                     elseif ((g_util_cycleNumber(idPrevCycle) > 0) && (g_util_cycleNumber(idPrevCycle) < nbCyclesFirstMission))
                        
                        refDate = g_util_firstMsgDate(idPrevCycle);
                        dates = [ ...
                           refDate ...
                           repmat(cycleDuration(1), 1, nbCyclesFirstMission-g_util_cycleNumber(idPrevCycle)) ...
                           transitionCycleDuration ...
                           repmat(cycleDuration(2), 1, 999)];
                        for id = 2:length(dates)
                           dates(id) = dates(id) + dates(id-1);
                        end
                        cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
                        
                        [~, idMin] = min(abs(dates-firstArgosMsgDate));
                        cycleNumberFile = cycleNumbers(idMin);
                        
                     elseif (g_util_cycleNumber(idPrevCycle) == nbCyclesFirstMission)
                        
                        refDate = g_util_firstMsgDate(idPrevCycle);
                        dates = [ ...
                           refDate ...
                           transitionCycleDuration ...
                           repmat(cycleDuration(2), 1, 999)];
                        for id = 2:length(dates)
                           dates(id) = dates(id) + dates(id-1);
                        end
                        cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
                        
                        [~, idMin] = min(abs(dates-firstArgosMsgDate));
                        cycleNumberFile = cycleNumbers(idMin);
                        
                     else
                        
                        refDate = g_util_firstMsgDate(idPrevCycle);
                        dates = [ ...
                           refDate ...
                           repmat(cycleDuration(2), 1, 999)];
                        for id = 2:length(dates)
                           dates(id) = dates(id) + dates(id-1);
                        end
                        cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
                        
                        [~, idMin] = min(abs(dates-firstArgosMsgDate));
                        cycleNumberFile = cycleNumbers(idMin);
                        
                     end
                     
                  else
                     
                     % use float meta-data
                     
                     dates = [ ...
                        floatRefDay+delayBeforeMission/1440 ...
                        preludeDuration/1440+firstDeepCycleDuration ...
                        repmat(cycleDuration(1), 1, nbCyclesFirstMission-1) ...
                        transitionCycleDuration ...
                        repmat(cycleDuration(2), 1, 999)];
                     for id = 2:length(dates)
                        dates(id) = dates(id) + dates(id-1);
                     end
                     cycleNumbers = 0:length(dates);
                     
                     [~, idMin] = min(abs(dates-firstArgosMsgDate));
                     cycleNumberFile = cycleNumbers(idMin);
                     
                  end
               end
               
               if (~isempty(cycleNumberFile))
                  cycleNumber = [cycleNumber cycleNumberFile];
               else
                  fprintf('ERROR: Float #%d: Cannot determine cycle number for file: %s\n', ...
                     a_floatNum, subFileNameList{idFile});
                  cycleNumber = [];
                  break
               end
            else
               fprintf('ERROR: Float #%d: Cannot determine cycle number for file: %s\n', ...
                  a_floatNum, subFileNameList{idFile});
               cycleNumber = [];
               break
            end
         end
         
      else
         
         % the cycle number cannot be decoded from the transmitted data
         % we will use the transmission times to determine cycle number
         
         % multiple cycle durations only concern floats with a prelude phase
         
         % compute the duration of the cycle #1 (first deep cycle)
         firstDeepCycleDuration = firstProfileEndDate - floatRefDay - ...
            delayBeforeMission/1440 - preludeDuration/1440;
         
         % compute the duration of the transition cycle
         surfTime = firstProfileEndDate - fix(firstProfileEndDate);
         transitionCycleStartDate = surfTime + (nbCyclesFirstMission-1)*cycleDuration(1);
         transitionCycleEndDate = fix(transitionCycleStartDate + cycleDuration(2)) + surfTime;
         transitionCycleDuration = transitionCycleEndDate - transitionCycleStartDate;
         
         % try to use already computed cycles
         idPrevCycle = find(g_util_lastMsgDate < firstArgosMsgDate);
         if (~isempty(idPrevCycle))
            idPrevCycle = idPrevCycle(end);
            
            if (g_util_cycleNumber(idPrevCycle) == 0)
               
               refDate = g_util_lastMsgDate(idPrevCycle);
               dates = [ ...
                  refDate+firstDeepCycleDuration ...
                  repmat(cycleDuration(1), 1, nbCyclesFirstMission-1) ...
                  transitionCycleDuration ...
                  repmat(cycleDuration(2), 1, 999)];
               for id = 2:length(dates)
                  dates(id) = dates(id) + dates(id-1);
               end
               cycleNumbers = 1:length(dates);
               
               [~, idMin] = min(abs(dates-firstArgosMsgDate));
               cycleNumber = cycleNumbers(idMin);
               
            elseif ((g_util_cycleNumber(idPrevCycle) > 0) && (g_util_cycleNumber(idPrevCycle) < nbCyclesFirstMission))
               
               refDate = g_util_firstMsgDate(idPrevCycle);
               dates = [ ...
                  refDate ...
                  repmat(cycleDuration(1), 1, nbCyclesFirstMission-g_util_cycleNumber(idPrevCycle)) ...
                  transitionCycleDuration ...
                  repmat(cycleDuration(2), 1, 999)];
               for id = 2:length(dates)
                  dates(id) = dates(id) + dates(id-1);
               end
               cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
               
               [~, idMin] = min(abs(dates-firstArgosMsgDate));
               cycleNumber = cycleNumbers(idMin);
               
            elseif (g_util_cycleNumber(idPrevCycle) == nbCyclesFirstMission)
               
               refDate = g_util_firstMsgDate(idPrevCycle);
               dates = [ ...
                  refDate ...
                  transitionCycleDuration ...
                  repmat(cycleDuration(2), 1, 999)];
               for id = 2:length(dates)
                  dates(id) = dates(id) + dates(id-1);
               end
               cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
               
               [~, idMin] = min(abs(dates-firstArgosMsgDate));
               cycleNumber = cycleNumbers(idMin);
               
            else
               
               refDate = g_util_firstMsgDate(idPrevCycle);
               dates = [ ...
                  refDate ...
                  repmat(cycleDuration(2), 1, 999)];
               for id = 2:length(dates)
                  dates(id) = dates(id) + dates(id-1);
               end
               cycleNumbers = g_util_cycleNumber(idPrevCycle):g_util_cycleNumber(idPrevCycle)+length(dates);
               
               [~, idMin] = min(abs(dates-firstArgosMsgDate));
               cycleNumber = cycleNumbers(idMin);
               
            end
            
         else
            
            % use float meta-data
            
            dates = [ ...
               floatRefDay+delayBeforeMission/1440 ...
               preludeDuration/1440+firstDeepCycleDuration ...
               repmat(cycleDuration(1), 1, nbCyclesFirstMission-1) ...
               transitionCycleDuration ...
               repmat(cycleDuration(2), 1, 999)];
            for id = 2:length(dates)
               dates(id) = dates(id) + dates(id-1);
            end
            cycleNumbers = 0:length(dates);
            
            [~, idMin] = min(abs(dates-firstArgosMsgDate));
            cycleNumber = cycleNumbers(idMin);
            
         end
      end
   end
else
   move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, [], 'TTT');
   
   fprintf('INFO: Last date of input file (%s) is before float launch date (%s) - file stored without cycle number (i.e. not decoded)\n', ...
      julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
      julian_2_gregorian_dec_argo(launchDate));
   return
end

% create the name of the input file and move it to the approriate directory
if (~isempty(cycleNumber))
   if (length(cycleNumber) == 1)
      if (cycleNumber < 0)
         move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, [], 'MMM');
         
         fprintf('ERROR: Computed cycle number is negative (%d): check the consistency of the meta-data - file stored without cycle number (i.e. not decoded)\n', ...
            cycleNumber);
      else
         move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, cycleNumber);
         
         g_util_cycleNumber = [g_util_cycleNumber; cycleNumber];
         g_util_firstMsgDate = [g_util_firstMsgDate; firstArgosMsgDate];
         g_util_lastMsgDate = [g_util_lastMsgDate; lastArgosMsgDate];
      end
   else
      for idFile = 1:length(subFileNameList)
         
         % read Argos file
         [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
            argosDataDate, argosDataData] = read_argos_file_fmt1({subFileNameList{idFile}}, a_argosId, frameLen);
         firstArgosMsgDate = min(argosDataDate);
         lastArgosMsgDate = max(argosDataDate);
         
         g_decArgo_inputArgosFile = subFileNameList{idFile};
         
         if (cycleNumber(idFile) < 0)
            move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, [], 'MMM');
            
            fprintf('ERROR: Computed cycle number is negative (%d): check the consistency of the meta-data - file stored without cycle number (i.e. not decoded)\n', ...
               cycleNumber(idFile));
         else
            move_argos_input_file(a_argosId, firstArgosMsgDate, a_floatNum, cycleNumber(idFile));
            
            g_util_cycleNumber = [g_util_cycleNumber; cycleNumber(idFile)];
            g_util_firstMsgDate = [g_util_firstMsgDate; firstArgosMsgDate];
            g_util_lastMsgDate = [g_util_lastMsgDate; lastArgosMsgDate];
         end
      end
   end
end

return
