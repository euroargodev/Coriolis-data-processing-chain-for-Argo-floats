% ------------------------------------------------------------------------------
% Check and retrieve statistical information on Argos cycle files.
%
% SYNTAX :
%   check_argos_cycle_files or check_argos_cycle_files(6900189, 7900118)
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
%   02/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function check_argos_cycle_files(varargin)

% directory of the argos files to check
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS\cycle\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\collectes_20161202\tmp2\ori_out\FINAL\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\ARGOS\cycle\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\OUT\FINAL\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_ARGOS_APF11\OUT_CO\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\Desktop\TMP\OUT\FINAL\';

% directory to store the log and CSV files
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% min non-trans duration (in hour) to use the ghost detection
MIN_NON_TRANS_DURATION_FOR_GHOST = 7;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% date of the last check
LAST_CHECK_GREG_DATE = '01/01/1900';
lastCheckMatDate = datenum(LAST_CHECK_GREG_DATE, 'dd/mm/YYYY');

% consider only active floats (since last check date)
ONLY_ACTIVE_FLOATS_FLAG = 0;


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

logFile = [DIR_LOG_FILE '/' 'check_argos_cycle_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_FILE '/' 'check_argos_cycle_files' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['To check; Line; WMO; File; Cy #; Missing cy; Cy dur; ' ...
   'JulD first; JulD last; Trans dur; Nb ghost del; ' ...
   'Max non-trans time; JulD before; JulD after; Cor trans dur'];
fprintf(fidOut, '%s\n', header);
      
% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbLine = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   tabCycleNumber = [];
   tabFirstMsgDate = [];
   
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
   dirFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   argosFiles = dir([dirFloat '/' sprintf('*%d*%d*', floatArgosId, floatNum)]);
   
   % if we want to consider only floats for which cycle files have been modified
   % since the last check
   if (ONLY_ACTIVE_FLOATS_FLAG == 1)
      consider = 0;
      for idFile = 1:length(argosFiles)
         if (argosFiles(idFile).datenum >= lastCheckMatDate)
            consider = 1;
            break
         end
      end
      if (consider == 0)
         continue
      end
   end
   
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
         tabCycleNumber = [tabCycleNumber; cycleNumber];
         tabFirstMsgDate =[tabFirstMsgDate; min(argosDataDate)];
      end
      
      [maxNonTransTime, idMax] = max(diff(argosDate)*24);
      juldLastBefore = julian_2_gregorian_dec_argo(argosDate(idMax));
      juldFirstAfter = julian_2_gregorian_dec_argo(argosDate(idMax+1));
      minDate = min(argosDate);
      maxDate = max(argosDate);
      juldFirst = julian_2_gregorian_dec_argo(minDate);
      juldLast = julian_2_gregorian_dec_argo(maxDate);
      
      ghostMsgNb = 0;
      if (maxNonTransTime >= MIN_NON_TRANS_DURATION_FOR_GHOST)
         stop = 0;
         while(~stop)
            if (strcmp(juldFirst, juldLastBefore) == 1)
               idDel = find(argosDate == argosDate(idMax));
               argosDate(idDel) = [];
               ghostMsgNb = ghostMsgNb + 1;
            elseif (strcmp(juldFirstAfter, juldLast) == 1)
               idDel = find(argosDate == argosDate(idMax+1));
               argosDate(idDel) = [];
               ghostMsgNb = ghostMsgNb + 1;
            else
               stop = 1;
            end
            
            if (stop == 0)
               [maxNonTransTime, idMax] = max(diff(argosDate)*24);
               juldLastBefore = julian_2_gregorian_dec_argo(argosDate(idMax));
               juldFirstAfter = julian_2_gregorian_dec_argo(argosDate(idMax+1));
               minDate = min(argosDate);
               maxDate = max(argosDate);
               juldFirst = julian_2_gregorian_dec_argo(minDate);
               juldLast = julian_2_gregorian_dec_argo(maxDate);
               if (maxNonTransTime < MIN_NON_TRANS_DURATION_FOR_GHOST)
                  stop = 1;
               end
            end
         end
      end

      % compute cycle duration
      cycleDuration = [];
      missingCycles = [];
      if (~isempty(cycleNumber) && (cycleNumber > 0))
         idPrevCy = find(tabCycleNumber < cycleNumber);
         if (~isempty(idPrevCy))
            idPrevCy = idPrevCy(end);
            if (tabCycleNumber(idPrevCy) == cycleNumber-1)
               cycleDuration = min(argosDataDate) - tabFirstMsgDate(idPrevCy);
               missingCycles = 0;
            else
               missingCycles = cycleNumber - tabCycleNumber(idPrevCy) - 1;
            end
         else
            missingCycles = cycleNumber;
         end
      end
      
      toCheck = 0;
      if (argosFiles(idFile).datenum >= lastCheckMatDate)
         toCheck = 1;
      end
      fprintf(fidOut, '%d; %d; %d; %s; %d; %d; %.1f; %s; %s; %.1f; %d; %.1f; %s; %s; %.1f\n', ...
         toCheck, nbLine, floatNum, argosFileName, ...
         cycleNumber, missingCycles, cycleDuration, ...
         juldFirst, juldLast, ...
         (maxDate-minDate)*24, ...
         ghostMsgNb, ...
         maxNonTransTime, ...
         juldLastBefore, juldFirstAfter, ...
         ((maxDate-minDate)*24)-maxNonTransTime);

      nbLine = nbLine + 1;

   end
   
   fprintf(fidOut, '; %d\n', nbLine);
   nbLine = nbLine + 1;

end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
