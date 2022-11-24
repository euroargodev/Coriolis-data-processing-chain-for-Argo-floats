% ------------------------------------------------------------------------------
% Make a copy of the CTS5 files from DIR_INPUT_RSYNC_DATA to
% IRIDIUM_DATA_DIRECTORY.
%
% SYNTAX :
%   copy_cts5_files or copy_cts5_files(6900189, 7900118)
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
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function copy_cts5_files(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;
global g_decArgo_janFirst1950InMatlab;

% default values initialization
init_default_values;


% type of files to copy
fileTypeList = [ ...
   {'*_apmt*.ini'} ...
   {'*_payload*.xml'} ...
   {'_payload_*.txt'} ...
   {'*_autotest_*.txt'} ...
   {'*_technical*.txt'} ...
   {'*_default_*.txt'} ...
   {'*_sbe41*.hex'} ...
   {'*_payload*.bin'} ...
   {'*_system_*.hex'} ...
   {'*_metadata*.xml'} ... % CTS5-USEA
   {'*_do*.hex'} ... % CTS5-USEA
   {'*_eco*.hex'} ... % CTS5-USEA
   {'*_ocr*.hex'} ... % CTS5-USEA
   {'*_opus_blk*.hex'} ... % CTS5-USEA
   {'*_opus_lgt*.hex'} ... % CTS5-USEA
   {'*uvp6_blk*.hex'} ... % CTS5-USEA
   {'*_uvp6_lpm*.hex'} ... % CTS5-USEA
   {'*_crover*.hex'} ... % CTS5-USEA
   {'*_sbeph*.hex'} ... % CTS5-USEA
   {'*_suna*.hex'} ... % CTS5-USEA
   ];

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
[numWmoList, listDecId, loginNameList, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(numWmoList))
   return
end

% copy SBD files
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find the login name of the float
   [loginName] = find_login_name(floatNum, numWmoList, loginNameList);
   if (isempty(loginName))
      return
   end
   
   % create the output directory of this float
   floatOutputDirName = [outputDirName '/' loginName '_' floatNumStr];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   floatOutputDirName = [floatOutputDirName '/archive/'];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   updatedDirName = [floatOutputDirName '/updated_files/']; % to store old versions of files that have been updated in the rudics server
   if ~(exist(updatedDirName, 'dir') == 7)
      mkdir(updatedDirName);
   end
   unusedDirName = [floatOutputDirName '/unused_files/']; % to store files that shold not be used (they need to be deleted from the rudics server)
   if ~(exist(unusedDirName, 'dir') == 7)
      mkdir(unusedDirName);
   end
   
   fileNameList = [];
   for idType = 1:length(fileTypeList)
      files = dir([inputDirName '/' loginName '/' fileTypeList{idType}]);
      for idFile = 1:length(files)
         fileNameList{end+1} = files(idFile).name;
      end
   end
   fileNameList = unique(fileNameList);
   
   for idFile = 1:length(fileNameList)
      fileName = fileNameList{idFile};
      filePathName = [inputDirName '/' loginName '/' fileName];
      fileInfo = dir(filePathName);
      fileNameOut = [ ...
         fileName(1:end-4) '_' ...
         datestr(datenum(fileInfo.date, 'dd-mmmm-yyyy HH:MM:SS'), 'yyyymmddHHMMSS') ...
         fileName(end-3:end)];
      
      filePathNameOut = [floatOutputDirName '/' fileNameOut];
      if (exist(filePathNameOut, 'file') == 2)
         % file exists
         fprintf('%s => unchanged\n', fileNameOut);
      else
         fileExist = dir([floatOutputDirName '/' fileName(1:end-4) '_*' fileName(end-3:end)]);
         if (~isempty(fileExist))
            % update existing file
            move_file([floatOutputDirName '/' fileExist.name], updatedDirName);
            copy_file(filePathName, filePathNameOut);
            fprintf('%s => copy (update of %s)\n', fileNameOut,fileExist.name);
         else
            % copy new file
            copy_file(filePathName, filePathNameOut);
            fprintf('%s => copy\n', fileNameOut);
         end
      end
   end
   
   fprintf('\n');
   
   % clean files to be processed
   switch(floatNum)
      case 4901801
         % files 019b_* should not be kept
         delFile = dir([floatOutputDirName '/019b_*']);
         for idF = 1:length(delFile)
            move_file([floatOutputDirName '/' delFile(idF).name], unusedDirName);
            fprintf('MISC: %s - not used\n', delFile(idF).name);
         end
         
      case 4901802
         % file 013b_system_00007#01.hex is not the first part of
         % 013b_system_00007.hex => only 013b_system_00007#02.hex should be kept
         delFile = dir([floatOutputDirName '/013b_system_00007#01*.hex']);
         if (~isempty(delFile))
            move_file([floatOutputDirName '/' delFile.name], unusedDirName);
            fprintf('MISC: %s - not used\n', delFile.name);
         end
         % 013b_system_00007#02.hex should be renamed 013b_system_00007#02.hex
         movFile = dir([floatOutputDirName '/013b_system_00007#02*.hex']);
         move_file([floatOutputDirName '/' movFile.name], ...
            [floatOutputDirName '/' regexprep(movFile.name, '#02', '')]);
         
      case 4901805
         % files 012b_* should not be kept
         delFile = dir([floatOutputDirName '/012b_*']);
         for idF = 1:length(delFile)
            move_file([floatOutputDirName '/' delFile(idF).name], unusedDirName);
            fprintf('MISC: %s - not used\n', delFile(idF).name);
         end
         
      case 6902667
         % there are 2 deployments of the same float => use only files dated
         % after july 2016
         startDate = gregorian_2_julian_dec_argo('2016/07/01 00:00:00');
         files = dir(floatOutputDirName);
         for idF = 1:length(files)
            if (~files(idF).isdir)
               if (datenum(files(idF).date, 'dd-mmmm-yyyy HH:MM:SS')-g_decArgo_janFirst1950InMatlab < startDate)
                  move_file([floatOutputDirName '/' files(idF).name], unusedDirName);
                  fprintf('MISC: %s - not used\n', files(idF).name);
               end
            end
         end
         
      case 6902669
         % files 3a9b_* should not be kept
         delFile = dir([floatOutputDirName '/3a9b_*']);
         for idF = 1:length(delFile)
            move_file([floatOutputDirName '/' delFile(idF).name], unusedDirName);
            fprintf('MISC: %s - not used\n', delFile(idF).name);
         end
         
      case 6902829
         % file 3aa9_system_00116.hex should not be kept
         delFile = dir([floatOutputDirName '/3aa9_system_00116_*.hex']);
         if (~isempty(delFile))
            move_file([floatOutputDirName '/' delFile.name], unusedDirName);
            fprintf('MISC: %s - not used\n', delFile.name);
         end
         
      case 6902968
         % file 4279_047_00_payload.xml doesn't contain configuration at
         % launch for UVP sensor => we should use file _payload_190528_073923.xml
         inFile = dir([inputDirName '/' loginName '/_payload_190528_073923.xml']);
         outFile = [floatOutputDirName '/4279_047_00_payload.xml'];
         if (~isempty(inFile))
            copy_file([inputDirName '/' loginName '/' inFile.name], outFile);
            fprintf('MISC: %s replaced by %s\n', outFile, [inputDirName '/' loginName '/' inFile.name]);
         end
   end
end

return
