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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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


% retrieve float username
if (isfield(g_decArgo_jsonMetaData, 'FLOAT_RUDICS_ID'))
   o_floatRudicsId = g_decArgo_jsonMetaData.FLOAT_RUDICS_ID;
end
if (isempty(o_floatRudicsId) && ~ismember(a_decoderId, g_decArgo_decoderIdListApexApf11IridiumRudics))
   fprintf('ERROR: FLOAT_RUDICS_ID is mandatory, it should be set in Json meta-data file\n');
   return
end

% initialize the configuration with the json meta-data file contents
configNames = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_NAME);
configValues = nan(length(configNames), 1);

jConfValues = struct2cell(g_decArgo_jsonMetaData.CONFIG_PARAMETER_VALUE);
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
g_decArgo_rtOffsetInfo = get_rt_adj_info_from_meta_data(g_decArgo_jsonMetaData);

% add calibration coefficients
% read the calibration coefficients in the json meta-data file

% fill the calibration coefficients
if (isfield(g_decArgo_jsonMetaData, 'CALIBRATION_COEFFICIENT'))
   if (~isempty(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT))
      fieldNames = fields(g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT);
      for idF = 1:length(fieldNames)
         g_decArgo_calibInfo.(fieldNames{idF}) = g_decArgo_jsonMetaData.CALIBRATION_COEFFICIENT.(fieldNames{idF});
      end
   end
end

% store the sensor list
if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   jSensorNames = struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT);
   g_decArgo_sensorMountedOnFloat = jSensorNames';
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create the tabDoxyCoef array

if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'OPTODE')))
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create the RAMSES_ACC calibration arrays

if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'RAMSES')))
      if (isfield(g_decArgo_calibInfo, 'RAMSES'))

         calibData = g_decArgo_calibInfo.RAMSES;
         wavelength = nan(255, 1);
         back1 = nan(255, 1);
         back2 = nan(255, 1);
         calAq = nan(255, 1);
         cisCoef = [];
         cisCoef.c0s = str2double(calibData.c0s);
         cisCoef.c1s = str2double(calibData.c1s);
         cisCoef.c2s = str2double(calibData.c2s);
         cisCoef.c3s = str2double(calibData.c3s);
         cisCoef.c4s = str2double(calibData.c4s);

         for id = 1:255
            fieldName = ['WAVELENGTH_' num2str(id)];
            if (isfield(calibData, fieldName))
               wavelength(id) = str2double(calibData.(fieldName));
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for RAMSES_ACC sensor\n', g_decArgo_floatNum);
               return
            end
            fieldName = ['BACK1_' num2str(id)];
            if (isfield(calibData, fieldName))
               back1(id) = str2double(calibData.(fieldName));
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for RAMSES_ACC sensor\n', g_decArgo_floatNum);
               return
            end
            fieldName = ['BACK2_' num2str(id)];
            if (isfield(calibData, fieldName))
               back2(id) = str2double(calibData.(fieldName));
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for RAMSES_ACC sensor\n', g_decArgo_floatNum);
               return
            end
            fieldName = ['CAL_AQ_' num2str(id)];
            if (isfield(calibData, fieldName))
               calAq(id) = str2double(calibData.(fieldName));
            else
               fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for RAMSES_ACC sensor\n', g_decArgo_floatNum);
               return
            end
         end

         g_decArgo_calibInfo.RAMSES_ACC.CisCoef = cisCoef;
         g_decArgo_calibInfo.RAMSES_ACC.Wavelength = wavelength;
         g_decArgo_calibInfo.RAMSES_ACC.Back1 = back1;
         g_decArgo_calibInfo.RAMSES_ACC.Back2 = back2;
         g_decArgo_calibInfo.RAMSES_ACC.CalAq = calAq;

         g_decArgo_calibInfo.RAMSES_ACC.RamsesAccVerticalOffset = get_config_value_from_json('CONFIG_PX_1_11_0_0_0', g_decArgo_jsonMetaData);
         ramsesAccDarkPixelBegin = get_config_value_from_json('CONFIG_PX_1_11_0_0_1', g_decArgo_jsonMetaData);
         ramsesAccDarkPixelEnd = get_config_value_from_json('CONFIG_PX_1_11_0_0_2', g_decArgo_jsonMetaData);
         g_decArgo_calibInfo.RAMSES_ACC.RamsesAccDarkPixelBegin = ramsesAccDarkPixelBegin;
         g_decArgo_calibInfo.RAMSES_ACC.RamsesAccDarkPixelEnd = ramsesAccDarkPixelEnd;

      else
         fprintf('ERROR: Float #%d: inconsistent CALIBRATION_COEFFICIENT information for RAMSES_ACC sensor\n', g_decArgo_floatNum);
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add RAFOS information

if (isfield(g_decArgo_jsonMetaData, 'SENSOR_MOUNTED_ON_FLOAT'))
   if (any(strcmp(struct2cell(g_decArgo_jsonMetaData.SENSOR_MOUNTED_ON_FLOAT), 'RAFOS')))
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
