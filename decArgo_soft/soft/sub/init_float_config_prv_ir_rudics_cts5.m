% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_rudics_cts5(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_rudics_cts5(a_decoderId)

% float configuration structures:

% configuration used to store static configuration values (not received through
% messages)
% g_decArgo_floatConfig.STATIC.NAMES
% g_decArgo_floatConfig.STATIC.VALUES

% configuration used to store configuration file contents
% g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER
% g_decArgo_floatConfig.DYNAMIC_TMP.NAMES
% g_decArgo_floatConfig.DYNAMIC_TMP.VALUES

% configuration used to store configuration per cycle and profile (used by the
% decoder)
% g_decArgo_floatConfig.DYNAMIC.NUMBER
% g_decArgo_floatConfig.DYNAMIC.NAMES
% g_decArgo_floatConfig.DYNAMIC.VALUES
% g_decArgo_floatConfig.DYNAMIC.IGNORED_ID (ids of DYNAMIC configuration
% parameters to ignore when looking for a new configuration in the existing
% ones)
% g_decArgo_floatConfig.USE.CYCLE
% g_decArgo_floatConfig.USE.PROFILE
% g_decArgo_floatConfig.USE.CYCLE_OUT
% g_decArgo_floatConfig.USE.CONFIG

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% sensor list
global g_decArgo_sensorList;
global g_decArgo_sensorMountedOnFloat;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% number of the first cycle to process
global g_decArgo_firstCycleNumCts5;
g_decArgo_firstCycleNumCts5 = [];

% input data dir
global g_decArgo_archiveDirectory;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% Id of the first payload configuration parameter
global g_decArgo_firstPayloadConfigParamId
g_decArgo_firstPayloadConfigParamId = -1;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_floatConfig = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return
end

% read meta-data file
metaData = loadjson(jsonInputFileName);

% fill the sensor list
apmtSensorList = [];
payloadSensorList = [];
sensorMountedOnFloat = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   sensorMountedOnFloat = jSensorNames';
   for id = 1:length(jSensorNames)
      sensorName = jSensorNames{id};
      % for BGC sensors, we use the sensor numbers already defined for CTS4 floats
      switch (sensorName)
         case 'CTD'
            apmtSensorList = [apmtSensorList 0];
            
         case 'ECO3'
            payloadSensorList = [payloadSensorList 3];
         case 'OCR'
            payloadSensorList = [payloadSensorList 2];
         case 'SUNA'
            payloadSensorList = [payloadSensorList 6];
         case 'OPTODE'
            payloadSensorList = [payloadSensorList 1];
         case 'TRANSISTOR_PH'
            payloadSensorList = [payloadSensorList 7]; % not yet in CTS4 floats
            
            % not BGC sensors
         case 'PSA_916'
            payloadSensorList = [payloadSensorList 101];
         case 'OPT_TAK'
            payloadSensorList = [payloadSensorList 102];
         case 'OCR507_UART1'
            payloadSensorList = [payloadSensorList 103];
         case 'OCR507_UART2'
            payloadSensorList = [payloadSensorList 104];
         case 'ECO_PUCK'
            payloadSensorList = [payloadSensorList 105];
         case 'TILT'
            payloadSensorList = [payloadSensorList 106];
         case 'UVP'
            payloadSensorList = [payloadSensorList 107];
         otherwise
            fprintf('ERROR: Float #%d: Unknown sensor name %s\n', ...
               g_decArgo_floatNum, ...
               sensorName);
      end
   end
   apmtSensorList = sort(unique(apmtSensorList));
   payloadSensorList = sort(unique(payloadSensorList));
else
   fprintf('ERROR: Float #%d: SENSOR_MOUNTED_ON_FLOAT not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      jsonInputFileName);
end

% store the sensor list
g_decArgo_sensorList = [apmtSensorList payloadSensorList];
g_decArgo_sensorMountedOnFloat = sensorMountedOnFloat;

% retrieve the number of the first cycle to process
if (isfield(metaData, 'FIRST_CYCLE_TO_PROCESS'))
   g_decArgo_firstCycleNumCts5 = str2num(metaData.FIRST_CYCLE_TO_PROCESS);
else
   fprintf('ERROR: Float #%d: FIRST_CYCLE_TO_PROCESS not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      jsonInputFileName);
end

% create static configuration names
configNames1 = [];
switch (a_decoderId)
   case {121, 122, 123}
      configInfoList = [ ...
         {'SYSTEM'} {[0:4 7 9:12]} {[]}; ...
         {'TECHNICAL'} {[0:1 8:15 17 18 20]} {[]}; ...
         {'ALARM'} {[6:8 11:15 17:20 22:25]} {''}; ...
         {'END_OF_LIFE'} {3} {[]}; ...
         {'IRIDIUM_RUDICS'} {0:3} {[]}; ...
         {'MOTOR'} {0:1} {[]}; ...
         {'PAYLOAD'} {0:3} {[]}; ...
         {'GPS'} {0:2} {[]}; ...
         {'SENSOR_'} {8} {0}; ...
         {'BATTERY'} {0:3} {[]}; ...
         {'PRESSURE_I'} {0:3} {[]}; ...
         {'SBE41'} {0} {[]}; ...
         ];
   case {124, 125}
      configInfoList = [ ...
         {'SYSTEM'} {[0:4 7 9:12]} {[]}; ...
         {'TECHNICAL'} {[0:1 8:15 17 18 20]} {[]}; ...
         {'ALARM'} {[6:8 11:15 17:20 22:28]} {''}; ...
         {'END_OF_LIFE'} {3} {[]}; ...
         {'IRIDIUM_RUDICS'} {0:3} {[]}; ...
         {'MOTOR'} {0:1} {[]}; ...
         {'PAYLOAD'} {0:3} {[]}; ...
         {'GPS'} {0:2} {[]}; ...
         {'SENSOR_'} {8} {0}; ...
         {'BATTERY'} {0:3} {[]}; ...
         {'PRESSURE_I'} {0:3} {[]}; ...
         {'SBE41'} {0} {[]}; ...
         ];
   otherwise
      fprintf('ERROR: Static configuration parameters not defined yet for deciId #%d\n', ...
         a_decoderId);
      return
end
for idConfig = 1:length(configInfoList)
   section = configInfoList{idConfig, 1};
   paramNumList = configInfoList{idConfig, 2};
   if (strcmp(section, 'SENSOR_'))
      sensorNum = 1;
      miscNumList = configInfoList{idConfig, 3};
      for idMisc = miscNumList
         configNames1{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, idMisc);
      end
      for zoneNum = 1:5
         for paramNum = paramNumList
            configNames1{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (zoneNum-1)*9 + paramNum);
         end
      end
   else
      for paramNum = paramNumList
         configNames1{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNum);
      end
   end
end
configNames1 = [configNames1 ...
      {'CONFIG_PX_1_6_0_0_3'} ...
      {'CONFIG_PX_1_6_0_0_4'} ...
      {'CONFIG_PX_1_3_0_0_2'} ...
      {'CONFIG_PX_3_3_0_1_1'} ...
      {'CONFIG_PX_3_3_0_1_0'} ...
      {'CONFIG_PX_2_3_1_0_3'} ...
      {'CONFIG_PX_2_3_1_0_1'} ...
      {'CONFIG_PX_2_3_1_0_2'} ...
      {'CONFIG_PX_2_3_1_0_0'} ...
      {'CONFIG_PX_2_3_0_0_3'} ...
      {'CONFIG_PX_2_3_0_0_1'} ...
      {'CONFIG_PX_2_3_0_0_2'} ...
      {'CONFIG_PX_2_3_0_0_0'} ...
      {'CONFIG_PX_1_3_0_0_0'} ...
      {'CONFIG_PX_3_2_0_1_3'} ...
      {'CONFIG_PX_3_2_0_2_3'} ...
      {'CONFIG_PX_3_2_0_3_3'} ...
      {'CONFIG_PX_3_2_0_1_2'} ...
      {'CONFIG_PX_3_2_0_2_2'} ...
      {'CONFIG_PX_3_2_0_3_2'} ...
      {'CONFIG_PX_1_2_0_0_0'} ...
      {'CONFIG_PX_1_1_0_0_0'} ...
      {'CONFIG_PX_1_1_0_0_7'} ...
      {'CONFIG_PX_1_1_0_0_8'} ...
      {'CONFIG_PX_1_6_0_0_0'} ...
      {'CONFIG_PX_1_6_0_0_5'} ...
      ];

% create dynamic configuration names
configNames2 = [];
switch (a_decoderId)
   case {121, 122, 123}
      configInfoList = [ ...
         {'SYSTEM'} {[5 6 8]} {[]}; ...
         {'TECHNICAL'} {[2:7 16 19 21 22]} {[]}; ...
         {'PATTERN_'} {0:7} {[]}; ...
         {'ALARM'} {[0:5 9 10 16 21]} {[]}; ...
         {'TEMPORIZATION'} {0:3} {[]}; ...
         {'END_OF_LIFE'} {0:2} {[]}; ...
         {'SECURITY'} {0:3} {[]}; ...
         {'SURFACE_APPROACH'} {0:1} {[]}; ...
         {'ICE'} {0:3} {[]}; ...
         {'CYCLE'} {0:2} {[]}; ...
         {'IRIDIUM_RUDICS'} {4:7} {[]}; ...
         {'GPS'} {3} {[]}; ...
         {'SENSOR_'} {[1:7 9]} {46:53}; ...
         ];
   case {124, 125}
      configInfoList = [ ...
         {'SYSTEM'} {[5 6 8]} {[]}; ...
         {'TECHNICAL'} {[2:7 16 19 21 22]} {[]}; ...
         {'PATTERN_'} {0:7} {[]}; ...
         {'ALARM'} {[0:5 9 10 16 21]} {[]}; ...
         {'TEMPORIZATION'} {0:3} {[]}; ...
         {'END_OF_LIFE'} {0:2} {[]}; ...
         {'SECURITY'} {0:4} {[]}; ...
         {'SURFACE_APPROACH'} {0:1} {[]}; ...
         {'ICE'} {0:3} {[]}; ...
         {'CYCLE'} {0:2} {[]}; ...
         {'IRIDIUM_RUDICS'} {4:7} {[]}; ...
         {'GPS'} {3:4} {[]}; ...
         {'SENSOR_'} {[1:7 9]} {46:53}; ...
         {'SPECIAL'} {0:1} {[]}; ...
         {'PRESSURE_ACTIVATION'} {0:2} {[]}; ...
         ];   otherwise
      fprintf('ERROR: Dynamic configuration parameters not defined yet for deciId #%d\n', ...
         a_decoderId);
      return
end
for idConfig = 1:length(configInfoList)
   section = configInfoList{idConfig, 1};
   paramNumList = configInfoList{idConfig, 2};
   if (strcmp(section, 'PATTERN_'))
      for patternNum = 1:10
         for paramNum = paramNumList
            configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, patternNum, paramNum);
         end
      end
   elseif (strcmp(section, 'SENSOR_'))
      miscNumList = configInfoList{idConfig, 3};
      sensorNum = 1;
      for zoneNum = 1:5
         for paramNum = paramNumList
            configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, (zoneNum-1)*9 + paramNum);
         end
      end
      for miscNum = miscNumList
         configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, miscNum);
      end
      if (sensorNum == 1)
         configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, max(miscNumList)+1);
         if (ismember(a_decoderId, [124, 125]))
            configNames2{end+1} = sprintf('CONFIG_APMT_%s%02d_P%02d', section, sensorNum, max(miscNumList)+2);
         end
      end
   else
      for paramNum = paramNumList
         configNames2{end+1} = sprintf('CONFIG_APMT_%s_P%02d', section, paramNum);
      end
   end
end

% initialize the configuration values with the json meta-data file

% fill the configuration values
configValues1 = [];
configValues1Ids = [];
configValues2 = nan(length(configNames2), 1);

if (~isempty(metaData.CONFIG_PARAMETER_NAME) && ~isempty(metaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      jConfName = jConfNames{id};
      jConfValue = jConfValues{id};
      if (~isempty(jConfValue))
         % look for this configuration parameter in the dynamic list
         idPos = find(strcmp(jConfName, configNames2) == 1, 1);
         if (~isempty(idPos))
            if (isstrprop(jConfValue, 'digit'))
               configValues2(idPos) = str2num(jConfValue);
            else
               [value, status] = str2num(jConfValue);
               if ((length(value) == 1) && (status == 1))
                  configValues2(idPos) = str2num(jConfValue);
               else
                  if (strcmp(jConfValue, 'True'))
                     configValues2(idPos) = 1;
                  elseif (strcmp(jConfValue, 'False'))
                     configValues2(idPos) = 0;
                  elseif (strcmp(jConfName([1:20 23:end]), 'CONFIG_APMT_PATTERN__P04'))
                     timeSec = time_2_sec(jConfValue);
                     if (~isempty(timeSec))
                        configValues2(idPos) = timeSec;
                     else
                        fprintf('ERROR: Float #%d: cannot parse ''%s'' data from Json meta-data file: %s\n', ...
                           g_decArgo_floatNum, ...
                           jConfName, ...
                           jsonInputFileName);
                        return
                     end
                  else
                     fprintf('WARNING: Float #%d: cannot convert ''%s'' data to float type from Json meta-data file: %s\n', ...
                        g_decArgo_floatNum, ...
                        jConfName, ...
                        jsonInputFileName);
                  end
               end
            end
         else
            % look for this configuration parameter in the static list
            idPos = find(strcmp(jConfName, configNames1) == 1, 1);
            if (~isempty(idPos))
               if (~isempty(jConfValues{id}))
                  configValues1{end+1} = jConfValues{id};
                  configValues1Ids = [configValues1Ids idPos];
               end
            else
               fprintf('WARNING: Float #%d: cannot find ''%s'' parameter in the configuration list (Json meta-data file: %s)\n', ...
                  g_decArgo_floatNum, ...
                  jConfName, ...
                  jsonInputFileName);
            end
         end
      end
   end
end
% all static configuration parameters are not present for all the floats
configValues1bis = cell(size(configNames1));
configValues1bis(configValues1Ids) = configValues1;
idDel = setdiff(1:length(configNames1), configValues1Ids);
configNames1(idDel) = [];
configValues1bis(idDel) = [];
configValues1 = configValues1bis;

% initialize payload configuration
payloadConfigFile = manage_split_files({g_decArgo_archiveDirectory}, ...
   {[g_decArgo_filePrefixCts5 sprintf('_%03d_00_payload*.xml', g_decArgo_firstCycleNumCts5)]}, ...
   a_decoderId);
if (isempty(payloadConfigFile))
   fprintf('DEC_WARNING: Float #%d: payload configuration (at launch) file not found\n', ...
      g_decArgo_floatNum);
else
   [payloadConfigNames, payloadConfigValues] = get_payload_config([payloadConfigFile{1, 4} payloadConfigFile{1, 1}]);
   g_decArgo_firstPayloadConfigParamId = length(configNames2) + 1;

   configNames2 = cat(2, configNames2, payloadConfigNames);
   configValues2 = cat(1, configValues2, payloadConfigValues');
   
   %    voir = cat(2, configNames2', num2cell(configValues2));
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = configNames1';
g_decArgo_floatConfig.STATIC.VALUES = configValues1';
g_decArgo_floatConfig.DYNAMIC.IGNORED_ID = []; % this list will be updated just before being used (because payload configuration could increase the number of config param names
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues2;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.PROFILE = [];
g_decArgo_floatConfig.USE.CYCLE_OUT = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.NUMBER = 1;
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = configValues2;

% create_csv_to_print_config_ir_rudics_sbd2('init_', 0, g_decArgo_floatConfig);

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(metaData);

% fill the calibration coefficients
if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(metaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
      
      % create the tabDoxyCoef array
      switch (a_decoderId)

         case {121, 122, 124}
            if (any(strcmp(g_decArgo_sensorMountedOnFloat, 'OPTODE')))
               if (isfield(g_decArgo_calibInfo, 'OPTODE'))
                  calibData = g_decArgo_calibInfo.OPTODE;
                  tabDoxyCoef = [];
                  for id = 0:3
                     fieldName = ['PhaseCoef' num2str(id)];
                     if (isfield(calibData, fieldName))
                        tabDoxyCoef(1, id+1) = calibData.(fieldName);
                     else
                        fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                        return
                     end
                  end
                  for id = 0:6
                     fieldName = ['SVUFoilCoef' num2str(id)];
                     if (isfield(calibData, fieldName))
                        tabDoxyCoef(2, id+1) = calibData.(fieldName);
                     else
                        fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                        return
                     end
                  end
                  g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
               else
                  fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
               end
            end
            
         case {123, 125}
            if (isfield(g_decArgo_calibInfo, 'OPTODE'))
               calibData = g_decArgo_calibInfo.OPTODE;
               tabDoxyCoef = [];
               for id = 0:3
                  fieldName = ['PhaseCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(1, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:5
                  fieldName = ['TempCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(2, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefA' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:13
                  fieldName = ['FoilCoefB' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(3, id+15) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegT' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(4, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:27
                  fieldName = ['FoilPolyDegO' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(5, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               for id = 0:1
                  fieldName = ['ConcCoef' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabDoxyCoef(6, id+1) = calibData.(fieldName);
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               
               g_decArgo_calibInfo.OPTODE.TabDoxyCoef = tabDoxyCoef;
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for OPTODE sensor\n', g_decArgo_floatNum);
            end
      end
      
      % create the NITRATE calibration arrays
      if (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
         if (ismember(6, g_decArgo_sensorList))
            if (isfield(g_decArgo_calibInfo, 'SUNA'))
               calibData = g_decArgo_calibInfo.SUNA;
               tabOpticalWavelengthUv = [];
               tabENitrate = [];
               tabESwaNitrate = [];
               tabUvIntensityRefNitrate = [];
               for id = 1:256
                  fieldName = ['OPTICAL_WAVELENGTH_UV_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabOpticalWavelengthUv = [tabOpticalWavelengthUv calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
                  fieldName = ['E_NITRATE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabENitrate = [tabENitrate calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
                  fieldName = ['E_SWA_NITRATE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabESwaNitrate = [tabESwaNitrate calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
                  fieldName = ['UV_INTENSITY_REF_NITRATE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabUvIntensityRefNitrate = [tabUvIntensityRefNitrate calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
               end
               g_decArgo_calibInfo.SUNA.TabOpticalWavelengthUv = tabOpticalWavelengthUv;
               g_decArgo_calibInfo.SUNA.TabENitrate = tabENitrate;
               g_decArgo_calibInfo.SUNA.TabESwaNitrate = tabESwaNitrate;
               g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = tabUvIntensityRefNitrate;
               
               g_decArgo_calibInfo.SUNA.SunaVerticalOffset = get_config_value_from_json('CONFIG_PX_1_6_0_0_0', metaData);
               g_decArgo_calibInfo.SUNA.FloatPixelBegin = get_config_value_from_json('CONFIG_PX_1_6_0_0_3', metaData);
               g_decArgo_calibInfo.SUNA.FloatPixelEnd = get_config_value_from_json('CONFIG_PX_1_6_0_0_4', metaData);
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
            end
         end
      end
      
   end
end

return
