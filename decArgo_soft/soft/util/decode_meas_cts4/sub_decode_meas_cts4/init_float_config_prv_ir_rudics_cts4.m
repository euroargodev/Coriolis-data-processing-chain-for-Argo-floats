% ------------------------------------------------------------------------------
% Initialize list of sensor mounted on the float and calibration information.
%
% SYNTAX :
%  [o_ok] = init_float_config_prv_ir_rudics_cts4(a_jsonFilePathName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_jsonFilePathName : JSON META file
%   a_decoderId        : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ok : 1: if everithing is OK, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = init_float_config_prv_ir_rudics_cts4(a_jsonFilePathName, a_decoderId)

% output parameters initialization
o_ok = 0;

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% sensor list
global g_decArgo_sensorList;
global g_decArgo_sensorMountedOnFloat;

% arrays to store decoded calibration coefficient
global g_decArgo_calibInfo;


% read meta-data file
metaData = loadjson(a_jsonFilePathName);

% list of sensors mounted on the float
sensorMountedOnFloat = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   sensorMountedOnFloat = jSensorNames';
end

% create static configuration names
configNames1 = [];

% create dynamic configuration names
configNames2 = [];
for id = 3:7 % only PI 3 to PI 7 are really dynamic
   configNames2{end+1} = sprintf('CONFIG_PI_%d', id);
end
for id = 0:29
   configNames2{end+1} = sprintf('CONFIG_PT_%d', id);
end
for id = 3:7
   configNames2{end+1} = sprintf('CONFIG_PM_%02d', id);
end
for id = 0:52
   configNames2{end+1} = sprintf('CONFIG_PM_%d', id);
end
for id = 0:6
   configNames2{end+1} = sprintf('CONFIG_PV_%d', id);
end
configNames2{end+1} = sprintf('CONFIG_PV_03');
for idS = 0:6
   for id = 0:48
      configNames2{end+1} = sprintf('CONFIG_PC_%d_0_%d', idS, id);
   end
   switch idS
      case 0
         lastId = 19;
      case 1
         lastId = 10;
      case 2
         lastId = 12;
      case 3
         lastId = 19;
      case 4
         if (ismember('FLNTU', sensorMountedOnFloat))
            lastId = 13;
         elseif (ismember('TRANSISTOR_PH', sensorMountedOnFloat))
            lastId = 6;
         end
      case 5
         lastId = 6;
      case 6
         lastId = 7;
   end
   for id = 0:lastId
      configNames2{end+1} = sprintf('CONFIG_PC_%d_1_%d', idS, id);
   end
end

% fill the configuration values
configValues2 = nan(length(configNames2), 1);

if (~isempty(metaData.CONFIG_PARAMETER_NAME) && ~isempty(metaData.CONFIG_PARAMETER_VALUE))
   jConfNames = struct2cell(metaData.CONFIG_PARAMETER_NAME);
   jConfValues = struct2cell(metaData.CONFIG_PARAMETER_VALUE);
   for id = 1:length(jConfNames)
      idPos = find(strcmp(jConfNames{id}, configNames2) == 1, 1);
      if (~isempty(idPos))
         if (~isempty(jConfValues{id}))
            [value, status] = str2num(jConfValues{id});
            if ((length(value) == 1) && (status == 1))
               configValues2(idPos) = value;
            else
               fprintf('ERROR: Float #%d: The configuration value ''%s'' cannot be converted to numerical value\n', ...
                  g_decArgo_floatNum, ...
                  jConfNames{id});
               return
            end
         end
      end
   end
end

% for PM parameters, duplicate the information of (PM3 to PM7) in (PM03 to PM07)
for id = 1:5
   confName = sprintf('CONFIG_PM_%d', 3+(id-1));
   idL1 = find(strcmp(confName, configNames2) == 1, 1);
   confName = sprintf('CONFIG_PM_%02d', 3+(id-1));
   idL2 = find(strcmp(confName, configNames2) == 1, 1);
   configValues2(idL2) = configValues2(idL1);
end

% fill the CONFIG_PV_03 parameter
idFPV03 = find(strcmp('CONFIG_PV_03', configNames2) == 1, 1);
idF2 = find(strcmp('CONFIG_PV_3', configNames2) == 1, 1);
configValues2(idFPV03) = configValues2(idF2);

% fill the CONFIG_PC_0_1_19 parameter
idPC0119 = find(strcmp('CONFIG_PC_0_1_19', configNames2) == 1, 1);
if (~isempty(idPC0119))
   idPC014 = find(strcmp('CONFIG_PC_0_1_4', configNames2) == 1, 1);
   if (~isempty(idPC014))
      
      configPC014 = configValues2(idPC014);
      
      % retrieve the treatment type of the depth zone associated
      % to CONFIG_PC_0_1_4 pressure value
      
      % find the depth zone thresholds
      depthZoneNum = -1;
      for id = 1:4
         % zone threshold
         confParamName = sprintf('CONFIG_PC_0_0_%d', 44+id);
         idPos = find(strcmp(confParamName, configNames2) == 1, 1);
         if (~isempty(idPos))
            zoneThreshold = configValues2(idPos);
            if (configPC014 <= zoneThreshold)
               depthZoneNum = id;
               break
            end
         end
      end
      if (depthZoneNum == -1)
         depthZoneNum = 5;
      end
      
      % retrieve treatment type for this depth zone
      confParamName = sprintf('CONFIG_PC_0_0_%d', 6+(depthZoneNum-1)*9);
      idPos = find(strcmp(confParamName, configNames2) == 1, 1);
      if (~isempty(idPos))
         treatType = configValues2(idPos);
         if (treatType == 0)
            configValues2(idPC0119) = configPC014;
         else
            configValues2(idPC0119) = configPC014 + 0.5;
         end
      end
   end
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.STATIC.NAMES = [];
g_decArgo_floatConfig.STATIC.VALUES = [];
g_decArgo_floatConfig.DYNAMIC.IGNORED_ID = [];
g_decArgo_floatConfig.DYNAMIC.NUMBER = 0;
g_decArgo_floatConfig.DYNAMIC.NAMES = configNames2';
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues2;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.PROFILE = [];
g_decArgo_floatConfig.USE.CYCLE_OUT = [];
g_decArgo_floatConfig.USE.CONFIG = [];
g_decArgo_floatConfig.DYNAMIC_TMP.DATES = [];
g_decArgo_floatConfig.DYNAMIC_TMP.NAMES = [];
g_decArgo_floatConfig.DYNAMIC_TMP.VALUES = [];

% fill the sensor list
sensorList = [];
if (isfield(metaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(metaData.SENSOR_MOUNTED_ON_FLOAT);
   for id = 1:length(jSensorNames)
      sensorName = jSensorNames{id};
      switch (sensorName)
         case 'CTD'
            sensorList = [sensorList 0];
         case 'OPTODE'
            sensorList = [sensorList 1];
         case 'OCR'
            sensorList = [sensorList 2];
         case 'ECO2'
            if (ismember(3, sensorList))
               fprintf('ERROR: Float #%d: Sensor #3 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 3];
         case 'ECO3'
            if (ismember(3, sensorList))
               fprintf('ERROR: Float #%d: Sensor #3 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 3];
         case 'FLNTU'
            if (ismember(4, sensorList))
               fprintf('ERROR: Float #%d: Sensor #4 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 4];
         case 'CROVER'
            sensorList = [sensorList 5];
         case 'SUNA'
            sensorList = [sensorList 6];
         case 'TRANSISTOR_PH'
            if (ismember(4, sensorList))
               fprintf('ERROR: Float #%d: Sensor #4 is already in the list\n', ...
                  g_decArgo_floatNum);
            end
            sensorList = [sensorList 4];
         otherwise
            fprintf('ERROR: Float #%d: Unknown sensor name %s\n', ...
               g_decArgo_floatNum, ...
               sensorName);
      end
   end
   sensorList = unique(sensorList);
else
   fprintf('ERROR: Float #%d: SENSOR_MOUNTED_ON_FLOAT not present in Json meta-data file: %s\n', ...
      g_decArgo_floatNum, ...
      a_jsonFilePathName);
   return
end

% store the sensor list
g_decArgo_sensorList = sensorList;
g_decArgo_sensorMountedOnFloat = sensorMountedOnFloat;

% fill the calibration coefficients
if (isfield(metaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(metaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(metaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = metaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
      
      % create the tabDoxyCoef array
      switch (a_decoderId)
         
         case {111, 113, 114, 115, 116}
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
               return
            end
      end
      
      % create the NITRATE calibration arrays
      if (ismember(6, g_decArgo_sensorList))
         if (isfield(g_decArgo_calibInfo, 'SUNA'))
            calibData = g_decArgo_calibInfo.SUNA;
            tabOpticalWavelengthUv = [];
            tabENitrate = [];
            tabESwaNitrate = [];
            tabEBisulfide = [];
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
               if (a_decoderId == 113)
                  fieldName = ['E_BISULFIDE_' num2str(id)];
                  if (isfield(calibData, fieldName))
                     tabEBisulfide = [tabEBisulfide calibData.(fieldName)];
                  else
                     fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
                     return
                  end
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
            if (~isempty(tabEBisulfide))
               g_decArgo_calibInfo.SUNA.TabEBisulfide = tabEBisulfide;
            end
            g_decArgo_calibInfo.SUNA.TabUvIntensityRefNitrate = tabUvIntensityRefNitrate;
            
            g_decArgo_calibInfo.SUNA.SunaVerticalOffset = get_config_value_from_json('CONFIG_PX_1_6_0_0_0', metaData);
            g_decArgo_calibInfo.SUNA.FloatPixelBegin = get_config_value_from_json('CONFIG_PX_1_6_0_0_3', metaData);
            g_decArgo_calibInfo.SUNA.FloatPixelEnd = get_config_value_from_json('CONFIG_PX_1_6_0_0_4', metaData);
         else
            fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for SUNA sensor\n', g_decArgo_floatNum);
            return
         end
      end
   end
end

o_ok = 1;

return
