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
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
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
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet to create decoding buffers for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
