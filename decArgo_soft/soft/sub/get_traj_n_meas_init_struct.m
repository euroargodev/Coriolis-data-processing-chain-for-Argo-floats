% ------------------------------------------------------------------------------
% Get the basic structure to store N_MEASUREMENT trajectory information.
%
% SYNTAX :
%  [o_trajNMeasStruct] = get_traj_n_meas_init_struct(a_cycleNum, a_profNum)
%
% INPUT PARAMETERS :
%   a_cycleNum : cycle number
%   a_profNum  : profile number
%
% OUTPUT PARAMETERS :
%   o_trajNMeasStruct : N_MEASUREMENT trajectory initialized structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/07/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajNMeasStruct] = get_traj_n_meas_init_struct(a_cycleNum, a_profNum)

% output parameters initialization
o_trajNMeasStruct = struct( ...
   'cycleNumber', a_cycleNum, ...
   'outputCycleNumber', -1, ...
   'profileNumber', a_profNum, ...
   'surfOnly', 0, ...
   'tabMeas', '');

return
