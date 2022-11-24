% ------------------------------------------------------------------------------
% Get the float family.
%
% SYNTAX :
%  [o_platformFamily] = get_platform_family(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_platformFamily : float family
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/17/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_platformFamily] = get_platform_family(a_decoderId)

% output parameters initialization
o_platformFamily = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1, 4, 11, 12, 19, 24, 25, 27, 28, 29}
      % PROVOR Argos
      o_platformFamily = 'FLOAT';
      
   case {3, 17, 30, 31, 32}
      % ARVOR Argos
      o_platformFamily = 'FLOAT';
      
   case {105, 106, 107, 108, 109, 110, 301}
      % PROVOR REMOCEAN
      o_platformFamily = 'FLOAT';
      
   case {121, 122, 123}
      % PROVOR CTS5
      o_platformFamily = 'FLOAT';
      
   case {201, 202, 203, 215}
      % DEEP ARVOR
      o_platformFamily = 'FLOAT_DEEP';
      
   case {205, 204, 210, 211, 212}
      % ARVOR Iridium
      o_platformFamily = 'FLOAT';
      
   case {206, 207, 208, 209, 213, 214}
      % Provor-DO Iridium
      o_platformFamily = 'FLOAT';
            
   case {302, 303}
      % Arvor CM
      o_platformFamily = 'FLOAT_COASTAL';
      
   otherwise
      fprintf('ERROR: Float #%d: No platform family assigned to decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return;
