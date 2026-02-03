% ------------------------------------------------------------------------------
% Get the basic structure to store meta data trnasmitted in TECH files.
%
% SYNTAX :
%  [o_dataStruct] = get_pfv2_meta_from_tech_init_struct
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
%   14/11/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_pfv2_meta_from_tech_init_struct

% output parameters initialization
o_dataStruct = struct( ...
   'techId', [], ...
   'value', [] ...
   );

return
