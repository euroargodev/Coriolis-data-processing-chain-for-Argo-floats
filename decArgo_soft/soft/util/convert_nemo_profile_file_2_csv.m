% ------------------------------------------------------------------------------
% Read all .profile files of a NEMO float and retrieve meta-data and data in a
% CSV file.
%
% SYNTAX :
%   convert_nemo_profile_file_2_csv or convert_nemo_profile_file_2_csv(6900189, 7900118)
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
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function convert_nemo_profile_file_2_csv(varargin)

% directory of .profile files
DIR_INPUT_PROFILE_FILES = 'C:\Users\jprannou\_DATA\IN\IRIDIUM_DATA\NEMO\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the output csv files
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values initialization
init_default_values;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
      fprintf('ERROR: File not found: %s\n', floatListFileName);
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

timeInfo = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'convert_nemo_profile_file_2_csv' name '_' timeInfo '.log'];
diary(logFile);
tic;

% get floats information
[listWmoNum, listDecId, listSn, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   g_decArgo_floatNum = floatNum;
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % create the CSV output file
   outputFileName = [DIR_CSV_FILE '/' 'convert_nemo_profile_file_2_csv_' num2str(floatNum) '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      return
   end
   header = ['WMO #; Cycle #; Info type; Name; Value'];
   fprintf(fidOut, '%s\n', header);
   
   % find float SN
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d - nothing done for this float\n', floatNum);
      continue
   end
   floatSerialNumStr = sprintf('%04d', str2num(listSn{idF}));
   
   dirPathFileName = [DIR_INPUT_PROFILE_FILES '/' floatSerialNumStr '_' num2str(floatNum) '/archive/'];
   fileNames = dir([dirPathFileName '/' floatSerialNumStr '*.profile']);
   
   % retrieve available cycle numbers
   cycleList = [];
   fileNameList = [];
   for idFile = 1:length(fileNames)
      fileName = fileNames(idFile).name;
      idF1 = strfind(fileName, num2str(floatNum));
      idF2 = strfind(fileName, '_');
      idF3 = find(idF2 > idF1);
      cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
      [cyNum, status] = str2num(cyNum);
      if (status)
         cycleList = [cycleList cyNum];
         fileNameList{end+1} = fileName;
      end
   end
   
   % sort files according to cycle numbers
   [cycleList, idSorted] = sort(cycleList);
   fileNameList = fileNameList(idSorted);
   
   % process .profile files of this float
   for idFile = 1:length(fileNameList)
      g_decArgo_cycleNum = cycleList(idFile);
      profileFileName = fileNameList{idFile};
      
      fprintf(fidOut, '%d; %d; FileName; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         profileFileName);

      fprintf('   %03d/%03d Float: %d File: %s\n', idFile, length(fileNames), floatNum, profileFileName);
      
      profilePathFileName = [dirPathFileName '/' profileFileName];
      
      % read .profile file
      [ ...
         error, ...
         floatIdentificationStr, ...
         overallMissionInformationStr, ...
         deploymentInfoStr, ...
         profileTechnicalDataStr, ...
         bottomValuesDuringDriftStr, ...
         rafosValuesFormatStr, ...
         rafosValuesStr, ...
         profileHeaderStr, ...
         qualityControlHeaderStr, ...
         profileDataHeaderStr, ...
         profileDataStr, ...
         surfaceGpsDataFormatStr, ...
         surfaceGpsDataStr, ...
         iridiumPositionsFormatStr, ...
         iridiumPositionsStr, ...
         iridiumDataFormatStr, ...
         iridiumDataStr, ...
         startupMessageStr, ...
         secondOrderInformationStr ...
         ] = read_nemo_profile_file(profilePathFileName);
      if (error == 1)
         fprintf('ERROR: Error in file: %s - ignored\n', profilePathFileName);
         continue
      end
      
      % parse information and parameter measurements
      floatIdentification = parse_nemo_info(floatIdentificationStr);
      overallMissionInformation = parse_nemo_info(overallMissionInformationStr);
      deploymentInfo = parse_nemo_info(deploymentInfoStr);
      profileTechnicalData = parse_nemo_info(profileTechnicalDataStr);
      bottomValuesDuringDrift = parse_nemo_info(bottomValuesDuringDriftStr);
      rafosValues = parse_nemo_data(rafosValuesFormatStr, rafosValuesStr, ...
         [{'rtcJulD'} {2:7}], 'RAFOS_VALUES_FORMAT');

      profileHeader = parse_nemo_info(profileHeaderStr);
      qualityControlHeader = parse_nemo_info(qualityControlHeaderStr);
      
      profileData = parse_nemo_data(profileDataHeaderStr, profileDataStr, [], 'PROFILE_DATA_HEADER');
      surfaceGpsData = parse_nemo_data(surfaceGpsDataFormatStr, surfaceGpsDataStr, ...
         [{'rtcJulD'} {2:7}; {'GPSJulD'} {8:13}], 'SURFACE_GPS_DATA_FORMAT');
      
      iridiumPositions = parse_nemo_data(iridiumPositionsFormatStr, iridiumPositionsStr, ...
         [{'julD'} {4:9}], 'IRIDIUM_POSITIONS_FORMAT');

      iridiumData = parse_nemo_data(iridiumDataFormatStr, iridiumDataStr, ...
         [{'julD'} {4:9}], 'IRIDIUM_DATA_FORMAT');
      
      startupMessage = parse_nemo_info(startupMessageStr);
      secondOrderInformation = parse_nemo_info(secondOrderInformationStr);
      
      % print .profile contents in CSV file
      print_info_in_csv(floatIdentification, 'FLOAT_IDENTIFICATION', fidOut);
      print_info_in_csv(overallMissionInformation, 'OVERALL_MISSION_INFORMATION', fidOut);
      print_info_in_csv(deploymentInfo, 'DEPLOYMENT_INFO', fidOut);
      print_info_in_csv(profileTechnicalData, 'PROFILE_TECHNICAL_DATA', fidOut);
      print_info_in_csv(bottomValuesDuringDrift, 'BOTTOM_VALUES_DURING_DRIFT', fidOut);
      print_data_in_csv(rafosValues, 'RAFOS_VALUES', fidOut);
      print_info_in_csv(profileHeader, 'PROFILE_HEADER', fidOut);
      print_info_in_csv(qualityControlHeader, 'QUALITY_CONTROL_HEADER', fidOut);
      print_data_in_csv(profileData, 'PROFILE_DATA', fidOut);
      print_data_in_csv(surfaceGpsData, 'SURFACE_GPS_DATA', fidOut);
      print_data_in_csv(iridiumPositions, 'IRIDIUM_POSITIONS', fidOut);
      print_data_in_csv(iridiumData, 'IRIDIUM_DATA', fidOut);
      print_info_in_csv(startupMessage, 'STARTUP_MESSAGE', fidOut);
      print_info_in_csv(secondOrderInformation, 'SECOND_ORDER_INFORMATION', fidOut);
   end
   fclose(fidOut);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Print NEMO (ASCII) information in a CSV file.
%
% SYNTAX :
%  print_info_in_csv(a_infoStruct, a_itemLabel, a_fid)
%
% INPUT PARAMETERS :
%   a_infoStruct : NEMO (ASCII) information
%   a_itemLabel  : item name associated to information
%   a_fid        : CSV file Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_info_in_csv(a_infoStruct, a_itemLabel, a_fid)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(a_infoStruct))
   fieldNames = fieldnames(a_infoStruct);
   for idF = 1:length(fieldNames)
      fprintf(a_fid, '%d; %d; %s; %s; %s\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         a_itemLabel, fieldNames{idF}, a_infoStruct.(fieldNames{idF}));
   end
end

return

% ------------------------------------------------------------------------------
% Print NEMO data values in a CSV file.
%
% SYNTAX :
%  print_data_in_csv(a_dataStruct, a_itemLabel, a_fid)
%
% INPUT PARAMETERS :
%   a_dataStruct : NEMO data values
%   a_itemLabel  : item name associated to data values
%   a_fid        : CSV file Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function print_data_in_csv(a_dataStruct, a_itemLabel, a_fid)
      
% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;


if (~isempty(a_dataStruct))
   
   paramNameList = a_dataStruct.paramName;
   paramValue = a_dataStruct.paramValue;
   
   fprintf(a_fid, '%d; %d; %s', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, a_itemLabel);
   for idP = 1:length(paramNameList)
      fprintf(a_fid, '; %s', paramNameList{idP});
   end
   fprintf(a_fid, '\n');
   
   for idL = 1:size(paramValue, 1)
      fprintf(a_fid, '%d; %d; %s', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, a_itemLabel);
      for idP = 1:length(paramNameList)
         if (any(strfind(lower(paramNameList{idP}), 'juld')))
            if (isnan(paramValue(idL, idP)))
               paramValue(idL, idP) = g_decArgo_dateDef;
            end
            fprintf(a_fid, '; %s', julian_2_gregorian_dec_argo(paramValue(idL, idP)));
         else
            fprintf(a_fid, '; %g', paramValue(idL, idP));
         end
      end
      fprintf(a_fid, '\n');
   end
end

return
