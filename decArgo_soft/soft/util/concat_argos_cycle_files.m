% ------------------------------------------------------------------------------
% Concat Argos cycle file contents.
%
% SYNTAX :
% concat_argos_cycle_files(WMO, start_date, end_date) => concat Argos cycle files of float #WMO from start_date to end_date
% or
% concat_argos_cycle_files(WMO, start_date)           => concat Argos cycle files of float #WMO from start_date to the last one
% or
% concat_argos_cycle_files(WMO)                       => concat all Argos cycle files of float #WMO
% where start_date and end_date are provided as strings present in the Argos cycle file names (format: 'yyyy-mm-dd-HH-MM-SS')
%
% INPUT PARAMETERS :
%   WMO        : WMO number of the float
%   start_date : date of the first concerned Argos cycle file (format:
%                'yyyy-mm-dd-HH-MM-SS')
%   end_date   : date of the last concerned Argos cycle file (format:
%                'yyyy-mm-dd-HH-MM-SS')
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
function concat_argos_cycle_files(varargin)

% directory of the Argos cycle files
DIR_INPUT_ARGOS_FILES = 'E:\HDD\archive_cycle_co_20141201\';


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

if ((nargin == 0) || (nargin > 4))
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   concat_argos_cycle_files(WMO, start_date, end_date) => concat Argos cycle files of float #WMO from start_date to end_date or\n');
   fprintf('   concat_argos_cycle_files(WMO, start_date)           => concat Argos cycle files of float #WMO from start_date to the last one or\n');
   fprintf('   concat_argos_cycle_files(WMO)                       => concat all Argos cycle files of float #WMO\n');
   fprintf('where start_date and end_date are provided as strings present in the Argos cycle file names (format: ''yyyy-mm-dd-HH-MM-SS'')\n');
   fprintf('aborted ...\n');
   return
else
   firstDate = [];
   lastDate = [];
   
   floatNum = varargin{1};
   if (nargin > 1)
      firstDate = datenum(varargin{2}, 'yyyy-mm-dd-HH-MM-SS');
   end
   if (nargin > 2)
      lastDate = datenum(varargin{3}, 'yyyy-mm-dd-HH-MM-SS');
   end

   if (~isempty(lastDate))
      if (firstDate > lastDate)
         fprintf('Start and end dates should be chronolocally sorted!\n');
         fprintf('aborted ...\n');
         return
      end
   end
   
   if (~isempty(lastDate))
      fprintf('Concat Argos cycle files of float #%d from %s to %s\n', ...
         floatNum, ...
         datestr(firstDate, 'yyyy/mm/dd HH:MM:SS'), ...
         datestr(lastDate, 'yyyy/mm/dd HH:MM:SS'));
   elseif (~isempty(firstDate))
      fprintf('Concat Argos cycle files of float #%d from %s untill the end\n', ...
         floatNum, ...
         datestr(firstDate, 'yyyy/mm/dd HH:MM:SS'));
   else
      fprintf('Concat all Argos cycle files of float #%d\n', ...
         floatNum);
   end
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
fileFound = 0;
argosFileNames = [];
argosFileFirstMsgDate = [];
dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
for idFile = 1:length(argosFiles)

   argosFileName = argosFiles(idFile).name;

   [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
   [val2, count2, errmsg2, nextindex2] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_EEE.txt');
   [val3, count3, errmsg3, nextindex3] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_WWW.txt');
   [val4, count4, errmsg4, nextindex4] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_MMM.txt');
   [val5, count5, errmsg5, nextindex5] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_TTT.txt');
   [val6, count6, errmsg6, nextindex6] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_GGG.txt');
   [val7, count7, errmsg7, nextindex7] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_UUU.txt');

   if (isempty(errmsg1) && (count1 == 9) || ...
         (isempty(errmsg2) && (count2 == 8)) || ...
         (isempty(errmsg3) && (count3 == 8)) || ...
         (isempty(errmsg4) && (count4 == 8)) || ...
         (isempty(errmsg5) && (count5 == 8)) || ...
         (isempty(errmsg6) && (count6 == 8)) || ...
         (isempty(errmsg7) && (count7 == 8)))

      argosFileNames{end+1} = argosFileName;
      argosFileFirstMsgDate(end+1) = datenum(argosFileName(8:26), 'yyyy-mm-dd-HH-MM-SS');
      
      if (nargin == 2)
         if (strcmp(argosFileName(8:26), varargin{2}) == 1)
            fileFound = 1;
         end
      elseif (nargin == 3)
         if (strcmp(argosFileName(8:26), varargin{2}) == 1)
            fileFound = fileFound + 1;
         end
         if (strcmp(argosFileName(8:26), varargin{3}) == 1)
            fileFound = fileFound + 1;
         end
      end
   else
      fprintf('ERROR: Not expected file name: %s => file not considered\n', argosFileName);
   end
end

if ~((nargin == 1) || ...
   ((nargin == 2) && (fileFound == 1)) || ...
      ((nargin == 3) && (fileFound == 2)))
   fprintf('ERROR: Check that provided date(s) is(are) part of the Argos cycle file name => exit\n');
   return
end

% chronologically sort the files
[argosFileFirstMsgDate, idSort] = sort(argosFileFirstMsgDate);
argosFileNames = argosFileNames(idSort);

idFile = [];
if (nargin == 3)
   idFile = find((argosFileFirstMsgDate >= firstDate) & ...
      (argosFileFirstMsgDate <= lastDate));
elseif (nargin == 2)
   idFile = find(argosFileFirstMsgDate >= firstDate);
else
   idFile = 1:length(argosFileFirstMsgDate);
end

if (isempty(idFile))
   fprintf('No Argos cycle file to concat\n');
else
   fprintf('%d Argos cycle file(s) to concat\n', length(idFile));
   
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

   nbFiles = length(idFile);
   concatFileName = sprintf('%06d_%s_%d_UUU.txt', ...
      floatArgosId, ...
      datestr(min(argosFileFirstMsgDate(idFile)), 'yyyy-mm-dd-HH-MM-SS'), ...
      floatNum);
   for idF = 1: nbFiles
      fprintf('File %2d/%2d: %s\n', idF, nbFiles, argosFileNames{idFile(idF)});

      if (idF == 1)
         fileIn = [dirFloat '/' argosFileNames{idFile(idF)}];
         fileOut = [saveDirNow '/' argosFileNames{idFile(idF)}];
         fprintf('   saving file %s to directory %s\n', argosFileNames{idFile(idF)}, saveDirNow);
         copy_file(fileIn, fileOut);

         if (strcmp(argosFileNames{idFile(idF)}, concatFileName) == 0)
            fileIn = [dirFloat '/' argosFileNames{idFile(idF)}];
            fileOut = [dirFloat '/' concatFileName];
            fprintf('   moving file %s to %s in directory %s\n', argosFileNames{idFile(idF)}, concatFileName, saveDirNow);
            move_file(fileIn, fileOut);
         end
      else
         fileBase = [dirFloat '/' concatFileName];
         fileNew = [dirFloat '/' argosFileNames{idFile(idF)}];
         fprintf('   concatenating file %s contents to file %s in directory %s\n', argosFileNames{idFile(idF)}, concatFileName, dirFloat);
         concatenate_files(fileBase, fileNew);

         fileIn = [dirFloat '/' argosFileNames{idFile(idF)}];
         fileOut = [saveDirNow '/' argosFileNames{idFile(idF)}];
         fprintf('   moving file %s to directory %s\n', argosFileNames{idFile(idF)}, saveDirNow);
         move_file(fileIn, fileOut);
      end
      
   end
end
fprintf('DONT''T FORGET to set the cycle number of the resulting file\n');
fprintf('done\n');

return
