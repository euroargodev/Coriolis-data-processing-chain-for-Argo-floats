% ------------------------------------------------------------------------------
% Get float information from float information json file.
%
% SYNTAX :
%  [o_floatNum, o_floatArgosId, ...
%    o_floatDecVersion, o_floatDecId, ...
%    o_floatFrameLen, ...
%    o_floatCycleTime, o_floatDriftSamplingPeriod, o_floatDelay, ...
%    o_floatLaunchDate, o_floatLaunchLon, o_floatLaunchLat, ...
%    o_floatRefDay, o_floatEndDate, ...
%    o_floatDmFlag] = get_one_float_info(a_floatNum, a_floatArgosId)
%
% INPUT PARAMETERS :
%   a_floatNum      : float WMO number (empty if a_floatArgosId is not empty)
%   a_floatArgosId  : float Argos Id number (empty if a_floatNum is not empty)
%
% OUTPUT PARAMETERS :
%   o_floatNum                 : float WMO number
%   o_floatArgosId             : float PTT number
%   o_floatDecVersion          : Coriolis float decoder version
%   o_floatDecId               : float decoder Id
%   o_floatFrameLen            : float data frame length
%   o_floatCycleTime           : float cycle duration
%   o_floatDriftSamplingPeriod : float sampling period during drift phase
%                                (in hours)
%   o_floatDelay               : DELAI parameter (in hours)
%   o_floatLaunchDate          : float launch date
%   o_floatLaunchLon           : float launch longitude
%   o_floatLaunchLat           : float launch latitude
%   o_floatRefDay              : float reference day (day of the first descent)
%   o_floatEndDate             : float end decoding date
%   o_floatDmFlag              : float DM flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/17/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatNum, o_floatArgosId, ...
   o_floatDecVersion, o_floatDecId, ...
   o_floatFrameLen, ...
   o_floatCycleTime, o_floatDriftSamplingPeriod, o_floatDelay, ...
   o_floatLaunchDate, o_floatLaunchLon, o_floatLaunchLat, ...
   o_floatRefDay, o_floatEndDate, ...
   o_floatDmFlag] = get_one_float_info(a_floatNum, a_floatArgosId)

% output parameters initialization
o_floatNum = [];
o_floatArgosId = [];
o_floatDecVersion = [];
o_floatDecId = [];
o_floatFrameLen = [];
o_floatCycleTime = [];
o_floatDriftSamplingPeriod = [];
o_floatDelay = [];
o_floatLaunchDate = [];
o_floatLaunchLon = [];
o_floatLaunchLat = [];
o_floatRefDay = [];
o_floatEndDate = [];
o_floatDmFlag = [];

% global configuration values
global g_decArgo_dirInputJsonFloatDecodingParametersFile;

% global input parameter information
global g_decArgo_inputArgosFile;

% default values
global g_decArgo_dateDef;


% json float information file name
if (~isempty(a_floatNum))
   floatInfoFileNames = dir([g_decArgo_dirInputJsonFloatDecodingParametersFile '/' sprintf('%d_*_info.json', a_floatNum)]);
   if (length(floatInfoFileNames) == 1)
      floatInfoFileName = [g_decArgo_dirInputJsonFloatDecodingParametersFile '/' floatInfoFileNames(1).name];
   elseif (isempty(floatInfoFileNames))
      fprintf('WARNING: Float information file not found for float #%d\n', a_floatNum);
      return;
   else
      fprintf('ERROR: Multiple float information files for float #%d\n', a_floatNum);
      return;
   end
   
elseif (~isempty(a_floatArgosId))
   floatInfoFileNames = dir([g_decArgo_dirInputJsonFloatDecodingParametersFile '/' sprintf('*_%d_info.json', a_floatArgosId)]);
   if (length(floatInfoFileNames) == 1)
      floatInfoFileName = [g_decArgo_dirInputJsonFloatDecodingParametersFile '/' floatInfoFileNames(1).name];
   elseif (isempty(floatInfoFileNames))
      fprintf('WARNING: Float information file not found for Argos Id #%d\n', a_floatArgosId);
      return;
   else
      for idF = 1: length(floatInfoFileNames)
         if (~isempty(strfind(floatInfoFileNames(idF).name, 'WWWWWWW_')))
            fprintf('ERROR: Conflict between one JSON info file (%s) and the other ones => clean the set of JSON info files for this float\n', floatInfoFileNames(idF).name);
            return;
         end
      end
      % read Argos file
      [argosLocDate, argosLocLon, argosLocLat, argosLocAcc, argosLocSat, ...
         argosDataDate, argosDataData] = read_argos_file({g_decArgo_inputArgosFile}, a_floatArgosId, 31);
      lastArgosMsgDate = max(argosDataDate);
      
      if (isempty(lastArgosMsgDate))
         fprintf('WARNING: Input Argos file (%s) is empty => cannot choose between possible WMO numbers\n', g_decArgo_inputArgosFile);
         return;
      end
      
      % collect launch dates of possible json files
      fileName = [];
      launchDate = [];
      for idFile = 1:length(floatInfoFileNames)
         
         filePathName = [g_decArgo_dirInputJsonFloatDecodingParametersFile '/' floatInfoFileNames(idFile).name];
         
         % read information file
         fileContents = loadjson(filePathName);
         
         expectedFields = [];
         expectedFields{end+1} = 'LAUNCH_DATE';
         
         if (sum(isfield(fileContents, expectedFields)) ~= length(expectedFields))
            fprintf('ERROR: Missing data in float information file: %s\n', filePathName);
            return;
         end
         
         floatLaunchDateStr = getfield(fileContents, 'LAUNCH_DATE');
         floatLaunchDate = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
            floatLaunchDateStr(1:4), floatLaunchDateStr(5:6), floatLaunchDateStr(7:8), ...
            floatLaunchDateStr(9:10), floatLaunchDateStr(11:12), floatLaunchDateStr(13:14)));
         
         fileName{end+1} = filePathName;
         launchDate(end+1) = floatLaunchDate;
      end
      
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

% read information file
fileContents = loadjson(floatInfoFileName);

% check if this float can be decoded by this decoder
floatDecId = str2num(getfield(fileContents, 'DECODER_ID'));
if (floatDecId == -1)
   
   if (~strcmp(getfield(fileContents, 'WMO'), 'Unknown'))
      % float in the data base but not decoded
      o_floatNum = str2num(getfield(fileContents, 'WMO'));
      
      floatType = getfield(fileContents, 'FLOAT_TYPE');
      floatDecVersion = getfield(fileContents, 'DECODER_VERSION');
      
      fprintf('INFO: Float #%d (FLOAT_TYPE:%s, Coriolis version: %s) is not decoded by this decoder\n', ...
         o_floatNum, floatType, floatDecVersion);
   else
      % float not in the data base and not decoded
      fprintf('INFO: Float with Argos Id #%d is not decoded by this decoder\n', ...
         a_floatArgosId);
   end
else
   
   expectedFields = [];
   expectedFields{end+1} = 'WMO';
   expectedFields{end+1} = 'PTT';
   expectedFields{end+1} = 'FLOAT_TYPE';
   expectedFields{end+1} = 'DECODER_VERSION';
   expectedFields{end+1} = 'DECODER_ID';
   expectedFields{end+1} = 'FRAME_LENGTH';
   expectedFields{end+1} = 'CYCLE_LENGTH';
   expectedFields{end+1} = 'DRIFT_SAMPLING_PERIOD';
   expectedFields{end+1} = 'DELAI';
   expectedFields{end+1} = 'LAUNCH_DATE';
   expectedFields{end+1} = 'LAUNCH_LON';
   expectedFields{end+1} = 'LAUNCH_LAT';
   expectedFields{end+1} = 'END_DECODING_DATE';
   expectedFields{end+1} = 'REFERENCE_DAY';
   expectedFields{end+1} = 'DM_FLAG';
   
   if (sum(isfield(fileContents, expectedFields)) ~= length(expectedFields))
      fprintf('ERROR: Missing data in float information file: %s\n', floatInfoFileName);
      return;
   end
   
   o_floatNum = str2num(getfield(fileContents, 'WMO'));
   o_floatArgosId = getfield(fileContents, 'PTT');
   o_floatDecVersion = getfield(fileContents, 'DECODER_VERSION');
   o_floatDecId = str2num(getfield(fileContents, 'DECODER_ID'));
   o_floatFrameLen = str2num(getfield(fileContents, 'FRAME_LENGTH'));
   o_floatCycleTime = str2num(getfield(fileContents, 'CYCLE_LENGTH'));
   o_floatDriftSamplingPeriod = str2num(getfield(fileContents, 'DRIFT_SAMPLING_PERIOD'));
   o_floatDelay = str2num(getfield(fileContents, 'DELAI'));
   floatLaunchDate = getfield(fileContents, 'LAUNCH_DATE');
   o_floatLaunchDate = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
      floatLaunchDate(1:4), floatLaunchDate(5:6), floatLaunchDate(7:8), ...
      floatLaunchDate(9:10), floatLaunchDate(11:12), floatLaunchDate(13:14)));
   o_floatLaunchLon = str2num(getfield(fileContents, 'LAUNCH_LON'));
   o_floatLaunchLat = str2num(getfield(fileContents, 'LAUNCH_LAT'));
   floatEndDate = getfield(fileContents, 'END_DECODING_DATE');
   if (strcmp(floatEndDate, '99999999999999'))
      o_floatEndDate = g_decArgo_dateDef;
   else
      o_floatEndDate = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s %s:%s:%s', ...
         floatEndDate(1:4), floatEndDate(5:6), floatEndDate(7:8), ...
         floatEndDate(9:10), floatEndDate(11:12), floatEndDate(13:14)));
   end
   floatRefDay = getfield(fileContents, 'REFERENCE_DAY');
   o_floatRefDay = gregorian_2_julian_dec_argo(sprintf('%s/%s/%s 00:00:00', ...
      floatRefDay(1:4), floatRefDay(5:6), floatRefDay(7:8)));
   o_floatDmFlag = str2num(getfield(fileContents, 'DM_FLAG'));
end

return;
