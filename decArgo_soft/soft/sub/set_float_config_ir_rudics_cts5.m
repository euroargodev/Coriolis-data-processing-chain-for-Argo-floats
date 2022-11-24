% ------------------------------------------------------------------------------
% Set the float configuration used to process the data of given profiles.
%
% SYNTAX :
%  set_float_config_ir_rudics_cts5(a_cycleNum, a_patternNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_patternNum : pattern number
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function set_float_config_ir_rudics_cts5(a_cycleNum, a_patternNum)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


% update the configuration

configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
configValues = g_decArgo_floatConfig.DYNAMIC.VALUES;

tmpConfNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
tmpConfValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

% the configuration name list may have changed (due to payload configuration)
% we should first update this list

% list of parameters to add
configNamesToAdd = setdiff(tmpConfNames, configNames);
if (~isempty(configNamesToAdd))
   configNames = cat(1, configNames, configNamesToAdd);
   configValues = cat(1, configValues, nan(length(configNamesToAdd), size(configValues, 2)));
end

g_decArgo_floatConfig.DYNAMIC.NAMES = configNames;
g_decArgo_floatConfig.DYNAMIC.VALUES = configValues;

% create the current configurtion
currentConfig = nan(size(configNames));
for idP = 1:length(tmpConfNames)
   idF = find(strcmp(configNames, tmpConfNames{idP}), 1);
   currentConfig(idF) = tmpConfValues(idP);
end

% update the current configuration (duplicate payload configuration values of
% the current phase number into the CONFIG_PAYLOAD_USED ones)

% ISA parameters
nbAscentPhases = get_config_value('CONFIG_PAYLOAD_ISA_P09', configNames, configValues);
currentPhaseNum = rem(a_cycleNum-1, nbAscentPhases) + 1;
currentPhaseNumStr = ['_' num2str(currentPhaseNum)];

idIsa = find(strncmp(configNames, 'CONFIG_PAYLOAD_ISA', length('CONFIG_PAYLOAD_ISA')));
for id = 1:length(idIsa)
   idP = idIsa(id);
   configName = configNames{idP};
   idFUs = strfind(configName, '_');
   if (strcmp(configName(idFUs(end):end), currentPhaseNumStr))
      configNameOut = regexprep(configName(1:idFUs(end)-1), 'CONFIG_PAYLOAD_', 'CONFIG_PAYLOAD_USED_');
      idF = find(strcmp(configNames, configNameOut), 1);
      currentConfig(idF) = currentConfig(idP);
   end
end

% AID parameters
nbAscentPhases = get_config_value('CONFIG_PAYLOAD_AID_P15', configNames, configValues);
currentPhaseNum = rem(a_cycleNum-1, nbAscentPhases) + 1;
currentPhaseNumStr = ['_' num2str(currentPhaseNum)];

idAid = find(strncmp(configNames, 'CONFIG_PAYLOAD_AID', length('CONFIG_PAYLOAD_AID')));
for id = 1:length(idAid)
   idP = idAid(id);
   configName = configNames{idP};
   idFUs = strfind(configName, '_');
   if (strcmp(configName(idFUs(end):end), currentPhaseNumStr))
      configNameOut = regexprep(configName(1:idFUs(end)-1), 'CONFIG_PAYLOAD_', 'CONFIG_PAYLOAD_USED_');
      idF = find(strcmp(configNames, configNameOut), 1);
      currentConfig(idF) = currentConfig(idP);
   end
end

% AC1 parameters
nbAscentPhases = get_config_value('CONFIG_PAYLOAD_AC1_P02', configNames, configValues);
currentPhaseNum = rem(a_cycleNum-1, nbAscentPhases) + 1;
currentPhaseNumStr = ['_' num2str(currentPhaseNum)];

idAc1 = find(strncmp(configNames, 'CONFIG_PAYLOAD_AC1', length('CONFIG_PAYLOAD_AC1')));
for id = 1:length(idAc1)
   idP = idAc1(id);
   configName = configNames{idP};
   idFUs = strfind(configName, '_');
   if (strcmp(configName(idFUs(end):end), currentPhaseNumStr))
      configNameOut = regexprep(configName(1:idFUs(end)-1), 'CONFIG_PAYLOAD_', 'CONFIG_PAYLOAD_USED_');
      idF = find(strcmp(configNames, configNameOut), 1);
      currentConfig(idF) = currentConfig(idP);
   end
end

% SENSOR parameters
idSensor = find(strncmp(configNames, 'CONFIG_PAYLOAD_SENSOR', length('CONFIG_PAYLOAD_SENSOR')));
for id = 1:length(idSensor)
   idP = idSensor(id);
   configName = configNames{idP};
   if (any(strfind(configName, '_P09_VP')) || any(strfind(configName, '_P09_HP')))
      nbPhases = get_config_value(configName, configNames, configValues);
      idFUs = strfind(configName, '_');
      strToFind = [configName(idFUs(end):end) '_' num2str(nbPhases)];
      idSensor2 = find(strncmp(configNames, configName(1:25), length(configName(1:25))));
      for id2 = 1:length(idSensor2)
         idP2 = idSensor2(id2);
         configName2 = configNames{idP2};
         if (any(strfind(configName2, strToFind)))
            idFUs2 = strfind(configName2, '_');
            if (length(idFUs2) == 6)
               configName2 = configName2(1:idFUs2(end)-1);
            else
               configName2 = configName2([1:idFUs2(6) idFUs2(7)+1:end]);
            end
            configNameOut = regexprep(configName2, 'CONFIG_PAYLOAD_', 'CONFIG_PAYLOAD_USED_');
            idF = find(strcmp(configNames, configNameOut), 1);
            currentConfig(idF) = currentConfig(idP2);
         end
      end
   end
end

% voir = cat(2, configNames, num2cell(currentConfig));

% set g_decArgo_floatConfig.DYNAMIC.IGNORED_ID
% only CONFIG_PAYLOAD_USED_* payload parameters should be used in configuration
% comparisons
id1 = find(strncmp(configNames, 'CONFIG_PAYLOAD', length('CONFIG_PAYLOAD')));
id2 = find(strncmp(configNames, 'CONFIG_PAYLOAD_USED', length('CONFIG_PAYLOAD_USED')));
g_decArgo_floatConfig.DYNAMIC.IGNORED_ID = setdiff(id1, id2);

% look for the current configurations in existing ones
[configNum] = config_exists_ir_rudics_sbd2( ...
   currentConfig, ...
   g_decArgo_floatConfig.DYNAMIC.NUMBER, ...
   g_decArgo_floatConfig.DYNAMIC.VALUES, ...
   g_decArgo_floatConfig.DYNAMIC.IGNORED_ID);

% if configNum == -1 the new configuration doesn't exist
% if configNum == 0 the new configuration is identical to launch
% configuration, we create a new one however so that the launch
% configuration should never be referenced in the prof and traj
% data

% anomaly-managment: check if a config already exists for this
% cycle and profile
idUsedConf = find((g_decArgo_floatConfig.USE.CYCLE == a_cycleNum) & ...
   (g_decArgo_floatConfig.USE.PROFILE == a_patternNum));

if (~isempty(idUsedConf))
   
   fprintf('WARNING: Float #%d: config already exists for cycle #%d and pattern #%d => updating the current one\n', ...
      g_decArgo_floatNum, a_cycleNum, a_patternNum);
   
   if ((configNum == -1) || (configNum == 0))
      idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == ...
         g_decArgo_floatConfig.USE.CONFIG(idUsedConf));
      g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf) = currentConfig;
   else
      g_decArgo_floatConfig.USE.CONFIG(idUsedConf) = configNum;
   end
   
else
   
   % nominal case
   if ((configNum == -1) || (configNum == 0))
      
      % create a new config
      
      g_decArgo_floatConfig.DYNAMIC.NUMBER(end+1) = ...
         max(g_decArgo_floatConfig.DYNAMIC.NUMBER) + 1;
      g_decArgo_floatConfig.DYNAMIC.VALUES(:, end+1) = currentConfig;
      configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER(end);
   end
   
   % assign the config to the cycle and profile
   g_decArgo_floatConfig.USE.CYCLE(end+1) = a_cycleNum;
   g_decArgo_floatConfig.USE.PROFILE(end+1) = a_patternNum;
   g_decArgo_floatConfig.USE.CYCLE_OUT(end+1) = g_decArgo_cycleNum;
   g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
end

% print_config_in_csv_file_ir_rudics_cts5('setConfig_', 1, g_decArgo_floatConfig);

return;
