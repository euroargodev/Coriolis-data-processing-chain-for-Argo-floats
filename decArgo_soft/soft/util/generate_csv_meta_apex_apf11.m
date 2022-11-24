% ------------------------------------------------------------------------------
% Generate meta data for APEX APF11 Iridium floats.
%
% SYNTAX :
%  generate_csv_meta_apex_apf11 or generate_csv_meta_apex_apf11(varargin)
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
%   07/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function generate_csv_meta_apex_apf11(varargin)

% meta-data file exported from Coriolis data base
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\Apex_APF11_Norway_DB_export.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\APF11_2.11.3.R_finlande.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\APF11_2.11.3.R_7900562.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\APF11_DBexport_7900559_7900560.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_ApexRudics_Norway_APF11_2.13.1.R_from_vb_20200528.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_2.15.0.R_6903552.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_6903567_test.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_2.15.0.R_7900973_RAFOS.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_2.14.3.R_7900563_RAMSES.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_2.14.3.R_7900563_RAMSES.txt';
FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\_configParamNames\DB_Export\DB_export_APF11_2.15.2.R_7900586_7900587.txt';

% list of sensors mounted on floats
SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_info\_float_sensor_list\float_sensor_list.txt';

% calibration coefficient file
CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecApx_info\APEX_APF11\_CalibCoef\calib_coef.txt';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

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

logFile = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta_apex_apf11' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta_apex_apf11' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE'];
fprintf(fidOut, '%s\n', header);

% get floats information
[listWmoNum, listDecId, listArgosId, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

% get sensor list
[wmoSensorList, nameSensorList] = get_sensor_list(SENSOR_LIST_FILE_NAME);

% read meta file
fprintf('Processing file: %s\n', FLOAT_META_FILE_NAME);
fId = fopen(FLOAT_META_FILE_NAME, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', FLOAT_META_FILE_NAME);
   return
end
metaFileContents = textscan(fId, '%s', 'delimiter', '\t');
metaFileContents = metaFileContents{:};
fclose(fId);

metaFileContents = regexprep(metaFileContents, '"', '');

metaData = reshape(metaFileContents, 5, size(metaFileContents, 1)/5)';

metaWmoList = metaData(:, 1);
S = sprintf('%s*', metaWmoList{:});
metaWmoList = sscanf(S, '%f*');

% read calib file
fId = fopen(CALIB_FILE_NAME, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', CALIB_FILE_NAME);
   return
end
calibData = textscan(fId, '%s');
calibData = calibData{:};
fclose(fId);

calibData = reshape(calibData, 4, size(calibData, 1)/4)';

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % get the list of sensors for this float
   idSensor = find(wmoSensorList == floatNum);
   if (isempty(idSensor))
      fprintf('ERROR: Unknown sensor list for float #%d - nothing done for this float (PLEASE UPDATE "%s" file)\n', ...
         floatNum, SENSOR_LIST_FILE_NAME);
      continue
   end
   sensorList = nameSensorList(idSensor);
   if (length(sensorList) ~= length(unique(sensorList)))
      fprintf('ERROR: Duplicated sensors for float #%d - nothing done for this float (PLEASE CHECK "%s" file)\n', ...
         floatNum, SENSOR_LIST_FILE_NAME);
      continue
   end
   
   % find decoder Id
   idF = find(listWmoNum == floatNum, 1);
   if (isempty(idF))
      fprintf('ERROR: No information on float #%d - nothing done for this float\n', floatNum);
      continue
   end
   floatDecId = listDecId(idF);
   
   [floatVersion] = get_float_version(floatNum, metaWmoList, metaData);
   
   [positioningSystem] = get_float_positioning_system(floatNum, metaWmoList, metaData);
   if ((length(positioningSystem) == 1) && (floatVersion(end) == 'S'))
      fprintf(fidOut, '%d;377;1;%s;POSITIONING_SYSTEM;%s\n', floatNum, 'GPS', floatVersion);
      fprintf(fidOut, '%d;377;2;%s;POSITIONING_SYSTEM;%s\n', floatNum, 'IRIDIUM', floatVersion);
   end

   [platformFamily] = get_platform_family_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;2081;1;%s;PLATFORM_FAMILY;%s\n', floatNum, platformFamily, floatVersion);
   
   [platformType] = get_platform_type_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;2209;1;%s;PLATFORM_TYPE;%s\n', floatNum, platformType, floatVersion);
   
   [wmoInstType] = get_wmo_inst_type_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;13;1;%s;PR_PROBE_CODE;%s\n', floatNum, wmoInstType, floatVersion);
   
   % sensor information
   calibCoefStruct = [];
   if (any(strcmp(sensorList, 'OCR')))
      idF = find(strcmp(calibData(:, 1), num2str(floatNum)));
      for id = 1:length(idF)
         fieldName1 = calibData{idF(id), 2};
         fieldName2 = calibData{idF(id), 3};
         calibCoefStruct.(fieldName1).(fieldName2) = calibData{idF(id), 4};
      end
   end
   
   for idSensor = 1:length(sensorList)
      [sensorName, sensorDimLevel, sensorMaker, sensorModel] = get_sensor_info(sensorList{idSensor}, floatDecId, floatNum, metaWmoList, metaData, calibCoefStruct);
      for idS = 1:length(sensorName)
         fprintf(fidOut, '%d;408;%d;%s;SENSOR;%s\n', floatNum, sensorDimLevel(idS), sensorName{idS}, floatVersion);
         fprintf(fidOut, '%d;409;%d;%s;SENSOR_MAKER;%s\n', floatNum, sensorDimLevel(idS), sensorMaker{idS}, floatVersion);
         fprintf(fidOut, '%d;410;%d;%s;SENSOR_MODEL;%s\n', floatNum, sensorDimLevel(idS), sensorModel{idS}, floatVersion);
         [sensorSn] = get_sensor_sn(sensorName{idS}, floatNum, metaWmoList, metaData);
         if (~isempty(sensorSn))
            fprintf(fidOut, '%d;411;%d;%s;SENSOR_SERIAL_NO;%s\n', floatNum, sensorDimLevel(idS), sensorSn, floatVersion);
         end
      end
   end
   
   % parameter information
   for idSensor = 1:length(sensorList)
      [paramName, paramDimLevel, paramSensor, paramUnits, paramAccuracy, paramResolution] = ...
         get_sensor_parameter_info(sensorList{idSensor}, floatNum, floatDecId, metaWmoList, metaData, calibCoefStruct);
      for idP = 1:length(paramName)
         fprintf(fidOut, '%d;415;%d;%s;PARAMETER;%s\n', floatNum, paramDimLevel(idP), paramName{idP}, floatVersion);
         fprintf(fidOut, '%d;2100;%d;%s;PARAMETER_SENSOR;%s\n', floatNum, paramDimLevel(idP), paramSensor{idP}, floatVersion);
         fprintf(fidOut, '%d;2206;%d;%s;PARAMETER_UNITS;%s\n', floatNum, paramDimLevel(idP), paramUnits{idP}, floatVersion);
         fprintf(fidOut, '%d;2207;%d;%s;PARAMETER_ACCURACY;%s\n', floatNum, paramDimLevel(idP), paramAccuracy{idP}, floatVersion);
         fprintf(fidOut, '%d;2208;%d;%s;PARAMETER_RESOLUTION;%s\n', floatNum, paramDimLevel(idP), paramResolution{idP}, floatVersion);
      end
   end
   
   % sensor misc information
   [techParId, techParDimLev, techParCode, techParValue] = ...
      get_sensor_misc_info(sensorList, floatNum, floatDecId, metaWmoList, metaData, calibCoefStruct);
   if (~isempty(techParId))
      for idT = 1:length(techParId)
         fprintf(fidOut, '%d;%s;%s;%s;%s;%s\n', ...
            floatNum, techParId{idT}, techParDimLev{idT}, techParValue{idT}, techParCode{idT}, floatVersion);
      end
   end
   
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
function [o_sensorName, o_sensorDimLevel, o_sensorMaker, o_sensorModel] = ...
   get_sensor_info(a_inputSensorName, a_decId, a_floatNum, a_metaWmoList, a_metaData, a_calibCoefStruct)

o_sensorName = [];
o_sensorDimLevel = [];
o_sensorMaker = [];
o_sensorModel = [];

switch a_inputSensorName
   case  'CTD'
      o_sensorName = [{'CTD_PRES'} {'CTD_TEMP'} {'CTD_CNDC'}];
      o_sensorDimLevel = [1 2 3];
      o_sensorMaker = [{'SBE'} {'SBE'} {'SBE'}];
      o_sensorModel = [{'SBE41CP'} {'SBE41CP'} {'SBE41CP'}];
      
   case 'OPTODE'
      o_sensorName = {'OPTODE_DOXY'};
      o_sensorDimLevel = [101];
      o_sensorMaker = {'AANDERAA'};
      [sensorModel] = get_sensor_model('OPTODE_DOXY', a_floatNum, a_metaWmoList, a_metaData);
      if (~isempty(sensorModel))
         o_sensorModel = {sensorModel};
      end
      
   case 'OCR'
      okFlag = 0;
      if (~isempty(a_calibCoefStruct))
         if (isfield(a_calibCoefStruct, 'OCR'))
            if (isfield(a_calibCoefStruct.OCR, 'A0Lambda380') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda380') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda380') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda412') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda412') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda412') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0PAR') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1PAR') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmPAR'))
               okFlag = 1;
            elseif (isfield(a_calibCoefStruct.OCR, 'A0Lambda443') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda443') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda443') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda555') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda555') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda555') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda670') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda670') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda670'))
               okFlag = 2;
            else
               okFlag = -1;
            end
         end
      end
      
      if (okFlag == 1)
         o_sensorName = [{'RADIOMETER_DOWN_IRR380'} {'RADIOMETER_DOWN_IRR412'} {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_PAR'}];
         o_sensorDimLevel = [201 202 203 204];
         o_sensorMaker = [{'SATLANTIC'} {'SATLANTIC'} {'SATLANTIC'} {'SATLANTIC'}];
         o_sensorModel = [{'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'}];
      elseif (okFlag == 2)
         o_sensorName = [{'RADIOMETER_DOWN_IRR443'} {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_DOWN_IRR555'} {'RADIOMETER_DOWN_IRR670'}];
         o_sensorDimLevel = [201 202 203 204];
         o_sensorMaker = [{'SATLANTIC'} {'SATLANTIC'} {'SATLANTIC'} {'SATLANTIC'}];
         o_sensorModel = [{'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'}];
      elseif (okFlag == -1)
         fprintf('ERROR: unexpected set of OCR calibration coefficients in get_sensor_info\n');
      else
         fprintf('ERROR: OCR calibration coefficients are needed to set associated parameters in get_sensor_info\n');
      end
      
   case 'ECO3'
      o_sensorName = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} {'FLUOROMETER_CDOM'}];
      o_sensorDimLevel = [301 302 303];
      o_sensorMaker = [{'WETLABS'} {'WETLABS'} {'WETLABS'}];
      o_sensorModel = [{'ECO_FLBBCD'} {'ECO_FLBBCD'} {'ECO_FLBBCD'}];

   case 'TRANSISTOR_PH'
      o_sensorName = {'TRANSISTOR_PH'};
      o_sensorDimLevel = [701];
      o_sensorMaker = {'SBE'};
      o_sensorModel = {'SEAFET'};
      
   case 'RAFOS'
      o_sensorName = {'AUX_ACOUSTIC_GEOLOCATION'};
      o_sensorDimLevel = [1001];
      o_sensorMaker = {'SEASCAN'};
      o_sensorModel = {'RAFOS'};

   case 'RAFOS_RTC'
      o_sensorName = {'AUX_RAFOS_CLOCK'};
      o_sensorDimLevel = [1101];
      o_sensorMaker = {'SEASCAN'};
      o_sensorModel = {'RAFOS_RTC'};
      
   case 'RAMSES'
      o_sensorName = {'AUX_RADIOMETER_DOWN_IRR'};
      o_sensorDimLevel = [1201];
      o_sensorMaker = {'TRIOS'};
      o_sensorModel = {'RAMSES_ACC'};
      
   otherwise
      fprintf('ERROR: No sensor name for %s\n', a_inputSensorName);
end

return

% ------------------------------------------------------------------------------
function [o_techParId, o_techParDimLev, o_techParCode, o_techParValue] = ...
   get_sensor_misc_info(a_sensorList, a_floatNum, a_decId, a_metaWmoList, a_metaData, a_calibCoefStruct)

o_techParId = [];
o_techParDimLev = [];
o_techParCode = [];
o_techParValue = [];

for idSensor = 1:length(a_sensorList)
   
   techParId = [];
   techParDimLev = [];
   techParCode = [];
   techParValue = [];
   
   switch a_sensorList{idSensor}
      case  'CTD'
         
      case 'OPTODE'
                  
      case 'OCR'
         okFlag = 0;
         if (~isempty(a_calibCoefStruct))
            if (isfield(a_calibCoefStruct, 'OCR'))
               if (isfield(a_calibCoefStruct.OCR, 'A0Lambda380') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda380') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda380') && ...
                     isfield(a_calibCoefStruct.OCR, 'A0Lambda412') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda412') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda412') && ...
                     isfield(a_calibCoefStruct.OCR, 'A0Lambda490') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda490') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda490') && ...
                     isfield(a_calibCoefStruct.OCR, 'A0PAR') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1PAR') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmPAR'))
                  okFlag = 1;
               elseif (isfield(a_calibCoefStruct.OCR, 'A0Lambda443') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda443') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda443') && ...
                     isfield(a_calibCoefStruct.OCR, 'A0Lambda490') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda490') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda490') && ...
                     isfield(a_calibCoefStruct.OCR, 'A0Lambda555') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda555') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda555') && ...
                     isfield(a_calibCoefStruct.OCR, 'A0Lambda670') && ...
                     isfield(a_calibCoefStruct.OCR, 'A1Lambda670') && ...
                     isfield(a_calibCoefStruct.OCR, 'LmLambda670'))
                  okFlag = 2;
               else
                  okFlag = -1;
               end
            end
         end
         
         if (okFlag == 1)
            codeList = [ ...
               {'OCR_DOWN_IRR_BANDWIDTH'}; ...
               {'OCR_DOWN_IRR_WAVELENGTH'} ...
               ];
            ifEmptyList = [ ...
               {[{'10'}; {'10'}; {'10'}]}; ...
               {[{'380'}; {'412'}; {'490'}]} ...
               ];
            techParIdList = [ ...
               {'2196'}; ...
               {'2197'} ...
               ];
            [techParId, techParDimLev, techParCode, techParValue] = ...
               get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         elseif (okFlag == 2)
            codeList = [ ...
               {'OCR_DOWN_IRR_BANDWIDTH'}; ...
               {'OCR_DOWN_IRR_WAVELENGTH'} ...
               ];
            ifEmptyList = [ ...
               {[{'10'}; {'10'}; {'10'}; {'10'}]}; ...
               {[{'443'}; {'490'}; {'555'}; {'670'}]} ...
               ];
            techParIdList = [ ...
               {'2196'}; ...
               {'2197'} ...
               ];
            [techParId, techParDimLev, techParCode, techParValue] = ...
               get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         elseif (okFlag == -1)
            fprintf('ERROR: unexpected set of OCR calibration coefficients in get_sensor_misc_info\n');
         else
            fprintf('ERROR: OCR calibration coefficients are needed to set associated parameters in get_sensor_misc_info\n');
         end
         
      case 'ECO3'
         codeList = [ ...
            {'ECO_BETA_ANGLE'}; ...
            {'ECO_BETA_BANDWIDTH'}; ...
            {'ECO_BETA_WAVELENGTH'}; ...
            {'ECO_CDOM_FLUO_EMIS_BANDWIDTH'}; ...
            {'ECO_CDOM_FLUO_EMIS_WAVELENGTH'}; ...
            {'ECO_CDOM_FLUO_EXCIT_BANDWIDTH'}; ...
            {'ECO_CDOM_FLUO_EXCIT_WAVELENGTH'}; ...
            {'ECO_CHLA_FLUO_EMIS_BANDWIDTH'}; ...
            {'ECO_CHLA_FLUO_EMIS_WAVELENGTH'}; ...
            {'ECO_CHLA_FLUO_EXCIT_BANDWIDTH'}; ...
            {'ECO_CHLA_FLUO_EXCIT_WAVELENGTH'} ...
            ];
         ifEmptyList = [ ...
            {'124'}; ...
            {''}; ...
            {'700'}; ...
            {''}; ...
            {'460'}; ...
            {''}; ...
            {'370'}; ...
            {''}; ...
            {'695'}; ...
            {''}; ...
            {'470'} ...
            ];
         techParIdList = [ ...
            {'2184'}; ...
            {''}; ...
            {'2186'}; ...
            {''}; ...
            {'2188'}; ...
            {''}; ...
            {'2190'}; ...
            {''}; ...
            {'2192'}; ...
            {''}; ...
            {'2194'} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
      case 'TRANSISTOR_PH'
         % nothing yet
         
      case 'RAFOS'
         % nothing yet
         
      case 'RAFOS_RTC'
         % nothing yet

      case 'RAMSES'
         % nothing yet

      otherwise
         fprintf('ERROR: No sensor misc information for %s\n', a_sensorList{idSensor});
   end
   
   if (~isempty(techParId))
      o_techParId = [o_techParId; techParId];
      o_techParDimLev = [o_techParDimLev; techParDimLev];
      o_techParCode = [o_techParCode; techParCode];
      o_techParValue = [o_techParValue; techParValue];
   end
end

return

% ------------------------------------------------------------------------------
function [o_techParId, o_techParDimLev, o_techParCode, o_techParValue] = ...
   get_data(a_codeList, a_ifEmptyList, a_techParIdList, a_floatNum, a_metaWmoList, a_metaData)

o_techParId = [];
o_techParDimLev = [];
o_techParCode = [];
o_techParValue = [];

idForWmo = find(a_metaWmoList == a_floatNum);

for idC = 1:length(a_codeList)
   
   idF1 = find(strcmp(a_metaData(idForWmo, 5), a_codeList{idC}));
   if (~isempty(idF1))
      o_techParId = [o_techParId; a_metaData(idForWmo(idF1), 2)];
      o_techParDimLev = [o_techParDimLev; a_metaData(idForWmo(idF1), 3)];
      o_techParCode = [o_techParCode; a_metaData(idForWmo(idF1), 5)];
      o_techParValue = [o_techParValue; a_metaData(idForWmo(idF1), 4)];
   elseif (~isempty(a_ifEmptyList{idC}))
      emptyList = a_ifEmptyList{idC};
      if (size(emptyList, 1) > 1)
         for id = 1:size(emptyList, 1)
            o_techParId = [o_techParId; a_techParIdList(idC)];
            o_techParDimLev = [o_techParDimLev; {num2str(id)}];
            o_techParCode = [o_techParCode; a_codeList(idC)];
            o_techParValue = [o_techParValue; emptyList(id)];
         end
      else
         o_techParId = [o_techParId; a_techParIdList(idC)];
         o_techParDimLev = [o_techParDimLev; {'1'}];
         o_techParCode = [o_techParCode; a_codeList(idC)];
         o_techParValue = [o_techParValue; a_ifEmptyList(idC)];
      end
      
      fprintf('INFO: Sensor info ''%s'' is missing for float #%d - value set to default\n', ...
         a_codeList{idC}, a_floatNum);
   end
end

return

% ------------------------------------------------------------------------------
function [o_sensorSn] = get_sensor_sn(a_sensorName, a_floatNum, a_metaWmoList, a_metaData)

o_sensorSn = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF1 = find(strcmp(a_metaData(idForWmo, 4), a_sensorName) & ...
   strcmp(a_metaData(idForWmo, 5), 'SENSOR'));
if (~isempty(idF1))
   dimLevel = a_metaData(idForWmo(idF1), 3);
   idF2 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'SENSOR_SERIAL_NO'));
   if (~isempty(idF2))
      o_sensorSn = a_metaData{idForWmo(idF2), 4};
   else
      fprintf('ERROR: Sensor serial number not found for sensor %s of float %d\n', ...
         a_sensorName, a_floatNum);
   end
else
   fprintf('ERROR: Sensor %s not found for float %d\n', ...
      a_sensorName, a_floatNum);
end

return

% ------------------------------------------------------------------------------
function [o_sensorModel] = get_sensor_model(a_sensorName, a_floatNum, a_metaWmoList, a_metaData)

o_sensorModel = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF1 = find(strcmp(a_metaData(idForWmo, 4), a_sensorName) & ...
   strcmp(a_metaData(idForWmo, 5), 'SENSOR'));
if (~isempty(idF1))
   dimLevel = a_metaData(idForWmo(idF1), 3);
   idF2 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'SENSOR_MODEL'));
   if (~isempty(idF2))
      o_sensorModel = strtrim(a_metaData{idForWmo(idF2), 4});
   else
      fprintf('ERROR: Sensor model not found for sensor %s of float %d\n', ...
         a_sensorName, a_floatNum);
   end
else
   fprintf('ERROR: Sensor %s not found for float %d\n', ...
      a_sensorName, a_floatNum);
end

return

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

return

% ------------------------------------------------------------------------------
function [o_positioningSystem] = get_float_positioning_system(a_floatNum, a_metaWmoList, a_metaData)

o_positioningSystem = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF = find(strcmp(a_metaData(idForWmo, 5), 'POSITIONING_SYSTEM'));
if (~isempty(idF))
   for id = 1:length(idF)
      o_positioningSystem{end+1} = a_metaData{idForWmo(idF(id)), 4};
   end
else
   fprintf('ERROR: Float positioning system not found for float %d\n', ...
      a_floatNum);
end

return

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
      fprintf('WARNING: Float #%d decid #%d: DB platform family (%s) differs from default value (%s) - set to default value\n', ...
         a_floatNum, a_decId, ...
         o_platformFamily, defaultPlatformFamily);
      o_platformFamily = defaultPlatformFamily;
   end
else
   o_platformFamily = defaultPlatformFamily;
   fprintf('INFO: Float #%d decid #%d: DB platform family is missing - set to default value (%s)\n', ...
      a_floatNum, a_decId, ...
      o_platformFamily);
end

return

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
      fprintf('WARNING: Float #%d decid #%d: DB platform type (%s) differs from default value (%s) - set to default value\n', ...
         a_floatNum, a_decId, ...
         o_platformType, defaultPlatformType);
      o_platformType = defaultPlatformType;
   end
else
   o_platformType = defaultPlatformType;
   fprintf('INFO: Float #%d decid #%d: DB platform type is missing - set to default value (%s)\n', ...
      a_floatNum, a_decId, ...
      o_platformType);
end

return

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
      fprintf('WARNING: Float #%d decid #%d: DB WMO instrument type (%s) differs from default value (%s) - set to default value\n', ...
         a_floatNum, a_decId, ...
         o_wmoInstType, defaultWmoInstType);
      o_wmoInstType = defaultWmoInstType;
   end
else
   o_wmoInstType = defaultWmoInstType;
   fprintf('INFO: Float #%d decid #%d: DB WMO instrument type is missing - set to default value (%s)\n', ...
      a_floatNum, a_decId, ...
      o_wmoInstType);
end

return

% ------------------------------------------------------------------------------
function [o_paramName, o_paramDimLevel, o_paramSensor, ...
   o_paramUnits, o_paramAccuracy, o_paramResolution] = ...
   get_sensor_parameter_info(a_inputSensorName, a_floatNum, a_decId, ...
   a_metaWmoList, a_metaData, a_calibCoefStruct)

o_paramName = [];
o_paramDimLevel = [];
o_paramSensor = [];
o_paramUnits = [];
o_paramAccuracy = [];
o_paramResolution = [];

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
      o_paramName = [ ...
         {'C1PHASE_DOXY'} {'C2PHASE_DOXY'} {'TEMP_DOXY'} {'PPOX_DOXY'} ...
         {'DOXY'} ...
         ];
      o_paramDimLevel = [101 102 103 109 104];
      o_paramSensor = [ ...
         {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'} {'OPTODE_DOXY'}...
         {'OPTODE_DOXY'} ...
         ];
      o_paramUnits = [ ...
         {'degree'} {'degree'} {'degree_Celsius'} {'millibar'} ...
         {'micromole/kg'} ...
         ];
      
   case 'OCR'
      okFlag = 0;
      if (~isempty(a_calibCoefStruct))
         if (isfield(a_calibCoefStruct, 'OCR'))
            if (isfield(a_calibCoefStruct.OCR, 'A0Lambda380') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda380') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda380') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda412') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda412') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda412') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0PAR') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1PAR') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmPAR'))
               okFlag = 1;
            elseif (isfield(a_calibCoefStruct.OCR, 'A0Lambda443') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda443') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda443') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda490') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda555') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda555') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda555') && ...
                  isfield(a_calibCoefStruct.OCR, 'A0Lambda670') && ...
                  isfield(a_calibCoefStruct.OCR, 'A1Lambda670') && ...
                  isfield(a_calibCoefStruct.OCR, 'LmLambda670'))
               okFlag = 2;
            else
               okFlag = -1;
            end
         end
      end
      
      if (okFlag == 1)
         o_paramName = [ ...
            {'DOWN_IRRADIANCE380'} {'DOWN_IRRADIANCE412'} ...
            {'DOWN_IRRADIANCE490'} {'DOWNWELLING_PAR'} ...
            ];
         o_paramDimLevel = [205 206 207 208];
         o_paramSensor = [ ...
            {'RADIOMETER_DOWN_IRR380'} {'RADIOMETER_DOWN_IRR412'} ...
            {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_PAR'} ...
            ];
         o_paramUnits = [ ...
            {'W/m^2/nm'} {'W/m^2/nm'} {'W/m^2/nm'} {'microMoleQuanta/m^2/sec'} ...
            ];
      elseif (okFlag == 2)
         o_paramName = [ ...
            {'DOWN_IRRADIANCE443'} {'DOWN_IRRADIANCE490'} ...
            {'DOWN_IRRADIANCE555'} {'DOWN_IRRADIANCE670'} ...
            ];
         o_paramDimLevel = [205 206 207 208];
         o_paramSensor = [ ...
            {'RADIOMETER_DOWN_IRR443'} {'RADIOMETER_DOWN_IRR490'} ...
            {'RADIOMETER_DOWN_IRR555'} {'RADIOMETER_DOWN_IRR670'} ...
            ];
         o_paramUnits = [ ...
            {'W/m^2/nm'} {'W/m^2/nm'} {'W/m^2/nm'} {'W/m^2/nm'} ...
            ];
      elseif (okFlag == -1)
         fprintf('ERROR: unexpected set of OCR calibration coefficients in get_sensor_parameter_info\n');
      else
         fprintf('ERROR: OCR calibration coefficients are needed to set associated parameters in get_sensor_parameter_info\n');
      end      

   case 'ECO3'
      o_paramName = [ ...
         {'FLUORESCENCE_CHLA'} {'BETA_BACKSCATTERING700'} {'FLUORESCENCE_CDOM'} ...
         {'CHLA'} {'BBP700'} {'CDOM'} ...
         ];
      o_paramDimLevel = [301 302 304 305 306 308];
      o_paramSensor = [ ...
         {'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} {'FLUOROMETER_CDOM'} ...
         {'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} {'FLUOROMETER_CDOM'} ...
         ];
      o_paramUnits = [ ...
         {'count'} {'count'} {'count'} ...
         {'mg/m3'} {'m-1'} {'ppb'} ...
         ];

   case 'TRANSISTOR_PH'
      o_paramName = [ ...
         {'VRS_PH'} ...
         {'PH_IN_SITU_FREE'} ...
         {'PH_IN_SITU_TOTAL'} ...
         ];
      o_paramDimLevel = [701 702 703];
      o_paramSensor = [ ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         ];
      o_paramUnits = [ ...
         {'volt'} ...
         {'dimensionless'} ...
         {'dimensionless'} ...
         ];

   case 'RAFOS'
      o_paramName = [ ...
         {'COR'} {'RAW_TOA'} {'TOA'} ...
         ];
      o_paramDimLevel = [1001 1002 1003];
      o_paramSensor = [ ...
         {'AUX_ACOUSTIC_GEOLOCATION'} {'AUX_ACOUSTIC_GEOLOCATION'} {'AUX_ACOUSTIC_GEOLOCATION'} ...
         ];
      o_paramUnits = [ ...
         {'dimensionless'} {'count'} {'second'} ...
         ];

   case 'RAFOS_RTC'
      o_paramName = [ ...
         {'RAFOS_RTC_TIME'} ...
         ];
      o_paramDimLevel = [1101];
      o_paramSensor = [ ...
         {'AUX_RAFOS_CLOCK'} ...
         ];
      o_paramUnits = [ ...
         {'second'} ...
         ];

   case 'RAMSES'
      o_paramName = [ ...
         {'RAW_DOWNWELLING_IRRADIANCE'} {'RADIOMETER_INTEGRATION_TIME'} ...
         {'RADIOMETER_TEMP'} {'RADIOMETER_PRES'} ...
         {'RADIOMETER_PRE_INCLINATION'} {'RADIOMETER_POST_INCLINATION'} ...
         ];
      o_paramDimLevel = [1201 1202 1203 1204 1205 1206];
      o_paramSensor = [ ...
         {'AUX_RADIOMETER_DOWN_IRR'} {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} {'AUX_RADIOMETER_DOWN_IRR'} ...
         ];
      o_paramUnits = [ ...
         {'count'} {'msec'} {'degree_Celsius'} {'decibar'} {'degree'} {'degree'} ...
         ];
      
   otherwise
      fprintf('ERROR: No sensor parameters for sensor %s\n', a_inputSensorName);
end

for idP = 1:length(o_paramName)
   [o_paramAccuracy{end+1}, o_paramResolution{end+1}] = get_parameter_info(o_paramName{idP}, a_floatNum, a_metaWmoList, a_metaData);
end
o_paramAccuracy = o_paramAccuracy';
o_paramResolution = o_paramResolution';

return

% ------------------------------------------------------------------------------
function [o_paramAccuracy, o_paramResolution] = ...
   get_parameter_info(a_paramName, a_floatNum, a_metaWmoList, a_metaData)

o_paramAccuracy = [];
o_paramResolution = [];

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
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'TEMP'))
         o_paramAccuracy = '0.002';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'PSAL'))
         o_paramAccuracy = '0.005';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'DOXY'))
         o_paramAccuracy = '10%';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'NITRATE'))
         o_paramAccuracy = '2';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
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
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'TEMP'))
         o_paramResolution = '0.001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'PSAL'))
         o_paramResolution = '0.001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'DOXY'))
         o_paramResolution = '0.001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'NITRATE'))
         o_paramResolution = '0.01';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      end
   end
   
end

return
