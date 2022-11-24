% ------------------------------------------------------------------------------
% Generate a CSV file with mandatory meta data that are not filled in the data
% base.
%
% SYNTAX :
%  generate_csv_meta_mandatory or generate_csv_meta_mandatory(varargin)
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
%   03/20/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_csv_meta_mandatory(varargin)

% meta-data file exported from Coriolis data base
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150217.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\Arvor-Cm-Bio\DBexport_arvorCM_fromVB20151030.txt';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

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

logFile = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta_mandatory' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta_mandatory' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['PLATFORM_CODE; TECH_PARAMETER_ID; DIM_LEVEL; CORIOLIS_TECH_METADATA.PARAMETER_VALUE; TECH_PARAMETER_CODE; ARGO META-DATA; Coriolis version'];
fprintf(fidOut, '%s\n', header);

% read meta file
fprintf('Processing file: %s\n', dataBaseFileName);
fId = fopen(dataBaseFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', dataBaseFileName);
   return;
end
metaFileContents = textscan(fId, '%s', 'delimiter', '\t');
metaFileContents = metaFileContents{:};
fclose(fId);

metaFileContents = regexprep(metaFileContents, '"', '');

metaData = reshape(metaFileContents, 5, size(metaFileContents, 1)/5)';

metaWmoList = metaData(:, 1);
% for id = 1:length(metaWmoList)
%    if (isempty(str2num(metaWmoList{id})))
%       fprintf('%s is not a valid WMO number\n', metaWmoList{id});
%       return;
%    end
% end
S = sprintf('%s*', metaWmoList{:});
metaWmoList = sscanf(S, '%f*');

mandatoryList = [ ...
   {'BATTERY_TYPE'} {'BATTERY_TYPE'} {1} {1248}; ...
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} {'CONTROLLER_BOARD_SERIAL_NO_PRIMA'} {1} {1252}; ...
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} {'CONTROLLER_BOARD_TYPE_PRIMARY'} {1} {1250}; ...
   {'DAC_FORMAT_ID'} {'PR_VERSION'} {1} {2}; ...
   {'DATA_CENTRE'} {'DATA_CENTRE'} {0} {376}; ...
   {'FIRMWARE_VERSION'} {'FIRMWARE_VERSION'} {1} {961}; ...
   {'FLOAT_SERIAL_NO'} {'INST_REFERENCE'} {1} {392}; ...
   {'LAUNCH_DATE'} {'PR_LAUNCH_DATETIME'} {0} {8}; ...
   {'LAUNCH_LATITUDE'} {'PR_LAUNCH_LATITUDE'} {0} {9}; ...
   {'LAUNCH_LONGITUDE'} {'PR_LAUNCH_LONGITUDE'} {0} {10}; ...
   {'LAUNCH_QC'} {'LAUNCH_QC'} {0} {396}; ...
   {'MANUAL_VERSION'} {'MANUAL_VERSION'} {1} {1244}; ...
   {'PI_NAME'} {'PI_NAME'} {1} {394}; ...
   {'PLATFORM_FAMILY'} {'PLATFORM_FAMILY'} {0} {2081}; ...
   {'PLATFORM_MAKER'} {'PLATFORM_MAKER'} {2} {391}; ...
   {'PLATFORM_TYPE'} {'PLATFORM_TYPE'} {0} {2209}; ...
   {'POSITIONING_SYSTEM'} {'POSITIONING_SYSTEM'} {0} {377}; ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} {'PREDEPLOYMENT_CALIB_COEFFICIENT'} {1} {417}; ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} {'PREDEPLOYMENT_CALIB_EQUATION'} {1} {416}; ...
   {'PTT'} {'PTT'} {1} {384}; ...
   {'SENSOR'} {'SENSOR'} {0} {408}; ...
   {'SENSOR_MAKER'} {'SENSOR_MAKER'} {2} {409}; ...
   {'SENSOR_MODEL'} {'SENSOR_MODEL'} {2} {410}; ...
   {'SENSOR_SERIAL_NO'} {'SENSOR_SERIAL_NO'} {1} {411}; ...
   {'PARAMETER'} {'PARAMETER'} {0} {415}; ...
   {'PARAMETER_UNITS'} {'PARAMETER_UNITS'} {0} {2206}; ...
   {'PARAMETER_SENSOR'} {'PARAMETER_SENSOR'} {0} {2100}; ...
   {'STANDARD_FORMAT_ID'} {'STANDARD_FORMAT_ID'} {1} {1246}; ...
   {'TRANS_FREQUENCY'} {'TRANS_FREQUENCY'} {1} {387}; ...
   {'TRANS_SYSTEM'} {'TRANS_SYSTEM'} {0} {385}; ...
   {'TRANS_SYSTEM_ID'} {'TRANS_SYSTEM_ID'} {1} {386}; ...
   {'WMO_INST_TYPE'} {'PR_PROBE_CODE'} {0} {13} ...
   ];

parameterDependantList = [ ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_SENSOR'} ...
   ];

sensorDependantList = [ ...
   {'SENSOR'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   ];

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
      
   % retrieve float version
   [floatVersion] = get_float_version(floatNum, metaWmoList, metaData);
   
   for idL = 1:size(mandatoryList, 1)
      [fieldValue, fieldDimLevel, fieldTechId] = get_field_value(mandatoryList{idL, 2}, floatNum, metaWmoList, metaData, mandatoryList{idL, 4});
      
      if (isempty(fieldValue))
         if (mandatoryList{idL, 3} == 1)
            fprintf(fidOut, '%d; %d; 1; MANDATORY (can be replaced by ''n/a''); %s; %s; %s\n', ...
               floatNum, fieldTechId, mandatoryList{idL, 2}, mandatoryList{idL, 1}, floatVersion);
         elseif (mandatoryList{idL, 3} == 2)
            fprintf(fidOut, '%d; %d; 1; MANDATORY (can be replaced by ''UNKNOWN''); %s; %s; %s\n', ...
               floatNum, fieldTechId, mandatoryList{idL, 2}, mandatoryList{idL, 1}, floatVersion);
         else
            fprintf(fidOut, '%d; %d; 1; MANDATORY; %s; %s; %s\n', ...
               floatNum, fieldTechId, mandatoryList{idL, 2}, mandatoryList{idL, 1}, floatVersion);
         end
      else
         for idV = 1:length(fieldValue)
            if (strcmp(strtrim(fieldValue{idV}), 'n/a'))
               
               if (~isempty(find(strcmp(mandatoryList{idL, 1}, parameterDependantList) == 1, 1)))
                  [fieldValue2, fieldDimLevel2, fieldTechId2] = get_field_value('PARAMETER', floatNum, metaWmoList, metaData, {415});
                  idF = find(fieldDimLevel2 == fieldDimLevel(idV));
                  fprintf(fidOut, '%d; %d; %d; %s; %s; %s; %s\n', ...
                     floatNum, fieldTechId2(idF), fieldDimLevel2(idF), fieldValue2{idF}, 'PARAMETER', 'PARAMETER', floatVersion);
               end
               
               if (~isempty(find(strcmp(mandatoryList{idL, 1}, sensorDependantList) == 1, 1)))
                  [fieldValue2, fieldDimLevel2, fieldTechId2] = get_field_value('SENSOR', floatNum, metaWmoList, metaData, {408});
                  idF = find(fieldDimLevel2 == fieldDimLevel(idV));
                  fprintf(fidOut, '%d; %d; %d; %s; %s; %s; %s\n', ...
                     floatNum, fieldTechId2(idF), fieldDimLevel2(idF), fieldValue2{idF}, 'SENSOR', 'SENSOR', floatVersion);
               end
               
               if (mandatoryList{idL, 3} == 1)
                  fprintf(fidOut, '%d; %d; %d; MANDATORY (can be replaced by ''n/a''); %s; %s; %s\n', ...
                     floatNum, fieldTechId(idV), fieldDimLevel(idV), mandatoryList{idL, 2}, mandatoryList{idL, 1}, floatVersion);
               elseif (mandatoryList{idL, 3} == 2)
                  fprintf(fidOut, '%d; %d; %d; MANDATORY (can be replaced by ''UNKNOWN''); %s; %s; %s\n', ...
                     floatNum, fieldTechId(idV), fieldDimLevel(idV), mandatoryList{idL, 2}, mandatoryList{idL, 1}, floatVersion);
               else
                  fprintf(fidOut, '%d; %d; %d; MANDATORY; %s; %s; %s\n', ...
                     floatNum, fieldTechId(idV), fieldDimLevel(idV), mandatoryList{idL, 2}, mandatoryList{idL, 1}, floatVersion);
               end
            end
         end
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

% ------------------------------------------------------------------------------
function [o_floatVersion] = get_float_version(a_floatNum, a_metaWmoList, a_metaData)

o_floatVersion = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF = find(strcmp(a_metaData(idForWmo, 5), 'PR_VERSION'));
if (~isempty(idF))
   o_floatVersion = a_metaData{idForWmo(idF), 4};
else
   fprintf('ERROR: Float version not found for float %d\n', ...
      a_floatNum);
end

return;

% ------------------------------------------------------------------------------
function [o_fieldValue, o_fieldDimLevel, o_fieldTechId] = ...
   get_field_value(a_fieldName, a_floatNum, a_metaWmoList, a_metaData, a_fieldTechId)
   
o_fieldValue = [];
o_fieldDimLevel = [];
o_fieldTechId = [];


% retrieve TECH Id
fieldTechId = -1;
idF = find(strcmp(a_metaData(:, 5), a_fieldName));
if (~isempty(idF))
   fieldTechId = str2num(a_metaData{idF(1), 2});
else
   fieldTechId = a_fieldTechId;
end

% retrieve data base value
idForWmo = find(a_metaWmoList == a_floatNum);

idF = find(strcmp(a_metaData(idForWmo, 5), a_fieldName));
if (~isempty(idF))
   for id = 1:length(idF)
      o_fieldValue{end+1} = a_metaData{idForWmo(idF(id)), 4};
      o_fieldDimLevel(end+1) = str2num(a_metaData{idForWmo(idF(id)), 3});
      o_fieldTechId(end+1) = fieldTechId;
   end
end

if (isempty(o_fieldTechId))
   o_fieldTechId = fieldTechId;
end

return;
