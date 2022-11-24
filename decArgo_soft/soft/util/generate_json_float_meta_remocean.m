% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in
% individual json files (same as generate_json_float_meta but here,
% configuration parameters and values are retrieved from a configuration
% commands report file).
%
% SYNTAX :
%  generate_json_float_meta_remocean
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/17/2013 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_remocean

% meta-data file exported from Coriolis data base
floatMetaFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150217.txt';
% floatMetaFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150519.txt';
% floatMetaFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\export_JPR_6901866_from_LF_20150715.txt';

fprintf('Generating json meta-data files from input file: %s\n', floatMetaFileName);

% list of concerned floats
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_rem_all.txt';
% floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\rem_with_suna.txt';

fprintf('Generating json meta-data files for floats of the list: %s\n', floatListFileName);

% calibration coefficient file decoded from data
calibFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\Remocean\DataFromFloatToMeta\CalibCoef\calib_coef.txt';

% directory of individual configuration commands report files
configDirName = 'C:\Users\jprannou\_RNU\DecPrv_info\Remocean\ConfigAtLaunch\';

% directory of SUNA calibration files
sunaCalibDirName = 'C:\Users\jprannou\_RNU\DecPrv_info\Remocean\meta_remocean_www\suna_calibration_file\';

% directory of individual json float meta-data files
outputDirName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_' datestr(now, 'yyyymmddTHHMMSS')];

% création et ouverture du fichier log
logFile = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\generate_json_float_meta_remocean_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);


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

if ~(exist(floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', floatMetaFileName);
   return;
end

if ~(exist(configDirName, 'dir') == 7)
   fprintf('ERROR: Directory of configuration commands report files not found: %s\n', configDirName);
   return;
end

% read meta file
fId = fopen(floatMetaFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', floatMetaFileName);
   return;
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';

% get the mapping structure
metaBddStruct = get_meta_bdd_struct();
metaBddStructNames = fieldnames(metaBddStruct);

% process the meta-data to fill the structure
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the sme number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the sme number of digits
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

if ~(exist(floatListFileName, 'file') == 2)
   fprintf('File not found: %s\n', floatListFileName);
   return;
end
refFloatList = load(floatListFileName);

floatList = sort(intersect(floatList, refFloatList));
% floatList = [6901032 6901440];
floatList = [6901865];

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('Meta-data not found for float: %d\n', notFoundFloat);
end

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
   
   % PTT / IMEI specific processing
   if (~isempty(metaStruct.IMEI))
      metaStruct.PTT = metaStruct.IMEI;
   end
   
   %    idF = find(strcmp(metaData(idForWmo, 5), 'PTT') == 1, 1);
   %    if (~isempty(idF))
   %       if (strcmp(metaStruct.TRANS_SYSTEM, 'IRIDIUM'))
   %          if (isempty(metaStruct.PTT))
   %             metaStruct.PTT = metaStruct.IMEI;
   %          end
   %       end
   %    end
   
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
   sensorList = get_sensor_list(wmoNumber);
   metaStruct.SENSOR_MOUNTED_ON_FLOAT = sensorList;
   
   % add the calibration coefficients for ECO3 and OCR sensors (coming from the
   % calibFileName)
   
   % read calib file
   fId = fopen(calibFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Unable to open file: %s\n', calibFileName);
      return;
   end
   calibData = textscan(fId, '%s');
   calibData = calibData{:};
   fclose(fId);
   
   calibData = reshape(calibData, 4, size(calibData, 1)/4)';
   
   idF = find(strcmp(calibData(:, 1), num2str(wmoNumber)) == 1);
   dataStruct = [];
   for id = 1:length(idF)
      fieldName1 = calibData{idF(id), 2};
      %       dataStruct.(fieldName1) = [];
      fieldName2 = calibData{idF(id), 3};
      dataStruct.(fieldName1).(fieldName2) = calibData{idF(id), 4};
   end
   metaStruct.CALIBRATION_COEFFICIENT = dataStruct;
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = getfield(metaStruct, 'DAC_FORMAT_ID');
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d => no json file generated\n', ...
         floatList(idFloat));
      continue;
   end
   
   % add the calibration coefficients for OPTODE sensor (coming from the
   % data base)
   switch (dacFormatId)
      case {'5.91'}
         idF = find((strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_COEFF_A', length('AANDERAA_OPTODE_FOIL_COEFF_A')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_COEFF_B', length('AANDERAA_OPTODE_FOIL_COEFF_B')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_POLYDEG_T', length('AANDERAA_OPTODE_FOIL_POLYDEG_T')) == 1) | ...
            (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_FOIL_POLYDEG_O', length('AANDERAA_OPTODE_FOIL_POLYDEG_O')) == 1));
         calibDataDb = [];
         for id = 1:length(idF)
            calibName = char(metaData(idForWmo(idF(id)), 5));
            if (strncmp(calibName, 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1)
               fieldName = ['TempCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1)
               fieldName = ['PhaseCoef' calibName(end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_COEFF_A', length('AANDERAA_OPTODE_FOIL_COEFF_A')) == 1)
               fieldName = ['FoilCoefA' calibName(length('AANDERAA_OPTODE_FOIL_COEFF_A')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_COEFF_B', length('AANDERAA_OPTODE_FOIL_COEFF_B')) == 1)
               fieldName = ['FoilCoefB' calibName(length('AANDERAA_OPTODE_FOIL_COEFF_B')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_POLYDEG_T', length('AANDERAA_OPTODE_FOIL_POLYDEG_T')) == 1)
               fieldName = ['FoilPolyDegT' calibName(length('AANDERAA_OPTODE_FOIL_POLYDEG_T')+1:end)];
            elseif (strncmp(calibName, 'AANDERAA_OPTODE_FOIL_POLYDEG_O', length('AANDERAA_OPTODE_FOIL_POLYDEG_O')) == 1)
               fieldName = ['FoilPolyDegO' calibName(length('AANDERAA_OPTODE_FOIL_POLYDEG_O')+1:end)];
            end
            calibDataDb.(fieldName) = char(metaData(idForWmo(idF(id)), 4));
         end
         if (~isempty(calibDataDb))
            metaStruct.CALIBRATION_COEFFICIENT.OPTODE = calibDataDb;
         end
      case {'5.92', '6.01', '6.11'}
         idF = find(strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1);
         calibDataDb = [];
         for id = 1:length(idF)
            calibName = char(metaData(idForWmo(idF(id)), 5));
            fieldName = ['SVUFoilCoef' num2str(str2num(calibName(end)))];
            calibDataDb.(fieldName) = char(metaData(idForWmo(idF(id)), 4));
         end
         if (~isempty(calibDataDb))
            metaStruct.CALIBRATION_COEFFICIENT.OPTODE = calibDataDb;
         end
   end
   
   % add the calibration information for SUNA sensor
   if (any(strcmp(metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'SUNA') == 1))
      
      % find the SUNA calibration file
      files = dir([sunaCalibDirName '/' num2str(floatList(idFloat)) '_*.cal']);
      if (length(files) == 1)
         
         sunaCalibFileName = [sunaCalibDirName '/' files(1).name];
         [creationDate, TEMP_CAL_NITRATE, ...
            OPTICAL_WAVELENGTH_UV, E_NITRATE, E_SWA_NITRATE, ...
            UV_INTENSITY_REF_NITRATE] = read_suna_calib_file(sunaCalibFileName);
         
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
   configReportFileName = [configDirName '/' metaStruct.PLATFORM_NUMBER '_2.txt'];
   configDefaultFilename = [configDirName '/defaultConfiguration.txt'];
   [configParamNames, configParamValues] = read_conf_cmd_report(configReportFileName, configDefaultFilename, sensorList);
   
   idF = find(strcmp('CONFIG_PT_27', configParamNames) ==1, 1);
   if (~isempty(idF))
      % this coefficient is transmitted without any digit, consequently to avoid
      % creating one useless configuration we truncate this parameter for the
      % launch configuration
      configParamValues{idF} = num2str(fix(str2num(configParamValues{idF})));
   end
   
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
      {'VECTOR_BOARD_SHOW_MODE_STATE'} ...
      {'SENSOR_BOARD_SHOW_MODE_STATE'} ...
      {'SUNA_APF_OUTPUT_PIXEL_BEGIN'} ...
      {'SUNA_APF_OUTPUT_PIXEL_END'} ...
      {'CROVER_IN_PUMPED_STREAM'} ...
      {'CROVER_BEAM_ATT_WAVELENGTH'} ...
      {'CROVER_VERTICAL_PRES_OFFSET'} ...
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
      {'SUNA_VERTICAL_PRES_OFFSET'} ...
      {'SUNA_WITH_SCOOP'} ...
      ];
   
   configParamCode = [ ...
      {'CONFIG_PX_0_0_0_0_0'} ...
      {'CONFIG_PX_0_0_0_0_1'} ...
      {'CONFIG_PX_1_6_0_0_3'} ...
      {'CONFIG_PX_1_6_0_0_4'} ...
      {'CONFIG_PX_1_5_0_0_1'} ...
      {'CONFIG_PX_1_5_0_0_6'} ...
      {'CONFIG_PX_1_5_0_0_0'} ...
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
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
   
   % create the json output files
   outputFileName = [outputDirName '/' sprintf('%d_meta.json', floatList(idFloat))];
   fidOut = fopen(outputFileName, 'wt');
   if (fidOut == -1)
      fprintf('ERROR: Unable to create json output file: %s\n', outputFileName);
      return;
   end
   
   fprintf(fidOut, '{\n');
   
   metaStructNames = fieldnames(metaStruct);
   for idBSN = 1:length(metaStructNames)
      fprintf(fidOut, '   "%s" : ', metaStructNames{idBSN});
      if (strcmp(metaStructNames{idBSN}, 'CALIBRATION_COEFFICIENT') == 1)
         fieldVal = getfield(metaStruct, metaStructNames{idBSN});
         if (isempty(fieldVal) || (isa(fieldVal, 'struct')))
            fprintf(fidOut, '[ \n');
            if (~isempty(fieldVal))
               fprintf(fidOut, '      {\n');
               fieldSubVal = fieldnames(fieldVal);
               for idDim1 = 1:size(fieldSubVal, 1)
                  fprintf(fidOut, '      "%s" :\n', ...
                     fieldSubVal{idDim1});
                  fprintf(fidOut, '         {\n');
                  fieldSubVal2 = fieldnames(fieldVal.(fieldSubVal{idDim1}));
                  for idDim2 = 1:size(fieldSubVal2, 1)
                     fprintf(fidOut, '            "%s" : %s', ...
                        fieldSubVal2{idDim2}, ...
                        fieldVal.(fieldSubVal{idDim1}).(fieldSubVal2{idDim2}));
                     if (idDim2 < size(fieldSubVal2, 1))
                        fprintf(fidOut, ',\n');
                     else
                        fprintf(fidOut, '\n');
                     end
                  end
                  if (idDim1 < size(fieldSubVal, 1))
                     fprintf(fidOut, '         },\n');
                  else
                     fprintf(fidOut, '         }\n');
                  end
               end
               fprintf(fidOut, '      }\n');
            end
            if (idBSN < length(metaStructNames))
               fprintf(fidOut, '   ],\n');
            else
               fprintf(fidOut, '   ]\n');
            end
         end
      elseif (strcmp(metaStructNames{idBSN}, 'RT_OFFSET') == 1)
         fieldVal = getfield(metaStruct, metaStructNames{idBSN});
         if (isempty(fieldVal) || (isa(fieldVal, 'struct')))
            fprintf(fidOut, '[ \n');
            if (~isempty(fieldVal))
               fprintf(fidOut, '      {\n');
               fieldSubVal = fieldnames(fieldVal);
               for idDim1 = 1:size(fieldSubVal, 1)
                  fprintf(fidOut, '      "%s" :\n', ...
                     fieldSubVal{idDim1});
                  fprintf(fidOut, '         {\n');
                  fieldSubVal2 = fieldnames(fieldVal.(fieldSubVal{idDim1}));
                  for idDim2 = 1:size(fieldSubVal2, 1)
                     fprintf(fidOut, '            "%s" : "%s"', ...
                        fieldSubVal2{idDim2}, ...
                        fieldVal.(fieldSubVal{idDim1}).(fieldSubVal2{idDim2}));
                     if (idDim2 < size(fieldSubVal2, 1))
                        fprintf(fidOut, ',\n');
                     else
                        fprintf(fidOut, '\n');
                     end
                  end
                  if (idDim1 < size(fieldSubVal, 1))
                     fprintf(fidOut, '         },\n');
                  else
                     fprintf(fidOut, '         }\n');
                  end
               end
               fprintf(fidOut, '      }\n');
            end
            if (idBSN < length(metaStructNames))
               fprintf(fidOut, '   ],\n');
            else
               fprintf(fidOut, '   ]\n');
            end
         end
      else
         fieldVal = getfield(metaStruct, metaStructNames{idBSN});
         if (isa(fieldVal, 'char'))
            fprintf(fidOut, '"%s", \n', char(fieldVal));
         else
            if (isempty(fieldVal) || (isa(fieldVal, 'cell')))
               fprintf(fidOut, '[ \n');
               for idDim2 = 1:size(fieldVal, 2)
                  fprintf(fidOut, '      {\n');
                  for idDim1 = 1:size(fieldVal, 1)
                     fieldSubVal = char(fieldVal{idDim1, idDim2});
                     if (size(fieldVal, 2) == 1)
                        fprintf(fidOut, '      "%s_%d" : "%s"', ...
                           metaStructNames{idBSN}, ...
                           idDim1, ...
                           fieldSubVal);
                     else
                        fprintf(fidOut, '      "%s_%d_%d" : "%s"', ...
                           metaStructNames{idBSN}, ...
                           idDim1, ...
                           idDim2, ...
                           fieldSubVal);
                     end
                     if (idDim1 < size(fieldVal, 1))
                        fprintf(fidOut, ',\n');
                     else
                        fprintf(fidOut, '\n');
                     end
                  end
                  if (idDim2 < size(fieldVal, 2))
                     fprintf(fidOut, '      },\n');
                  else
                     fprintf(fidOut, '      }\n');
                  end
               end
               if (idBSN < length(metaStructNames))
                  fprintf(fidOut, '   ],\n');
               else
                  fprintf(fidOut, '   ]\n');
               end
            else
               fprintf('ERROR\n');
            end
         end
      end
   end
   
   fprintf(fidOut, '}\n');
   
   fclose(fidOut);
end

diary off;

return;

% ------------------------------------------------------------------------------
function [o_metaStruct] = add_multi_dim_data( ...
   a_itemList, ...
   a_metaData, a_idForWmo, a_dimLevlist, ...
   a_metaStruct, a_mandatoryList1, a_mandatoryList2)

o_metaStruct = a_metaStruct;

dimLevListAll = [];
for idItem = 1:length(a_itemList)
   idF = find(strcmp(a_metaData(a_idForWmo, 5), a_itemList{idItem}) == 1);
   if (~isempty(idF))
      dimLevListAll = [dimLevListAll a_dimLevlist(a_idForWmo(idF))'];
   end
end
dimLevListAll = sort(unique(dimLevListAll));

for idItem = 1:length(a_itemList)
   idF = find(strcmp(a_metaData(a_idForWmo, 5), a_itemList{idItem}) == 1);
   if (~isempty(idF))
      val = cell(length(dimLevListAll), 1);
      dimLevList = a_dimLevlist(a_idForWmo(idF));
      for idL = 1:length(dimLevList)
         idLev = find(dimLevListAll == dimLevList(idL));
         val{idLev, 1} = char(a_metaData(a_idForWmo(idF(idL)), 4));
      end
      for idL = 1:length(dimLevListAll)
         if (isempty(val{idL, 1}))
            if (~isempty(find(strcmp(a_mandatoryList1, a_itemList{idItem}) == 1, 1)))
               val{idL, 1} = 'n/a';
            elseif (~isempty(find(strcmp(a_mandatoryList2, a_itemList{idItem}) == 1, 1)))
               val{idL, 1} = 'UNKNOWN';
            end
         end
      end
      o_metaStruct.(a_itemList{idItem}) = val;
   else
      if (~isempty(find(strcmp(a_mandatoryList1, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'n/a';
         end
         o_metaStruct.(a_itemList{idItem}) = val;
      elseif (~isempty(find(strcmp(a_mandatoryList2, a_itemList{idItem}) == 1, 1)))
         val = cell(length(dimLevListAll), 1);
         for idL = 1:length(dimLevListAll)
            val{idL, 1} = 'UNKNOWN';
         end
         o_metaStruct.(a_itemList{idItem}) = val;
      end
   end
end

% idF = find(strcmp(a_metaData(a_idForWmo, 5), a_item) == 1);
% if (~isempty(idF))
%    dimLev = a_dimLevlist(a_idForWmo(idF));
%    [unused idSort] = sort(dimLev);
%    val = cell(length(dimLev), 1);
%    for id = 1:length(dimLev)
%       val{id, 1} = char(a_metaData(a_idForWmo(idF(idSort(id))), 4));
%    end
%    o_metaStruct = setfield(o_metaStruct, a_item, val);
% end

return;

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
   'CALIBRATION_COEFFICIENT', '');

return;
