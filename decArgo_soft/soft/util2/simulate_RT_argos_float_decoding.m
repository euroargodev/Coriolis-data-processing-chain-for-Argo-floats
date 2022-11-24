% ------------------------------------------------------------------------------
% Launh decode_provor_2_nc_rt on Argos files of a given list of floats.
%
% SYNTAX :
%   simulate_RT_argos_float_decoding or simulate_RT_argos_float_decoding(6900189, 7900118)
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
%   01/23/2014 - RNU - creation
% ------------------------------------------------------------------------------
function simulate_RT_argos_float_decoding(varargin)

% DIR_INPUT_ARGOS_FILES = 'C:\users\RNU\Argo\work\input\088423\';
DIR_INPUT_ARGOS_FILES = 'C:\users\RNU\Argo\argos\coriolis\bascule_20140303\argos_files_copy\';
DIR_REJECTED_ARGOS_FILES = 'C:\users\RNU\Argo\argos\coriolis\bascule_20140303\argos_files_rejected\';
DIR_EMPTY_ARGOS_FILES = 'C:\users\RNU\Argo\argos\coriolis\bascule_20140303\argos_files_empty\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

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

% create the output directories
if ~(exist(DIR_REJECTED_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_REJECTED_ARGOS_FILES);
end
if ~(exist(DIR_EMPTY_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_EMPTY_ARGOS_FILES);
end

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

logFile = [DIR_LOG_FILE '/' 'simulate_RT_argos_float_decoding_' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

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
      continue
   end
   floatArgosId = str2num(listArgosId{idF});
   floatFrameLen = listFrameLen(idF);
   
   % select and sort the Argos files of the float
   argosFileNames = [];
   argosFileFirstMsgDate = [];
   argosFiles = dir([DIR_INPUT_ARGOS_FILES '/' sprintf('*%d_*', floatArgosId)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [DIR_INPUT_ARGOS_FILES '/' argosFileName];
      
      [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d.txt');
      [val2, count2, errmsg2, nextindex2] = sscanf(argosFileName, '%d_%d-%d-%d_%d.txt');
      [val3, count3, errmsg3, nextindex3] = sscanf(argosFileName, '%d_%d-%d-%d_%d_%d.txt');
      [val4, count4, errmsg4, nextindex4] = sscanf(argosFileName, '%d_%d-%d-%d_%d_%d_%d.txt');
      [val5, count5, errmsg5, nextindex5] = sscanf(argosFileName, '%d_%d-%d-%d_%d_XXX.txt');
      [val6, count6, errmsg6, nextindex6] = sscanf(argosFileName, '%d_%d-%d-%d_XXXXXXX_XXX.txt');
      [val7, count7, errmsg7, nextindex7] = sscanf(argosFileName, '%d_%d-%d-%d_%d_XXX_%d.txt');
      [val8, count8, errmsg8, nextindex8] = sscanf(argosFileName, '%d_%d-%d-%d_XXXXXXX_XXX_%d.txt');
      [val9, count9, errmsg9, nextindex9] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d.txt');
      [val10, count10, errmsg10, nextindex10] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_%d.txt');
      [val11, count11, errmsg11, nextindex11] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_EEE.txt');
      [val12, count12, errmsg12, nextindex12] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_WWW.txt');
      [val13, count13, errmsg13, nextindex13] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_MMM.txt');
      [val14, count14, errmsg14, nextindex14] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_TTT.txt');
      [val15, count15, errmsg15, nextindex15] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_GGG.txt');
      [val16, count16, errmsg16, nextindex16] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d_UUU.txt');
      [val17, count17, errmsg17, nextindex17] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_WWWWWWW_EEE.txt');
      [val18, count18, errmsg18, nextindex18] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_WWWWWWW_WWW.txt');
      [val19, count19, errmsg19, nextindex19] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_WWWWWWW_MMM.txt');
      [val20, count20, errmsg20, nextindex20] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_WWWWWWW_TTT.txt');
      [val21, count21, errmsg21, nextindex21] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_WWWWWWW_GGG.txt');
      [val22, count22, errmsg22, nextindex22] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_WWWWWWW_UUU.txt');
      
      if ((isempty(errmsg1) && (count1 == 4)) || ...
            (isempty(errmsg2) && (count2 == 5)) || ...
            (isempty(errmsg3) && (count3 == 6)) || ...
            (isempty(errmsg4) && (count4 == 7)) || ...
            (isempty(errmsg5) && (count5 == 5)) || ...
            (isempty(errmsg6) && (count6 == 4)) || ...
            (isempty(errmsg7) && (count7 == 6)) || ...
            (isempty(errmsg8) && (count8 == 5)) || ...
            (isempty(errmsg9) && (count9 == 8)) || ...
            (isempty(errmsg10) && (count10 == 9)) || ...
            (isempty(errmsg11) && (count11 == 8)) || ...
            (isempty(errmsg12) && (count12 == 8)) || ...
            (isempty(errmsg13) && (count13 == 8)) || ...
            (isempty(errmsg14) && (count14 == 8)) || ...
            (isempty(errmsg15) && (count15 == 8)) || ...
            (isempty(errmsg16) && (count16 == 8)) || ...
            (isempty(errmsg17) && (count17 == 7)) || ...
            (isempty(errmsg18) && (count18 == 7)) || ...
            (isempty(errmsg19) && (count19 == 7)) || ...
            (isempty(errmsg20) && (count20 == 7)) || ...
            (isempty(errmsg21) && (count21 == 7)) || ...
            (isempty(errmsg22) && (count22 == 7)))
         
         [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
            argosDataDate, argosDataData] = read_argos_file_fmt1({argosFilePathName}, floatArgosId, floatFrameLen);
         
         if ~(isempty(argosDataDate) && isempty(argosLocDate))
            argosFileNames{end+1} = argosFilePathName;
            argosFileFirstMsgDate(end+1) = min(argosDataDate);
         else
            % move the file to the empty files directory
            move_file(argosFilePathName, DIR_EMPTY_ARGOS_FILES);
         end
      else
         % move the file to the rejected files directory
         move_file(argosFilePathName, DIR_REJECTED_ARGOS_FILES);
      end
   end
   
   % chronologically sort the files
   [argosFileFirstMsgDate, idSort] = sort(argosFileFirstMsgDate);
   argosFileNames = argosFileNames(idSort);
   
   % process the Argos files of the float
   nbFiles = length(argosFileNames);
   for idFile = 1:nbFiles
      cmd = ['matlab -nodesktop -nosplash -r "decode_provor_2_nc_rt(''processmode'', ''all'', ''argosfile'', ''' argosFileNames{idFile} ''');exit"'];
      fprintf('File %03d/%03d: Processing file %s\n%s\n', idFile, nbFiles, argosFileNames{idFile}, cmd);
      system(cmd);
   end
end

fprintf('done\n');

diary off;

return
