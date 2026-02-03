% ------------------------------------------------------------------------------
% Get the basic structure to store APEX APF11 Ice ascent abort information.
%
% SYNTAX :
%  [o_ascentAbort] = get_ice_ascent_abort_apx_apf11_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_iceDetection : APEX APF11 Ice ascent abort structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/07/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ascentAbort] = get_ice_ascent_abort_apx_apf11_init_struct

o_ascentAbort = struct( ...
   'abortTypeTime', '', ...
   'abortTypeTimeAdj', '', ...
   'abortType', 0 ...
   );

return
