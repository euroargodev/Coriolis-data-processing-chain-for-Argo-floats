% ------------------------------------------------------------------------------
% Check if a given profile has only core parameters.
%
% SYNTAX :
%  [o_core] = is_core_profile(a_profile)
%
% INPUT PARAMETERS :
%   a_profile : input profile
%
% OUTPUT PARAMETERS :
%   o_core : 1 if the profile has only core parameters (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_core] = is_core_profile(a_profile)

o_core = 0;

if (~isempty(a_profile.paramList))
   if (~any(([a_profile.paramList.paramType] ~= 'c') & ([a_profile.paramList.paramType] ~= 'j')))
      o_core = 1;
   end
end

return
