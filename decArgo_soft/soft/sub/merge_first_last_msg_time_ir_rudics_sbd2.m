% ------------------------------------------------------------------------------
% Assign the second Iridium session to the end of previous cycle and then merge
% the first/last msg and location times.
%
% SYNTAX :
%  [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_sbd2( ...
%    a_tabTrajNMeas, a_tabTrajNCycle, a_decoderId)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle : N_CYCLE trajectory data
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : N_MEASUREMENT trajectory data
%   o_tabTrajNCycle : N_CYCLE trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_sbd2( ...
   a_tabTrajNMeas, a_tabTrajNCycle, a_decoderId)

% output parameters initialization
o_tabTrajNMeas = [];
o_tabTrajNCycle = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 301, 302, 303}
      
      [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_105_to_110_sbd2(a_tabTrajNMeas, a_tabTrajNCycle);

   case {111}
      
      [o_tabTrajNMeas, o_tabTrajNCycle] = merge_first_last_msg_time_ir_rudics_111(a_tabTrajNMeas, a_tabTrajNCycle);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in merge_first_last_msg_time_ir_rudics_sbd2 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
