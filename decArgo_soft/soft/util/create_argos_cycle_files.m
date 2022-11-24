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
function create_argos_cycle_files(varargin)

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_062608\ori_split\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_062608\ori_split_cycle\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061609\in_split\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061609\in_split_cycle\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_021009\in_split\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_021009\in_split_cycle\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\in_split\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\in_split_cycle\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\118188\in_split\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\split_apex_061810\118188\in_split_cycle\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\historical_processing\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\historical_processing_cycle\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\rerun\ori_split\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\rerun\ori_split_cycle\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARN\ori_split_cycle\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default values
global g_decArgo_janFirst1950InMatlab;

% miscellaneous decoder configuration parameters
global g_decArgo_minNonTransDurForNewCycle;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% minimum duration of the non-transmission periods for a given file (in hour)
MIN_NON_TRANS_DURATION_FOR_NEW_CYCLE = g_decArgo_minNonTransDurForNewCycle;


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

% create the output directories
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
end

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

logFile = [DIR_LOG_FILE '/' 'create_argos_cycle_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

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

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
