% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and store it in META.json
% file.
%
% SYNTAX :
% generate_json_float_meta_pfv2_ir_sbd_( ...
%   a_floatMetaFileName, a_sensorListFileName, a_floatListFileName, ...
%   a_configDirName, a_rbrMetaDataDirName, a_outputDirName, ...
%   a_dirInputRsyncData, a_tmpDirName, a_currentTime, a_rtVersionFlag)
%
% INPUT PARAMETERS :
%   a_floatMetaFileName  : meta-data file exported from Coriolis data base
%   a_sensorListFileName : list of sensors mounted on floats
%   a_floatListFileName  : list of concerned floats
%   a_configDirName      : directory of float configuration at launch files
%   a_rbrMetaDataDirName : directory of RBR meta-data files
%   a_outputDirName      : directory of individual json float meta-data files
%   a_dirInputRsyncData  : directory of Iridium email files
%   a_tmpDirName         : temporary directory used to decode received XML settings files
%   a_currentTime        : current time of the run
%   a_rtVersionFlag      : 1 if it is the RT version of the tool, 0 otherwise
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2024 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_pfv2_ir_sbd_( ...
   a_floatMetaFileName, a_sensorListFileName, a_floatListFileName, ...
   a_configDirName, a_rbrMetaDataDirName, a_outputDirName, ...
   a_dirInputRsyncData, a_tmpDirName, a_currentTime, a_rtVersionFlag)

% report information structure
global g_cogj_reportData;


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

fprintf('Directory of float launch configuration files used: \n CONFIG_DIR_NAME = %s\n', a_configDirName);

if ~(exist(a_configDirName, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', a_configDirName);
   return
end

fprintf('Directory of RBR meta-data files: \n RBR_META_DATA_DIR_NAME = %s\n', a_rbrMetaDataDirName);

fprintf('Output directory of json meta-data files: \n OUTPUT_DIR_NAME = %s\n', a_outputDirName);

fprintf('Directory of Iridium email files: \n DIR_INPUT_RSYNC_DATA = %s\n', a_dirInputRsyncData);

fprintf('Temporary directory used to decode received XML settings files: \n TMP_DIR_NAME = %s\n', a_tmpDirName);

if ~(exist(a_tmpDirName, 'dir') == 7)
   fprintf('ERROR: Temporary directory not found: %s\n', a_tmpDirName);
   return
end

fprintf('\n');

% create the specific temporary directory of the run
tmpDirName = [a_tmpDirName '/generate_json_float_meta_pfv2_ir_sbd_' a_currentTime];
if (exist(tmpDirName, 'dir') == 7)
   rmdir(tmpDirName, 's');
end
mkdir(tmpDirName);
removeTmpDirFlag = 1;

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

% get sensor list
[wmoSensorList, nameSensorList] = get_sensor_list(a_sensorListFileName);

% get the mapping structure
metaBddStruct = get_meta_bdd_struct();
metaBddStructNames = fieldnames(metaBddStruct);

% check needed floats against DB contents
refFloatList = load(a_floatListFileName);

floatList = sort(intersect(floatList, refFloatList));

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('WARNING: Meta-data not found for float: %d\n', notFoundFloat);
end

% process floats
for idFloat = 1:length(floatList)
   
   skipFloat = 0;
   floatNum = floatList(idFloat);
   fprintf('%d/%d %d\n', idFloat, length(floatList), floatNum);
   
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
               metaStruct.(metaBddStructField) = 'n/a';
               %                fprintf('Empty mandatory meta-data ''%s'' set to ''n/a''\n', metaBddStructValue);
            elseif (~isempty(find(strcmp(mandatoryList2, metaBddStructField) == 1, 1)))
               metaStruct.(metaBddStructField) = 'UNKNOWN';
            end
            if (strcmp(metaBddStructField, 'FLOAT_SERIAL_NO'))
               fprintf('ERROR: Float #%d: FLOAT_SERIAL_NO (''%s'') is mandatory - no json file generated\n', ...
                  floatNum, metaBddStructValue);
               skipFloat = 1;
            end
         end
      end
   end
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = metaStruct.DAC_FORMAT_ID;
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d - no json file generated\n', ...
         floatNum);
      continue
   end
   
   % check if the float version is concerned by this tool
   if (~ismember(dacFormatId, [ ...
         {'8.01'} {'8.02'}]))
      fprintf('INFO: Float %d is not managed by this tool (DAC_FORMAT_ID (from PR_VERSION) : ''%s'')\n', ...
         floatNum, dacFormatId);
      continue
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
      {'SENSOR_FIRMWARE_VERSION'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   % check that SENSOR_SERIAL_NO is set
   if (~isempty(metaStruct.SENSOR_SERIAL_NO))
      for idS = 1:length(metaStruct.SENSOR_SERIAL_NO)
         if (isempty(metaStruct.SENSOR_SERIAL_NO{idS}))
            fprintf('ERROR: Float #%d: SENSOR_SERIAL_NO is mandatory (for SENSOR=''%s'' SENSOR_MODEL=''%s'' SENSOR_MAKER=''%s'') - no json file generated\n', ...
               floatNum, ...
               metaStruct.SENSOR{idS}, ...
               metaStruct.SENSOR_MODEL{idS}, ...
               metaStruct.SENSOR_MAKER{idS});
            skipFloat = 1;
         end
      end
   else
      fprintf('ERROR: Float #%d: SENSOR_SERIAL_NO is mandatory - no json file generated\n', ...
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
      {'CALIB_RT_DATE_APPLY'} ...
      {'CALIB_RT_ADJUSTED_ERROR'} ...
      {'CALIB_RT_ADJ_ERROR_METHOD'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
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
   
   % add the list of the sensor mounted on the float
   idSensor = find(wmoSensorList == floatNum);
   if (isempty(idSensor))
      fprintf('ERROR: Unknown sensor list for float #%d - nothing done for this float (PLEASE UPDATE "%s" file)\n', ...
         floatNum, a_sensorListFileName);
      continue
   end
   sensorList = nameSensorList(idSensor);
   if (length(sensorList) ~= length(unique(sensorList)))
      fprintf('ERROR: Duplicated sensors for float #%d - nothing done for this float (PLEASE CHECK "%s" file)\n', ...
         floatNum, a_sensorListFileName);
      continue
   end
   metaStruct.SENSOR_MOUNTED_ON_FLOAT = sensorList;

   % configuration parameters
   
   % retrieve configuration at launch (from setting.xml file)
   confFileName = [num2str(floatNum) '_setting.xml'];
   confFilePathName = [a_configDirName '/' confFileName];
   if (exist(confFilePathName, 'file') == 2)
      [configParamNames, configParamValues] = get_conf_at_launch_pfv2(confFilePathName, floatNum);
   else
      fprintf('INFO: Expected configuration file ''%s'' not found - generating transmitted config files in directory: %s\n', confFileName, tmpDirName);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      [removeTmpDirFlag] = decode_setting_files(a_dirInputRsyncData, tmpDirName, metaStruct.IMEI, floatNum);
      continue
   end

   metaStruct.CONFIG_PARAMETER_NAME = configParamNames';
   metaStruct.CONFIG_PARAMETER_VALUE = configParamValues';
   metaStruct.CONFIG_MISSION_NUMBER = {'0'};
   
   % CALIBRATION_COEFFICIENT
   if (any(strcmp(metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'OPTODE')))
      switch (dacFormatId)
         case {'8.01', '8.02'}
            idF = find((strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1) | ...
               (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1) | ...
               (strncmp(metaData(idForWmo, 5), 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1));
            calibData = [];
            for id = 1:length(idF)
               calibName = metaData{idForWmo(idF(id)), 5};
               if (strncmp(calibName, 'AANDERAA_OPTODE_COEF_C', length('AANDERAA_OPTODE_COEF_C')) == 1)
                  fieldName = ['SVUFoilCoef' num2str(str2num(calibName(end)))];
               elseif (strncmp(calibName, 'AANDERAA_OPTODE_PHASE_COEF_', length('AANDERAA_OPTODE_PHASE_COEF_')) == 1)
                  fieldName = ['PhaseCoef' calibName(end)];
               elseif (strncmp(calibName, 'AANDERAA_OPTODE_TEMP_COEF_', length('AANDERAA_OPTODE_TEMP_COEF_')) == 1)
                  fieldName = ['TempCoef' calibName(end)];
               end
               calibData.(fieldName) = metaData{idForWmo(idF(id)), 4};
            end
            if (~isempty(calibData))
               calibrationCoefficient = [];
               calibrationCoefficient.OPTODE = calibData;

               metaStruct.CALIBRATION_COEFFICIENT = calibrationCoefficient;
            end
      end
   end
   
   % RT_OFFSET
   if (any(strcmp(metaData(idForWmo, 5), 'CALIB_RT_PARAMETER')))
      metaStruct.RT_OFFSET = get_rt_offset(metaData, idForWmo, floatNum);
   end
   
   % RBR META-DATA
   if (any(strcmp(metaStruct.SENSOR_MOUNTED_ON_FLOAT, 'CTD_RBR')))
            
      if ~(exist(a_rbrMetaDataDirName, 'dir') == 7)
         fprintf('WARNING: Float #%d: Directory not found: %s - RBR meta-data are missing\n', ...
            floatNum, a_rbrMetaDataDirName);
      else
         files = dir([a_rbrMetaDataDirName '/' num2str(floatNum) '_*.txt']);
         if (isempty(files))
            fprintf('WARNING: Float #%d: No RBR meta-data file in directory: %s - RBR meta-data are missing\n', ...
               floatNum, a_rbrMetaDataDirName);
         elseif (length(files) > 1)
            fprintf('WARNING: Float #%d: Multiple (%d) RBR meta-data file in directory: %s - RBR meta-data are missing\n', ...
               floatNum, length(files), a_rbrMetaDataDirName);
         else
            % consider XML meta-data file
            rbrMetaDataFileName = [a_rbrMetaDataDirName '/' files(1).name];
            metaStruct = get_meta_data_rbr(rbrMetaDataFileName, metaStruct, floatNum);
         end
      end
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

if (removeTmpDirFlag)
   if (exist(tmpDirName, 'dir') == 7)
      rmdir(tmpDirName, 's');
   end
end

return

% ------------------------------------------------------------------------------
% Decode XML settings files transmitted by the float.
%
% SYNTAX :
% [o_removeTmpDirFlag] = decode_setting_files(a_rsyncDataDir, a_tmpDir, a_floatImei, a_floatWmo)
%
% INPUT PARAMETERS :
%   a_rsyncDataDir : directory of Iridium email files
%   a_tmpDir       : temporary directory used to decode received XML settings files
%   a_floatImei    : float IMEI number
%   a_floatWmo     : float WMO number
%
% OUTPUT PARAMETERS :
%   o_removeTmpDirFlag : remove temporary directory flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_removeTmpDirFlag] = decode_setting_files(a_rsyncDataDir, a_tmpDir, a_floatImei, a_floatWmo)

% output parameters initialization
o_removeTmpDirFlag = 1;


if ~(exist(a_rsyncDataDir, 'dir') == 7)
   fprintf('ERROR: DIR_INPUT_RSYNC_DATA not found: %s\n', a_rsyncDataDir);
   return
end

inputDirName = [a_rsyncDataDir '/' a_floatImei];
if ~(exist(a_rsyncDataDir, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', inputDirName);
   return
end

% create output directory of this float
floatOutputDirName = [a_tmpDir '/' num2str(a_floatWmo) '/'];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end

mailDirectory = [floatOutputDirName 'mail/'];
if ~(exist(mailDirectory, 'dir') == 7)
   mkdir(mailDirectory);
end
sbdDirectory = [floatOutputDirName 'sbd/'];
if ~(exist(sbdDirectory, 'dir') == 7)
   mkdir(sbdDirectory);
end
dataGzDirectory = [floatOutputDirName 'data_gz/'];
if ~(exist(dataGzDirectory, 'dir') == 7)
   mkdir(dataGzDirectory);
end
dataDirectory = [floatOutputDirName 'data/'];
if ~(exist(dataDirectory, 'dir') == 7)
   mkdir(dataDirectory);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% duplicate Iridium email files 

mailFiles = dir([inputDirName '/' sprintf('co*_%s_*.txt', a_floatImei)]);
if (isempty(mailFiles))
   fprintf('ERROR: No data for float %d in DIR_INPUT_RSYNC_DATA directory\n', a_floatWmo);
   return
end

for idFile = 1:length(mailFiles)
   copy_file([inputDirName '/' mailFiles(idFile).name], mailDirectory);
end

fprintf('%d email files duplicated\n', length(mailFiles));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% extract email attachements

idDel = [];
for idFile = 1:length(mailFiles)
   [~, attachmentFound] = read_mail_and_extract_attachment( ...
      mailFiles(idFile).name, mailDirectory, sbdDirectory);
   if (~attachmentFound)
      idDel = [idDel idFile];
   end
end
mailFiles(idDel) = [];

fprintf('%d SBD files extracted\n', length(mailFiles));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate float files

fprintf('Generating float files\n');

create_data_files_pfv2({mailFiles.name}, nan(1, length(mailFiles)), ...
   sbdDirectory, ...
   dataDirectory, dataGzDirectory);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% keep only setting files

settingsFiles = dir([dataDirectory '/*_setting.xml']);
if (isempty(settingsFiles))
   fprintf('No XML setting file for float %d in transmitted SBD data\n', a_floatWmo);
else
   fprintf('%d XML setting files decoded\n', length(settingsFiles));
   o_removeTmpDirFlag = 0;
end

for idFile = 1:length(settingsFiles)
   move_file([dataDirectory '/' settingsFiles(idFile).name], floatOutputDirName);
end

% remove temporary directories
if (exist(mailDirectory, 'dir') == 7)
   rmdir(mailDirectory, 's');
end
if (exist(sbdDirectory, 'dir') == 7)
   rmdir(sbdDirectory, 's');
end
if (exist(dataGzDirectory, 'dir') == 7)
   rmdir(dataGzDirectory, 's');
end
if (exist(dataDirectory, 'dir') == 7)
   rmdir(dataDirectory, 's');
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/15/2014 - RNU - creation
%   09/01/2017 - RNU - RT version added
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
   'PROGRAM_NAME', 'PROGRAM_NAME', ...
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
   'DEPLOYMENT_CRUISE_ID', 'CRUISE_NAME', ...
   'DEPLOYMENT_REFERENCE_STATION_ID', 'DEPLOY_AVAILABLE_PROFILE_ID', ...
   'END_MISSION_DATE', 'END_MISSION_DATE', ...
   'END_MISSION_STATUS', 'END_MISSION_STATUS', ...
   'END_DECODING_DATE', 'END_DECODING_DATE', ...
   'PREDEPLOYMENT_CALIB_EQUATION', 'PREDEPLOYMENT_CALIB_EQUATION', ...
   'PREDEPLOYMENT_CALIB_COEFFICIENT', 'PREDEPLOYMENT_CALIB_COEFFICIENT', ...
   'PREDEPLOYMENT_CALIB_COMMENT', 'PREDEPLOYMENT_CALIB_COMMENT', ...
   'CALIB_RT_PARAMETER', 'CALIB_RT_PARAMETER', ...
   'CALIB_RT_EQUATION', 'CALIB_RT_EQUATION', ...
   'CALIB_RT_COEFFICIENT', 'CALIB_RT_COEFFICIENT', ...
   'CALIB_RT_COMMENT', 'CALIB_RT_COMMENT', ...
   'CALIB_RT_DATE', 'CALIB_RT_DATE', ...
   'CALIB_RT_ADJUSTED_ERROR', 'CALIB_RT_ADJUSTED_ERROR', ...
   'CALIB_RT_ADJ_ERROR_METHOD', 'CALIB_RT_ADJ_ERROR_METHOD', ...
   'CP_COR', 'CPcor');

return
