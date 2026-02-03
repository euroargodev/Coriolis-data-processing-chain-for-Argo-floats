% ------------------------------------------------------------------------------
% Get the basic structure to store APEX APF11 Ice breakup detection information.
%
% SYNTAX :
%  [o_breakupDetect] = get_ice_breakup_detect_apx_apf11_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_breakupDetect : APEX APF11 Ice breakup detection structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/07/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_breakupDetect] = get_ice_breakup_detect_apx_apf11_init_struct

o_breakupDetect = struct( ...
   'detectTime', '', ...
   'detectTimeAdj', '', ...
   'detectFlag', '' ...
   );

return
