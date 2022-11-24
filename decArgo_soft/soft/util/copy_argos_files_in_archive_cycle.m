% ------------------------------------------------------------------------------
% Copy Argos cycle files associated to a list of floats from the archive cycle
% directory to a given directory (all the files in only one directory).
%
% SYNTAX :
%   copy_argos_files_in_archive_cycle or copy_argos_files_in_archive_cycle(6900189, 7900118)
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
%   05/28/2015 - RNU - creation
% ------------------------------------------------------------------------------
function copy_argos_files_in_archive_cycle(varargin)

% archive cycle directory
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\archive_cycle_co_20150409\';

% directory to store archive cycle files
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\OUT\test\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\'; 

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


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

logFile = [DIR_LOG_FILE '/' 'copy_argos_files_in_archive_cycle' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the output directory
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
   fprintf('INFO: Creating directory: %s\n', DIR_OUTPUT_ARGOS_FILES);
end

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
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
   
   % select the directories associated with the current float (only one expected
   % in archive/cycle)
   argosDirs = dir([DIR_INPUT_ARGOS_FILES '/' sprintf('*%d*', floatArgosId)]);
   nbDirs = length(argosDirs);
   for idDir = 1:nbDirs
      
      argosDirName = argosDirs(idDir).name;
      argosDirPathName = [DIR_INPUT_ARGOS_FILES '/' argosDirName];
      
      % copy the files (*.txt) of the current directory
      argosFiles = dir([argosDirPathName '/*.txt']);
      nbFiles = length(argosFiles);
      for idF = 1:nbFiles
      
         argosFileName = argosFiles(idF).name;
         inputFilePathName = [argosDirPathName '/' argosFileName];
         outputFilePathName = [DIR_OUTPUT_ARGOS_FILES '/' argosFileName];
         
         % manage file duplicates in different directories
         if (exist(outputFilePathName, 'file') == 2)
            cpt = 1;
            while (exist(outputFilePathName, 'file') == 2)
               newFileName = [argosFileName(1:end-4) sprintf('_%05d', cpt) '.txt'];
               outputFilePathName = [DIR_OUTPUT_ARGOS_FILES '/' newFileName];
               cpt = cpt + 1;
            end
            fprintf('WARNING: File: %s is renamed %s in output directory\n', ...
               argosFileName, newFileName);
         end
         
         copy_file(inputFilePathName, outputFilePathName);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
