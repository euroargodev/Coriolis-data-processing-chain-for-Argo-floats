% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_prv_ir_rudics_cts4(a_launchDate, a_decoderId)
%
% INPUT PARAMETERS :
%   a_launchDate : launch date of the float
%   a_decoderId  : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_prv_ir_rudics_cts4(a_launchDate, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 112}
      
      init_float_config_prv_ir_rudics_cts4_105_to_110_112(a_launchDate, a_decoderId);

   case {111, 113, 114}
      
      init_float_config_prv_ir_rudics_cts4_111_113_114(a_launchDate, a_decoderId);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in init_float_config_prv_ir_rudics_cts4 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
