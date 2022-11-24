% ------------------------------------------------------------------------------
% Process APEX Argos data to create Argos cycle files to be used by the decoder.
% This tool applies the following tools to the input data:
% - STEP1: split_argos_cycles
% - STEP2: delete_double_argos_split
% - STEP3: create_argos_cycle_files
% - STEP4: co_cls_correct_argos_raw_file
% - STEP5: move_and_rename_apx_argos_files
% - STEP6 (FINAL): clean_ghost_in_apx_argos_cycle_files
%
% SYNTAX :
%   process_argos_data_apx
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/23/2016 - RNU - creation
% ------------------------------------------------------------------------------
function process_argos_data_apx(varargin)

% directory of input Argos files (all the files in only one directory)
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\DATA\ori\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_BIO\FINAL\IN\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\IN\';

% output directory (at the end of the process, it will contain one directory for
% each step of the process and a 'FINAL' directory for the final step)
DIR_OUTPUT = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\DATA\ori_out\';
DIR_OUTPUT = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_BIO\FINAL\OUT\';
DIR_OUTPUT = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\OUT\';

% directory to store the log files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_LIST_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatListFileName = configVal{1};

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

logFile = [DIR_LOG_FILE '/' 'process_argos_data_apx' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create output directory
if (exist(DIR_OUTPUT, 'dir') == 7)
   fprintf('INFO: Removing directory: %s\n', DIR_OUTPUT);
   rmdir(DIR_OUTPUT, 's');
end
mkdir(DIR_OUTPUT);
fprintf('INFO: Creating directory: %s\n', DIR_OUTPUT);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: split the data by satellite passes
fprintf('STEP 1: split the data by satellite passes\n');
dirOutStep1 = [DIR_OUTPUT '/STEP1/'];
[ok] = split_argos_cycles_bis(floatList, DIR_INPUT_ARGOS_FILES, dirOutStep1);
if (ok == 0)
   fprintf('ERROR: In step1 => exit\n');
   return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 2: delete identical satellite passes
fprintf('\nSTEP 2: delete identical satellite passes\n');
dirOutStep2 = [DIR_OUTPUT '/STEP2/'];
% duplicate the input directory in the output one
copy_file(dirOutStep1, dirOutStep2);
[ok] = delete_double_argos_split_bis(dirOutStep2);
if (ok == 0)
   fprintf('ERROR: In step2 => exit\n');
   return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 3: create cycle files
fprintf('\nSTEP 3: create cycle files\n');
dirOutStep3 = [DIR_OUTPUT '/STEP3/'];
[ok] = create_argos_cycle_files_bis(floatList, dirOutStep2, dirOutStep3);
if (ok == 0)
   fprintf('ERROR: In step3 => exit\n');
   return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 4: correct CLS headers (number of lines in the satellite pass)
fprintf('\nSTEP 4: correct CLS headers\n');
dirOutStep4 = [DIR_OUTPUT '/STEP4/'];
[ok] = co_cls_correct_argos_raw_file_bis(dirOutStep3, dirOutStep4);
if (ok == 0)
   fprintf('ERROR: In step4 => exit\n');
   return;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 5: identify cycle files
fprintf('\nSTEP 5: identify cycle files\n');
dirOutStep5 = [DIR_OUTPUT '/STEP5/'];
mkdir(dirOutStep5);
% create temporary directory
mkdir([dirOutStep5 '/IN/']);
% duplicate the input directory in the output one
copy_file(dirOutStep4, [dirOutStep5 '/IN/']);
[ok] = move_and_rename_apx_argos_files_bis(floatList, [dirOutStep5 '/IN/'], dirOutStep5);
if (ok == 0)
   fprintf('ERROR: In step5 => exit\n');
   return;
end
rmdir([dirOutStep5 '/IN/'], 's');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 6: delete ghost messages
fprintf('\nSTEP 6: delete ghost messages\n');
dirOutStep6 = [DIR_OUTPUT '/FINAL/'];
% mkdir(dirOutStep6);
% % duplicate the input directory in the output one
copy_file(dirOutStep5, dirOutStep6);
[ok] = clean_ghost_in_apx_argos_cycle_files_bis(floatList, dirOutStep6);
if (ok == 0)
   fprintf('ERROR: In step6 => exit\n');
   return;
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

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
function [o_ok] = split_argos_cycles_bis(varargin)

o_ok = 1;

if (nargin ~= 3)
   o_ok = 0;
   return;
end

% floats to process
floatList = varargin{1};

% input and output directories
DIR_INPUT_ARGOS_FILES = varargin{2};
DIR_OUTPUT_ARGOS_FILES = varargin{3};

% number of cyle files to process per run
NB_FILES_PER_RUN = 10000;

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

% create the output directory
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
end

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
      continue;
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

return;

% ------------------------------------------------------------------------------
% Find and delete identical split files (one file for each satellite pass)
% of a given directory.
%
% SYNTAX :
%   delete_double_argos_split
%
% INPUT PARAMETERS :
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
function [o_ok] = delete_double_argos_split_bis(varargin)

o_ok = 1;

if (nargin ~= 1)
   o_ok = 0;
   return;
end

% input and output directory
DIR_INPUT_OUTPUT_ARGOS_FILES = varargin{1};


% process the directories of the input directory
dirs = dir(DIR_INPUT_OUTPUT_ARGOS_FILES);
nbDirs = length(dirs);
for idDir = 1:nbDirs
   
   dirName = dirs(idDir).name;
   dirPathName = [DIR_INPUT_OUTPUT_ARGOS_FILES '/' dirName];
   
   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         
         fprintf('%03d/%03d Processing directory %s\n', idDir, nbDirs, dirName);
         
         % look for possible duplicated files
         fileList = [];
         files = dir(dirPathName);
         nbFiles = length(files);
         for idFile = 1:nbFiles
            
            fileName = files(idFile).name;
            if ~(strcmp(fileName, '.') || strcmp(fileName, '..'))
               fileList{end+1} = fileName(1:end-7);
            end
         end
         fileList = unique(fileList);
         
         % process possible duplicated files
         nbFiles = length(fileList);
         for idFile = 1:nbFiles
            stop = 0;
            while (~stop)
               if (length(dir([dirPathName '/' fileList{idFile} '*'])) > 1)
                  
                  dFiles = dir([dirPathName '/' fileList{idFile} '*']);
                  if (length(fileList{idFile}) == 7)
                     idDel = [];
                     nbDFiles = length(dFiles);
                     for id = 1:nbDFiles
                        if (~isempty(strfind(dFiles(id).name, '-')))
                           idDel = [idDel id];
                        end
                     end
                     dFiles(idDel) = [];
                  end
                  
                  deleted = 0;
                  nbDFiles = length(dFiles);
                  for id1 = 1:nbDFiles
                     for id2 = id1+1:nbDFiles
                        
                        % compare the 2 file contents
                        
                        fileName1 = [dirPathName '/' dFiles(id1).name];
                        fid1 = fopen(fileName1, 'r');
                        if (fid1 == -1)
                           fprintf('ERROR: Unable to open file: %s\n', fileName1);
                           return;
                        end
                        file1Contents = textscan(fid1, '%s');
                        fclose(fid1);
                        
                        fileName2 = [dirPathName '/' dFiles(id2).name];
                        fid2 = fopen(fileName2, 'r');
                        if (fid2 == -1)
                           fprintf('ERROR: Unable to open file: %s\n', fileName2);
                           return;
                        end
                        file2Contents = textscan(fid2, '%s');
                        fclose(fid2);
                        
                        compRes = 1;
                        file1Contents = file1Contents{:};
                        file2Contents = file2Contents{:};
                        for idL = 1:min([length(file1Contents) length(file2Contents)])
                           if ((length(file1Contents) >= idL) && (length(file2Contents) >= idL))
                              if (strcmp(file1Contents{idL}, file2Contents{idL}) == 0)
                                 compRes = 2;
                                 break;
                              end
                           elseif (length(file1Contents) >= idL)
                              compRes = 3;
                              break;
                           elseif (length(file2Contents) >= idL)
                              compRes = 4;
                              break;
                           end
                        end
                        
                        if (compRes == 1)
                           
                           % files are identical
                           fprintf('INFO: Files %s and %s are identical => %s deleted\n', dFiles(id1).name, dFiles(id2).name, dFiles(id2).name);
                           delete(fileName2);
                           deleted = 1;
                           break;
                        elseif (compRes == 3)
                           
                           % new file contents is included in base file
                           fprintf('INFO: File %s includes file %s contents => %s deleted\n', dFiles(id1).name, dFiles(id2).name, dFiles(id2).name);
                           delete(fileName2);
                           deleted = 1;
                           break;
                        elseif (compRes == 4)
                           
                           % base file contents is included in new file
                           fprintf('INFO: File %s includes file %s contents => %s deleted\n', dFiles(id2).name, dFiles(id1).name, dFiles(id1).name);
                           delete(fileName1);
                           deleted = 1;
                           break;
                        end
                     end
                     if (deleted == 1)
                        break;
                     end
                  end
                  
                  if (deleted == 0)
                     stop = 1;
                  end
               else
                  stop = 1;
               end
            end
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% For a given list of floats, process the associated Argos split files (one
% file for each satellite pass) by concatenating them so that each output file
% (called Argos cycle file) contains only one cycle transmitted data (the
% non-transmission periods are always less than a given threshold
% (i.e. g_decArgo_minNonTransDurForNewCycle)).
%
% SYNTAX :
%   create_argos_cycle_files or create_argos_cycle_files(6900189, 7900118)
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
function [o_ok] = create_argos_cycle_files_bis(varargin)

o_ok = 1;

if (nargin ~= 3)
   o_ok = 0;
   return;
end

% float to process
floatList = varargin{1};

% input and output directories
DIR_INPUT_ARGOS_FILES = varargin{2};
DIR_OUTPUT_ARGOS_FILES = varargin{3};

% default values
global g_decArgo_janFirst1950InMatlab;

% miscellaneous decoder configuration parameters
global g_decArgo_minNonTransDurForNewCycle;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% minimum duration of the non-transmission periods for a given file (in hour)
MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE = g_decArgo_minNonTransDurForNewCycle;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};

% create the output directories
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
end

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% create the list of Argos Ids (to manage reused Argos Ids)
nbFloats = length(floatList);
argosIdListAll = ones(length(floatList), 1)*-1;
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   
   % find current float Argos Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d\n', floatNum);
      fprintf('(nothing done)\n');
      continue;
   end
   floatArgosId = str2num(listArgosId{idF});
   argosIdListAll(idFloat) = floatArgosId;
end
argosIdListAll = sort(argosIdListAll);
argosIdList = unique(argosIdListAll);
argosIdOccList = ones(length(argosIdList), 1);
idM = find(diff(argosIdListAll) == 0);
for id = 1:length(idM)
   idOcc = length(find(argosIdListAll == argosIdListAll(idM(id))));
   idF = find(argosIdList == argosIdListAll(idM(id)));
   argosIdOccList(idF) = idOcc;
end

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
   
   % find the occurence of ArgosId for this float
   idFloatArgosIdOcc = find(argosIdList == floatArgosId);
   floatArgosIdOcc = argosIdOccList(idFloatArgosIdOcc);
   
   % directory of Argos files for this float
   dirInputFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   if (~isdir(dirInputFloat))
      fprintf('WARNING: No Argos data for float #%d\n', floatNum);
      continue;
   end
   
   % collect dates in the Argos files of the float
   argosFileNames = [];
   argosFileFirstMsgDate = [];
   argosFileLastMsgDate = [];
   floatArgosDate = [];
   argosFiles = dir([dirInputFloat '/' sprintf('*%d*', floatArgosId)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [dirInputFloat '/' argosFileName];
      
      [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d.txt');
      
      if ((isempty(errmsg1) && (count1 == 8)))
         
         [argosLocDate, argosDataDate] = ...
            read_argos_file_fmt1_rough(argosFilePathName, floatArgosId);
         argosDate = [argosLocDate; argosDataDate];
         
         if (~isempty(argosDate))
            argosFileNames{end+1} = argosFilePathName;
            argosFileFirstMsgDate(end+1) = min(argosDate);
            argosFileLastMsgDate(end+1) = max(argosDate);
            
            floatArgosDate = [floatArgosDate; argosDate];
         else
            fprintf('WARNING: Empty file (%s) => not considered\n', argosFileName);
         end
      else
         fprintf('WARNING: Not expected file name %s => not considered\n', argosFileName);
      end
   end
   
   % process the Argos files in chronological order
   if (~isempty(argosFileNames))
      
      % compute the first date of each split file
      floatArgosDate = sort(floatArgosDate);
      
      idCut = find(diff(floatArgosDate)*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE);
      dateCut = min(floatArgosDate);
      if (~isempty(idCut))
         dateCut = [dateCut; floatArgosDate(idCut+1)];
      end
      
      % create the output dircetory for this floats
      dirOutputFloat = [DIR_OUTPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
      if ~(exist(dirOutputFloat, 'dir') == 7)
         mkdir(dirOutputFloat);
      end
      
      % create the output file names
      fileNameList = [];
      for id = 1:length(dateCut)
         fileName = sprintf('%06d_%s_%d.txt', ...
            floatArgosId, ...
            datestr(dateCut(id)+g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
            floatNum);
         fileNameList{id} = [dirOutputFloat '/' fileName];
      end
      
      % chronologically sort the files
      [argosFileFirstMsgDate, idSort] = sort(argosFileFirstMsgDate);
      argosFileLastMsgDate = argosFileLastMsgDate(idSort);
      argosFileNames = argosFileNames(idSort);
      
      nbFiles = length(argosFileNames);
      for idFile = 1:nbFiles
         
         % open and process input file
         fIdIn = fopen(argosFileNames{idFile}, 'r');
         if (fIdIn == -1)
            fprintf('Error while opening file : %s\n', argosFileNames{idFile});
            return;
         end
         
         text = [];
         dateList = [];
         lineNum = 0;
         while (1)
            line = fgetl(fIdIn);
            lineNum = lineNum + 1;
            if (line == -1)
               if (~isempty(text))
                  if (~isempty(dateList))
                     minDate = min(dateList);
                     
                     % number of the file to store the data
                     idF = find(dateCut <= minDate);
                     if (~isempty(idF))
                        fileNum = idF(end);
                     else
                        fileNum = length(dateCut);
                     end
                     
                     % store the data in the output file
                     fIdOut = fopen(fileNameList{fileNum}, 'a');
                     if (fIdOut == -1)
                        fprintf('ERROR: Unable to open file: %s\n', fileNameList{fileNum});
                        return;
                     end
                     
                     for id = 1:length(text)
                        fprintf(fIdOut, '%s\n', text{id});
                     end
                     
                     fclose(fIdOut);
                     
                  else
                     fprintf('INFO: Argos data without dates => not considered\n');
                     for id = 1:length(text)
                        fprintf('%s\n', text{id});
                     end
                     fprintf('\n');
                  end
               end
               
               break;
            end
            
            % empty line
            if (strcmp(deblank(line), ''))
               continue;
            end
            
            % look for satellite pass header
            [val, count, errmsg, nextindex] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%d %f %f %f %d');
            if (isempty(errmsg) && (count >= 5) && (val(2) == floatArgosId))
               if (~isempty(text))
                  if (~isempty(dateList))
                     minDate = min(dateList);
                     
                     % number of the file to store the data
                     idF = find(dateCut <= minDate);
                     if (~isempty(idF))
                        fileNum = idF(end);
                     else
                        fileNum = length(dateCut);
                     end
                     
                     % store the data in the output file
                     fIdOut = fopen(fileNameList{fileNum}, 'a');
                     if (fIdOut == -1)
                        fprintf('ERROR: Unable to open file: %s\n', fileNameList{fileNum});
                        return;
                     end
                     
                     for id = 1:length(text)
                        fprintf(fIdOut, '%s\n', text{id});
                     end
                     
                     fclose(fIdOut);
                     
                  else
                     fprintf('INFO: Argos data without dates => not considered\n');
                     for id = 1:length(text)
                        fprintf('%s\n', text{id});
                     end
                     fprintf('\n');
                  end
                  
                  text = [];
                  dateList = [];
               end
               
               if (isempty(errmsg) && (count == 16))
                  date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                     val(7), val(8), val(9), val(10), val(11), val(12)));
                  dateList = [dateList; date];
               end
               
            else
               
               % look for message header
               [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %2c %2c %2c %2c');
               if (isempty(errmsg) && (count == 11))
                  
                  date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                     val(1), val(2), val(3), val(4), val(5), val(6)));
                  dateList = [dateList; date];
                  
               else
                  [val, count, errmsg, nextindex] = sscanf(line, '%d-%d-%d %d:%d:%f %d %8c %x %x %x');
                  if (isempty(errmsg) && (count == 11))
                     
                     date = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
                        val(1), val(2), val(3), val(4), val(5), val(6)));
                     dateList = [dateList; date];
                     
                  end
               end
            end
            
            text{end+1} = line;
         end
         
         fclose(fIdIn);
         
         %          % move the file to the done files directory
         %          if (floatArgosIdOcc == 1)
         %             move_file(argosFileNames{idFile}, DIR_DONE_ARGOS_FILES);
         %          end
      end
   else
      fprintf('INFO: No available Argos file for float #%d\n', ...
         floatNum);
   end
   
   argosIdOccList(idFloatArgosIdOcc) = argosIdOccList(idFloatArgosIdOcc) - 1;
end

return;

% ------------------------------------------------------------------------------
% Correction of the Argos HEX data.
% The correction only concerns the number of lines of the satellite pass.
%
% SYNTAX :
%   co_cls_correct_argos_raw_file
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/04/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = co_cls_correct_argos_raw_file_bis(varargin)

o_ok = 1;

if (nargin ~= 2)
   o_ok = 0;
   return;
end

% input directory(ies) to process
tabInputDirName = [];
tabInputDirName{end+1} = varargin{1};

% directory to store corrected files
corDirName = varargin{2};
if ~(exist(corDirName, 'dir') == 7)
   mkdir(corDirName);
end

% flag to process also sub-directories
SUB_DIR_FLAG = 1;


for idName = 1:length(tabInputDirName)
   
   % directory to process
   inputDirName = char(tabInputDirName{idName});
   
   fprintf('Processing directory : %s\n', inputDirName);
   
   if (SUB_DIR_FLAG == 0)
      co_cls_correct_argos_raw_file_one_dir(inputDirName, corDirName);
   else
      dirs = dir(inputDirName);
      nbDirs = length(dirs);
      for idDir = 1:nbDirs
         
         dirName = dirs(idDir).name;
         subDirPathName = [inputDirName '/' dirName '/'];
         
         if (isdir(subDirPathName))
            if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
               
               corSubDirName = [corDirName '/' dirName];
               if ~(exist(corSubDirName, 'dir') == 7)
                  mkdir(corSubDirName);
               end
               
               fprintf('Processing sub-directory : %s\n', dirName);
               
               co_cls_correct_argos_raw_file_one_dir(subDirPathName, corSubDirName);
            end
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Correction of the Argos HEX files of a given directory.
% The correction only concerns the number of lines of the satellite pass.
%
% SYNTAX :
%  co_cls_correct_argos_raw_file(a_inputDir, a_outputDir)
%
% INPUT PARAMETERS :
%   a_inputDir  : input directory of the files to correct
%   a_outputDir : output directory of the corrected files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/04/2014 - RNU - creation
% ------------------------------------------------------------------------------
function co_cls_correct_argos_raw_file_one_dir(a_inputDir, a_outputDir)

% processing of current directory contents
files = dir(a_inputDir);
nbFiles = length(files);
fprintf('Dir: %s (%d files)\n', a_inputDir, nbFiles);
for idFic = 1:nbFiles
   fileName = files(idFic).name;
   filePathName = [a_inputDir '/' fileName];
   
   if (exist(filePathName, 'file') == 2)
      
      % process the current file
      fIdIn = fopen(filePathName, 'r');
      if (fIdIn == -1)
         fprintf('Error while opening file : %s\n', filePathName);
         return;
      end
      
      % first step: looking for satellite pass header and storing the number of
      % lines of each satellite pass
      tabNbLinesToReadCor = [];
      tabNbLinesToReadOri = [];
      startLine = -1;
      lineNum = 0;
      while (1)
         line = fgetl(fIdIn);
         if (line == -1)
            if (startLine ~= -1)
               tabNbLinesToReadCor = [tabNbLinesToReadCor; lineNum-startLine+1];
            end
            break;
         end
         lineNum = lineNum + 1;
         
         % looking for satellite pass header
         [val1, count1, errmsg1, nextindex1] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%f %f %f %f %d');
         [val2, count2, errmsg2, nextindex2] = sscanf(line, '%d %d %d %d %c');
         [val3, count3, errmsg3, nextindex3] = sscanf(line, '%d %d %d %d %c %d-%d-%d %d:%d:%f %d %x %x %x %x');
         if ((isempty(errmsg1) && (count1 == 16)) || ...
               (isempty(errmsg2) && (count2 == 5) && (val2(2) > 99)) || ...
               (isempty(errmsg3) && (count3 == 16) && (isempty(find(val3(13:end) > 255, 1)))))
            
            if (startLine ~= -1)
               tabNbLinesToReadCor = [tabNbLinesToReadCor; lineNum-startLine];
            end
            startLine = lineNum;
            tabNbLinesToReadOri = [tabNbLinesToReadOri; val1(3)];
         end
      end
      
      fclose(fIdIn);
      
      % second step: writing of output file with the updated number of lines of
      % each satellite pass
      if (~isempty(tabNbLinesToReadCor))
         
         if (isempty(find((tabNbLinesToReadCor-tabNbLinesToReadOri) ~= 0, 1)))
            % no error dected => duplicate the file
            fileIn = filePathName;
            fileOut = [a_outputDir '/' fileName];
            copy_file(fileIn, fileOut);
         else
            % error(s) detected => correct the file
            
            % input file
            fIdIn = fopen(filePathName, 'r');
            if (fIdIn == -1)
               fprintf('Error while opening file : %s\n', filePathName);
               return;
            end
            
            % output file
            outputFileName = [a_outputDir '/' fileName];
            fIdOut = fopen(outputFileName, 'wt');
            if (fIdOut == -1)
               fprintf('Error while creating file : %s\n', outputFileName);
               return;
            end
            
            lineNum = 0;
            for id = 1:length(tabNbLinesToReadCor)
               started = 0;
               nbLinesToCopy = tabNbLinesToReadCor(id);
               while (nbLinesToCopy > 0)
                  line = fgetl(fIdIn);
                  if (line == -1)
                     break;
                  end
                  lineNum = lineNum + 1;
                  
                  if (started == 1)
                     nbLinesToCopy = nbLinesToCopy - 1;
                  end
                  
                  % looking for satellite pass header
                  [val1, count1, errmsg1, nextindex1] = sscanf(line, '%d %d %d %d %c %c %d-%d-%d %d:%d:%f %f %f %f %d');
                  [val2, count2, errmsg2, nextindex2] = sscanf(line, '%d %d %d %d %c');
                  [val3, count3, errmsg3, nextindex3] = sscanf(line, '%d %d %d %d %c %d-%d-%d %d:%d:%f %d %x %x %x %x');
                  if ((isempty(errmsg1) && (count1 == 16)) || ...
                        (isempty(errmsg2) && (count2 == 5) && (val2(2) > 99)) || ...
                        (isempty(errmsg3) && (count3 == 16) && (isempty(find(val3(13:end) > 255, 1)))))
                     
                     started = 1;
                     nbLinesToCopy = nbLinesToCopy - 1;
                     if (tabNbLinesToReadCor(id) > 1)
                        if (val1(3) ~= tabNbLinesToReadCor(id))
                           idBlank = strfind(line, ' ');
                           
                           idB1 = idBlank(1);
                           idB = idBlank(2);
                           pos = 3;
                           while ((idB == idB1+1) && (pos <= length(idBlank)))
                              idB = idBlank(pos);
                              pos = pos + 1;
                           end
                           idB2 = idB;
                           idB = idBlank(pos);
                           pos = pos + 1;
                           while ((idB == idB2+1) && (pos <= length(idBlank)))
                              idB = idBlank(pos);
                              pos = pos + 1;
                           end
                           idB3 = idB;
                           
                           line = [line(1:idB2) num2str(tabNbLinesToReadCor(id)) line(idB3:end)];
                           fprintf('File corrected %s: line %d (%d instead of %d)\n', ...
                              fileName, lineNum, tabNbLinesToReadCor(id), val1(3));
                        end
                     end
                  end
                  
                  if (tabNbLinesToReadCor(id) > 1)
                     fprintf(fIdOut, '%s\n', line);
                  end
               end
            end
            
            fclose(fIdOut);
            fclose(fIdIn);
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% For a given list of floats, process the associated Argos cycle files by:
%   1: renaming the files (according to float and cycle numbers)
%   2: moving the file to the apropriate directory.
%
% SYNTAX :
%   move_and_rename_apx_argos_files_bis or move_and_rename_apx_argos_files_bis(6900189, 7900118)
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
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = move_and_rename_apx_argos_files_bis(varargin)

o_ok = 1;

if (nargin ~= 3)
   o_ok = 0;
   return;
end

% float to process
floatList = varargin{1};

% input and output directories
DIR_INPUT_ARGOS_FILES = varargin{2};
DIR_OUTPUT_ARGOS_FILES = varargin{3};

% global input parameter information
global g_decArgo_processModeAll;
g_decArgo_processModeAll = 1;
global g_decArgo_processModeRedecode;
g_decArgo_processModeRedecode = 0;

% configuration values
global g_decArgo_dirInputHexArgosFileFormat1
g_decArgo_dirInputHexArgosFileFormat1 = DIR_OUTPUT_ARGOS_FILES;
global g_decArgo_hexArgosFileFormat;
g_decArgo_hexArgosFileFormat = 1;

% output CSV file Id
global g_decArgo_outputCsvFileId;
g_decArgo_outputCsvFileId = '';

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% mode processing flags
global g_decArgo_realtimeFlag;
g_decArgo_realtimeFlag = 0;
global g_decArgo_delayedModeFlag;
g_decArgo_delayedModeFlag = 0;

% current float WMO number
global g_decArgo_floatNum;

% global input parameter information
global g_decArgo_inputArgosFile;

global g_decArgo_dpfSplitDone;

% default values initialization
init_default_values;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';
configVar{end+1} = 'DIR_INPUT_JSON_FLOAT_META_DATA_FILE';

% get configuration parameters
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};
g_decArgo_dirInputJsonFloatMetaDataFile = configVal{2};

% create the output directories
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
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
   g_decArgo_floatNum = floatNum;
   g_decArgo_dpfSplitDone = 0;
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
   floatEndDate = listEndDate(idF);
   
   % select and sort the Argos files of the float
   argosFileNames = [];
   argosFileFirstMsgDate = [];
   dirInputFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   argosFiles = dir([dirInputFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [dirInputFloat '/' argosFileName];
      
      if (length(argosFileName) >= 27)
         
         [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName(1:27), '%d_%d-%d-%d-%d-%d-%d_');
         
         if (isempty(errmsg1) && (count1 == 7))
            
            if (floatEndDate ~= g_decArgo_dateDef)
               
               % check if the file should be considered
               fileDate = datenum(argosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
               if (fileDate > floatEndDate)
                  fprintf('INFO: Date of input file (%s) is after float end decoding date (%s) => file stored without cycle number (i.e. not decoded)\n', ...
                     julian_2_gregorian_dec_argo(fileDate), ...
                     julian_2_gregorian_dec_argo(floatEndDate));
                  g_decArgo_inputArgosFile = argosFilePathName;
                  move_argos_input_file(floatArgosId, fileDate, floatNum, [], 'UUU');
                  continue;
               end
            end
            
            argosFileNames{end+1} = argosFilePathName;
            argosFileFirstMsgDate(end+1) = datenum(argosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS') - ...
               g_decArgo_janFirst1950InMatlab;
            
         else
            fprintf('ERROR: Not expected file name: %s => file not considered\n', argosFileName);
         end
      else
         fprintf('ERROR: Not expected file name: %s => file not considered\n', argosFileName);
      end
   end
   
   % chronologically sort the files
   [argosFileFirstMsgDate, idSort] = sort(argosFileFirstMsgDate);
   argosFileNames = argosFileNames(idSort);
   
   % process the Argos files of the float
   move_and_rename_files(argosFileNames, floatNum, floatInformationFileName);
end

return;

% ------------------------------------------------------------------------------
% Process one Argos cycle file by:
%   1: renaming it (according to float and cycle numbers)
%   2: moving it to the apropriate directory.
%
% SYNTAX :
%  move_and_rename_file(a_argosFileName, a_floatNum, a_argosId, ...
%    a_floatInformationFileName)
%
% INPUT PARAMETERS :
%   a_argosFileName : Argos cycle file name
%   a_floatNum : float WMO number
%   a_floatInformationFileName : name of the float information file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_files(a_argosFileNames, a_floatNum, ...
   a_floatInformationFileName)

% global input parameter information
global g_decArgo_inputArgosFile;

% miscellaneous decoder configuration parameters
global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNumMsgForNotGhost;

global g_decArgo_dpfSplitDone;

% minimum number of float messages for not only ghosts in contents
NB_MSG_MIN = g_decArgo_minNumMsgForNotGhost;

% minimum duration (in hour) of a non-transmission period to create a new
% cycle
MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE = g_decArgo_minNonTransDurForNewCycle;


% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(a_floatInformationFileName);

idFloat = find(listWmoNum == a_floatNum);

frameLen = listFrameLen(idFloat);
floatDecId = listDecId(idFloat);
floatArgosId = str2double(listArgosId{idFloat});
floatLaunchDate = listLaunchDate(idFloat);
floatCycleTime = listCycleTime(idFloat);

% retrieve useful float meta-data
[launchDate, preludeDuration, profilePressure, cycleDuration, dpfFloatFlag] = ...
   get_apx_meta_data_for_cycle_number_determination(a_floatNum, floatLaunchDate, floatCycleTime, floatDecId);

% minimum duration of the first deep cycle for a DPF float (first transmission
% is expected to occur after an ascent/descent at profile pressure with an
% average speed of 10 cm/s)
dpfFirstDeepCycleDuration = (profilePressure*2/0.1)/3600;

% storage of already assigned cycles
tabCycleNumber = [];
tabFirstMsgDate = [];
tabLastMsgDate = [];

% first loop to decode cycle number from transmitted data
remainingArgosFileNames = [];
remainingFileCycleNumber = [];
nbFiles = length(a_argosFileNames);
for idFile = 1:nbFiles
   
   % process one Argos file
   argosFileName = a_argosFileNames{idFile};
   g_decArgo_inputArgosFile = argosFileName;
   
   % read Argos file
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataDate, argosDataData] = read_argos_file_fmt1({argosFileName}, floatArgosId, frameLen);
   firstArgosMsgDate = min(argosDataDate);
   lastArgosMsgDate = max(argosDataDate);
   
   % store file with only ghost messages without any cycle number
   if (isempty(argosDataDate))
      
      % search dates in the file without checking its consistency
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(argosFileName, floatArgosId);
      if (~isempty(argosDataDate))
         move_argos_input_file(floatArgosId, min(argosDataDate), a_floatNum, [], 'EEE');
      else
         move_argos_input_file(floatArgosId, min(argosLocDate), a_floatNum, [], 'EEE');
      end
      fprintf('INFO: File (%s) contains no Argos messages => file stored without cycle number (i.e. not decoded)\n', ...
         argosFileName);
      continue;
   elseif (length(unique(argosDataDate)) < NB_MSG_MIN)
      
      move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, [], 'GGG');
      fprintf('INFO: File (%s) contains only ghost messages => file stored without cycle number (i.e. not decoded)\n', ...
         argosFileName);
      continue;
   end
   
   % compute the cycle number
   
   if (isempty(launchDate))
      
      fprintf('ERROR: Unable to compute cycle number because of missing meta-data => file stored without cycle number (i.e. not decoded)\n');
      move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, [], 'MMM');
      continue;
   else
      if (lastArgosMsgDate <= launchDate)
         
         fprintf('INFO: Last date of input file (%s) is before float launch date (%s) => file stored without cycle number (i.e. not decoded)\n', ...
            julian_2_gregorian_dec_argo(lastArgosMsgDate), ...
            julian_2_gregorian_dec_argo(launchDate));
         move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, [], 'TTT');
         continue;
      else
         
         subFileNameList = {argosFileName};
         
         % check if the input file contains data of prelude phase and first deep
         % cycle (generally occurs for DPF floats)
         if (isempty(tabCycleNumber) && (g_decArgo_dpfSplitDone == 0))
            
            diffArgosDataDates = diff(argosDataDate)*24;
            if (max(diffArgosDataDates) > dpfFirstDeepCycleDuration/2)
               
               % a significant pause in data transmission is probably due to a
               % DPF float first deep cycle => the file should be split
               
               [subFileNameList] = split_argos_file(argosFileName, a_floatNum, floatArgosId);
               if (~isempty(subFileNameList))
                  
                  fprintf('INFO: Argos cycle file split (%.1f hours without transmission): %s\n', ...
                     max(diffArgosDataDates), argosFileName);
               else
                  fprintf('ERROR: Unable to split Argos cycle file: %s\n', ...
                     argosFileName);
                  continue;
               end
            end
         end
         g_decArgo_dpfSplitDone = 1;
         for idFile2 = 1:length(subFileNameList)
            
            argosFileName = subFileNameList{idFile2};
            g_decArgo_inputArgosFile = argosFileName;
            
            if (length(subFileNameList) == 2)
               % read Argos file
               [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
                  argosDataDate, argosDataData] = read_argos_file_fmt1({argosFileName}, floatArgosId, frameLen);
               firstArgosMsgDate = min(argosDataDate);
               lastArgosMsgDate = max(argosDataDate);
            end
            
            % decode the cycle number
            checkTestMsg = 0;
            if ((isempty(tabCycleNumber)) || ...
                  ((length(subFileNameList) == 2) && (idFile2 == 1)))
               checkTestMsg = 1;
            end
            
            [cycleNumber, cycleNumberCount] = decode_apex_cycle_number( ...
               argosFileName, floatDecId, floatArgosId, checkTestMsg);
            if (a_floatNum == 3901639)
               cycleNumber = -1;
               cycleNumberCount = -1;
            end
            if (cycleNumberCount > 1)
               
               % manage possible roll over of profile number counter
               if (~isempty(tabCycleNumber))
                  idPrevCycle = find(tabLastMsgDate < firstArgosMsgDate);
                  if (~isempty(idPrevCycle))
                     idPrevCycle = idPrevCycle(end);
                     while (cycleNumber < tabCycleNumber(idPrevCycle))
                        cycleNumber = cycleNumber + 256;
                     end
                  end
               end
               
               move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, cycleNumber);
               tabCycleNumber = [tabCycleNumber; cycleNumber];
               tabFirstMsgDate = [tabFirstMsgDate; firstArgosMsgDate];
               tabLastMsgDate = [tabLastMsgDate; lastArgosMsgDate];
            else
               remainingArgosFileNames{end+1} = argosFileName;
               remainingFileCycleNumber(end+1) = cycleNumber;
            end
         end
      end
   end
end

% second loop to estimate cycle number for remaining files
nbFiles = length(remainingArgosFileNames);
for idFile = 1:nbFiles
   
   % process one Argos file
   argosFileName = remainingArgosFileNames{idFile};
   g_decArgo_inputArgosFile = argosFileName;
   
   % read Argos file
   [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
      argosDataDate, argosDataData] = read_argos_file_fmt1({argosFileName}, floatArgosId, frameLen);
   firstArgosMsgDate = min(argosDataDate);
   lastArgosMsgDate = max(argosDataDate);
   
   cycleNumber = [];
   
   % try to use already computed cycles
   idPrevCycle = find(tabLastMsgDate < firstArgosMsgDate);
   if (~isempty(idPrevCycle))
      idPrevCycle = idPrevCycle(end);
      prevNum = tabCycleNumber(idPrevCycle);
   else
      idPrevCycle = [];
      prevNum = [];
   end
   idNextCycle = find(tabFirstMsgDate > lastArgosMsgDate);
   if (~isempty(idNextCycle))
      idNextCycle = idNextCycle(1);
      nextNum = tabCycleNumber(idNextCycle);
   else
      idNextCycle = [];
      nextNum = [];
   end
   
   if (~isempty(nextNum))
      if ((nextNum == 0) || (nextNum == 1))
         cycleNumber = 0;
      else
         if (lastArgosMsgDate < launchDate + preludeDuration/24 + cycleDuration/48)
            % it is a DPF cycle, cycle number should be #0 or #1
            if ((~isempty(prevNum) && (prevNum == 0)) || ...
                  (lastArgosMsgDate > dpfFirstDeepCycleDuration/24))
               cycleNumber = 1;
            else
               cycleNumber = 0;
            end
         else
            nbCycles = round((tabLastMsgDate(idNextCycle)-lastArgosMsgDate)*24/cycleDuration);
            if ((nbCycles == 0) && ...
                  ((tabLastMsgDate(idNextCycle)-lastArgosMsgDate)*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
               % we consider it is a new cycle if we have had a
               % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
               % transmission
               nbCycles = 1;
            end
            cycleNumber = nextNum - nbCycles;
         end
      end
   elseif (~isempty(prevNum))
      if (prevNum == 0)
         if (lastArgosMsgDate < launchDate + preludeDuration/24 + cycleDuration/48)
            % it is a DPF cycle, cycle number is #1
            cycleNumber = 1;
         else
            nbCycles = round((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24/cycleDuration);
            if ((nbCycles == 0) && ...
                  ((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
               % we consider it is a new cycle if we have had a
               % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
               % transmission
               nbCycles = 1;
            end
            cycleNumber = prevNum + nbCycles;
         end
      else
         nbCycles = round((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24/cycleDuration);
         if ((nbCycles == 0) && ...
               ((lastArgosMsgDate-tabLastMsgDate(idPrevCycle))*24 >= MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE))
            % we consider it is a new cycle if we have had a
            % MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE hours period without
            % transmission
            nbCycles = 1;
         end
         cycleNumber = prevNum + nbCycles;
      end
   end
   
   % use float meta-data
   if (isempty(cycleNumber))
      firstProfileEndDate = launchDate + preludeDuration/24 + dpfFirstDeepCycleDuration/24;
      if (firstArgosMsgDate < launchDate + preludeDuration/24)
         cycleNumber = 0;
      elseif (firstArgosMsgDate < firstProfileEndDate)
         if (abs(firstArgosMsgDate-(launchDate + preludeDuration/24)) < abs(firstArgosMsgDate-firstProfileEndDate))
            cycleNumber = 0;
         else
            cycleNumber = 1;
         end
      else
         cycleNumber = round((firstArgosMsgDate-firstProfileEndDate)*24/cycleDuration) + 1;
      end
   end
   
   if ((remainingFileCycleNumber(idFile) ~= -1) && ...
         (remainingFileCycleNumber(idFile) ~= cycleNumber))
      fprintf('WARNING: float #%d: computed cycle number (=%d) differs from decoded one (=%d) (but with a bad redundancy)\n', ...
         a_floatNum, cycleNumber, remainingFileCycleNumber(idFile));
   end
   
   move_argos_input_file(floatArgosId, firstArgosMsgDate, a_floatNum, cycleNumber);
   tabCycleNumber = [tabCycleNumber; cycleNumber];
   tabFirstMsgDate = [tabFirstMsgDate; firstArgosMsgDate];
   tabLastMsgDate = [tabLastMsgDate; lastArgosMsgDate];
   [tabCycleNumber, idSort] = sort(tabCycleNumber);
   tabFirstMsgDate = tabFirstMsgDate(idSort);
   tabLastMsgDate = tabLastMsgDate(idSort);
end

dpfFloat = 0;
cyDur1 = (diff(tabFirstMsgDate)*24)./diff(tabCycleNumber);
cyDur2 = (diff(tabLastMsgDate)*24)./diff(tabCycleNumber);

fprintf('\n')

if ((length(tabCycleNumber) > 1) && isempty(setdiff(tabCycleNumber(1:2), [0 1])))
   if (cyDur2(1) < mean(cyDur2)/2)
      dpfFloat = 1;
      if (dpfFloatFlag ~= 1)
         fprintf('WARNING: float #%d is a DPF float (DPF cycle duration : %.1f hours)\n', ...
            a_floatNum, cyDur2(1));
      else
         fprintf('INFO: float #%d is a DPF float (DPF cycle duration : %.1f hours)\n', ...
            a_floatNum, cyDur2(1));
      end
   end
end
fprintf('INFO: float #%d cycle duration : mean1 %.1f hours (stdev1 %.1f hours); mean2 %.1f hours (stdev2 %.1f hours)\n', ...
   a_floatNum, mean(cyDur1(1+dpfFloat:end)), std(cyDur1(1+dpfFloat:end)), ...
   mean(cyDur2(1+dpfFloat:end)), std(cyDur2(1+dpfFloat:end)));

fprintf('\n')

return;

% ------------------------------------------------------------------------------
% Detect ghost message at the end of the transmission and move it to a dedicated
% file.
%
% SYNTAX :
%   clean_ghost_in_apx_argos_cycle_files or clean_ghost_in_apx_argos_cycle_files(6900189, 7900118)
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
%   11/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = clean_ghost_in_apx_argos_cycle_files_bis(varargin)

o_ok = 1;

if (nargin ~= 2)
   o_ok = 0;
   return;
end

% float to process
floatList = varargin{1};

% directory of the argos files to check
DIR_INPUT_OUTPUT_ARGOS_FILES = varargin{2};

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% min non-trans duration (in hour) to use the ghost detection
MIN_NON_TRANS_DURATION_FOR_GHOST = 3;


% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDpfFlag, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   tabCycleNumber = [];
   tabLastMsgDate = [];
   tabFilename = [];
   
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
   floatDecId = listDecId(idF);
   if (ismember(floatDecId, [1021 1022]))
      fprintf('INFO: Clean ghost operation is not possible for decId #%d\n', floatDecId);
      continue;
   end
   floatArgosId = str2num(listArgosId{idF});
   floatCycleTime = double(listCycleTime(idF));
   floatDpfFlag = listDpfFlag(idF);
   if (~ismember(floatDpfFlag, [0 1]))
      fprintf('Float %d: inconsistent DPF float flag value (= %d)\n', ...
         floatNum, floatDpfFlag);
      floatDpfFlag = 1;
   end
   
   % select and sort the Argos files of the float
   dirFloat = [DIR_INPUT_OUTPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [dirFloat '/' argosFileName];
      
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(argosFilePathName, floatArgosId);
      argosDate = [argosLocDate; argosDataDate];
      argosDate = sort(argosDate);
      
      cycleNumber = [];
      [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
      if (isempty(errmsg1) && (count1 == 9) && (val1(8) == floatNum))
         cycleNumber = val1(9);
         if (cycleNumber > floatDpfFlag)
            tabCycleNumber = [tabCycleNumber; cycleNumber];
            tabLastMsgDate = [tabLastMsgDate; max(argosDataDate)];
            tabFilename{end+1} = argosFilePathName;
         end
      end
   end
   
   if (~isempty(tabCycleNumber))
      
      tabLastMsgDateBis = tabLastMsgDate-compute_duration(tabCycleNumber, tabCycleNumber(1), ones(max(tabCycleNumber)+1, 1)*floatCycleTime)';
      
      for idCy = 1:length(tabCycleNumber)
         
         tabLast = tabLastMsgDateBis;
         tabLast(idCy) = [];
         
         if ((tabLastMsgDateBis(idCy)-mean(tabLast))*24 > 0)
            fprintf('Cycle #%3d: LAST %s\n', ...
               tabCycleNumber(idCy), ...
               format_time_dec_argo((tabLastMsgDateBis(idCy)-mean(tabLast))*24));
         end
         
         if ((tabLastMsgDateBis(idCy)-mean(tabLast))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST)
            [argosLocDate, argosDataDate] = ...
               read_argos_file_fmt1_rough(tabFilename{idCy}, floatArgosId);
            argosDate = [argosLocDate; argosDataDate];
            argosDate = sort(argosDate);
            argosDate = argosDate-compute_duration(tabCycleNumber(idCy), tabCycleNumber(1), ones(max(tabCycleNumber)+1, 1)*floatCycleTime)';
            argosPathFileName = tabFilename{idCy};
            while (~isempty(argosDate) && ((argosDate(end)-mean(tabLast))*24 > MIN_NON_TRANS_DURATION_FOR_GHOST))
               
               % a ghost message is detected, move it to a dedicated file
               [subFileNameList] = split_argos_file_ghost(argosPathFileName, floatNum, floatArgosId);
               argosPathFileName = subFileNameList{1};
               
               argosDate(end) = [];
               fprintf('=> GHOST DETECTED: stored in %s\n', subFileNameList{2});
            end
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Compute durations between cycles.
%
% SYNTAX :
%  [o_duration] = compute_duration(a_tabEndCyNum, a_startCyNum, a_cycleTime)
%
% INPUT PARAMETERS :
%   a_tabEndCyNum : end cycle numbers
%   a_startCyNum  : start cycle number
%   a_cycleTime   : cycle durations
%
% OUTPUT PARAMETERS :
%   o_duration : durations between cycles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_duration] = compute_duration(a_tabEndCyNum, a_startCyNum, a_cycleTime)

% output parameters initialization
o_duration = [];

for id = 1:length(a_tabEndCyNum)
   % cycles to compute the duration
   cyNum = [a_startCyNum+1:a_tabEndCyNum(id)];
   if (~isempty(cyNum))
      o_duration(id) = sum(a_cycleTime(cyNum));
   else
      o_duration(id) = 0;
   end
end

o_duration = o_duration/24;

return;
