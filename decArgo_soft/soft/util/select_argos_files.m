% ------------------------------------------------------------------------------
% Select (move to a sub-directory called 'select') Argos files associated to a
% list of floats.
%
% SYNTAX :
%   select_argos_files or select_argos_files(6900189, 7900118)
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
function select_argos_files(varargin)

DIR_INPUT_ARGOS_FILES = 'H:\HDD\_bascule_20140326\_merge_final\cycle_message_misc_split_raw_sans_doubles_zip';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\fichiers_cycle_CORRECT_final';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\archive_cycle_all_20160823\cycle';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\collecte_20161002\cycle';


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

logFile = [DIR_LOG_FILE '/' 'select_argos_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the output directory
selectDirName = [DIR_INPUT_ARGOS_FILES '/select/'];
if (exist(selectDirName, 'dir') == 7)
   fprintf('The ''select'' directory (%s) already exist => exit\n', selectDirName);
   return
else
   mkdir(selectDirName);
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
      continue
   end
   floatArgosId = str2num(listArgosId{idF});
   
   % select the Argos files or directories associated with the floats
   argosFilesOrDirs = dir([DIR_INPUT_ARGOS_FILES '/' sprintf('*%d*', floatArgosId)]);
   nbElts = length(argosFilesOrDirs);
   for idElt = 1:nbElts
      
      argosFileOrDirName = argosFilesOrDirs(idElt).name;
      inputFile = [DIR_INPUT_ARGOS_FILES '/' argosFileOrDirName];
      outputFile = [selectDirName '/' argosFileOrDirName];
      move_file(inputFile, outputFile);

   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
