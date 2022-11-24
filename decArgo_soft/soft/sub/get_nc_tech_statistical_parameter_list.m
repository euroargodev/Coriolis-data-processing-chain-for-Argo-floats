% ------------------------------------------------------------------------------
% Get the list of NetCDF statistical technical parameters (they should be set to
% 0 if not present in the received data).
%
% SYNTAX :
%  [o_statNcTechParamList] = get_nc_tech_statistical_parameter_list(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/04/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_statNcTechParamList] = get_nc_tech_statistical_parameter_list(a_decoderId)

% output parameters initialization
o_statNcTechParamList = [];


% list of parameters to initialize with 0 values
switch (a_decoderId)
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      o_statNcTechParamList = [10:17 20 21 22 221 224 225 321 323 521 524 525 1000];
      
   case {30, 32}
      o_statNcTechParamList = [10:17 20 21 22 221 224 225 321 323 521 524 525 1000 1001];
      
   case {201, 202, 203}
      o_statNcTechParamList = 1001:1007;
      
   case {204, 205, 206, 207, 208, 209}
      o_statNcTechParamList = 1001:1005;
      
   case {210, 211, 213}
      o_statNcTechParamList = 1001:1009;
      
   case {212, 222, 214, 217, 223, 224}
      o_statNcTechParamList = 1001:1010;
      
   case {215, 216}
      o_statNcTechParamList = 1001:1009;
      
   case {218, 221}
      o_statNcTechParamList = [1001:1009 1016];
      
   case {219, 220}
      o_statNcTechParamList = 1000;

   case {1001, 1002, 1003, 1004, 1005, 1006, 1007, 1008, 1009, 1010, 1011, ...
         1012, 1013, 1014, 1015, 1016, 1021, 1022}
      o_statNcTechParamList = 10:19;
      
   case {1101, 1102, 1103, 1104, 1105, 1106, 1107, 1108, 1109, 1110, 1111, 1112, 1113, ...
         1201, ...
         1314, ...
         1321, 1322, 1323, ...
         1121, 1122, 1123, 1124, 1125, 1126, 1127}
      % none
      
   case {2001, 2002, 2003}
      % none
      
   case {3001}
      % none
      
   otherwise
      fprintf('WARNING: The list of statistical technical parameters is not defined yet for decoderId #%d\n', a_decoderId);
end

return
