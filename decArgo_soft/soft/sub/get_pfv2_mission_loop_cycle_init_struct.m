% ------------------------------------------------------------------------------
% Get the basic structure to store mission/loop/cycle information.
%
% SYNTAX :
%  [o_dataStruct] = get_pfv2_mission_loop_cycle_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : mission/loop/cycle initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_pfv2_mission_loop_cycle_init_struct

% output parameters initialization
o_dataStruct = struct( ...
   'cycleNumber', [], ... % current cycle number
   'mission', [], ... % mission number of the current cycle
   'loop', [], ... % loop number, in the configuration, that corresponds to current cycle
   'cycle', [] ... % cycle number, in the configuration, that corresponds to current cycle
   );

return
