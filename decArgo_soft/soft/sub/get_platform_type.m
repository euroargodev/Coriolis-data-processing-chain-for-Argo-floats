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
      
   case {105, 106, 107, 108, 109, 110, 111, 112, 113, 301}
      % PROVOR CTS4
      o_platformType = 'PROVOR_III';
      
   case {121, 122, 123, 124, 125}
      % PROVOR APMT (CTS5)
      o_platformType = 'PROVOR_IV';
      
   case {201, 202, 203, 215, 216, 218}
      % DEEP ARVOR
      o_platformType = 'ARVOR_D';
      
   case {205, 204, 209, 210, 211, 212}
      % ARVOR Iridium
      o_platformType = 'ARVOR';
      
   case {206, 207, 208, 213, 214}
      % Provor-DO Iridium
      o_platformType = 'PROVOR';
            
   case {217}
      % ARVOR-DO Iridium
      o_platformType = 'ARVOR';
      
   case {219, 220}
      % ARVOR-C Iridium
      o_platformType = 'ARVOR_C';
      
   case {302, 303}
      % Arvor CM
      o_platformType = 'ARVOR_C';
      
   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016, 1021, 1022}
      % Apex Argos
      o_platformType = 'APEX';
      
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, ...
         1314, ...
         1121, ...
         1321, 1322}
      % Apex Iridium
      o_platformType = 'APEX';
      
   case {1201}
      % Navis
      o_platformType = 'NAVIS_A';
      
   case {2001, 2002, 2003}
      % Nova & Dova
      o_platformType = 'NOVA';
      
      %    case {2002}
      %       % Dova
      %       o_platformType = 'DOVA';
      
   case {3001}
      % NEMO
      o_platformType = 'NEMO';

   otherwise
      o_platformType = '';
      fprintf('WARNING: Float #%d: No platform type assigned to decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return
