% ------------------------------------------------------------------------------
% Make a copy of the Remocean SBD files from DIR_INPUT_RSYNC_DATA to
% IRIDIUM_DATA_DIRECTORY (first step to use the PROVOR decoder in DM on Remocean
% floats).
%
% SYNTAX :
%   copy_remocean_sbd_files or copy_remocean_sbd_files(6900189, 7900118)
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
%   01/27/2013 - RNU - creation
% ------------------------------------------------------------------------------
function copy_remocean_sbd_files(varargin)

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
[numWmo, listDecId, loginName, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmo))
   return
end

% copy SBD files
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find the login name of the float
   [logName] = find_login_name(floatNum, numWmo, loginName);
   if (isempty(logName))
      return
   end
   
   % find the decoder ID of the float
   idF = find(floatNum == numWmo);
   if (isempty(idF))
      fprintf('No decoder Id for float : %d\n', floatNum);
      return
   end
   floatDecId = listDecId(idF);
   
   % create the output directory of this float
   floatOutputDirName = [outputDirName '/' logName '_' floatNumStr];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   floatOutputDirName = [floatOutputDirName '/archive/'];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   
   unusedDirName = [floatOutputDirName '/unused_files/']; % to store files that shold not be used (they need to be deleted from the rudics server)
   if ~(exist(unusedDirName, 'dir') == 7)
      mkdir(unusedDirName);
   end

   sbdFile = [dir([inputDirName '/' logName '/' sprintf('*_%s_*.b64', logName)]); ...
      dir([inputDirName '/' logName '/' sprintf('*_%s_*.bin', logName)])];

   for idFile = 1:length(sbdFile)
      %    for idFile = 1:min(100,length(sbdFile))
      sbdFileName = sbdFile(idFile).name;
      sbdFilePathName = [inputDirName '/' logName '/' sbdFileName];
      
      sbdFilePathNameOut = [floatOutputDirName '/' sbdFileName];
      if (exist(sbdFilePathNameOut, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         sbdFileOut = dir(sbdFilePathNameOut);
         if (~strcmp(sbdFile(idFile).date, sbdFileOut.date))
            copy_file(sbdFilePathName, sbdFilePathNameOut);
            fprintf('%s => copy\n', sbdFileName);
         else
            fprintf('%s => unchanged\n', sbdFileName);
         end
      else
         % copy the file if it doesn't exist
         copy_file(sbdFilePathName, sbdFilePathNameOut);
         fprintf('%s => copy\n', sbdFileName);
      end
   end

   % specific
   switch(floatNum)
      case 6902902
         % files transmitted in 2023 should be ignored (bad cycle number and
         % dates due to emergency ascent)
         delFile = dir([floatOutputDirName '/230113_*.b64']);
         for idF = 1:length(delFile)
            move_file([floatOutputDirName '/' delFile(idF).name], unusedDirName);
            fprintf('MISC: %s - not used\n', delFile(idF).name);
         end
   end

end

return
