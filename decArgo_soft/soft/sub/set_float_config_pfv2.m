% ------------------------------------------------------------------------------
% Set the float configuration used to process the data of given profiles.
%
% SYNTAX :
%  set_float_config_pfv2(a_cycleNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number associated to the configuration
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function set_float_config_pfv2(a_cycleNum)

% float configuration
global g_decArgo_floatConfig;

% mission, loop and cycle management
global g_decArgo_missionLoopCycle;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update the configuration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve the configuration of the previous profile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
configNames = g_decArgo_floatConfig.DYNAMIC.NAMES;
if (~isempty(g_decArgo_floatConfig.USE.CONFIG))
   idConf = find(g_decArgo_floatConfig.DYNAMIC.NUMBER == g_decArgo_floatConfig.USE.CONFIG(end));
else
   idConf = 1;
end
currentConfig = g_decArgo_floatConfig.DYNAMIC.VALUES(:, idConf);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve and update the last configuration received
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% retrieve the last configuration received
tmpConfNames = g_decArgo_floatConfig.DYNAMIC_TMP.NAMES;
tmpConfValues = g_decArgo_floatConfig.DYNAMIC_TMP.VALUES(:, end);

% retrieve config loop and cycle numbers for the current cycle
if (a_cycleNum == 0)
   cycleLoopPattern = '-LOOP01-CYCLE01';
else
   idCyNum = find(g_decArgo_missionLoopCycle.cycleNumber == a_cycleNum, 1, 'first');
   configLoop = g_decArgo_missionLoopCycle.loop(idCyNum);
   configCycle = g_decArgo_missionLoopCycle.cycle(idCyNum);
   cycleLoopPattern = sprintf('-LOOP%02d-CYCLE%02d', configLoop, configCycle);
end

% update last configuration received parameters with cycleLoopPattern in their labels
idF = find(contains(tmpConfNames, cycleLoopPattern));
curConfNames = tmpConfNames(idF);
curConfValues = tmpConfValues(idF);
curConfNames = regexprep(curConfNames, cycleLoopPattern, '-L-C');

% update the last configuration received with updated entries
for id = 1:length(curConfNames)
   idF = find(strcmp(curConfNames{id}, tmpConfNames));
   if (~isempty(idF))
      tmpConfValues(idF) = curConfValues(id);
   else
      fprintf('ERROR: Float #%d: The configuration name ''%s'' is not present in the initial configuration\n', ...
         g_decArgo_floatNum, ...
         curConfNames{id});
      return
   end
end
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% update the current configuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for id = 1:length(tmpConfNames)
   idF = find(strcmp(tmpConfNames{id}, configNames), 1);
   if (~isempty(idF))
      currentConfig(idF) = tmpConfValues(id);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% look for the current configurations in existing ones

% remove the '-LOOPXX-CYCLEXX' parameters from the comparison
% because only parameters of the current configuration (with '-L-C' should be
% compared)
configIgnoreIds = find(contains(configNames, '-LOOP') & contains(configNames, '-CYCLE'));

[configNum] = config_exists_ir_sbd_argos( ...
   currentConfig, ...
   g_decArgo_floatConfig.DYNAMIC.NUMBER, ...
   g_decArgo_floatConfig.DYNAMIC.VALUES, configIgnoreIds);

% if configNum == -1 the new configuration doesn't exist
% if configNum == 0 the new configuration is identical to launch configuration,
% we create a new one however so that the launch configuration should never be
% referenced in the prof and traj data
if ((configNum == -1) || (configNum == 0))

   % create a new config

   % we add the new configuration
   g_decArgo_floatConfig.DYNAMIC.NUMBER(end+1) = ...
      max(g_decArgo_floatConfig.DYNAMIC.NUMBER) + 1;
   g_decArgo_floatConfig.DYNAMIC.VALUES(:, end+1) = currentConfig;
   configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER(end);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% assign the config to the cycle and profile
g_decArgo_floatConfig.USE.CYCLE(end+1) = a_cycleNum;
g_decArgo_floatConfig.USE.CONFIG(end+1) = configNum;
   
% a=1
% create_csv_to_print_config_ir_sbd('setConfig_', 1, g_decArgo_floatConfig);

return
