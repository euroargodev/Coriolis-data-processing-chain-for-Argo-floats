% ------------------------------------------------------------------------------
% Get the default duration of the prelude phase according to float decoder Id.
%
% SYNTAX :
%  [o_preludeDuration] = get_default_prelude_duration(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_preludeDuration : duration of the prelude phase (in minutes)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_preludeDuration] = get_default_prelude_duration(a_decoderId)

% output parameters initialization
o_preludeDuration = [];

% default values
global g_decArgo_durationDef;


switch (a_decoderId)
   
   case {1, 11, 12, 4, 19}
      o_preludeDuration = 0;

   case {24, 27, 25, 28, 29, 3, 17, 30, 31, 32}
      o_preludeDuration = 180;

   otherwise
      o_preludeDuration = g_decArgo_durationDef;
      fprintf('WARNING: No default prelude duration for decoderId #%d\n', a_decoderId);
      
end

return
