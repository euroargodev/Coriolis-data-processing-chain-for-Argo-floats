% ------------------------------------------------------------------------------
% Find the float WMO number and compute the cycle number associated to the Argos
% input file.
% Rename and move the Argos input file in the correct directory (according to
% the 'processmode' input parameter value).
%
% SYNTAX :
%  [o_floatList, o_stopProcess] = rename_argos_input_file
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_floatList   : WMO number of the float to process
%   o_stopProcess : stop processing flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatList, o_stopProcess] = rename_argos_input_file

% output parameters initialization
o_floatList = [];
o_stopProcess = 1;

% global input parameter information
global g_decArgo_processModeAll;
global g_decArgo_inputArgosFile;

% configuration values
global g_decArgo_dirInputHexArgosFileFormat1

% miscellaneous decoder configuration parameters
global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNumMsgForNotGhost;
global g_decArgo_minNonTransDurForGhost;

% default values
global g_decArgo_janFirst1950InMatlab;

% minimum duration of the non-transmission periods for a given file (in hour)
MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE = g_decArgo_minNonTransDurForNewCycle;

% min non-trans duration (in hour) to use the ghost detection
MIN_NON_TRANS_DURATION_FOR_GHOST = g_decArgo_minNonTransDurForGhost;


% argos input file name
[pathstr, inputArgosFileName, ext] = fileparts(g_decArgo_inputArgosFile);
inputArgosFileName = [inputArgosFileName ext];

% find the WMO number of the float
idPos = strfind(inputArgosFileName, '_');
if (~isempty(idPos))
   floatArgosId = str2num(inputArgosFileName(1:idPos(1)-1));
   
   [floatNum, floatArgosId2, ...
      floatDecVersion, floatDecId, ...
      floatFrameLen, ...
      floatCycleTime, floatDriftSamplingPeriod, floatDpfFlag, ...
      floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
      floatRefDay, floatEndDate, floatDmFlag] = get_one_float_info([], floatArgosId);
   
   if (~isempty(floatNum))
      o_floatList = floatNum;
      
      if (isempty(floatDecId))
         % this float cannot be decoded by this decoder
         minArgosDataDate = datenum(inputArgosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
         move_argos_input_file(floatArgosId, minArgosDataDate, floatNum, [], 'MMM');
         return;
      end
   else
      if (g_decArgo_processModeAll == 1)
         % read Argos file
         [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
            argosDataDate, argosDataData] = read_argos_file({g_decArgo_inputArgosFile}, floatArgosId, 31);
         firstArgosMsgDate = min(argosDataDate);
         
         if (isempty(firstArgosMsgDate))
            
            % search dates in the file without checking its consistency
            [argosLocDate, argosDataDate] = ...
               read_argos_file_fmt1_rough(g_decArgo_inputArgosFile, floatArgosId);
            
            if ~(isempty(argosDataDate) && isempty(argosDataDate))
               if (~isempty(argosDataDate))
                  move_argos_input_file(floatArgosId, min(argosDataDate), [], [], 'EEE');
               elseif (~isempty(argosLocDate))
                  move_argos_input_file(floatArgosId, min(argosLocDate), [], [], 'EEE');
               end
               
               fprintf('DEC_INFO: Empty Argos file (%s) => stored\n', ...
                  g_decArgo_inputArgosFile);
            else
               % create the Argos Id directory
               argosIdDirName = [g_decArgo_dirInputHexArgosFileFormat1 '/' sprintf('%06d', floatArgosId) '/'];
               if ~(exist(argosIdDirName, 'dir') == 7)
                  mkdir(argosIdDirName);
               end
               % create the empty files directory
               emptyFilesDirName = [argosIdDirName '/empty_files/'];
               if ~(exist(emptyFilesDirName, 'dir') == 7)
                  mkdir(emptyFilesDirName);
               end
               
               % move the Argos input file in the empty files directory
               fileNameIn = g_decArgo_inputArgosFile;
               fileNamOut = [emptyFilesDirName inputArgosFileName];
               move_file(fileNameIn, fileNamOut);
               
               fprintf('DEC_INFO: Empty Argos file (%s) => stored (in the ''empty_files'' directory)\n', ...
                  g_decArgo_inputArgosFile);
            end
         else
            % check if the input Argos file is consistent for RT decoding
            % (non-transmission periods less than MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE)
            argosDataDate = sort(argosDataDate);
            if (~isempty(find(diff(argosDataDate)*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE, 1)))
               fprintf('ERROR: Inconsistent input Argos file (%s) contents for the Real Time decoder (all non-transmission periods should be less than %d hours)\n', ...
                  g_decArgo_inputArgosFile, MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE);
               return;
            end
            
            if (length(unique(argosDataDate)) < g_decArgo_minNumMsgForNotGhost)
               move_argos_input_file(floatArgosId, firstArgosMsgDate, [], [], 'GGG');
               
               fprintf('DEC_INFO: Ghost Argos file (%s) => stored\n', ...
                  g_decArgo_inputArgosFile);
            else
               move_argos_input_file(floatArgosId, firstArgosMsgDate, [], [], 'WWW');
               
               fprintf('DEC_INFO: Argos file without associated WMO number (%s) => stored\n', ...
                  g_decArgo_inputArgosFile);
            end
         end
      end
      return;
   end
else
   fprintf('ERROR: Inconsistent input Argos file name (%s)\n', inputArgosFileName);
   return;
end

% read Argos file
[argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
   argosDataDate, argosDataData] = read_argos_file({g_decArgo_inputArgosFile}, floatArgosId, floatFrameLen);
firstArgosMsgDate = min(argosDataDate);
lastArgosMsgDate = max(argosDataDate);

% check if the input Argos file is consistent for RT decoding
% (non-transmission periods less than MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE)
argosDataDate = sort(argosDataDate);
if (~isempty(find(diff(argosDataDate)*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE, 1)))
   fprintf('ERROR: Inconsistent input Argos file contents (%s) for the Real Time decoder (all non-transmission periods should be less than %d hours)\n', ...
      g_decArgo_inputArgosFile, MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE);
   return;
end

% do not consider empty files or files with only ghost messages
if (g_decArgo_processModeAll == 1)
   if (isempty(firstArgosMsgDate))
      % search dates in the file without checking its consistency
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(g_decArgo_inputArgosFile, floatArgosId);
      
      if ~(isempty(argosDataDate) && isempty(argosDataDate))
         if (~isempty(argosDataDate))
            move_argos_input_file(floatArgosId, min(argosDataDate), floatNum, [], 'EEE');
         elseif (~isempty(argosLocDate))
            move_argos_input_file(floatArgosId, min(argosLocDate), floatNum, [], 'EEE');
         end
         
         fprintf('DEC_WARNING: Empty Argos file (%s) => stored but not decoded\n', ...
            g_decArgo_inputArgosFile);
      else
         % create the Argos Id directory
         argosIdDirName = [g_decArgo_dirInputHexArgosFileFormat1 '/' sprintf('%06d', floatArgosId) '/'];
         if ~(exist(argosIdDirName, 'dir') == 7)
            mkdir(argosIdDirName);
         end
         % create the empty files directory
         emptyFilesDirName = [argosIdDirName '/empty_files/'];
         if ~(exist(emptyFilesDirName, 'dir') == 7)
            mkdir(emptyFilesDirName);
         end
         
         % move the Argos input file in the empty files directory
         fileNameIn = g_decArgo_inputArgosFile;
         fileNamOut = [emptyFilesDirName inputArgosFileName];
         move_file(fileNameIn, fileNamOut);
         
         fprintf('DEC_WARNING: Empty Argos file (%s) => stored (in the ''empty_files'' directory) but not decoded\n', ...
            g_decArgo_inputArgosFile);
      end
      
      return;
   elseif (length(unique(argosDataDate)) < g_decArgo_minNumMsgForNotGhost)
      move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, [], 'GGG');
      
      fprintf('DEC_WARNING: Ghost Argos file (%s) => stored but not decoded\n', ...
         g_decArgo_inputArgosFile);
      
      return;
   end
end

% find the cycle number

if (floatDecId < 1000)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % NKE FLOATS
   
   % retrieve useful float meta-data
   [launchDate, delayBeforeMission, preludeDuration, firstProfileEndDate, cycleDuration, nbCyclesFirstMission] = ...
      get_meta_data_for_cycle_number_determination(floatNum, floatDecId, floatLaunchDate, floatCycleTime, floatRefDay);
   if (isempty(launchDate))
      if (g_decArgo_processModeAll == 1)
         move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, [], 'MMM');
         
         fprintf('ERROR: Float #%d: Unable to compute cycle number because of missing meta-data => stored but not decoded\n', floatNum);
      else
         fprintf('ERROR: Float #%d: Unable to compute cycle number because of missing meta-data => not decoded\n', floatNum);
      end
      return;
   end
   
   % retrieve useful TRAJ data
   [cycleNumberTraj, firstMsgDateTraj, lastMsgDateTraj] = ...
      get_traj_data_for_cycle_number_determination(floatNum);
   
   % estimate the cycle number
   cycleNumber = [];
   if (lastArgosMsgDate > launchDate)
      if (length(cycleDuration) == 1)
         
         % floats with one cycle duration
         
         if (get_default_prelude_duration(floatDecId) == 0)
            
            % floats with no prelude phase
            
            % try to use TRAJ dates
            idPrevCycle = find(lastMsgDateTraj < firstArgosMsgDate);
            if (~isempty(idPrevCycle))
               idPrevCycle = idPrevCycle(end);
               nbCycles = round((firstArgosMsgDate-firstMsgDateTraj(idPrevCycle))/cycleDuration);
               if ((nbCycles == 0) && ...
                     ((firstArgosMsgDate-lastMsgDateTraj(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
                  % we consider it is a new cycle if we have had a
                  % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
                  % transmission
                  nbCycles = 1;
               end
               cycleNumber = cycleNumberTraj(idPrevCycle) + nbCycles;
            end
            
            % use float meta-data
            if (isempty(cycleNumber))
               cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)/cycleDuration);
               %          fprintf('INFO: Cycle number (%d) has been computed from meta-data only\n', cycleNumber);
            end
            
         else
            
            % floats with a prelude phase
            
            % try to use TRAJ dates
            idPrevCycle = find(lastMsgDateTraj < firstArgosMsgDate);
            if (~isempty(idPrevCycle))
               idPrevCycle = idPrevCycle(end);
               if (cycleNumberTraj(idPrevCycle) == 0)
                  cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)/cycleDuration) + 1;
                  if ((cycleNumber == 0) && ...
                        ((firstArgosMsgDate-lastMsgDateTraj(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
                     % we consider it is a new cycle if we have had a
                     % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
                     % transmission
                     cycleNumber = 1;
                  end
               else
                  nbCycles = round((firstArgosMsgDate-firstMsgDateTraj(idPrevCycle))/cycleDuration);
                  if ((nbCycles == 0) && ...
                        ((firstArgosMsgDate-lastMsgDateTraj(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
                     % we consider it is a new cycle if we have had a
                     % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
                     % transmission
                     nbCycles = 1;
                  end
                  cycleNumber = cycleNumberTraj(idPrevCycle) + nbCycles;
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
         decodedCycleNumber = decode_cycle_number(g_decArgo_inputArgosFile, ...
            floatNum, floatArgosId, floatFrameLen, floatDecId);
         
         if (~isempty(decodedCycleNumber) && (decodedCycleNumber ~= -1))
            % the cycle number has been decoded from the transmitted data
            cycleNumber = decodedCycleNumber;
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
            idPrevCycle = find(lastMsgDateTraj < firstArgosMsgDate);
            if (~isempty(idPrevCycle))
               idPrevCycle = idPrevCycle(end);
               
               if (cycleNumberTraj(idPrevCycle) == 0)
                  
                  refDate = lastMsgDateTraj(idPrevCycle);
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
                  
               elseif ((cycleNumberTraj(idPrevCycle) > 0) && (cycleNumberTraj(idPrevCycle) < nbCyclesFirstMission))
                  
                  refDate = firstMsgDateTraj(idPrevCycle);
                  dates = [ ...
                     refDate ...
                     repmat(cycleDuration(1), 1, nbCyclesFirstMission-cycleNumberTraj(idPrevCycle)) ...
                     transitionCycleDuration ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = cycleNumberTraj(idPrevCycle):cycleNumberTraj(idPrevCycle)+length(dates);
                  
                  [~, idMin] = min(abs(dates-firstArgosMsgDate));
                  cycleNumber = cycleNumbers(idMin);
                  
               elseif (cycleNumberTraj(idPrevCycle) == nbCyclesFirstMission)
                  
                  refDate = firstMsgDateTraj(idPrevCycle);
                  dates = [ ...
                     refDate ...
                     transitionCycleDuration ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = cycleNumberTraj(idPrevCycle):cycleNumberTraj(idPrevCycle)+length(dates);
                  
                  [~, idMin] = min(abs(dates-firstArgosMsgDate));
                  cycleNumber = cycleNumbers(idMin);
                  
               else
                  
                  refDate = firstMsgDateTraj(idPrevCycle);
                  dates = [ ...
                     refDate ...
                     repmat(cycleDuration(2), 1, 999)];
                  for id = 2:length(dates)
                     dates(id) = dates(id) + dates(id-1);
                  end
                  cycleNumbers = cycleNumberTraj(idPrevCycle):cycleNumberTraj(idPrevCycle)+length(dates);
                  
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
      if (g_decArgo_processModeAll == 1)
         move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, [], 'TTT');
         
         fprintf('DEC_INFO: Float #%d: Last date of input file (%s) is before float launch date (%s) => stored but not decoded\n', ...
            floatNum, ...
            julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
            julian_2_gregorian_dec_argo(launchDate));
      else
         fprintf('DEC_INFO: Float #%d: Last date of input file (%s) is before float launch date (%s) => not decoded\n', ...
            floatNum, ...
            julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
            julian_2_gregorian_dec_argo(launchDate));
      end
      return;
   end
   
   % create the name of the input file and move it to the approriate directory
   if (~isempty(cycleNumber))
      if (cycleNumber < 0)
         if (g_decArgo_processModeAll == 1)
            move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, [], 'MMM');
            
            fprintf('ERROR: Float #%d: Computed cycle number is negative (%d): check the consistency of the meta-data => stored but not decoded\n', ...
               floatNum, cycleNumber);
         else
            fprintf('ERROR: Float #%d: Computed cycle number is negative (%d): check the consistency of the meta-data => not decoded\n', ...
               floatNum, cycleNumber);
         end
      else
         if (move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, cycleNumber) == 1)
            o_stopProcess = 0;
         end
      end
   end
   
else
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % APEX FLOATS
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % split DPF float file and rename Argos cycle file(s)

   % temporary directory used to split DPF Argos file
   splitTmpDir = '';
   
   % retrieve useful float meta-data
   [launchDate, preludeDuration, profilePressure, cycleDuration, dpfFloatFlag] = ...
      get_apx_meta_data_for_cycle_number_determination(floatNum, floatDecId, floatLaunchDate, floatCycleTime);

   if (isempty(launchDate))
      if (g_decArgo_processModeAll == 1)
         move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, [], 'MMM');
         
         fprintf('ERROR: Float #%d: Unable to compute cycle number because of missing meta-data => stored but not decoded\n', floatNum);
      else
         fprintf('ERROR: Float #%d: Unable to compute cycle number because of missing meta-data => not decoded\n', floatNum);
      end
      return;
   end
   
   % minimum duration of the first deep cycle for a DPF float (first transmission
   % is expected to occur after an ascent/descent at profile pressure with an
   % average speed of 10 cm/s)
   dpfFirstDeepCycleDuration = (profilePressure*2/0.1)/3600;

   % storage of already assigned cycles

   % retrieve useful TRAJ data
   [tabCycleNumber, tabFirstMsgDate, tabLastMsgDate] = ...
      get_traj_data_for_cycle_number_determination(floatNum);
   
   % compute the cycle number

   if (lastArgosMsgDate > launchDate)

      subFileNameList = {g_decArgo_inputArgosFile};
      
      % check if the input file contains data of prelude phase and first deep
      % cycle (generally occurs for DPF floats)
      if (isempty(tabCycleNumber) || (max(tabCycleNumber) < 1))
         
         diffArgosDataDates = diff(argosDataDate)*24;
         if (max(diffArgosDataDates) > dpfFirstDeepCycleDuration/2)
            
            % a significant pause in data transmission is probably due to a
            % DPF float first deep cycle => the file should be split
            [subFileNameList, splitTmpDir] = split_argos_file(g_decArgo_inputArgosFile, floatNum, floatArgosId);
            if (~isempty(subFileNameList))
               
               fprintf('DEC_INFO: Float #%d: Argos cycle file split (%.1f hours without transmission): %s\n', ...
                  floatNum, max(diffArgosDataDates), g_decArgo_inputArgosFile);

            else
               fprintf('ERROR: Float #%d: Unable to split Argos cycle file: %s\n', ...
                  floatNum, g_decArgo_inputArgosFile);
               return;
            end
         end
      end
      
      for idFile = 1:length(subFileNameList)
         
         g_decArgo_inputArgosFile = subFileNameList{idFile};
         
         if (length(subFileNameList) == 2)
            % read Argos file
            [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
               argosDataDate, argosDataData] = read_argos_file({g_decArgo_inputArgosFile}, floatArgosId, floatFrameLen);
            firstArgosMsgDate = min(argosDataDate);
            lastArgosMsgDate = max(argosDataDate);
         end
         
         % try to decode the cycle number
         checkTestMsg = 0;
         if (((length(subFileNameList) == 2) && (idFile == 1)) || ...
               (isempty(tabCycleNumber) || (max(tabCycleNumber) < 1)))
            checkTestMsg = 1;
         end
         
         [cycleNumber, cycleNumberCount] = decode_apex_cycle_number( ...
            g_decArgo_inputArgosFile, floatDecId, floatArgosId, checkTestMsg);
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
            
            if (g_decArgo_processModeAll == 1)
               if (move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, cycleNumber) ~= 1)
                  return;
               else
                  if ((length(subFileNameList) == 1) || ...
                        ((length(subFileNameList) == 2) && (idFile == 2)))
                     o_stopProcess = 0;
                  end
               end
            else
               if ((length(subFileNameList) == 1) || ...
                     ((length(subFileNameList) == 2) && (idFile == 2)))
                  if (move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, cycleNumber) == 1)
                     o_stopProcess = 0;
                  end
               end
            end
         else
            
            % estimate cycle number from meta-data

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
               if (nextNum == 1)
                  cycleNumber = 0;
               else
                  if (lastArgosMsgDate < launchDate + preludeDuration/24 + cycleDuration/48)
                     % it is a DPF cycle, cycle number should be #0 or #1
                     if ((~isempty(prevNum) && (prevNum == 0)) || ...
                           (lastArgosMsgDate > dpfFirstDeepCycleDuration/24))
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
            
            if (g_decArgo_processModeAll == 1)
               if (move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, cycleNumber) ~= 1)
                  return;
               else
                  if ((length(subFileNameList) == 1) || ...
                        ((length(subFileNameList) == 2) && (idFile == 2)))
                     o_stopProcess = 0;
                  end
               end
            else
               if ((length(subFileNameList) == 1) || ...
                     ((length(subFileNameList) == 2) && (idFile == 2)))
                  if (move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, cycleNumber) == 1)
                     o_stopProcess = 0;
                  end
               end
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % clean last message ghosts from renamed files
         if (~isempty(tabCycleNumber))
            
            if (~ismember(floatDpfFlag, [0 1]))
               fprintf('DEC_WARNING: Float #%d: Inconsistent DPF float flag value (= %d) => set to 1\n', ...
                  floatNum, floatDpfFlag);
               
               floatDpfFlag = 1;
            end
            
            idUsed = find(tabCycleNumber >= floatDpfFlag);
            tabCycleNumberBis = tabCycleNumber(idUsed);
            tabLastMsgDateBis = tabLastMsgDate(idUsed);
            
            if (~isempty(tabCycleNumberBis))
               
               tabLastMsgDateBis = tabLastMsgDateBis-compute_duration(tabCycleNumberBis, tabCycleNumberBis(1), ones(max(tabCycleNumberBis)+1, 1)*floatCycleTime)';
               lastArgosMsgDateBis = lastArgosMsgDate-compute_duration(cycleNumber, tabCycleNumberBis(1), ones(max(tabCycleNumberBis)+1, 1)*floatCycleTime)';
               
               %                if ((lastArgosMsgDateBis-mean(tabLastMsgDateBis))*24 > 0)
               %                   fprintf('Cycle #%3d: LAST %s\n', ...
               %                      cycleNumber, ...
               %                      format_time_dec_argo((lastArgosMsgDateBis-mean(tabLastMsgDateBis))*24));
               %                end
               
               if ((lastArgosMsgDateBis-mean(tabLastMsgDateBis))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST)
                  argosDate = [argosLocDate; argosDataDate];
                  argosDate = sort(argosDate);
                  argosDate = argosDate-compute_duration(cycleNumber, tabCycleNumberBis(1), ones(max(tabCycleNumberBis)+1, 1)*floatCycleTime)';
                  
                  if (g_decArgo_processModeAll == 1)
                     argosDirName = [g_decArgo_dirInputHexArgosFileFormat1 '/' sprintf('%06d', floatArgosId) '/'];
                  else
                     argosDirName = [g_decArgo_dirInputHexArgosFileFormat1 '/' sprintf('%06d', floatArgosId) '/tmp/'];
                  end
                  argosPathFileName = dir([argosDirName sprintf('%d_*_%03d.txt', floatArgosId, cycleNumber)]);
                  argosPathFileName = [argosDirName argosPathFileName(1).name];
                  while (~isempty(argosDate) && ((argosDate(end)-mean(tabLastMsgDateBis))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST))
                     
                     % a ghost message is detected, move it to a dedicated file
                     [subFileNameList] = split_argos_file_ghost(argosPathFileName, floatNum, floatArgosId);
                     argosPathFileName = subFileNameList{1};
                     
                     argosDate(end) = [];
                     lastArgosMsgDate = argosDate(end);
                     fprintf('DEC_INFO: Float #%d: Ghost detected in LMT: stored in %s\n', ...
                        floatNum, subFileNameList{2});
                  end
               end
               
            end
         end
         
         tabCycleNumber = [tabCycleNumber; cycleNumber];
         tabFirstMsgDate = [tabFirstMsgDate; firstArgosMsgDate];
         tabLastMsgDate = [tabLastMsgDate; lastArgosMsgDate];
         [tabCycleNumber, idSort] = sort(tabCycleNumber);
         tabFirstMsgDate = tabFirstMsgDate(idSort);
         tabLastMsgDate = tabLastMsgDate(idSort);
      end
   else
      
      if (g_decArgo_processModeAll == 1)
         move_argos_input_file(floatArgosId, firstArgosMsgDate, floatNum, [], 'TTT');
         
         fprintf('DEC_INFO: Float #%d: Last date of input file (%s) is before float launch date (%s) => stored but not decoded\n', ...
            floatNum, ...
            julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
            julian_2_gregorian_dec_argo(launchDate));
      else
         fprintf('DEC_INFO: Float #%d: Last date of input file (%s) is before float launch date (%s) => not decoded\n', ...
            floatNum, ...
            julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
            julian_2_gregorian_dec_argo(launchDate));
      end
      return;
   end
   
   % delete the temporary sub-directory
   if (~isempty(splitTmpDir) && (exist(splitTmpDir, 'dir') == 7))
      [statusRmdir, message, messageId] = rmdir(splitTmpDir, 's');
      if (statusRmdir == 0)
         fprintf('ERROR: Error while deleting the %s directory (%s)\n', ...
            splitTmpDir, ...
            message);
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Compute durations between cycles.
%
% SYNTAX :
%  [o_duration] = compute_duration(a_tabEndCyNum, a_startCyNum, a_cycleTime)
%
% INPUT PARAMETERS :
%   a_tabEndCyNum : end cycle numbers
%   a_startCyNum  : start cycle number
%   a_cycleTime   : cycle durations
%
% OUTPUT PARAMETERS :
%   o_duration : durations between cycles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_duration] = compute_duration(a_tabEndCyNum, a_startCyNum, a_cycleTime)

% output parameters initialization
o_duration = [];

for id = 1:length(a_tabEndCyNum)
   % cycles to compute the duration
   cyNum = [a_startCyNum+1:a_tabEndCyNum(id)];
   if (~isempty(cyNum))
      o_duration(id) = sum(a_cycleTime(cyNum));
   else
      o_duration(id) = 0;
   end
end

o_duration = o_duration/24;

return;
