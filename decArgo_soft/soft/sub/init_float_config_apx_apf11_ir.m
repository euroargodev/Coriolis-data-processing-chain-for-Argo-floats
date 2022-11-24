% ------------------------------------------------------------------------------
% Create configuration structures from JSON meta-data information.
%
% SYNTAX :
%  [o_floatRudicsId] = init_float_config_apx_apf11_ir(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatRudicsId : float Rudics Id
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatRudicsId] = init_float_config_apx_apf11_ir(a_decoderId)

% output parameters initialization
o_floatRudicsId = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% sensor list
global g_decArgo_sensorMountedOnFloat;

% arrays to store calibration information
global g_decArgo_calibInfo;
g_decArgo_calibInfo = [];

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;
g_decArgo_rtOffsetInfo = [];

% json meta-data
global g_decArgo_jsonMetaData;

% lists of managed decoders
global g_decArgo_decoderIdListApexApf11IridiumRudics;


% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   g_decArgo_floatConfig = [];
   fprintf('ERROR: Json meta-data file not found: %s\n', jsonInputFileName);
   return
end

% read meta-data file
jsonMetaData = loadjson(jsonInputFileName);
g_decArgo_jsonMetaData = jsonMetaData;

% retrieve float username
if (isfield(jsonMetaData, 'FLOAT_RUDICS_ID'))
   o_floatRudicsId = jsonMetaData.FLOAT_RUDICS_ID;
end
if (isempty(o_floatRudicsId) && ~ismember(a_decoderId, g_decArgo_decoderIdListApexApf11IridiumRudics))
   fprintf('ERROR: FLOAT_RUDICS_ID is mandatory, it should be set in Json meta-data file (%s)\n', jsonInputFileName);
   return
end

% initialize the configuration with the json meta-data file contents
configNames = struct2cell(jsonMetaData.CONFIG_PARAMETER_NAME);
configValues = nan(length(configNames), 1);

jConfValues = struct2cell(jsonMetaData.CONFIG_PARAMETER_VALUE);
for id = 1:length(jConfValues)
   if (~isempty(jConfValues{id}))
      if (strncmp(jConfValues{id}, '0x', 2))
         configValues(id) = hex2dec(jConfValues{id}(3:end));
      else
         configValues(id) = str2double(jConfValues{id});
      end
   end
end

% compute CONFIG_CT_CycleTime
idF1 = find(strcmp(configNames, 'CONFIG_CT_CycleTime'));
idF2 = find(strcmp(configNames, 'CONFIG_DOWN_DownTime'));
idF3 = find(strcmp(configNames, 'CONFIG_UP_UpTime'));
if (~isempty(idF1) && ~isempty(idF2) && ~isempty(idF3))
   configValues(idF1) = configValues(idF2) + configValues(idF3);
end

% create the list of index of dynamic configuration parameters ignored when
% looking for existing configuration
configNameToIgnore = [{'CONFIG_PPP_ParkPistonPosition'} {'CONFIG_TPP_ProfilePistonPosition'}];
listIdParamToIgnore = [];
for idC = 1:length(configNames)
   if (ismember(configNames{idC}, configNameToIgnore))
      listIdParamToIgnore = [listIdParamToIgnore; idC];
   end
end

% store the configuration
g_decArgo_floatConfig = [];
g_decArgo_floatConfig.NAMES = configNames;
g_decArgo_floatConfig.IGNORED_ID = listIdParamToIgnore;
g_decArgo_floatConfig.VALUES = configValues;
g_decArgo_floatConfig.NUMBER = 0;
g_decArgo_floatConfig.USE.CYCLE = [];
g_decArgo_floatConfig.USE.CONFIG = [];

% retrieve the RT offsets
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(jsonMetaData);

% add calibration coefficients
% read the calibration coefficients in the json meta-data file

% fill the calibration coefficients
if (isfield(jsonMetaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(jsonMetaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(jsonMetaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
   end
end

% store the sensor list
g_decArgo_sensorMountedOnFloat = [];
if (isfield(jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(jsonMetaData.SENSOR_MOUNTED_ON_FLOAT);
   g_decArgo_sensorMountedOnFloat = jSensorNames';
end
   
% create the tabDoxyCoef array
if (isfield(jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   if (any(strcmp(struct2cell(jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'OPTODE')))
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
end

% create the tabDoxyCoef array
if (isfield(jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   if (any(strcmp(struct2cell(jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'RAFOS')))
      % if RAFOS field already exists it has been recovered from the json
      % meta-data file otherwise we set a default one
      if (~isfield(g_decArgo_calibInfo, 'RAFOS'))
         calibData = [];
         calibData.SlopeRafosTOA = 0.3075; % Olaf Boebel specifications (8 Mar 2021 08:57:18)
         calibData.OffsetRafosTOA = -80; % Olaf Boebel specifications (8 Mar 2021 08:57:18)
         g_decArgo_calibInfo.RAFOS = calibData;
      end
   end
end

return
