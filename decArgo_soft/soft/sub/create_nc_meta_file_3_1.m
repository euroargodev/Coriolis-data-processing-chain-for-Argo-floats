% ------------------------------------------------------------------------------
% Create NetCDF META-DATA file.
%
% SYNTAX :
%  create_nc_meta_file_3_1(a_decoderId, a_structConfig)
%
% INPUT PARAMETERS :
%   a_decoderId    : float decoder Id
%   a_structConfig : float configuration
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/20/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_meta_file_3_1(a_decoderId, a_structConfig)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_applyRtqc;

% directory of json meta-data files
global g_decArgo_dirInputJsonFloatMetaDataFile;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% output NetCDF configuration parameter descriptions
global g_decArgo_outputNcConfParamDescription;

% structure to store miscellaneous meta-data
global g_decArgo_jsonMetaData;

% meta-data retrieved from APMT tech files
global g_decArgo_apmtMetaFromTech;

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabel;
global g_decArgo_outputNcParamDescription;

% decoder version
global g_decArgo_decoderVersion;


% verbose mode flag
VERBOSE_MODE = 1;

% json meta-data file for this float
jsonInputFileName = [g_decArgo_dirInputJsonFloatMetaDataFile '/' sprintf('%d_meta.json', g_decArgo_floatNum)];

if ~(exist(jsonInputFileName, 'file') == 2)
   fprintf('ERROR: Float #%d: Json meta-data file not found: %s\n', ...
      g_decArgo_floatNum, ...
      jsonInputFileName);
   return
end

% read meta-data file
metaData = loadjson(jsonInputFileName);

% update the meta-data contents
metaData = update_meta_data(metaData, a_decoderId);

% collect AUX meta-data information
% for SENSOR
sensorAux = [];
metaDataAux = [];
metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
fieldSensorList = [ ...
   {'SENSOR'} ...
   {'SENSOR_MAKER'} ...
   {'SENSOR_MODEL'} ...
   {'SENSOR_SERIAL_NO'} ...
   ];
if (~isempty(metaData.(fieldSensorList{1})))
   tabSensor = metaData.(fieldSensorList{1});
   idAux = [];
   fieldNames = fieldnames(tabSensor);
   for idF = 1:length(fieldNames)
      sensorName = tabSensor.(fieldNames{idF});
      if (strncmp(sensorName, 'AUX_', length('AUX_')))
         idAux = [idAux idF];
         sensorAux{end+1} = sensorName;
      end
   end
   if (~isempty(idAux))
      for idFS = 1:length(fieldSensorList)
         item = fieldSensorList{idFS};
         if (~isempty(metaData.(item)))
            tabData = metaData.(item);
            tabDataAux = [];
            for id = 1:length(idAux)
               tabDataAux.([item '_' num2str(idAux(id))]) = tabData.([item '_' num2str(idAux(id))]);
               tabData = rmfield(tabData, [item '_' num2str(idAux(id))]);
            end
            metaData.(item) = tabData;
            metaDataAux.(item) = tabDataAux;
         end
      end
   end
end

% for PARAMETER
fieldParamList = [ ...
   {'PARAMETER_SENSOR'} ...
   {'PARAMETER'} ...
   {'PARAMETER_UNITS'} ...
   {'PARAMETER_ACCURACY'} ...
   {'PARAMETER_RESOLUTION'} ...
   {'PREDEPLOYMENT_CALIB_EQUATION'} ...
   {'PREDEPLOYMENT_CALIB_COEFFICIENT'} ...
   {'PREDEPLOYMENT_CALIB_COMMENT'} ...
   ];
if (~isempty(metaData.(fieldParamList{1})))
   tabParam = metaData.(fieldParamList{1});
   idAux = [];
   fieldNames = fieldnames(tabParam);
   for idF = 1:length(fieldNames)
      sensorName = tabParam.(fieldNames{idF});
      if (any(strcmp(sensorName, sensorAux)))
         idAux = [idAux idF];
      end
   end
   if (~isempty(idAux))
      for idFS = 1:length(fieldParamList)
         item = fieldParamList{idFS};
         if (~isempty(metaData.(item)))
            tabData = metaData.(item);
            tabDataAux = [];
            for id = 1:length(idAux)
               tabDataAux.([item '_' num2str(idAux(id))]) = tabData.([item '_' num2str(idAux(id))]);
               tabData = rmfield(tabData, [item '_' num2str(idAux(id))]);
            end
            metaData.(item) = tabData;
            metaDataAux.(item) = tabDataAux;
         end
      end
   end
end

% collect dimensions in input meta-data
nbSensor = 0;
if (~isempty(metaData.SENSOR))
   nbSensor = length(fieldnames(metaData.SENSOR));
end
nbParam = 0;
if (~isempty(metaData.PARAMETER))
   nbParam = length(fieldnames(metaData.PARAMETER));
end

launchConfigName = [];
launchConfigValue = [];
nbLaunchConfigParam = 0;
missionConfigName = [];
missionConfigValue = [];
nbConfigParam = 0;
configMissionNumber = [];
% process the launch and mission configurations
switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % NKE floats
   
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      % Argos floats
      
      if ~(ismember(a_decoderId, [27 28 29]))
         
         % add the CTD pump cut-off pressure (not in the JSON met-data but computed
         % on the fly according to decoder Id)
         if (~isempty(g_decArgo_jsonMetaData))
            
            if (isfield(g_decArgo_jsonMetaData, 'PRES_STOP_CTD_PUMP') && ...
                  ~isempty(g_decArgo_jsonMetaData.PRES_STOP_CTD_PUMP))
               
               configParamNum = length(fieldnames(metaData.CONFIG_PARAMETER_NAME))+1;
               metaData.CONFIG_PARAMETER_NAME.(sprintf('CONFIG_PARAMETER_NAME_%d', configParamNum)) = ...
                  'CONFIG_PX1_PumpCutOffPressure';
               
               for idC = 1:length(metaData.CONFIG_PARAMETER_VALUE)
                  metaData.CONFIG_PARAMETER_VALUE{idC}.(sprintf('CONFIG_PARAMETER_VALUE_%d_%d', configParamNum, idC)) = ...
                     num2str(g_decArgo_jsonMetaData.PRES_STOP_CTD_PUMP);
               end
            end
            
            if (isfield(g_decArgo_jsonMetaData, 'PRES_CUT_OFF_PROF') && ...
                  ~isempty(g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF))
               
               configParamNum = length(fieldnames(metaData.CONFIG_PARAMETER_NAME))+1;
               metaData.CONFIG_PARAMETER_NAME.(sprintf('CONFIG_PARAMETER_NAME_%d', configParamNum)) = ...
                  'CONFIG_PX2_ProfCutOffPressure';
               
               for idC = 1:length(metaData.CONFIG_PARAMETER_VALUE)
                  metaData.CONFIG_PARAMETER_VALUE{idC}.(sprintf('CONFIG_PARAMETER_VALUE_%d_%d', configParamNum, idC)) = ...
                     num2str(g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF);
               end
            end
         end
      else
         
         % fill the 'CONFIG_PT20_CTDPumpSwitchOffPres' configuration parameter
         % with the CTD pump cut-off pressure. It can be:
         % - already present if the parameter is in the json file
         % - missing if the information has not been collected, in that case the
         % value to be stored has been computed on the fly according to decoder
         % Id
         
         if (~isempty(g_decArgo_jsonMetaData))
            
            if (isfield(g_decArgo_jsonMetaData, 'PRES_STOP_CTD_PUMP') && ...
                  ~isempty(g_decArgo_jsonMetaData.PRES_STOP_CTD_PUMP))
               
               configParamNum = -1;
               fieldNames = fieldnames(metaData.CONFIG_PARAMETER_NAME);
               for idConfParam = 1:length(fieldNames)
                  confParamName = metaData.CONFIG_PARAMETER_NAME.(fieldNames{idConfParam});
                  if (~isempty(confParamName))
                     if (strcmp(confParamName, 'CONFIG_PT20_CTDPumpSwitchOffPres'))
                        configParamNum = idConfParam;
                        break
                     end
                  end
               end
               if (configParamNum ~= -1)
                  for idC = 1:length(metaData.CONFIG_PARAMETER_VALUE)
                     metaData.CONFIG_PARAMETER_VALUE{idC}.(sprintf('CONFIG_PARAMETER_VALUE_%d_%d', configParamNum, idC)) = ...
                        num2str(g_decArgo_jsonMetaData.PRES_STOP_CTD_PUMP);
                  end
               else
                  fprintf('ERROR: Float #%d: Cannot retrieve configuration param name :''%s'' from the configuration\n', ...
                     g_decArgo_floatNum, ...
                     'CONFIG_PT20_CTDPumpSwitchOffPres');
               end
            end
            
            if (isfield(g_decArgo_jsonMetaData, 'PRES_CUT_OFF_PROF') && ...
                  ~isempty(g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF))
               
               configParamNum = length(fieldnames(metaData.CONFIG_PARAMETER_NAME))+1;
               metaData.CONFIG_PARAMETER_NAME.(sprintf('CONFIG_PARAMETER_NAME_%d', configParamNum)) = ...
                  'CONFIG_PX2_ProfCutOffPressure';
               
               for idC = 1:length(metaData.CONFIG_PARAMETER_VALUE)
                  metaData.CONFIG_PARAMETER_VALUE{idC}.(sprintf('CONFIG_PARAMETER_VALUE_%d_%d', configParamNum, idC)) = ...
                     num2str(g_decArgo_jsonMetaData.PRES_CUT_OFF_PROF);
               end
            end
         end
      end
      
      % convert configuration decoder names into NetCDF ones
      confParamNameStruct = metaData.CONFIG_PARAMETER_NAME;
      if (~isempty(confParamNameStruct))
         fieldNames = fieldnames(confParamNameStruct);
         for idConfParam = 1:length(fieldNames)
            confParamName = confParamNameStruct.(fieldNames{idConfParam});
            if (~isempty(confParamName))
               idF = strfind(confParamName, '_');
               if ((strncmp(confParamName, 'CONFIG_P', length('CONFIG_P')) == 1) && ...
                     (length(idF) > 1))
                  confParamId = confParamName(idF(1)+1:idF(2)-1);
                  idF = find(strcmp(confParamId, g_decArgo_outputNcConfParamId) == 1);
                  if (~isempty(idF))
                     metaData.CONFIG_PARAMETER_NAME.(fieldNames{idConfParam}) =  g_decArgo_outputNcConfParamLabel{idF};
                  else
                     fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
                        g_decArgo_floatNum, ...
                        confParamName);
                  end
               else
                  fprintf('ERROR: Float #%d: Inconsistent CONFIG_PARAMETER_NAME found in json meta-data file :''%s''\n', ...
                     g_decArgo_floatNum, ...
                     confParamName);
               end
            end
         end
      end
      
      % retrieve configuration information from metaData structures
      configName = [];
      fieldNames = fieldnames(metaData.CONFIG_PARAMETER_NAME);
      for idL = 1:length(fieldNames)
         configName{end+1} = metaData.CONFIG_PARAMETER_NAME.(fieldNames{idL});
      end
      configName = configName';
      
      configValue = nan(length(configName), length(metaData.CONFIG_PARAMETER_VALUE));
      for idC = 1:size(configValue, 2)
         conf = metaData.CONFIG_PARAMETER_VALUE{idC};
         if (~isempty(conf))
            fieldNames = fieldnames(conf);
            for idL = 1:length(fieldNames)
               confParamVal = conf.(fieldNames{idL});
               if (~isempty(confParamVal))
                  configValue(idL, idC) = str2num(confParamVal);
               end
            end
         end
      end
      
      idDel = [];
      for idL = 1:size(configValue, 1)
         if (sum(isnan(configValue(idL, :))) == size(configValue, 2))
            idDel = [idDel; idL];
         end
      end
      configName(idDel) = [];
      configValue(idDel, :) = [];
      configValue(isnan(configValue)) = 99999;
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      nbLaunchConfigParam = length(configName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = cat(2, configValue(:, 1), configValue);
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         missionConfigValue(:, 1) = [];
         configMissionNumber = 1:size(configValue, 2);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      nbConfigParam = length(missionConfigName);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {30, 32}
      
      % Arvor ARN
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      configName = a_structConfig.NAMES;
      configValue = a_structConfig.VALUES;
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      nbLaunchConfigParam = length(configName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      nbConfigParam = length(missionConfigName);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 301, 302, 303}
      
      % Remocean floats
      
      % select Argo and Auxiliary configuration information
      staticConfigName = a_structConfig.STATIC_NC.NAMES;
      staticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputStaticConfigName = [];
      inputStaticConfigValue = [];
      inputAuxStaticConfigName = [];
      inputAuxStaticConfigValue = [];
      inputAuxMetaName = [];
      inputAuxMetaValue = [];
      inputAuxMetaDescription = [];
      for idC = 1:length(staticConfigName)
         if (strncmp(staticConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxStaticConfigName = [inputAuxStaticConfigName; staticConfigName(idC)];
            inputAuxStaticConfigValue = [inputAuxStaticConfigValue; staticConfigValue(idC)];
         elseif (strncmp(staticConfigName{idC}, 'META_AUX_', length('META_AUX_')))
            inputAuxMetaName = [inputAuxMetaName; staticConfigName(idC)];
            inputAuxMetaValue = [inputAuxMetaValue; staticConfigValue(idC)];
            inputAuxMetaDescription = [inputAuxMetaDescription; ...
               g_decArgo_outputNcConfParamDescription(find(strcmp(staticConfigName(idC), g_decArgo_outputNcConfParamLabel), 1))];
         elseif (strncmp(staticConfigName{idC}, 'META_', length('META_')))
            % not used
         else
            inputStaticConfigName = [inputStaticConfigName; staticConfigName(idC)];
            inputStaticConfigValue = [inputStaticConfigValue; staticConfigValue(idC)];
         end
      end
      
      % we create the dynamic configurations including AUX parameters (they will
      % be selected later)
      inputDynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      inputDynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      % concat the input configuration information
      inputStaticConfigName = a_structConfig.STATIC_NC.NAMES;
      inputStaticConfigValue = a_structConfig.STATIC_NC.VALUES;
            
      configName = [inputStaticConfigName; inputDynamicConfigName];
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      if (~isempty(inputStaticConfigValue))
         staticConfigValue = nan(size(inputStaticConfigValue, 1), size(inputDynamicConfigValue, 2));
         staticConfigValue(:, 1) = str2num(char(inputStaticConfigValue));
         
         configValue = cat(1, staticConfigValue, inputDynamicConfigValue);
      else
         configValue = inputDynamicConfigValue;
      end
            
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);

      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);

      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.DYNAMIC_NC.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
            
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];

      % create/update NetCDF META_AUX file
      if (isfield(metaDataAux, 'SENSOR') || ~isempty(inputAuxStaticConfigName) || ...
            ~isempty(missionAuxConfigName) || ~isempty(inputAuxMetaName))
         create_nc_meta_aux_file( ...
            inputAuxMetaName, inputAuxMetaValue, inputAuxMetaDescription, ...
            inputAuxStaticConfigName, inputAuxStaticConfigValue, ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end
      
      nbConfigParam = length(missionConfigName);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {121, 122, 123, 124, 125, 126}
      
      % CTS5 floats
      
      % select Argo and Auxiliary configuration information
      staticConfigName = a_structConfig.STATIC_NC.NAMES;
      staticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputStaticConfigName = [];
      inputStaticConfigValue = [];
      inputAuxStaticConfigName = [];
      inputAuxStaticConfigValue = [];
      inputAuxMetaName = [];
      inputAuxMetaValue = [];
      inputAuxMetaDescription = [];
      for idC = 1:length(staticConfigName)
         if (strncmp(staticConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxStaticConfigName = [inputAuxStaticConfigName; staticConfigName(idC)];
            inputAuxStaticConfigValue = [inputAuxStaticConfigValue; staticConfigValue(idC)];
         elseif (strncmp(staticConfigName{idC}, 'META_AUX_', length('META_AUX_')))
            inputAuxMetaName = [inputAuxMetaName; staticConfigName(idC)];
            inputAuxMetaValue = [inputAuxMetaValue; staticConfigValue(idC)];
            inputAuxMetaDescription = [inputAuxMetaDescription; ...
               g_decArgo_outputNcConfParamDescription(find(strcmp(staticConfigName(idC), g_decArgo_outputNcConfParamLabel), 1))];
         elseif (strncmp(staticConfigName{idC}, 'META_', length('META_')))
            % not used
         else
            inputStaticConfigName = [inputStaticConfigName; staticConfigName(idC)];
            inputStaticConfigValue = [inputStaticConfigValue; staticConfigValue(idC)];
         end
      end
      
      % CTS5-USEA
      if (a_decoderId == 126)
         if (isfield(metaData, 'META_AUX_FLOAT_SIM_CARD_NUMBER'))
            inputAuxMetaName = [inputAuxMetaName; 'META_AUX_FLOAT_SIM_CARD_NUMBER'];
            inputAuxMetaValue = [inputAuxMetaValue; metaData.META_AUX_FLOAT_SIM_CARD_NUMBER];
            inputAuxMetaDescription = [inputAuxMetaDescription; ...
               g_decArgo_outputNcConfParamDescription(find(strcmp('META_AUX_FLOAT_SIM_CARD_NUMBER', g_decArgo_outputNcConfParamLabel), 1))];
         end
         if (isfield(metaData, 'META_AUX_FIRMWARE_VERSION_SECONDARY'))
            inputAuxMetaName = [inputAuxMetaName; 'META_AUX_FIRMWARE_VERSION_SECONDARY'];
            inputAuxMetaValue = [inputAuxMetaValue; metaData.META_AUX_FIRMWARE_VERSION_SECONDARY];
            inputAuxMetaDescription = [inputAuxMetaDescription; ...
               g_decArgo_outputNcConfParamDescription(find(strcmp('META_AUX_FIRMWARE_VERSION_SECONDARY', g_decArgo_outputNcConfParamLabel), 1))];
         end
         if (isfield(metaData, 'META_AUX_UVP_CONFIG_PARAMETERS'))
            fieldNames = fields(metaData.META_AUX_UVP_CONFIG_PARAMETERS);
            for idConf = 1:11
               if (idConf == 11)
                  confName = 'META_AUX_UVP_HW_CONF_PARAMETERS';
               else
                  confName = sprintf('META_AUX_UVP_ACQ_CONF_%02d_PARAMETERS', idConf);
               end
               inputAuxMetaName = [inputAuxMetaName; confName];
               inputAuxMetaValue = [inputAuxMetaValue; metaData.META_AUX_UVP_CONFIG_PARAMETERS.(fieldNames{idConf})];
               inputAuxMetaDescription = [inputAuxMetaDescription; ...
                  g_decArgo_outputNcConfParamDescription(find(strcmp(confName, g_decArgo_outputNcConfParamLabel), 1))];
            end
         end
      end
      
      % retrieve meta-data from APMT tech files
      if (~isempty(g_decArgo_apmtMetaFromTech))
         
         % delete duplicates
         metaStructList = [g_decArgo_apmtMetaFromTech{:}];
         idList = [metaStructList.techId];
         if (~isempty(idList))
            uIdList = unique(idList);
            if (length(uIdList) == 1)
               g_decArgo_apmtMetaFromTech(2:end) = [];
            else
               nbElts = hist(idList, uIdList);
               idDel = [];
               idToDel = uIdList(find(nbElts > 1));
               for id = idToDel
                  idF = find(idList == id);
                  idDel = [idDel idF(2:end)];
               end
               g_decArgo_apmtMetaFromTech(idDel) = [];
            end
         end
         
         for idM = 1:length(g_decArgo_apmtMetaFromTech)
            metaStruct = g_decArgo_apmtMetaFromTech{idM};
            idMetaName = find(g_decArgo_outputNcParamId == metaStruct.techId);
            metaName = char(g_decArgo_outputNcParamLabel{idMetaName});
            metaDescription = char(g_decArgo_outputNcParamDescription{idMetaName});

            if (strncmp(metaName, 'META_AUX_', length('META_AUX_')))
               inputAuxMetaName = [inputAuxMetaName; metaName];
               inputAuxMetaValue = [inputAuxMetaValue; metaStruct.value];
               inputAuxMetaDescription = [inputAuxMetaDescription; metaDescription];
            elseif (strncmp(staticConfigName{idC}, 'META_', length('META_')))
               % not used
            end
         end
      end
      
      %       dynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      %       dynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      %
      %       inputDynamicConfigName = [];
      %       inputDynamicConfigValue = [];
      %       inputAuxDynamicConfigName = [];
      %       inputAuxDynamicConfigValue = [];
      %       for idC = 1:length(dynamicConfigName)
      %          if (strncmp(dynamicConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
      %             inputAuxDynamicConfigName = [inputAuxDynamicConfigName; dynamicConfigName(idC)];
      %             inputAuxDynamicConfigValue = [inputAuxDynamicConfigValue; dynamicConfigValue(idC, :)];
      %          elseif (strncmp(dynamicConfigName{idC}, 'META_AUX_', length('META_AUX_')))
      %             inputAuxMetaName = [inputAuxMetaName; dynamicConfigName(idC)];
      %             inputAuxMetaValue = [inputAuxMetaValue; dynamicConfigValue(idC, :)];
      %          elseif (strncmp(dynamicConfigName{idC}, 'META_', length('META_')))
      %             % not used
      %          else
      %             inputDynamicConfigName = [inputDynamicConfigName; dynamicConfigName(idC)];
      %             inputDynamicConfigValue = [inputDynamicConfigValue; dynamicConfigValue(idC, :)];
      %          end
      %       end
      
      % we create the dynamic configurations including AUX parameters (they will
      % be selected later)
      inputDynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      inputDynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      % concat the input configuration information      
      configName = [inputStaticConfigName; inputDynamicConfigName];
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      if (~isempty(inputStaticConfigValue))
         staticConfigValue = nan(size(inputStaticConfigValue, 1), size(inputDynamicConfigValue, 2));
         inputStaticConfigValue = regexprep(inputStaticConfigValue, 'True', '1');
         inputStaticConfigValue = regexprep(inputStaticConfigValue, 'False', '0');
         inputStaticConfigValue = regexprep(inputStaticConfigValue, 'yes', '1');
         inputStaticConfigValue = regexprep(inputStaticConfigValue, 'no', '0');
         staticConfigValue(:, 1) = cellfun(@str2num, inputStaticConfigValue);
         
         configValue = cat(1, staticConfigValue, inputDynamicConfigValue);
      else
         configValue = inputDynamicConfigValue;
      end
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);

      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.DYNAMIC_NC.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];
      
      % create/update NetCDF META_AUX file
      if (isfield(metaDataAux, 'SENSOR') || ~isempty(inputAuxStaticConfigName) || ...
            ~isempty(missionAuxConfigName) || ~isempty(inputAuxMetaName))
         create_nc_meta_aux_file( ...
            inputAuxMetaName, inputAuxMetaValue, inputAuxMetaDescription, ...
            inputAuxStaticConfigName, inputAuxStaticConfigValue, ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end
      
      nbConfigParam = length(missionConfigName);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, ...
         214, 215, 216, 217, 218, 219, 220}
      
      % Arvor deep 4000
      % Arvor deep 3500
      % Arvor iridium
      % Provor-DO Iridium
      % Arvor-2DO Iridium
      % Arvor-ARN Iridium
      % Arvor-ARN-Ice Iridium 5.45
      % Provor-ARN-DO Iridium
      % Provor-ARN-DO-Ice Iridium
      % Arvor deep 4000 with "Near Surface" & "In Air" measurements
      % Arvor-Deep-Ice Iridium 5.65
      % Arvor-ARN-DO-Ice Iridium 5.46
      % Arvor-Deep-Ice Iridium 5.66
      % Arvor-C Iridium 5.3 & 5.301
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      % concat the input configuration information
      inputStaticConfigName = a_structConfig.STATIC_NC.NAMES;
      inputStaticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputDynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      inputDynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      
      configName = [inputStaticConfigName; inputDynamicConfigName];
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      configValue = inputDynamicConfigValue;
      if (~isempty(inputStaticConfigName))
         staticConfigValue = nan(size(inputStaticConfigName, 1), size(inputDynamicConfigValue, 2));
         if (~isempty(inputStaticConfigValue))
            staticConfigValue(:, 1) = str2num(char(inputStaticConfigValue));
         end
         configValue = cat(1, staticConfigValue, inputDynamicConfigValue);
      end
      
      % TEMPORARY CODE
      %       if ((a_decoderId == 210) || (a_decoderId == 211))
      %
      %          % exclude configuration labels not accepted yet by the GDAC checker
      %          exclusionList = [ ...
      %             {'CONFIG_InAirMeasurementPeriodicity_NUMBER'} ...
      %             {'CONFIG_InAirMeasurementSamplingTime_seconds'} ...
      %             {'CONFIG_InAirMeasurementPhaseDuration_minutes'} ...
      %             {'CONFIG_PumpActionTimeBuoyancyAcquisitionForInAirMeasCycle_csec'} ...
      %             ];
      %          idDel = [];
      %          for idL = 1:length(configName)
      %             if (ismember(configName{idL}, exclusionList))
      %                idDel = [idDel idL];
      %             end
      %          end
      %          configName(idDel) = [];
      %          configValue(idDel, :) = [];
      %       end
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      nbLaunchConfigParam = length(configName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.DYNAMIC_NC.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      nbConfigParam = length(missionConfigName);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {221}
      
      % Arvor-Deep-Ice Iridium 5.67
      
      % select Argo and Auxiliary configuration information
      staticConfigName = a_structConfig.STATIC_NC.NAMES;
      staticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputAuxStaticConfigName = [];
      inputAuxStaticConfigValue = [];
      for idC = 1:length(staticConfigName)
         if (strncmp(staticConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxStaticConfigName = [inputAuxStaticConfigName; staticConfigName(idC)];
            inputAuxStaticConfigValue = [inputAuxStaticConfigValue; staticConfigValue(idC)];
         end
      end
      
      % we create the dynamic configurations including AUX parameters (they will
      % be selected later)

      % concat the input configuration information
      inputStaticConfigName = a_structConfig.STATIC_NC.NAMES;
      inputStaticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputDynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      inputDynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      
      configName = [inputStaticConfigName; inputDynamicConfigName];
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);

      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      configValue = inputDynamicConfigValue;
      if (~isempty(inputStaticConfigName))
         staticConfigValue = nan(size(inputStaticConfigName, 1), size(inputDynamicConfigValue, 2));
         if (~isempty(inputStaticConfigValue))
            staticConfigValue(:, 1) = str2num(char(inputStaticConfigValue));
         end
         configValue = cat(1, staticConfigValue, inputDynamicConfigValue);
      end
            
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);

      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);

      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.DYNAMIC_NC.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
            
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];      
      
      nbConfigParam = length(missionConfigName);      

      % create/update NetCDF META_AUX file
      if (~isempty(inputAuxStaticConfigName) || ...
            ~isempty(launchAuxConfigName) || ...
            ~isempty(missionAuxConfigName))
         % collect AUX meta-data information
         metaDataAux = [];
         metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
         metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
         metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
         create_nc_meta_aux_file( ...
            [], [], [], ...
            inputAuxStaticConfigName, inputAuxStaticConfigValue, ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {222, 223}
      
      % Arvor-ARN-Ice Iridium 5.47
      % Arvor-ARN-DO-Ice Iridium 5.48
      
      % select Argo and Auxiliary configuration information
      staticConfigName = a_structConfig.STATIC_NC.NAMES;
      staticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputAuxStaticConfigName = [];
      inputAuxStaticConfigValue = [];
      for idC = 1:length(staticConfigName)
         if (strncmp(staticConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxStaticConfigName = [inputAuxStaticConfigName; staticConfigName(idC)];
            inputAuxStaticConfigValue = [inputAuxStaticConfigValue; staticConfigValue(idC)];
         end
      end
      
      % we create the dynamic configurations including AUX parameters (they will
      % be selected later)

      % concat the input configuration information
      inputStaticConfigName = a_structConfig.STATIC_NC.NAMES;
      inputStaticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputDynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      inputDynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      
      configName = [inputStaticConfigName; inputDynamicConfigName];

      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      configValue = inputDynamicConfigValue;
      if (~isempty(inputStaticConfigName))
         staticConfigValue = nan(size(inputStaticConfigName, 1), size(inputDynamicConfigValue, 2));
         if (~isempty(inputStaticConfigValue))
            staticConfigValue(:, 1) = str2num(char(inputStaticConfigValue));
         end
         configValue = cat(1, staticConfigValue, inputDynamicConfigValue);
      end
            
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      
      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);

      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.DYNAMIC_NC.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];      

      nbConfigParam = length(missionConfigName);      
      
      % create/update NetCDF META_AUX file
      if (~isempty(inputAuxStaticConfigName) || ...
            ~isempty(launchAuxConfigName) || ...
            ~isempty(missionAuxConfigName))
         % collect AUX meta-data information
         metaDataAux = [];
         metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
         metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
         metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
         create_nc_meta_aux_file( ...
            [], [], [], ...
            inputAuxStaticConfigName, inputAuxStaticConfigValue, ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % APEX Argos floats
      
   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016}
            
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      % if no data has been received create the configuration at launch
      if (isempty(a_structConfig.NAMES))
         
         % create and initialize the launch configuration
         create_float_config_apx_argos([], a_decoderId);
         
         % create the configuration parameter names for the META NetCDF file
         [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_apx_argos(a_decoderId);
         
         % create output float configuration
         [a_structConfig] = create_output_float_config_argos(decArgoConfParamNames, ncConfParamNames, a_decoderId);
      end
      
      configName = a_structConfig.NAMES;
      configValue = a_structConfig.VALUES;
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      nbLaunchConfigParam = length(configName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         configMissionNumber = a_structConfig.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      nbConfigParam = length(missionConfigName);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % APEX Argos APF11
      
   case {1021, 1022}
            
      % AUX meta-data
      inputStaticConfigName = a_structConfig.STATIC_NC.NAMES;
      inputStaticConfigValue = a_structConfig.STATIC_NC.VALUES;

      inputAuxMetaName = [];
      inputAuxMetaValue = [];
      inputAuxMetaDescription = [];
      for idC = 1:length(inputStaticConfigName)
         if (strncmp(inputStaticConfigName{idC}, 'META_AUX_', length('META_AUX_')))
            inputAuxMetaName = [inputAuxMetaName; inputStaticConfigName(idC)];
            inputAuxMetaValue = [inputAuxMetaValue; inputStaticConfigValue(idC)];
            inputAuxMetaDescription = [inputAuxMetaDescription; ...
               g_decArgo_outputNcConfParamDescription(find(strcmp(inputStaticConfigName(idC), g_decArgo_outputNcConfParamLabel), 1))];
         end
      end
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      % if no data has been received create the configuration at launch
      if (isempty(a_structConfig.NAMES))
         
         % create and initialize the launch configuration
         create_float_config_apx_argos([], a_decoderId);
         
         % create the configuration parameter names for the META NetCDF file
         [decArgoConfParamNames, ncConfParamNames] = create_config_param_names_apx_argos(a_decoderId);
         
         % create output float configuration
         [a_structConfig] = create_output_float_config_argos(decArgoConfParamNames, ncConfParamNames, a_decoderId);
      end
      
      configName = a_structConfig.NAMES;
      configValue = a_structConfig.VALUES;
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % select Auxiliary configuration information
      inputAuxConfigName = [];
      inputAuxConfigValue = [];
      for idC = 1:length(configName)
         if (strncmp(configName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxConfigName = [inputAuxConfigName; configName(idC)];
            inputAuxConfigValue = [inputAuxConfigValue; configValue(idC)];
         end
      end      
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      
      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);

      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         configMissionNumber = a_structConfig.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];
      
      nbConfigParam = length(missionConfigName);      
      
      % create/update NetCDF META_AUX file
      if (~isempty(inputAuxConfigName) || ~isempty(missionAuxConfigName))
         % collect AUX meta-data information
         metaDataAux = [];
         metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
         metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
         metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
         create_nc_meta_aux_file( ...
            inputAuxMetaName, inputAuxMetaValue, inputAuxMetaDescription, ...
            [], [], ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % APEX APF11 Iridium
      
   case {1121, 1122, 1123, 1124, 1125, 1126, 1127, 1321, 1322, 1323}
                  
      % retrieve mandatory configuration names for this decoder
      mandatoryConfigName = get_config_param_mandatory(a_decoderId);
            
      configName = a_structConfig.NAMES;
      configValue = a_structConfig.VALUES;
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % select Auxiliary configuration information
      inputAuxConfigName = [];
      inputAuxConfigValue = [];
      for idC = 1:length(configName)
         if (strncmp(configName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxConfigName = [inputAuxConfigName; configName(idC)];
            inputAuxConfigValue = [inputAuxConfigValue; configValue(idC)];
         end
      end      
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      
      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);

      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];
      
      % clean piston configuration parameters from output Argo configuration
      configNameToRemove = [{'CONFIG_PistonPark_COUNT'} {'CONFIG_PistonProfile_COUNT'}];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (~isempty(find(strcmp(missionConfigName{idC}, configNameToRemove) == 1, 1)))
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];
      
      nbConfigParam = length(missionConfigName);      
      
      % create/update NetCDF META_AUX file
      if (~isempty(inputAuxConfigName) || ~isempty(missionAuxConfigName))
         % collect AUX meta-data information
         metaDataAux = [];
         metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
         metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
         metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
         create_nc_meta_aux_file( ...
            [], [], [], ...
            [], [], ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % APEX Iridium Rudics & Navis floats
      
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, ...
         1201, 1314}
            
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      configName = a_structConfig.NAMES;
      configValue = a_structConfig.VALUES;
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % select Auxiliary configuration information
      inputAuxConfigName = [];
      inputAuxConfigValue = [];
      for idC = 1:length(configName)
         if (strncmp(configName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxConfigName = [inputAuxConfigName; configName(idC)];
            inputAuxConfigValue = [inputAuxConfigValue; configValue(idC)];
         end
      end      
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      
      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];
      
      nbConfigParam = length(missionConfigName);  
      
      % create/update NetCDF META_AUX file
      if (~isempty(inputAuxConfigName) || ~isempty(missionAuxConfigName))
         % collect AUX meta-data information
         metaDataAux = [];
         metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
         metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
         metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
         create_nc_meta_aux_file( ...
            [], [], [], ...
            [], [], ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end      
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % NOVA, DOVA floats

   case {2001, 2002, 2003} % Nova, Dova
      
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      % concat the input configuration information
      inputStaticConfigName = a_structConfig.STATIC_NC.NAMES;
      inputStaticConfigValue = a_structConfig.STATIC_NC.VALUES;
      
      inputDynamicConfigName = a_structConfig.DYNAMIC_NC.NAMES;
      inputDynamicConfigValue = a_structConfig.DYNAMIC_NC.VALUES;
      
      % siwtch 0 <-> 1 in CONFIG_PH38 parameter (the float meaning is the
      % contrary to the NetCDF label one)
      idF = find(strcmp('PH38', g_decArgo_outputNcConfParamId) == 1);
      if (~isempty(idF))
         idF2 = find(strcmp(g_decArgo_outputNcConfParamLabel{idF}, inputDynamicConfigName) == 1);
         if (~isempty(idF2))
            values = inputDynamicConfigValue(idF2, :);
            values = values + 1;
            values(find(values == 2)) = 0;
            inputDynamicConfigValue(idF2, :) = values;
         end
      end
      
      configName = [inputStaticConfigName; inputDynamicConfigName];
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      if (~isempty(inputStaticConfigName))
         staticConfigValue = nan(size(inputStaticConfigName, 1), size(inputDynamicConfigValue, 2));
         if (~isempty(inputStaticConfigValue))
            staticConfigValue(:, 1) = str2num(char(inputStaticConfigValue));
         end
      end
      configValue = cat(1, staticConfigValue, inputDynamicConfigValue);
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      nbLaunchConfigParam = length(configName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         % don't keep launch mission
         missionConfigValue(:, 1) = [];
         configMissionNumber = a_structConfig.DYNAMIC_NC.NUMBER(2:end);
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      nbConfigParam = length(missionConfigName);      

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % NEMO floats
      
   case {3001}
            
      % retrieve mandatory configuration names for this decoder
      [mandatoryConfigName] = get_config_param_mandatory(a_decoderId);
      
      configName = a_structConfig.NAMES;
      configValue = a_structConfig.VALUES;
      
      mandatoryList = [];
      for idL = 1:length(mandatoryConfigName)
         for idC = 1:length(configName)
            if (~isempty(strfind(configName{idC}, mandatoryConfigName{idL})))
               mandatoryList = [mandatoryList idC];
               if (idL < length(mandatoryConfigName))
                  break
               end
            end
         end
      end
      
      % select Auxiliary configuration information
      inputAuxConfigName = [];
      inputAuxConfigValue = [];
      for idC = 1:length(configName)
         if (strncmp(configName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            inputAuxConfigName = [inputAuxConfigName; configName(idC)];
            inputAuxConfigValue = [inputAuxConfigValue; configValue(idC)];
         end
      end      
      
      % create the launch configuration
      launchConfigName = configName;
      launchConfigValue = configValue(:, 1);
      
      % clean AUX parameters from output Argo launch configuration
      launchAuxConfigName = [];
      launchAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(launchConfigName)
         if (strncmp(launchConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            launchAuxConfigName = [launchAuxConfigName; launchConfigName(idC)];
            launchAuxConfigValue = [launchAuxConfigValue; launchConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      launchConfigName(idDel) = [];
      launchConfigValue(idDel, :) = [];
      
      nbLaunchConfigParam = length(launchConfigName);
      
      % create the mission configuration
      missionConfigName = configName;
      missionConfigValue = configValue;
      
      if (size(configValue, 2) > 1)
         idDel = [];
         for idL = 1:size(missionConfigValue, 1)
            if (sum(isnan(missionConfigValue(idL, 2:end))) == size(missionConfigValue, 2)-1)
               idDel = [idDel; idL];
            elseif ((length(unique(missionConfigValue(idL, 2:end))) == 1) && ...
                  (unique(missionConfigValue(idL, 2:end)) == missionConfigValue(idL, 1)))
               idDel = [idDel; idL];
            end
         end
         idDel = setdiff(idDel, mandatoryList);
         missionConfigName(idDel) = [];
         missionConfigValue(idDel, :) = [];
         configMissionNumber = a_structConfig.NUMBER;
      else
         missionConfigName = configName(mandatoryList);
         missionConfigValue = configValue(mandatoryList, 1);
         configMissionNumber = 1;
      end
      
      % clean AUX parameters from output Argo configuration
      missionAuxConfigName = [];
      missionAuxConfigValue = [];
      idDel = [];
      for idC = 1:length(missionConfigName)
         if (strncmp(missionConfigName{idC}, 'CONFIG_AUX_', length('CONFIG_AUX_')))
            missionAuxConfigName = [missionAuxConfigName; missionConfigName(idC)];
            missionAuxConfigValue = [missionAuxConfigValue; missionConfigValue(idC, :)];
            idDel = [idDel; idC];
         end
      end
      missionConfigName(idDel) = [];
      missionConfigValue(idDel, :) = [];
      
      nbConfigParam = length(missionConfigName);  
      
      % create/update NetCDF META_AUX file
      if (~isempty(inputAuxConfigName) || ~isempty(missionAuxConfigName))
         % collect AUX meta-data information
         metaDataAux = [];
         metaDataAux.DATA_CENTRE = metaData.DATA_CENTRE;
         metaDataAux.PLATFORM_NUMBER = metaData.PLATFORM_NUMBER;
         metaDataAux.FLOAT_SERIAL_NO = metaData.FLOAT_SERIAL_NO;
         create_nc_meta_aux_file( ...
            [], [], [], ...
            [], [], ...
            launchAuxConfigName, launchAuxConfigValue, ...
            missionAuxConfigName, missionAuxConfigValue, configMissionNumber, ...
            metaDataAux);
      end           
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in launch and mission configurations processing for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

nbPositioningSystem = 0;
if (~isempty(metaData.POSITIONING_SYSTEM))
   nbPositioningSystem = length(fieldnames(metaData.POSITIONING_SYSTEM));
end
nbTransSystem = 0;
if (~isempty(metaData.TRANS_SYSTEM))
   nbTransSystem = length(fieldnames(metaData.TRANS_SYSTEM));
end

% create output file pathname
floatNumStr = num2str(g_decArgo_floatNum);
outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

ncFileName = [floatNumStr '_meta.nc'];
ncPathFileName = [outputDirName  ncFileName];

% information to retrieve from a possible existing meta-data file
ncCreationDate = '';
if (exist(ncPathFileName, 'file') == 2)
   
   % retrieve information from existing file
   wantedMetaVars = [ ...
      {'DATE_CREATION'} ...
      ];
   
   % retrieve information from META-DATA netCDF file
   [ncMetaData] = get_data_from_nc_file(ncPathFileName, wantedMetaVars);
   
   idVal = find(strcmp('DATE_CREATION', ncMetaData) == 1);
   if (~isempty(idVal))
      ncCreationDate = ncMetaData{idVal+1}';
   end
   
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Updating NetCDF META-DATA file (%s) ...\n', ncFileName);
   end
   
else
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Creating NetCDF META-DATA file (%s) ...\n', ncFileName);
   end
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

% create and open NetCDF file
fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
if (isempty(fCdf))
   fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE MODE BEGIN
if (VERBOSE_MODE == 2)
   fprintf('START DEFINE MODE\n');
end

% create dimensions
dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
string4096DimId = netcdf.defDim(fCdf, 'STRING4096', 4096);
string1024DimId = netcdf.defDim(fCdf, 'STRING1024', 1024);
string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
string128DimId = netcdf.defDim(fCdf, 'STRING128', 128);
string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

if (nbParam == 0)
   nbParam = 1;
end
nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbParam);

if (nbSensor == 0)
   nbSensor = 1;
end
nSensorDimId = netcdf.defDim(fCdf, 'N_SENSOR', nbSensor);

if (nbConfigParam == 0)
   nbConfigParam = 1;
end
nConfigParamDimId = netcdf.defDim(fCdf, 'N_CONFIG_PARAM', nbConfigParam);

if (nbLaunchConfigParam == 0)
   nbLaunchConfigParam = 1;
end
nLaunchConfigParamDimId = netcdf.defDim(fCdf, 'N_LAUNCH_CONFIG_PARAM', nbLaunchConfigParam);

nMissionsDimId = netcdf.defDim(fCdf, 'N_MISSIONS', netcdf.getConstant('NC_UNLIMITED'));

if (nbPositioningSystem == 0)
   nbPositioningSystem = 1;
end
nPositioningSystemDimId = netcdf.defDim(fCdf, 'N_POSITIONING_SYSTEM', nbPositioningSystem);

if (nbTransSystem == 0)
   nbTransSystem = 1;
end
nTransSystemDimId = netcdf.defDim(fCdf, 'N_TRANS_SYSTEM', nbTransSystem);

if (VERBOSE_MODE == 2)
   fprintf('N_PARAM = %d\n', nbParam);
   fprintf('N_SENSOR = %d\n', nbSensor);
   fprintf('N_CONFIG_PARAM = %d\n', nbConfigParam);
   fprintf('N_LAUNCH_CONFIG_PARAM = %d\n', nbLaunchConfigParam);
   fprintf('N_POSITIONING_SYSTEM = %d\n', nbPositioningSystem);
   fprintf('N_TRANS_SYSTEM = %d\n', length(nbTransSystem));
end

% create global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float metadata file');

institution = 'CORIOLIS';
inputElt = getfield(metaData, 'DATA_CENTRE');
if (~isempty(inputElt))
   dataCentre = getfield(metaData, 'DATA_CENTRE');
   [institution] = get_institution_from_data_centre(dataCentre, 1);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
if (isempty(ncCreationDate))
   globalHistoryText = [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
else
   globalHistoryText = [datestr(datenum(ncCreationDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
end
globalHistoryText = [globalHistoryText ...
   datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis float real time data processing)'];
netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.1');
netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));

% general information on the meta-data file
dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string16DimId);
netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
netcdf.putAtt(fCdf, dataTypeVarId, 'conventions', 'Argo reference table 1');
netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');

formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');

handbookVersionVarId = netcdf.defVar(fCdf, 'HANDBOOK_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, handbookVersionVarId, 'long_name', 'Data handbook version');
netcdf.putAtt(fCdf, handbookVersionVarId, '_FillValue', ' ');

dateCreationVarId = netcdf.defVar(fCdf, 'DATE_CREATION', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateCreationVarId, 'long_name', 'Date of file creation');
netcdf.putAtt(fCdf, dateCreationVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateCreationVarId, '_FillValue', ' ');

dateUpdateVarId = netcdf.defVar(fCdf, 'DATE_UPDATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateUpdateVarId, 'long_name', 'Date of update of this file');
netcdf.putAtt(fCdf, dateUpdateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateUpdateVarId, '_FillValue', ' ');

% float characteristics
floatNcVarId = [];
floatNcVarName = [];
platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', string8DimId);
netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; platformNumberVarId];
floatNcVarName{end+1} = 'PLATFORM_NUMBER';

pttVarId = netcdf.defVar(fCdf, 'PTT', 'NC_CHAR', string256DimId);
netcdf.putAtt(fCdf, pttVarId, 'long_name', 'Transmission identifier (ARGOS, ORBCOMM, etc.)');
netcdf.putAtt(fCdf, pttVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; pttVarId];
floatNcVarName{end+1} = 'PTT';

transSystemVarId = netcdf.defVar(fCdf, 'TRANS_SYSTEM', 'NC_CHAR', fliplr([nTransSystemDimId string16DimId]));
netcdf.putAtt(fCdf, transSystemVarId, 'long_name', 'Telecommunications system used');
netcdf.putAtt(fCdf, transSystemVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; transSystemVarId];
floatNcVarName{end+1} = 'TRANS_SYSTEM';

transSystemIdVarId = netcdf.defVar(fCdf, 'TRANS_SYSTEM_ID', 'NC_CHAR', fliplr([nTransSystemDimId string32DimId]));
netcdf.putAtt(fCdf, transSystemIdVarId, 'long_name', 'Program identifier used by the transmission system');
netcdf.putAtt(fCdf, transSystemIdVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; transSystemIdVarId];
floatNcVarName{end+1} = 'TRANS_SYSTEM_ID';

transFrequencyVarId = netcdf.defVar(fCdf, 'TRANS_FREQUENCY', 'NC_CHAR', fliplr([nTransSystemDimId string16DimId]));
netcdf.putAtt(fCdf, transFrequencyVarId, 'long_name', 'Frequency of transmission from the float');
netcdf.putAtt(fCdf, transFrequencyVarId, 'units', 'hertz');
netcdf.putAtt(fCdf, transFrequencyVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; transFrequencyVarId];
floatNcVarName{end+1} = 'TRANS_FREQUENCY';

positioningSystemVarId = netcdf.defVar(fCdf, 'POSITIONING_SYSTEM', 'NC_CHAR', fliplr([nPositioningSystemDimId string8DimId]));
netcdf.putAtt(fCdf, positioningSystemVarId, 'long_name', 'Positioning system');
netcdf.putAtt(fCdf, positioningSystemVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; positioningSystemVarId];
floatNcVarName{end+1} = 'POSITIONING_SYSTEM';

platformFamilyVarId = netcdf.defVar(fCdf, 'PLATFORM_FAMILY', 'NC_CHAR', string256DimId);
netcdf.putAtt(fCdf, platformFamilyVarId, 'long_name', 'Category of instrument');
netcdf.putAtt(fCdf, platformFamilyVarId, 'conventions', 'Argo reference table 22');
netcdf.putAtt(fCdf, platformFamilyVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; platformFamilyVarId];
floatNcVarName{end+1} = 'PLATFORM_FAMILY';

platformTypeVarId = netcdf.defVar(fCdf, 'PLATFORM_TYPE', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, platformTypeVarId, 'long_name', 'Type of float');
netcdf.putAtt(fCdf, platformTypeVarId, 'conventions', 'Argo reference table 23');
netcdf.putAtt(fCdf, platformTypeVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; platformTypeVarId];
floatNcVarName{end+1} = 'PLATFORM_TYPE';

platformMakerVarId = netcdf.defVar(fCdf, 'PLATFORM_MAKER', 'NC_CHAR', string256DimId);
netcdf.putAtt(fCdf, platformMakerVarId, 'long_name', 'Name of the manufacturer');
netcdf.putAtt(fCdf, platformMakerVarId, 'conventions', 'Argo reference table 24');
netcdf.putAtt(fCdf, platformMakerVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; platformMakerVarId];
floatNcVarName{end+1} = 'PLATFORM_MAKER';

firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Firmware version for the float');
netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; firmwareVersionVarId];
floatNcVarName{end+1} = 'FIRMWARE_VERSION';

manualVersionVarId = netcdf.defVar(fCdf, 'MANUAL_VERSION', 'NC_CHAR', string16DimId);
netcdf.putAtt(fCdf, manualVersionVarId, 'long_name', 'Manual version for the float');
netcdf.putAtt(fCdf, manualVersionVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; manualVersionVarId];
floatNcVarName{end+1} = 'MANUAL_VERSION';

floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; floatSerialNoVarId];
floatNcVarName{end+1} = 'FLOAT_SERIAL_NO';

standardFormatIdVarId = netcdf.defVar(fCdf, 'STANDARD_FORMAT_ID', 'NC_CHAR', string16DimId);
netcdf.putAtt(fCdf, standardFormatIdVarId, 'long_name', 'Standard format number to describe the data format type for each float');
netcdf.putAtt(fCdf, standardFormatIdVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; standardFormatIdVarId];
floatNcVarName{end+1} = 'STANDARD_FORMAT_ID';

dacFormatIdVarId = netcdf.defVar(fCdf, 'DAC_FORMAT_ID', 'NC_CHAR', string16DimId);
netcdf.putAtt(fCdf, dacFormatIdVarId, 'long_name', 'Format number used by the DAC to describe the data format type for each float');
netcdf.putAtt(fCdf, dacFormatIdVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; dacFormatIdVarId];
floatNcVarName{end+1} = 'DAC_FORMAT_ID';

wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; wmoInstTypeVarId];
floatNcVarName{end+1} = 'WMO_INST_TYPE';

projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Program under which the float was deployed');
netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; projectNameVarId];
floatNcVarName{end+1} = 'PROJECT_NAME';

dataCentreVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', string2DimId);
netcdf.putAtt(fCdf, dataCentreVarId, 'long_name', 'Data centre in charge of float real-time processing');
netcdf.putAtt(fCdf, dataCentreVarId, 'conventions', 'Argo reference table 4');
netcdf.putAtt(fCdf, dataCentreVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; dataCentreVarId];
floatNcVarName{end+1} = 'DATA_CENTRE';

piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; piNameVarId];
floatNcVarName{end+1} = 'PI_NAME';

anomalyVarId = netcdf.defVar(fCdf, 'ANOMALY', 'NC_CHAR', string256DimId);
netcdf.putAtt(fCdf, anomalyVarId, 'long_name', 'Describe any anomalies or problems the float may have had');
netcdf.putAtt(fCdf, anomalyVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; anomalyVarId];
floatNcVarName{end+1} = 'ANOMALY';

batteryTypeVarId = netcdf.defVar(fCdf, 'BATTERY_TYPE', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, batteryTypeVarId, 'long_name', 'Type of battery packs in the float');
netcdf.putAtt(fCdf, batteryTypeVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; batteryTypeVarId];
floatNcVarName{end+1} = 'BATTERY_TYPE';

batteryPacksVarId = netcdf.defVar(fCdf, 'BATTERY_PACKS', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, batteryPacksVarId, 'long_name', 'Configuration of battery packs in the float');
netcdf.putAtt(fCdf, batteryPacksVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; batteryPacksVarId];
floatNcVarName{end+1} = 'BATTERY_PACKS';

controllerBoardTypePrimaryVarId = netcdf.defVar(fCdf, 'CONTROLLER_BOARD_TYPE_PRIMARY', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, controllerBoardTypePrimaryVarId, 'long_name', 'Type of primary controller board');
netcdf.putAtt(fCdf, controllerBoardTypePrimaryVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; controllerBoardTypePrimaryVarId];
floatNcVarName{end+1} = 'CONTROLLER_BOARD_TYPE_PRIMARY';

controllerBoardTypeSecondaryVarId = netcdf.defVar(fCdf, 'CONTROLLER_BOARD_TYPE_SECONDARY', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, controllerBoardTypeSecondaryVarId, 'long_name', 'Type of secondary controller board');
netcdf.putAtt(fCdf, controllerBoardTypeSecondaryVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; controllerBoardTypeSecondaryVarId];
floatNcVarName{end+1} = 'CONTROLLER_BOARD_TYPE_SECONDARY';

controllerBoardSerialNoPrimaryVarId = netcdf.defVar(fCdf, 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, controllerBoardSerialNoPrimaryVarId, 'long_name', 'Serial number of the primary controller board');
netcdf.putAtt(fCdf, controllerBoardSerialNoPrimaryVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; controllerBoardSerialNoPrimaryVarId];
floatNcVarName{end+1} = 'CONTROLLER_BOARD_SERIAL_NO_PRIMARY';

controllerBoardSerialNoSecondaryVarId = netcdf.defVar(fCdf, 'CONTROLLER_BOARD_SERIAL_NO_SECONDARY', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, controllerBoardSerialNoSecondaryVarId, 'long_name', 'Serial number of the secondary controller board');
netcdf.putAtt(fCdf, controllerBoardSerialNoSecondaryVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; controllerBoardSerialNoSecondaryVarId];
floatNcVarName{end+1} = 'CONTROLLER_BOARD_SERIAL_NO_SECONDARY';

specialFeaturesVarId = netcdf.defVar(fCdf, 'SPECIAL_FEATURES', 'NC_CHAR', string1024DimId);
netcdf.putAtt(fCdf, specialFeaturesVarId, 'long_name', 'Extra features of the float (algorithms, compressee etc.)');
netcdf.putAtt(fCdf, specialFeaturesVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; specialFeaturesVarId];
floatNcVarName{end+1} = 'SPECIAL_FEATURES';

floatOwnerVarId = netcdf.defVar(fCdf, 'FLOAT_OWNER', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, floatOwnerVarId, 'long_name', 'Float owner');
netcdf.putAtt(fCdf, floatOwnerVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; floatOwnerVarId];
floatNcVarName{end+1} = 'FLOAT_OWNER';

operatingInstitutionVarId = netcdf.defVar(fCdf, 'OPERATING_INSTITUTION', 'NC_CHAR', string64DimId);
netcdf.putAtt(fCdf, operatingInstitutionVarId, 'long_name', 'Operating institution of the float');
netcdf.putAtt(fCdf, operatingInstitutionVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; operatingInstitutionVarId];
floatNcVarName{end+1} = 'OPERATING_INSTITUTION';

customisationVarId = netcdf.defVar(fCdf, 'CUSTOMISATION', 'NC_CHAR', string1024DimId);
netcdf.putAtt(fCdf, customisationVarId, 'long_name', 'Float customisation, i.e. (institution and modifications)');
netcdf.putAtt(fCdf, customisationVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; customisationVarId];
floatNcVarName{end+1} = 'CUSTOMISATION';

% float deployment and mission information
launchDateVarId = netcdf.defVar(fCdf, 'LAUNCH_DATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, launchDateVarId, 'long_name', 'Date (UTC) of the deployment');
netcdf.putAtt(fCdf, launchDateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, launchDateVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; launchDateVarId];
floatNcVarName{end+1} = 'LAUNCH_DATE';

launchLatitudeVarId = netcdf.defVar(fCdf, 'LAUNCH_LATITUDE', 'NC_DOUBLE', []);
netcdf.putAtt(fCdf, launchLatitudeVarId, 'long_name', 'Latitude of the float when deployed');
netcdf.putAtt(fCdf, launchLatitudeVarId, 'units', 'degree_north');
netcdf.putAtt(fCdf, launchLatitudeVarId, 'valid_min', double(-90));
netcdf.putAtt(fCdf, launchLatitudeVarId, 'valid_max', double(90));
netcdf.putAtt(fCdf, launchLatitudeVarId, '_FillValue', double(99999));
floatNcVarId = [floatNcVarId; launchLatitudeVarId];
floatNcVarName{end+1} = 'LAUNCH_LATITUDE';

launchLongitudeVarId = netcdf.defVar(fCdf, 'LAUNCH_LONGITUDE', 'NC_DOUBLE', []);
netcdf.putAtt(fCdf, launchLongitudeVarId, 'long_name', 'Longitude of the float when deployed');
netcdf.putAtt(fCdf, launchLongitudeVarId, 'units', 'degree_east');
netcdf.putAtt(fCdf, launchLongitudeVarId, 'valid_min', double(-180));
netcdf.putAtt(fCdf, launchLongitudeVarId, 'valid_max', double(180));
netcdf.putAtt(fCdf, launchLongitudeVarId, '_FillValue', double(99999));
floatNcVarId = [floatNcVarId; launchLongitudeVarId];
floatNcVarName{end+1} = 'LAUNCH_LONGITUDE';

launchQcVarId = netcdf.defVar(fCdf, 'LAUNCH_QC', 'NC_CHAR', []);
netcdf.putAtt(fCdf, launchQcVarId, 'long_name', 'Quality on launch date, time and location');
netcdf.putAtt(fCdf, launchQcVarId, 'conventions', 'Argo reference table 2');
netcdf.putAtt(fCdf, launchQcVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; launchQcVarId];
floatNcVarName{end+1} = 'LAUNCH_QC';

startDateVarId = netcdf.defVar(fCdf, 'START_DATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, startDateVarId, 'long_name', 'Date (UTC) of the first descent of the float');
netcdf.putAtt(fCdf, startDateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, startDateVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; startDateVarId];
floatNcVarName{end+1} = 'START_DATE';

startDateQcVarId = netcdf.defVar(fCdf, 'START_DATE_QC', 'NC_CHAR', []);
netcdf.putAtt(fCdf, startDateQcVarId, 'long_name', 'Quality on start date');
netcdf.putAtt(fCdf, startDateQcVarId, 'conventions', 'Argo reference table 2');
netcdf.putAtt(fCdf, startDateQcVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; startDateQcVarId];
floatNcVarName{end+1} = 'START_DATE_QC';

startupDateVarId = netcdf.defVar(fCdf, 'STARTUP_DATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, startupDateVarId, 'long_name', 'Date (UTC) of the activation of the float');
netcdf.putAtt(fCdf, startupDateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, startupDateVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; startupDateVarId];
floatNcVarName{end+1} = 'STARTUP_DATE';

startupDateQcVarId = netcdf.defVar(fCdf, 'STARTUP_DATE_QC', 'NC_CHAR', []);
netcdf.putAtt(fCdf, startupDateQcVarId, 'long_name', 'Quality on startup date');
netcdf.putAtt(fCdf, startupDateQcVarId, 'conventions', 'Argo reference table 2');
netcdf.putAtt(fCdf, startupDateQcVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; startupDateQcVarId];
floatNcVarName{end+1} = 'STARTUP_DATE_QC';

deploymentPlatformVarId = netcdf.defVar(fCdf, 'DEPLOYMENT_PLATFORM', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, deploymentPlatformVarId, 'long_name', 'Identifier of the deployment platform');
netcdf.putAtt(fCdf, deploymentPlatformVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; deploymentPlatformVarId];
floatNcVarName{end+1} = 'DEPLOYMENT_PLATFORM';

deploymentCruiseIdVarId = netcdf.defVar(fCdf, 'DEPLOYMENT_CRUISE_ID', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, deploymentCruiseIdVarId, 'long_name', 'Identification number or reference number of the cruise used to deploy the float');
netcdf.putAtt(fCdf, deploymentCruiseIdVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; deploymentCruiseIdVarId];
floatNcVarName{end+1} = 'DEPLOYMENT_CRUISE_ID';

deploymentReferenceStationIdVarId = netcdf.defVar(fCdf, 'DEPLOYMENT_REFERENCE_STATION_ID', 'NC_CHAR', string256DimId);
netcdf.putAtt(fCdf, deploymentReferenceStationIdVarId, 'long_name', 'Identifier or reference number of co-located stations used to verify the first profile');
netcdf.putAtt(fCdf, deploymentReferenceStationIdVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; deploymentReferenceStationIdVarId];
floatNcVarName{end+1} = 'DEPLOYMENT_REFERENCE_STATION_ID';

endMissionDateVarId = netcdf.defVar(fCdf, 'END_MISSION_DATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, endMissionDateVarId, 'long_name', 'Date (UTC) of the end of mission of the float');
netcdf.putAtt(fCdf, endMissionDateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, endMissionDateVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; endMissionDateVarId];
floatNcVarName{end+1} = 'END_MISSION_DATE';

endMissionStatusVarId = netcdf.defVar(fCdf, 'END_MISSION_STATUS', 'NC_CHAR', []);
netcdf.putAtt(fCdf, endMissionStatusVarId, 'long_name', 'Status of the end of mission of the float');
netcdf.putAtt(fCdf, endMissionStatusVarId, 'conventions', 'T:No more transmission received, R:Retrieved');
netcdf.putAtt(fCdf, endMissionStatusVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; endMissionStatusVarId];
floatNcVarName{end+1} = 'END_MISSION_STATUS';

% configuration parameters
launchConfigParameterNameVarId = netcdf.defVar(fCdf, 'LAUNCH_CONFIG_PARAMETER_NAME', 'NC_CHAR', fliplr([nLaunchConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, launchConfigParameterNameVarId, 'long_name', 'Name of configuration parameter at launch');
netcdf.putAtt(fCdf, launchConfigParameterNameVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; launchConfigParameterNameVarId];
floatNcVarName{end+1} = 'LAUNCH_CONFIG_PARAMETER_NAME';

launchConfigParameterValueVarId = netcdf.defVar(fCdf, 'LAUNCH_CONFIG_PARAMETER_VALUE', 'NC_DOUBLE', nLaunchConfigParamDimId);
netcdf.putAtt(fCdf, launchConfigParameterValueVarId, 'long_name', 'Value of configuration parameter at launch');
netcdf.putAtt(fCdf, launchConfigParameterValueVarId, '_FillValue', double(99999));
floatNcVarId = [floatNcVarId; launchConfigParameterValueVarId];
floatNcVarName{end+1} = 'LAUNCH_CONFIG_PARAMETER_VALUE';

configParameterNameVarId = netcdf.defVar(fCdf, 'CONFIG_PARAMETER_NAME', 'NC_CHAR', fliplr([nConfigParamDimId string128DimId]));
netcdf.putAtt(fCdf, configParameterNameVarId, 'long_name', 'Name of configuration parameter');
netcdf.putAtt(fCdf, configParameterNameVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; configParameterNameVarId];
floatNcVarName{end+1} = 'CONFIG_PARAMETER_NAME';

configParameterValueVarId = netcdf.defVar(fCdf, 'CONFIG_PARAMETER_VALUE', 'NC_DOUBLE', fliplr([nMissionsDimId nConfigParamDimId]));
netcdf.putAtt(fCdf, configParameterValueVarId, 'long_name', 'Value of configuration parameter');
netcdf.putAtt(fCdf, configParameterValueVarId, '_FillValue', double(99999));
floatNcVarId = [floatNcVarId; configParameterValueVarId];
floatNcVarName{end+1} = 'CONFIG_PARAMETER_VALUE';

configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nMissionsDimId);
netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));
floatNcVarId = [floatNcVarId; configMissionNumberVarId];
floatNcVarName{end+1} = 'CONFIG_MISSION_NUMBER';

configMissionCommentVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_COMMENT', 'NC_CHAR', fliplr([nMissionsDimId string256DimId]));
netcdf.putAtt(fCdf, configMissionCommentVarId, 'long_name', 'Comment on configuration');
netcdf.putAtt(fCdf, configMissionCommentVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; configMissionCommentVarId];
floatNcVarName{end+1} = 'CONFIG_MISSION_COMMENT';

% float sensor information
sensorVarId = netcdf.defVar(fCdf, 'SENSOR', 'NC_CHAR', fliplr([nSensorDimId string32DimId]));
netcdf.putAtt(fCdf, sensorVarId, 'long_name', 'Name of the sensor mounted on the float');
netcdf.putAtt(fCdf, sensorVarId, 'conventions', 'Argo reference table 25');
netcdf.putAtt(fCdf, sensorVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorVarId];
floatNcVarName{end+1} = 'SENSOR';

sensorMakerVarId = netcdf.defVar(fCdf, 'SENSOR_MAKER', 'NC_CHAR', fliplr([nSensorDimId string256DimId]));
netcdf.putAtt(fCdf, sensorMakerVarId, 'long_name', 'Name of the sensor manufacturer');
netcdf.putAtt(fCdf, sensorMakerVarId, 'conventions', 'Argo reference table 26');
netcdf.putAtt(fCdf, sensorMakerVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorMakerVarId];
floatNcVarName{end+1} = 'SENSOR_MAKER';

sensorModelVarId = netcdf.defVar(fCdf, 'SENSOR_MODEL', 'NC_CHAR', fliplr([nSensorDimId string256DimId]));
netcdf.putAtt(fCdf, sensorModelVarId, 'long_name', 'Type of sensor');
netcdf.putAtt(fCdf, sensorModelVarId, 'conventions', 'Argo reference table 27');
netcdf.putAtt(fCdf, sensorModelVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorModelVarId];
floatNcVarName{end+1} = 'SENSOR_MODEL';

sensorSerialNoVarId = netcdf.defVar(fCdf, 'SENSOR_SERIAL_NO', 'NC_CHAR', fliplr([nSensorDimId string16DimId]));
netcdf.putAtt(fCdf, sensorSerialNoVarId, 'long_name', 'Serial number of the sensor');
netcdf.putAtt(fCdf, sensorSerialNoVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; sensorSerialNoVarId];
floatNcVarName{end+1} = 'SENSOR_SERIAL_NO';

% float parameter information
parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nParamDimId string64DimId]));
netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'Name of parameter computed from float measurements');
netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Argo reference table 3');
netcdf.putAtt(fCdf, parameterVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterVarId];
floatNcVarName{end+1} = 'PARAMETER';

parameterSensorVarId = netcdf.defVar(fCdf, 'PARAMETER_SENSOR', 'NC_CHAR', fliplr([nParamDimId string128DimId]));
netcdf.putAtt(fCdf, parameterSensorVarId, 'long_name', 'Name of the sensor that measures this parameter');
netcdf.putAtt(fCdf, parameterSensorVarId, 'conventions', 'Argo reference table 25');
netcdf.putAtt(fCdf, parameterSensorVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterSensorVarId];
floatNcVarName{end+1} = 'PARAMETER_SENSOR';

parameterUnitsVarId = netcdf.defVar(fCdf, 'PARAMETER_UNITS', 'NC_CHAR', fliplr([nParamDimId string32DimId]));
netcdf.putAtt(fCdf, parameterUnitsVarId, 'long_name', 'Units of accuracy and resolution of the parameter');
netcdf.putAtt(fCdf, parameterUnitsVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterUnitsVarId];
floatNcVarName{end+1} = 'PARAMETER_UNITS';

parameterAccuracyVarId = netcdf.defVar(fCdf, 'PARAMETER_ACCURACY', 'NC_CHAR', fliplr([nParamDimId string32DimId]));
netcdf.putAtt(fCdf, parameterAccuracyVarId, 'long_name', 'Accuracy of the parameter');
netcdf.putAtt(fCdf, parameterAccuracyVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterAccuracyVarId];
floatNcVarName{end+1} = 'PARAMETER_ACCURACY';

parameterResolutionVarId = netcdf.defVar(fCdf, 'PARAMETER_RESOLUTION', 'NC_CHAR', fliplr([nParamDimId string32DimId]));
netcdf.putAtt(fCdf, parameterResolutionVarId, 'long_name', 'Resolution of the parameter');
netcdf.putAtt(fCdf, parameterResolutionVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; parameterResolutionVarId];
floatNcVarName{end+1} = 'PARAMETER_RESOLUTION';

% float calibration information
predeploymentCalibEquationVarId = netcdf.defVar(fCdf, 'PREDEPLOYMENT_CALIB_EQUATION', 'NC_CHAR', fliplr([nParamDimId string4096DimId]));
netcdf.putAtt(fCdf, predeploymentCalibEquationVarId, 'long_name', 'Calibration equation for this parameter');
netcdf.putAtt(fCdf, predeploymentCalibEquationVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; predeploymentCalibEquationVarId];
floatNcVarName{end+1} = 'PREDEPLOYMENT_CALIB_EQUATION';

predeploymentCalibCoefficientVarId = netcdf.defVar(fCdf, 'PREDEPLOYMENT_CALIB_COEFFICIENT', 'NC_CHAR', fliplr([nParamDimId string4096DimId]));
netcdf.putAtt(fCdf, predeploymentCalibCoefficientVarId, 'long_name', 'Calibration coefficients for this equation');
netcdf.putAtt(fCdf, predeploymentCalibCoefficientVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; predeploymentCalibCoefficientVarId];
floatNcVarName{end+1} = 'PREDEPLOYMENT_CALIB_COEFFICIENT';

predeploymentCalibCommentVarId = netcdf.defVar(fCdf, 'PREDEPLOYMENT_CALIB_COMMENT', 'NC_CHAR', fliplr([nParamDimId string4096DimId]));
netcdf.putAtt(fCdf, predeploymentCalibCommentVarId, 'long_name', 'Comment applying to this parameter calibration');
netcdf.putAtt(fCdf, predeploymentCalibCommentVarId, '_FillValue', ' ');
floatNcVarId = [floatNcVarId; predeploymentCalibCommentVarId];
floatNcVarName{end+1} = 'PREDEPLOYMENT_CALIB_COMMENT';

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % DEFINE MODE END
if (VERBOSE_MODE == 2)
   fprintf('STOP DEFINE MODE\n');
end

netcdf.endDef(fCdf);

% general information on the meta-data file
valueStr = 'Argo meta-data';
netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);

valueStr = '3.1';
netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);

valueStr = '1.2';
netcdf.putVar(fCdf, handbookVersionVarId, 0, length(valueStr), valueStr);

if (isempty(ncCreationDate))
   netcdf.putVar(fCdf, dateCreationVarId, currentDate);
else
   netcdf.putVar(fCdf, dateCreationVarId, ncCreationDate);
end

netcdf.putVar(fCdf, dateUpdateVarId, currentDate);

% valueStr = 'Float';
% netcdf.putVar(fCdf, platformFamilyVarId, 0, length(valueStr), valueStr)

% float characteristics
% float deployment and mission information
% configuration parameters
% float sensor information
% float calibration information

metaFieldNames = fieldnames(metaData);
for idField = 1:length(metaFieldNames)
   % field name of the json structure is also the nc var name
   fieldName = metaFieldNames{idField};
   
   % corresponding nc varId
   idMeta = find(strcmp(floatNcVarName, fieldName) == 1);
   if (isempty(idMeta))
      continue
   end
   
   % CONFIG_* information have been used in the configuration processing
   if ((strcmp(fieldName, 'CONFIG_REPETITION_RATE') == 1) || ...
         (strcmp(fieldName, 'CONFIG_PARAMETER_NAME') == 1) || ...
         (strcmp(fieldName, 'CONFIG_PARAMETER_VALUE') == 1) || ...
         (strcmp(fieldName, 'CONFIG_MISSION_NUMBER') == 1) || ...
         (strcmp(fieldName, 'CONFIG_MISSION_COMMENT') == 1))
      continue
   end
   
   % TEMPORARY START
   %    % data from the Coriolis data base can be inconsistent
   %    if ((strcmp(fieldName, 'SENSOR_MAKER') == 1) || ...
   %          (strcmp(fieldName, 'SENSOR_MODEL') == 1) || ...
   %          (strcmp(fieldName, 'SENSOR_SERIAL_NO') == 1) || ...
   %          (strcmp(fieldName, 'SENSOR_UNITS') == 1) || ...
   %          (strcmp(fieldName, 'SENSOR_ACCURACY') == 1) || ...
   %          (strcmp(fieldName, 'SENSOR_RESOLUTION') == 1))
   %       if (~isempty(metaData.(fieldName)) && ...
   %             (length(fieldnames(metaData.(fieldName))) > nbSensor))
   %          fNames = fieldnames(metaData.(fieldName));
   %          for id = nbSensor+1:length(fNames)
   %             metaData.(fieldName) = rmfield(metaData.(fieldName), fNames{id});
   %          end
   %          fprintf('INFO: %s file generation: too many fields for the %s structure in the Json meta-data file - considering only the %d first ones\n', ...
   %             ncFileName, fieldName, nbSensor);
   %       end
   %    end
   %    if ((strcmp(fieldName, 'PREDEPLOYMENT_CALIB_EQUATION') == 1) || ...
   %          (strcmp(fieldName, 'PREDEPLOYMENT_CALIB_COEFFICIENT') == 1) || ...
   %          (strcmp(fieldName, 'PREDEPLOYMENT_CALIB_COMMENT') == 1))
   %       if (~isempty(metaData.(fieldName)) && ...
   %             (length(fieldnames(metaData.(fieldName))) > nbParam))
   %          fNames = fieldnames(metaData.(fieldName));
   %          for id = nbParam+1:length(fNames)
   %             metaData.(fieldName) = rmfield(metaData.(fieldName), fNames{id});
   %          end
   %          fprintf('INFO: %s file generation: too many fields for the %s structure in the Json meta-data file - considering only the %d first ones\n', ...
   %             ncFileName, fieldName, nbParam);
   %       end
   %    end
   % TEMPORARY END
   
   % field values are to be stored in the nc META file
   inputElt = metaData.(fieldName);
   if (~isempty(inputElt))
      
      if (isa(inputElt, 'char'))
         
         % meta-data with no dimension
         if ((strcmp(fieldName, 'LAUNCH_DATE') == 1) || ...
               (strcmp(fieldName, 'START_DATE') == 1) || ...
               (strcmp(fieldName, 'STARTUP_DATE') == 1) || ...
               (strcmp(fieldName, 'END_MISSION_DATE') == 1))
            
            % format dates according to convention
            if (length(inputElt) == 14)
               % input format is 'yyyymmddHHMMSS'
               netcdf.putVar(fCdf, floatNcVarId(idMeta), inputElt);
            else
               % input format is 'dd/mm/yyyy HH:MM:SS'
               netcdf.putVar(fCdf, floatNcVarId(idMeta), ...
                  datestr(datenum(inputElt, 'dd/mm/yyyy HH:MM:SS'), 'yyyymmddHHMMSS'));
            end
            
         elseif ((strcmp(fieldName, 'LAUNCH_LATITUDE') == 1) || ...
               (strcmp(fieldName, 'LAUNCH_LONGITUDE') == 1))
            
            % values of type double
            netcdf.putVar(fCdf, floatNcVarId(idMeta), str2num(inputElt));
            
         else
            
            % values of type char
            [varName, xType, dimIds, nAtts] = netcdf.inqVar(fCdf, floatNcVarId(idMeta));
            if (~isempty(dimIds))
               netcdf.putVar(fCdf, floatNcVarId(idMeta), 0, length(inputElt), inputElt);
            else
               netcdf.putVar(fCdf, floatNcVarId(idMeta), inputElt);
            end
            
         end
         
      elseif (isa(inputElt, 'struct'))
         
         % meta-data with one dimension
         fieldNames = fieldnames(inputElt);
         for id = 1:length(fieldNames)
            valueStr = inputElt.(fieldNames{id});
            if (~isempty(valueStr))
               [varName, xType, dimIds, nAtts] = netcdf.inqVar(fCdf, floatNcVarId(idMeta));
               if (xType == netcdf.getConstant('NC_CHAR'))
                  % values of type char
                  netcdf.putVar(fCdf, floatNcVarId(idMeta), ...
                     fliplr([id-1  0]), fliplr([1 length(valueStr)]), valueStr');
               else
                  % values of type double
                  netcdf.putVar(fCdf, floatNcVarId(idMeta), ...
                     fliplr([id-1  0]), fliplr([1 1]), str2num(valueStr));
               end
            end
         end
         
         %       elseif (isa(inputElt, 'cell'))
         %
         %          % meta-data with two dimensions (presently only
         %          % CONFIG_PARAMETER_VALUE)
         %          if (strcmp(fieldName, 'CONFIG_PARAMETER_VALUE') == 1)
         %             for id = 1:size(inputElt, 2)
         %                netcdf.putVar(fCdf, configMissionNumberVarId, id-1, id);
         %             end
         %          end
         %          for id1 = 1:size(inputElt, 2)
         %             inputSubElt = inputElt{id1};
         %             fieldNames = fieldnames(inputSubElt);
         %             for id2 = 1:length(fieldNames)
         %                valueStr = inputSubElt.(fieldNames{id2});
         %                if (~isempty(valueStr))
         %                   % we only manage values of type double because only
         %                   % CONFIG_PARAMETER_VALUE variable has two dimensions
         %                   netcdf.putVar(fCdf, floatNcVarId(idMeta), ...
         %                      fliplr([id1-1 id2-1]), fliplr([1 1]), str2num(valueStr));
         %                end
         %             end
         %          end
         
      else
         fprintf('WARNING: Float #%d: unexpected type in the input Json meta-ada structure\n', ...
            g_decArgo_floatNum);
      end
   end
end

% set configuration parameters from input structure
% store launch configuration data
for idConfName = 1:length(launchConfigName)
   valueStr = launchConfigName{idConfName};
   netcdf.putVar(fCdf, launchConfigParameterNameVarId, ...
      fliplr([idConfName-1  0]), fliplr([1 length(valueStr)]), valueStr');
end

if (~isempty(launchConfigValue))
   launchConfigValue(isnan(launchConfigValue)) =  netcdf.getAtt(fCdf, launchConfigParameterValueVarId, '_FillValue');
   netcdf.putVar(fCdf, launchConfigParameterValueVarId, 0, length(launchConfigValue), launchConfigValue);
end

% store mission configuration data
for idConfName = 1:length(missionConfigName)
   valueStr = missionConfigName{idConfName};
   netcdf.putVar(fCdf, configParameterNameVarId, ...
      fliplr([idConfName-1  0]), fliplr([1 length(valueStr)]), valueStr');
end

if (~isempty(missionConfigValue))
   missionConfigValue(isnan(missionConfigValue)) =  netcdf.getAtt(fCdf, configParameterValueVarId, '_FillValue');
   netcdf.putVar(fCdf, configParameterValueVarId, [0 0], size(missionConfigValue), missionConfigValue);
end

% store mission configuration numbers
if (~isempty(configMissionNumber))
   netcdf.putVar(fCdf, configMissionNumberVarId, 0, length(configMissionNumber), configMissionNumber);
end

netcdf.close(fCdf);

if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
   % store information for the XML report
   g_decArgo_reportStruct.outputMetaFiles = [g_decArgo_reportStruct.outputMetaFiles ...
      {ncPathFileName}];
end

fprintf('... NetCDF META-DATA file created\n');

return
