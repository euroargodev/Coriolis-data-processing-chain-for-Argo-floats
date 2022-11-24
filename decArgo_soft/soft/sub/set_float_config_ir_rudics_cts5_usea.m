% ------------------------------------------------------------------------------
% Set the float configuration used to process the data of given profiles.
%
% SYNTAX :
%  set_float_config_ir_rudics_cts5_usea(a_cycleNum, a_patternNum)
%
% INPUT PARAMETERS :
%   a_cycleNum   : cycle number
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function set_float_config_ir_rudics_cts5_usea(a_cycleNum, a_patternNum)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% float configuration
global g_decArgo_floatConfig;


% retrieve the configuration of the previous profile
configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
if (~isempty(g_decArgo_floatConfig.USE.CONFIG))
   idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == g_decArgo_floatConfig.USE.CONFIG(end));
else
   idConf = 1;
end
currentConfig = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);
      
% update the current configuration
tmpConfNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
tmpConfValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);
      
% update the current configuration
for id = 1:length(tmpConfNames)
   configName = tmpConfNames{id};
   idPos = find(strcmp(configName, configNames) == 1, 1);
   if (~isempty(idPos))
      currentConfig(idPos) = tmpConfValues(id);
   end
end

% look for the current configurations in existing ones
[configNum] = config_exists_ir_rudics_sbd2( ...
   currentConfig, ...
   g_decArgo_floatConfig.DYNAMIC.NUMBER, ...
   g_decArgo_floatConfig.DYNAMIC.VALUES, []);

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
   
   fprintf('WARNING: Float #%d: config already exists for cycle #%d and pattern #%d - updating the current one\n', ...
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

% create_csv_to_print_config_ir_rudics_cts5('setConfig_', 1, g_decArgo_floatConfig);

return
