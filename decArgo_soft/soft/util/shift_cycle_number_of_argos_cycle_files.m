% ------------------------------------------------------------------------------
% Shift cycle numbers of Argos cycle files.
%
% SYNTAX :
% shift_cycle_number_of_argos_cycle_files(WMO, cycle_number_offset, start_cycle, end_cycle) => shift (by cycle_number_offset) cycle number of Argos cycle files of float #WMO from start_cycle to end_cycle
% or
% shift_cycle_number_of_argos_cycle_files(WMO, cycle_number_offset, start_cycle)            => shift (by cycle_number_offset) cycle number of Argos cycle files of float #WMO from start_cycle to the last cycle
%
% INPUT PARAMETERS :
%   WMO                 : WMO number of the float
%   cycle_number_offset : number of cycles to shift
%   start_cycle         : first cycle to shift
%   end_cycle           : last cycle to shift
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2014 - RNU - creation
% ------------------------------------------------------------------------------
function shift_cycle_number_of_argos_cycle_files(varargin)

% directory of the Argos cycle files
DIR_INPUT_ARGOS_FILES = 'E:\TRANSFERT\NEW\_merge_final\479_cycle_CORRECT_final\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};

if ((nargin < 3) || (nargin > 4))
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   shift_cycle_number_of_argos_cycle_files(WMO, cycle_number_offset, start_cycle, end_cycle) => shift (by cycle_number_offset) cycle number of Argos cycle files of float #WMO from start_cycle to end_cycle or\n');
   fprintf('   shift_cycle_number_of_argos_cycle_files(WMO, cycle_number_offset, start_cycle)            => shift (by cycle_number_offset) cycle number of Argos cycle files of float #WMO from start_cycle to the last cycle\n');
   fprintf('aborted ...\n');
   return
else
   lastCycle = [];

   floatNum = varargin{1};
   offsetCycle = varargin{2};
   firstCycle = varargin{3};
   if (nargin > 3)
      lastCycle = varargin{4};
   end
   
   if (offsetCycle == 0)
      fprintf('cycle_number_offset is set to 0! => nothing to do\n');
      return
   end

   if (~isempty(lastCycle))
      if (firstCycle > lastCycle)
         fprintf('Start and end cycles should be consistently ordered!\n');
         fprintf('aborted ...\n');
         return
      end
   end
   
   if (~isempty(lastCycle))
      fprintf('Shift (by %d) cycle numbers of Argos cycle files of float #%d from cycle #%d to #%d\n', ...
         floatNum, ...
         offsetCycle, ...
         firstCycle, ...
         lastCycle);
   elseif (~isempty(firstCycle))
      fprintf('Shift (by %d) cycle numbers of Argos cycle files of float #%d from cycle #%d until the end\n', ...
         floatNum, ...
         offsetCycle, ...
         firstCycle);
   end
end

% check the input directory
if ~(exist(DIR_INPUT_ARGOS_FILES, 'dir') == 7)
   fprintf('ERROR: The Argos cycle files directory %s does not exist - exit\n', DIR_INPUT_ARGOS_FILES);
   return
end

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% find current float Argos Id
idF = find(listWmoNum == floatNum, 1);
if (isempty(idF))
   fprintf('ERROR: No information on float #%d - exit\n', floatNum);
   return
end
floatArgosId = str2num(listArgosId{idF});

% check the Argos files of the float
argosFileNames = [];
argosFileCycle = [];
allArgosFileCycle = [];
dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
for idFile = 1:length(argosFiles)

   argosFileName = argosFiles(idFile).name;

   [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');

   if (isempty(errmsg1) && (count1 == 9))
      cyNum =  val1(9);
      allArgosFileCycle = [allArgosFileCycle; cyNum];
      considerFile = 0;
      if (nargin == 3)
         if (cyNum >= firstCycle)
            considerFile = 1;
         end
      elseif (nargin == 4)
         if (cyNum >= firstCycle) && (cyNum <= lastCycle)
            considerFile = 1;
         end
      end

      if (considerFile == 1)
         argosFileNames{end+1} = argosFileName;
         argosFileCycle(end+1) = val1(9);
      end
   end
end

if (offsetCycle >= 0)
   [argosFileCycle, idSorted] = sort(argosFileCycle, 'descend');
else
   [argosFileCycle, idSorted] = sort(argosFileCycle, 'ascend');
end
argosFileNames = argosFileNames(idSorted);


if (isempty(argosFileNames))
   fprintf('No Argos cycle file to shift\n');
else
   % shifted cycle number should be >= 0
   if (~isempty(find(argosFileCycle + offsetCycle < 0, 1)))
      fprintf('WARNING: This shift will create Argos cycle file with negative cycle number - exit\n');
      return
   end
   
   % check that we can shift the cycles
   newCy = setdiff(argosFileCycle + offsetCycle, argosFileCycle);
   for idCy = 1:length(newCy)
      if (~isempty(find(allArgosFileCycle == newCy(idCy), 1)))
         fprintf('WARNING: An Argos cycle file already exists for cycle #%d - exit\n', newCy(idCy));
         return
      end
   end
   
   fprintf('%d Argos cycle file(s) to shift\n', length(argosFileNames));
   
   % create a common save directory
   saveDir = [dirFloat '/save/'];
   if ~(exist(saveDir, 'dir') == 7)
      fprintf('Creating directory %s\n', saveDir);
      mkdir(saveDir);
   end
   % create a specific save directory
   saveDirNow = [saveDir '/save_' datestr(now, 'yyyymmddTHHMMSS') '/'];
   if ~(exist(saveDirNow, 'dir') == 7)
      fprintf('Creating directory %s\n', saveDirNow);
      mkdir(saveDirNow);
   end

   nbFiles = length(argosFileNames);
   for idF = 1: nbFiles
      fprintf('File %2d/%2d: %s\n', idF, nbFiles, argosFileNames{idF});

      fileIn = [dirFloat '/' argosFileNames{idF}];
      fileOut = [saveDirNow '/' argosFileNames{idF}];
      fprintf('   saving file %s to directory %s\n', argosFileNames{idF}, saveDirNow);
      copy_file(fileIn, fileOut);

      [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');

      fileIn = [dirFloat '/' argosFileNames{idF}];
      newFileName = argosFileNames{idF};
      [val1, count1, errmsg1, nextindex1] = sscanf(newFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
      newFileName = sprintf('%06d_%04d-%02d-%02d-%02d-%02d-%02d_%d_%03d.txt', ...
         val1(1), val1(2), val1(3), val1(4), val1(5), val1(6), val1(7), val1(8), val1(9)+offsetCycle);
      fileOut = [dirFloat '/' newFileName];
      fprintf('   moving file %s to %s in directory %s\n', argosFileNames{idF}, newFileName, dirFloat);
      move_file(fileIn, fileOut);
   end
end

fprintf('done\n');

return
