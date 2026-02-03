% ------------------------------------------------------------------------------
% Decode technical file.
%
% SYNTAX :
% [o_techData] = decode_pfv2_tech_file(a_fileName, a_decoderId)
%
% INPUT PARAMETERS :
%   a_fileName  : technical file name
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_techData : decoded TECH data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/23/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techData] = decode_pfv2_tech_file(a_fileName, a_decoderId)

% output parameters initialization
o_techData = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {401} % Arvor PFV2 8.01

      o_techData = decode_pfv2_tech_file_401(a_fileName);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {402} % Arvor PFV2 8.02

      o_techData = decode_pfv2_tech_file_402(a_fileName);

   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in decode_pfv2_tech_file for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
