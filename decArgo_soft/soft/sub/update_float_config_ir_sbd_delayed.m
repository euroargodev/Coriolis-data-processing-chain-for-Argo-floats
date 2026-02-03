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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function update_float_config_ir_sbd_delayed(a_floatParam, a_cycleNum, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {212, 214, 217}
      % Arvor-ARN-Ice Iridium 5.45
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      update_float_config_ir_sbd_212_214_217(a_floatParam, a_cycleNum);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {216} % Arvor-Deep-Ice Iridium 5.65 (IFREMER version)
      
      update_float_config_ir_sbd_216(a_floatParam, a_cycleNum);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {218} % Arvor-Deep-Ice Iridium 5.66 (NKE version)
      
      update_float_config_ir_sbd_218(a_floatParam, a_cycleNum);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {221, 230}
      % Arvor-deep 5.67
      % Arvor-Deep-Ice Iridium 5.77 (2DO)

      update_float_config_ir_sbd_221_230(a_floatParam, a_cycleNum);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   case {222, 223, 225, 232}
      % Arvor-ARN-Ice Iridium 5.47
      % Arvor-ARN-DO-Ice Iridium 5.48
      % Provor-ARN-DO-Ice Iridium 5.76
      % Arvor-ARN-Ice Iridium 5.47

      update_float_config_ir_sbd_222_223_225_232(a_floatParam, a_cycleNum, a_decoderId);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   case {224, 226, 227}
      % Arvor-ARN-Ice RBR Iridium 5.49
      % Arvor-ARN-Ice RBR 1 Hz Iridium 5.51
      % Arvor-ARN-Ice RBR 1 Hz + auto corrected PSAL Iridium 5.52

      update_float_config_ir_sbd_224_226_227(a_floatParam, a_cycleNum, a_decoderId);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {228} % Arvor-Deep-Ice Iridium 5.68 (3T prototype)
      
      update_float_config_ir_sbd_228(a_floatParam, a_cycleNum);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {229} % Arvor-Deep-Ice Iridium 5.69 (2T prototype)
      
      update_float_config_ir_sbd_229(a_floatParam, a_cycleNum);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {231} % Arvor-ARN-Ice SBE Iridium 5.53
      
      update_float_config_ir_sbd_231(a_floatParam, a_cycleNum);

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to update configuration for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
