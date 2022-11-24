% ------------------------------------------------------------------------------
% Make a copy of the Apex Iridium Rudics or Navis files from
% DIR_INPUT_RSYNC_DATA to IRIDIUM_DATA_DIRECTORY (and set the created file names
% according to matlab decoder specifications).
%
% SYNTAX :
%   copy_apx_iridium_rudics_files_after_move_archive or copy_apx_iridium_rudics_files_after_move_archive(6900189, 7900118)
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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function copy_apx_iridium_rudics_files_after_move_archive(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;
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
% inputDirName = 'C:\Users\jprannou\_DATA\IN\APEX_IR\data_out_new\';
% inputDirName = 'C:\Users\jprannou\_DATA\IN\APEX_IR\data_out_20170904\';
outputDirName = configVal{4};
% outputDirName = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\apx_rudics_data\';
% outputDirName = 'C:\Users\jprannou\_DATA\IN\APEX_IR\apx_rudics_data_new\';

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
[floatWmoList, floatDecIdList, floatIdlist, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   floatLaunchDatelist, listLaunchLon, listLaunchLat, ...
   listRefDay, floatEndDateList, listDmFlag] = get_floats_info(floatInformationFileName);
if (isempty(floatWmoList))
   return
end

% rename and duplicate file (if needed)
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % find information on current float
   idF = find(floatWmoList == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d => (nothing done)\n', floatNum);
      continue
   end
   floatDecId = floatDecIdList(idF);
   floatId = str2num(floatIdlist{idF});
   floatLaunchDate = floatLaunchDatelist(idF);
   floatEndDate = floatEndDateList(idF);
   
   % create the output directory of this float
   floatOutputDirName = [outputDirName '/' sprintf('%04d', floatId) '_' num2str(floatNum) '/archive/'];
   if ~(exist(floatOutputDirName, 'dir') == 7)
      mkdir(floatOutputDirName);
   end
   
   % manage float files
   floatInputDirName = [inputDirName '/' sprintf('%04d', floatId)];
   fileNames = dir([floatInputDirName '/' sprintf('%04d', floatId) '*']);
   for idFile = 1:length(fileNames)
      inputFileName = fileNames(idFile).name;
      inputFilePathName = [floatInputDirName '/' inputFileName];
      
      [~, ~, extention] = fileparts(inputFilePathName);
      if (strcmp(extention, '.msg'))
         outputFileName = create_apx_rudics_msg_file_name(inputFilePathName, ...
            floatNum, floatId, floatDecId, floatLaunchDate, floatEndDate);
      elseif (strcmp(extention, '.log'))
         outputFileName = create_apx_rudics_log_file_name(inputFilePathName, ...
            floatNum, floatId, floatLaunchDate, floatEndDate);
      else
         fprintf('ERROR: Unknown file type (%s) => (nothing done)\n', inputFilePathName);
         continue
      end
      
      outputFilePathName = [floatOutputDirName '/' outputFileName];
      if (exist(outputFilePathName, 'file') == 2)
         % when the file already exists, check (with its date) if it needs to be
         % updated
         outputFile = dir(outputFilePathName);
         if (~strcmp(fileNames(idFile).date, outputFile.date))
            copy_file(inputFilePathName, outputFilePathName);
            fprintf('%s => copy\n', inputFileName);
         else
            fprintf('%s => unchanged\n', inputFileName);
         end
      else
         % the file doesn't exist
         copy = 1;
         [~, ~, extention] = fileparts(outputFilePathName);
         if (strcmp(extention, '.log'))
            if (strfind(outputFileName, ['_CCC_' floatNumStr '_CCC_']))
               files = dir(inputFilePathName);
               inputFileSize = files.bytes;
               idF = strfind(outputFileName, '_');
               files = dir([floatOutputDirName '/' outputFileName(1:idF(4)) '*.log']);
               for idFi = 1:length(files)
                  if (files(idFi).bytes == inputFileSize)
                     copy = 0;
                     break
                  end
               end
            end
         end
         
         % copy the file if it doesn't exist
         if (copy)
            copy_file(inputFilePathName, outputFilePathName);
            fprintf('%s => copy\n', inputFileName);
         else
            fprintf('%s => unchanged\n', inputFileName);
         end
      end
   end
   
   % set remaining unknown cycle numbers
   fileNames = dir([floatOutputDirName '/' sprintf('%04d', floatId) '*_CCC_' floatNumStr '_CCC*.log']);
   if (~isempty(fileNames))
      
      cyNumDate = [];
      fileNames = dir([floatOutputDirName '/' sprintf('%04d', floatId) '*' floatNumStr '*.log']);
      for idFile = 1:length(fileNames)
         fileName = fileNames(idFile).name;
         idF = strfind(fileName, '_');
         fileNameDateStr = fileName(idF(1)+1:idF(2)-1);
         fileNameDate = datenum(fileNameDateStr, 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
         cyNum = fileName(idF(4)+1:idF(5)-1);
         cyNumDate = [cyNumDate; {cyNum} {fileNameDate} {fileName}];
      end
      
      [~, idSort] = sort([cyNumDate{:, 2}]);
      cyNumDate = cyNumDate(idSort, :);
      idFileCy = find(~strcmp(cyNumDate(:, 1), 'CCC'));
      idFileNoCy = find(strcmp(cyNumDate(:, 1), 'CCC'));
      
      for idFile = 1:length(idFileNoCy)
         fileName = cyNumDate{idFileNoCy(idFile), 3};
         cyNumPrev = [];
         cyNumNext = [];
         idF1 = find(idFileCy < idFileNoCy(idFile));
         if (~isempty(idF1))
            idB = idFileCy(idF1(end));
            [cyNumPrev, status] = str2num(cyNumDate{idB, 1});
         end
         idF2 = find(idFileCy > idFileNoCy(idFile));
         if (~isempty(idF2))
            idA = idFileCy(idF2(1));
            [cyNumNext, status] = str2num(cyNumDate{idA, 1});
         end
         if (~isempty(cyNumPrev) && ~isempty(cyNumNext))
            if (cyNumPrev == cyNumNext-1)
               idF = strfind(fileName, '_');
               newFileName = [fileName(1:idF(4)) cyNumDate{idB, 1} fileName(idF(5):end)];
               if (~strcmp(newFileName, fileName))
                  move_file([floatOutputDirName '/' fileName], [floatOutputDirName '/' newFileName]);
               end
            else
               fprintf('WARNING: unable to determine cycle number for file: %s\n', fileName);
            end
         else
            % use deployment date
            filePathName = [floatOutputDirName '/' fileName];
            
            [error, events] = read_apx_ir_rudics_log_file(filePathName);
            if (error == 1)
               fprintf('ERROR: Error in file: %s => ignored\n', filePathName);
               continue
            end
            
            dates = [events.time];
            if (any(dates >= floatLaunchDate))
               cyNum = '000';
            else
               cyNum = 'TTT';
            end
            idF = strfind(fileName, '_');
            newFileName = [fileName(1:idF(4)) cyNum fileName(idF(5):end)];
            if (~strcmp(newFileName, fileName))
               move_file([floatOutputDirName '/' fileName], [floatOutputDirName '/' newFileName]);
            end
         end
      end
   end
   
   % be sure that there is only one msg file per cycle (except for cycle #0)
   cycleList = [];
   fileList = [];
   fileNames = dir([floatOutputDirName '/' sprintf('%04d', floatId) '*' floatNumStr '*.msg']);
   for idFile = 1:length(fileNames)
      fileName = fileNames(idFile).name;
      idF1 = strfind(fileName, floatNumStr);
      idF2 = strfind(fileName, '_');
      idF3 = find(idF2 > idF1);
      cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
      [cyNum, status] = str2num(cyNum);
      if (status)
         cycleList(end+1) = cyNum;
         fileList{end+1} = [floatOutputDirName '/' fileName];
      end
   end
   uCycleList = unique(cycleList);
   nbElts = hist(cycleList, uCycleList);
   anomalyCyList = uCycleList(find(nbElts > 1));
   if (~isempty(anomalyCyList))
      for cyNum = anomalyCyList
         if (cyNum == 0)
            continue
         end
         idFCy = find(cycleList == cyNum);
         fprintf('INFO: Float #%d Cycle #%d: %d msg files for this cycle\n', ...
            floatNum, cyNum, length(idFCy));
         fileSize = zeros(length(idFCy), 1);
         fileNames = [];
         for idF = 1:length(idFCy)
            filePathName = fileList{idFCy(idF)};
            file = dir(filePathName);
            [~, fileName, fileExt] = fileparts(filePathName);
            fprintf('\tFile #%d: %s (%d bytes)\n', ...
               idF, ...
               [fileName fileExt], ...
               file(1).bytes);
            fileSize(idF) = file(1).bytes;
            fileNames{end+1} = filePathName;
         end
         
         [~, idMax] = max(fileSize);
         fileNames(idMax) = [];
         
         % disable remaining files
         for idF = 1:length(fileNames)
            filePathName = fileNames{idF};
            [filePath, fileName, fileExt] = fileparts(filePathName);
            
            idF1 = strfind(fileName, floatNumStr);
            idF2 = strfind(fileName, '_');
            idF3 = find(idF2 > idF1);
            fileNameOut = [fileName(1:idF2(idF3(1))) 'UUU' fileName(idF2(idF3(2)):end)];
            
            move_file(filePathName, [filePath '/' fileNameOut fileExt]);
            fprintf('\t=> File %s moved to %s\n', ...
               [fileName fileExt], ...
               [fileNameOut fileExt]);
         end
      end
   end
   
   % be sure that there is no duplicates in log files (except for cycle #0)
   cycleList = [];
   fileList = [];
   fileNames = dir([floatOutputDirName '/' sprintf('%04d', floatId) '*' floatNumStr '*.log']);
   for idFile = 1:length(fileNames)
      fileName = fileNames(idFile).name;
      idF1 = strfind(fileName, floatNumStr);
      idF2 = strfind(fileName, '_');
      idF3 = find(idF2 > idF1);
      cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
      [cyNum, status] = str2num(cyNum);
      if (status)
         cycleList(end+1) = cyNum;
         fileList{end+1} = [floatOutputDirName '/' fileName];
      end
   end
   uCycleList = unique(cycleList);
   nbElts = hist(cycleList, uCycleList);
   anomalyCyList = uCycleList(find(nbElts > 1));
   if (~isempty(anomalyCyList))
      for cyNum = anomalyCyList
         if (cyNum == 0)
            continue
         end
         
         printLog = 0;
         log = [];
         
         idFCy = find(cycleList == cyNum);
         log{end+1} = sprintf('INFO: Float #%d Cycle #%d: %d log files for this cycle\n', ...
            floatNum, cyNum, length(idFCy));
         fileSize = zeros(length(idFCy), 1);
         filePathNames = [];
         fileNames = [];
         for idF = 1:length(idFCy)
            filePathName = fileList{idFCy(idF)};
            file = dir(filePathName);
            [~, fileName, fileExt] = fileparts(filePathName);
            log{end+1} = sprintf('\tFile #%d: %s (%d bytes)\n', ...
               idF, ...
               [fileName fileExt], ...
               file(1).bytes);
            fileSize(idF) = file(1).bytes;
            filePathNames{end+1} = filePathName;
            idF = strfind(fileName, '_');
            fileNames{end+1} = fileName(1:idF(5)-1);
         end
         
         [fileSize, idSort] = sort(fileSize, 'descend');
         filePathNames = filePathNames(idSort);
         fileNames = fileNames(idSort);
         
         stop = 0;
         idRef = 1;
         idNext = idRef + 1;
         while (~stop)
            if (length(fileNames) > idRef)
               if (length(fileNames) >= idNext)
                  if (strcmp(fileNames{idRef}, fileNames{idNext}))
                     
                     filePathName = filePathNames{idNext};
                     [filePath, fileName, fileExt] = fileparts(filePathName);
                     
                     idF1 = strfind(fileName, floatNumStr);
                     idF2 = strfind(fileName, '_');
                     idF3 = find(idF2 > idF1);
                     fileNameOut = [fileName(1:idF2(idF3(1))) 'UUU' fileName(idF2(idF3(2)):end)];
                     
                     move_file(filePathName, [filePath '/' fileNameOut fileExt]);
                     log{end+1} = sprintf('\t=> File %s moved to %s\n', ...
                        [fileName fileExt], ...
                        [fileNameOut fileExt]);
                     printLog = 1;

                     fileSize(idNext) = [];
                     filePathNames(idNext) = [];
                     fileNames(idNext) = [];
                  else
                     idNext = idNext + 1;
                  end
               else
                  idRef = idRef + 1;
                  idNext = idRef + 1;
               end
            else
               stop = 1;
            end
         end
         
         if (printLog)
            fprintf('%s', log{:});
         end
      end
   end
end

return
