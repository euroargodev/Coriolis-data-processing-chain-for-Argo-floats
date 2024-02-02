% ------------------------------------------------------------------------------
% Update AUX configuration with detailed UVP parameters.
%
% SYNTAX :
%  [o_launchAuxConfigName, o_launchAuxConfigId, o_launchAuxConfigValue, ...
%    o_missionAuxConfigName, o_missionAuxConfigId, o_missionAuxConfigValue] = ...
%    dispatch_uvp_detailed_configuration_parameters( ...
%    a_inputAuxMetaName, a_inputAuxMetaValue, ...
%    a_launchAuxConfigName, a_launchAuxConfigId, a_launchAuxConfigValue, ...
%    a_missionAuxConfigName, a_missionAuxConfigId, a_missionAuxConfigValue)
%
% INPUT PARAMETERS :
%   a_inputAuxMetaName          : AUX meta-data names
%   a_inputAuxMetaValue         : AUX meta-data values
%   a_launchAuxConfigName       : input launch AUX configuration names
%   a_launchAuxConfigId         : input launch AUX configuration Ids
%   a_launchAuxConfigValue      : input launch AUX configuration values
%   a_missionAuxConfigName      : input mission AUX configuration names
%   a_missionAuxConfigId        : input mission AUX configuration Ids
%   a_missionAuxConfigValue     : input mission AUX configuration values
%
% OUTPUT PARAMETERS :
%   o_launchAuxConfigName       : output launch AUX configuration names
%   o_launchAuxConfigId         : output launch AUX configuration Ids
%   o_launchAuxConfigValue      : output launch AUX configuration values
%   o_missionAuxConfigName      : output mission AUX configuration names
%   o_missionAuxConfigId        : output mission AUX configuration Ids
%   o_missionAuxConfigValue     : output mission AUX configuration values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_launchAuxConfigName, o_launchAuxConfigId, o_launchAuxConfigValue, ...
   o_missionAuxConfigName, o_missionAuxConfigId, o_missionAuxConfigValue] = ...
   dispatch_uvp_detailed_configuration_parameters( ...
   a_inputAuxMetaName, a_inputAuxMetaValue, ...
   a_launchAuxConfigName, a_launchAuxConfigId, a_launchAuxConfigValue, ...
   a_missionAuxConfigName, a_missionAuxConfigId, a_missionAuxConfigValue)

% output parameters initialization
o_launchAuxConfigName = a_launchAuxConfigName;
o_launchAuxConfigId = a_launchAuxConfigId;
o_launchAuxConfigValue = a_launchAuxConfigValue;
o_missionAuxConfigName = a_missionAuxConfigName;
o_missionAuxConfigId = a_missionAuxConfigId;
o_missionAuxConfigValue = a_missionAuxConfigValue;

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% output NetCDF configuration parameter descriptions
global g_decArgo_outputNcConfParamDescription;


% get detailed configuration labels and descriptions
[confHw, confAcq, confTaxo] = initConf;
if (isempty(confHw))
   return
end

% to store UVP configuration we need to store config parameter values as
% charecter arrays
o_launchAuxConfigValue = cellstr(num2str(o_launchAuxConfigValue));
missionAuxConfigValue = cell(size(o_missionAuxConfigValue));
for idC = 1:size(o_missionAuxConfigValue, 2)
   missionAuxConfigValue(:, idC) = cellstr(num2str(o_missionAuxConfigValue(:, idC)));
end
o_missionAuxConfigValue = missionAuxConfigValue;

% get hardware configuration
configName = 'META_AUX_UVP_HW_CONF_PARAMETERS';
idF = find(strcmp(a_inputAuxMetaName, configName));
configParams = a_inputAuxMetaValue{idF};
configLauncHwDetailed = get_detailed_config_hardware(configParams, 'CONFIG_AUX_Uvp', confHw);

configLaunchAcqDetailed = [];
for idZ = 1:5
   configName = sprintf('CONFIG_AUX_UvpDepthZone%dConfiguration_NUMBER', idZ);
   idF = find(strcmp(a_launchAuxConfigName, configName));
   configNum = a_launchAuxConfigValue(idF);
   if (~isnan(configNum))
      configName2 = sprintf('META_AUX_UVP_ACQ_CONF_%d_PARAMETERS', configNum);
      idF2 = find(strcmp(a_inputAuxMetaName, configName2));
      configParams = a_inputAuxMetaValue{idF2};
      configDetailed = get_detailed_config_acquisition(configParams, sprintf('CONFIG_AUX_UvpDepthZone%d', idZ), confAcq, confTaxo, a_inputAuxMetaName, a_inputAuxMetaValue);
      configLaunchAcqDetailed = [configLaunchAcqDetailed; configDetailed];
   end
end

% get launch acquisition configuration
configName = 'CONFIG_AUX_UvpParkDriftPhaseConfiguration_NUMBER';
idF = find(strcmp(a_launchAuxConfigName, configName));
configNum = a_launchAuxConfigValue(idF);
if (~isnan(configNum))
   configName2 = sprintf('META_AUX_UVP_ACQ_CONF_%d_PARAMETERS', configNum);
   idF2 = find(strcmp(a_inputAuxMetaName, configName2));
   configParams = a_inputAuxMetaValue{idF2};
   configDetailed = get_detailed_config_acquisition(configParams, 'CONFIG_AUX_UvpParkDriftPhase', confAcq, confTaxo, a_inputAuxMetaName, a_inputAuxMetaValue);
   configLaunchAcqDetailed = [configLaunchAcqDetailed; configDetailed];
end

% get mission acquisition configurations
NB_LINES = 100;
configMissionAcqDetailed = cell(NB_LINES, size(a_missionAuxConfigValue, 2)+2);
lineNum = 1;
for idZ = 1:5
   configName = sprintf('CONFIG_AUX_UvpDepthZone%dConfiguration_NUMBER', idZ);
   idF = find(strcmp(a_missionAuxConfigName, configName));
   if (~isempty(idF))
      configNum = a_missionAuxConfigValue(idF);
      for idConf = 1:length(configNum)
         if (~isnan(configNum(idConf)))
            configName2 = sprintf('META_AUX_UVP_ACQ_CONF_%d_PARAMETERS', configNum(idConf));
            idF2 = find(strcmp(a_inputAuxMetaName, configName2));
            configParams = a_inputAuxMetaValue{idF2};
            configDetailed = get_detailed_config_acquisition(configParams, sprintf('CONFIG_AUX_UvpDepthZone%d', idZ), confAcq, confTaxo, a_inputAuxMetaName, a_inputAuxMetaValue);
            for idL = 1:size(configDetailed, 1)
               idF3 = find(strcmp(configMissionAcqDetailed(:, 1), configDetailed{idL, 1}));
               if (isempty(idF3))
                  configMissionAcqDetailed{lineNum, 1} = configDetailed{idL, 1};
                  configMissionAcqDetailed{lineNum, 2} = configDetailed{idL, 2};
                  configMissionAcqDetailed{lineNum, idConf+2} = configDetailed{idL, 3};
                  lineNum = lineNum + 1;
                  if (lineNum > size(configMissionAcqDetailed, 1))
                     configMissionAcqDetailed = cat(1, configMissionAcqDetailed, ...
                        cell(NB_LINES, size(a_missionAuxConfigValue, 2)+2));
                  end
               else
                  configMissionAcqDetailed{idF3, idConf+2} = configDetailed{idL, 3};
               end
            end
         end
      end
   end
end

configName = 'CONFIG_AUX_UvpParkDriftPhaseConfiguration_NUMBER';
idF = find(strcmp(a_missionAuxConfigName, configName));
if (~isempty(idF))
   configNum = a_missionAuxConfigValue(idF, :);
   for idConf = 1:length(configNum)
      if (~isnan(configNum(idConf)))
         configName2 = sprintf('META_AUX_UVP_ACQ_CONF_%d_PARAMETERS', configNum(idConf));
         idF2 = find(strcmp(a_inputAuxMetaName, configName2));
         configParams = a_inputAuxMetaValue{idF2};
         configDetailed = get_detailed_config_acquisition(configParams, 'CONFIG_AUX_UvpParkDriftPhase', confAcq, confTaxo, a_inputAuxMetaName, a_inputAuxMetaValue);
         for idL = 1:size(configDetailed, 1)
            idF3 = find(strcmp(configMissionAcqDetailed(:, 1), configDetailed{idL, 1}));
            if (isempty(idF3))
               configMissionAcqDetailed{lineNum, 1} = configDetailed{idL, 1};
               configMissionAcqDetailed{lineNum, 2} = configDetailed{idL, 2};
               configMissionAcqDetailed{lineNum, idConf+2} = configDetailed{idL, 3};
               lineNum = lineNum + 1;
               if (lineNum > size(configMissionAcqDetailed, 1))
                  configMissionAcqDetailed = cat(1, configMissionAcqDetailed, ...
                     cell(NB_LINES, size(a_missionAuxConfigValue, 2)+2));
               end
            else
               configMissionAcqDetailed{idF3, idConf+2} = configDetailed{idL, 3};
            end
         end
      end
   end
end
configMissionAcqDetailed(lineNum:end, :) = [];

% add missing mission labels in launch configuration
for idL = 1:size(configMissionAcqDetailed, 1)
   if (~any(strcmp(configLaunchAcqDetailed(:, 1), configMissionAcqDetailed{idL, 1})))
      configLaunchAcqDetailed = [configLaunchAcqDetailed; cell(1, 3)];
      configLaunchAcqDetailed{end, 1} = configMissionAcqDetailed{idL, 1};
      configLaunchAcqDetailed{end, 2} = configMissionAcqDetailed{idL, 2};
   end
end

% add UVP detailed configuration into the float configuration
lineNum = length(o_launchAuxConfigName) + 1;
paramId = max(g_decArgo_outputNcConfParamId) + 1;
o_launchAuxConfigName = cat(1, o_launchAuxConfigName, cell(NB_LINES, 1));
o_launchAuxConfigId = cat(1, o_launchAuxConfigId, nan(NB_LINES, 1));
o_launchAuxConfigValue = cat(1, o_launchAuxConfigValue, cell(NB_LINES, 1));
for idL = 1:size(configLauncHwDetailed, 1)
   o_launchAuxConfigName{lineNum} = configLauncHwDetailed{idL, 1};
   idF = find(strcmp(g_decArgo_outputNcConfParamLabel, o_launchAuxConfigName{lineNum}));
   if (isempty(idF))
      g_decArgo_outputNcConfParamLabel{end+1} = configLauncHwDetailed{idL, 1};
      g_decArgo_outputNcConfParamId(end+1) = paramId;
      g_decArgo_outputNcConfParamDescription{end+1} = configLauncHwDetailed{idL, 2};
      confParamId = paramId;
      paramId = paramId + 1;
   else
      confParamId = g_decArgo_outputNcConfParamId(idF);
   end
   o_launchAuxConfigId(lineNum) = confParamId;
   o_launchAuxConfigValue{lineNum} = configLauncHwDetailed{idL, 3};
   lineNum = lineNum + 1;
   if (lineNum > length(o_launchAuxConfigName))
      o_launchAuxConfigName = cat(1, o_launchAuxConfigName, cell(NB_LINES, 1));
      o_launchAuxConfigId = cat(1, o_launchAuxConfigId, nan(NB_LINES, 1));
      o_launchAuxConfigValue = cat(1, o_launchAuxConfigValue, cell(NB_LINES, 1));
   end
end
for idL = 1:size(configLaunchAcqDetailed, 1)
   o_launchAuxConfigName{lineNum} = configLaunchAcqDetailed{idL, 1};
   idF = find(strcmp(g_decArgo_outputNcConfParamLabel, o_launchAuxConfigName{lineNum}));
   if (isempty(idF))
      g_decArgo_outputNcConfParamLabel{end+1} = configLaunchAcqDetailed{idL, 1};
      g_decArgo_outputNcConfParamId(end+1) = paramId;
      g_decArgo_outputNcConfParamDescription{end+1} = configLaunchAcqDetailed{idL, 2};
      confParamId = paramId;
      paramId = paramId + 1;
   else
      confParamId = g_decArgo_outputNcConfParamId(idF);
   end
   o_launchAuxConfigId(lineNum) = confParamId;
   o_launchAuxConfigValue{lineNum} = configLaunchAcqDetailed{idL, 3};
   lineNum = lineNum + 1;
   if (lineNum > length(o_launchAuxConfigName))
      o_launchAuxConfigName = cat(1, o_launchAuxConfigName, cell(NB_LINES, 1));
      o_launchAuxConfigId = cat(1, o_launchAuxConfigId, nan(NB_LINES, 1));
      o_launchAuxConfigValue = cat(1, o_launchAuxConfigValue, cell(NB_LINES, 1));
   end
end
o_launchAuxConfigName(lineNum:end) = [];
o_launchAuxConfigId(lineNum:end) = [];
o_launchAuxConfigValue(lineNum:end) = [];

lineNum = length(o_missionAuxConfigName) + 1;
o_missionAuxConfigName = cat(1, o_missionAuxConfigName, cell(NB_LINES, 1));
o_missionAuxConfigId = cat(1, o_missionAuxConfigId, nan(NB_LINES, 1));
o_missionAuxConfigValue = cat(1, o_missionAuxConfigValue, cell(NB_LINES, size(o_missionAuxConfigValue, 2)));
for idL = 1:size(configMissionAcqDetailed, 1)
   o_missionAuxConfigName{lineNum} = configMissionAcqDetailed{idL, 1};
   idF = find(strcmp(g_decArgo_outputNcConfParamLabel, o_missionAuxConfigName{lineNum}));
   if (isempty(idF))
      g_decArgo_outputNcConfParamLabel{end+1} = o_missionAuxConfigName{idL, 1};
      g_decArgo_outputNcConfParamId(end+1) = paramId;
      g_decArgo_outputNcConfParamDescription{end+1} = o_missionAuxConfigName{idL, 2};
      confParamId = paramId;
      paramId = paramId + 1;
   else
      confParamId = g_decArgo_outputNcConfParamId(idF);
   end
   o_missionAuxConfigId(lineNum) = confParamId;
   for idConf = 1:size(configMissionAcqDetailed, 2)-2
      o_missionAuxConfigValue{lineNum, idConf} = configMissionAcqDetailed{idL, idConf+2};
   end
   lineNum = lineNum + 1;
   if (lineNum > length(o_missionAuxConfigName))
      o_missionAuxConfigName = cat(1, o_missionAuxConfigName, cell(NB_LINES, 1));
      o_missionAuxConfigId = cat(1, o_missionAuxConfigId, nan(NB_LINES, 1));
      o_missionAuxConfigValue = cat(1, o_missionAuxConfigValue, cell(NB_LINES, size(o_missionAuxConfigValue, 2)));
   end

end
o_missionAuxConfigName(lineNum:end) = [];
o_missionAuxConfigId(lineNum:end) = [];
o_missionAuxConfigValue(lineNum:end, :) = [];

return

% ------------------------------------------------------------------------------
% Create detailed configuration from hardware summarized one.
%
% SYNTAX :
%  [o_configDetailed] = ...
%    get_detailed_config_hardware(a_configSqueeze, a_configPrefix, a_configDetails)
%
% INPUT PARAMETERS :
%   a_configSqueeze : summarized configuration
%   a_configPrefix  : prefix for configuration labels
%   a_configDetails : detailed configuration labels
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configDetailed] = ...
   get_detailed_config_hardware(a_configSqueeze, a_configPrefix, a_configDetails)

% output parameters initialization
o_configDetailed = [];

% current float WMO number
global g_decArgo_floatNum;


% get configuration values
configValues = textscan(a_configSqueeze, '%s', 'delimiter', ',');
configValues = configValues{:};
if (length(configValues) ~= size(a_configDetails, 1))
   fprintf('ERROR: Float #%d: Number of HW configuration values (%d) not consistent with expected (%d)\n', ...
      g_decArgo_floatNum, length(configValues), size(a_configDetails, 1));
   return
end
o_configDetailed = cell(length(configValues), 3);
lineNum = 1;
for idVal = 1:length(configValues)
   if (strncmp(a_configDetails{idVal, 2}, 'CONFIG_', length('CONFIG_')) && ~isempty(configValues{idVal}))
      o_configDetailed{lineNum, 1} = regexprep(a_configDetails{idVal, 2}, 'CONFIG_Uvp', a_configPrefix);
      o_configDetailed{lineNum, 2} = a_configDetails{idVal, 3};
      if (~strcmp(a_configDetails{idVal, 2}, 'CONFIG_UvpCalibrationDate_YYYYMMDDHHMM'))
         o_configDetailed{lineNum, 3} = configValues{idVal};
      else
         o_configDetailed{lineNum, 3} = [configValues{idVal} '0000'];
      end
      lineNum = lineNum + 1;
   end
end
o_configDetailed(lineNum:end, :) = [];

return

% ------------------------------------------------------------------------------
% Create detailed configuration from acquisition summarized one.
%
% SYNTAX :
%  [o_configDetailed] = get_detailed_config_acquisition( ...
%    a_configSqueeze, a_configPrefix, a_configAcqDetails, a_configTaxoDetails, ...
%    a_inputAuxMetaName, a_inputAuxMetaValue)
%
% INPUT PARAMETERS :
%   a_configSqueeze     : summarized configuration
%   a_configPrefix      : prefix for configuration labels
%   a_configAcqDetails  : detailed acquisition configuration labels
%   a_configDetails     : detailed taxonomic configuration labels
%   a_inputAuxMetaName  : AUX meta-data names
%   a_inputAuxMetaValue : AUX meta-data values
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configDetailed] = get_detailed_config_acquisition( ...
   a_configSqueeze, a_configPrefix, a_configAcqDetails, a_configTaxoDetails, ...
   a_inputAuxMetaName, a_inputAuxMetaValue)

% output parameters initialization
o_configDetailed = [];

% current float WMO number
global g_decArgo_floatNum;


% get configuration values
configValues = textscan(a_configSqueeze, '%s', 'delimiter', ',');
configValues = configValues{:};
if (length(configValues) ~= size(a_configAcqDetails, 1))
   fprintf('ERROR: Float #%d: Number of ACQ configuration values (%d) not consistent with expected (%d)\n', ...
      g_decArgo_floatNum, length(configValues), size(a_configAcqDetails, 1));
   return
end
o_configDetailed = cell(length(configValues), 3);
lineNum = 1;
taxoTable = '';
for idVal = 1:length(configValues)
   if (strncmp(a_configAcqDetails{idVal, 2}, 'CONFIG_', length('CONFIG_')) && ~isempty(configValues{idVal}))
      o_configDetailed{lineNum, 1} = regexprep(a_configAcqDetails{idVal, 2}, 'CONFIG_Uvp', a_configPrefix);
      o_configDetailed{lineNum, 2} = a_configAcqDetails{idVal, 3};
      o_configDetailed{lineNum, 3} = configValues{idVal};
      lineNum = lineNum + 1;
      if (strcmp(a_configAcqDetails{idVal, 2}, 'CONFIG_UvpTaxoTable'))
         taxoTable = configValues{idVal};
      end
   end
end
o_configDetailed(lineNum:end, :) = [];

if (~isempty(taxoTable))
   for idTx = 0:1
      configName = sprintf('META_AUX_UVP_TAXO_CONF_%d_PARAMETERS', idTx);
      idF = find(strcmp(a_inputAuxMetaName, configName));
      configParams = a_inputAuxMetaValue{idF};
      if (strncmp(configParams, taxoTable, length(taxoTable)))

         % add TAXO detailed configuration
         configValues = textscan(configParams, '%s', 'delimiter', ',');
         configValues = configValues{:};
         if (length(configValues) ~= size(a_configTaxoDetails, 1))
            fprintf('ERROR: Float #%d: Number of TAXO configuration values (%d) not consistent with expected (%d)\n', ...
               g_decArgo_floatNum, length(configValues), size(a_configTaxoDetails, 1));
            return
         end
         lineNum = size(o_configDetailed, 1) + 1;
         o_configDetailed = cat(1, o_configDetailed, cell(length(configValues), 3));
         nbClass = '';
         for idVal = 1:length(configValues)
            if (strncmp(a_configTaxoDetails{idVal, 2}, 'CONFIG_', length('CONFIG_')) && ~isempty(configValues{idVal}))
               if (~strcmp(a_configTaxoDetails{idVal, 2}, 'CONFIG_UvpTaxoConfName'))
                  o_configDetailed{lineNum, 1} = regexprep(a_configTaxoDetails{idVal, 2}, 'CONFIG_Uvp', a_configPrefix);
                  o_configDetailed{lineNum, 2} = a_configTaxoDetails{idVal, 3};
                  o_configDetailed{lineNum, 3} = configValues{idVal};
                  lineNum = lineNum + 1;
                  if (~isempty(nbClass))
                     nbClass = nbClass - 1;
                     if (nbClass == 0)
                        break
                     end
                  end
                  if (strcmp(a_configTaxoDetails{idVal, 2}, 'CONFIG_UvpTaxoModelNbClass_NUMBER'))
                     nbClass = str2double(configValues{idVal});
                  end
               end
            end
         end
         o_configDetailed(lineNum:end, :) = [];

         break
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve detailed configuration for hardware, acquisition and taxonomy.
%
% SYNTAX :
%  [o_confHw, o_confAcq, o_confTaxo] = initConf
%
% INPUT PARAMETERS :
%   o_confHw   : hardware configuration labels and descriptions
%   o_confAcq  : acquisition configuration labels and descriptions
%   o_confTaxo : taxonomy configuration labels and descriptions
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confHw, o_confAcq, o_confTaxo] = initConf

% output parameters initialization
o_confHw = [];
o_confAcq = [];
o_confTaxo = [];

% current float WMO number
global g_decArgo_floatNum;

% json meta-data
global g_decArgo_jsonMetaData;


if (isfield(g_decArgo_jsonMetaData, 'META_AUX_UVP_FIRMWARE_VERSION'))
   uvpFirmVersion = g_decArgo_jsonMetaData.META_AUX_UVP_FIRMWARE_VERSION;
   switch (g_decArgo_jsonMetaData.META_AUX_UVP_FIRMWARE_VERSION)
      case '2022.01'
         [o_confHw, o_confAcq, o_confTaxo] = initConf_2022_01;
      case '2020.01'
         [o_confHw, o_confAcq] = initConf_2020_01;
      otherwise
         fprintf('ERROR: Float #%d: Not managed UVP firmware version (''%s'') - ASK FOR AN UPDATE OF THE DECODER\n', ...
            g_decArgo_floatNum, uvpFirmVersion);
   end
else
   fprintf('ERROR: Float #%d: ''META_AUX_UVP_FIRMWARE_VERSION'' information not found in META.jon file\n', ...
      g_decArgo_floatNum);
end

return

% ------------------------------------------------------------------------------
% Retrieve detailed configuration for hardware, acquisition and taxonomy.
%
% SYNTAX :
%  [o_confHw, o_confAcq, o_confTaxo] = initConf_2022_01
%
% INPUT PARAMETERS :
%   o_confHw   : hardware configuration labels and descriptions
%   o_confAcq  : acquisition configuration labels and descriptions
%   o_confTaxo : taxonomy configuration labels and descriptions
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confHw, o_confAcq, o_confTaxo] = initConf_2022_01

o_confHw = [ ...
   {'Camera_ref'} {'SENSOR_SERIAL_NO'} {'UVP6 serial number (XXXXXXXX)'}; ...
   {'Acquisition_mode'} {'CONFIG_UvpAcquisitionMode_NUMBER'} {'0: SUPERVISED mode, 1: AUTONOMOUS mode (including CTD mode), 2: TIME-programmed mode'}; ...
   {'Default_acquisition_configuration'} {'CONFIG_UvpAcquisitionModeDefault'} {'Name of the acquisition configuration automatically launched when Acquisition_mode = 1'}; ...
   {'Delay_after_power_up_on_time_mode'} {'CONFIG_UvpDelayPowerModeTime_minutes'} {'Optional delay before starting image acquisition when Acquisition_mode = 1 (AUTONOMOUS)'}; ...
   {'Light_ref'} {'CONFIG_UvpLightSn'} {'Light unit serial number'}; ...
   {'Correction_table_activation'} {'CONFIG_UvpCorrectionTableActivation_NUMBER'} {'Selection of the lighting correction LUT -> 0: no correction, 1: light unit correction #1, 2: light unit correction #2 (default : 1)'}; ...
   {'Time_between_lighting_trigger_and_acquisition'} {'CONFIG_UvpLightTriggerAcquisitionTime_usec'} {'Delay between light unit trigger and image sensor shutter'}; ...
   {'Pressure_sensor_ref'} {'CONFIG_UvpPresSn'} {'Pressure sensor serial number (empty if no sensor installed)'}; ...
   {'Pressure_offset'} {'CONFIG_UvpVerticalPressureOffset_dbar'} {'Vertical distance between the image plan and the pressure measurement point ( >0 if pressure sensor above image field, if undefined, set 999)'}; ...
   {'Storage_capacity'} {'CONFIG_UvpStorageCapacity_Mbyte'} {'SD card storage capacity, automatically updated by UVP6 when parameters are modified, do not edit'}; ...
   {'Minimum_remaining_memory_for_thumbnail_saving'} {'CONFIG_UvpMinSecuredForThumbSavingCapacity_Mbyte'} {'Minimal memory remaining in the SD card to keep saving images or vignettes, do not edit'}; ...
   {'Baud_Rate'} {'CONFIG_UvpBaudRateCode_NUMBER'} {'UVP6 RS232 baud rate selection -> 0: 9600 bauds, 1: 19200 bauds, 2: 38400 bauds'}; ...
   {'Black_level'} {'CONFIG_UvpBlackLevel_NUMBER'} {'Image sensor black level parameter'}; ...
   {'Shutter'} {'CONFIG_UvpShutter_usec'} {'Image sensor integration time (shutter)'}; ...
   {'Gain'} {'CONFIG_UvpGain_dB'} {'Image sensor gain, do not edit'}; ...
   {'Threshold'} {'CONFIG_UvpThreshold_NUMBER'} {'Threshold for image segmentation (pixels <= Threshold are considered background)'}; ...
   {'Aa'} {'CONFIG_UvpSizeToPixelsConversionAa_um^2'} {'Calibration parameter (corresponding area in the scene represented by each pixel)'}; ...
   {'Exp'} {'CONFIG_UvpSizeToPixelsConversionExp'} {'Calibration parameter (adjusting for specular reflections)'}; ...
   {'Pixel_Size'} {'CONFIG_UvpPixelSize_um'} {'Uncalibrated pixel size (side of the pixel in the image field)'}; ...
   {'Image_volume'} {'CONFIG_UvpImageVolume_L'} {'Image volume'}; ...
   {'Calibration_date'} {'CONFIG_UvpCalibrationDate_YYYYMMDDHHMM'} {'Calibration date for the values in this table'}; ...
   {'Last_parameters_modification'} {'CONFIG_UvpLastUpdateConfigDate_YYYYMMDDHHMM'} {'Automatically updated by UVP6 when hardware parameters are modified'}; ...
   {'Operator_email'} {'CONFIG_UvpHardwareEmail'} {'Identification of the operator filling this configuration table'}; ...
   {'Min_esd_class_01'} {'CONFIG_UvpMinEsdClass01_um'} {'Lower Equivalent Spherical Diameter for class 01'}; ...
   {'Min_esd_class_02'} {'CONFIG_UvpMinEsdClass02_um'} {'Lower Equivalent Spherical Diameter for class 02'}; ...
   {'Min_esd_class_03'} {'CONFIG_UvpMinEsdClass03_um'} {'Lower Equivalent Spherical Diameter for class 03'}; ...
   {'Min_esd_class_04'} {'CONFIG_UvpMinEsdClass04_um'} {'Lower Equivalent Spherical Diameter for class 04'}; ...
   {'Min_esd_class_05'} {'CONFIG_UvpMinEsdClass05_um'} {'Lower Equivalent Spherical Diameter for class 05'}; ...
   {'Min_esd_class_06'} {'CONFIG_UvpMinEsdClass06_um'} {'Lower Equivalent Spherical Diameter for class 06'}; ...
   {'Min_esd_class_07'} {'CONFIG_UvpMinEsdClass07_um'} {'Lower Equivalent Spherical Diameter for class 07'}; ...
   {'Min_esd_class_08'} {'CONFIG_UvpMinEsdClass08_um'} {'Lower Equivalent Spherical Diameter for class 08'}; ...
   {'Min_esd_class_09'} {'CONFIG_UvpMinEsdClass09_um'} {'Lower Equivalent Spherical Diameter for class 09'}; ...
   {'Min_esd_class_10'} {'CONFIG_UvpMinEsdClass10_um'} {'Lower Equivalent Spherical Diameter for class 10'}; ...
   {'Min_esd_class_11'} {'CONFIG_UvpMinEsdClass11_um'} {'Lower Equivalent Spherical Diameter for class 11'}; ...
   {'Min_esd_class_12'} {'CONFIG_UvpMinEsdClass12_um'} {'Lower Equivalent Spherical Diameter for class 12'}; ...
   {'Min_esd_class_13'} {'CONFIG_UvpMinEsdClass13_um'} {'Lower Equivalent Spherical Diameter for class 13'}; ...
   {'Min_esd_class_14'} {'CONFIG_UvpMinEsdClass14_um'} {'Lower Equivalent Spherical Diameter for class 14'}; ...
   {'Min_esd_class_15'} {'CONFIG_UvpMinEsdClass15_um'} {'Lower Equivalent Spherical Diameter for class 15'}; ...
   {'Min_esd_class_16'} {'CONFIG_UvpMinEsdClass16_um'} {'Lower Equivalent Spherical Diameter for class 16'}; ...
   {'Min_esd_class_17'} {'CONFIG_UvpMinEsdClass17_um'} {'Lower Equivalent Spherical Diameter for class 17'}; ...
   {'Min_esd_class_18'} {'CONFIG_UvpMinEsdClass18_um'} {'Lower Equivalent Spherical Diameter for class 18'}; ...
   ];

o_confAcq = [ ...
   {'Configuration_name'} {'CONFIG_UvpAcqConfName'} {'Name used to launch this configuration'}; ...
   {'PT_mode'} {'CONFIG_UvpPtMode_NUMBER'} {'0: Triggered by vector, 1: Asks for pressure and time, 2: Use UVP6 Acquisition_frequency, 3: CTD mode (mandatory Pressure Sensor)'}; ...
   {'Acquisition_frequency'} {'CONFIG_UvpSampleRateMax_hertz'} {'Acquisition frequency (maximum value)'}; ...
   {'Frames_per_bloc'} {'CONFIG_UvpFramesPerBloc_NUMBER'} {'Nb of frames to accumulate and synthesize to send'}; ...
   {'Pressure_for_auto_start'} {'CONFIG_UvpPressureAutoStart_dbar'} {'When in CTD mode (PT_mode= 3), pressure value to automatically start the acquisition'}; ...
   {'Pressure_difference_for_auto_stop'} {'CONFIG_UvpPressureAutoStop_dbar'} {'When in CTD mode (PT_mode= 3), pressure drop from deepest value to automatically stop the acquisition'}; ...
   {'Result_sending'} {'CONFIG_UvpResultSending_LOGICAL'} {'0/false: results are never sent - 1/true: synthesized results are sent through RS232 after each bloc'}; ...
   {'Save_synthetic_data_for_delayed_request'} {'CONFIG_UvpSyntheticDataSaving_LOGICAL'} {'0/false: do not save - 1/true: save synthetic data for a potential delayed request (usefull only for troubleshooting)'}; ...
   {'Save_images'} {'CONFIG_UvpSavingImages_NUMBER'} {'How to save Images -> 0: don''t save, 1: save whole raw image, 2: save selected vignettes only'}; ...
   {'Vignetting_lower_limit_size'} {'CONFIG_UvpMinVignettingLimitESD_um'} {'When saving vignettes (Save_images= 2), minimum object size (ESD) to save vignette, utilizes Aa and Exp, (default : 645)'}; ...
   {'Appendices_ratio'} {'CONFIG_UvpAppendicesRatio_NUMBER'} {'When saving vignettes (Save_images= 2), vignette size to actual object size ratio (default : 1.5)'}; ...
   {'Interval_for_measuring_background_noise'} {'CONFIG_UvpBackgroundNoise_NUMBER'} {'Background noise measured every ''interval'' (bloc acquired without flashing). Disabled if zero'}; ...
   {'Image_nb_for_smoothing'} {'CONFIG_UvpFrameNumberForSmoothing_NUMBER'} {'Nb of images to measure temperature (for safety stop) and average particle abundance for the analog output'}; ...
   {'Analog_output_activation'} {'CONFIG_UvpAnalogOutput_LOGICAL'} {'Activation of the particle abundance analog output : 0/false: disabled - 1/true'}; ...
   {'Gain_for_analog_out'} {'CONFIG_UvpAnalogOutputGain_NUMBER'} {'Smoothed number of counted objects for 5 volts analog output voltage'}; ...
   {'Maximal_internal_temperature'} {'CONFIG_UvpTemperatureMax_degC'} {'Maximum internal temperature to cause a security stop'}; ...
   {'Operator_email'} {'CONFIG_UvpConfigAcqEmail'} {'Identification of the operator filling this configuration table'}; ...
   {'Taxo_conf'} {'CONFIG_UvpTaxoTable'} {'Taxonomic classification configuration for this acquisition (let it empty to disable embedded recognition)'}; ...
   {'Remaining_memory'} {'CONFIG_UvpRemainingMemory_Mbyte'} {'SD card remaining memory at the start of the acquisition'}; ...
   ];

o_confTaxo = [ ...
   {'Configuration_name'} {'CONFIG_UvpTaxoConfName'} {'Name used to set this configuration into the field Taxo_conf, from the Acquisition configuration file'}; ...
   {'Model_reference'} {'CONFIG_UvpTaxoModel'} {'Taxonomic classification model to be used. Automatically filled during model creation/export'}; ...
   {'Max_size_for_classification'} {'CONFIG_UvpTaxoMaxSize_NUMBER'} {'Maximum vignette size to perform the embedded classification'}; ...
   {'Model_nb_classes'} {'CONFIG_UvpTaxoModelNbClass_NUMBER'} {'Number of classes used by the classification model. Automatically filled during model creation/export'}; ...
   {'Taxo_ID_for_class_00'} {'CONFIG_UvpTaxoIdClass00'} {'Ecotaxa taxonomic unique identifier for model''s class 00'}; ...
   {'Taxo_ID_for_class_01'} {'CONFIG_UvpTaxoIdClass01'} {'Ecotaxa taxonomic unique identifier for model''s class 01'}; ...
   {'Taxo_ID_for_class_02'} {'CONFIG_UvpTaxoIdClass02'} {'Ecotaxa taxonomic unique identifier for model''s class 02'}; ...
   {'Taxo_ID_for_class_03'} {'CONFIG_UvpTaxoIdClass03'} {'Ecotaxa taxonomic unique identifier for model''s class 03'}; ...
   {'Taxo_ID_for_class_04'} {'CONFIG_UvpTaxoIdClass04'} {'Ecotaxa taxonomic unique identifier for model''s class 04'}; ...
   {'Taxo_ID_for_class_05'} {'CONFIG_UvpTaxoIdClass05'} {'Ecotaxa taxonomic unique identifier for model''s class 05'}; ...
   {'Taxo_ID_for_class_06'} {'CONFIG_UvpTaxoIdClass06'} {'Ecotaxa taxonomic unique identifier for model''s class 06'}; ...
   {'Taxo_ID_for_class_07'} {'CONFIG_UvpTaxoIdClass07'} {'Ecotaxa taxonomic unique identifier for model''s class 07'}; ...
   {'Taxo_ID_for_class_08'} {'CONFIG_UvpTaxoIdClass08'} {'Ecotaxa taxonomic unique identifier for model''s class 08'}; ...
   {'Taxo_ID_for_class_09'} {'CONFIG_UvpTaxoIdClass09'} {'Ecotaxa taxonomic unique identifier for model''s class 09'}; ...
   {'Taxo_ID_for_class_10'} {'CONFIG_UvpTaxoIdClass10'} {'Ecotaxa taxonomic unique identifier for model''s class 10'}; ...
   {'Taxo_ID_for_class_11'} {'CONFIG_UvpTaxoIdClass11'} {'Ecotaxa taxonomic unique identifier for model''s class 11'}; ...
   {'Taxo_ID_for_class_12'} {'CONFIG_UvpTaxoIdClass12'} {'Ecotaxa taxonomic unique identifier for model''s class 12'}; ...
   {'Taxo_ID_for_class_13'} {'CONFIG_UvpTaxoIdClass13'} {'Ecotaxa taxonomic unique identifier for model''s class 13'}; ...
   {'Taxo_ID_for_class_14'} {'CONFIG_UvpTaxoIdClass14'} {'Ecotaxa taxonomic unique identifier for model''s class 14'}; ...
   {'Taxo_ID_for_class_15'} {'CONFIG_UvpTaxoIdClass15'} {'Ecotaxa taxonomic unique identifier for model''s class 15'}; ...
   {'Taxo_ID_for_class_16'} {'CONFIG_UvpTaxoIdClass16'} {'Ecotaxa taxonomic unique identifier for model''s class 16'}; ...
   {'Taxo_ID_for_class_17'} {'CONFIG_UvpTaxoIdClass17'} {'Ecotaxa taxonomic unique identifier for model''s class 17'}; ...
   {'Taxo_ID_for_class_18'} {'CONFIG_UvpTaxoIdClass18'} {'Ecotaxa taxonomic unique identifier for model''s class 18'}; ...
   {'Taxo_ID_for_class_19'} {'CONFIG_UvpTaxoIdClass19'} {'Ecotaxa taxonomic unique identifier for model''s class 19'}; ...
   {'Taxo_ID_for_class_20'} {'CONFIG_UvpTaxoIdClass20'} {'Ecotaxa taxonomic unique identifier for model''s class 20'}; ...
   {'Taxo_ID_for_class_21'} {'CONFIG_UvpTaxoIdClass21'} {'Ecotaxa taxonomic unique identifier for model''s class 21'}; ...
   {'Taxo_ID_for_class_22'} {'CONFIG_UvpTaxoIdClass22'} {'Ecotaxa taxonomic unique identifier for model''s class 22'}; ...
   {'Taxo_ID_for_class_23'} {'CONFIG_UvpTaxoIdClass23'} {'Ecotaxa taxonomic unique identifier for model''s class 23'}; ...
   {'Taxo_ID_for_class_24'} {'CONFIG_UvpTaxoIdClass24'} {'Ecotaxa taxonomic unique identifier for model''s class 24'}; ...
   {'Taxo_ID_for_class_25'} {'CONFIG_UvpTaxoIdClass25'} {'Ecotaxa taxonomic unique identifier for model''s class 25'}; ...
   {'Taxo_ID_for_class_26'} {'CONFIG_UvpTaxoIdClass26'} {'Ecotaxa taxonomic unique identifier for model''s class 26'}; ...
   {'Taxo_ID_for_class_27'} {'CONFIG_UvpTaxoIdClass27'} {'Ecotaxa taxonomic unique identifier for model''s class 27'}; ...
   {'Taxo_ID_for_class_28'} {'CONFIG_UvpTaxoIdClass28'} {'Ecotaxa taxonomic unique identifier for model''s class 28'}; ...
   {'Taxo_ID_for_class_29'} {'CONFIG_UvpTaxoIdClass29'} {'Ecotaxa taxonomic unique identifier for model''s class 29'}; ...
   {'Taxo_ID_for_class_30'} {'CONFIG_UvpTaxoIdClass30'} {'Ecotaxa taxonomic unique identifier for model''s class 30'}; ...
   {'Taxo_ID_for_class_31'} {'CONFIG_UvpTaxoIdClass31'} {'Ecotaxa taxonomic unique identifier for model''s class 31'}; ...
   {'Taxo_ID_for_class_32'} {'CONFIG_UvpTaxoIdClass32'} {'Ecotaxa taxonomic unique identifier for model''s class 32'}; ...
   {'Taxo_ID_for_class_33'} {'CONFIG_UvpTaxoIdClass33'} {'Ecotaxa taxonomic unique identifier for model''s class 33'}; ...
   {'Taxo_ID_for_class_34'} {'CONFIG_UvpTaxoIdClass34'} {'Ecotaxa taxonomic unique identifier for model''s class 34'}; ...
   {'Taxo_ID_for_class_35'} {'CONFIG_UvpTaxoIdClass35'} {'Ecotaxa taxonomic unique identifier for model''s class 35'}; ...
   {'Taxo_ID_for_class_36'} {'CONFIG_UvpTaxoIdClass36'} {'Ecotaxa taxonomic unique identifier for model''s class 36'}; ...
   {'Taxo_ID_for_class_37'} {'CONFIG_UvpTaxoIdClass37'} {'Ecotaxa taxonomic unique identifier for model''s class 37'}; ...
   {'Taxo_ID_for_class_38'} {'CONFIG_UvpTaxoIdClass38'} {'Ecotaxa taxonomic unique identifier for model''s class 38'}; ...
   {'Taxo_ID_for_class_39'} {'CONFIG_UvpTaxoIdClass39'} {'Ecotaxa taxonomic unique identifier for model''s class 39'}; ...
   ];

return

% ------------------------------------------------------------------------------
% Retrieve detailed configuration for hardware, acquisition and taxonomy.
%
% SYNTAX :
%  [o_confHw, o_confAcq] = initConf_2020_01
%
% INPUT PARAMETERS :
%   o_confHw  : hardware configuration labels and descriptions
%   o_confAcq : acquisition configuration labels and descriptions
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/04/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confHw, o_confAcq] = initConf_2020_01

o_confHw = [ ...
   {'Camera_ref'} {'SENSOR_SERIAL_NO'} {'UVP6 serial number (XXXXXXXX)'}; ...
   {'Acquisition_mode'} {'CONFIG_UvpAcquisitionMode_NUMBER'} {'0: SUPERVISED mode, 1: AUTONOMOUS mode (including CTD mode), 2: TIME-programmed mode'}; ...
   {'Default_acquisition_configuration'} {'CONFIG_UvpAcquisitionModeDefault'} {'Name of the acquisition configuration automatically launched when Acquisition_mode = 1'}; ...
   {'Delay_after_power_up_on_time_mode'} {'CONFIG_UvpDelayPowerModeTim_minutes'} {'Optional delay before starting image acquisition when Acquisition_mode = 1 (AUTONOMOUS)'}; ...
   {'Light_ref'} {'CONFIG_UvpLightSn'} {'Light unit serial number'}; ...
   {'Correction_table_activation'} {'CONFIG_UvpCorrectionTableActivation_NUMBER'} {'Selection of the lighting correction LUT -> 0: no correction, 1: light unit correction #1, 2: light unit correction #2 (default : 1)'}; ...
   {'Time_between_lighting_power_up_and_trigger'} {'CONFIG_UvpLightWarmUpTime_usec'} {'Delay between light unit powering and trigger'}; ...
   {'Time_between_lighting_trigger_and_acquisition'} {'CONFIG_UvpLightTriggerAcquisitionTime_usec'} {'Delay between light unit trigger and image sensor shutter'}; ...
   {'Pressure_sensor_ref'} {'CONFIG_UvpPresSn'} {'Pressure sensor serial number (empty if no sensor installed)'}; ...
   {'Pressure_offset'} {'CONFIG_UvpVerticalPressureOffset_dbar'} {'Vertical distance between the image plan and the pressure measurement point ( >0 if pressure sensor above image field, if undefined, set 999)'}; ...
   {'Storage_capacity'} {'CONFIG_UvpStorageCapacity_Mbyte'} {'SD card storage capacity, automatically updated by UVP6 when parameters are modified, do not edit'}; ...
   {'Minimum_remaining_memory_for_thumbnail_saving'} {'CONFIG_UvpMinSecuredForThumbSavingCapacity_Mbyte'} {'Minimal memory remaining in the SD card to keep saving images or vignettes, do not edit'}; ...
   {'Baud_Rate'} {'CONFIG_UvpBaudRateCode_NUMBER'} {'UVP6 RS232 baud rate selection -> 0: 9600 bauds, 1: 19200 bauds, 2: 38400 bauds'}; ...
   {'IP_adress'} {'CONFIG_UvpIpAddress'} {'UVP6 IP address for Ethernet communication'}; ...
   {'Black_level'} {'CONFIG_UvpBlackLevel_NUMBER'} {'Image sensor black level parameter'}; ...
   {'Shutter'} {'CONFIG_UvpShutter_usec'} {'Image sensor integration time (shutter)'}; ...
   {'Gain'} {'CONFIG_UvpGain_dB'} {'Image sensor gain, do not edit'}; ...
   {'Threshold'} {'CONFIG_UvpThreshold_NUMBER'} {'Threshold for image segmentation (pixels <= Threshold are considered background)'}; ...
   {'Aa'} {'CONFIG_UvpSizeToPixelsConversionAa__um^2'} {'Calibration parameter (corresponding area in the scene represented by each pixel)'}; ...
   {'Exp'} {'CONFIG_UvpSizeToPixelsConversionExp'} {'Calibration parameter (adjusting for specular reflections)'}; ...
   {'Pixel_Size'} {'CONFIG_UvpPixelSize_um'} {'Uncalibrated pixel size (side of the pixel in the image field)'}; ...
   {'Image_volume'} {'CONFIG_UvpImageVolume_L'} {'Image volume'}; ...
   {'Calibration_date'} {'CONFIG_UvpCalibrationDate_YYYYMMDDHHMM'} {'Calibration date for the values in this table'}; ...
   {'Last_parameters_modification'} {'CONFIG_UvpLastUpdateConfigDate_YYYYMMDDHHMM'} {'Automatically updated by UVP6 when hardware parameters are modified'}; ...
   {'Operator_email'} {'CONFIG_UvpHardwareEmail'} {'Identification of the operator filling this configuration table'}; ...
   {'Min_esd_class_01'} {'CONFIG_UvpMinEsdClass01_um'} {'Lower Equivalent Spherical Diameter for class 01'}; ...
   {'Min_esd_class_02'} {'CONFIG_UvpMinEsdClass02_um'} {'Lower Equivalent Spherical Diameter for class 02'}; ...
   {'Min_esd_class_03'} {'CONFIG_UvpMinEsdClass03_um'} {'Lower Equivalent Spherical Diameter for class 03'}; ...
   {'Min_esd_class_04'} {'CONFIG_UvpMinEsdClass04_um'} {'Lower Equivalent Spherical Diameter for class 04'}; ...
   {'Min_esd_class_05'} {'CONFIG_UvpMinEsdClass05_um'} {'Lower Equivalent Spherical Diameter for class 05'}; ...
   {'Min_esd_class_06'} {'CONFIG_UvpMinEsdClass06_um'} {'Lower Equivalent Spherical Diameter for class 06'}; ...
   {'Min_esd_class_07'} {'CONFIG_UvpMinEsdClass07_um'} {'Lower Equivalent Spherical Diameter for class 07'}; ...
   {'Min_esd_class_08'} {'CONFIG_UvpMinEsdClass08_um'} {'Lower Equivalent Spherical Diameter for class 08'}; ...
   {'Min_esd_class_09'} {'CONFIG_UvpMinEsdClass09_um'} {'Lower Equivalent Spherical Diameter for class 09'}; ...
   {'Min_esd_class_10'} {'CONFIG_UvpMinEsdClass10_um'} {'Lower Equivalent Spherical Diameter for class 10'}; ...
   {'Min_esd_class_11'} {'CONFIG_UvpMinEsdClass11_um'} {'Lower Equivalent Spherical Diameter for class 11'}; ...
   {'Min_esd_class_12'} {'CONFIG_UvpMinEsdClass12_um'} {'Lower Equivalent Spherical Diameter for class 12'}; ...
   {'Min_esd_class_13'} {'CONFIG_UvpMinEsdClass13_um'} {'Lower Equivalent Spherical Diameter for class 13'}; ...
   {'Min_esd_class_14'} {'CONFIG_UvpMinEsdClass14_um'} {'Lower Equivalent Spherical Diameter for class 14'}; ...
   {'Min_esd_class_15'} {'CONFIG_UvpMinEsdClass15_um'} {'Lower Equivalent Spherical Diameter for class 15'}; ...
   {'Min_esd_class_16'} {'CONFIG_UvpMinEsdClass16_um'} {'Lower Equivalent Spherical Diameter for class 16'}; ...
   {'Min_esd_class_17'} {'CONFIG_UvpMinEsdClass17_um'} {'Lower Equivalent Spherical Diameter for class 17'}; ...
   {'Min_esd_class_18'} {'CONFIG_UvpMinEsdClass18_um'} {'Lower Equivalent Spherical Diameter for class 18'}; ...
   ];

o_confAcq = [ ...
   {'Configuration_name'} {'CONFIG_UvpAcqConfName'} {'Name used to launch this configuration'}; ...
   {'PT_mode'} {'CONFIG_UvpPtMode_NUMBER'} {'0: Triggered by vector, 1: Asks for pressure and time, 2: Use UVP6 Acquisition_frequency, 3: CTD mode (mandatory Pressure Sensor)'}; ...
   {'Acquisition_frequency'} {'CONFIG_UvpSampleRateMax_hertz'} {'Acquisition frequency (maximum value)'}; ...
   {'Frames_per_bloc'} {'CONFIG_UvpFramesPerBloc_NUMBER'} {'Nb of frames to accumulate and synthesize to send'}; ...
   {'Blocs_per_PT'} {'CONFIG_Uvp UvpBlocsPerPt_NUMBER'} {'Nb of blocs to acquire before a new acquisition or asking for a new pressure information'}; ...
   {'Pressure_for_auto_start'} {'CONFIG_UvpPressureAutoStart_dbar'} {'When in CTD mode (PT_mode= 3), pressure value to automatically start the acquisition'}; ...
   {'Pressure_difference_for_auto_stop'} {'CONFIG_UvpPressureAutoStop_dbar'} {'When in CTD mode (PT_mode= 3), pressure drop from deepest value to automatically stop the acquisition'}; ...
   {'Result_sending'} {'CONFIG_UvpResultSending_LOGICAL'} {'0/false: results are never sent - 1/true: synthesized results are sent through RS232 after each bloc'}; ...
   {'Save_synthetic_data_for_delayed_request'} {'CONFIG_UvpSyntheticDataSaving_LOGICAL'} {'0/false: do not save - 1/true: save synthetic data for a potential delayed request (usefull only for troubleshooting)'}; ...
   {'Limit_lpm_detection_size'} {'CONFIG_Uvp UvpLpmDetectionLimitESD_um'} {'Minimum size (ESD) to count and analyze objects, utilizes Aa and Exp, (default : 10)'}; ...
   {'Save_images'} {'CONFIG_UvpSavingImages_NUMBER'} {'How to save Images -> 0: don''t save, 1: save whole raw image, 2: save selected vignettes only'}; ...
   {'Vignetting_lower_limit_size'} {'CONFIG_UvpMinVignettingLimitESD_um'} {'When saving vignettes (Save_images= 2), minimum object size (ESD) to save vignette, utilizes Aa and Exp, (default : 645)'}; ...
   {'Appendices_ratio'} {'CONFIG_UvpAppendicesRatio_NUMBER'} {'When saving vignettes (Save_images= 2), vignette size to actual object size ratio (default : 1.5)'}; ...
   {'Interval_for_measuring_background_noise'} {'CONFIG_UvpBackgroundNoise_NUMBER'} {'Background noise measured every ''interval'' (bloc acquired without flashing). Disabled if zero'}; ...
   {'Image_nb_for_smoothing'} {'CONFIG_UvpFrameNumberForSmoothing_NUMBER'} {'Nb of images to measure temperature (for safety stop) and average particle abundance for the analog output'}; ...
   {'Analog_output_activation'} {'CONFIG_UvpAnalogOutput_LOGICAL'} {'Activation of the particle abundance analog output : 0/false: disabled - 1/true'}; ...
   {'Gain_for_analog_out'} {'CONFIG_UvpAnalogOutputGain_NUMBER'} {'Smoothed number of counted objects for 5 volts analog output voltage'}; ...
   {'Minimum_object_number'} {'CONFIG_UvpMinObjectSecurityStop_NUMBER'} {'Smoothed minimum number of objects to cause a security stop (not implemented)'}; ...
   {'Maximal_internal_temperature'} {'CONFIG_UvpTemperatureMax_degC'} {'Maximum internal temperature to cause a security stop'}; ...
   {'Operator_email'} {'CONFIG_UvpConfigAcqEmail'} {'Identification of the operator filling this configuration table'}; ...
   {'Taxo_flag'} {'CONFIG_UvpTaxoAcqFlag_LOGICAL'} {'Taxonomic classification flag for this acquisition (not implemented)'}; ...
   {'Remaining_memory'} {'CONFIG_UvpRemainingMemory_Mbyte'} {'SD card remaining memory at the start of the acquisition'}; ...
   ];

return
