% ------------------------------------------------------------------------------
% Check if the buffer data is ready to be processed (if all expected data has
% been received).
%
% SYNTAX :
%  [o_completed, o_cycleProf, o_cycleInfoStr] = is_buffer_completed_ir_rudics_cts4(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_completed     : buffer completed flag (1 if the data can be processed, 0
%                    otherwise)
%   o_cycleProf    : cycle and profiles data in the completed buffer
%   o_cycleInfoStr : information on completed buffer
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/26/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed, o_cycleProf, o_cycleInfoStr] = is_buffer_completed_ir_rudics_cts4(a_decoderId)

% output parameters initialization
o_completed = 0;
o_cycleProf = [];
o_cycleInfoStr = '';

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 112}
      
      [o_completed, o_cycleProf] = is_buffer_completed_ir_rudics_cts4_105_to_110_112;

   case {111}
      
      [o_completed, o_cycleProf, o_cycleInfoStr] = is_buffer_completed_ir_rudics_cts4_111;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in is_buffer_completed_ir_rudics_cts4 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
