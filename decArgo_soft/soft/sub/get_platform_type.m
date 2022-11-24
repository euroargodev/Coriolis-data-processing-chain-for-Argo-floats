% ------------------------------------------------------------------------------
% Get the float type.
%
% SYNTAX :
%  [o_platformType] = get_platform_type(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_platformType : float type
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_platformType] = get_platform_type(a_decoderId)

% output parameters initialization
o_platformType = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1, 4, 11, 12, 19, 24, 25, 27, 28, 29}
      % PROVOR Argos
      o_platformType = 'PROVOR';
      
   case {3, 17, 30, 31, 32}
      % ARVOR Argos
      o_platformType = 'ARVOR';
      
   case {105, 106, 107, 108, 109, 301}
      % PROVOR REMOCEAN
      o_platformType = 'PROVOR_III';
      
   case {201, 202, 203}
      % DEEP ARVOR
      o_platformType = 'ARVOR_D';
      
   case {205, 204, 209, 210}
      % ARVOR Iridium
      o_platformType = 'ARVOR';
      
   case {206, 207, 208}
      % Provor-DO Iridium
      o_platformType = 'PROVOR';
            
   case {302, 303}
      % Arvor CM
      o_platformType = 'ARVOR_C';
      
   case {1001, 1002, 1003, 1004, 1005, 1006}
      % Apex Argos
      o_platformType = 'APEX';
      
   case {2001}
      % Nova
      o_platformType = 'NOVA';
      
   case {2002}
      % Dova
      o_platformType = 'DOVA';
      
   otherwise
      o_platformType = '';
      fprintf('WARNING: Float #%d: No platform type assigned to decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return;
