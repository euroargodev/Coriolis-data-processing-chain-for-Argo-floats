% ------------------------------------------------------------------------------
% Get the basic structure to store surface data information for a cycle.
%
% SYNTAX :
%  [o_cycleSurfDataStruct] = get_cycle_surf_data_init_struct()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_cycleSurfDataStruct : surface data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleSurfDataStruct] = get_cycle_surf_data_init_struct()

% default values
global g_decArgo_dateDef;


% output parameters initialization
o_cycleSurfDataStruct = struct( ...
   'descentStartTime', g_decArgo_dateDef, ...
   'ascentEndTime', g_decArgo_dateDef, ...
   'transStartTime', g_decArgo_dateDef, ...
   'firstMsgTime', g_decArgo_dateDef, ...
   'lastCtdMsgTime', g_decArgo_dateDef, ...
   'lastMsgTime', g_decArgo_dateDef, ...
   'argosLocDate', '', ...
   'argosLocLon', '', ...
   'argosLocLat', '', ...
   'argosLocAcc', '', ...
   'argosLocSat', '', ...
   'argosLocQc', '');

return;
