% ------------------------------------------------------------------------------
% Update the DYNAMIC_TMP configuration with the contents of a received parameter
% packet.
%
% SYNTAX :
%  update_float_config_ir_sbd(a_floatParam, a_decoderId)
%
% INPUT PARAMETERS :
%   a_floatParam : parameter packet decoded data
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
%   12/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd(a_floatParam, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {201, 203} % Arvor-deep 4000
      
      update_float_config_ir_sbd_201_203(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {202} % Arvor-deep 3500
      
      update_float_config_ir_sbd_202(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {204} % Arvor Iridium 5.4
      
      update_float_config_ir_sbd_204(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {205} % Arvor Iridium 5.41 & 5.42
      
      update_float_config_ir_sbd_205(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {206, 207, 208, 209}
      % Provor-DO Iridium 5.71 & 5.7 & 5.72
      % Arvor-2DO Iridium 5.73
      
      update_float_config_ir_sbd_206_to_209(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {210, 211, 213}
      % Arvor-ARN Iridium
      % Provor-ARN-DO Iridium
      
      update_float_config_ir_sbd_210_211_213(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {212, 214}
      % Arvor-ARN-Ice Iridium
      % Provor-ARN-DO-Ice Iridium
      
      update_float_config_ir_sbd_212_214(a_floatParam);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {215} % Arvor-deep 4000 with "Near Surface" & "In Air" measurements
      
      update_float_config_ir_sbd_215(a_floatParam);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to update configuration for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
