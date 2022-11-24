% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd_delayed(a_floatParam, a_cycleNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatParam : parameter packet decoded data
%   a_cycleNum   : associated cycle number
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
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_delayed(a_floatParam, a_cycleNum, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {212, 214}
      % Arvor-ARN-Ice Iridium
      % Provor-ARN-DO-Ice Iridium
      
      update_float_config_ir_sbd_212_214(a_floatParam, a_cycleNum);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to update configuration for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
