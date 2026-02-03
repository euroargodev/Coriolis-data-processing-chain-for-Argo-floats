% ------------------------------------------------------------------------------
% Update the output cycle number of the profile, N_MEASUREMENT and N_CYCLE data
% structures.
%
% SYNTAX :
%  [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
%    update_output_cycle_number_ir_sbd( ...
%    a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas, a_tabTechAuxNMeas)
%
% INPUT PARAMETERS :
%   a_tabProfiles     : input profile structures
%   a_tabTrajNMeas    : input trajectory N_MEASUREMENT measurement structures
%   a_tabTrajNCycle   : input trajectory N_CYCLE measurement structures
%   a_tabTechNMeas    : input technical N_MEASUREMENT measurement structures
%   a_tabTechAuxNMeas : input technical N_MEASUREMENT AUX measurement structures
%
% OUTPUT PARAMETERS :
%   o_tabProfiles     : output profile structures
%   o_tabTrajNMeas    : output trajectory N_MEASUREMENT measurement structures
%   o_tabTrajNCycle   : output trajectory N_CYCLE measurement structures
%   o_tabTechNMeas    : output technical N_MEASUREMENT measurement structures
%   o_tabTechAuxNMeas : output technical N_MEASUREMENT AUX measurement structures
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%  10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabTrajNMeas, o_tabTrajNCycle, o_tabTechNMeas, o_tabTechAuxNMeas] = ...
   update_output_cycle_number_ir_sbd( ...
   a_tabProfiles, a_tabTrajNMeas, a_tabTrajNCycle, a_tabTechNMeas, a_tabTechAuxNMeas)

% output parameters initialization
o_tabProfiles = [];
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];
o_tabTechNMeas = [];
o_tabTechAuxNMeas = [];


% duplicate cycleNumber in outputCycleNumber in the profile structures
if (~isempty(a_tabProfiles))
   cyNumList = [a_tabProfiles.cycleNumber];
   cyNumList = num2cell(cyNumList);
   [a_tabProfiles.outputCycleNumber] = deal(cyNumList{:});
end

% duplicate cycleNumber in outputCycleNumber in the N_MEASUREMENT traj structures
if (~isempty(a_tabTrajNMeas))
   cyNumList = [a_tabTrajNMeas.cycleNumber];
   cyNumList = num2cell(cyNumList);
   [a_tabTrajNMeas.outputCycleNumber] = deal(cyNumList{:});
end

% duplicate cycleNumber in outputCycleNumber in the N_CYCLE structures
if (~isempty(a_tabTrajNCycle))
   cyNumList = [a_tabTrajNCycle.cycleNumber];
   cyNumList = num2cell(cyNumList);
   [a_tabTrajNCycle.outputCycleNumber] = deal(cyNumList{:});
end

% duplicate cycleNumber in outputCycleNumber in the N_MEASUREMENT tech structures
if (~isempty(a_tabTechNMeas))
   cyNumList = [a_tabTechNMeas.cycleNumber];
   cyNumList = num2cell(cyNumList);
   [a_tabTechNMeas.outputCycleNumber] = deal(cyNumList{:});
end

% duplicate cycleNumber in outputCycleNumber in the N_MEASUREMENT tech AUX structures
if (~isempty(a_tabTechAuxNMeas))
   cyNumList = [a_tabTechAuxNMeas.cycleNumber];
   cyNumList = num2cell(cyNumList);
   [a_tabTechAuxNMeas.outputCycleNumber] = deal(cyNumList{:});
end

% update output parameters
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabTechNMeas = a_tabTechNMeas;
o_tabTechAuxNMeas = a_tabTechAuxNMeas;

return
