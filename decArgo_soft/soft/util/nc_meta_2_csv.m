% ------------------------------------------------------------------------------
% Convert NetCDF meta-data file contents in CSV format.
%
% SYNTAX :
%   nc_meta_2_csv or nc_meta_2_csv(6900189, 7900118)
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
%   06/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_meta_2_csv(varargin)

% top directory of the NetCDF files to convert
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_rnuokRem&PrvIr\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_update_format_conf\coriolis\';

% default list of floats to convert
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_cm.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_arn_ir.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\arvor_4.54.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default values initialization
init_default_values;

% to compare different set of files do not print current dates
COMPARISON_MODE = 0;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
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

logFile = [DIR_LOG_FILE '/' 'nc_meta_2_csv' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
     
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   ncFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];

   if (exist(ncFileDir, 'dir') == 7)
      
      % convert meta file
      metaFileName = sprintf('%d_meta.nc', floatNum);
      metaFilePathName = [ncFileDir metaFileName];
      
      if (exist(metaFilePathName, 'file') == 2)
         
         outputFileName = [metaFileName(1:end-3) '.csv'];
         outputFilePathName = [ncFileDir outputFileName];
         nc_meta_2_csv_file(metaFilePathName, outputFilePathName, floatNum, COMPARISON_MODE);
      end
      
   else
      fprintf('WARNING: Directory not found: %s\n', ncFileDir);
   end
end
   
ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
% Convert one NetCDF meta-data file contents in CSV format.
%
% SYNTAX :
%  nc_meta_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
%    a_floatNum, a_comparisonFlag)
%
% INPUT PARAMETERS :
%   a_inputPathFileName  : input NetCDF file path name
%   a_outputPathFileName : output CSV file path name
%   a_floatNum           : float WMO number
%   a_comparisonFlag     : if 1, do not print current dates
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_meta_2_csv_file(a_inputPathFileName, a_outputPathFileName, ...
   a_floatNum, a_comparisonFlag)

% input and output file names
[inputPath, inputName, inputExt] = fileparts(a_inputPathFileName);
[outputPath, outputName, outputExt] = fileparts(a_outputPathFileName);
inputFileName = [inputName inputExt];
ourputFileName = [outputName outputExt];
fprintf('Converting: %s to %s\n', inputFileName, ourputFileName);

% retrieve information from meta file
wantedMetaVars = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'PLATFORM_NUMBER'} ...
   {'PTT'} ...
   {'TRANS_SYSTEM'} ...
   {'TRANS_SYSTEM_ID'} ...
   {'TRANS_FREQUENCY'} ...
   {'POSITIONING_SYSTEM'} ...
   {'PLATFORM_FAMILY'} ...
   {'PLATFORM_TYPE'} ...
   {'PLATFORM_MAKER'} ...
   {'FIRMWARE_VERSION'} ...
   {'MANUAL_VERSION'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'STANDARD_FORMAT_ID'} ...
   {'DAC_FORMAT_ID'} ...
   {'WMO_INST_TYPE'} ...
   {'PROJECT_NAME'} ...
   {'DATA_CENTRE'} ...
   {'PI_NAME'} ...
   {'ANOMALY'} ...
   {'BATTERY_TYPE'} ...
   {'BATTERY_PACKS'} ...
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} ...
   {'CONTROLLER_BOARD_TYPE_SECONDARY'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_SECONDARY'} ...
   {'SPECIAL_FEATURES'} ...
   {'FLOAT_OWNER'} ...
   {'OPERATING_INSTITUTION'} ...
   {'CUSTOMISATION'} ...
   {'LAUNCH_DATE'} ...
   {'LAUNCH_LATITUDE'} ...
   {'LAUNCH_LONGITUDE'} ...
   {'LAUNCH_QC'} ...
   {'START_DATE'} ...
   {'START_DATE_QC'} ...
   {'STARTUP_DATE'} ...
   {'STARTUP_DATE_QC'} ...
   {'DEPLOYMENT_PLATFORM'} ...
   {'DEPLOYMENT_CRUISE_ID'} ...
   {'DEPLOYMENT_REFERENCE_STATION_ID'} ...
   {'END_MISSION_DATE'} ...
   {'END_MISSION_STATUS'} ...
   {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
   {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_PARAMETER_NAME'} ...
   {'CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'CONFIG_MISSION_COMMENT'} ...
   {'SENSOR'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_ACCURACY'} ...
   {'PARAMETER_RESOLUTION'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_COMMENT'} ...
   ];
if (a_comparisonFlag == 0)
   wantedMetaVars = [ ...
      wantedMetaVars ...
      {'DATE_CREATION'} ...
      {'DATE_UPDATE'} ...
      ];
end

% retrieve information from PROF netCDF file
[metaData] = get_data_from_nc_file(a_inputPathFileName, wantedMetaVars);

% create CSV file
fidOut = fopen(a_outputPathFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create output file: %s\n', a_outputPathFileName);
   return;
end

fprintf(fidOut, ' WMO; DIMENSIONS; ------------------------------\n');

idVal = find(strcmp('PARAMETER', metaData) == 1);
if (~isempty(idVal))
   val = metaData{idVal+1}';
   fprintf(fidOut, ' %d; N_PARAM; %d\n', a_floatNum, size(val, 1));
else
   fprintf(fidOut, ' %d; N_PARAM\n', a_floatNum);
end

idVal = find(strcmp('SENSOR', metaData) == 1);
if (~isempty(idVal))
   val = metaData{idVal+1}';
   fprintf(fidOut, ' %d; N_SENSOR; %d\n', a_floatNum, size(val, 1));
else
   fprintf(fidOut, ' %d; N_SENSOR\n', a_floatNum);
end

idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData) == 1);
if (~isempty(idVal))
   val = metaData{idVal+1}';
   fprintf(fidOut, ' %d; N_CONFIG_PARAM; %d\n', a_floatNum, size(val, 1));
else
   fprintf(fidOut, ' %d; N_CONFIG_PARAM\n', a_floatNum);
end

idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData) == 1);
if (~isempty(idVal))
   val = metaData{idVal+1}';
   fprintf(fidOut, ' %d; N_LAUNCH_CONFIG_PARAM; %d\n', a_floatNum, size(val, 1));
else
   fprintf(fidOut, ' %d; N_LAUNCH_CONFIG_PARAM\n', a_floatNum);
end

idVal = find(strcmp('CONFIG_MISSION_NUMBER', metaData) == 1);
if (~isempty(idVal))
   val = metaData{idVal+1}';
   fprintf(fidOut, ' %d; N_MISSIONS; %d\n', a_floatNum, length(val));
else
   fprintf(fidOut, ' %d; N_MISSIONS\n', a_floatNum);
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; GENERAL INFORMATION; ------------------------------\n');

metaVars = [ ...
   {'DATA_TYPE'} ...
   {'FORMAT_VERSION'} ...
   {'HANDBOOK_VERSION'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   ];

for idL = 1:length(metaVars)
   
   name = metaVars{idL};
   val = '';
   idVal = find(strcmp(name, metaData) == 1);
   if (~isempty(idVal))
      val = metaData{idVal+1}';
   end
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, name, strtrim(val));
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; FLOAT CHARACTERISTICS; ------------------------------\n');

metaVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'PTT'} ...
   {'TRANS_SYSTEM'} ...
   {'TRANS_SYSTEM_ID'} ...
   {'TRANS_FREQUENCY'} ...
   {'POSITIONING_SYSTEM'} ...
   {'PLATFORM_FAMILY'} ...
   {'PLATFORM_TYPE'} ...
   {'PLATFORM_MAKER'} ...
   {'FIRMWARE_VERSION'} ...
   {'MANUAL_VERSION'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'STANDARD_FORMAT_ID'} ...
   {'DAC_FORMAT_ID'} ...
   {'WMO_INST_TYPE'} ...
   {'PROJECT_NAME'} ...
   {'DATA_CENTRE'} ...
   {'PI_NAME'} ...
   {'ANOMALY'} ...
   {'BATTERY_TYPE'} ...
   {'BATTERY_PACKS'} ...
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} ...
   {'CONTROLLER_BOARD_TYPE_SECONDARY'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_SECONDARY'} ...
   {'SPECIAL_FEATURES'} ...
   {'FLOAT_OWNER'} ...
   {'OPERATING_INSTITUTION'} ...
   {'CUSTOMISATION'} ...
   ];

for idL = 1:length(metaVars)
   
   name = metaVars{idL};
   val = '';
   idVal = find(strcmp(name, metaData) == 1);
   if (~isempty(idVal))
      val = metaData{idVal+1}';
   end
   valStr = sprintf('%s', strtrim(val(1, :)));
   for id = 2:size(val, 1)
      valStr = [valStr sprintf('; %s', strtrim(val(id, :)))];
   end
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, name, valStr);
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; FLOAT DEPLOYMENT AND MISSION INFORMATION; ------------------------------\n');

metaVars = [ ...
   {'LAUNCH_DATE'} ...
   {'LAUNCH_LATITUDE'} ...
   {'LAUNCH_LONGITUDE'} ...
   {'LAUNCH_QC'} ...
   {'START_DATE'} ...
   {'START_DATE_QC'} ...
   {'STARTUP_DATE'} ...
   {'STARTUP_DATE_QC'} ...
   {'DEPLOYMENT_PLATFORM'} ...
   {'DEPLOYMENT_CRUISE_ID'} ...
   {'DEPLOYMENT_REFERENCE_STATION_ID'} ...
   {'END_MISSION_DATE'} ...
   {'END_MISSION_STATUS'} ...
   ];

for idL = 1:length(metaVars)
   
   name = metaVars{idL};
   val = '';
   idVal = find(strcmp(name, metaData) == 1);
   if (~isempty(idVal))
      val = metaData{idVal+1}';
      if (isnumeric(val))
         val = num2str(val);
      end
   end
   fprintf(fidOut, ' %d; %s; %s\n', a_floatNum, name, strtrim(val));
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; CONFIGURATION PARAMETERS; ------------------------------\n');

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; LAUNCH CONFIGURATION; ------------------------------\n');

launchConfigParamName = '';
idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData) == 1);
if (~isempty(idVal))
   launchConfigParamName = metaData{idVal+1}';
end

launchConfigParamValue = '';
idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', metaData) == 1);
if (~isempty(idVal))
   launchConfigParamValue = metaData{idVal+1};
end

for idConfParam = 1:length(launchConfigParamValue)
   fprintf(fidOut, ' %d; %s; %g\n', a_floatNum, strtrim(launchConfigParamName(idConfParam, :)), launchConfigParamValue(idConfParam));
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; MISSION CONFIGURATIONS; ------------------------------\n');

configMissionNumber = '';
idVal = find(strcmp('CONFIG_MISSION_NUMBER', metaData) == 1);
if (~isempty(idVal))
   configMissionNumber = metaData{idVal+1};
end

configMissionComment = '';
idVal = find(strcmp('CONFIG_MISSION_COMMENT', metaData) == 1);
if (~isempty(idVal))
   configMissionComment = metaData{idVal+1}';
end

configParamName = '';
idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData) == 1);
if (~isempty(idVal))
   configParamName = metaData{idVal+1}';
end

configParamValue = '';
idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData) == 1);
if (~isempty(idVal))
   configParamValue = metaData{idVal+1};
end

fprintf(fidOut, ' %d; %s', a_floatNum, 'CONFIG_MISSION_NUMBER');
fprintf(fidOut, '; %d', configMissionNumber);
fprintf(fidOut, '\n');

fprintf(fidOut, ' %d; %s', a_floatNum, 'CONFIG_MISSION_COMMENT');
for idMis = 1:length(configMissionNumber)
   fprintf(fidOut, '; %s', strtrim(configMissionComment(idMis, :)));
end
fprintf(fidOut, '\n');

for idConfParam = 1:size(configParamValue, 1)
   fprintf(fidOut, ' %d; %s', a_floatNum, strtrim(configParamName(idConfParam, :)));
   fprintf(fidOut, '; %d', configParamValue(idConfParam, :));
   fprintf(fidOut, '\n');
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; FLOAT SENSOR INFORMATION; ------------------------------\n');

metaVars = [ ...
   {'SENSOR'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   ];

for idL = 1:length(metaVars)
   
   fprintf(fidOut, ' %d; %s', a_floatNum, metaVars{idL});
   idVal = find(strcmp(metaVars{idL}, metaData) == 1);
   if (~isempty(idVal))
      val = metaData{idVal+1}';
      for idSensor = 1:size(val, 1)
         fprintf(fidOut, '; %s', strtrim(val(idSensor, :)));
      end
   end
   fprintf(fidOut, '\n');
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; FLOAT PARAMETER INFORMATION; ------------------------------\n');

metaVars = [ ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_ACCURACY'} ...
   {'PARAMETER_RESOLUTION'} ...
   ];

for idL = 1:length(metaVars)
   
   fprintf(fidOut, ' %d; %s', a_floatNum, metaVars{idL});
   idVal = find(strcmp(metaVars{idL}, metaData) == 1);
   if (~isempty(idVal))
      val = metaData{idVal+1}';
      for idParam = 1:size(val, 1)
         fprintf(fidOut, '; %s', strtrim(val(idParam, :)));
      end
   end
   fprintf(fidOut, '\n');
end

fprintf(fidOut, ' %d\n', a_floatNum);
fprintf(fidOut, ' WMO; FLOAT CALIBRATION INFORMATION; ------------------------------\n');

metaVars = [ ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_COMMENT'} ...
   ];

for idL = 1:length(metaVars)
   
   fprintf(fidOut, ' %d; %s', a_floatNum, metaVars{idL});
   idVal = find(strcmp(metaVars{idL}, metaData) == 1);
   if (~isempty(idVal))
      val = metaData{idVal+1}';
      for idParam = 1:size(val, 1)
         fprintf(fidOut, ';"%s"', strtrim(val(idParam, :)));
      end
   end
   fprintf(fidOut, '\n');
end

fclose(fidOut);

return;
