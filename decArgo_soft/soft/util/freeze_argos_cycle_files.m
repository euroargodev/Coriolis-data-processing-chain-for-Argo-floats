% ------------------------------------------------------------------------------
% Freeze Argos cycle files so that they will not be decoded (to freeze an Argos
% cycle file, we set its cycle number to 'UUU').
%
% SYNTAX :
% freeze_argos_cycle_files(WMO, start_cycle, end_cycle) => freeze Argos cycle files of float #WMO from start_cycle to end_cycle
% or
% freeze_argos_cycle_files(WMO, start_cycle)            => freeze Argos cycle files of float #WMO from start_cycle to the last cycle
% or
% freeze_argos_cycle_files(WMO)                         => freeze all Argos cycle files of float #WMO
%
% INPUT PARAMETERS :
%   WMO         : WMO number of the float
%   start_cycle : first cycle to freeze
%   end_cycle   : last cycle to freeze
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
function freeze_argos_cycle_files(varargin)

% directory of the Argos cycle files
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\fichiers_cycle_CORRECT_final\';

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

if ((nargin == 0) || (nargin > 3))
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   freeze_argos_cycle_files(WMO, start_cycle, end_cycle) => freeze Argos cycle files of float #WMO from start_cycle to end_cycle or\n');
   fprintf('   freeze_argos_cycle_files(WMO, start_cycle)            => freeze Argos cycle files of float #WMO from start_cycle to the last cycle or\n');
   fprintf('   freeze_argos_cycle_files(WMO)                         => freeze all Argos cycle files of float #WMO\n');
   fprintf('aborted ...\n');
   return;
else
   firstCycle = [];
   lastCycle = [];

   floatNum = varargin{1};
   if (nargin > 1)
      firstCycle = varargin{2};
   end
   if (nargin > 2)
      lastCycle = varargin{3};
   end

   if (~isempty(lastCycle))
      if (firstCycle > lastCycle)
         fprintf('Start and end cycles should be consistently ordered!\n');
         fprintf('aborted ...\n');
         return;
      end
   end
   
   if (~isempty(lastCycle))
      fprintf('Freeze Argos cycle files of float #%d from cycle #%d to #%d\n', ...
         floatNum, ...
         firstCycle, ...
         lastCycle);
   elseif (~isempty(firstCycle))
      fprintf('Freeze Argos cycle files of float #%d from cycle #%d untill the end\n', ...
         floatNum, ...
         firstCycle);
   else
      fprintf('Freeze all Argos cycle files of float #%d\n', ...
         floatNum);
   end
end

% check the input directory
if ~(exist(DIR_INPUT_ARGOS_FILES, 'dir') == 7)
   fprintf('ERROR: The Argos cycle files directory %s does not exist => exit\n', DIR_INPUT_ARGOS_FILES);
   return;
end

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% find current float Argos Id
idF = find(listWmoNum == floatNum, 1);
if (isempty(idF))
   fprintf('ERROR: No information on float #%d => exit\n', floatNum);
   return;
end
floatArgosId = str2num(listArgosId{idF});

% check the Argos files of the float
argosFileNames = [];
argosFileCycle = [];
dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
for idFile = 1:length(argosFiles)

   argosFileName = argosFiles(idFile).name;

   [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');

   if (isempty(errmsg1) && (count1 == 9))
      cyNum =  val1(9);
      considerFile = 0;
      if (nargin == 1)
         considerFile = 1;
      elseif (nargin == 2)
         if (cyNum >= firstCycle)
            considerFile = 1;
         end
      elseif (nargin == 3)
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

if (isempty(argosFileNames))
   fprintf('No Argos cycle file to freeze\n');
else
   fprintf('%d Argos cycle file(s) to freeze\n', length(argosFileNames));
   
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

      fileIn = [dirFloat '/' argosFileNames{idF}];
      newFileName = argosFileNames{idF};
      [val1, count1, errmsg1, nextindex1] = sscanf(newFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
      newFileName = sprintf('%06d_%04d-%02d-%02d-%02d-%02d-%02d_%d_UUU.txt', ...
         val1(1), val1(2), val1(3), val1(4), val1(5), val1(6), val1(7), val1(8));
      fileOut = [dirFloat '/' newFileName];
      fprintf('   moving file %s to %s in directory %s\n', argosFileNames{idF}, newFileName, dirFloat);
      move_file(fileIn, fileOut);
   end
end

fprintf('done\n');

return;
