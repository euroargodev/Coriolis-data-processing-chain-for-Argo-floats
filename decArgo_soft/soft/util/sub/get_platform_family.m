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
      
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 301}
      % PROVOR CTS4
      o_platformFamily = 'FLOAT';
      
   case {121, 122, 123, 124, 125, 126, 127}
      % PROVOR CTS5
      o_platformFamily = 'FLOAT';
      
   case {201, 202, 203, 215, 216, 218, 221}
      % DEEP ARVOR
      o_platformFamily = 'FLOAT_DEEP';
      
   case {205, 204, 210, 211, 212, 222, 224}
      % ARVOR Iridium
      o_platformFamily = 'FLOAT';
      
   case {206, 207, 208, 209, 213, 214, 225}
      % Provor-DO Iridium
      o_platformFamily = 'FLOAT';
            
   case {217, 223}
      % Arvor-DO Iridium
      o_platformFamily = 'FLOAT';
            
   case {302, 303}
      % Arvor CM
      o_platformFamily = 'FLOAT_COASTAL';
      
   case {2001, 2002, 2003}
      % NOVA & DOVA
      o_platformFamily = 'FLOAT';
         
   case {1321, 1322, 1323, 1121, 1122, 1123, 1124, 1125, 1126, 1127}
      % Apex APF11
      o_platformFamily = 'FLOAT';
      
   otherwise
      fprintf('ERROR: Float #%d: No platform family assigned to decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return
