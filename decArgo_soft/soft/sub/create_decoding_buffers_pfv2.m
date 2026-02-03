% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
% [o_floatbuffers] = create_decoding_buffers_pfv2(a_floatData, a_decoderId)
%
% INPUT PARAMETERS :
%   o_floatData : float data information
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_floatbuffers  : float decoding buffers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatbuffers] = create_decoding_buffers_pfv2(a_floatData, a_decoderId)

% output parameters initialization
o_floatbuffers = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {401} % Arvor PFV2 8.01

      [o_floatbuffers] = create_decoding_buffers_401(a_floatData);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {402} % Arvor PFV2 8.02

      [o_floatbuffers] = create_decoding_buffers_402(a_floatData);

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in create_decoding_buffers_pfv2 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return