% ------------------------------------------------------------------------------
% Detect ghost message at the end of the transmission and move it to a dedicated
% file.
%
% SYNTAX :
%   clean_ghost_in_apx_argos_cycle_files or clean_ghost_in_apx_argos_cycle_files(6900189, 7900118)
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
%   11/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function clean_ghost_in_apx_argos_cycle_files(varargin)

% directory of the argos files to check
DIR_INPUT_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\fichiers_cycle_apex_233_floats_bascule_20160823_CORRECT_FINAL\';

% directory to store the log and CSV files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% min non-trans duration (in hour) to use the ghost detection
MIN_NON_TRANS_DURATION_FOR_GHOST = 3;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};

if (nargin == 0)
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('File not found: %s\n', floatListFileName);
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

logFile = [DIR_LOG_FILE '/' 'clean_ghost_in_apx_argos_cycle_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDpfFlag, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   tabCycleNumber = [];
   tabLastMsgDate = [];
   tabFilename = [];
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find current float Argos Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d\n', floatNum);
      fprintf('(nothing done)\n');
      continue;
   end
   floatArgosId = str2num(listArgosId{idF});
   floatCycleTime = double(listCycleTime(idF));
   floatDpfFlag = listDpfFlag(idF);
   if (~ismember(floatDpfFlag, [0 1]))
      fprintf('Float %d: inconsistent DPF float flag value (= %d)\n', ...
         floatNum, floatDpfFlag);
      floatDpfFlag = 1;
   end
   
   % select and sort the Argos files of the float
   dirFloat = [DIR_INPUT_OUTPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [dirFloat '/' argosFileName];
      
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(argosFilePathName, floatArgosId);
      argosDate = [argosLocDate; argosDataDate];
      argosDate = sort(argosDate);
      
      cycleNumber = [];
      [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
      if (isempty(errmsg1) && (count1 == 9) && (val1(8) == floatNum))
         cycleNumber = val1(9);
         if (cycleNumber > floatDpfFlag)
            tabCycleNumber = [tabCycleNumber; cycleNumber];
            tabLastMsgDate = [tabLastMsgDate; max(argosDataDate)];
            tabFilename{end+1} = argosFilePathName;
         end
      end
   end
   
   if (~isempty(tabCycleNumber))
      
      tabLastMsgDateBis = tabLastMsgDate-compute_duration(tabCycleNumber, tabCycleNumber(1), ones(max(tabCycleNumber)+1, 1)*floatCycleTime)';
      
      for idCy = 1:length(tabCycleNumber)
         
         tabLast = tabLastMsgDateBis;
         tabLast(idCy) = [];
         
         if ((tabLastMsgDateBis(idCy)-mean(tabLast))*24 > 0)
            fprintf('Cycle #%3d: LAST %s\n', ...
               tabCycleNumber(idCy), ...
               format_time_dec_argo((tabLastMsgDateBis(idCy)-mean(tabLast))*24));
         end
         
         if ((tabLastMsgDateBis(idCy)-mean(tabLast))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST)
            [argosLocDate, argosDataDate] = ...
               read_argos_file_fmt1_rough(tabFilename{idCy}, floatArgosId);
            
            % in bad transmission conditions the algorithm can fail; we must
            % then check the data to confirm the ghost
            if (any(diff(sort(argosDataDate))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST))
               argosDate = [argosLocDate; argosDataDate];
               argosDate = sort(argosDate);
               argosDate = argosDate-compute_duration(tabCycleNumber(idCy), tabCycleNumber(1), ones(max(tabCycleNumber)+1, 1)*floatCycleTime)';
               argosPathFileName = tabFilename{idCy};
               while (~isempty(argosDate) && ((argosDate(end)-mean(tabLast))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST))
                  
                  % a ghost message is detected, move it to a dedicated file
                  [subFileNameList] = split_argos_file_ghost(argosPathFileName, floatNum, floatArgosId);
                  argosPathFileName = subFileNameList{1};
                  
                  argosDate(end) = [];
                  fprintf('=> GHOST DETECTED: stored in %s\n', subFileNameList{2});
               end
            else
               fprintf('=> THIS IS NOT A GHOST\n');
            end
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

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
