% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_ir_sbd2( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decArgoConfParamNames : internal configuration parameter names
%   a_ncConfParamNames      : NetCDF configuration parameter names
%   a_decoderId             : float decoder Id
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_ir_sbd2( ...
   a_decArgoConfParamNames, a_ncConfParamNames, a_ncConfParamIds, a_decoderId)

% output parameters initialization
o_ncConfig = [];

% float configuration
global g_decArgo_floatConfig;

% current float WMO number
global g_decArgo_floatNum;


% current configuration
inputConfigNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
inputConfigName = g_decArgo_floatConfig.DYNAMIC.NAMES;
inputConfigValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
inputUsedCy = g_decArgo_floatConfig.USE.CYCLE;
inputUsedProf = g_decArgo_floatConfig.USE.PROFILE;
inputUsedCyOut = g_decArgo_floatConfig.USE.CYCLE_OUT;
inputUsedConfNum = g_decArgo_floatConfig.USE.CONFIG;

% update the output cycle number list

% create the expected final table
finalCyNum = [];
finalProfNum = [];
for cyNum = 0:max(inputUsedCy)
   idF = find(inputUsedCy == cyNum);
   if (~isempty(idF))
      finalCyNum = [finalCyNum repmat(cyNum, 1, max(inputUsedProf(idF))+1)];
      finalProfNum = [finalProfNum 0:max(inputUsedProf(idF))];
   else
      finalCyNum = [finalCyNum cyNum];
      finalProfNum = [finalProfNum 0];
   end
end

% update the configuration list
for idC = 1:length(inputUsedCy)
   idF = find((inputUsedCy(idC) == finalCyNum) & ...
      (inputUsedProf(idC) == finalProfNum));
   if (inputUsedCyOut(idC) ~= -1)
      if (inputUsedCyOut(idC) ~= idF)
         fprintf('ERROR: Float #%d: Inconsistency (output cycle number already set (to %d)) - set to %d\n', ...
            g_decArgo_floatNum, ...
            inputUsedCyOut(idC), ...
            idF);
      end
   end
   inputUsedCyOut(idC) = idF;
end
g_decArgo_floatConfig.USE.CYCLE_OUT = inputUsedCyOut;

% create_csv_to_print_config_ir_rudics_sbd2('create_output_', 1, g_decArgo_floatConfig);

% final configuration
finalConfigNum = inputConfigNum;
finalConfigName = inputConfigName;
finalConfigValue = inputConfigValue;

% for PM parameters, duplicate the information of (PM03 to PM07) in (PM3 to PM7)
for idC = 1:size(finalConfigValue, 2)
   for id = 1:5
      confName = sprintf('CONFIG_PM_%02d', 3+(id-1));
      idL1 = find(strcmp(confName, finalConfigName) == 1, 1);
      confName = sprintf('CONFIG_PM_%d', 3+(id-1));
      idL2 = find(strcmp(confName, finalConfigName) == 1, 1);
      finalConfigValue(idL2, idC) = finalConfigValue(idL1, idC);
   end
end

% delete the configuration parameters unused by each float type

switch (a_decoderId)
   
   case {301} % Remocean FLBB
      
      % delete unused technical parameter configuration information
      notWantedDynamicConfigNames = [ ...
         {'CONFIG_PT_19'} ...
         {'CONFIG_PT_20'} ...
         {'CONFIG_PT_23'} ...
         {'CONFIG_PT_24'} ...
         {'CONFIG_PT_25'} ...
         ];
      
      % delete unused PM (PM8 to PM52 and PM03 to PM07)
      for id = 8:52
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PM_%d', id)}];
      end
      for id = 3:7
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PM_%02d', id)}];
      end
      
      % delete unused "synchronisation zone" standard sensor configuration
      % information
      for idS = [0 1 4]
         for idZ = 1:5
            notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
               {sprintf('CONFIG_PC_%d_0_%d', idS, 7+(idZ-1)*5)}];
         end
      end
      
      % delete unused PC specific parameters
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_0_1_10'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_0_1_11'}];
      
   case {302} % Arvor CM
      
      % delete unused technical parameter configuration information
      notWantedDynamicConfigNames = [ ...
         {'CONFIG_PT_19'} ...
         {'CONFIG_PT_20'} ...
         {'CONFIG_PT_23'} ...
         {'CONFIG_PT_24'} ...
         {'CONFIG_PT_25'} ...
         ];
      
      % delete unused PM (PM8 to PM52 and PM03 to PM07)
      for id = 8:52
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PM_%d', id)}];
      end
      for id = 3:7
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PM_%02d', id)}];
      end
      
      % delete unused "synchronisation zone" standard sensor configuration
      % information
      % delete unused PC_X_1_3 parameters
      for idS = [0 1 4]
         for idZ = 1:5
            notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
               {sprintf('CONFIG_PC_%d_0_%d', idS, 7+(idZ-1)*9)}];
         end
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PC_%d_1_3', idS)}];
      end
      
      % delete unused PC specific parameters
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_0_1_11'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_0_1_12'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_1_1_6'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_1_1_7'}];
      
      for id = 8:11
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PC_4_1_%d', id)}];
      end
      
   case {303} % Arvor CM
      
      % delete unused technical parameter configuration information
      notWantedDynamicConfigNames = [ ...
         {'CONFIG_PT_19'} ...
         {'CONFIG_PT_20'} ...
         {'CONFIG_PT_23'} ...
         {'CONFIG_PT_24'} ...
         {'CONFIG_PT_25'} ...
         ];
      
      % delete unused PM (PM8 to PM52 and PM03 to PM07)
      for id = 8:52
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PM_%d', id)}];
      end
      for id = 3:7
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PM_%02d', id)}];
      end
      
      % delete unused "synchronisation zone" standard sensor configuration
      % information
      % delete unused PC_X_1_3 parameters
      for idS = [0 1 4 7 8]
         for idZ = 1:5
            notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
               {sprintf('CONFIG_PC_%d_0_%d', idS, 7+(idZ-1)*9)}];
         end
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PC_%d_1_3', idS)}];
      end
      
      % delete unused PC specific parameters
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_0_1_11'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_0_1_12'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_1_1_6'}];
      notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
         {'CONFIG_PC_1_1_7'}];

      for id = 8:11
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PC_4_1_%d', id)}];
      end
      
      for id = 7:10
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PC_7_1_%d', id)}];
         notWantedDynamicConfigNames = [notWantedDynamicConfigNames ...
            {sprintf('CONFIG_PC_8_1_%d', id)}];
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to create list of unused configuration parameters for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

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

% delete the static configuration parameters we don't want to put in the META
% NetCDF file
staticConfigName = g_decArgo_floatConfig.STATIC.NAMES;
staticConfigValue = g_decArgo_floatConfig.STATIC.VALUES;

% convert decoder names into NetCDF ones
staticConfigId = [];
finalConfigId = [];
if (isempty(a_ncConfParamIds))
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
else
   staticConfigId = ones(size(staticConfigName))*-1;
   finalConfigId = ones(size(finalConfigName))*-1;
   if (~isempty(a_decArgoConfParamNames))
      for idConfParam = 1:length(staticConfigName)
         idF = find(strcmp(staticConfigName{idConfParam}, a_decArgoConfParamNames) == 1);
         if (~isempty(idF))
            staticConfigName{idConfParam} = a_ncConfParamNames{idF};
            staticConfigId(idConfParam) = a_ncConfParamIds(idF);
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
            finalConfigId(idConfParam) = a_ncConfParamIds(idF);
         else
            fprintf('ERROR: Float #%d: Cannot convert configuration param name :''%s'' into NetCDF one\n', ...
               g_decArgo_floatNum, ...
               finalConfigName{idConfParam});
         end
      end
   end
end

% output data
o_ncConfig.STATIC_NC.NAMES = staticConfigName;
o_ncConfig.STATIC_NC.IDS = staticConfigId;
o_ncConfig.STATIC_NC.VALUES = staticConfigValue;
o_ncConfig.DYNAMIC_NC.NUMBER = finalConfigNum;
o_ncConfig.DYNAMIC_NC.NAMES = finalConfigName;
o_ncConfig.DYNAMIC_NC.IDS = finalConfigId;
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
