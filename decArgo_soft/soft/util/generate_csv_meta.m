% ------------------------------------------------------------------------------
% Generate meta data for Argos and Iridium floats (SENSOR, PARAMETER and
% CALIBRATION information).
%
% SYNTAX :
%  generate_csv_meta or generate_csv_meta(varargin)
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
%   03/12/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_csv_meta(varargin)

% meta-data file exported from Coriolis data base
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150217.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\ArvorARN\meta_provor_4.52_20150416.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_JPR_2DO_20150630.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_JPR_ArvorDeep_v2_20150707.txt';

% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\new_iridium_meta.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\new_iridium_meta_updated.txt';
% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\export_meta_APEX_from_VB_20150703.txt';

% dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\ASFAR\DBexport_ASFAR_fromVB20151029.txt';

dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_DOXY_from_VB_20160518.txt';
dataBaseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_4-54_20160701.txt';

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

logFile = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = ['PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

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

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % find decoder Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d => nothing done for this float\n', floatNum);
      continue;
   end
   floatDecId = listDecId(idF);
   
   % retrieve float version
   [floatVersion] = get_float_version(floatNum, metaWmoList, metaData);
   
   [platformFamily] = get_platform_family_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;2081;1;%s;PLATFORM_FAMILY;%s\n', floatNum, platformFamily, floatVersion);
   
   [platformType] = get_platform_type_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;2209;1;%s;PLATFORM_TYPE;%s\n', floatNum, platformType, floatVersion);
   
   [wmoInstType] = get_wmo_inst_type_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;13;1;%s;PR_PROBE_CODE;%s\n', floatNum, wmoInstType, floatVersion);
   
   % get the list of sensors for this float
   [sensorList] = get_sensor_list(floatDecId);
   if (isempty(sensorList))
      continue;
   end
   
   % sensor information
   for idSensor = 1:length(sensorList)
      [sensorName, sensorDimLevel, sensorMaker, sensorModel, sensorSn] = ...
         get_sensor_info(sensorList{idSensor}, floatNum, metaWmoList, metaData);
      for idS = 1:length(sensorName)
         fprintf(fidOut, '%d;408;%d;%s;SENSOR;%s\n', floatNum, sensorDimLevel(idS), sensorName{idS}, floatVersion);
         fprintf(fidOut, '%d;409;%d;%s;SENSOR_MAKER;%s\n', floatNum, sensorDimLevel(idS), sensorMaker{idS}, floatVersion);
         fprintf(fidOut, '%d;410;%d;%s;SENSOR_MODEL;%s\n', floatNum, sensorDimLevel(idS), sensorModel{idS}, floatVersion);
         fprintf(fidOut, '%d;411;%d;%s;SENSOR_SERIAL_NO;%s\n', floatNum, sensorDimLevel(idS), sensorSn{idS}, floatVersion);
      end
   end
   
   % parameter information
   for idSensor = 1:length(sensorList)
      [paramName, paramDimLevel, paramSensor, paramUnits, paramAccuracy, paramResolution, ...
         calibEquation, calibCoef, calibComment] = ...
         get_parameter_info(sensorList{idSensor}, floatNum, floatDecId, metaWmoList, metaData);
      for idP = 1:length(paramName)
         fprintf(fidOut, '%d;415;%d;%s;PARAMETER;%s\n', floatNum, paramDimLevel(idP), paramName{idP}, floatVersion);
         fprintf(fidOut, '%d;2100;%d;%s;PARAMETER_SENSOR;%s\n', floatNum, paramDimLevel(idP), paramSensor{idP}, floatVersion);
         fprintf(fidOut, '%d;2206;%d;%s;PARAMETER_UNITS;%s\n', floatNum, paramDimLevel(idP), paramUnits{idP}, floatVersion);
         fprintf(fidOut, '%d;2207;%d;%s;PARAMETER_ACCURACY;%s\n', floatNum, paramDimLevel(idP), paramAccuracy{idP}, floatVersion);
         fprintf(fidOut, '%d;2208;%d;%s;PARAMETER_RESOLUTION;%s\n', floatNum, paramDimLevel(idP), paramResolution{idP}, floatVersion);

         %          fprintf(fidOut, '%d;416;%d;%s;PREDEPLOYMENT_CALIB_EQUATION;%s\n', floatNum, paramDimLevel(idP), calibEquation{idP}, floatVersion);
         %          fprintf(fidOut, '%d;417;%d;%s;PREDEPLOYMENT_CALIB_COEFFICIENT;%s\n', floatNum, paramDimLevel(idP), calibCoef{idP}, floatVersion);
         %          fprintf(fidOut, '%d;418;%d;%s;PREDEPLOYMENT_CALIB_COMMENT;%s\n', floatNum, paramDimLevel(idP), calibComment{idP}, floatVersion);
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
function [o_platformFamily] = get_platform_family_db(a_floatNum, a_decId, a_metaWmoList, a_metaData)
   
o_platformFamily = [];

global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatNum;


% retrieve default value
defaultPlatformFamily = get_platform_family(a_decId);

% retrieve data base value
idForWmo = find(a_metaWmoList == a_floatNum);

idF = find(strcmp(a_metaData(idForWmo, 5), 'PLATFORM_FAMILY'));
if (~isempty(idF))
   o_platformFamily = a_metaData{idForWmo(idF), 4};
end

if (~isempty(o_platformFamily))
   if (~strcmp(o_platformFamily, defaultPlatformFamily))
      fprintf('WARNING: Float #%d decid #%d: DB platform family (%s) differs from default value (%s) => set to default value\n', ...
         a_floatNum, a_decId, ...
         o_platformFamily, defaultPlatformFamily);
      o_platformFamily = defaultPlatformFamily;
   end
else
   o_platformFamily = defaultPlatformFamily;
   fprintf('INFO: Float #%d decid #%d: DB platform family is missing => set to default value (%s)\n', ...
      a_floatNum, a_decId, ...
      o_platformFamily);
end

return;

% ------------------------------------------------------------------------------
function [o_platformType] = get_platform_type_db(a_floatNum, a_decId, a_metaWmoList, a_metaData)
   
o_platformType = [];

global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatNum;


% retrieve default value
defaultPlatformType = get_platform_type(a_decId);

% retrieve data base value
idForWmo = find(a_metaWmoList == a_floatNum);

idF = find(strcmp(a_metaData(idForWmo, 5), 'PLATFORM_TYPE'));
if (~isempty(idF))
   o_platformType = a_metaData{idForWmo(idF), 4};
end

if (~isempty(o_platformType))
   if (~strcmp(o_platformType, defaultPlatformType))
      fprintf('WARNING: Float #%d decid #%d: DB platform type (%s) differs from default value (%s) => set to default value\n', ...
         a_floatNum, a_decId, ...
         o_platformType, defaultPlatformType);
      o_platformType = defaultPlatformType;
   end
else
   o_platformType = defaultPlatformType;
   fprintf('INFO: Float #%d decid #%d: DB platform type is missing => set to default value (%s)\n', ...
      a_floatNum, a_decId, ...
      o_platformType);
end

return;

% ------------------------------------------------------------------------------
function [o_wmoInstType] = get_wmo_inst_type_db(a_floatNum, a_decId, a_metaWmoList, a_metaData)
   
o_wmoInstType = [];

global g_decArgo_floatNum;
g_decArgo_floatNum = a_floatNum;


% retrieve default value
defaultWmoInstType = get_wmo_instrument_type(a_decId);

% retrieve data base value
idForWmo = find(a_metaWmoList == a_floatNum);

idF = find(strcmp(a_metaData(idForWmo, 5), 'PR_PROBE_CODE'));
if (~isempty(idF))
   o_wmoInstType = a_metaData{idForWmo(idF), 4};
end

if (~isempty(o_wmoInstType))
   if (~strcmp(o_wmoInstType, defaultWmoInstType))
      fprintf('WARNING: Float #%d decid #%d: DB WMO instrument type (%s) differs from default value (%s) => set to default value\n', ...
         a_floatNum, a_decId, ...
         o_wmoInstType, defaultWmoInstType);
      o_wmoInstType = defaultWmoInstType;
   end
else
   o_wmoInstType = defaultWmoInstType;
   fprintf('INFO: Float #%d decid #%d: DB WMO instrument type is missing => set to default value (%s)\n', ...
      a_floatNum, a_decId, ...
      o_wmoInstType);
end

return;

% ------------------------------------------------------------------------------
function [o_sensorList] = get_sensor_list(a_decId)

o_sensorList = [];

% get the list of sensors for this float
switch a_decId
   
   case {1, 3, 11, 12, 17, 24, 30, 31, 204, 205, 210, 211, 212}
      % CTD floats
      o_sensorList = [{'CTD'}];
      
   case {4, 19, 25, 27, 28, 29, 32, 201, 202, 203, 206, 207, 208}
      % CTDO floats
      o_sensorList = [{'CTD'}; {'OPTODE'}];
      
   case {209}
      % CTDO float with 2 DO sensors
      o_sensorList = [{'CTD'}; {'OPTODE'}; {'OPTODE2'}];
      
   otherwise
      fprintf('ERROR: Unknown sensor list for decId #%d => nothing done for this float\n', a_decId);
end

return;

% ------------------------------------------------------------------------------
function [o_sensorName, o_sensorDimLevel, o_sensorMaker, o_sensorModel, o_sensorSn] = ...
   get_sensor_info(a_inputSensorName, a_floatNum, a_metaWmoList, a_metaData)

o_sensorName = [];
o_sensorDimLevel = [];
o_sensorMaker = [];
o_sensorModel = [];
o_sensorSn = [];

switch a_inputSensorName
   case  'CTD'
      o_sensorName = [ ...
         {'CTD_PRES'} ...
         {'CTD_TEMP'} ...
         {'CTD_CNDC'} ...
         ];
      o_sensorDimLevel = [1 2 3];
      ifEmptySensorMakerList = [ ...
         {'SBE'} ...
         {'SBE'} ...
         {'SBE'} ...
         ];
      ifEmptySensorModelList = [ ...
         {'SBE41CP'} ...
         {'SBE41CP'} ...
         {'SBE41CP'} ...
         ];
      
   case 'OPTODE'
      o_sensorName = [ ...
         {'OPTODE_DOXY'} ...
         ];
      o_sensorDimLevel = [101];
      ifEmptySensorMakerList = [ ...
         {'AANDERAA'} ...
         ];
      ifEmptySensorModelList = [ ...
         {'AANDERAA_OPTODE_4330'} ...
         ];
      
   case 'OPTODE2'
      o_sensorName = [ ...
         {'OPTODE_DOXY'} ...
         ];
      o_sensorDimLevel = [102];
      ifEmptySensorMakerList = [ ...
         {'SBE'} ...
         ];
      ifEmptySensorModelList = [ ...
         {'SBE63_OPTODE'} ...
         ];

   otherwise
      fprintf('ERROR: No sensor name for %s\n', a_inputName);
end

[o_sensorMaker, o_sensorModel, o_sensorSn] = ...
   get_sensor_data(o_sensorName, ifEmptySensorMakerList, ifEmptySensorModelList, a_floatNum, a_metaWmoList, a_metaData);

return;

% ------------------------------------------------------------------------------
function [o_sensorMaker, o_sensorModel, o_sensorSn] = ...
   get_sensor_data(o_sensorName, ifEmptySensorMakerList, ifEmptySensorModelList, a_floatNum, a_metaWmoList, a_metaData)

o_sensorMaker = [];
o_sensorModel = [];
o_sensorSn = [];

idForWmo = find(a_metaWmoList == a_floatNum);

for idC = 1:length(o_sensorName)
   
   idF1 = find(strcmp(a_metaData(idForWmo, 5), 'SENSOR') & ...
      strcmp(a_metaData(idForWmo, 4), o_sensorName{idC}));
   if (~isempty(idF1))
      dimLev = a_metaData(idForWmo(idF1), 3);
      
      % sensor maker
      idF2 = find(strcmp(a_metaData(idForWmo, 5), 'SENSOR_MAKER') & ...
         strcmp(a_metaData(idForWmo, 3), dimLev));
      if (~isempty(idF2))
         o_sensorMaker{end+1} = a_metaData{idForWmo(idF2), 4};
      else
         o_sensorMaker{end+1} = ifEmptySensorMakerList{idC};
         
         fprintf('INFO: SENSOR_MAKER is missing for sensor ''%s'' of float #%d => value set to ''%s''\n', ...
            o_sensorName{idC}, a_floatNum, o_sensorMaker{end});
      end
   
      % sensor model
      idF2 = find(strcmp(a_metaData(idForWmo, 5), 'SENSOR_MODEL') & ...
         strcmp(a_metaData(idForWmo, 3), dimLev));
      if (~isempty(idF2))
         o_sensorModel{end+1} = a_metaData{idForWmo(idF2), 4};
      else
         o_sensorModel{end+1} = ifEmptySensorModelList{idC};
         
         fprintf('INFO: SENSOR_MODEL is missing for sensor ''%s'' of float #%d => value set to ''%s''\n', ...
            o_sensorName{idC}, a_floatNum, o_sensorModel{end});
      end
      
      % sensor serial number
      idF2 = find(strcmp(a_metaData(idForWmo, 5), 'SENSOR_SERIAL_NO') & ...
         strcmp(a_metaData(idForWmo, 3), dimLev));
      if (~isempty(idF2))
         o_sensorSn{end+1} = a_metaData{idForWmo(idF2), 4};
      else
         o_sensorSn{end+1} = 'n/a';
         
         fprintf('INFO: SENSOR_SERIAL_NO is missing for sensor ''%s'' of float #%d => value set to ''%s''\n', ...
            o_sensorName{idC}, a_floatNum, o_sensorSn{end});
      end
   else      
      o_sensorMaker{end+1} = ifEmptySensorMakerList{idC};
      o_sensorModel{end+1} = ifEmptySensorModelList{idC};
      o_sensorSn{end+1} = 'n/a';
      
      fprintf('INFO: SENSOR ''%s'' is missing for float #%d => sensor created with default values (''%s'', ''%s'', ''%s'')\n', ...
         o_sensorName{idC}, a_floatNum, ...
         o_sensorMaker{end}, o_sensorModel{end}, o_sensorSn{end});
   end
end

return;

% ------------------------------------------------------------------------------
function [o_paramName, o_paramDimLevel, o_paramSensor, ...
   o_paramUnits, o_paramAccuracy, o_paramResolution, ...
   o_predCalibEquation, o_predCalibCoefficient, o_predCalibComment] = ...
   get_parameter_info(a_inputSensorName, a_floatNum, a_decId, a_metaWmoList, a_metaData)

o_paramName = [];
o_paramDimLevel = [];
o_paramSensor = [];
o_paramUnits = [];
o_paramAccuracy = [];
o_paramResolution = [];
o_predCalibEquation = [];
o_predCalibCoefficient = [];
o_predCalibComment = [];

switch a_inputSensorName
   case  'CTD'
      o_paramName = [ ...
         {'PRES'} {'TEMP'} {'PSAL'} ...
         ];
      o_paramDimLevel = [1 2 3];
      o_paramSensor = [ ...
         {'CTD_PRES'} {'CTD_TEMP'} {'CTD_CNDC'} ...
         ];
      o_paramUnits = [ ...
         {'decibar'} {'degree_Celsius'} {'psu'} ...
         ];
      
   case 'OPTODE'
      
      switch a_decId
         
         case {4, 19, 25}
            
            o_paramName = [ ...
               {'MOLAR_DOXY'} {'DOXY'} {'PPOX_DOXY'} ...
               ];
            o_paramDimLevel = [105 104 109];
            o_paramSensor = [ ...
               {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} ...
               ];
            o_paramUnits = [ ...
               {'micromole/l'} {'micromole/kg'} {'millibar'} ...
               ];
            
         case {27, 28, 29, 32}
            
            o_paramName = [ ...
               {'TPHASE_DOXY'} {'DOXY'} {'PPOX_DOXY'} ...
               ];
            o_paramDimLevel = [106 104 109];
            o_paramSensor = [ ...
               {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} ...
               ];
            o_paramUnits = [ ...
               {'degree'} {'micromole/kg'} {'millibar'} ...
               ];
            
         case {201, 202, 203, 206, 207, 208}
            
            o_paramName = [ ...
               {'C1PHASE_DOXY'} {'C2PHASE_DOXY'} {'TEMP_DOXY'} {'DOXY'} {'PPOX_DOXY'} ...
               ];
            o_paramDimLevel = [101 102 103 104 109];
            o_paramSensor = [ ...
               {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} ...
               ];
            o_paramUnits = [ ...
               {'degree'} {'degree'} {'degree_Celsius'} {'micromole/kg'} {'millibar'} ...
               ];
            
         case {209}
            
            o_paramName = [ ...
               {'C1PHASE_DOXY'} {'C2PHASE_DOXY'} {'TEMP_DOXY'} {'DOXY'} {'PPOX_DOXY'} ...
               ];
            o_paramDimLevel = [101 102 103 104 109];
            o_paramSensor = [ ...
               {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} ...
               ];
            o_paramUnits = [ ...
               {'degree'} {'degree'} {'degree_Celsius'} {'micromole/kg'} {'millibar'} ...
               ];
            
         otherwise
            fprintf('ERROR: Unknown OPTODE sensor parameter list for decId #%d => nothing done for this float\n', a_decId);
      end

   case 'OPTODE2'
      
      switch a_decId
            
         case {209}
            
            o_paramName = [ ...
               {'PHASE_DELAY_DOXY'} {'TEMP_DOXY2'} {'DOXY2'} {'PPOX_DOXY2'} ...
               ];
            o_paramDimLevel = [101 102 103 110];
            o_paramSensor = [ ...
               {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} ...
               ];
            o_paramUnits = [ ...
               {'microsecond'} {'degree_Celsius'} {'micromole/kg'} {'millibar'} ...
               ];
            
         otherwise
            fprintf('ERROR: Unknown OPTODE sensor parameter list for decId #%d => nothing done for this float\n', a_decId);
      end
      
   otherwise
      fprintf('ERROR: No sensor parameters for sensor %s\n', a_inputName);
end

for idP = 1:length(o_paramName)
   [o_paramAccuracy{end+1}, ...
      o_paramResolution{end+1}, ...
      o_predCalibEquation{end+1}, ...
      o_predCalibCoefficient{end+1}, ...
      o_predCalibComment{end+1}] = get_parameter_data(o_paramName{idP}, a_floatNum, a_metaWmoList, a_metaData);
end
o_paramAccuracy = o_paramAccuracy';
o_paramResolution = o_paramResolution';
o_predCalibEquation = o_predCalibEquation';
o_predCalibCoefficient = o_predCalibCoefficient';
o_predCalibComment = o_predCalibComment';

return;

% ------------------------------------------------------------------------------
function [o_paramAccuracy, o_paramResolution, ...
   o_predCalibEquation, o_predCalibCoefficient, o_predCalibComment] = ...
   get_parameter_data(a_paramName, a_floatNum, a_metaWmoList, a_metaData)

o_paramAccuracy = [];
o_paramResolution = [];
o_predCalibEquation = [];
o_predCalibCoefficient = [];
o_predCalibComment = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF1 = find(strcmp(a_metaData(idForWmo, 4), a_paramName) & ...
   strcmp(a_metaData(idForWmo, 5), 'PARAMETER'));
if (~isempty(idF1))
   dimLevel = a_metaData(idForWmo(idF1), 3);
   
   idF2 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'PARAMETER_ACCURACY'));
   if (~isempty(idF2))
      o_paramAccuracy = a_metaData{idForWmo(idF2), 4};
   end
   if (isempty(o_paramAccuracy))
      if (strcmp(a_paramName, 'PRES'))
         o_paramAccuracy = '2.4';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing => set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'TEMP'))
         o_paramAccuracy = '0.002';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing => set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'PSAL'))
         o_paramAccuracy = '0.005';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing => set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'DOXY'))
         o_paramAccuracy = '10%';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing => set to ''%s''\n', a_paramName, o_paramAccuracy);
      end
   end
   
   idF3 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'PARAMETER_RESOLUTION'));
   if (~isempty(idF3))
      o_paramResolution = a_metaData{idForWmo(idF3), 4};
   end
   if (isempty(o_paramResolution))
      if (strcmp(a_paramName, 'PRES'))
         o_paramResolution = '1';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing => set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'TEMP'))
         o_paramResolution = '0.001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing => set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'PSAL'))
         o_paramResolution = '0.001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing => set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'DOXY'))
         o_paramResolution = '0.001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing => set to ''%s''\n', a_paramName, o_paramResolution);
      end
   end
   
   idF4 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'PREDEPLOYMENT_CALIB_EQUATION'));
   if (~isempty(idF4))
      o_predCalibEquation = regexprep(a_metaData{idForWmo(idF4), 4}, ';', ',');
   else
      o_predCalibEquation = 'n/a';
   end
   
   idF5 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'PREDEPLOYMENT_CALIB_COEFFICIENT'));
   if (~isempty(idF5))
      o_predCalibCoefficient = regexprep(a_metaData{idForWmo(idF5), 4}, ';', ',');
   else
      o_predCalibCoefficient = 'n/a';
   end
   
   idF6 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'PREDEPLOYMENT_CALIB_COMMENT'));
   if (~isempty(idF6))
      o_predCalibComment = regexprep(a_metaData{idForWmo(idF6), 4}, ';', ',');
   else
      o_predCalibComment = '';
   end
end

return;

