% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_arvor_c_ir_sbd_( ...
%    a_floatMetaFileName, a_floatListFileName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_floatMetaFileName  : meta-data file exported from Coriolis data base
%   a_floatListFileName  : list of concerned floats
%   a_outputDirName      : directory of individual json float meta-data files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_arvor_c_ir_sbd_( ...
   a_floatMetaFileName, a_floatListFileName, a_outputDirName)

% report information structure
global g_cogj_reportData;


% check inputs
fprintf('Generating json meta-data files from input file: \n FLOAT_META_FILE_NAME = %s\n', a_floatMetaFileName);

if ~(exist(a_floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', a_floatMetaFileName);
   return
end

fprintf('Generating json meta-data files for floats of the list: \n FLOAT_LIST_FILE_NAME = %s\n', a_floatListFileName);

if ~(exist(a_floatListFileName, 'file') == 2)
   fprintf('ERROR: Float file list not found: %s\n', a_floatListFileName);
   return
end

fprintf('Output directory of json meta-data files: \n OUTPUT_DIR_NAME = %s\n', a_outputDirName);

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
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the same number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the sme number of digits
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
   if (~ismember(dacFormatId, [{'5.3'} {'5.301'}]))
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
   
   % configuration parameters
   
   % CONFIG_PARAMETER_NAME
   configStruct = get_config_init_struct(dacFormatId);
   if (isempty(configStruct))
      continue
   end
   configStructNames = fieldnames(configStruct);
   metaStruct.CONFIG_PARAMETER_NAME = configStructNames;
   
   % CONFIG_PARAMETER_VALUE
   configBddStruct = get_config_bdd_struct(dacFormatId);
   if (isempty(configBddStruct))
      continue
   end
   configBddStructNames = fieldnames(configBddStruct);
   
   nbConfig = 1;
   configParamVal = cell(length(configStructNames), nbConfig);
   for idConf = 1:nbConfig
      for idBSN = 1:length(configBddStructNames)
         configBddStructName = configBddStructNames{idBSN};
         if ((strcmp(configBddStructName, 'CONFIG_PM02_ReferenceDay') == 0) && ...
               (strcmp(configBddStructName, 'CONFIG_PM03_EstimatedSurfaceTime') == 0))
            configBddStructValue = configBddStruct.(configBddStructName);
            if (~isempty(configBddStructValue))
               idF = find(strcmp(metaData(idForWmo, 5), configBddStructValue) == 1);
               if (~isempty(idF))
                  dimLev = dimLevlist(idForWmo(idF));
                  idDim = find(dimLev == idConf, 1);
                  if ((isempty(idDim)) && (idConf > 1))
                     idDim = 1;
                  elseif ((isempty(idDim)) && (idConf == 1))
                     fprintf('ERROR\n');
                  end
                  
                  if ((strcmp(configBddStructValue, 'DIRECTION') == 0) && ...
                        (strcmp(configBddStructValue, 'CYCLE_TIME') == 0) && ...
                        (strcmp(configBddStructValue, 'PR_IMMERSION_DRIFT_PERIOD') == 0) && ...
                        (strncmp(configBddStructValue, 'AANDERAA_OPTODE_', length('AANDERAA_OPTODE_')) == 0))
                     
                     if (~strcmp(configBddStructValue, 'PRCFG_Pressure_coefficient_B'))
                        value = metaData{idForWmo(idF(idDim)), 4};
                        if ((strcmpi(value, 'yes')) || (strcmpi(value, 'y')))
                           value = '1';
                        elseif ((strcmpi(value, 'no')) || (strcmpi(value, 'n')))
                           value = '0';
                        end
                        configParamVal{idBSN, idConf} = value;
                     else
                        % this coefficient is transmitted without any digit,
                        % consequently to avoid creating one useless
                        % configuration we truncate this parameter for the
                        % launch configuration
                        configParamVal{idBSN, idConf} = num2str(fix(str2num(metaData{idForWmo(idF(idDim)), 4})));
                     end
                  else
                     if (strcmp(configBddStructValue, 'DIRECTION') == 1)
                        configParamVal{idBSN, idConf} = '1';
                     elseif (strcmp(configBddStructValue, 'CYCLE_TIME') == 1)
                        configParamVal{idBSN, idConf} = num2str(str2num(metaData{idForWmo(idF(idDim)), 4})/24);
                     elseif (strcmp(configBddStructValue, 'PR_IMMERSION_DRIFT_PERIOD') == 1)
                        configParamVal{idBSN, idConf} = num2str(str2num(metaData{idForWmo(idF(idDim)), 4})/60);
                     elseif (strncmp(configBddStructValue, 'AANDERAA_OPTODE_', length('AANDERAA_OPTODE_')) == 1)
                        % processed below
                     end
                  end
               else
                  if (strcmp(configBddStructName, 'CONFIG_PG00_NbDaysWithoutSurfacingAfterIceDetection'))
                     fprintf('ERROR: Float #%d: CONFIG_PG00 (''%s'') is mandatory - no json file generated\n', ...
                        floatNum, configBddStructValue);
                     skipFloat = 1;
                  end
               end
            else
               % if we want to use default values if the information is
               % missing in the database
               %                      configParamVal{idBSN, idConf} = configStruct.(configBddStructName);
            end
         else
            if (strcmp(configBddStructName, 'CONFIG_PM02_ReferenceDay') == 1)
               idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_Reference_day') == 1);
               if (~isempty(idF0))
                  configParamVal{idBSN, idConf} = metaData{idForWmo(idF0), 4};
               else
                  idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                  idF2 = find(strcmp(metaData(idForWmo, 5), 'PR_LAUNCH_DATETIME') == 1);
                  if ~(isempty(idF1) || isempty(idF2))
                     refDate = datenum(metaData{idForWmo(idF1), 4}, 'dd/mm/yyyy HH:MM');
                     launchDate = datenum(metaData{idForWmo(idF2), 4}, 'dd/mm/yyyy HH:MM');
                     configParamVal{idBSN, idConf} = num2str(fix(refDate) - fix(launchDate));
                  end
               end
            elseif (strcmp(configBddStructName, 'CONFIG_PM03_EstimatedSurfaceTime') == 1)
               idF0 = find(strcmp(metaData(idForWmo, 5), 'PRCFG_End_time') == 1);
               if (~isempty(idF0))
                  configParamVal{idBSN, idConf} = sprintf('%02d', str2num(metaData{idForWmo(idF0), 4}));
               else
                  idF1 = find(strcmp(metaData(idForWmo, 5), 'PR_REFERENCE_DATETIME') == 1);
                  if (~isempty(idF1))
                     refDate = datenum(metaData{idForWmo(idF1), 4}, 'dd/mm/yyyy HH:MM');
                     configParamVal{idBSN, idConf} = datestr(refDate, 'HH');
                  end
               end
            end
         end
      end
   end
   
   % CONFIG_PARAMETER_VALUE
   metaStruct.CONFIG_PARAMETER_VALUE = configParamVal;
   metaStruct.CONFIG_MISSION_NUMBER = {'0'};
   
   % RT_OFFSET
   if (any(strcmp(metaData(idForWmo, 5), 'CALIB_RT_PARAMETER')))
      metaStruct.RT_OFFSET = get_rt_offset(metaData, idForWmo);
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

return

% ------------------------------------------------------------------------------
% Get the list of configuration parameters for a given float version.
%
% SYNTAX :
%  [o_configStruct] = get_config_init_struct(a_dacFormatId)
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
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_init_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   
   case {'5.3', '5.301'}
      o_configStruct = struct( ...
         'CONFIG_PM00_NumberOfCycles', '255', ...
         'CONFIG_PM01_DelayBeforeMission', '0', ...
         'CONFIG_PM02_IridiumEOLTransmissionPeriod', '60');
      
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_arvor_c_ir_sbd_ for dacFormatId %s\n', a_dacFormatId);
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
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_bdd_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   
   case {'5.3', '5.301'}
      o_configStruct = struct( ...
         'CONFIG_PM00_NumberOfCycles', 'CONFIG_MaxCycles_NUMBER', ...
         'CONFIG_PM01_DelayBeforeMission', 'DELAY_BEFORE_MISSION', ...
         'CONFIG_PM02_IridiumEOLTransmissionPeriod', 'PRCFG_EOL_trans_period');
      
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_arvor_c_ir_sbd_ for dacFormatId %s\n', a_dacFormatId);
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
%   09/17/2019 - RNU - creation
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
   'DEPLOYMENT_CRUISE_ID', 'CRUISE_NAME', ...
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
   'CALIB_RT_ADJUSTED_ERROR', 'CALIB_RT_ADJUSTED_ERROR', ...
   'CALIB_RT_ADJ_ERROR_METHOD', 'CALIB_RT_ADJ_ERROR_METHOD');

return
