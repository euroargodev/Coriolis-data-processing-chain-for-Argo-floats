% ------------------------------------------------------------------------------
% Find in the configuration if the float surfaced after a given profile.
%
% SYNTAX :
%  [o_surface] = config_surface_after_prof_ir_rudics_sbd2(a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_cycleNum  : cycle number
%   a_profNum   : profile number
%
% OUTPUT PARAMETERS :
%   o_surface  : output surface flag (1: yes, 0: no, -1: don't know
%                (missing configuration information))
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surface] = config_surface_after_prof_ir_rudics_sbd2(a_cycleNum, a_profNum)

% output parameters initialization
o_surface = [];

% float configuration
global g_decArgo_floatConfig;


% current configuration
configNum = g_decArgo_floatConfig.DYNAMIC.NUMBER;
configName = g_decArgo_floatConfig.DYNAMIC.NAMES;
configValue = g_decArgo_floatConfig.DYNAMIC.VALUES;
usedCy = g_decArgo_floatConfig.USE.CYCLE;
usedProf = g_decArgo_floatConfig.USE.PROFILE;
usedConfNum = g_decArgo_floatConfig.USE.CONFIG;

% if a_profNum < 0, the last profile of the previous cycle is wanted => the
% float surfaced
if (a_profNum < 0)
   o_surface = 1;
   return
end

% find the id of the concerned configuration
idUsedConf = find((usedCy == a_cycleNum) & (usedProf == a_profNum));
if (isempty(idUsedConf))
   % the configuration does not exist (no data received yet)
   o_surface = -1;
   return
end
idConf = find(configNum == usedConfNum(idUsedConf));

% name of the concerned parameter
confName = sprintf('CONFIG_PM_%d', 7+a_profNum*5);

% retrieve the configuration value
idPos = find(strcmp(confName, configName) == 1, 1);
surface = configValue(idPos, idConf);

if (surface == 0)
   % check if it is the last profile of the cycle
   % name of the concerned parameter
   confName = 'CONFIG_PM_0';
   
   % retrieve the configuration value
   idPos = find(strcmp(confName, configName) == 1, 1);
   nbProf = configValue(idPos, idConf);
   if (a_profNum+1 >= nbProf)
      surface = 1;
   end
end

o_surface = surface;

return
