% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
%  [o_decodedData] = create_decoding_buffers(a_decodedData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decodedData : decoded data
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_decodedData : decoded data (decoding buffers are in 'rankByCycle'
%                   field)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/06/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = create_decoding_buffers(a_decodedData, a_decoderId)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   case {212, 214, 216, 217, 218}
      % Arvor-ARN-Ice Iridium 5.45
      % Provor-ARN-DO-Ice Iridium 5.75
      % Arvor-Deep-Ice Iridium 5.65 (IFREMER version)
      % Arvor-ARN-DO-Ice Iridium 5.46
      % Arvor-Deep-Ice Iridium 5.66 (NKE version)
      
      [o_decodedData] = create_decoding_buffers_212_214_216_217_218(a_decodedData, a_decoderId);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {221} % Arvor-Deep-Ice Iridium 5.67
      
      [o_decodedData] = create_decoding_buffers_221(a_decodedData, a_decoderId);
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {222, 223, 225, 232}
      % Arvor-ARN-Ice Iridium 5.47
      % Arvor-ARN-DO-Ice Iridium 5.48
      % Provor-ARN-DO-Ice Iridium 5.76
      % Arvor-ARN-Ice Iridium 5.54

      [o_decodedData] = create_decoding_buffers_222_223_225_232(a_decodedData, a_decoderId);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   case {224, 226, 227, 231}
      % Arvor-ARN-Ice RBR Iridium 5.49
      % Arvor-ARN-Ice RBR 1 Hz Iridium 5.51
      % Arvor-ARN-Ice RBR 1 Hz + auto corrected PSAL Iridium 5.52
      % Arvor-ARN-Ice SBE Iridium 5.53

      [o_decodedData] = create_decoding_buffers_224_226_227_231(a_decodedData, a_decoderId);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
   case {228} % Arvor-Deep-Ice Iridium 5.68 (3T prototype)
      
      [o_decodedData] = create_decoding_buffers_228(a_decodedData, a_decoderId);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   case {229} % Arvor-Deep-Ice Iridium 5.69 (2T prototype)

      [o_decodedData] = create_decoding_buffers_229(a_decodedData, a_decoderId);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   case {230} % Arvor-Deep-Ice Iridium 5.77 (2DO)

      [o_decodedData] = create_decoding_buffers_230(a_decodedData, a_decoderId);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to create decoding buffers for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
