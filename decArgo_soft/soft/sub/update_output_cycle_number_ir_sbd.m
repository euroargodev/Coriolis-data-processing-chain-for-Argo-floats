% ------------------------------------------------------------------------------
% Update the output cycle number of the profile, N_MEASUREMENT and N_CYCLE data
% structures.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
%    update_output_cycle_number_ir_sbd( ...
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
%  10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas] = ...
   update_output_cycle_number_ir_sbd( ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];


% duplicate cycleNumber in outputCycleNumber in the profile structures
for id = 1:length(a_tabProfiles)
   a_tabProfiles(id).outputCycleNumber = a_tabProfiles(id).cycleNumber;
end

% duplicate cycleNumber in outputCycleNumber in the N_MEASUREMENT traj structures
for id = 1:length(a_tabTrajNMeas)
   a_tabTrajNMeas(id).outputCycleNumber = a_tabTrajNMeas(id).cycleNumber;
end

% duplicate cycleNumber in outputCycleNumber in the N_CYCLE structures
for id = 1:length(a_tabTrajNCycle)
   a_tabTrajNCycle(id).outputCycleNumber = a_tabTrajNCycle(id).cycleNumber;
end

% duplicate cycleNumber in outputCycleNumber in the N_MEASUREMENT tech structures
for id = 1:length(a_tabTechNMeas)
   a_tabTechNMeas(id).outputCycleNumber = a_tabTechNMeas(id).cycleNumber;
end

% update output parameters
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabTechNMeas = a_tabTechNMeas;

return
