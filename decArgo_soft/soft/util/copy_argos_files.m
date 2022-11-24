% ------------------------------------------------------------------------------
% Make a copy of Argos files associated to a list of floats.
%
% SYNTAX :
%   copy_argos_files or copy_argos_files(6900189, 7900118)
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
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function copy_argos_files(varargin)

DIR_INPUT_ARGOS_FILES = 'E:\HDD\bascule_20140326\cycle_20140326\';
DIR_OUTPUT_ARGOS_FILES = 'E:\HDD\bascule_20140326\cycle_20140326_copy\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 

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

logFile = [DIR_LOG_FILE '/' 'copy_argos_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the output directory
if (exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   fprintf('The output directory %s already exist => exit\n', DIR_OUTPUT_ARGOS_FILES);
   return;
else
   mkdir(DIR_OUTPUT_ARGOS_FILES);
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
   
   % copy the Argos files of the float
   argosFiles = dir([DIR_INPUT_ARGOS_FILES '/' sprintf('*%d_*', floatArgosId)]);
   nbFiles = length(argosFiles);
   %    nbFiles = 5;
   for idFile = 1:nbFiles
      
      argosFileName = argosFiles(idFile).name;
      fprintf('File %03d/%03d: %s\n', idFile, nbFiles, argosFileName);
      inputFile = [DIR_INPUT_ARGOS_FILES '/' argosFileName];
      outputFile = [DIR_OUTPUT_ARGOS_FILES '/' argosFileName];
      if (copy_file(inputFile, outputFile) == 0)
         break;
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
