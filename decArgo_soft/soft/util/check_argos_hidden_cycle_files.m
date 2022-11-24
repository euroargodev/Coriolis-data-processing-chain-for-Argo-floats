% ------------------------------------------------------------------------------
% Look for 'hidden' Argos cycle files.
% A cycle file is hidden if the associated float is not in its name (replaced by
% 'WWW').
%
% SYNTAX :
%   check_argos_hidden_cycle_files or check_argos_hidden_cycle_files(6900189, 7900118)
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
%   12/04/2014 - RNU - creation
% ------------------------------------------------------------------------------
function check_argos_hidden_cycle_files(varargin)

% directory of the argos files to check
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS\cycle\';

% directory to store the log and CSV files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values
global g_decArgo_janFirst1950InMatlab;

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

logFile = [DIR_LOG_FILE '/' 'check_argos_hidden_cycle_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_FILE '/' 'check_argos_hidden_cycle_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['Hidden; Line; WMO; File name; File date'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbLine = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s ', idFloat, nbFloats, floatNumStr);
   
   % find current float Argos Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d\n', floatNum);
      fprintf('(nothing done)\n');
      continue
   end
   floatArgosId = str2num(listArgosId{idF});
   
   % look for 'WWW' in file names
   dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   hiddenFiles = [dir([dirFloat '/*WWW*']); dir([dirFloat '/*MMM*'])] ;
   if (isempty(hiddenFiles))
      fprintf('=> OK\n');
   else
      fprintf('=> KO : hidden files found !\n');
      
      % select and sort the Argos files of the float
      argosFiles = dir([dirFloat '/*.txt']);
      
      for idFile = 1:length(argosFiles)
         
         argosFileName = argosFiles(idFile).name;
         
         hidden = 0;
         if ~(isempty(strfind(argosFileName, 'WWW')) && isempty(strfind(argosFileName, 'MMM')))
            hidden = 1;
         end
         
         fprintf(fidOut, '%d; %d; %d; %s; %s\n', ...
            hidden, nbLine, floatNum, argosFileName, ...
            julian_2_gregorian_dec_argo(argosFiles(idFile).datenum-g_decArgo_janFirst1950InMatlab));
         
         nbLine = nbLine + 1;
      end
      
      fprintf(fidOut, '; %d\n', nbLine);
      nbLine = nbLine + 1;
      
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
