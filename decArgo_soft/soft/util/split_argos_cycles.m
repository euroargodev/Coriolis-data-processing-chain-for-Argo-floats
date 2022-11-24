% ------------------------------------------------------------------------------
% Split Argos cycle files (one file for each satellite pass).
%
% SYNTAX :
%   split_argos_cycles or split_argos_cycles(6900189, 7900118)
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
%   03/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function split_argos_cycles(varargin)

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_093008\in';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_093008\in_split';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\rerun\ori2';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\rerun\ori_split';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\IN\ori';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\IN\ori_split';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% number of cycle files to process per run
NB_FILES_PER_RUN = 10000;

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

% create the output directory
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

logFile = [DIR_LOG_FILE '/' 'split_argos_cycles' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% create the list of Argos Ids
nbFloats = length(floatList);
argosIdList = [];
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);

   % find current float Argos Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d\n', floatNum);
      fprintf('(nothing done)\n');
      continue
   end
   floatArgosId = str2num(listArgosId{idF});
   argosIdList = [argosIdList; floatArgosId];
end
argosIdList = unique(argosIdList);

% process the files of the input directory
files = dir(DIR_INPUT_ARGOS_FILES);
nbFilesTot = length(files);
stop = 0;
idFile = 1;
filePathNames = [];
nbFiles = 0;
while (~stop)

   fileName = files(idFile).name;
   filePathName = [DIR_INPUT_ARGOS_FILES '/' fileName];

   fprintf('%03d/%03d %s\n', idFile, nbFilesTot, fileName);

   if (exist(filePathName, 'file') == 2)

      filePathNames{end+1} = filePathName;
      nbFiles = nbFiles + 1;
      if (nbFiles == NB_FILES_PER_RUN)

         fprintf('\nProcessing one set of %d files\n', nbFiles);

         tic;
         tmpName = ['./tmp_' datestr(now, 'yyyymmddTHHMMSS') '.mat'];
         save(tmpName, 'filePathNames');
         %          split_argos_cycles_one_set( ...
         %             tmpName, ...
         %             DIR_OUTPUT_ARGOS_FILES);
         cmd = ['matlab -nodesktop -nosplash -r "split_argos_cycles_one_set(''' tmpName ''', ''' DIR_OUTPUT_ARGOS_FILES ''');exit"'];
         system(cmd);
         ellapsedTime = toc;
         delete(tmpName);
         fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

         clear filePathNames;
         filePathNames = [];
         nbFiles = 0;

      end

   end

   idFile = idFile + 1;
   if (idFile > nbFilesTot)
      if (nbFiles > 0)

         fprintf('\nProcessing one set of %d files\n', nbFiles);

         tic;
         tmpName = ['./tmp_' datestr(now, 'yyyymmddTHHMMSS') '.mat'];
         save(tmpName, 'filePathNames');
         %          split_argos_cycles_one_set( ...
         %             tmpName, ...
         %             DIR_OUTPUT_ARGOS_FILES);
         cmd = ['matlab -nodesktop -nosplash -r "split_argos_cycles_one_set(''' tmpName ''', ''' DIR_OUTPUT_ARGOS_FILES ''');exit"'];
         system(cmd);
         ellapsedTime = toc;
         delete(tmpName);
         fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

         clear filePathNames;
         filePathNames = [];
         nbFiles = 0;

      end

      stop = 1;
   end
end

fprintf('done\n');

diary off;

return
