% ------------------------------------------------------------------------------
% Retrieve global comment on unusual resolutions for a given decoder.
%
% SYNTAX :
%  [o_comment] = get_global_comment_on_resolution(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_comment : output comment
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_comment] = get_global_comment_on_resolution(a_decoderId)

% output parameter initialization
o_comment = [];

% current float WMO number
global g_decArgo_floatNum;

switch (a_decoderId)
   
   case {1, 4, 11, 12, 19, 24, 25, 27, 28, 29}
      % PROVOR Argos
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {3, 17, 30, 31, 32}
      % ARVOR Argos
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {105, 106, 107, 108, 109, 110, 111, 112, 301, 302, 303}
      % PROVOR CTS4 & ARVOR CM
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {121, 122, 123, 124}
      % PROVOR APMT
      o_comment = 'PRES variable resolutions depend on measurement codes';
      
   case {201, 202, 203, 215, 216}
      % ARVOR DEEP 4000
      % ARVOR DEEP 3500
      % ARVOR DEEP 4000 with "Near Surface" & "In Air" measurements
      % Arvor-Deep-Ice Iridium 5.65
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {205, 204, 210, 211, 212, 213, 214, 217}
      % ARVOR Iridium
      % ARVOR-ARN Iridium
      % ARVOR-ARN-Ice Iridium
      % PROVOR-ARN-DO Iridium
      % Provor-ARN-DO-Ice Iridium
      % Arvor-ARN-DO-Ice Iridium 5.46
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {209}
      % Arvor-2DO Iridium
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
   
   case {206, 207, 208}
      % Provor-DO Iridium
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';

   case {1001, 1002, 1003, 1005, 1006, 1007, 1008, 1009, 1010, 1011, 1012, ...
         1013, 1014, 1015, 1016}
      % Apex Argos
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {1021, 1022}
      % Apex Argos APF11
      o_comment = 'JULD variable resolution depends on measurement codes';
      
   case {1004}
      % Apex Argos
      o_comment = 'PRES variable resolution depends on measurement codes';

   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, 1314}
      % Apex Iridium Rudics & Sbd
      o_comment = 'PRES variable resolution depends on measurement codes';
      
   case {1121, 1321, 1322}
      % Apex APF11 Iridium
      o_comment = '';
      
   case {1201}
      % Navis
      o_comment = 'PRES variable resolution depends on measurement codes';
      
   case {2001, 2002, 2003}
      % Nova, Dova
      o_comment = 'JULD and PRES variable resolution depends on measurement codes';

   otherwise
      o_comment = ' ';
      fprintf('WARNING: Float #%d: No global comment on resolution defined yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
