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
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31}
      o_statNcTechParamList = [[10:17] 20 21 22 221 224 225 321 323 521 524 525];
      
   case {201, 202, 203, 204, 205, 206, 207, 208, 209}
      
   case {1001, 1002, 1003, 1004, 1005, 1006}
      o_statNcTechParamList = 10:19;
      
   case {2001, 2002}
      
   otherwise
      fprintf('WARNING: The list of statistical technical parameters is not defined yet for decoderId #%d\n', a_decoderId);
end

return;
