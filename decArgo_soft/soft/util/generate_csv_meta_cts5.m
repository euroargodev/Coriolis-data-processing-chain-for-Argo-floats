% ------------------------------------------------------------------------------
% Generate meta data for CTS5 floats (SENSOR, PARAMETER and CALIBRATION
% information) and miscellaneous configuration parameters.
%
% SYNTAX :
%  generate_csv_meta_cts5 or generate_csv_meta_cts5(varargin)
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
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function generate_csv_meta_cts5(varargin)

% to switch between Coriolis and JPR configurations
CORIOLIS_CONFIGURATION_FLAG = 0;

if (CORIOLIS_CONFIGURATION_FLAG)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % CORIOLIS CONFIGURATION - START

   % calibration coefficients decoded from data
   CALIB_FILE_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS5/DataFromFloatToMeta/CalibCoef/calib_coef.txt';

   % SUNA output pixel numbers decoded from data
   OUTPUT_PIXEL_FILE_NAME = '/home/coriolis_dev/gestion/exploitation/argo/flotteurs-coriolis/Bgc-Argo/CTS5/DataFromFloatToMeta/SunaOutputPixel/output_pixel.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = '/home/coriolis_exp/binlx/co04/co0414/co041404/decArgo_config_floats/argoFloatInfo/float_sensor_list.txt';

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = '/home/idmtmp7/vincent/matlab/DB_export/new_rem_meta.txt';

   % directory to store the log and csv files
   DIR_LOG_CSV_FILE = '/home/coriolis_exp/binlx/co04/co0414/co041402/data/csv';

   % CORIOLIS CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

else

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % JPR CONFIGURATION - START

   % calibration coefficients decoded from data
   CALIB_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS5\CTS5_float_config\DataFromFloatToMeta\CalibCoef\calib_coef.txt';

   % SUNA output pixel numbers decoded from data
   OUTPUT_PIXEL_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\PROVOR_CTS5\CTS5_float_config\DataFromFloatToMeta\SunaOutputPixel\output_pixel.txt';

   % list of sensors mounted on floats
   SENSOR_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_info\_float_sensor_list\float_sensor_list.txt';

   % meta-data file exported from Coriolis data base
   FLOAT_META_FILE_NAME = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\DB_Export\db_export_CTS5_6904226.txt';

   % directory to store the log and csv files
   DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

   % JPR CONFIGURATION - END
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

end

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

logFile = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta_cts5' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'generate_csv_meta_cts5' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
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

% read output pixel file
fId = fopen(OUTPUT_PIXEL_FILE_NAME, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', OUTPUT_PIXEL_FILE_NAME);
   return
end
outputPixelData = textscan(fId, '%s');
outputPixelData = outputPixelData{:};
fclose(fId);

outputPixelData = reshape(outputPixelData, 3, size(outputPixelData, 1)/3)';

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
% for id = 1:length(metaWmoList)
%    if (isempty(str2num(metaWmoList{id})))
%       fprintf('%s is not a valid WMO number\n', metaWmoList{id});
%       return
%    end
% end
S = sprintf('%s*', metaWmoList{:});
metaWmoList = sscanf(S, '%f*');

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
   
   % retrieve float version
   [floatVersion] = get_float_version(floatNum, metaWmoList, metaData);
   
   [platformFamily] = get_platform_family_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;2081;1;%s;PLATFORM_FAMILY;%s\n', floatNum, platformFamily, floatVersion);
   
   [platformType] = get_platform_type_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;2209;1;%s;PLATFORM_TYPE;%s\n', floatNum, platformType, floatVersion);
   
   [wmoInstType] = get_wmo_inst_type_db(floatNum, floatDecId, metaWmoList, metaData);
   fprintf(fidOut, '%d;13;1;%s;PR_PROBE_CODE;%s\n', floatNum, wmoInstType, floatVersion);
   
   % sensor information
   for idSensor = 1:length(sensorList)
      [sensorName, sensorDimLevel, sensorMaker, sensorModel] = get_sensor_info(sensorList{idSensor}, floatDecId, floatNum, metaWmoList, metaData);
      for idS = 1:length(sensorName)
         fprintf(fidOut, '%d;408;%d;%s;SENSOR;%s\n', floatNum, sensorDimLevel(idS), sensorName{idS}, floatVersion);
         fprintf(fidOut, '%d;409;%d;%s;SENSOR_MAKER;%s\n', floatNum, sensorDimLevel(idS), sensorMaker{idS}, floatVersion);
         fprintf(fidOut, '%d;410;%d;%s;SENSOR_MODEL;%s\n', floatNum, sensorDimLevel(idS), sensorModel{idS}, floatVersion);
         [sensorSn] = get_sensor_sn(sensorName{idS}, sensorMaker{idS}, sensorModel{idS}, floatNum, metaWmoList, metaData);
         if (~isempty(sensorSn))
            fprintf(fidOut, '%d;411;%d;%s;SENSOR_SERIAL_NO;%s\n', floatNum, sensorDimLevel(idS), sensorSn, floatVersion);
         end
      end
   end
   
   % parameter information
   for idSensor = 1:length(sensorList)
      [paramName, paramDimLevel, paramSensor, paramUnits, paramAccuracy, paramResolution] = ...
         get_sensor_parameter_info(sensorList{idSensor}, floatNum, floatDecId, metaWmoList, metaData);
      for idP = 1:length(paramName)
         fprintf(fidOut, '%d;415;%d;%s;PARAMETER;%s\n', floatNum, paramDimLevel(idP), paramName{idP}, floatVersion);
         fprintf(fidOut, '%d;2100;%d;%s;PARAMETER_SENSOR;%s\n', floatNum, paramDimLevel(idP), paramSensor{idP}, floatVersion);
         fprintf(fidOut, '%d;2206;%d;%s;PARAMETER_UNITS;%s\n', floatNum, paramDimLevel(idP), paramUnits{idP}, floatVersion);
         fprintf(fidOut, '%d;2207;%d;%s;PARAMETER_ACCURACY;%s\n', floatNum, paramDimLevel(idP), paramAccuracy{idP}, floatVersion);
         fprintf(fidOut, '%d;2208;%d;%s;PARAMETER_RESOLUTION;%s\n', floatNum, paramDimLevel(idP), paramResolution{idP}, floatVersion);
         
         %          [calibEquation, calibCoef, calibComment] = get_calib_info(paramName{idP}, floatNum, floatDecId, calibData);
         %          fprintf(fidOut, '%d;416;%d;%s;PREDEPLOYMENT_CALIB_EQUATION;%s\n', floatNum, paramDimLevel(idP), calibEquation, floatVersion);
         %          fprintf(fidOut, '%d;417;%d;%s;PREDEPLOYMENT_CALIB_COEFFICIENT;%s\n', floatNum, paramDimLevel(idP), calibCoef, floatVersion);
         %          fprintf(fidOut, '%d;418;%d;%s;PREDEPLOYMENT_CALIB_COMMENT;%s\n', floatNum, paramDimLevel(idP), calibComment, floatVersion);
      end
   end
   
   % SUNA output pixel numbers information
   if (~isempty(find(strcmp(sensorList, 'SUNA') == 1, 1)))
      [pixelBegin, pixelEnd] = get_output_pixel(outputPixelData, floatNum);
      if (isempty(pixelBegin))
         pixelBegin = -1;
         fprintf('INFO: Pixel Begin is missing for float #%d - value set to %d (it will be updated by the decoder BUT store the right value in the ''output_pixel.txt'' file)\n', ...
            floatNum, pixelBegin);
      end
      if (isempty(pixelEnd))
         pixelEnd = -1;
         fprintf('INFO: Pixel End is missing for float #%d - value set to %d (it will be updated by the decoder BUT store the right value in the ''output_pixel.txt'' file)\n', ...
            floatNum, pixelEnd);
      end
      fprintf(fidOut, '%d;2204;1;%d;SUNA_APF_OUTPUT_PIXEL_BEGIN;%s\n', floatNum, pixelBegin, floatVersion);
      fprintf(fidOut, '%d;2205;1;%d;SUNA_APF_OUTPUT_PIXEL_END;%s\n', floatNum, pixelEnd, floatVersion);
   end
   
   % sensor misc information
   [techParId, techParDimLev, techParCode, techParValue] = ...
      get_sensor_misc_info(sensorList, floatNum, floatDecId, metaWmoList, metaData);
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
function [o_sensorName, o_sensorDimLevel, o_sensorMaker, o_sensorModel] = get_sensor_info(a_inputSensorName, a_decId, a_floatNum, a_metaWmoList, a_metaData)

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
      for idS = 1:length(o_sensorName)
         [sensorModel] = get_sensor_model(o_sensorName{idS}, a_floatNum, a_metaWmoList, a_metaData);
         if (~isempty(sensorModel))
            if (~strcmp(sensorModel, o_sensorModel{idS}))
               fprintf('INFO: DB SENSOR_MODEL (''%s'') not replaced by default one (''%s'')\n', ...
                  sensorModel, o_sensorModel{idS});
               o_sensorModel(idS) = {sensorModel};
            end
         end
      end
      for idS = 1:length(o_sensorMaker)
         [sensorMaker] = get_sensor_maker(o_sensorName{idS}, a_floatNum, a_metaWmoList, a_metaData);
         if (~isempty(sensorMaker))
            if (~strcmp(sensorMaker, o_sensorMaker{idS}))
               fprintf('INFO: DB SENSOR_Maker (''%s'') not replaced by default one (''%s'')\n', ...
                  sensorMaker, o_sensorMaker{idS});
               o_sensorMaker(idS) = {sensorMaker};
            end
         end
      end

   case 'OPTODE'
      o_sensorName = {'OPTODE_DOXY'};
      o_sensorDimLevel = [101];
      o_sensorMaker = {'AANDERAA'};
      [sensorModel] = get_sensor_model('OPTODE_DOXY', a_floatNum, a_metaWmoList, a_metaData);
      if (~isempty(sensorModel))
         o_sensorModel = {sensorModel};
      end
      
   case 'OCR'
      o_sensorName = [{'RADIOMETER_DOWN_IRR380'} {'RADIOMETER_DOWN_IRR412'} {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_PAR'}];
      o_sensorDimLevel = [201 202 203 204];
      o_sensorMaker = [{'SATLANTIC'} {'SATLANTIC'} {'SATLANTIC'} {'SATLANTIC'}];
      o_sensorModel = [{'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'} {'SATLANTIC_OCR504_ICSW'}];
      
   case 'ECO3'
      o_sensorName = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} {'FLUOROMETER_CDOM'}];
      o_sensorDimLevel = [301 302 303];
      o_sensorMaker = [{'WETLABS'} {'WETLABS'} {'WETLABS'}];
      o_sensorModel = [{'ECO_FLBBCD'} {'ECO_FLBBCD'} {'ECO_FLBBCD'}];
      
   case 'ECO2'
      o_sensorName = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'}];
      o_sensorDimLevel = [301 302];
      o_sensorMaker = [{'WETLABS'} {'WETLABS'}];
      o_sensorModel = [{'ECO_FLBB_2K'} {'ECO_FLBB_2K'}];
      
   case 'CROVER'
      o_sensorName = {'TRANSMISSOMETER_CP660'};
      o_sensorDimLevel = [501];
      o_sensorMaker = {'WETLABS'};
      o_sensorModel = {'C_ROVER'};
      
   case 'SUNA'
      o_sensorName = {'SPECTROPHOTOMETER_NITRATE'};
      o_sensorDimLevel = [601];
      o_sensorMaker = {'SATLANTIC'};
      o_sensorModel = {'SUNA_V2'};
      
   case 'TRANSISTOR_PH'
      o_sensorName = {'TRANSISTOR_PH'};
      o_sensorDimLevel = [701];
      o_sensorMaker = {'SBE'};
      o_sensorModel = {'SEAFET'};
      
   case 'UVP'
      o_sensorName = {'AUX_PARTICLES_PLANKTON_CAMERA'};
      o_sensorDimLevel = [801];
      o_sensorMaker = {'HYDROPTIC'};
      o_sensorModel = {'UVP6-LP'};
      
   case 'OPUS'
      o_sensorName = {'AUX_SPECTROPHOTOMETER_NITRATE'};
      o_sensorDimLevel = [901];
      o_sensorMaker = {'TRIOS'};
      o_sensorModel = {'OPUS_DS'};
      
   case 'RAMSES'
      o_sensorName = {'AUX_RADIOMETER_DOWN_IRR'};
      o_sensorDimLevel = [1201];
      o_sensorMaker = {'TRIOS'};
      o_sensorModel = {'RAMSES_ACC'};
      
   case 'MPE'
      o_sensorName = {'AUX_RADIOMETER_PAR'};
      o_sensorDimLevel = [1301];
      o_sensorMaker = {'Biospherical instruments inc'};
      o_sensorModel = {'MPE'};
      
   case 'HYDROC'
      o_sensorName = {'AUX_OPTODE_DOXY'};
      o_sensorDimLevel = [1401];
      o_sensorMaker = {'4H-JENA'};
      o_sensorModel = {'HYDROC'};
      
   otherwise
      fprintf('ERROR: No sensor name for %s\n', a_inputSensorName);
end

return

% ------------------------------------------------------------------------------
function [o_techParId, o_techParDimLev, o_techParCode, o_techParValue] = ...
   get_sensor_misc_info(a_sensorList, a_floatNum, a_decId, a_metaWmoList, a_metaData)

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
         codeList = [ ...
            {'OPTODE_VERTICAL_PRES_OFFSET'} ...
            ];
         ifEmptyList = [ ...
            {'-0.06'} ...
            ];
         techParIdList = [ ...
            {'2199'} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
      case 'OCR'
         codeList = [ ...
            {'OCR_DOWN_IRR_BANDWIDTH'}; ...
            {'OCR_DOWN_IRR_WAVELENGTH'}; ...
            {'OCR_VERTICAL_PRES_OFFSET'} ...
            ];
         ifEmptyList = [ ...
            {[{'10'}; {'10'}; {'10'}]}; ...
            {[{'380'}; {'412'}; {'490'}]}; ...
            {'-0.08'} ...
            ];
         techParIdList = [ ...
            {'2196'}; ...
            {'2197'}; ...
            {'2198'} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
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
            {'ECO_CHLA_FLUO_EXCIT_WAVELENGTH'}; ...
            {'ECO_VERTICAL_PRES_OFFSET'} ...
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
            {'470'}; ...
            {'0.1'} ...
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
            {'2194'}; ...
            {'2195'} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
      case 'ECO2'
         codeList = [ ...
            {'ECO_BETA_ANGLE'}; ...
            {'ECO_BETA_BANDWIDTH'}; ...
            {'ECO_BETA_WAVELENGTH'}; ...
            {'ECO_CHLA_FLUO_EMIS_BANDWIDTH'}; ...
            {'ECO_CHLA_FLUO_EMIS_WAVELENGTH'}; ...
            {'ECO_CHLA_FLUO_EXCIT_BANDWIDTH'}; ...
            {'ECO_CHLA_FLUO_EXCIT_WAVELENGTH'}; ...
            {'ECO_VERTICAL_PRES_OFFSET'} ...
            ];
         ifEmptyList = [ ...
            {'142'}; ...
            {''}; ...
            {'700'}; ...
            {''}; ...
            {'695'}; ...
            {''}; ...
            {'470'}; ...
            {'0.1'} ...
            ];
         techParIdList = [ ...
            {'2184'}; ...
            {''}; ...
            {'2186'}; ...
            {''}; ...
            {'2192'}; ...
            {''}; ...
            {'2194'}; ...
            {'2195'} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
      case 'CROVER'
         codeList = [ ...
            {'CROVER_IN_PUMPED_STREAM'}; ...
            {'CROVER_BEAM_ATT_WAVELENGTH'}; ...
            {'CROVER_VERTICAL_PRES_OFFSET'} ...
            ];
         ifEmptyList = [ ...
            {'0'}; ...
            {'660'}; ...
            {''} ...
            ];
         techParIdList = [ ...
            {'2181'}; ...
            {'2182'}; ...
            {''} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
      case 'SUNA'
         codeList = [ ...
            {'SUNA_VERTICAL_PRES_OFFSET'}; ...
            {'SUNA_WITH_SCOOP'} ...
            ];
         ifEmptyList = [ ...
            {'1.5'}; ...
            {'0'} ...
            ];
         techParIdList = [ ...
            {'2200'}; ...
            {'2201'} ...
            ];
         [techParId, techParDimLev, techParCode, techParValue] = ...
            get_data(codeList, ifEmptyList, techParIdList, a_floatNum, a_metaWmoList, a_metaData);
         
      case 'TRANSISTOR_PH'
         % nothing yet
         
      case 'UVP'
         % nothing yet
         
      case 'OPUS'
         % nothing yet
         
      case 'RAMSES'
         % nothing yet

      case 'MPE'
         % nothing yet

      case 'HYDROC'
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
function [o_sensorSn] = get_sensor_sn(a_sensorName, a_sensorMaker, a_sensorModel, a_floatNum, a_metaWmoList, a_metaData)

o_sensorSn = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF1 = find(strcmp(a_metaData(idForWmo, 4), a_sensorName) & ...
   strcmp(a_metaData(idForWmo, 5), 'SENSOR'));
if (length(idF1) == 1)
   dimLevel = a_metaData(idForWmo(idF1), 3);
   idF2 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'SENSOR_SERIAL_NO'));
   if (~isempty(idF2))
      o_sensorSn = a_metaData{idForWmo(idF2), 4};
   else
      fprintf('ERROR: Sensor serial number not found for sensor %s of float %d\n', ...
         a_sensorName, a_floatNum);
   end
elseif (length(idF1) > 1)
   idF1 = find(strcmp(a_metaData(idForWmo, 4), a_sensorName) & strcmp(a_metaData(idForWmo, 5), 'SENSOR'));
   idF2 = find(strcmp(a_metaData(idForWmo, 4), a_sensorMaker) & strcmp(a_metaData(idForWmo, 5), 'SENSOR_MAKER'));
   idF3 = find(strcmp(a_metaData(idForWmo, 4), a_sensorModel) & strcmp(a_metaData(idForWmo, 5), 'SENSOR_MODEL'));
   dimLevel = intersect(intersect(a_metaData(idForWmo(idF1), 3)', a_metaData(idForWmo(idF2), 3)), a_metaData(idForWmo(idF3), 3));
   if (~isempty(dimLevel))
      idF2 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
         strcmp(a_metaData(idForWmo, 5), 'SENSOR_SERIAL_NO'));
      if (~isempty(idF2))
         o_sensorSn = a_metaData{idForWmo(idF2), 4};
      else
         fprintf('ERROR: Sensor serial number not found for sensor %s of float %d\n', ...
            a_sensorName, a_floatNum);
      end
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
function [o_sensorMaker] = get_sensor_maker(a_sensorName, a_floatNum, a_metaWmoList, a_metaData)

o_sensorMaker = [];

idForWmo = find(a_metaWmoList == a_floatNum);

idF1 = find(strcmp(a_metaData(idForWmo, 4), a_sensorName) & ...
   strcmp(a_metaData(idForWmo, 5), 'SENSOR'));
if (~isempty(idF1))
   dimLevel = a_metaData(idForWmo(idF1), 3);
   idF2 = find(strcmp(a_metaData(idForWmo, 3), dimLevel) & ...
      strcmp(a_metaData(idForWmo, 5), 'SENSOR_MAKER'));
   if (~isempty(idF2))
      o_sensorMaker = strtrim(a_metaData{idForWmo(idF2), 4});
   else
      fprintf('ERROR: Sensor maker not found for sensor %s of float %d\n', ...
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
   a_metaWmoList, a_metaData)

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
      o_paramName = [ ...
         {'RAW_DOWNWELLING_IRRADIANCE380'} {'RAW_DOWNWELLING_IRRADIANCE412'} ...
         {'RAW_DOWNWELLING_IRRADIANCE490'} {'RAW_DOWNWELLING_PAR'} ...
         {'DOWN_IRRADIANCE380'} {'DOWN_IRRADIANCE412'} ...
         {'DOWN_IRRADIANCE490'} {'DOWNWELLING_PAR'} ...
         ];
      o_paramDimLevel = [201 202 203 204 205 206 207 208];
      o_paramSensor = [ ...
         {'RADIOMETER_DOWN_IRR380'} {'RADIOMETER_DOWN_IRR412'} ...
         {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_PAR'} ...
         {'RADIOMETER_DOWN_IRR380'} {'RADIOMETER_DOWN_IRR412'} ...
         {'RADIOMETER_DOWN_IRR490'} {'RADIOMETER_PAR'} ...
         ];
      o_paramUnits = [ ...
         {'count'} {'count'} {'count'} {'count'} ...
         {'W/m^2/nm'} {'W/m^2/nm'} {'W/m^2/nm'} {'microMoleQuanta/m^2/sec'} ...
         ];
      
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
      
   case 'ECO2'
      o_paramName = [ ...
         {'FLUORESCENCE_CHLA'} {'BETA_BACKSCATTERING700'} ...
         {'CHLA'} {'BBP700'} ...
         ];
      o_paramDimLevel = [301 302 305 306];
      o_paramSensor = [ ...
         {'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} ...
         {'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP700'} ...
         ];
      o_paramUnits = [ ...
         {'count'} {'count'} ...
         {'mg/m3'} {'m-1'} ...
         ];
      
   case 'CROVER'
      o_paramName = [ ...
         {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'} {'CP660'} ...
         ];
      o_paramDimLevel = [502 501];
      o_paramSensor = [ ...
         {'TRANSMISSOMETER_CP660'} ...
         {'TRANSMISSOMETER_CP660'} ...
         ];
      o_paramUnits = [ ...
         {'dimensionless'} ...
         {'m-1'} ...
         ];
      
   case 'SUNA'
      switch a_decId
         case {126, 128}
            o_paramName = [ ...
               {'TEMP_NITRATE'} ...
               {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
               {'HUMIDITY_NITRATE'} ...
               {'UV_INTENSITY_DARK_NITRATE'} ...
               {'FIT_ERROR_NITRATE'} ...
               {'UV_INTENSITY_NITRATE'} ...
               {'NITRATE'} ...
               ];
            o_paramDimLevel = [601 602 603 604 606 607 608];
            o_paramSensor = [ ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               {'SPECTROPHOTOMETER_NITRATE'} ...
               ];
            o_paramUnits = [ ...
               {'degree_Celsius'} ...
               {'degree_Celsius'} ...
               {'percent'} ...
               {'count'} ...
               {'micromole/kg'} ...
               {'count'} ...
               {'micromole/kg'} ...
               ];
         case {127}
            o_paramName = [ ...
               {'TEMP_NITRATE'} ...
               {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
               {'HUMIDITY_NITRATE'} ...
               {'UV_INTENSITY_DARK_NITRATE'} ...
               {'FIT_ERROR_NITRATE'} ...
               {'UV_INTENSITY_NITRATE'} ...
               {'NITRATE'} ...
               {'BISULFIDE'} ...
               ];
            o_paramDimLevel = [601 602 603 604 606 607 608 609];
            o_paramSensor = [ ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               {'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_NITRATE'} ...
               ];
            o_paramUnits = [ ...
               {'degree_Celsius'} ...
               {'degree_Celsius'} ...
               {'percent'} ...
               {'count'} ...
               {'dimensionless'} ...
               {'count'} ...
               {'micromole/kg'} ...
               {'micromole/kg'} ...
               ];
         otherwise
            fprintf('ERROR: No parameter list for SUNA sensor for decId #%d\n', a_decId);
      end
      
   case 'TRANSISTOR_PH'
      o_paramName = [ ...
         {'VRS_PH'} ...
         {'VK_PH'} ...
         {'IK_PH'} ...
         {'IB_PH'} ...
         {'PH_IN_SITU_FREE'} ...
         {'PH_IN_SITU_TOTAL'} ...
         ];
      o_paramDimLevel = [701 702 703 704 705 706];
      o_paramSensor = [ ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         {'TRANSISTOR_PH'} ...
         ];
      o_paramUnits = [ ...
         {'volt'} ...
         {'volt'} ...
         {'nanoampere'} ...
         {'nanoampere'} ...
         {'dimensionless'} ...
         {'dimensionless'} ...
         ];
      
   case 'UVP'
      o_paramName = [ ...
         {'NB_SIZE_SPECTRA_PARTICLES'} ...
         {'GREY_SIZE_SPECTRA_PARTICLES'} ...
         {'TEMP_PARTICLES'} ...
         {'IMAGE_NUMBER_PARTICLES'} ...
         {'BLACK_NB_SIZE_SPECTRA_PARTICLES'} ...
         {'BLACK_TEMP_PARTICLES'} ...
         {'NB_CAT_SPECTRA_PLANKTON'} ...
         {'SIZE_CAT_SPECTRA_PLANKTON'} ...
         {'GREY_LEVEL_CAT_SPECTRA_PLANKTON'} ...
         {'TEMP_PLANKTON'} ...
         {'IMAGE_NUMBER_PLANKTON'} ...
         {'NB_REL_CAT_SPECTRA_PLANKTON'} ...
         {'SIZE_REL_CAT_SPECTRA_PLANKTON'} ...
         {'GREY_LEVEL_EST_REL_SPECTRA_PLANKTON'} ...
         ];
      o_paramDimLevel = [801 802 803 804 805 806 807 808 809 810 811 812 813 814];
      o_paramSensor = [ ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         {'AUX_PARTICLES_PLANKTON_CAMERA'} ...
         ];
      o_paramUnits = [ ...
         {'number of particles per litre'} ...
         {'bit'} ...
         {'degree_Celsius'} ...
         {'count'} ...
         {'count'} ...
         {'degree_Celsius'} ...
         {'count'} ...
         {'ESD in micrometer'} ...
         {'bit'} ...
         {'degree_Celsius'} ...
         {'count'} ...
         {'count'} ...
         {'count'} ...
         {'bit'} ...
         ];
      
   case 'OPUS'
      o_paramName = [ ...
         {'SPECTRUM_TYPE_NITRATE'} ...
         {'AVERAGING_NITRATE'} ...
         {'FLASH_COUNT_NITRATE'} ...
         {'TEMP_NITRATE2'} ...
         {'UV_INTENSITY_FULL_NITRATE'} ...
         {'UV_INTENSITY_BINNED_NITRATE'} ...
         {'UV_INTENSITY_DARK_NITRATE_AVG'} ...
         {'UV_INTENSITY_DARK_NITRATE_SD'} ...
         ];
      o_paramDimLevel = [901 902 903 904 905 906 907 908];
      o_paramSensor = [ ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         {'AUX_SPECTROPHOTOMETER_NITRATE'} ...
         ];
      o_paramUnits = [ ...
         {'dimensionless'} ...
         {'count'} ...
         {'count'} ...
         {'count'} ...
         {'count'} ...
         {'count'} ...
         {'count'} ...
         {'count'} ...
         ];
      
   case 'RAMSES'
      o_paramName = [ ...
         {'RADIOMETER_INTEGRATION_TIME'} ...
         {'RADIOMETER_PRE_PRES'} ...
         {'RADIOMETER_POST_PRES'} ...
         {'RADIOMETER_PRE_INCLINATION'} ...
         {'RADIOMETER_POST_INCLINATION'} ...
         {'RADIOMETER_DARK_AVERAGE'} ...
         {'RAW_DOWNWELLING_IRRADIANCE'} ...
         ];
      o_paramDimLevel = [1201 1202 1203 1204 1205 1206 1207];
      o_paramSensor = [ ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         {'AUX_RADIOMETER_DOWN_IRR'} ...
         ];
      o_paramUnits = [ ...
         {'msec'} ...
         {'decibar'} ...
         {'decibar'} ...
         {'degree'} ...
         {'degree'} ...
         {'count'} ...
         {'count'} ...
         ];
      
   case 'MPE'
      o_paramName = [ ...
         {'TEMP_DOWNWELLING_PAR'} ...
         {'VOLTAGE_DOWNWELLING_PAR'} ...
         {'DOWNWELLING_PAR2'} ...
         ];
      o_paramDimLevel = [1301 1302 1303];
      o_paramSensor = [ ...
         {'AUX_RADIOMETER_PAR'} ...
         {'AUX_RADIOMETER_PAR'} ...
         {'AUX_RADIOMETER_PAR'} ...
         ];
      o_paramUnits = [ ...
         {'degree_Celsius'} ...
         {'volt'} ...
         {'microMoleQuanta/m^2/sec'} ...
         ];

   case 'HYDROC'
      o_paramName = [ ...
         {'ACQUISITION_MODE'} ...
         {'SIGNAL_RAW'} ...
         {'SIGNAL_REF'} ...
         {'PRES_IN'} ...
         {'PRES_NDIR'} ...
         {'TEMP_NDIR'} ...
         {'TEMP_GAS'} ...
         {'HUMIDITY_GAS'} ...
         {'PUMP_POWER'} ...
         {'SUPPLY_VOLTAGE'} ...
         {'TOTAL_CURRENT'} ...
         {'RUNTIME'} ...
         ];
      o_paramDimLevel = [1401 1402 1403 1404 1405 1406 1407 1408 1409 1410 1411 1412];
      o_paramSensor = [ ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         {'AUX_OPTODE_DOXY'} ...
         ];
      o_paramUnits = [ ...
         {'dimensionless'} ...
         {'count'} ...
         {'count'} ...
         {'mbar'} ...
         {'mbar'} ...
         {'degree_Celsius'} ...
         {'degree_Celsius'} ...
         {'%'} ...
         {'W'} ...
         {'V'} ...
         {'mA'} ...
         {'sec'} ...
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
if (length(idF1) == 1)
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
      elseif (strcmp(a_paramName, 'VRS_PH'))
         o_paramAccuracy = '0.000030';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'PH_IN_SITU_TOTAL'))
         o_paramAccuracy = '0.005';
         fprintf('INFO: ''%s'' PARAMETER_ACCURACY is missing - set to ''%s''\n', a_paramName, o_paramAccuracy);
      elseif (strcmp(a_paramName, 'PH_IN_SITU_FREE'))
         o_paramAccuracy = '0.005';
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
      elseif (strcmp(a_paramName, 'VRS_PH'))
         o_paramResolution = '0.000001';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'PH_IN_SITU_TOTAL'))
         o_paramResolution = '0.0004';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      elseif (strcmp(a_paramName, 'PH_IN_SITU_FREE'))
         o_paramResolution = '0.0004';
         fprintf('INFO: ''%s'' PARAMETER_RESOLUTION is missing - set to ''%s''\n', a_paramName, o_paramResolution);
      end
   end

elseif (length(idF1) > 1)
   fprintf('ERROR: Float #%d: %d entries in DB for parameter ''%s''\n', ...
      a_floatNum, length(idF1), a_paramName);
end

return

% ------------------------------------------------------------------------------
function [o_calibEquation, o_calibCoef, o_calibComment] = get_calib_info(a_parameterName, a_floatNum, a_decId, a_calibData)

o_calibEquation = [];
o_calibCoef = [];
o_calibComment = [];

switch a_parameterName
   
   % CTD
   case {'PRES'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = '';
      
   case {'TEMP'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = '';
      
   case {'PSAL'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = '';
      
      % OPTODE
   case {'C1PHASE_DOXY'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'C2PHASE_DOXY'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'TEMP_DOXY'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'PPOX_DOXY'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'DOXY'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
      % ECO3
   case {'FLUORESCENCE_CHLA'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Uncalibrated chlorophyll-a fluorescence measurement';
      
   case {'BETA_BACKSCATTERING700'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Uncalibrated backscattering measurement';
      
   case {'FLUORESCENCE_CDOM'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
      % ECO3
   case {'CHLA'}
      
      scaleFactChloroA = '';
      darkCountChloroA = '';
      switch a_decId
         
         case {121, 122, 123, 124, 125}
            [scaleFactChloroA] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'ScaleFactChloroA');
            [darkCountChloroA] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'DarkCountChloroA');
            
         otherwise
            fprintf('ERROR: No calib information for parameter %s of float #%d (decId %d)\n', a_parameterName, a_floatNum, a_decId);
      end
      
      if ((~isempty(scaleFactChloroA)) && (~isempty(darkCountChloroA)))
         o_calibEquation = 'CHLA=(FLUORESCENCE_CHLA-DARK_CHLA)*SCALE_CHLA';
         o_calibCoef = sprintf('DARK_CHLA=%s, SCALE_CHLA=%s', ...
            num_2_str(darkCountChloroA), num_2_str(scaleFactChloroA));
         o_calibComment = 'No DARK_CHLA_O provided';
      end
      
      % ECO3
   case {'BBP700'}
      
      scaleFactBackscatter700 = '';
      darkCountBackscatter700 = '';
      khiCoefBackscatter = '';
      switch a_decId
         
         case {121, 122, 123, 124, 125}
            [scaleFactBackscatter700] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'ScaleFactBackscatter700');
            [darkCountBackscatter700] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'DarkCountBackscatter700');
            [khiCoefBackscatter] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'KhiCoefBackscatter');
            %             [molecularBackscatteringOfWaterBackscatter700] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'MolecularBackscatteringOfWaterBackscatter700');
            
         otherwise
            fprintf('ERROR: No calib information for parameter %s of float #%d (decId %d)\n', a_parameterName, a_floatNum, a_decId);
      end
      
      if ((~isempty(scaleFactBackscatter700)) && (~isempty(darkCountBackscatter700)) && ...
            (~isempty(khiCoefBackscatter)))
         o_calibCoef = sprintf('DARK_BACKSCATTERING700=%s, SCALE_BACKSCATTERING700=%s, khi=%s, BETASW700 (contribution of pure sea water) is calculated at 124 angularDeg', ...
            num_2_str(darkCountBackscatter700), num_2_str(scaleFactBackscatter700), num_2_str(khiCoefBackscatter));
         o_calibEquation = 'BBP700=2*pi*khi*((BETA_BACKSCATTERING700-DARK_BACKSCATTERING700)*SCALE_BACKSCATTERING700-BETASW700)';
         o_calibComment = 'No DARK_BACKSCATTERING700_O provided, Sullivan et al., 2012, Zhang et al., 2009, BETASW700 is the contribution by the pure seawater at 700nm, the calculation can be found at http://doi.org/10.17882/42916';
      end
      
   case {'CDOM'}
      [scaleFactCDOM] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'ScaleFactCDOM');
      [darkCountCDOM] = get_calib_coef(a_calibData, a_floatNum, 'ECO3', 'DarkCountCDOM');
      
      o_calibEquation = 'CDOM=(FLUORESCENCE_CDOM-DARK_CDOM)*SCALE_CDOM';
      o_calibCoef = sprintf('DARK_CDOM=%s, SCALE_CDOM=%s', ...
         num_2_str(darkCountCDOM), num_2_str(scaleFactCDOM));
      o_calibComment = '';
      
      % OCR
   case {'RAW_DOWNWELLING_IRRADIANCE380'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Uncalibrated downwelling irradiance measurement at 380 nm';
      
   case {'RAW_DOWNWELLING_IRRADIANCE412'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Uncalibrated downwelling irradiance measurement at 412 nm';
      
   case {'RAW_DOWNWELLING_IRRADIANCE490'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Uncalibrated downwelling irradiance measurement at 490 nm';
      
   case {'RAW_DOWNWELLING_PAR'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Uncalibrated downwelling PAR measurement';
      
   case {'DOWN_IRRADIANCE380'}
      [a0Lambda380] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A0Lambda380');
      [a1Lambda380] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A1Lambda380');
      [lmLambda380] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'LmLambda380');
      
      o_calibEquation = 'DOWN_IRRADIANCE380=0.01*A1_380*(RAW_DOWNWELLING_IRRADIANCE380-A0_380)*lm_380';
      o_calibCoef = sprintf('A1_380=%s, A0_380=%s, lm_380=%s', ...
         num_2_str(a1Lambda380), num_2_str(a0Lambda380), num_2_str(lmLambda380));
      o_calibComment = '';
      
   case {'DOWN_IRRADIANCE412'}
      [a0Lambda412] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A0Lambda412');
      [a1Lambda412] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A1Lambda412');
      [lmLambda412] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'LmLambda412');
      
      o_calibEquation = 'DOWN_IRRADIANCE412=0.01*A1_412*(RAW_DOWNWELLING_IRRADIANCE412-A0_412)*lm_412';
      o_calibCoef = sprintf('A1_412=%s, A0_412=%s, lm_412=%s', ...
         num_2_str(a1Lambda412), num_2_str(a0Lambda412), num_2_str(lmLambda412));
      o_calibComment = '';
      
   case {'DOWN_IRRADIANCE490'}
      [a0Lambda490] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A0Lambda490');
      [a1Lambda490] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A1Lambda490');
      [lmLambda490] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'LmLambda490');
      
      o_calibEquation = 'DOWN_IRRADIANCE490=0.01*A1_490*(RAW_DOWNWELLING_IRRADIANCE490-A0_490)*lm_490';
      o_calibCoef = sprintf('A1_490=%s, A0_490=%s, lm_490=%s', ...
         num_2_str(a1Lambda490), num_2_str(a0Lambda490), num_2_str(lmLambda490));
      o_calibComment = '';
      
   case {'DOWNWELLING_PAR'}
      [a0PAR] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A0PAR');
      [a1PAR] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'A1PAR');
      [lmPAR] = get_calib_coef(a_calibData, a_floatNum, 'OCR', 'LmPAR');
      
      o_calibEquation = 'DOWNWELLING_PAR=A1_PAR*(RAW_DOWNWELLING_PAR-A0_PAR)*lm_PAR';
      o_calibCoef = sprintf('A1_PAR=%s, A0_PAR=%s, lm_PAR=%s', ...
         num_2_str(a1PAR), num_2_str(a0PAR), num_2_str(lmPAR));
      o_calibComment = '';
      
      % CROVER
   case {'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION660'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'CP660'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
      % SUNA
   case {'MOLAR_NITRATE'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'NITRATE'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'TEMP_NITRATE'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'TEMP_SPECTROPHOTOMETER_NITRATE'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'HUMIDITY_NITRATE'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'UV_INTENSITY_DARK_NITRATE'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Intensity of ultra violet flux dark measurement from nitrate sensor';
      
   case {'FIT_ERROR_NITRATE'}
      o_calibEquation = '';
      o_calibCoef = '';
      o_calibComment = '';
      
   case {'UV_INTENSITY_NITRATE'}
      o_calibEquation = 'none';
      o_calibCoef = 'none';
      o_calibComment = 'Intensity of ultra violet flux from nitrate sensor';
      
   otherwise
      fprintf('ERROR: No calib information for parameter %s of float #%d\n', a_parameterName, a_floatNum);
end

return

% ------------------------------------------------------------------------------
function [o_coefVal] = get_calib_coef(a_calibData, a_floatNum, a_sensorName, a_coefName)

o_coefVal = [];

idF = find((strcmp(a_calibData(:, 1), num2str(a_floatNum)) == 1) & ...
   (strcmp(a_calibData(:, 2), a_sensorName) == 1) & ...
   (strcmp(a_calibData(:, 3), a_coefName) == 1));
if (~isempty(idF))
   o_coefVal = str2num(a_calibData{idF, 4});
else
   fprintf('ERROR: Calib coef %s is missing for float #%d\n', a_coefName, a_floatNum);
end

return

% ------------------------------------------------------------------------------
function [o_vectorShowMode, o_sensorShowMode] = get_show_mode(a_showModeData, a_floatNum)

o_vectorShowMode = [];
o_sensorShowMode = [];

idF = find((strcmp(a_showModeData(:, 1), num2str(a_floatNum)) == 1) & ...
   (strcmp(a_showModeData(:, 2), 'CONFIG_VectorBoardShowModeOn_LOGICAL') == 1));
if (~isempty(idF))
   o_vectorShowMode = str2num(a_showModeData{idF, 3});
else
   fprintf('ERROR: Vector show mode is missing for float #%d\n', a_floatNum);
end

idF = find((strcmp(a_showModeData(:, 1), num2str(a_floatNum)) == 1) & ...
   (strcmp(a_showModeData(:, 2), 'CONFIG_SensorBoardShowModeOn_LOGICAL') == 1));
if (~isempty(idF))
   o_sensorShowMode = str2num(a_showModeData{idF, 3});
else
   fprintf('ERROR: Sensor show mode is missing for float #%d\n', a_floatNum);
end

return

% ------------------------------------------------------------------------------
function [o_pixelBegin, o_pixelEnd] = get_output_pixel(a_outputPixelData, a_floatNum)

o_pixelBegin = [];
o_pixelEnd = [];

idF = find((strcmp(a_outputPixelData(:, 1), num2str(a_floatNum)) == 1) & ...
   (strcmp(a_outputPixelData(:, 2), 'CONFIG_SunaApfFrameOutputPixelBegin_NUMBER') == 1));
if (~isempty(idF))
   o_pixelBegin = str2num(a_outputPixelData{idF, 3});
else
   fprintf('ERROR: SUNA output pixel begin number is missing for float #%d\n', a_floatNum);
end

idF = find((strcmp(a_outputPixelData(:, 1), num2str(a_floatNum)) == 1) & ...
   (strcmp(a_outputPixelData(:, 2), 'CONFIG_SunaApfFrameOutputPixelEnd_NUMBER') == 1));
if (~isempty(idF))
   o_pixelEnd = str2num(a_outputPixelData{idF, 3});
else
   fprintf('ERROR: SUNA output pixel end number is missing for float #%d\n', a_floatNum);
end

return

% % ------------------------------------------------------------------------------
% function [o_sensorSn] = get_sensor_sn(a_sensorSnData, a_floatNum, a_sensorName)
%
% o_sensorSn = [];
%
% idF = find((strcmp(a_sensorSnData(:, 1), num2str(a_floatNum)) == 1) & ...
%    (strcmp(a_sensorSnData(:, 2), a_sensorName) == 1));
% if (~isempty(idF))
%    o_sensorSn = a_sensorSnData{idF, 3};
% else
%    fprintf('ERROR: Sensor number is missing for sensor %s of float #%d\n', a_sensorName, a_floatNum);
% end
%
% return
