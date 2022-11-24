% ------------------------------------------------------------------------------
% For a given list of floats, process the associated Argos cycle files by:
%   1: renaming the files (according to float and cycle numbers)
%   2: moving the file to the apropriate directory.
%
% SYNTAX :
%   move_and_rename_apx_argos_files or move_and_rename_apx_argos_files(6900189, 7900118)
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
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_apx_argos_files(varargin)

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_062608\ori_split_cycle\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_062608\ori_split_cycle_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061609\in_split_cycle\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061609\in_split_cycle_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_021009\in_split_cycle\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_021009\in_split_cycle_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\in_split_cycle\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\in_split_cycle_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_093008\in_split_cycle_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_093008\in_split_cycle_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\118188\in_split_cycle_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\118188\in_split_cycle_final\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\fichiers_cycle_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\fichiers_cycle_CORRECT_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\110813\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\110813_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\082213\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\082213_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\082213_1\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\082213_1_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\021208\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\021208_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\032213\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\032213_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\110613\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\110613_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\090413\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\090413_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\121512\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set2\121512_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\fichiers_cycle_apex_233_floats_bascule_20160823_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\fichiers_cycle_apex_233_floats_bascule_20160823_CORRECT_FINAL\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\071807\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\071807_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\082807\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\082807_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\020110\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\020110_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\090810\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\090810_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\102015\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\Apex_set3\102015_final\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\collectes_20161202\tmp2\ori_out\STEP4\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\collectes_20161202\tmp2\ori_out\FINAL\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\IN\ori_cycle_CORRECT\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\IN\FINAL\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEMPO\OUT\STEP4\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TEMPO\OUT\FINAL\';




% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% global input parameter information
global g_decArgo_processModeAll;
g_decArgo_processModeAll = 1;
global g_decArgo_processModeRedecode;
g_decArgo_processModeRedecode = 0;

% configuration values
global g_decArgo_dirInputHexArgosFileFormat1
g_decArgo_dirInputHexArgosFileFormat1 = DIR_OUTPUT_ARGOS_FILES;
global g_decArgo_hexArgosFileFormat;
g_decArgo_hexArgosFileFormat = 1;

% output CSV file Id
global g_decArgo_outputCsvFileId;
g_decArgo_outputCsvFileId = '';

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% mode processing flags
global g_decArgo_realtimeFlag;
g_decArgo_realtimeFlag = 0;
global g_decArgo_delayedModeFlag;
g_decArgo_delayedModeFlag = 0;

% current float WMO number
global g_decArgo_floatNum;

% global input parameter information
global g_decArgo_inputArgosFile;

global g_decArgo_dpfSplitDone;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_JSON_FLOAT_META_DATA_FILE';

% get configuration parameters
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

logFile = [DIR_LOG_FILE '/' 'move_and_rename_apx_argos_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
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
   
   floatNum = floatList(idFloat);
   g_decArgo_floatNum = floatNum;
   g_decArgo_dpfSplitDone = 0;
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
                  fprintf('INFO: Date of input file (%s) is after float end decoding date (%s) => file stored without cycle number (i.e. not decoded)\n', ...
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
            fprintf('ERROR: Not expected file name: %s => file not considered\n', argosFileName);
         end
      else
         fprintf('ERROR: Not expected file name: %s => file not considered\n', argosFileName);
      end
   end
   
   % chronologically sort the files
   [argosFileFirstMsgDate, idSort] = sort(argosFileFirstMsgDate);
   argosFileNames = argosFileNames(idSort);

   % process the Argos files of the float
   move_and_rename_files(argosFileNames, floatNum, floatInformationFileName);
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
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_files(a_argosFileNames, a_floatNum, ...
   a_floatInformationFileName)

% global input parameter information
global g_decArgo_inputArgosFile;

% miscellaneous decoder configuration parameters
global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNumMsgForNotGhost;

global g_decArgo_dpfSplitDone;

% minimum number of float messages for not only ghosts in contents
NB_MSG_MIN = g_decArgo_minNumMsgForNotGhost;

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
floatArgosId = str2double(listArgosId{idFloat});
floatLaunchDate = listLaunchDate(idFloat);
floatCycleTime = listCycleTime(idFloat);

% retrieve useful float meta-data
[launchDate, preludeDuration, profilePressure, cycleDuration, dpfFloatFlag] = ...
   get_apx_meta_data_for_cycle_number_determination(a_floatNum, floatLaunchDate, floatCycleTime, floatDecId);

% minimum duration of the first deep cycle for a DPF float (first transmission
% is expected to occur after an ascent/descent at profile pressure with an
% average speed of 10 cm/s)
dpfFirstDeepCycleDuration = (profilePressure*2/0.1)/3600;

% storage of already assigned cycles
tabCycleNumber = [];
tabFirstMsgDate = [];
tabLastMsgDate = [];
   
% first loop to decode cycle number from transmitted data
remainingArgosFileNames = [];
remainingFileCycleNumber = [];
offsetCyNum = 0;
nbFiles = length(a_argosFileNames);
for idFile = 1:nbFiles
   
   % process one Argos file
   argosFileName = a_argosFileNames{idFile};
   g_decArgo_inputArgosFile = argosFileName;
   
   % read Argos file
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataDate, argosDataData] = read_argos_file_fmt1({argosFileName}, floatArgosId, frameLen);
   firstArgosMsgDate = min(argosDataDate);
   lastArgosMsgDate = max(argosDataDate);
   
   % store file with only ghost messages without any cycle number
   if (isempty(argosDataDate))
      
      % search dates in the file without checking its consistency
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(argosFileName, floatArgosId);
      if (~isempty(argosDataDate))
         move_argos_input_file(floatArgosId, min(argosDataDate), a_floatNum, [], 'EEE');
      else
         move_argos_input_file(floatArgosId, min(argosLocDate), a_floatNum, [], 'EEE');
      end
      fprintf('INFO: File (%s) contains no Argos messages => file stored without cycle number (i.e. not decoded)\n', ...
         argosFileName);
      continue
   elseif (length(unique(argosDataDate)) < NB_MSG_MIN)
      
      move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, [], 'GGG');
      fprintf('INFO: File (%s) contains only ghost messages => file stored without cycle number (i.e. not decoded)\n', ...
         argosFileName);
      continue
   end
   
   % compute the cycle number
   
   if (isempty(launchDate))
      
      fprintf('ERROR: Unable to compute cycle number because of missing meta-data => file stored without cycle number (i.e. not decoded)\n');
      move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, [], 'MMM');
      continue
   else
      if (lastArgosMsgDate <= launchDate)
         
         fprintf('INFO: Last date of input file (%s) is before float launch date (%s) => file stored without cycle number (i.e. not decoded)\n', ...
            julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
            julian_2_gregorian_dec_argo(launchDate));
         move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, [], 'TTT');
         continue
      else
         
         subFileNameList = {argosFileName};
         
         % check if the input file contains data of prelude phase and first deep
         % cycle (generally occurs for DPF floats)
         if (isempty(tabCycleNumber) && (g_decArgo_dpfSplitDone == 0))

            diffArgosDataDates = diff(argosDataDate)*24;
            if (max(diffArgosDataDates) > dpfFirstDeepCycleDuration/2)
               
               % a significant pause in data transmission is probably due to a
               % DPF float first deep cycle => the file should be split
               
               [subFileNameList] = split_argos_file(argosFileName, a_floatNum, floatArgosId);
               if (~isempty(subFileNameList))
                  
                  fprintf('INFO: Argos cycle file split (%.1f hours without transmission): %s\n', ...
                     max(diffArgosDataDates), argosFileName);
               else
                  fprintf('ERROR: Unable to split Argos cycle file: %s\n', ...
                     argosFileName);
                  continue
               end
            end
         end
         g_decArgo_dpfSplitDone = 1;
         for idFile2 = 1:length(subFileNameList)
            
            argosFileName = subFileNameList{idFile2};
            g_decArgo_inputArgosFile = argosFileName;
            
            if (length(subFileNameList) == 2)
               % read Argos file
               [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
                  argosDataDate, argosDataData] = read_argos_file_fmt1({argosFileName}, floatArgosId, frameLen);
               firstArgosMsgDate = min(argosDataDate);
               lastArgosMsgDate = max(argosDataDate);
            end
            
            % decode the cycle number
            checkTestMsg = 0;
            if ((isempty(tabCycleNumber)) || ...
                  ((length(subFileNameList) == 2) && (idFile2 == 1)))
               checkTestMsg = 1;
            end
               
            [cycleNumber, cycleNumberCount] = decode_apex_cycle_number( ...
               argosFileName, floatDecId, floatArgosId, checkTestMsg);
            
            % specific
            if (a_floatNum == 3901639)
               cycleNumber = -1;
               cycleNumberCount = -1;
            end
            if (a_floatNum == 3901663)
               % Apex float 3901663 (decId 1022) regularly resets at sea
               if (cycleNumber == 1)
                  if (max([tabCycleNumber; remainingFileCycleNumber']) > 0)
                     offsetCyNum = max([tabCycleNumber; remainingFileCycleNumber']);
                     cycleNumberCount = 2;
                  end
               end
               cycleNumber = cycleNumber + offsetCyNum;
               
               offsetDate = gregorian_2_julian_dec_argo('2019/03/23 00:00:00');
               if (fix(firstArgosMsgDate) == offsetDate)
                  cycleNumber = 34;
                  cycleNumberCount = 2;
               end
               offsetDate2 = gregorian_2_julian_dec_argo('2019/04/22 00:00:00');
               if (fix(firstArgosMsgDate) == offsetDate2)
                  cycleNumber = 37;
                  cycleNumberCount = 2;
               end
               offsetDate3 = gregorian_2_julian_dec_argo('2019/05/12 00:00:00');
               if (fix(firstArgosMsgDate) == offsetDate3)
                  cycleNumber = 39;
                  cycleNumberCount = 2;
               end
               offsetDate4 = gregorian_2_julian_dec_argo('2019/05/31 00:00:00');
               if (fix(firstArgosMsgDate) == offsetDate4)
                  cycleNumber = 41;
                  cycleNumberCount = 2;
               end
            end
            
            if (cycleNumberCount > 1)
            
               % manage possible roll over of profile number counter
               if (~isempty(tabCycleNumber))
                  idPrevCycle = find(tabLastMsgDate < firstArgosMsgDate);
                  if (~isempty(idPrevCycle))
                     idPrevCycle = idPrevCycle(end);
                     while (cycleNumber < tabCycleNumber(idPrevCycle))
                        cycleNumber = cycleNumber + 256;
                     end
                  end
               end
               
               move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, cycleNumber);
               tabCycleNumber = [tabCycleNumber; cycleNumber];
               tabFirstMsgDate = [tabFirstMsgDate; firstArgosMsgDate];
               tabLastMsgDate = [tabLastMsgDate; lastArgosMsgDate];
            else
               remainingArgosFileNames{end+1} = argosFileName;
               remainingFileCycleNumber(end+1) = cycleNumber;
            end
         end
      end
   end
end
         
% second loop to estimate cycle number for remaining files
nbFiles = length(remainingArgosFileNames);
for idFile = 1:nbFiles
   
   % process one Argos file
   argosFileName = remainingArgosFileNames{idFile};
   g_decArgo_inputArgosFile = argosFileName;
   
   % read Argos file
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataDate, argosDataData] = read_argos_file_fmt1({argosFileName}, floatArgosId, frameLen);
   firstArgosMsgDate = min(argosDataDate);
   lastArgosMsgDate = max(argosDataDate);
   
   cycleNumber = [];

   % try to use already computed cycles
   idPrevCycle = find(tabLastMsgDate < firstArgosMsgDate);
   if (~isempty(idPrevCycle))
      idPrevCycle = idPrevCycle(end);
      prevNum = tabCycleNumber(idPrevCycle);
   else
      idPrevCycle = [];
      prevNum = [];
   end   
   idNextCycle = find(tabFirstMsgDate > lastArgosMsgDate);
   if (~isempty(idNextCycle))
      idNextCycle = idNextCycle(1);
      nextNum = tabCycleNumber(idNextCycle);
   else
      idNextCycle = [];
      nextNum = [];
   end   
   
   if (~isempty(nextNum))
      if ((nextNum == 0) || (nextNum == 1))
         cycleNumber = 0;
      else
         if (lastArgosMsgDate < launchDate + preludeDuration/24 + cycleDuration/48)
            % it is a DPF cycle, cycle number should be #0 or #1
            if ((~isempty(prevNum) && (prevNum == 0)) || ...
                  (lastArgosMsgDate > launchDate + preludeDuration/24 + dpfFirstDeepCycleDuration/24))
               cycleNumber = 1;
            else
               cycleNumber = 0;
            end
         else
            nbCycles = round((tabLastMsgDate(idNextCycle)-lastArgosMsgDate)*24/cycleDuration);
            if ((nbCycles == 0) && ...
                  ((tabLastMsgDate(idNextCycle)-lastArgosMsgDate)*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
               % we consider it is a new cycle if we have had a
               % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
               % transmission
               nbCycles = 1;
            end
            cycleNumber = nextNum - nbCycles;
         end
      end
   elseif (~isempty(prevNum))
      if (prevNum == 0)
         if (lastArgosMsgDate < launchDate + preludeDuration/24 + cycleDuration/48)
            % it is a DPF cycle, cycle number is #1
            cycleNumber = 1;
         else
            nbCycles = round((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24/cycleDuration);
            if ((nbCycles == 0) && ...
                  ((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
               % we consider it is a new cycle if we have had a
               % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
               % transmission
               nbCycles = 1;
            end
            cycleNumber = prevNum + nbCycles;
         end
      else
         nbCycles = round((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24/cycleDuration);
         if ((nbCycles == 0) && ...
               ((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
            % we consider it is a new cycle if we have had a
            % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
            % transmission
            nbCycles = 1;
         end
         cycleNumber = prevNum + nbCycles;
      end
   end
      
   % use float meta-data
   if (isempty(cycleNumber))
      firstProfileEndDate = launchDate + preludeDuration/24 + dpfFirstDeepCycleDuration/24;
      if (firstArgosMsgDate < launchDate + preludeDuration/24)
         cycleNumber = 0;
      elseif (firstArgosMsgDate < firstProfileEndDate)
         if (abs(firstArgosMsgDate-(launchDate + preludeDuration/24)) < abs(firstArgosMsgDate-firstProfileEndDate))
            cycleNumber = 0;
         else
            cycleNumber = 1;
         end
      else
         cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)*24/cycleDuration) + 1;
      end
   end
   
   if ((remainingFileCycleNumber(idFile) ~= -1) && ...
         (remainingFileCycleNumber(idFile) ~= cycleNumber))
      fprintf('WARNING: float #%d: computed cycle number (=%d) differs from decoded one (=%d) (but with a bad redundancy)\n', ...
         a_floatNum, cycleNumber, remainingFileCycleNumber(idFile));
   end

   move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, cycleNumber);
   tabCycleNumber = [tabCycleNumber; cycleNumber];
   tabFirstMsgDate = [tabFirstMsgDate; firstArgosMsgDate];
   tabLastMsgDate = [tabLastMsgDate; lastArgosMsgDate];
   [tabCycleNumber, idSort] = sort(tabCycleNumber);
   tabFirstMsgDate = tabFirstMsgDate(idSort);
   tabLastMsgDate = tabLastMsgDate(idSort);
end

dpfFloat = 0;
cyDur1 = (diff(tabFirstMsgDate)*24)./diff(tabCycleNumber);
cyDur2 = (diff(tabLastMsgDate)*24)./diff(tabCycleNumber);

fprintf('\n')

if ((length(tabCycleNumber) > 1) && isempty(setdiff(tabCycleNumber(1:2), [0 1])))
   if (cyDur2(1) < mean(cyDur2)/2)
      dpfFloat = 1;
      if (dpfFloatFlag ~= 1)
         fprintf('WARNING: float #%d is a DPF float (DPF cycle duration : %.1f hours)\n', ...
            a_floatNum, cyDur2(1));
      else
         fprintf('INFO: float #%d is a DPF float (DPF cycle duration : %.1f hours)\n', ...
            a_floatNum, cyDur2(1));
      end
   end
end
fprintf('INFO: float #%d cycle duration : mean1 %.1f hours (stdev1 %.1f hours); mean2 %.1f hours (stdev2 %.1f hours)\n', ...
   a_floatNum, mean(cyDur1(1+dpfFloat:end)), std(cyDur1(1+dpfFloat:end)), ...
   mean(cyDur2(1+dpfFloat:end)), std(cyDur2(1+dpfFloat:end)));

fprintf('\n')

return
