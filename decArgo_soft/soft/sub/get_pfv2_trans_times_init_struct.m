% ------------------------------------------------------------------------------
% Get the basic structure to store TST and TET information.
%
% SYNTAX :
%  [o_dataStruct] = get_pfv2_trans_times_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : TST and TET initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/02/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_pfv2_trans_times_init_struct

% output parameters initialization
o_dataStruct = struct( ...
   'cycleNum', [], ...
   'techNum', [], ...
   'transStartTime', [], ...
   'transStartTimeAdj', [], ...
   'transEndTimePrevCy', [], ...
   'transEndTimePrevCyAdj', [], ...
   'cycleClockOffset', [] ...
   );

return
