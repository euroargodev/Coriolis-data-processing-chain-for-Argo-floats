% ------------------------------------------------------------------------------
% Add the configuration number and the output cycle number to the profiles,
% to the N_MEASUREMENT and N_CYCLE trajectory measurements and to the
% N_MEASUREMENT technical measurements.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
%    add_configuration_number_ir_rudics_cts5( ...
%    a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles   : input profile structures
%   a_tabTrajNMeas  : input trajectory N_MEASUREMENT measurement structures
%   a_tabTrajNCycle : input trajectory N_CYCLE measurement structures
%   a_tabTechNMeas  : input technical N_MEASUREMENT measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles   : output profile structures
%   o_tabTrajNMeas  : output trajectory N_MEASUREMENT measurement structures
%   o_tabTrajNCycle : output trajectory N_CYCLE measurement structures
%   o_tabTechNMeas  : output technical N_MEASUREMENT measurement structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
   add_configuration_number_ir_rudics_cts5( ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];

% float configuration
global g_decArgo_floatConfig;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;


% add the configuration number and the output cycle number of the profiles
for idProf = 1:length(a_tabProfiles)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabProfiles(idProf).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabProfiles(idProf).profileNumber));
   if (~isempty(idConf))
      a_tabProfiles(idProf).configMissionNumber = g_decArgo_floatConfig.USE.CONFIG(idConf);
      
      if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1))
         if (a_tabProfiles(idProf).outputCycleNumber == -1)
            % update the reports structure cycle list
            g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_floatConfig.USE.CYCLE_OUT(idConf)];
         end
      end
      
      a_tabProfiles(idProf).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
   end
end

% add the output cycle number of the N_MEASUREMENT measurements
for idNCy = 1:length(a_tabTrajNMeas)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNMeas(idNCy).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabTrajNMeas(idNCy).profileNumber));
   if (~isempty(idConf))
      a_tabTrajNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
   elseif (isempty(g_decArgo_floatConfig.USE.CYCLE))
      % prelude cycle
      a_tabTrajNMeas(idNCy).outputCycleNumber = 0;
   elseif ((a_tabTrajNMeas(idNCy).cycleNumber == min(g_decArgo_floatConfig.USE.CYCLE)) && ...
         (a_tabTrajNMeas(idNCy).profileNumber == 0))
      % prelude cycle
      a_tabTrajNMeas(idNCy).outputCycleNumber = 0;
   elseif (a_tabTrajNMeas(idNCy).profileNumber == 0)
      % EOL
      idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNMeas(idNCy).cycleNumber-1) & ...
         (g_decArgo_floatConfig.USE.PROFILE == 1));
      if (~isempty(idConf))
         a_tabTrajNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
      else
         % reset
         idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNMeas(idNCy).cycleNumber-1) & ...
            (g_decArgo_floatConfig.USE.PROFILE == 0));
         if (~isempty(idConf))
            a_tabTrajNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
         end
      end
   end
end
% manage EOL cycles
outputCycleNumberList = [a_tabTrajNMeas.outputCycleNumber];
idEol = find((outputCycleNumberList == -1));
idEol = idEol(find(idEol > 1));
for idC = 1:length(idEol)
   cyPrev = outputCycleNumberList(idEol(idC)-1);
   if (~any(outputCycleNumberList == cyPrev+1))
      a_tabTrajNMeas(idEol(idC)).outputCycleNumber = cyPrev+1;
      outputCycleNumberList(idEol(idC)) = cyPrev+1;
   end
end

% add the configuration number and the output cycle number of the N_CYCLE
% measurements
for idNCy = 1:length(a_tabTrajNCycle)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNCycle(idNCy).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabTrajNCycle(idNCy).profileNumber));
   if (~isempty(idConf))
      a_tabTrajNCycle(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
      if (a_tabTrajNCycle(idNCy).outputCycleNumber > 0) % we don't assign any configuration to cycle #0 data
         a_tabTrajNCycle(idNCy).configMissionNumber = g_decArgo_floatConfig.USE.CONFIG(idConf);
      end
   elseif (isempty(g_decArgo_floatConfig.USE.CYCLE))
      % prelude cycle
      a_tabTrajNCycle(idNCy).outputCycleNumber = 0;
   elseif ((a_tabTrajNCycle(idNCy).cycleNumber == min(g_decArgo_floatConfig.USE.CYCLE)) && ...
         (a_tabTrajNCycle(idNCy).profileNumber == 0))
      % prelude cycle
      a_tabTrajNCycle(idNCy).outputCycleNumber = 0;
      %       a_tabTrajNCycle(idNCy).configMissionNumber = 1; % we don't assign any configuration to cycle #0 data
   elseif (a_tabTrajNCycle(idNCy).profileNumber == 0)
      % EOL
      idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNCycle(idNCy).cycleNumber-1) & ...
         (g_decArgo_floatConfig.USE.PROFILE == 1));
      if (~isempty(idConf))
         a_tabTrajNCycle(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
         if (a_tabTrajNCycle(idNCy).outputCycleNumber > 0) % we don't assign any configuration to cycle #0 data
            a_tabTrajNCycle(idNCy).configMissionNumber = g_decArgo_floatConfig.USE.CONFIG(idConf);
         end
      else
         % reset
         idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTrajNCycle(idNCy).cycleNumber-1) & ...
            (g_decArgo_floatConfig.USE.PROFILE == 0));
         if (~isempty(idConf))
            a_tabTrajNCycle(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
            if (a_tabTrajNCycle(idNCy).outputCycleNumber > 0) % we don't assign any configuration to cycle #0 data
               a_tabTrajNCycle(idNCy).configMissionNumber = g_decArgo_floatConfig.USE.CONFIG(idConf);
            end
         end
      end
   end
end
% manage EOL cycles
outputCycleNumberList = [a_tabTrajNCycle.outputCycleNumber];
idEol = find((outputCycleNumberList == -1));
idEol = idEol(find(idEol > 1));
for idC = 1:length(idEol)
   cyPrev = outputCycleNumberList(idEol(idC)-1);
   if (~any(outputCycleNumberList == cyPrev+1))
      a_tabTrajNCycle(idEol(idC)).outputCycleNumber = cyPrev+1;
      outputCycleNumberList(idEol(idC)) = cyPrev+1;
   end
end

% add the output cycle number of the N_MEASUREMENT technical measurements
for idNCy = 1:length(a_tabTechNMeas)
   idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTechNMeas(idNCy).cycleNumber) & ...
      (g_decArgo_floatConfig.USE.PROFILE == a_tabTechNMeas(idNCy).profileNumber));
   if (~isempty(idConf))
      a_tabTechNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
   elseif ((a_tabTechNMeas(idNCy).cycleNumber == min(g_decArgo_floatConfig.USE.CYCLE)) && ...
         (a_tabTechNMeas(idNCy).profileNumber == 0))
      % prelude cycle
      a_tabTechNMeas(idNCy).outputCycleNumber = 0;
   elseif (a_tabTechNMeas(idNCy).profileNumber == 0)
      % EOL
      idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTechNMeas(idNCy).cycleNumber-1) & ...
         (g_decArgo_floatConfig.USE.PROFILE == 1));
      if (~isempty(idConf))
         a_tabTechNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
      else
         % reset
         idConf = find((g_decArgo_floatConfig.USE.CYCLE == a_tabTechNMeas(idNCy).cycleNumber-1) & ...
            (g_decArgo_floatConfig.USE.PROFILE == 0));
         if (~isempty(idConf))
            a_tabTechNMeas(idNCy).outputCycleNumber = g_decArgo_floatConfig.USE.CYCLE_OUT(idConf);
         end
      end
   end
end
% manage EOL cycles
if (~isempty(a_tabTechNMeas))
   outputCycleNumberList = [a_tabTechNMeas.outputCycleNumber];
   idEol = find((outputCycleNumberList == -1));
   idEol = idEol(find(idEol > 1));
   for idC = 1:length(idEol)
      cyPrev = outputCycleNumberList(idEol(idC)-1);
      if (~any(outputCycleNumberList == cyPrev+1))
         a_tabTechNMeas(idEol(idC)).outputCycleNumber = cyPrev+1;
         outputCycleNumberList(idEol(idC)) = cyPrev+1;
      end
   end
end

% update output parameters
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabTechNMeas = a_tabTechNMeas;

return;
