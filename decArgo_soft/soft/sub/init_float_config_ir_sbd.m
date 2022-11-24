% ------------------------------------------------------------------------------
% Initialize the float configurations and store the configuration at launch.
%
% SYNTAX :
%  init_float_config_ir_sbd(a_launchDate, a_decoderId)
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
%   12/03/2014 - RNU - creation
% ------------------------------------------------------------------------------
function init_float_config_ir_sbd(a_launchDate, a_decoderId)

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {201, 203} % Arvor-deep 4000
      
      init_float_config_prv_ir_sbd_201_203(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {202} % Arvor-deep 3500
      
      init_float_config_prv_ir_sbd_202(a_launchDate, a_decoderId);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {204} % Arvor Iridium 5.4
      
      init_float_config_prv_ir_sbd_204(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {205} % Arvor Iridium 5.41 & 5.42
      
      init_float_config_prv_ir_sbd_205(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {206, 207, 208, 209}
      % Provor-DO Iridium 5.71 & 5.7 & 5.72
      % Arvor-2DO Iridium 5.73
      
      init_float_config_prv_ir_sbd_206_to_209(a_launchDate, a_decoderId);
            
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {210, 211} % Arvor-ARN Iridium
      
      init_float_config_prv_ir_sbd_210_211(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {212}
      % Arvor-ARN-Ice Iridium
      
      init_float_config_prv_ir_sbd_212(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {213} % Provor-ARN-DO Iridium
      
      init_float_config_prv_ir_sbd_213(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {214, 217}
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-ARN-DO-Ice Iridium 5.46
      
      init_float_config_prv_ir_sbd_214_217(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {215} % Arvor-deep 4000 with "Near Surface" & "In Air" measurements
      
      init_float_config_prv_ir_sbd_215(a_launchDate);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {216} % Arvor-deep 4000 with NS&IA and Ice (IFREMER version)
      
      init_float_config_prv_ir_sbd_216(a_launchDate);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {218} % Arvor-deep 4000 with NS&IA and Ice (NKE version)
      
      init_float_config_prv_ir_sbd_218(a_launchDate);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {2001, 2002, 2003} % Nova, Dova
      
      init_float_config_nva_ir_sbd(a_launchDate, a_decoderId);

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to initialize configuration for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
