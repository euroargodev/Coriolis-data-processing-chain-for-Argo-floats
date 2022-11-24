% ------------------------------------------------------------------------------
% Set cycle number of and Argos cycle file.
%
% SYNTAX :
% set_cycle_number_of_argos_cycle_file(WMO, file_date, cycle_number) => set cycle cycle number of Argos cycle file (dated file_date) to cycle_number
% where file_date is provided as a string present in the Argos cycle file name (format: 'yyyy-mm-dd-HH-MM-SS')
%
% INPUT PARAMETERS :
%   WMO          : WMO number of the float
%   file_date    : date of the concerned Argos cycle file (format:
%                  'yyyy-mm-dd-HH-MM-SS')
%   cycle_number : cycle number to assign to the concerned Argos cycle file
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
function set_cycle_number_of_argos_cycle_file(varargin)

% directory of the Argos cycle files
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\fichiers_cycle_apex_233_floats_bascule_20160217\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\OUT\FINAL\';

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

if (nargin ~= 3)
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   set_cycle_number_of_argos_cycle_file(WMO, file_date, cycle_number) => set cycle cycle number of Argos cycle file (dated file_date) to cycle_number\n');
   fprintf('where file_date is provided as a string present in the Argos cycle file name (format: ''yyyy-mm-dd-HH-MM-SS''\n');
   fprintf('aborted ...\n');
   return
else

   floatNum = varargin{1};
   file_date = datenum(varargin{2}, 'yyyy-mm-dd-HH-MM-SS');
   cycleNumber = varargin{3};

   fprintf('Set cycle number to #%d for Argos cycle file dated %s of float #%d\n', ...
      cycleNumber, ...
      datestr(file_date, 'yyyy-mm-dd-HH-MM-SS'), ...
      floatNum);
end

% check the input directory
if ~(exist(DIR_INPUT_ARGOS_FILES, 'dir') == 7)
   fprintf('ERROR: The Argos cycle files directory %s does not exist => exit\n', DIR_INPUT_ARGOS_FILES);
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
   fprintf('ERROR: No information on float #%d => exit\n', floatNum);
   return
end
floatArgosId = str2num(listArgosId{idF});

% check the Argos files of the float
tabCycleNum = [];
argosFileNameFound = [];
expectedPattern = sprintf('%06d_%s_%d_', ...
   floatArgosId, ...
   datestr(file_date, 'yyyy-mm-dd-HH-MM-SS'), ...
   floatNum);
dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
for idFile = 1:length(argosFiles)

   argosFileName = argosFiles(idFile).name;

   if (~isempty(strfind(argosFileName, expectedPattern)))
      if (isempty(argosFileNameFound))
         argosFileNameFound = argosFileName;
      else
         fprintf('ERROR: More than one Argos cycle file are dated %s => exit\n', ...
            datestr(file_date, 'yyyy-mm-dd-HH-MM-SS'));
         return
      end
   end
   
   [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');

   if (isempty(errmsg1) && (count1 == 9))
      tabCycleNum = [tabCycleNum; val1(9)];
   end

end

if (isempty(argosFileNameFound))
   fprintf('ERROR: File not found, check that provided date is part of the Argos cycle file name => exit\n');
   return
end

if (~isempty(find(tabCycleNum == cycleNumber, 1)))
   fprintf('ERROR: An Argos cycle file already has cycle number #%d => exit\n', ...
      cycleNumber);
   return
end

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

fileIn = [dirFloat '/' argosFileNameFound];
fileOut = [saveDirNow '/' argosFileNameFound];
fprintf('   saving file %s to directory %s\n', argosFileNameFound, saveDirNow);
copy_file(fileIn, fileOut);

newFileName = [expectedPattern sprintf('%03d.txt', cycleNumber)];
if (strcmp(argosFileNameFound, newFileName) == 0)
   fileIn = [dirFloat '/' argosFileNameFound];
   fileOut = [dirFloat '/' newFileName];
   fprintf('   moving file %s to %s in directory %s\n', argosFileNameFound, newFileName, saveDirNow);
   move_file(fileIn, fileOut);
end

fprintf('done\n');

return
