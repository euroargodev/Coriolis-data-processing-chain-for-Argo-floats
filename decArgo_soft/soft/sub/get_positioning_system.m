% ------------------------------------------------------------------------------
% Get the float positioning system
%
% SYNTAX :
%  [o_posSystem] = get_positioning_system(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_posSystem : float positioning system
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_posSystem] = get_positioning_system(a_decoderId)

% output parameters initialization
o_posSystem = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31, 32}
      o_posSystem = 'ARGOS';
      
   case {105, 106, 107, 108, 109, 110, 121, ...
         201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, ...
         301, 302, 303}
      o_posSystem = 'GPS';
      
   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016}
      o_posSystem = 'ARGOS';
      
   case {2001, 2002}
      o_posSystem = 'GPS';

   otherwise
      o_posSystem = ' ';
      fprintf('WARNING: Float #%d: No positioning system defined yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
