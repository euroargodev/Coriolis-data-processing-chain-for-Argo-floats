% ------------------------------------------------------------------------------
% Get the basic structure to store surface data information.
%
% SYNTAX :
%  [o_floatSurfDataStruct] = get_float_surf_data_init_struct()
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_floatSurfDataStruct : surface data initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/03/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatSurfDataStruct] = get_float_surf_data_init_struct()

% default values
global g_decArgo_dateDef;


% output parameters initialization
o_floatSurfDataStruct = struct( ...
   'updatedForCycleNumber', -1, ...
   'launchDate', g_decArgo_dateDef, ...
   'launchLon', '', ...
   'launchLat', '', ...
   'cycleDuration', '', ...
   'cycleNumbers', [], ...
   'cycleData', '');

return
