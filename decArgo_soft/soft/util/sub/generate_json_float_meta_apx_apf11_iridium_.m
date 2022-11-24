% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_apx_apf11_iridium_( ...
%    a_floatMetaFileName, a_sensorListFileName, a_floatListFileName, ...
%    a_calibFileName, a_configDirName, a_outputDirName, a_csvDirName, a_rudicsFlag)
%
% INPUT PARAMETERS :
%   a_floatMetaFileName  : meta-data file exported from Coriolis data base
%   a_sensorListFileName : list of sensors mounted on floats
%   a_floatListFileName  : list of concerned floats
%   a_calibFileName      : list of calibration coefficient
%   a_configDirName      : directory of float configuration at launch files
%   a_outputDirName      : directory of individual json float meta-data files
%   a_csvDirName         : directory to store the CSV file (when DB update is needed)
%   a_rudicsFlag         : 1 if it is a RUDICS transmission, 0 for a SBD
%                          transmission
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_apx_apf11_iridium_( ...
   a_floatMetaFileName, a_sensorListFileName, a_floatListFileName, ...
   a_calibFileName, a_configDirName, a_outputDirName, a_csvDirName, a_rudicsFlag)

% report information structure
global g_cogj_reportData;

% file to store DB update
csvFileId = -1;


% check inputs
fprintf('Generating json meta-data files from input file: \n FLOAT_META_FILE_NAME = %s\n', a_floatMetaFileName);

if ~(exist(a_floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', a_floatMetaFileName);
   return
end

fprintf('Using sensor list from file: \n SENSOR_LIST_FILE_NAME = %s\n', a_sensorListFileName);

if ~(exist(a_sensorListFileName, 'file') == 2)
   fprintf('ERROR: Sensor list file not found: %s\n', a_sensorListFileName);
   return
end

fprintf('Generating json meta-data files for floats of the list: \n FLOAT_LIST_FILE_NAME = %s\n', a_floatListFileName);

if ~(exist(a_floatListFileName, 'file') == 2)
   fprintf('ERROR: Float file list not found: %s\n', a_floatListFileName);
   return
end

fprintf('Calibration coefficient file: \n CALIB_FILE_NAME = %s\n', a_calibFileName);

if ~(exist(a_calibFileName, 'file') == 2)
   fprintf('ERROR: Float file list not found: %s\n', a_calibFileName);
   return
end

fprintf('Directory of float launch configuration files used: \n CONFIG_DIR_NAME = %s\n', a_configDirName);

if ~(exist(a_configDirName, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', a_configDirName);
   return
end

fprintf('Output directory of json meta-data files: \n OUTPUT_DIR_NAME = %s\n', a_outputDirName);

fprintf('Output directory of CSV files for data to be updated in DB: \n DIR_CSV_FILE = %s\n', a_csvDirName);

% lists of mandatory meta-data
% FLOAT_SERIAL_NO and SENSOR_SERIAL_NO should not be in the following list
% (only the database can set these mandatory values to 'n/a')
mandatoryList1 = [ ...
   {'BATTERY_TYPE'} ...
   {'CONTROLLER_BOARD_SERIAL_NO_PRIMARY'} ...
   {'CONTROLLER_BOARD_TYPE_PRIMARY'} ...
   {'DAC_FORMAT_ID'} ...
   {'FIRMWARE_VERSION'} ...
   {'MANUAL_VERSION'} ...
   {'PI_NAME'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PTT'} ...
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
   return
end
fileContents = textscan(fId, '%s', 'delimiter', '\t');
fileContents = fileContents{:};
fclose(fId);

fileContents = regexprep(fileContents, '"', '');

metaData = reshape(fileContents, 5, size(fileContents, 1)/5)';
metaData(:,4)=(cellfun(@strtrim, metaData(:, 4), 'UniformOutput', 0))';

% read calib file
fId = fopen(a_calibFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_calibFileName);
   return
end
calibData = textscan(fId, '%s');
calibData = calibData{:};
fclose(fId);

calibData = reshape(calibData, 4, size(calibData, 1)/4)';

% get sensor list
[wmoSensorList, nameSensorList] = get_sensor_list(a_sensorListFileName);

% get the mapping structure
metaBddStruct = get_meta_bdd_struct();
metaBddStructNames = fieldnames(metaBddStruct);

% process the meta-data to fill the structure
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('ERROR: %s is not a valid WMO number\n', wmoList{id});
      return
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
% floatList = [3901592];

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('WARNING: Meta-data not found for float: %d\n', notFoundFloat);
end

% process floats
for idFloat = 1:length(floatList)
   
   skipFloat = 0;
   floatNum = floatList(idFloat);
   fprintf('%3d/%3d %d\n', idFloat, length(floatList), floatNum);
   
   % initialize the structure to be filled
   metaStruct = get_meta_init_struct();
   
   metaStruct.PLATFORM_NUMBER = num2str(floatNum);
   metaStruct.ARGO_USER_MANUAL_VERSION = '3.1';
   
   % direct conversion data
   idForWmo = find(wmoList == floatNum);
   for idBSN = 1:length(metaBddStructNames)
      metaBddStructField = metaBddStructNames{idBSN};
      metaBddStructValue = metaBddStruct.(metaBddStructField);
      if (~isempty(metaBddStructValue))
         idF = find(strcmp(metaData(idForWmo, 5), metaBddStructValue) == 1, 1);
         if (~isempty(idF))
            metaStruct.(metaBddStructField) = metaData{idForWmo(idF), 4};
         else
            if (~isempty(find(strcmp(mandatoryList1, metaBddStructField) == 1, 1)))
               if (strcmp(metaBddStructField, 'CONTROLLER_BOARD_TYPE_PRIMARY'))
                  metaStruct.(metaBddStructField) = 'APF11';
               else
                  metaStruct.(metaBddStructField) = 'n/a';
               end
               %                fprintf('Empty mandatory meta-data ''%s'' set to ''n/a''\n', metaBddStructValue);
            elseif (~isempty(find(strcmp(mandatoryList2, metaBddStructField) == 1, 1)))
               metaStruct.(metaBddStructField) = 'UNKNOWN';
            end
            if (strcmp(metaBddStructField, 'FLOAT_SERIAL_NO'))
               fprintf('ERROR: Float #%d: FLOAT_SERIAL_NO (''%s'') is mandatory => no json file generated\n', ...
                  floatNum, metaBddStructValue);
               skipFloat = 1;
            end
         end
      end
   end
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = metaStruct.DAC_FORMAT_ID;
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d => no json file generated\n', ...
         floatNum);
      continue
   end
   
   % check if the float version is concerned by this tool
   if (a_rudicsFlag == 0)
      if (~ismember(dacFormatId, [{'2.10.1.S'} {'2.11.1.S'} {'2.11.3.S'} {'2.12.2.1.S'}]))
         fprintf('INFO: Float %d is not managed by this tool (DAC_FORMAT_ID (from PR_VERSION) : ''%s'')\n', ...
            floatNum, dacFormatId);
         continue
      end
   else
      if (~ismember(dacFormatId, [{'2.10.4.R'} {'2.11.3.R'}]))
         fprintf('INFO: Float %d is not managed by this tool (DAC_FORMAT_ID (from PR_VERSION) : ''%s'')\n', ...
            floatNum, dacFormatId);
         continue
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
   
   % check that SENSOR_SERIAL_NO is set
   if (~isempty(metaStruct.SENSOR_SERIAL_NO))
      for idS = 1:length(metaStruct.SENSOR_SERIAL_NO)
         if (isempty(metaStruct.SENSOR_SERIAL_NO{idS}))
            fprintf('ERROR: Float #%d: SENSOR_SERIAL_NO is mandatory (for SENSOR=''%s'' SENSOR_MODEL=''%s'' SENSOR_MAKER=''%s'') => no json file generated\n', ...
               floatNum, ...
               metaStruct.SENSOR{idS}, ...
               metaStruct.SENSOR_MODEL{idS}, ...
               metaStruct.SENSOR_MAKER{idS});
            skipFloat = 1;
         end
      end
   else
      fprintf('ERROR: Float #%d: SENSOR_SERIAL_NO is mandatory => no json file generated\n', ...
         floatNum);
      skipFloat = 1;
   end
   
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
   
   if (a_rudicsFlag == 0)
      % IMEI / PTT specific processing
      if (~isempty(metaStruct.IMEI))
         if (length(metaStruct.IMEI) ~= 15)
            fprintf('ERROR: Float #%d: inconsistent IMEI number (''%s''); 15 digits expected\n', ...
               floatNum, metaStruct.IMEI);
         else
            if (~strcmp(metaStruct.PTT, 'n/a'))
               if (length(metaStruct.PTT) ~= 6)
                  fprintf('ERROR: Float #%d: inconsistent PTT number (''%s''); 6 digits expected\n', ...
                     floatNum, metaStruct.PTT);
               else
                  if (~strcmp(metaStruct.IMEI(end-6:end-1), metaStruct.PTT))
                     fprintf('ERROR: Float #%d: inconsistent IMEI number (''%s'') VS PTT number (''%s'')\n', ...
                        floatNum, metaStruct.IMEI, metaStruct.PTT);
                  end
               end
            else
               metaStruct.PTT = metaStruct.IMEI(end-6:end-1);
               fprintf('INFO: Float #%d: PTT number (''%s'') set from IMEI number (''%s'')\n', ...
                  floatNum, metaStruct.PTT, metaStruct.IMEI);
            end
         end
      elseif (~strcmp(metaStruct.PTT, 'n/a'))
         fprintf('WARNING: Float #%d: PTT number (''%s'') is set but IMEI number is unknown\n', ...
            floatNum, metaStruct.PTT);
      end
   end
   
   % add the list of the sensor mounted on the float (because SENSOR variable is
   % not correctly filled yet), this list is used by the decoder to check the
   % expected data
   idSensor = find(wmoSensorList == floatNum);
   if (isempty(idSensor))
      fprintf('ERROR: Unknown sensor list for float #%d => nothing done for this float (PLEASE UPDATE "%s" file)\n', ...
         floatNum, a_sensorListFileName);
      continue
   end
   sensorList = nameSensorList(idSensor);
   if (length(sensorList) ~= length(unique(sensorList)))
      fprintf('ERROR: Duplicated sensors for float #%d => nothing done for this float (PLEASE CHECK "%s" file)\n', ...
         floatNum, a_sensorListFileName);
      continue
   end
   metaStruct.SENSOR_MOUNTED_ON_FLOAT = sensorList;
   
   % add the calibration coefficients for ECO3 and OCR sensors (coming from the
   % a_calibFileName)
   
   idF = find(strcmp(calibData(:, 1), num2str(floatNum)) == 1);
   dataStruct = [];
   for id = 1:length(idF)
      fieldName1 = calibData{idF(id), 2};
      %       dataStruct.(fieldName1) = [];
      fieldName2 = calibData{idF(id), 3};
      dataStruct.(fieldName1).(fieldName2) = calibData{idF(id), 4};
   end
   metaStruct.CALIBRATION_COEFFICIENT = dataStruct;   
   
   % add the calibration coefficients for OPTODE sensor (coming from the data base)
   switch (dacFormatId)
      case {'2.11.1.S', '2.11.3.S', '2.12.2.1.S', '2.11.3.R'}
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
   
   % add the calibration information for TRANSISTOR_PH sensor
   if (any(strcmp(metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'TRANSISTOR_PH') == 1))
      
      idF = find((strncmp(metaData(idForWmo, 5), 'SBE_TRANSISTOR_PH_', length('SBE_TRANSISTOR_PH_')) == 1));
      phCalibData = [];
      for id = 1:length(idF)
         calibName = metaData{idForWmo(idF(id)), 5};
         if (strncmp(calibName, 'SBE_TRANSISTOR_PH_K', length('SBE_TRANSISTOR_PH_K')) == 1)
            fieldName = ['k' calibName(end)];
         elseif (strncmp(calibName, 'SBE_TRANSISTOR_PH_F', length('SBE_TRANSISTOR_PH_F')) == 1)
            fieldName = ['f' calibName(end)];
         end
         phCalibData.(fieldName) = metaData{idForWmo(idF(id)), 4};
      end
      if (~isempty(phCalibData))
         metaStruct.CALIBRATION_COEFFICIENT.TRANSISTOR_PH = phCalibData;
      end
   end
   
   % configuration parameters
   
   % read launch configuration information
   [missionConfData, systemConfData, sensorsConfData, sampleConfData] = ...
      get_config_at_launch_apex_apf11(a_configDirName, floatNum);
   
   % check that mission and system configuration data are already in the data
   % base
   for idSet = 1:2
      if (idSet == 1)
         if (~isempty(missionConfData))
            confData = missionConfData;
         else
            continue
         end
      else
         if (~isempty(systemConfData))
            confData = systemConfData;
         else
            continue
         end
      end
      
      % launch configuration names
      confNames = fieldnames(confData);
      
      % link between float configuration and decoder configuration
      configFloatStruct = get_config_float_struct(dacFormatId);
      if (isempty(configFloatStruct))
         continue
      end
      % link between decoder configuration and BDD static configuration
      metaBddStruct = get_meta_bdd_struct;
      
      % link between decoder configuration and BDD dynamic configuration
      configBddStruct = get_config_bdd_struct(dacFormatId);
      if (isempty(configBddStruct))
         continue
      end
      
      for idC = 1:length(confNames)
         bddConfName = [];
         floatConfName = confNames{idC};
         if (strcmp(floatConfName, 'iridium')) % see 6903699 & 6903700
            continue
         end
         if (length(confData.(floatConfName)) > 1)
            if (strcmp(floatConfName, 'AscentStartTimes'))
               if (length(unique(confData.(floatConfName))) == 1)
                  floatConfValue = confData.(floatConfName){1};
               else
                  valueList = confData.(floatConfName);
                  idDel = find(strcmp(confData.(floatConfName), '-1'));
                  valueList(idDel) = [];
                  if (length(unique(valueList)) == 1)
                     floatConfValue = valueList{1};
                  else
                     fprintf('ERROR: Float #%d: don''t know how to manage ''%s'' configuration multiple values\n', ...
                        floatNum, floatConfName);
                  end
               end
            else
               fprintf('ERROR: Float #%d: don''t know how to manage ''%s'' configuration multiple values\n', ...
                  floatNum, floatConfName);
            end
         else
            floatConfValue = confData.(floatConfName){:};
         end
         if (strcmpi(floatConfValue, 'on'))
            floatConfValue = 'yes';
         end
         if (strcmpi(floatConfValue, 'off'))
            floatConfValue = 'no';
         end
         
         if (isfield(configFloatStruct, floatConfName))
            decConfName = configFloatStruct.(floatConfName);
            if (~isempty(decConfName))
               
               if (strncmp(decConfName, 'CONFIG_', length('CONFIG_')))
                  % it is a configuration parameter
                  bddConfName = configBddStruct.(decConfName);
               else
                  % it is a meta-data parameter
                  bddConfName = metaBddStruct.(decConfName);
               end
            end
         end
         
         if (~isempty(bddConfName))
            
            if (ismember(bddConfName, [{'ActiveIceDetectionMonth'} {'VitalsMask'}]))
               floatConfValue = ['0x' floatConfValue];
            end
            
            nbLoops = 1;
            if (strcmp(floatConfName, 'float_id'))
               nbLoops = 2;
            end
            for idL = 1:nbLoops
               if (idL == 2)
                  bddConfName = 'FLOAT_RUDICS_ID';
               end
               diffFlag = -1;
               idF = find(strcmp(metaData(idForWmo, 5), bddConfName) & (dimLevlist(idForWmo) == 1));
               if (~isempty(idF))
                  bddConfvalue = metaData{idForWmo(idF), 4};
                  
                  % compare both values
                  [floatValue, status] = str2num(floatConfValue);
                  if (status == 1)
                     bddValue = str2num(bddConfvalue);
                     
                     if (~isempty(bddValue))
                        if (floatValue ~= bddValue)
                           diffFlag = 1;
                        end
                     else
                        diffFlag = 1;
                     end
                  else
                     if (~strcmp(floatConfValue, bddConfvalue))
                        diffFlag = 1;
                     end
                  end
               else
                  diffFlag = 0;
               end
               
               if (diffFlag ~= -1)
                  if (csvFileId == -1)
                     % output CSV file creation
                     csvFilePathName = [a_csvDirName '/data_to_update_bdd_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
                     csvFileId = fopen(csvFilePathName, 'wt');
                     if (csvFileId == -1)
                        fprintf('ERROR: Unable to create CSV output file: %s\n', csvFilePathName);
                        return
                     end
                     
                     header = 'PLATFORM_CODE;TECH_PARAMETER_ID;DIM_LEVEL;CORIOLIS_TECH_METADATA.PARAMETER_VALUE;TECH_PARAMETER_CODE';
                     fprintf(csvFileId, '%s\n', header);
                  end
                  
                  fprintf(csvFileId, '%d;%d;%d; %s;%s\n', ...
                     floatNum, ...
                     get_tech_id(bddConfName), 1, floatConfValue, bddConfName);
                  
                  if (diffFlag == 0)
                     fprintf('WARNING: Float #%d: MISSING: Meta-data ''%s'': launch float value (''%s'') is missing in the data base => DB contents should be updated (see %s)\n', ...
                        floatNum, ...
                        bddConfName, ...
                        floatConfValue, ...
                        csvFilePathName);
                  else
                     fprintf('WARNING: Float #%d: DIFFER: Meta-data ''%s'': launch float value (''%s'') and data base value (''%s'') differ => DB contents should be updated (see %s)\n', ...
                        floatNum, ...
                        bddConfName, ...
                        floatConfValue, ...
                        bddConfvalue, ...
                        csvFilePathName);
                  end
               end
            end
         end
      end
   end
   
   % CONFIG_PARAMETER_NAME & CONFIG_PARAMETER_VALUE
   
   % link between decoder configuration and BDD dynamic configuration
   configBddStruct = get_config_bdd_struct(dacFormatId);
   if (isempty(configBddStruct))
      continue
   end
   
   configBddStructNames = fieldnames(configBddStruct);
   configParamVal = cell(length(configBddStructNames), 1);
   configRepRate = {'1'};
   for idBSN = 1:length(configBddStructNames)
      configBddStructName = configBddStructNames{idBSN};
      configBddStructValue = configBddStruct.(configBddStructName);
      if (~isempty(configBddStructValue))
         
         idF = find(strcmp(metaData(idForWmo, 5), configBddStructValue) == 1, 1);
         if (~isempty(idF))
            dimLev = dimLevlist(idForWmo(idF));
            idDim = find(dimLev == 1, 1);
            if (isempty(idDim))
               idDim = 1;
            end
            
            if (strcmp(configBddStructValue, 'DIRECTION'))
               bddValue = metaData{idForWmo(idF), 4};
               if (~isempty(bddValue))
                  if (bddValue == 'A')
                     configParamVal{idBSN} = '1';
                  elseif (bddValue == 'B')
                     configParamVal{idBSN} = '3';
                  elseif (bddValue == 'D')
                     configParamVal{idBSN} = '2';
                  else
                     fprintf('ERROR: inconsistent BDD value (''%s'') for ''%s'' information => not considered\n', ...
                        bddValue, 'DIRECTION');
                  end
               end
            elseif (strcmp(configBddStructValue, 'ActivateRecoveryModeFlag') || ...
                  strcmp(configBddStructValue, 'DEEP_PROFILE_FIRST') || ...
                  strcmp(configBddStructValue, 'LeakDetectFlag') || ...
                  strcmp(configBddStructValue, 'PreludeSelfTestFlag'))
               bddValue = metaData{idForWmo(idF), 4};
               if (~isempty(bddValue))
                  if ((strcmpi(bddValue, 'yes')) || (strcmpi(bddValue, 'y')))
                     configParamVal{idBSN} = '1';
                  elseif ((strcmpi(bddValue, 'no')) || (strcmpi(bddValue, 'n')))
                     configParamVal{idBSN} = '0';
                  else
                     fprintf('ERROR: inconsistent BDD value (''%s'') for ''%s'' information => not considered\n', ...
                        bddValue, configBddStructValue);
                  end
               end
            else
               configParamVal{idBSN} = metaData{idForWmo(idF), 4};
            end
            
         end
      else
         % if we want to use default values if the information is
         % missing in the database
      end
   end
   
   metaStruct.CONFIG_PARAMETER_NAME = configBddStructNames;
   metaStruct.CONFIG_REPETITION_RATE = configRepRate;
   metaStruct.CONFIG_PARAMETER_VALUE = configParamVal;
   
   % add configuration parameters from sample.cfg file
   if (~isempty(sampleConfData))
      [configSampName, configSampVal] = create_sampling_configuration(sampleConfData);
      metaStruct.CONFIG_PARAMETER_NAME = [metaStruct.CONFIG_PARAMETER_NAME; configSampName'];
      metaStruct.CONFIG_PARAMETER_VALUE = [metaStruct.CONFIG_PARAMETER_VALUE; configSampVal'];
   end
   
      % add static configuration parameters stored in the data base
   dbConfigParamName = [ ...
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
      {'OPTODE_IN_AIR_MEASUREMENT'} ...
      {'OPTODE_TIME_PRESSURE_OFFSET'} ...
      {'SUNA_VERTICAL_PRES_OFFSET'} ...
      {'SUNA_WITH_SCOOP'} ...
      {'SEAFET_VERTICAL_PRES_OFFSET'} ...
      ];
   
   configParamCode = [ ...
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
      {'CONFIG_PX_1_1_0_0_7'} ...
      {'CONFIG_PX_1_1_0_0_8'} ...
      {'CONFIG_PX_1_6_0_0_0'} ...
      {'CONFIG_PX_1_6_0_0_5'} ...
      {'CONFIG_PX_1_4_0_0_0'} ...
      ];
   
   for idConfParam = 1:length(dbConfigParamName)
      [dbConfigParamNames, dbConfigParamValues] = get_conf_param( ...
         dbConfigParamName{idConfParam}, configParamCode{idConfParam}, ...
         metaData, idForWmo, dimLevlist);
      if (~isempty(dbConfigParamNames))
         for id = 1:length(dbConfigParamValues)
            if ((strcmpi(dbConfigParamValues{id}, 'yes')) || (strcmpi(dbConfigParamValues{id}, 'y')))
               dbConfigParamValues{id} = '1';
            elseif ((strcmpi(dbConfigParamValues{id}, 'no')) || (strcmpi(dbConfigParamValues{id}, 'n')))
               dbConfigParamValues{id} = '0';
            end
         end
         
         metaStruct.CONFIG_PARAMETER_NAME = [metaStruct.CONFIG_PARAMETER_NAME; dbConfigParamNames];
         metaStruct.CONFIG_PARAMETER_VALUE = [metaStruct.CONFIG_PARAMETER_VALUE; dbConfigParamValues];
      end
   end
   
   % RT_OFFSET
   idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_PARAMETER') == 1);
   if (~isempty(idF))
      rtOffsetData = [];
      
      dimLevelParam = [];
      dimLevelValueSlope = [];
      dimLevelDate = [];
      rtOffsetParam = [];
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['PARAM_' num2str(dimLevel)];
         rtOffsetParam.(fieldName) = metaData{idForWmo(idF(id)), 4};
         dimLevelParam = [dimLevelParam dimLevel];
      end
      rtOffsetSlope = [];
      rtOffsetValue = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_COEFFICIENT') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldNameValue = ['VALUE_' num2str(dimLevel)];
         fieldNameSlope = ['SLOPE_' num2str(dimLevel)];
         coefStrOri = metaData{idForWmo(idF(id)), 4};
         coefStr = regexprep(coefStrOri, ' ', '');
         idPos1 = strfind(coefStr, 'a1=');
         idPos2 = strfind(coefStr, ',a0=');
         if (~isempty(idPos1) && ~isempty(idPos2))
            rtOffsetSlope.(fieldNameSlope) = coefStr(idPos1+3:idPos2-1);
            rtOffsetValue.(fieldNameValue) = coefStr(idPos2+4:end);
            [~, statusSlope] = str2num(rtOffsetSlope.(fieldNameSlope));
            [~, statusValue] = str2num(rtOffsetValue.(fieldNameValue));
            if ((statusSlope == 0) || (statusValue == 0))
               fprintf('ERROR: non numerical CALIB_RT_COEFFICIENT for float %d (''%s'') => exit\n', ...
                  floatNum, coefStrOri);
               return
            end
            dimLevelValueSlope = [dimLevelValueSlope dimLevel];
         else
            fprintf('ERROR: while parsing CALIB_RT_COEFFICIENT for float %d (found: ''%s'') => exit\n', ...
               floatNum, coefStrOri);
            return
         end
      end
      rtOffsetDate = [];
      idF = find(strcmp(metaData(idForWmo, 5), 'CALIB_RT_DATE') == 1);
      for id = 1:length(idF)
         dimLevel = str2num(metaData{idForWmo(idF(id)), 3});
         fieldName = ['DATE_' num2str(dimLevel)];
         rtOffsetDate.(fieldName) = metaData{idForWmo(idF(id)), 4};
         dimLevelDate = [dimLevelDate dimLevel];
      end
      
      % check inputs
      if (~isempty(setdiff(dimLevelParam, dimLevelValueSlope)))
         missingDimLev = setdiff(dimLevelParam, dimLevelValueSlope);
         for idD = 1:length(missingDimLev)
            fprintf('ERROR: float %d no CALIB_RT_COEFFICIENT provided for DIM_LEVEL %d => exit\n', ...
               floatNum, missingDimLev(idD));
         end
         return
      elseif (~isempty(setdiff(dimLevelValueSlope, dimLevelParam)))
         missingDimLev = setdiff(dimLevelValueSlope, dimLevelParam);
         for idD = 1:length(missingDimLev)
            fprintf('ERROR: float %d no CALIB_RT_PARAMETER provided for DIM_LEVEL %d => exit\n', ...
               floatNum, missingDimLev(idD));
         end
         return
      end
      
      if (~isempty(setdiff(dimLevelParam, dimLevelDate)))
         missingDimLev = setdiff(dimLevelParam, dimLevelDate);
         for idD = 1:length(missingDimLev)
            fieldName = ['DATE_' num2str(missingDimLev(idD))];
            rtOffsetDate.(fieldName) = ...
               datestr(datenum(metaStruct.LAUNCH_DATE, 'dd/mm/yyyy HH:MM:SS'), 'yyyymmddHHMMSS'); % to adjust all profiles
         end
      end
      
      rtOffsetData.PARAM = rtOffsetParam;
      rtOffsetData.SLOPE = rtOffsetSlope;
      rtOffsetData.VALUE = rtOffsetValue;
      rtOffsetData.DATE = rtOffsetDate;
      
      metaStruct.RT_OFFSET = rtOffsetData;
   end
   
   if (~check_json_meta_data(metaStruct, floatNum))
      skipFloat = 1;
   end
   
   if (skipFloat)
      continue
   end
   
   % create the directory of json output files
   if ~(exist(a_outputDirName, 'dir') == 7)
      mkdir(a_outputDirName);
   end
   
   % create json output file
   outputFileName = [a_outputDirName '/' sprintf('%d_meta.json', floatNum)];
   ok = generate_json_file(outputFileName, metaStruct);
   if (~ok)
      return
   end
   g_cogj_reportData{end+1} = outputFileName;
   
end

if (csvFileId ~= -1)
   fclose(csvFileId);
end

return

% ------------------------------------------------------------------------------
% Get the list of BDD variables associated to configuration parameters for a
% given float version.
%
% SYNTAX :
%  [o_configStruct] = get_config_bdd_struct(a_dacFormatId)
%
% INPUT PARAMETERS :
%   a_dacFormatId : float DAC version
%
% OUTPUT PARAMETERS :
%   o_configStruct : list of BDD variables
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_bdd_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'2.10.1.S', '2.10.4.R', '2.11.1.S', '2.11.3.R', '2.11.3.S', '2.12.2.1.S'}
      o_configStruct = struct( ...
         'CONFIG_DIR_ProfilingDirection', 'DIRECTION', ...
         'CONFIG_CT_CycleTime', 'CYCLE_TIME', ...
         'CONFIG_ARM_ActivateRecoveryModeFlag', 'ActivateRecoveryModeFlag', ...
         'CONFIG_AR_AscentRate', 'AscentRate', ...
         'CONFIG_TOD_DownTimeExpiryTimeOfDay', 'PRCFG_TimeOfDay', ...
         'CONFIG_ASCEND_AscentTimeOut', 'MissionCfgAscentTimeoutPeriod', ...
         'CONFIG_ATI_AscentTimerInterval', 'AscentTimerInterval', ...
         'CONFIG_NUDGE_AscentBuoyancyNudge', 'MissionCfgBuoyancyNudge', ...
         'CONFIG_TPP_ProfilePistonPosition', 'MissionCfgTargetProfilePistonPos', ...
         'CONFIG_TP_ProfilePressure', 'DEEPEST_PRESSURE', ...
         'CONFIG_DPDP_DeepProfileDescentPeriod', 'DeepProfileDescentPeriod', ...
         'CONFIG_DDTI_DeepDescentTimerInterval', 'DeepDescentTimerInterval', ...
         'CONFIG_DPF_DeepProfileFirstFloat', 'DEEP_PROFILE_FIRST', ...
         'CONFIG_DOWN_DownTime', 'MissionCfgDownTime', ...
         'CONFIG_ETI_EmergencyTimerInterval', 'EmergencyTimerInterval', ...
         'CONFIG_HRC_HyperRetractCount', 'HyperRetractCount', ...
         'CONFIG_HRP_HyperRetractPressure', 'HyperRetractPressure', ...
         'CONFIG_IBD_IceBreakupDays', 'IceBreakupDays', ...
         'CONFIG_IMLT_IceDetectionTemperature', 'UnderIceMixedLayerCriticalTemp', ...
         'CONFIG_IDP_IceDetectionMaxPres', 'IceDetectionMixedLayerPMax', ...
         'CONFIG_IEP_IceEvasionPressure', 'IceEvasionPressure', ...
         'CONFIG_ICEM_IceDetectionMask', 'ActiveIceDetectionMonth', ...
         'CONFIG_ITI_IdleTimerInterval', 'IdleTimerInterval', ...
         'CONFIG_IBN_InitialBuoyancyNudge', 'InitialBuoyancyNudge', ...
         'CONFIG_LD_LeakDetectFlag', 'LeakDetectFlag', ...
         'CONFIG_DEBUG_LogVerbosity', 'PRCFG_Verbosity', ...
         'CONFIG_PACT_PressureActivationPistonPosition', 'PressureActivationPistonPosition', ...
         'CONFIG_MAP_MissionActivationPressure', 'MissionActivationPressure', ...
         'CONFIG_MBC_MinBuoyancyCount', 'MinBuoyancyCount', ...
         'CONFIG_OK_OkInternalVacuum', 'MissionCfgOKVacuumCount', ...
         'CONFIG_PBN_ParkBuoyancyNudge', 'ParkBuoyancyNudge', ...
         'CONFIG_PDB_ParkDeadBand', 'ParkDeadBand', ...
         'CONFIG_PPP_ParkPistonPosition', 'MissionCfgParkPistonPosition', ...
         'CONFIG_PDP_ParkDescentPeriod', 'ParkDescentPeriod', ...
         'CONFIG_PDTI_ParkDescentTimerInterval', 'ParkDescentTimerInterval', ...
         'CONFIG_PRKP_ParkPressure', 'PARKING_PRESSURE', ...
         'CONFIG_PTI_ParkTimerInterval', 'ParkTimerInterval', ...
         'CONFIG_N_ParkAndProfileCycleLength', 'MissionCfgParkAndProfileCount', ...
         'CONFIG_PST_PreludeSelfTestFlag', 'PreludeSelfTestFlag', ...
         'CONFIG_PRE_MissionPreludePeriod', 'MissionPreludePeriod', ...
         'CONFIG_SPSPC_SurfacePressureStopPumpedCtd', 'SurfacePressureStopPumpedCtd', ...
         'CONFIG_REP_ArgosTransmissionRepetitionPeriod', 'TRANS_REPETITION', ...
         'CONFIG_UP_UpTime', 'MissionCfgUpTime', ...
         'CONFIG_VM_VitalsMask', 'VitalsMask', ...
         'CONFIG_TBP_MaxAirBladderPressure', 'MissionCfgMaxAirBladderPressure', ...
         'CONFIG_FEXT_PistonFullExtension', 'FullyExtendedPistonPos', ...
         'CONFIG_FRET_PistonFullRetraction', 'RetractedPistonPos', ...
         'CONFIG_COP_CtdCutOffPressure', 'CTD_CUT_OFF_PRESSURE' ...
      );
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_apx_apf11_iridium_ for dacFormatId %s\n', a_dacFormatId);
end

return

% ------------------------------------------------------------------------------
% Get the list of configuration parameters associated to BDD variables for a
% given float version.
%
% SYNTAX :
%  [o_configStruct] = get_config_bdd_struct(a_dacFormatId)
%
% INPUT PARAMETERS :
%   a_dacFormatId : float DAC version
%
% OUTPUT PARAMETERS :
%   o_configStruct : list of configuration parameters
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_float_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'2.10.1.S', '2.10.4.R', '2.11.1.S', '2.11.3.R', '2.11.3.S', '2.12.2.1.S'}
      o_configStruct = struct( ...
         'ActivateRecoveryMode', 'CONFIG_ARM_ActivateRecoveryModeFlag', ...
         'AscentRate', 'CONFIG_AR_AscentRate', ...
         'AscentStartTimes', 'CONFIG_TOD_DownTimeExpiryTimeOfDay', ...
         'AscentTimeout', 'CONFIG_ASCEND_AscentTimeOut', ...
         'AscentTimerInterval', 'CONFIG_ATI_AscentTimerInterval', ...
         'BuoyancyNudge', 'CONFIG_NUDGE_AscentBuoyancyNudge', ...
         'DeepDescentCount', 'CONFIG_TPP_ProfilePistonPosition', ...
         'DeepDescentPressure', 'CONFIG_TP_ProfilePressure', ...
         'DeepDescentTimeout', 'CONFIG_DPDP_DeepProfileDescentPeriod', ...
         'DeepDescentTimerInterval', 'CONFIG_DDTI_DeepDescentTimerInterval', ...
         'DeepProfileFirst', 'CONFIG_DPF_DeepProfileFirstFloat', ...
         'DownTime', 'CONFIG_DOWN_DownTime', ...
         'EmergencyTimerInterval', 'CONFIG_ETI_EmergencyTimerInterval', ...
         'HyperRetractCount', 'CONFIG_HRC_HyperRetractCount', ...
         'HyperRetractPressure', 'CONFIG_HRP_HyperRetractPressure', ...
         'IceBreakupDays', 'CONFIG_IBD_IceBreakupDays', ...
         'IceCriticalT', 'CONFIG_IMLT_IceDetectionTemperature', ...
         'IceDetectionP', 'CONFIG_IDP_IceDetectionMaxPres', ...
         'IceEvasionP', 'CONFIG_IEP_IceEvasionPressure', ...
         'IceMonths', 'CONFIG_ICEM_IceDetectionMask', ...
         'IdleTimerInterval', 'CONFIG_ITI_IdleTimerInterval', ...
         'InitialBuoyancyNudge', 'CONFIG_IBN_InitialBuoyancyNudge', ...
         'LeakDetect', 'CONFIG_LD_LeakDetectFlag', ...
         'LogVerbosity', 'CONFIG_DEBUG_LogVerbosity', ...
         'MActivationCount', 'CONFIG_PACT_PressureActivationPistonPosition', ...
         'MActivationPressure', 'CONFIG_MAP_MissionActivationPressure', ...
         'MinBuoyancyCount', 'CONFIG_MBC_MinBuoyancyCount', ...
         'MinVacuum', 'CONFIG_OK_OkInternalVacuum', ...
         'ParkBuoyancyNudge', 'CONFIG_PBN_ParkBuoyancyNudge', ...
         'ParkDeadBand', 'CONFIG_PDB_ParkDeadBand', ...
         'ParkDescentCount', 'CONFIG_PPP_ParkPistonPosition', ...
         'ParkDescentTimeout', 'CONFIG_PDP_ParkDescentPeriod', ...
         'ParkDescentTimerInterval', 'CONFIG_PDTI_ParkDescentTimerInterval', ...
         'ParkPressure', 'CONFIG_PRKP_ParkPressure', ...
         'ParkTimerInterval', 'CONFIG_PTI_ParkTimerInterval', ...
         'PnPCycleLen', 'CONFIG_N_ParkAndProfileCycleLength', ...
         'PreludeSelfTest', 'CONFIG_PST_PreludeSelfTestFlag', ...
         'PreludeTime', 'CONFIG_PRE_MissionPreludePeriod', ...
         'SurfacePressure', 'CONFIG_SPSPC_SurfacePressureStopPumpedCtd', ...
         'TelemetryInterval', 'CONFIG_REP_ArgosTransmissionRepetitionPeriod', ...
         'UpTime', 'CONFIG_UP_UpTime', ...
         'VitalsMask', 'CONFIG_VM_VitalsMask', ...
         'float_id', 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY', ...
         'air_bladder_max', 'CONFIG_TBP_MaxAirBladderPressure', ...
         'buoyancy_pump_min', 'CONFIG_FRET_PistonFullRetraction', ...
         'buoyancy_pump_max', 'CONFIG_FEXT_PistonFullExtension', ...
         'argos_decimal_id', 'PTT', ...
         'argos_hex_id', 'PTT_HEX', ...
         'argos_frequency', 'TRANS_FREQUENCY');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_apx_apf11_iridium_ for dacFormatId %s\n', a_dacFormatId);
end

return

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
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaStruct] = get_meta_bdd_struct()

% output parameters initialization
o_metaStruct = struct( ...
   'ARGO_USER_MANUAL_VERSION', '', ...
   'PLATFORM_NUMBER', '', ...
   'PTT', 'PTT', ...
   'FLOAT_RUDICS_ID', 'FLOAT_RUDICS_ID', ...
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
   'STARTUP_DATE', 'STARTUP_DATE', ...
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
   'CTD_CUT_OFF_PRESSURE', 'CTD_CUT_OFF_PRESSURE', ...
   'SBE_TEMP_COEF_TA0', 'SBE_TEMP_COEF_TA0', ...
   'SBE_TEMP_COEF_TA1', 'SBE_TEMP_COEF_TA1', ...
   'SBE_TEMP_COEF_TA2', 'SBE_TEMP_COEF_TA2', ...
   'SBE_TEMP_COEF_TA3', 'SBE_TEMP_COEF_TA3', ...
   'SBE_CNDC_COEF_G', 'SBE_CNDC_COEF_G', ...
   'SBE_CNDC_COEF_H', 'SBE_CNDC_COEF_H', ...
   'SBE_CNDC_COEF_I', 'SBE_CNDC_COEF_I', ...
   'SBE_CNDC_COEF_J', 'SBE_CNDC_COEF_J', ...
   'SBE_CNDC_COEF_CPCOR', 'SBE_CNDC_COEF_CPCOR', ...
   'SBE_CNDC_COEF_CTCOR', 'SBE_CNDC_COEF_CTCOR', ...
   'SBE_CNDC_COEF_WBOTC', 'SBE_CNDC_COEF_WBOTC', ...
   'SBE_PRES_COEF_PA0', 'SBE_PRES_COEF_PA0', ...
   'SBE_PRES_COEF_PA1', 'SBE_PRES_COEF_PA1', ...
   'SBE_PRES_COEF_PA2', 'SBE_PRES_COEF_PA2', ...
   'SBE_PRES_COEF_PTCA0', 'SBE_PRES_COEF_PTCA0', ...
   'SBE_PRES_COEF_PTCA1', 'SBE_PRES_COEF_PTCA1', ...
   'SBE_PRES_COEF_PTCA2', 'SBE_PRES_COEF_PTCA2', ...
   'SBE_PRES_COEF_PTCB0', 'SBE_PRES_COEF_PTCB0', ...
   'SBE_PRES_COEF_PTCB1', 'SBE_PRES_COEF_PTCB1', ...
   'SBE_PRES_COEF_PTCB2', 'SBE_PRES_COEF_PTCB2', ...
   'SBE_PRES_COEF_PTHA0', 'SBE_PRES_COEF_PTHA0', ...
   'SBE_PRES_COEF_PTHA1', 'SBE_PRES_COEF_PTHA1', ...
   'SBE_PRES_COEF_PTHA2', 'SBE_PRES_COEF_PTHA2', ...
   'SENSOR_MOUNTED_ON_FLOAT', '');

return

% ------------------------------------------------------------------------------
% Get the TECH_PARAMETER_ID associated to a TECH_PARAMETER_CODE.
%
% SYNTAX :
%  [o_techId] = get_tech_id(a_techName)
%
% INPUT PARAMETERS :
%   a_techName : TECH_PARAMETER_CODE
%
% OUTPUT PARAMETERS :
%   o_techId : associated TECH_PARAMETER_ID
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techId] = get_tech_id(a_techName)

% output parameters initialization
o_techId = [];

switch (a_techName)
   case {'DIRECTION'}
      o_techId = 393;
   case {'CYCLE_TIME'}
      o_techId = 420;
   case {'ActivateRecoveryModeFlag'}
      o_techId = 2396;
   case {'AscentRate'}
      o_techId = 2397;
   case {'PRCFG_TimeOfDay'}
      o_techId = 1019;
   case {'MissionCfgAscentTimeoutPeriod'}
      o_techId = 1543;
   case {'AscentTimerInterval'}
      o_techId = 2398;
   case {'MissionCfgBuoyancyNudge'}
      o_techId = 1540;
   case {'MissionCfgTargetProfilePistonPos'}
      o_techId = 1546;
   case {'DEEPEST_PRESSURE'}
      o_techId = 426;
   case {'DeepProfileDescentPeriod'}
      o_techId = 1551;
   case {'DeepDescentTimerInterval'}
      o_techId = 2399;
   case {'DEEP_PROFILE_FIRST'}
      o_techId = 2145;
   case {'MissionCfgDownTime'}
      o_techId = 1537;
   case {'EmergencyTimerInterval'}
      o_techId = 2400;
   case {'HyperRetractCount'}
      o_techId = 2412;
   case {'HyperRetractPressure'}
      o_techId = 2413;
   case {'IceBreakupDays'}
      o_techId = 2401;
   case {'UnderIceMixedLayerCriticalTemp'}
      o_techId = 1558;
   case {'IceDetectionMixedLayerPMax'}
      o_techId = 2352;
   case {'IceEvasionPressure'}
      o_techId = 2057;
   case {'ActiveIceDetectionMonth'}
      o_techId = 1557;
   case {'IdleTimerInterval'}
      o_techId = 2402;
   case {'InitialBuoyancyNudge'}
      o_techId = 1550;
   case {'LeakDetectFlag'}
      o_techId = 2403;
   case {'PRCFG_Verbosity'}
      o_techId = 1021;
   case {'PressureActivationPistonPosition'}
      o_techId = 2030;
   case {'MissionActivationPressure'}
      o_techId = 2404;
   case {'MinBuoyancyCount'}
      o_techId = 2405;
   case {'MissionCfgOKVacuumCount'}
      o_techId = 1541;
   case {'ParkBuoyancyNudge'}
      o_techId = 2406;
   case {'ParkDeadBand'}
      o_techId = 2407;
   case {'MissionCfgParkPistonPosition'}
      o_techId = 1539;
   case {'ParkDescentPeriod'}
      o_techId = 1552;
   case {'ParkDescentTimerInterval'}
      o_techId = 2408;
   case {'PARKING_PRESSURE'}
      o_techId = 425;
   case {'ParkTimerInterval'}
      o_techId = 2409;
   case {'MissionCfgParkAndProfileCount'}
      o_techId = 1547;
   case {'PreludeSelfTestFlag'}
      o_techId = 2410;
   case {'MissionPreludePeriod'}
      o_techId = 1553;
   case {'SurfacePressureStopPumpedCtd'}
      o_techId = 2411;
   case {'TRANS_REPETITION'}
      o_techId = 388;
   case {'MissionCfgUpTime'}
      o_techId = 1536;
   case {'VitalsMask'}
      o_techId = 2414;
   case {'CheckSum'}
      o_techId = 2415;
   case {'CONTROLLER_BOARD_SERIAL_NO_PRIMA'}
      o_techId = 1252;
   case {'MissionCfgMaxAirBladderPressure'}
      o_techId = 1544;
   case {'RetractedPistonPos'}
      o_techId = 1549;
   case {'FullyExtendedPistonPos'}
      o_techId = 1548;
   case {'PTT'}
      o_techId = 384;
   case {'PTT_HEX'}
      o_techId = 2101;
   case {'TRANS_FREQUENCY'}
      o_techId = 387;
   case {'FLOAT_RUDICS_ID'}
      o_techId = 2384;
   otherwise
      fprintf('WARNING: Nothing done yet in get_tech_id for tech name %s\n', a_techName);
end

return

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
%   06/17/2013 - RNU - creation
%   09/01/2017 - RNU - RT version added
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
      a_configParamValues = a_metaData(a_idForWmo(idF), 4);
   else
      dimLev = a_dimLevlist(a_idForWmo(idF));
      [~, idSort] = sort(dimLev);
      
      a_configParamNames = cell(length(dimLev), 1);
      a_configParamValues = cell(length(dimLev), 1);
      for id = 1:length(dimLev)
         a_configParamNames{id, 1} = [a_confName(1:idPos-1) num2str(dimLev(id)) a_confName(idPos+length(pattern):end)];
         a_configParamValues{id, 1} = a_metaData{a_idForWmo(idF(idSort(id))), 4};
      end
   end
end

return
