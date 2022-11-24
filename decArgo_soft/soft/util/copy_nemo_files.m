% ------------------------------------------------------------------------------
% Make a copy of the NEMO .profile files from DIR_INPUT_RSYNC_DATA to
% IRIDIUM_DATA_DIRECTORY.
%
% SYNTAX :
%   copy_nemo_files or copy_nemo_files(6900189, 7900118)
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
%   11/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function copy_nemo_files(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_RSYNC_DATA';
configVar{end+1} = 'IRIDIUM_DATA_DIRECTORY';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};
floatInformationFileName = configVal{2};
inputDirName = configVal{3};
outputDirName = configVal{4};

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

% read the list to associate a WMO number to a login name
[numWmo, listDecId, tabRudicsId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmo))
   return
end

% copy .profile files
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   % find the float rudicsId
   floatRudicsId = find_login_name(floatNum, numWmo, tabRudicsId);
   if (isempty(floatRudicsId))
      return
   end
   floatRudicsIdStr = sprintf('%04d', str2double(floatRudicsId));
   
   % create the output directory of this float
   floatOutputDirName = [outputDirName '/' floatRudicsIdStr '_' floatNumStr];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   floatOutputDirName = [floatOutputDirName '/archive/'];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   
   floatFiles = dir([inputDirName '/' floatRudicsIdStr '/' floatRudicsIdStr '*.profile']);
   for idFile = 1:length(floatFiles)
      floatFileName = floatFiles(idFile).name;
      floatFilePathName = [inputDirName '/' floatRudicsIdStr '/' floatFileName];
      
      floatFileNameOut = [floatFileName(1:4) '_' floatNumStr floatFileName(5:end)];
      floatFilePathNameOut = [floatOutputDirName '/' floatFileNameOut];
      if (exist(floatFilePathNameOut, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         floatFileOut = dir(floatFilePathNameOut);
         if (~strcmp(floatFiles(idFile).date, floatFileOut.date))
            copy_file(floatFilePathName, floatFilePathNameOut);
            fprintf('%s => copy\n', floatFileName);
         else
            fprintf('%s => unchanged\n', floatFileName);
         end
      else
         % copy the file if it doesn't exist
         copy_file(floatFilePathName, floatFilePathNameOut);
         fprintf('%s => copy\n', floatFileName);
      end
   end
end

return
