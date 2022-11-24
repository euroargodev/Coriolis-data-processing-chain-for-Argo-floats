% ------------------------------------------------------------------------------
% Check the Argos files of the Argos spool directory (last Argos data date and
% file date time) to find emitting floats and files near to be archived.
%
% SYNTAX :
%   check_argos_spool_directory or check_argos_spool_directory(6900189, 7900118)
%   or check_argos_spool_directory('all')
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process or 'all' to check all the files
%              of the Argos spool directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/28/2015 - RNU - creation
% ------------------------------------------------------------------------------
function check_argos_spool_directory(varargin)

% Argos spool directory
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\IN\tmp\spool_cycle_20150601\';
DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\temp_20150624\spool_argos\';

% directory of JSON information files
DIR_JSON_FLOAT_INFO_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\temp_20150624\json_float_info\';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\'; 

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_janFirst1950InMatlab;

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
   if (strcmp(floatList, 'all'))
      name = '_all';
      floatList = [];
   else
      name = sprintf('_%d', floatList);
   end
end

logFile = [DIR_LOG_CSV_FILE '/' 'check_argos_spool_directory' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'check_argos_spool_directory' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['Float status; WMO; Argos Id; File name; First data date; Last data date; Ellapsed time since last Argos data; Comment'];
fprintf(fidOut, '%s\n', header);

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
   
   % find current float Argos Id in the .txt list file
   floatArgosIdInTxt = [];
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d in file %s\n', ...
         floatNum, floatInformationFileName);
   else
      floatArgosIdInTxt = str2num(listArgosId{idF});
   end

   % find current float Argos Id in the .json files
   floatArgosIdInJson = [];
   [~, floatArgosIdInJson, floatDecId] = get_json_float_info( ...
      floatNum, [], DIR_JSON_FLOAT_INFO_FILES, []);
   
   floatArgosId = [];
   floatState = [];
   if (~isempty(floatArgosIdInTxt) && ~isempty(floatArgosIdInJson))
      floatArgosId = floatArgosIdInTxt;
      if (floatDecId ~= -1)
         floatState = 'Managed by the decoder';
      else
         floatState = 'Not managed by the decoder';
      end
   elseif (~isempty(floatArgosIdInTxt))
      floatArgosId = floatArgosIdInTxt;
      floatState = 'Under declaration';
   elseif (~isempty(floatArgosIdInJson))
      floatState = 'Not managed by the decoder';
   else
      floatState = 'Unknown';
   end
   
   if (~isempty(floatArgosId))
   
      % select the Argos files associated with the current float
      argosFiles = dir([DIR_INPUT_ARGOS_FILES '/' sprintf('%06d_*', floatArgosId)]);
      nbFiles = length(argosFiles);
      for idF = 1:nbFiles
         
         argosFileName = argosFiles(idF).name;
         argosFilePathName = [DIR_INPUT_ARGOS_FILES '/' argosFileName];
         
         % read dates in the file without checking its consistency
         [argosLocDate, argosDataDate] = ...
            read_argos_file_fmt1_rough(argosFilePathName, floatArgosId);
         
         comment = 'Ok (free file)';
         % ellapsed time since last Argos data
         nowVsLastArgosData = (now_utc-(max([argosLocDate; argosDataDate])+g_decArgo_janFirst1950InMatlab))*24;
         if (nowVsLastArgosData < g_decArgo_minNonTransDurForNewCycle)
            comment = 'Float is transmitting (< 18 h)';
         elseif (nowVsLastArgosData > 23)
            comment = 'File is near to be archived (> 23 h). ';
         end
         
         fprintf(fidOut, '%s; %d; %d; %s; %s; %s; %s; %s\n', ...
            floatState, floatNum, floatArgosId, argosFileName, ...
            julian_2_gregorian_dec_argo(min([argosLocDate; argosDataDate])), ...
            julian_2_gregorian_dec_argo(max([argosLocDate; argosDataDate])), ...
            format_time_dec_argo(nowVsLastArgosData), ...
            comment);
      end
   else
      fprintf(fidOut, '%s; %d\n', ...
         floatState, floatNum);
   end
end

% process all the files of the Argos spool directory
if (isempty(floatList))
   
   argosFiles = dir([DIR_INPUT_ARGOS_FILES '/*.txt']);
   nbFiles = length(argosFiles);
   for idF = 1:nbFiles
            
      argosFileName = argosFiles(idF).name;
      argosFilePathName = [DIR_INPUT_ARGOS_FILES '/' argosFileName];
      
      fprintf('%03d/%03d %s\n', idF, nbFiles, argosFileName);
      
      % get the Argos Id from file name
      idFUs = strfind(argosFileName, '_');
      floatArgosId = str2num(argosFileName(1:idFUs(1)-1));
      
      % read dates in the file without checking its consistency
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(argosFilePathName, floatArgosId);
      
      % retrieve WMO number for the floats managed by the decoder
      floatNumInTxt = '';
      idF1 = find(listDecId < 100);
      S = sprintf('%s*', listArgosId{idF1});
      argosIdList = sscanf(S, '%f*');
      idF2 = find(argosIdList == floatArgosId);
      if (~isempty(idF2))
         if (length(idF2) == 1)
            floatNumInTxt = num2str(listWmoNum(idF1(idF2)));
         else
            idF3 = find(listLaunchDate(idF1(idF2)) <= min([argosLocDate; argosDataDate]));
            if (isempty(idF3))
               [~, idMin] = min(listLaunchDate(idF1(idF2)));
               floatNumInTxt = num2str(listWmoNum(idF1(idF2(idMin))));
            else
               [~, idMax] = max(listLaunchDate(idF1(idF2(idF3))));
               floatNumInTxt = num2str(listWmoNum(idF1(idF2(idF3(idMax)))));
            end
         end
      end
      
      % find float WMO number in the .json files
      floatNumInJson = [];
      [floatNumInJson, ~, floatDecId] = get_json_float_info( ...
         [], floatArgosId, DIR_JSON_FLOAT_INFO_FILES, argosFilePathName);
      
      floatNum = [];
      floatState = [];
      if (~isempty(floatNumInTxt) && ~isempty(floatNumInJson))
         floatNum = floatNumInTxt;
         if (floatDecId ~= -1)
            floatState = 'Managed by the decoder';
         else
            floatState = 'Not managed by the decoder';
         end
      elseif (~isempty(floatNumInTxt))
         floatNum = floatNumInTxt;
         floatState = 'Under declaration';
      elseif (~isempty(floatNumInJson))
         floatNum = floatNumInJson;
         floatState = 'Not managed by the decoder';
      elseif (isempty(floatNumInJson) && ~isempty(floatDecId))
         floatState = 'Not managed by the decoder';
      else
         floatState = 'Unknown';
      end
      
      comment = 'Ok (free file)';
      % ellapsed time since last Argos data
      nowVsLastArgosData = (now_utc-(max([argosLocDate; argosDataDate])+g_decArgo_janFirst1950InMatlab))*24;
      if (nowVsLastArgosData < g_decArgo_minNonTransDurForNewCycle)
         comment = 'Float is transmitting';
      end
      % ellapsed time since last file update
      nowVsLastFileUpdate = (now-datenum(argosFiles(idF).date, 'dd-mmmm-yyyy HH:MM:SS'))*24;
      if (nowVsLastFileUpdate > 24)
         comment = 'File is near to be archived';
      end
      
      fprintf(fidOut, '%s; %s; %d; %s; %s; %s; %s; %s; %s; %s\n', ...
         floatState, floatNum, floatArgosId, argosFileName, ...
         julian_2_gregorian_dec_argo(min([argosLocDate; argosDataDate])), ...
         julian_2_gregorian_dec_argo(max([argosLocDate; argosDataDate])), ...
         datestr(datenum(argosFiles(idF).date, 'dd-mmmm-yyyy HH:MM:SS'), 'yyyy/mm/dd HH:MM:SS'), ...
         format_time_dec_argo(nowVsLastArgosData), ...
         format_time_dec_argo(nowVsLastFileUpdate), ...
         comment);
   end   
   
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Get float information from JSON float information file.
%
% SYNTAX :
%  [o_floatNum, o_floatArgosId, o_floatDecId] = get_json_float_info( ...
%    a_floatNum, a_floatArgosId, a_jsonFloatInfoDirName, a_argosFilePathName)
%
% INPUT PARAMETERS :
%   a_floatNum              : float WMO number (empty if a_floatArgosId is not
%                             empty)
%   a_floatArgosId          : float Argos Id number (empty if a_floatNum is not
%                             empty)
%   a_jsonFloatInfoDirName  : directory of the JSON information files
%   a_argosFilePathName     : Argos file path name (used to choose between
%                             multiple WMO assigned to the same Argos Id) (empty
%                             if a_floatNum is not empty)
%
% OUTPUT PARAMETERS :
%   o_floatNum     : float WMO number
%   o_floatArgosId : float PTT number
%   o_floatDecId   : float decoder Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/17/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatNum, o_floatArgosId, o_floatDecId] = get_json_float_info( ...
   a_floatNum, a_floatArgosId, a_jsonFloatInfoDirName, a_argosFilePathName)

% output parameters initialization
o_floatNum = [];
o_floatArgosId = [];
o_floatDecId = [];


if (~isempty(a_floatNum))
   
   % json float information file name
   floatInfoFileNames = dir([a_jsonFloatInfoDirName '/' sprintf('%d_*_info.json', a_floatNum)]);
   if (isempty(floatInfoFileNames))
      return;
   elseif (length(floatInfoFileNames) == 1)
      floatInfoFileName = [a_jsonFloatInfoDirName '/' floatInfoFileNames(1).name];
   else
      fprintf('ERROR: Multiple float information files for float #%d\n', a_floatNum);
      return;
   end
   
elseif (~isempty(a_floatArgosId))

   % json float information file name
   floatInfoFileNames = dir([a_jsonFloatInfoDirName '/' sprintf('*_%d_info.json', a_floatArgosId)]);
   if (isempty(floatInfoFileNames))
      return;
   elseif (length(floatInfoFileNames) == 1)
      floatInfoFileName = [a_jsonFloatInfoDirName '/' floatInfoFileNames(1).name];
   else
      % we must choose between multiple JSON files
      
      % read dates in the file without checking its consistency
      [argosLocDate, argosDataDate] = ...
         read_argos_file_fmt1_rough(a_argosFilePathName, a_floatArgosId);
      lastArgosMsgDate = max(argosDataDate);
      
      if (isempty(lastArgosMsgDate))
         fprintf('WARNING: Input Argos file (%s) is empty => cannot choose between possible WMO numbers\n', a_argosFilePathName);
         return;
      end
      
      % collect launch dates of possible json files
      fileName = [];
      launchDate = [];
      for idFile = 1:length(floatInfoFileNames)
         
         filePathName = [a_jsonFloatInfoDirName '/' floatInfoFileNames(idFile).name];
         
         % read information file
         fileContents = loadjson(filePathName);
         
         expectedFields = [];
         expectedFields{end+1} = 'LAUNCH_DATE';
         
         if (sum(isfield(fileContents, expectedFields)) ~= length(expectedFields))
            fprintf('ERROR: Missing data in float information file: %s\n', filePathName);
            return;
         end
         
         floatLaunchDateStr = fileContents.LAUNCH_DATE;
         if (~strcmp(floatLaunchDateStr, 'Unknown'))
            floatLaunchDate = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
               floatLaunchDateStr(1:4), floatLaunchDateStr(5:6), floatLaunchDateStr(7:8), ...
               floatLaunchDateStr(9:10), floatLaunchDateStr(11:12), floatLaunchDateStr(13:14)));
            
            fileName{end+1} = filePathName;
            launchDate(end+1) = floatLaunchDate;
         end
      end
      
      if (isempty(fileName))
         o_floatDecId = -1;
         return;
      else
         % sort the files according to launch dates
         [launchDate, idSort] = sort(launchDate);
         fileName = fileName(idSort);
         
         idF = find(lastArgosMsgDate > launchDate);
         if (~isempty(idF))
            idFloat = idF(end);
         else
            [unused, idMin] = min(launchDate);
            idFloat = idMin;
         end
         
         floatInfoFileName = fileName{idFloat};
      end
   end
end

% read information file
fileContents = loadjson(floatInfoFileName);

if (~strcmp(fileContents.WMO, 'Unknown'))
   o_floatNum = str2num(fileContents.WMO);
end
if (~strcmp(fileContents.PTT, 'Unknown'))
   o_floatArgosId = str2num(fileContents.PTT);
end
o_floatDecId = str2num(fileContents.DECODER_ID);

return;
