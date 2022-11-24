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
      
   case {105, 106, 107, 108, 109, 301, 302, 303}
      % PROVOR REMOCEAN & ARVOR CM
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {201, 202, 203}
      % ARVOR DEEP 4000
      % ARVOR DEEP 3500
      o_comment = 'JULD and PRES variable resolutions depend on measurement codes';
      
   case {205, 204, 210, 211}
      % ARVOR Iridium
      % ARVOR-ARN Iridium
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
      
   case {1004}
      % Apex Argos
      o_comment = 'PRES variable resolution depends on measurement codes';

   case {2001, 2002}
      % Nova, Dova
      o_comment = 'JULD and PRES variable resolution depends on measurement codes';

   otherwise
      o_comment = ' ';
      fprintf('WARNING: Float #%d: No global comment on resolution defined yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
