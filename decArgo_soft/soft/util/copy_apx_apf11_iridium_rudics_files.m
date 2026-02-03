% ------------------------------------------------------------------------------
% Make a copy of the Apex APF11 Iridium float files from DIR_INPUT_RSYNC_DATA to
% IRIDIUM_DATA_DIRECTORY.
%
% SYNTAX :
%   copy_apx_apf11_iridium_rudics_files or copy_apx_apf11_iridium_rudics_files(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/29/2018 - RNU - creation
% ------------------------------------------------------------------------------
function copy_apx_apf11_iridium_rudics_files(varargin)

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
[numWmo, listDecId, tabImei, listFrameLen, ...
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

   % find the float login_name
   [floatLoginName] = find_login_name(floatNum, numWmo, tabImei);
   if (isempty(floatLoginName))
      return
   end
   
   % create the output directory of this float
   floatOutputDirName = [outputDirName '/' floatLoginName '_' floatNumStr];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   floatOutputDirName = [floatOutputDirName '/archive/'];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   
   floatFiles = dir([inputDirName '/' floatLoginName '/' sprintf('%s*', floatLoginName)]);
   for idFile = 1:length(floatFiles)
      floatFileName = floatFiles(idFile).name;
      floatFilePathName = [inputDirName '/' floatLoginName '/' floatFileName];

      floatFileNameOut = floatFileName;

      % specific
      switch(floatNum)
         case 2903802
            idF1 = strfind(floatFileName, '.');
            cyNumPrev = str2double(floatFileName(idF1(1)+1:idF1(2)-1));
            fileDateStr = floatFileName(idF1(2)+1:idF1(3)-1);
            fileDateRef = datenum('20250706T230408', 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
            if (strcmp(fileDateStr, '20250618T025934') || strcmp(fileDateStr, '20250618T025936'))
               cyNum = 2;
            elseif (strcmp(fileDateStr, '20250618T042652'))
               cyNum = 3;
            elseif (strcmp(fileDateStr, '20250618T114032'))
               cyNum = 4;
            elseif (strcmp(fileDateStr, '20250618T125800') || strcmp(fileDateStr, '20250618T125802'))
               cyNum = 5;
            elseif (strcmp(fileDateStr, '20250618T181632') || strcmp(fileDateStr, '20250618T181634'))
               cyNum = 6;
            elseif (strcmp(fileDateStr, '20250618T193544'))
               cyNum = 7;
            elseif (strcmp(fileDateStr, '20250618T235006'))
               cyNum = 8;
            elseif (strcmp(fileDateStr, '20250619T005336') || strcmp(fileDateStr, '20250619T005338'))
               cyNum = 9;
            elseif (strcmp(fileDateStr, '20250622T201420'))
               cyNum = 10;
            elseif (strcmp(fileDateStr, '20250622T212400'))
               cyNum = 11;
            elseif (strcmp(fileDateStr, '20250706T230406') || strcmp(fileDateStr, '20250706T230408'))
               cyNum = 12;
            else
               fileDate = datenum(fileDateStr, 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
               if (fileDate > fileDateRef)
                  cyNum = cyNumPrev + 12;
               else
                  cyNum = cyNumPrev;
               end
            end

            floatFileNameOut(idF1(1)+1:idF1(2)-1) = sprintf('%03d', cyNum);
      end

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
