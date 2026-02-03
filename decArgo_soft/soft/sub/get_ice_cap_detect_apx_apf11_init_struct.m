% ------------------------------------------------------------------------------
% Get the basic structure to store APEX APF11 Ice cap detection information.
%
% SYNTAX :
%  [o_capDetect] = get_ice_cap_detect_apx_apf11_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_iceDetection : APEX APF11 Ice cap detection structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/07/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_capDetect] = get_ice_cap_detect_apx_apf11_init_struct

o_capDetect = struct( ...
   'detectTime', '', ...
   'detectTimeAdj', '', ...
   'detectPres', '', ...
   'detectPresAdj', '', ...
   'detectTemp', '', ...
   'detectFlag', '' ...
   );

return
