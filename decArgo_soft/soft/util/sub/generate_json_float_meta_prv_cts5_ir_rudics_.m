% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_prv_cts5_ir_rudics_( ...
%    a_floatMetaFileName, a_floatListFileName, ...
%    a_calibFileName, a_configDirName, a_sunaConfigDirName, ...
%    a_outputDirName)
%
% INPUT PARAMETERS :
%   a_floatMetaFileName : meta-data file exported from Coriolis data base
%   a_floatListFileName : list of concerned floats
%   a_calibFileName     : list of calibartion coefficient (retrieved from
%                         decoded data)
%   a_configDirName     : directory of float configuration at launch files
%   a_sunaConfigDirName : directory of SUNA configuration files
%   a_outputDirName     : directory of individual json float meta-data files
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
%   09/04/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function generate_json_float_meta_prv_cts5_ir_rudics_( ...
   a_floatMetaFileName, a_floatListFileName, ...
   a_calibFileName, a_configDirName, a_sunaConfigDirName, ...
   a_outputDirName)

% report information structure
global g_cogj_reportData;


% check inputs
fprintf('Generating json meta-data files from input file: %s\n', a_floatMetaFileName);

if ~(exist(a_floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', a_floatMetaFileName);
   return;
end

fprintf('Generating json meta-data files for floats of the list: %s\n', a_floatListFileName);

if ~(exist(a_floatListFileName, 'file') == 2)
   fprintf('ERROR: Float file list not found: %s\n', a_floatListFileName);
   return;
end

fprintf('Calibration file used: %s\n', a_calibFileName);

if ~(exist(a_calibFileName, 'file') == 2)
   fprintf('ERROR: Float file list not found: %s\n', a_calibFileName);
   return;
end

fprintf('Directory of float configuration files used: %s\n', a_configDirName);

if ~(exist(a_configDirName, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', a_configDirName);
   return;
end

fprintf('Directory of SUNA configuration files used: %s\n', a_sunaConfigDirName);

if ~(exist(a_sunaConfigDirName, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', a_sunaConfigDirName);
   return;
end

% lists of mandatory meta-data
mandatoryList1 = [ ...
   {'BATTERY_TYPE'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} ...
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} ...
   {'DAC_FORMAT_ID'} ...
   {'FIRMWARE_VERSION'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'MANUAL_VERSION'} ...
   {'PI_NAME'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PTT'} ...
   {'SENSOR_SERIAL_NO'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_SENSOR'} ...
   {'STANDARD_FORMAT_ID'} ...
   {'TRANS_FREQUENCY'} ...
   {'TRANS_SYSTEM_ID'} ...
   {'WMO_INST_TYPE'} ...
   ];
mandatoryList2 = [ ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   ];

% get DB meta-data
fId = fopen(a_floatMetaFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_floatMetaFileName);
   return;
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';

% read calib file
fId = fopen(a_calibFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_calibFileName);
   return;
end
calibData = textscan(fId, '%s');
calibData = calibData{:};
fclose(fId);

calibData = reshape(calibData, 4, size(calibData, 1)/4)';

% get the mapping structure
metaBddStruct = get_meta_bdd_struct();
metaBddStructNames = fieldnames(metaBddStruct);

% process the meta-data to fill the structure
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the same number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the same number of digits
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('%s is not a valid WMO number\n', wmoList{id});
      return;
   end
end
S = sprintf('%s*', wmoList{:});
wmoList = sscanf(S, '%f*');
dimLevlist = metaData(:, 3);
S = sprintf('%s*', dimLevlist{:});
dimLevlist = sscanf(S, '%f*');
floatList = unique(wmoList);

% check needed floats against DB contents
refFloatList = load(a_floatListFileName);

floatList = sort(intersect(floatList, refFloatList));
% floatList = [6901032 6901440];
% floatList = [4901803];

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('WARNING: Meta-data not found for float: %d\n', notFoundFloat);
end

% process floats
for idFloat = 1:length(floatList)
   
   fprintf('%2d/%2d\n', idFloat, length(floatList));
   fprintf('%d\n', floatList(idFloat));
   wmoNumber = floatList(idFloat);
   
   % initialize the structure to be filled
   metaStruct = get_meta_init_struct();
   
   metaStruct.PLATFORM_NUMBER = num2str(floatList(idFloat));
   metaStruct.ARGO_USER_MANUAL_VERSION = '3.1';
   
   % direct conversion data
   idForWmo = find(wmoList == floatList(idFloat));
   for idBSN = 1:length(metaBddStructNames)
      metaBddStructField = char(metaBddStructNames(idBSN));
      if (strcmp(metaBddStructField, 'NEW_DARK_FOR_FLUOROMETER_CHLA') || ...
            strcmp(metaBddStructField, 'NEW_DARK_FOR_FLUOROMETER_CDOM') || ...
            strcmp(metaBddStructField, 'NEW_DARK_FOR_SCATTEROMETER_BBP'))
         continue;
      end
      metaBddStructValue = metaBddStruct.(metaBddStructField);
      if (~isempty(metaBddStructValue))
         idF = find(strcmp(metaData(idForWmo, 5), metaBddStructValue) == 1, 1);
         if (~isempty(idF))
            metaStruct.(metaBddStructField) = char(metaData(idForWmo(idF), 4));
         else
            if (~isempty(find(strcmp(mandatoryList1, metaBddStructField) == 1, 1)))
               metaStruct.(metaBddStructField) = 'n/a';
               %                fprintf('Empty mandatory meta-data ''%s'' set to ''n/a''\n', metaBddStructValue);
            elseif (~isempty(find(strcmp(mandatoryList2, metaBddStructField) == 1, 1)))
               metaStruct.(metaBddStructField) = 'UNKNOWN';
            end
         end
      end
   end
   
   % float login name
   if (~isempty(metaStruct.PTT))
      loginName = metaStruct.PTT;
   else
      fprintf('ERROR: login name not found for float %d => not considered\n', floatList(idFloat));
      continue;
   end
   
   % PTT / IMEI specific processing
   if (~isempty(metaStruct.IMEI))
      metaStruct.PTT = '';
      imei = metaStruct.IMEI;
      if (length(imei) > 6)
         metaStruct.PTT = imei(end-6:end-1);
      end
   end
   
   % multi dim data
   itemList = [ ...
      {'TRANS_SYSTEM'} ...
      {'TRANS_SYSTEM_ID'} ...
      {'TRANS_FREQUENCY'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   [metaStruct] = add_multi_dim_data( ...
      {'POSITIONING_SYSTEM'}, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   itemList = [ ...
      {'SENSOR'} ...
      {'SENSOR_MAKER'} ...
      {'SENSOR_MODEL'} ...
      {'SENSOR_SERIAL_NO'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   itemList = [ ...
      {'PARAMETER'} ...
      {'PARAMETER_SENSOR'} ...
      {'PARAMETER_UNITS'} ...
      {'PARAMETER_ACCURACY'} ...
      {'PARAMETER_RESOLUTION'} ...
      {'PREDEPLOYMENT_CALIB_EQUATION'} ...
      {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
      {'PREDEPLOYMENT_CALIB_COMMENT'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   itemList = [ ...
      {'CALIB_RT_PARAMETER'} ...
      {'CALIB_RT_EQUATION'} ...
      {'CALIB_RT_COEFFICIENT'} ...
      {'CALIB_RT_COMMENT'} ...
      {'CALIB_RT_DATE'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   % add the list of the sensor mounted on the float (because SENSOR variable is
   % not correctly filled yet), this list is used by the decoder to check the
   % expected data
   sensorList = get_sensor_list_cts5(wmoNumber);
   metaStruct.SENSOR_MOUNTED_ON_FLOAT = sensorList;
   
   % add the calibration coefficients for ECO3 and OCR sensors (coming from the
   % calibFileName)
      
   idF = find(strcmp(calibData(:, 1), num2str(wmoNumber)) == 1);
   dataStruct = [];
   for id = 1:length(idF)
      fieldName1 = calibData{idF(id), 2};
      %       dataStruct.(fieldName1) = [];
      fieldName2 = calibData{idF(id), 3};
      dataStruct.(fieldName1).(fieldName2) = calibData{idF(id), 4};
   end
   metaStruct.CALIBRATION_COEFFICIENT = dataStruct;
   
   % add DARK_O coefficients for ECO3 sensor
   if (isfield(metaStruct.CALIBRATION_COEFFICIENT, 'ECO3'))
      idForWmo = find(wmoList == floatList(idFloat));
      idF = find(strcmp(metaData(idForWmo, 5), 'NEW_DARK_FOR_FLUOROMETER_CHLA'));
      if (~isempty(idF))
         idF2 = find(cellfun(@str2num, metaData(idForWmo(idF), 3)) == 1); % always dim level 1 for DarkCountChloroA_O
         if (~isempty(idF2))
            metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountChloroA_O = metaData{idForWmo(idF(idF2)), 4};
         end
      end
      idF = find(strcmp(metaData(idForWmo, 5), 'NEW_DARK_FOR_FLUOROMETER_CDOM'));
      if (~isempty(idF))
         idF2 = find(cellfun(@str2num, metaData(idForWmo(idF), 3)) == 1); % always dim level 1 for DarkCountCDOM_O
         if (~isempty(idF2))
            metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountCDOM_O = metaData{idForWmo(idF(idF2)), 4};
         end
      end      
      idF = find(strcmp(metaData(idForWmo, 5), 'NEW_DARK_FOR_SCATTEROMETER_BBP'));
      if (~isempty(idF))
         idF2 = find(cellfun(@str2num, metaData(idForWmo(idF), 3)) == 1); % dim level 1 for DarkCountBackscatter700_O
         if (~isempty(idF2))
            metaStruct.CALIBRATION_COEFFICIENT.ECO3.DarkCountBackscatter700_O = metaData{idForWmo(idF(idF2)), 4};
         end
      end
   end
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = metaStruct.DAC_FORMAT_ID;
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d => no json file generated\n', ...
         floatList(idFloat));
      continue;
   end
   
   % add the calibration coefficients for OPTODE sensor (coming from the
   % data base)
   switch (dacFormatId)
      case {'7.01', '7.02'}
         idF = find((strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1));
         calibDataDb = [];
         for id = 1:length(idF)
            calibName = metaData{idForWmo(idF(id)), 5};
            if (strncmp(calibName, 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1)
               fieldName = ['SVUFoilCoef' num2str(str2num(calibName(end)))];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1)
               fieldName = ['PhaseCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1)
               fieldName = ['TempCoef' calibName(end)];
            end
            calibDataDb.(fieldName) = metaData{idForWmo(idF(id)), 4};
         end
         if (~isempty(calibDataDb))
            metaStruct.CALIBRATION_COEFFICIENT.OPTODE = calibDataDb;
         end
   end
   
   % add the calibration information for SUNA sensor
   if (any(strcmp(metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'SUNA') == 1))
      
      % find the SUNA calibration file
      files = dir([a_sunaConfigDirName '/' num2str(floatList(idFloat)) '_*.cal']);
      if (isempty(files))
         files = dir([a_sunaConfigDirName '/' num2str(floatList(idFloat)) '_*.CAL']);
      end
      if (length(files) == 1)
         
         sunaCalibFileName = [a_sunaConfigDirName '/' files(1).name];
         [creationDate, TEMP_CAL_NITRATE, ...
            OPTICAL_WAVELENGTH_UV, E_NITRATE, E_SWA_NITRATE, E_BISULFIDE, ...
            UV_INTENSITY_REF_NITRATE] = read_suna_calib_file(sunaCalibFileName, dacFormatId);

         if (~isempty(creationDate))
            
            sunaCalibData = [];
            sunaCalibData.TEMP_CAL_NITRATE = TEMP_CAL_NITRATE;
            for id = 1:length(OPTICAL_WAVELENGTH_UV)
               sunaCalibData.(['OPTICAL_WAVELENGTH_UV_' num2str(id)]) = OPTICAL_WAVELENGTH_UV{id};
            end
            for id = 1:length(E_NITRATE)
               sunaCalibData.(['E_NITRATE_' num2str(id)]) = E_NITRATE{id};
            end
            for id = 1:length(E_SWA_NITRATE)
               sunaCalibData.(['E_SWA_NITRATE_' num2str(id)]) = E_SWA_NITRATE{id};
            end
            for id = 1:length(UV_INTENSITY_REF_NITRATE)
               sunaCalibData.(['UV_INTENSITY_REF_NITRATE_' num2str(id)]) = UV_INTENSITY_REF_NITRATE{id};
            end
            
            metaStruct.CALIBRATION_COEFFICIENT.SUNA = sunaCalibData;

         end
      elseif (isempty(files))
         fprintf('WARNING: SUNA calibration file is missing for float %d\n', ...
            floatList(idFloat));
      else
         fprintf('WARNING: many SUNA calibration files for float %d => ignored\n', ...
            floatList(idFloat));
      end
      
   end
   
   % configuration parameters
   
   % retrieve configuration names and values at launch from configuration
   % commands report files
   configReportFileName = [a_configDirName '/' loginName '.txt'];
   [configParamNames, configParamValues] = get_conf_at_launch_cts5(configReportFileName, sensorList);
      
   % delete some configuration parameters
   %   listToDelete = [ ...
   %      {'CONFIG_PI_0'} ...
   %      {'CONFIG_PI_1'} ...
   %      {'CONFIG_PI_2'} ...
   %      ];
   %   for idDel = 1:length(listToDelete)
   %      configParamName = listToDelete{idDel};
   %
   %      idParam = find(strcmp(configParamName, configParamNames) == 1);
   %      if (~isempty(idParam))
   %         configParamNames(idParam) = [];
   %         configParamValues(idParam) = [];
   %      end
   %   end
   
   % add static configuration parameters stored in the data base
   
   dbConfigParamName = [ ...
      {'SUNA_APF_OUTPUT_PIXEL_BEGIN'} ...
      {'SUNA_APF_OUTPUT_PIXEL_END'} ...
      {'ECO_BETA_ANGLE'} ...
      {'ECO_BETA_BANDWIDTH'} ...
      {'ECO_BETA_WAVELENGTH'} ...
      {'ECO_CDOM_FLUO_EMIS_BANDWIDTH'} ...
      {'ECO_CDOM_FLUO_EMIS_WAVELENGTH'} ...
      {'ECO_CDOM_FLUO_EXCIT_BANDWIDTH'} ...
      {'ECO_CDOM_FLUO_EXCIT_WAVELENGTH'} ...
      {'ECO_CHLA_FLUO_EMIS_BANDWIDTH'} ...
      {'ECO_CHLA_FLUO_EMIS_WAVELENGTH'} ...
      {'ECO_CHLA_FLUO_EXCIT_BANDWIDTH'} ...
      {'ECO_CHLA_FLUO_EXCIT_WAVELENGTH'} ...
      {'ECO_VERTICAL_PRES_OFFSET'} ...
      {'OCR_DOWN_IRR_BANDWIDTH'} ...
      {'OCR_DOWN_IRR_WAVELENGTH'} ...
      {'OCR_VERTICAL_PRES_OFFSET'} ...
      {'OPTODE_VERTICAL_PRES_OFFSET'} ...
      {'OPTODE_IN_AIR_MEASUREMENT'} ...
      {'OPTODE_TIME_PRESSURE_OFFSET'} ...
      {'SUNA_VERTICAL_PRES_OFFSET'} ...
      {'SUNA_WITH_SCOOP'} ...
      ];
   
   configParamCode = [ ...
      {'CONFIG_PX_1_6_0_0_3'} ...
      {'CONFIG_PX_1_6_0_0_4'} ...
      {'CONFIG_PX_1_3_0_0_2'} ...
      {'CONFIG_PX_3_3_0_<I>_1'} ...
      {'CONFIG_PX_3_3_0_<I>_0'} ...
      {'CONFIG_PX_2_3_1_0_3'} ...
      {'CONFIG_PX_2_3_1_0_1'} ...
      {'CONFIG_PX_2_3_1_0_2'} ...
      {'CONFIG_PX_2_3_1_0_0'} ...
      {'CONFIG_PX_2_3_0_0_3'} ...
      {'CONFIG_PX_2_3_0_0_1'} ...
      {'CONFIG_PX_2_3_0_0_2'} ...
      {'CONFIG_PX_2_3_0_0_0'} ...
      {'CONFIG_PX_1_3_0_0_0'} ...
      {'CONFIG_PX_3_2_0_<I>_3'} ...
      {'CONFIG_PX_3_2_0_<I>_2'} ...
      {'CONFIG_PX_1_2_0_0_0'} ...
      {'CONFIG_PX_1_1_0_0_0'} ...
      {'CONFIG_PX_1_1_0_0_7'} ...
      {'CONFIG_PX_1_1_0_0_8'} ...
      {'CONFIG_PX_1_6_0_0_0'} ...
      {'CONFIG_PX_1_6_0_0_5'} ...
      ];
   
   for idConfParam = 1:length(dbConfigParamName)
      [dbConfigParamNames, dbConfigParamValues] = get_conf_param( ...
         dbConfigParamName{idConfParam}, configParamCode{idConfParam}, ...
         metaData, idForWmo, dimLevlist);
      if (~isempty(dbConfigParamNames))
         configParamNames = [configParamNames dbConfigParamNames'];
         configParamValues = [configParamValues dbConfigParamValues'];
      end
   end
   
   
   % CONFIG_PARAMETER_NAME
   metaStruct.CONFIG_PARAMETER_NAME = configParamNames';
   
   % CONFIG_PARAMETER_VALUE
   metaStruct.CONFIG_PARAMETER_VALUE = configParamValues';
   
   metaStruct.CONFIG_MISSION_NUMBER = {'0'};
   
   % RT_OFFSET
   idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_PARAMETER') == 1);
   if (~isempty(idF))
      rtOffsetData = [];
      
      rtOffsetParam = [];
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['PARAM_' num2str(dimLevel)];
         rtOffsetParam.(fieldName) = metaData{idForWmo(idF(id)), 4};
      end
      rtOffsetValue = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_COEFFICIENT') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['VALUE_' num2str(dimLevel)];
         value = metaData{idForWmo(idF(id)), 4};
         idPos = strfind(value, 'a0=');
         if (~isempty(idPos))
            rtOffsetValue.(fieldName) = value(idPos+3:end);
         else
            fprintf('ERROR: while parsing CALIB_RT_COEFFICIENT for float %d => exit\n', floatList(idFloat));
            return;
         end
      end
      rtOffsetDate = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_DATE') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['DATE_' num2str(dimLevel)];
         rtOffsetDate.(fieldName) = metaData{idForWmo(idF(id)), 4};
      end
      rtOffsetData.PARAM = rtOffsetParam;
      rtOffsetData.VALUE = rtOffsetValue;
      rtOffsetData.DATE = rtOffsetDate;
      
      metaStruct.RT_OFFSET = rtOffsetData;
   end
   
   % create the directory of json output files
   if ~(exist(a_outputDirName, 'dir') == 7)
      mkdir(a_outputDirName);
   end
   
   % create json output file
   outputFileName = [a_outputDirName '/' sprintf('%d_meta.json', floatList(idFloat))];
   ok = generate_json_file(outputFileName, metaStruct);
   if (~ok)
      return;
   end
   g_cogj_reportData{end+1} = outputFileName;

end

diary off;

return;

% ------------------------------------------------------------------------------
% Get static configuration parameters from data base
%
% SYNTAX :
%  [a_configParamNames, a_configParamValues] = get_conf_param( ...
%    a_dbName, a_confName, ...
%    a_metaData, a_idForWmo, a_dimLevlist)
%
% INPUT PARAMETERS :
%   a_dbName     : names in the DB
%   a_confName   : names in the decoder
%   a_metaData   : DB meta-data information
%   a_idForWmo   : DB meta-data information
%   a_dimLevlist : DB meta-data information
%
% OUTPUT PARAMETERS :
%   a_configParamNames  : list of configuration parameter names
%   a_configParamValues : list of configuration parameter values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
%   09/04/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function [a_configParamNames, a_configParamValues] = get_conf_param( ...
   a_dbName, a_confName, ...
   a_metaData, a_idForWmo, a_dimLevlist)

a_configParamNames = [];
a_configParamValues = [];

idF = find(strcmp(a_metaData(a_idForWmo, 5), a_dbName) == 1);
if (~isempty(idF))
   
   pattern = '<I>';
   idPos = strfind(a_confName, pattern);
   
   if (isempty(idPos))
      a_configParamNames = {a_confName};
      a_configParamValues = {char(a_metaData(a_idForWmo(idF), 4))};
   else
      dimLev = a_dimLevlist(a_idForWmo(idF));
      [~, idSort] = sort(dimLev);
      
      a_configParamNames = cell(length(dimLev), 1);
      a_configParamValues = cell(length(dimLev), 1);
      for id = 1:length(dimLev)
         a_configParamNames{id, 1} = [a_confName(1:idPos-1) num2str(dimLev(id)) a_confName(idPos+length(pattern):end)];
         a_configParamValues{id, 1} = char(a_metaData(a_idForWmo(idF(idSort(id))), 4));
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Get the list of BDD variables associated to float meta-data.
%
% SYNTAX :
%  [o_metaStruct] = get_meta_bdd_struct()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_metaStruct : list of BDD variables
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
%   09/04/2017 - RNU - RT version added
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_bdd_struct()

% output parameters initialization
o_metaStruct = struct( ...
   'ARGO_USER_MANUAL_VERSION', '', ...
   'PLATFORM_NUMBER', '', ...
   'PTT', 'PTT', ...
   'IMEI', 'IMEI', ...
   'TRANS_SYSTEM', 'TRANS_SYSTEM', ...
   'TRANS_SYSTEM_ID', 'TRANS_SYSTEM_ID', ...
   'TRANS_FREQUENCY', 'TRANS_FREQUENCY', ...
   'POSITIONING_SYSTEM', 'POSITIONING_SYSTEM', ...
   'PLATFORM_FAMILY', 'PLATFORM_FAMILY', ...
   'PLATFORM_TYPE', 'PLATFORM_TYPE', ...
   'PLATFORM_MAKER', 'PLATFORM_MAKER', ...
   'FIRMWARE_VERSION', 'FIRMWARE_VERSION', ...
   'MANUAL_VERSION', 'MANUAL_VERSION', ...
   'FLOAT_SERIAL_NO', 'INST_REFERENCE', ...
   'STANDARD_FORMAT_ID', 'STANDARD_FORMAT_ID', ...
   'DAC_FORMAT_ID', 'PR_VERSION', ...
   'WMO_INST_TYPE', 'PR_PROBE_CODE', ...
   'PROJECT_NAME', 'PR_EXPERIMENT_ID', ...
   'DATA_CENTRE', 'DATA_CENTRE', ...
   'PI_NAME', 'PI_NAME', ...
   'ANOMALY', 'ANOMALY', ...
   'BATTERY_TYPE', 'BATTERY_TYPE', ...
   'BATTERY_PACKS', 'BATTERY_PACKS', ...
   'CONTROLLER_BOARD_TYPE_PRIMARY', 'CONTROLLER_BOARD_TYPE_PRIMARY', ...
   'CONTROLLER_BOARD_TYPE_SECONDARY', 'CONTROLLER_BOARD_TYPE_SECONDARY', ...
   'CONTROLLER_BOARD_SERIAL_NO_PRIMARY', 'CONTROLLER_BOARD_SERIAL_NO_PRIMA', ...
   'CONTROLLER_BOARD_SERIAL_NO_SECONDARY', 'CONTROLLER_BOARD_SERIAL_NO_SECON', ...
   'SPECIAL_FEATURES', 'SPECIAL_FEATURES', ...
   'FLOAT_OWNER', 'FLOAT_OWNER', ...
   'OPERATING_INSTITUTION', 'OPERATING_INSTITUTION', ...
   'CUSTOMISATION', 'CUSTOMISATION', ...
   'LAUNCH_DATE', 'PR_LAUNCH_DATETIME', ...
   'LAUNCH_LATITUDE', 'PR_LAUNCH_LATITUDE', ...
   'LAUNCH_LONGITUDE', 'PR_LAUNCH_LONGITUDE', ...
   'LAUNCH_QC', 'LAUNCH_QC', ...
   'START_DATE', 'START_DATE', ...
   'START_DATE_QC', 'START_DATE_QC', ...
   'STARTUP_DATE', '', ...
   'STARTUP_DATE_QC', '', ...
   'DEPLOYMENT_PLATFORM', 'DEPLOY_PLATFORM', ...
   'DEPLOYMENT_CRUISE_ID', 'DEPLOY_MISSION', ...
   'DEPLOYMENT_REFERENCE_STATION_ID', 'DEPLOY_AVAILABLE_PROFILE_ID', ...
   'END_MISSION_DATE', 'END_MISSION_DATE', ...
   'END_MISSION_STATUS', 'END_MISSION_STATUS', ...
   'PREDEPLOYMENT_CALIB_EQUATION', 'PREDEPLOYMENT_CALIB_EQUATION', ...
   'PREDEPLOYMENT_CALIB_COEFFICIENT', 'PREDEPLOYMENT_CALIB_COEFFICIENT', ...
   'PREDEPLOYMENT_CALIB_COMMENT', 'PREDEPLOYMENT_CALIB_COMMENT', ...
   'CALIB_RT_PARAMETER', 'CALIB_RT_PARAMETER', ...
   'CALIB_RT_EQUATION', 'CALIB_RT_EQUATION', ...
   'CALIB_RT_COEFFICIENT', 'CALIB_RT_COEFFICIENT', ...
   'CALIB_RT_COMMENT', 'CALIB_RT_COMMENT', ...
   'CALIB_RT_DATE', 'CALIB_RT_DATE', ...
   'SENSOR_MOUNTED_ON_FLOAT', '', ...
   'CALIBRATION_COEFFICIENT', '', ...
   'FIRST_CYCLE_TO_PROCESS', 'FIRST_CYCLE_TO_PROCESS', ...
   'NEW_DARK_FOR_FLUOROMETER_CHLA', 'NEW_DARK_FOR_FLUOROMETER_CHLA', ...
   'NEW_DARK_FOR_FLUOROMETER_CDOM', 'NEW_DARK_FOR_FLUOROMETER_CDOM', ...
   'NEW_DARK_FOR_SCATTEROMETER_BBP', 'NEW_DARK_FOR_SCATTEROMETER_BBP');

return;
