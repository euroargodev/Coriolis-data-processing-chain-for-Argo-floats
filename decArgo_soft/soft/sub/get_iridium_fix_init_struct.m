% ------------------------------------------------------------------------------
% Get the basic structure to store Iridium fix information.
%
% SYNTAX :
%  [o_iridiumFixStruct] = get_iridium_fix_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_iridiumFixStruct : Iridium fix structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_iridiumFixStruct] = get_iridium_fix_init_struct

% default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;

% output parameters initialization
o_iridiumFixStruct = struct( ...
   'timeOfSessionJuld', g_decArgo_dateDef, ...
   'unitLocationLat', g_decArgo_argosLatDef, ...
   'unitLocationLon', g_decArgo_argosLonDef, ...
   'cepRadius', -1, ...
   'cycleNumber', -1, ... % cycle number corresponding to transmission session (not necessarily of the transmitted data - in case of delayed transmission)
   'cycleNumberData', -1 ... % cycle number corresponding to transmitted data (from NEMO .profile files)
   );

return
