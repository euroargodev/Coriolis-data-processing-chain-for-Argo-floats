% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_ir_rudics_cts5_usea(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_ir_rudics_cts5_usea(a_decoderId)

% output parameters initialization
o_ncConfig = [];


% create the configuration parameter names for the META NetCDF file
[decArgoConfParamNames, ncConfParamNames] = create_config_param_names_ir_rudics_cts5(a_decoderId);

% create output float configuration
[o_ncConfig] = create_output_float_config(decArgoConfParamNames, ncConfParamNames);

return

% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config(a_decArgoConfParamNames, a_ncConfParamNames)
%
% INPUT PARAMETERS :
%   a_decArgoConfParamNames : internal configuration parameter names
%   a_ncConfParamNames      : NetCDF configuration parameter names
%
% OUTPUT PARAMETERS :
% o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config(a_decArgoConfParamNames, a_ncConfParamNames)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;


% create_csv_to_print_config_ir_rudics_sbd2('create_output_', 1, g_decArgo_floatConfig);

%%%%%%%%%%%%%%%%%%%
% STATIC PARAMETERS

staticConfigName = g_decArgo_floatConfig.STATIC.NAMES;
staticConfigValue = g_decArgo_floatConfig.STATIC.VALUES;

% delete the static configuration parameters we don't want to put in the META
% NetCDF file
notWantedStaticConfigNames = [];

% static parameters
for paramNum = [6:8 11:15 17:20 22:28]
   notWantedStaticConfigNames{end+1} = sprintf('CONFIG_APMT_ALARM_P%02d', paramNum);
end
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_IRIDIUM_RUDICS_P02';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_01_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_02_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_03_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_04_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_05_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_06_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_07_P00';
notWantedStaticConfigNames{end+1} = 'CONFIG_APMT_SENSOR_08_P00';

% remove them from output lists
idDel = [];
for idConfParam = 1:length(notWantedStaticConfigNames)
   idF = find(strcmp(notWantedStaticConfigNames{idConfParam}, staticConfigName) == 1);
   if (~isempty(idF))
      idDel = [idDel; idF];
   end
end
staticConfigName(idDel) = [];
staticConfigValue(idDel, :) = [];

%%%%%%%%%%%%%%%%%%%%
% DYNAMIC PARAMETERS

% final configuration
finalConfigNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
finalConfigName = g_decArgo_floatConfig.DYNAMIC.NAMES;
finalConfigValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
inputUsedCy = g_decArgo_floatConfig.USE.CYCLE;
inputUsedProf = g_decArgo_floatConfig.USE.PROFILE;
inputUsedCyOut = g_decArgo_floatConfig.USE.CYCLE_OUT;
inputUsedConfNum = g_decArgo_floatConfig.USE.CONFIG;

% update output parameter values 

% for PATTERN_XX parameters, duplicate P0 to P7 values of the relevent pattern
% to PATTERN_01
% BE CAREFUL! This may create additionnal configurations (when cycles with
% different patterns share the same configuration, we should create a new
% one for each pattern - in fact create a temporary new one and check if it
% doesn't already exist)
uUsedPtn = unique(inputUsedProf(find(inputUsedProf > 1)));
if (~isempty(uUsedPtn))
   
   % create the list of configuration parameters to be ignored when looking
   % for an existing configuration
   % i.e. PATTERN_02 to PATTERN_10 configuration parameters
   confParamIdToIgnore = [];
   for ptnNum = 2:10
      for paramNum = 0:8
         confName = sprintf('CONFIG_APMT_PATTERN_%02d_P%02d', ptnNum, paramNum);
         confId = find(strcmp(confName, finalConfigName), 1);
         confParamIdToIgnore = [confParamIdToIgnore; confId];
      end
   end
   
   % process all PATTERN_XX with XX > 1
   for idPtn = 1:length(uUsedPtn)
      ptnNum = uUsedPtn(idPtn);
      confIdForPtn  = find(inputUsedProf == ptnNum);
      for idConf = 1:length(confIdForPtn)
         confNum = inputUsedConfNum(confIdForPtn(idConf));
         newConfValue = finalConfigValue(:, confNum+1);
         for paramNum = 0:8
            inputConfName = sprintf('CONFIG_APMT_PATTERN_%02d_P%02d', ptnNum, paramNum);
            inputConfid = find(strcmp(inputConfName, finalConfigName), 1);
            outputConfName = sprintf('CONFIG_APMT_PATTERN_01_P%02d', paramNum);
            outputConfid = find(strcmp(outputConfName, finalConfigName), 1);
            newConfValue(outputConfid) = newConfValue(inputConfid);
         end
         
         % look for the current configurations in existing ones
         [configNum] = config_exists_ir_rudics_sbd2( ...
            newConfValue, ...
            finalConfigNum, ...
            finalConfigValue, ...
            confParamIdToIgnore);
         
         % if configNum == -1 the new configuration doesn't exist
         % if configNum == 0 the new configuration is identical to launch
         % configuration, we create a new one however so that the launch
         % configuration should never be referenced in the prof and traj
         % data
         
         if ((configNum == -1) || (configNum == 0))
            
            % create a new config
            
            g_decArgo_floatConfig.DYNAMIC.NUMBER(end+1) = ...
               max(g_decArgo_floatConfig.DYNAMIC.NUMBER) + 1;
            g_decArgo_floatConfig.DYNAMIC.VALUES(:, end+1) = newConfValue;
            configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER(end);
            
            finalConfigNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
            finalConfigValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
         end
         
         % assign the config to the cycle and profile
         g_decArgo_floatConfig.USE.CONFIG(confIdForPtn(idConf)) = configNum;
         
         inputUsedConfNum = g_decArgo_floatConfig.USE.CONFIG;
      end
   end
   
   %    create_csv_to_print_config_ir_rudics_cts5('createOutputBefore_', 1, g_decArgo_floatConfig);

   % sort configuration and remove unused ones
   error = 0;
   finalConfigValueBis = finalConfigValue(:, 1); % initiliazed with launch config
   usedConfNumBis = [];
   confNumOldDone = [];
   confNumNewDone = [];
   cyNumList = unique(inputUsedCyOut);
   for idCy = 1:length(cyNumList)
      idForCy = find(inputUsedCyOut == cyNumList(idCy));
      confNum = unique(inputUsedConfNum(idForCy));
      if (length(confNum) > 1)
         error = 1;
         fprintf('ERROR: Float #%d: %d configurations for the same cycle number (#%d)\n', ...
            g_decArgo_floatNum, ...
            length(confNum), cyNumList(idCy));
         break;
      end
      if (any(confNumOldDone == confNum))
         idF = find(confNumOldDone == confNum, 1);
         usedConfNumBis = [usedConfNumBis repmat(confNumNewDone(idF), 1, length(idForCy))];
      else
         idForConf = find(finalConfigNum == confNum, 1);
         finalConfigValueBis = cat(2, finalConfigValueBis, finalConfigValue(:, idForConf));
         usedConfNumBis = [usedConfNumBis repmat(size(finalConfigValueBis, 2)-1, 1, length(idForCy))];
         
         confNumOldDone = [confNumOldDone confNum];
         confNumNewDone = [confNumNewDone usedConfNumBis(end)];
      end
   end
   if (~error)
      g_decArgo_floatConfig.DYNAMIC.NUMBER = 0:(size(finalConfigValueBis, 2)-1);
      g_decArgo_floatConfig.DYNAMIC.VALUES = finalConfigValueBis;
      g_decArgo_floatConfig.USE.CONFIG = usedConfNumBis;
      
      finalConfigNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
      finalConfigValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
      inputUsedConfNum = g_decArgo_floatConfig.USE.CONFIG;
   end
   
   %    create_csv_to_print_config_ir_rudics_cts5('createOutputAfter_', 1, g_decArgo_floatConfig);
end

% if CONFIG_APMT_PATTERN_01_P07 == 0 set CONFIG_APMT_PATTERN_01_P04 to Nan
% i.e. we dont set the configured surface time if the float is not expected to
% use it
inputConfName = 'CONFIG_APMT_PATTERN_01_P07';
inputConfid = find(strcmp(inputConfName, finalConfigName), 1);
outputConfName = 'CONFIG_APMT_PATTERN_01_P04';
outputConfid = find(strcmp(outputConfName, finalConfigName), 1);
idSetToNan = find(finalConfigValue(inputConfid, :) == 0);
finalConfigValue(outputConfid, idSetToNan) = nan;

% if CONFIG_APMT_SURFACE_APPROACH_P00 == 0 set CONFIG_APMT_SURFACE_APPROACH_P01 to Nan
inputConfName = 'CONFIG_APMT_SURFACE_APPROACH_P00';
inputConfid = find(strcmp(inputConfName, finalConfigName), 1);
outputConfName = 'CONFIG_APMT_SURFACE_APPROACH_P01';
outputConfid = find(strcmp(outputConfName, finalConfigName), 1);
idSetToNan = find(finalConfigValue(inputConfid, :) == 0);
finalConfigValue(outputConfid, idSetToNan) = nan;

% if CONFIG_APMT_ICE_P00 == 0 set CONFIG_APMT_ICE_P01 to CONFIG_APMT_ICE_P03 to Nan
inputConfName = 'CONFIG_APMT_ICE_P00';
inputConfid = find(strcmp(inputConfName, finalConfigName), 1);
idSetToNan = find(finalConfigValue(inputConfid, :) == 0);
for paramNum = 1:3
   outputConfName = sprintf('CONFIG_APMT_ICE_P%02d', paramNum);
   outputConfid = find(strcmp(outputConfName, finalConfigName), 1);
   finalConfigValue(outputConfid, idSetToNan) = nan;
end

% if CONFIG_APMT_SENSOR_XX_P00 == 0 set CONFIG_APMT_SENSOR_XX_P01 to CONFIG_APMT_SENSOR_XX_P53 to Nan
% not done because the APMT card manages only the CTD sensor (mandatory) in this version

% delete the dynamic configuration parameters we don't want to put in the META
% NetCDF file
notWantedDynamicConfigNames = [];

% PATTERN_02 to PATTERN_10 parameters
for ptnNum = 2:10
   for paramNum = 0:8
      notWantedDynamicConfigNames{end+1} = sprintf('CONFIG_APMT_PATTERN_%02d_P%02d', ptnNum, paramNum);
   end
end

notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_PATTERN_01_P00';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_PATTERN_01_P07';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_PATTERN_01_P08';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_END_OF_LIFE_P00';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SURFACE_APPROACH_P00';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_ICE_P00';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_CYCLE_P00';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_CYCLE_P01';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_CYCLE_P02';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_01_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_02_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_03_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_04_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_05_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_06_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_07_P53';
notWantedDynamicConfigNames{end+1} = 'CONFIG_APMT_SENSOR_08_P53';

idDel = [];
for idConfParam = 1:length(notWantedDynamicConfigNames)
   idF = find(strcmp(notWantedDynamicConfigNames{idConfParam}, finalConfigName) == 1);
   if (~isempty(idF))
      idDel = [idDel; idF];
   end
end
finalConfigName(idDel) = [];
finalConfigValue(idDel, :) = [];

% delete the unused configuration parameters
idDel = [];
for idL = 1:size(finalConfigValue, 1)
   if (sum(isnan(finalConfigValue(idL, :))) == size(finalConfigValue, 2))
      idDel = [idDel; idL];
   end
end
finalConfigName(idDel) = [];
finalConfigValue(idDel, :) = [];

% convert decoder names into NetCDF ones
staticConfigNameBefore = staticConfigName;
finalConfigNameBefore = finalConfigName;
if (~isempty(a_decArgoConfParamNames))
   for idConfParam = 1:length(staticConfigName)
      idF = find(strcmp(staticConfigName{idConfParam}, a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         staticConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
            g_decArgo_floatNum, ...
            staticConfigName{idConfParam});
      end
   end
   for idConfParam = 1:length(finalConfigName)
      idF = find(strcmp(finalConfigName{idConfParam}, a_decArgoConfParamNames) == 1);
      if (~isempty(idF))
         finalConfigName{idConfParam} = a_ncConfParamNames{idF};
      else
         fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
            g_decArgo_floatNum, ...
            finalConfigName{idConfParam});
      end
   end
end

% output data
o_ncConfig.STATIC_NC.NAMES = staticConfigName;
o_ncConfig.STATIC_NC.VALUES = staticConfigValue;
o_ncConfig.DYNAMIC_NC.NUMBER = finalConfigNum;
o_ncConfig.DYNAMIC_NC.NAMES = finalConfigName;
o_ncConfig.DYNAMIC_NC.VALUES = finalConfigValue;

% tmp = [];
% tmp.STATIC_NC.NAMES_DEC = staticConfigNameBefore;
% tmp.STATIC_NC.NAMES = staticConfigName;
% tmp.STATIC_NC.VALUES = staticConfigValue;
% tmp.DYNAMIC_NC.NUMBER = finalConfigNum;
% tmp.DYNAMIC_NC.NAMES_DEC = finalConfigNameBefore;
% tmp.DYNAMIC_NC.NAMES = finalConfigName;
% tmp.DYNAMIC_NC.VALUES = finalConfigValue;
% create_csv_to_print_config_ir_rudics_sbd2('', 2, tmp);

return
