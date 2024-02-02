% ------------------------------------------------------------------------------
% Process meta-data exported from Coriolis data base and save it in individual
% json files.
%
% SYNTAX :
%  generate_json_float_meta_nemo_ir_sbd_( ...
%    a_floatMetaFileName, a_floatListFileName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_floatMetaFileName : meta-data file exported from Coriolis data base
%   a_floatListFileName : list of concerned floats
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function generate_json_float_meta_nemo_ir_sbd_( ...
   a_floatMetaFileName, a_floatListFileName, a_outputDirName)

% report information structure
global g_cogj_reportData;


% check inputs
fprintf('Generating json meta-data files from input file: %s\n', a_floatMetaFileName);

if ~(exist(a_floatMetaFileName, 'file') == 2)
   fprintf('ERROR: Meta-data file not found: %s\n', a_floatMetaFileName);
   return
end

fprintf('Generating json meta-data files for floats of the list: %s\n', a_floatListFileName);

if ~(exist(a_floatListFileName, 'file') == 2)
   fprintf('ERROR: Float file list not found: %s\n', a_floatListFileName);
   return
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
   return
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
% wmoList = str2num(cell2mat(metaData(:, 1))); % works only if all raws have the same number of digits
% dimLevlist = str2num(cell2mat(metaData(:, 3))); % works only if all raws have the same number of digits
wmoList = metaData(:, 1);
for id = 1:length(wmoList)
   if (isempty(str2num(wmoList{id})))
      fprintf('%s is not a valid WMO number\n', wmoList{id});
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

notFoundFloat = setdiff(refFloatList, floatList);
if (~isempty(notFoundFloat))
   fprintf('WARNING: Meta-data not found for float: %d\n', notFoundFloat);
end

% process floats
for idFloat = 1:length(floatList)
   
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
         end
      end
   end

   % PTT / IMEI specific processing
   if (~isempty(metaStruct.IMEI) && (length(metaStruct.IMEI) >= 7))
      metaStruct.PTT = metaStruct.IMEI(end-6:end-1);
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
      {'CALIB_RT_DATE_APPLY'} ...
      {'CALIB_RT_ADJUSTED_ERROR'} ...
      {'CALIB_RT_ADJ_ERROR_METHOD'} ...
      ];
   [metaStruct] = add_multi_dim_data( ...
      itemList, ...
      metaData, idForWmo, dimLevlist, ...
      metaStruct, mandatoryList1, mandatoryList2);
   
   % retrieve DAC_FORMAT_ID
   dacFormatId = getfield(metaStruct, 'DAC_FORMAT_ID');
   if (isempty(dacFormatId))
      fprintf('ERROR: DAC_FORMAT_ID (from PR_VERSION) is missing for float %d - no json file generated\n', ...
         floatNum);
      continue
   end
   
   % calibration information
   
   % NO DO FLOATS YET
   
   % configuration parameters
   
   % add static configuration parameters stored in the data base
   
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
   
   idFRepRate = find(strcmp(metaData(idForWmo, 5), 'REPETITION_RATE') == 1);
   if (isempty(idFRepRate))
      fprintf('ERROR: REPETITION_RATE is missing for float %d - no json file generated\n', ...
         floatNum);
      continue
   end
            
   nbConfig = length(idFRepRate);
   configParamVal = cell(length(configStructNames), nbConfig);
   configRepRate = cell(1, nbConfig);
   for idConf = 1:nbConfig
      configRepRate{1, idConf} = metaData{idForWmo(idFRepRate(idConf)), 4};
      for idBSN = 1:length(configBddStructNames)
         configBddStructName = configBddStructNames{idBSN};
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
               
               configParamVal{idBSN, idConf} = metaData{idForWmo(idF(idDim)), 4};
            end
         end
      end
   end

   metaStruct.CONFIG_REPETITION_RATE = configRepRate;
   metaStruct.CONFIG_PARAMETER_VALUE = configParamVal;
   
   % RT_OFFSET
   if (any(strcmp(metaData(idForWmo, 5), 'CALIB_RT_PARAMETER')))
      metaStruct.RT_OFFSET = get_rt_offset(metaData, idForWmo);
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_init_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'3'}
      o_configStruct = struct( ...
         'CONFIG_profile_pressure', '', ...
         'CONFIG_parking_pressure', '', ...
         'CONFIG_parking_sample_interval', '', ...
         'CONFIG_mission_cycle_time', '');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_nemo_ir_sbd_ for dacFormatId %s\n', a_dacFormatId);
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configStruct] = get_config_bdd_struct(a_dacFormatId)

% output parameters initialization
o_configStruct = [];

switch (a_dacFormatId)
   case {'3'}
      o_configStruct = struct( ...
         'CONFIG_profile_pressure', 'DEEPEST_PRESSURE', ...
         'CONFIG_parking_pressure', 'PARKING_PRESSURE', ...
         'CONFIG_parking_sample_interval', 'PR_IMMERSION_DRIFT_PERIOD', ...
         'CONFIG_mission_cycle_time', 'CYCLE_TIME');
   otherwise
      fprintf('WARNING: Nothing done yet in generate_json_float_meta_apx_ir_rudic_s for dacFormatId %s\n', a_dacFormatId);
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
%   02/03/2020 - RNU - creation
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
   'PLATFORM_TYPE', 'PR_TYPE', ...
   'PLATFORM_MAKER', 'PLATFORM_MAKER', ...
   'FIRMWARE_VERSION', 'FIRMWARE_VERSION', ...
   'MANUAL_VERSION', 'MANUAL_VERSION', ...
   'FLOAT_SERIAL_NO', 'INST_REFERENCE', ...
   'STANDARD_FORMAT_ID', 'STANDARD_FORMAT_ID', ...
   'DAC_FORMAT_ID', 'PR_VERSION', ...
   'WMO_INST_TYPE', 'PR_PROBE_CODE', ...
   'WMO_RECORDER_TYPE', 'PR_RECORDER_CODE', ...
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
   'DEPLOYMENT_CRUISE_ID', 'CRUISE_NAME', ...
   'DEPLOYMENT_REFERENCE_STATION_ID', 'DEPLOY_AVAILABLE_PROFILE_ID', ...
   'DEPLOYMENT_OPERATOR_NAME', 'DPLY_OPERATOR_NAME', ...
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
   'CALIB_RT_ADJ_ERROR_METHOD', 'CALIB_RT_ADJ_ERROR_METHOD');

return
