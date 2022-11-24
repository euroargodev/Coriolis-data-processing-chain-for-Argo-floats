% ------------------------------------------------------------------------------
% Set cycle start time of a given cycle as TET of the previous cycle.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = ...
%    finalize_trajectory_data_argos( ...
%    a_tabTrajNMeas, a_tabTrajNCycle)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : input N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : input N_CYCLE trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : output N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = ...
   finalize_trajectory_data_argos( ...
   a_tabTrajNMeas, a_tabTrajNCycle)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% global measurement codes
global g_MC_CycleStart;
global g_MC_TET;

% global time status
global g_JULD_STATUS_2;

% default values
global g_decArgo_ncDateDef;


% N_MEASUREMENT DATA

% assign cycle start time of the current cycle to the TET of the previous cycle
if (~isempty(a_tabTrajNMeas))
   tabCyNum = sort(unique([a_tabTrajNMeas.cycleNumber]));
   for idCy = 1:length(tabCyNum)
      cycleNum = tabCyNum(idCy);
      if (cycleNum > 0)
         idC = find([a_tabTrajNMeas.cycleNumber] == cycleNum);
         idF1 = find([a_tabTrajNMeas(idC).tabMeas.measCode] == g_MC_CycleStart);
         if (~isempty(idF1))
            idCyPrec = find([a_tabTrajNMeas.cycleNumber] == cycleNum-1);
            if (~isempty(idCyPrec))
               idF2 = find([a_tabTrajNMeas(idCyPrec).tabMeas.measCode] == g_MC_TET);
               if (~isempty(idF2))
                  
                  measStruct = create_one_meas_float_time(g_MC_TET, ...
                     a_tabTrajNMeas(idC).tabMeas(idF1).juld, g_JULD_STATUS_2, 0);
                  a_tabTrajNMeas(idCyPrec).tabMeas(idF2) = measStruct;
               end
            end
         end
      end
   end
end

% N_CYCLE DATA

% assign cycle start time of the current cycle to the TET of the previous cycle
if (~isempty(a_tabTrajNMeas))
   tabCyNum = sort(unique([a_tabTrajNCycle.cycleNumber]));
   for idCy = 1:length(tabCyNum)
      cycleNum = tabCyNum(idCy);
      
      if (cycleNum > 0)
         idCyCur = find([a_tabTrajNCycle.cycleNumber] == cycleNum);
         idCyPrec = find([a_tabTrajNCycle.cycleNumber] == cycleNum-1);
         if (~isempty(idCyPrec) && ...
               ~isempty(a_tabTrajNCycle(idCyCur).juldCycleStart) && ...
               (a_tabTrajNCycle(idCyCur).juldCycleStart ~= g_decArgo_ncDateDef))
            
            a_tabTrajNCycle(idCyPrec).juldTransmissionEnd = a_tabTrajNCycle(idCyCur).juldCycleStart;
            a_tabTrajNCycle(idCyPrec).juldTransmissionEndStatus = a_tabTrajNCycle(idCyCur).juldCycleStartStatus;
         end
      end
   end
end

% output data
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;

return;
