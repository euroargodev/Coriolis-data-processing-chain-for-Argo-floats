% ------------------------------------------------------------------------------
% Collect non transmission periods of Argo Argos floats (can be used to find DPF
% APEX floats or to confirm cycle durations).
%
% SYNTAX :
%   find_apex_dpf_floats or find_apex_dpf_floats(6900189, 7900118)
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
%   08/01/2015 - RNU - creation
% ------------------------------------------------------------------------------
function find_apex_dpf_floats(varargin)

% list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';

% float information file
FLOAT_INFORMATION_FILE_NAME_ALL = 'C:\Users\jprannou\_RNU\DecPrv_info\_prvFloatInfo\_apex_floats_information_co_all.txt';

% directory of Argos hex files
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecApx_info\ArgosProcessing\apex_argos_cycle\';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default values
global g_decArgo_janFirst1950InMatlab;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% number of hours (before launch date) to check the Argos data
NB_HOUR_BEFORE = 6;

% number of days (after launch date) to check the Argos data
NB_DAY_AFTER = 50;

% minimum duration (in hour) of a non-transmission period to consider
NB_HOUR_MIN = 5;


floatListFileName = FLOAT_LIST_FILE_NAME;
floatInformationFileNameAll = FLOAT_INFORMATION_FILE_NAME_ALL;

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

logFile = [DIR_LOG_CSV_FILE '/' 'find_apex_dpf_floats' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'find_apex_dpf_floats' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['Version; WMO; First (hours); All (days)'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag, listDecVersion] = ...
   get_floats_info_all(floatInformationFileNameAll);

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
   
   % find float launch date
   floatLaunchDate = listLaunchDate(idF);
   startDate = floatLaunchDate - (NB_HOUR_BEFORE/24);
   endDate = floatLaunchDate + NB_DAY_AFTER;
   
   % directory of Argos files for this float
   dirInputFloat = [DIR_INPUT_ARGOS_FILES '/' sprintf('%06d', floatArgosId) '/'];
   if (~isdir(dirInputFloat))
      fprintf('WARNING: No Argos data for float #%d\n', floatNum);
      continue;
   end
      
   % collect the dates of the float Argos messages in the considered period
   argosFloatMsgDate = [];
   argosFiles = dir([dirInputFloat '/' sprintf('*%d*', floatArgosId)]);
   for idFile = 1:length(argosFiles)
      
      argosFileName = argosFiles(idFile).name;
      argosFilePathName = [dirInputFloat '/' argosFileName];
      
      [val1, count1, errmsg1, nextindex1] = sscanf(argosFileName, '%d_%d-%d-%d-%d-%d-%d_%d.txt');

      if ((isempty(errmsg1) && (count1 == 8)))

         [argosLocDate, argosDataDate] = ...
            read_argos_file_fmt1_rough(argosFilePathName, floatArgosId);
         
         if (max(argosDataDate) < startDate)
            continue;
         elseif (min(argosDataDate) > endDate)
            break;
         else
            argosFloatMsgDate = [argosFloatMsgDate; argosDataDate];
         end
      end
   end
   
   idDel = find ((argosFloatMsgDate < startDate) | (argosFloatMsgDate > endDate));
   argosFloatMsgDate(idDel) = [];
   
   diffDates = diff(argosFloatMsgDate)*24;
   diffDates = diffDates(find(diffDates > NB_HOUR_MIN));
   
   fprintf(fidOut, '%s; %d;', listDecVersion{idF}, floatNum);
   if (~isempty(diffDates))
      fprintf(fidOut, '%f;', round(diffDates(1)*10)/10);
      fprintf(fidOut, '%f;', round((diffDates(1:end)/24)*10)/10);
   end
   fprintf(fidOut, '\n');
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Get floats information from floats information file.
%
% SYNTAX :
%  [o_listWmoNum, o_listDecId, o_listArgosId, o_listFrameLen, ...
%    o_listCycleTime, o_listDriftSamplingPeriod, o_listDelay, ...
%    o_listLaunchDate, o_listLaunchLon, o_listLaunchLat, ...
%    o_listRefDay, o_listEndDate, o_listDmFlag, o_listDecVersion] = ...
%    get_floats_info_all(a_floatInfoFileName)
%
% INPUT PARAMETERS :
%   a_floatInfoFileName : float information file name
%
% OUTPUT PARAMETERS :
%   o_listWmoNum          : floats WMO number
%   o_listDecId           : floats decoder Id
%   o_listArgosId         : floats PTT number
%   o_listFrameLen        : floats data frame length
%   o_listCycleTime       : floats cycle duration
%   o_driftSamplingPeriod : sampling period during drift phase (in hours)
%   o_listDelay           : DELAI parameter (in hours)
%   o_listLaunchDate      : floats launch date
%   o_listLaunchLon       : floats launch longitude
%   o_listLaunchLat       : floats launch latitude
%   o_listRefDay          : floats reference day (day of the first descent)
%   o_listEndDate         : floats end decoding date
%   o_listDmFlag          : floats DM flag
%   o_listDecVersion      : floats decoder version
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/01/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_listWmoNum, o_listDecId, o_listArgosId, o_listFrameLen, ...
   o_listCycleTime, o_listDriftSamplingPeriod, o_listDelay, ...
   o_listLaunchDate, o_listLaunchLon, o_listLaunchLat, ...
   o_listRefDay, o_listEndDate, o_listDmFlag, o_listDecVersion] = ...
   get_floats_info_all(a_floatInfoFileName)

% output parameters initialization
o_listWmoNum = [];
o_listDecId = [];
o_listArgosId = [];
o_listFrameLen = [];
o_listCycleTime = [];
o_listDriftSamplingPeriod = [];
o_listDelay = [];
o_listLaunchDate = [];
o_listLaunchLon = [];
o_listLaunchLat = [];
o_listRefDay = [];
o_listEndDate = [];
o_listDmFlag = [];
o_listDecVersion = [];

% default values
global g_decArgo_dateDef;


if ~(exist(a_floatInfoFileName, 'file') == 2)
   fprintf('ERROR: Float information file not found: %s\n', a_floatInfoFileName);
   return;
end

fId = fopen(a_floatInfoFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', a_floatInfoFileName);
end

data = textscan(fId, '%d %d %s %d %d %d %f %s %f %f %s %s %d %s');

o_listWmoNum = data{1}(:);
o_listDecId = data{2}(:);
o_listArgosId = data{3}(:);
o_listFrameLen = data{4}(:);
o_listCycleTime = data{5}(:);
o_listDriftSamplingPeriod = data{6}(:);
o_listDelay = data{7}(:);
listLaunchDate = data{8}(:);
o_listLaunchLon = data{9}(:);
o_listLaunchLat = data{10}(:);
listRefDay = data{11}(:);
listEndDate = data{12}(:);
o_listDmFlag = data{13}(:);
o_listDecVersion = data{14}(:);

fclose(fId);

o_listLaunchDate = ones(length(listLaunchDate), 1)*g_decArgo_dateDef;
o_listRefDay = ones(length(listRefDay), 1)*g_decArgo_dateDef;
o_listEndDate = ones(length(listRefDay), 1)*g_decArgo_dateDef;
for id = 1:length(listRefDay)
   launchDate = listLaunchDate{id};
   refDay = listRefDay{id};
   endDate = listEndDate{id};
   if (length(launchDate) == 14)
      o_listLaunchDate(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
         launchDate(1:4), launchDate(5:6), launchDate(7:8), ...
         launchDate(9:10), launchDate(11:12), launchDate(13:14)));
   end
   if (length(refDay) == 8)
      o_listRefDay(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s 00:00:00', ...
         refDay(1:4), refDay(5:6), refDay(7:8)));
   end
   if ((length(endDate) == 14) && (strcmp(endDate, '99999999999999') == 0))
      o_listEndDate(id, 1) = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
         endDate(1:4), endDate(5:6), endDate(7:8), ...
         endDate(9:10), endDate(11:12), endDate(13:14)));
   end
end

return;
