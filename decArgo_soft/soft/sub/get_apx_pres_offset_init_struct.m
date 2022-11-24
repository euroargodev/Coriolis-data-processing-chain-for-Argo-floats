% ------------------------------------------------------------------------------
% Get the basic structure to store pressure offset information.
%
% SYNTAX :
%  [o_dataStruct] = get_apx_pres_offset_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_dataStruct : pressure offset initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataStruct] = get_apx_pres_offset_init_struct

% output parameters initialization
o_dataStruct = struct( ...
   'cycleNum', [], ... % cycle number (associated to cyclePresOffset values)
   'cyclePresOffset', [], ... % raw surface pressure reported by the float
   'cycleNumAdjPres', [], ... % cycle number (associated to presOffset values)
   'presOffset', [] ... % PRES offset used to adjust PRES values
   );

return
