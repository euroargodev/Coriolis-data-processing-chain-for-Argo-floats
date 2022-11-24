% ------------------------------------------------------------------------------
% Add the profile date and location of an Argos profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_argos( ...
%    a_profStruct, a_floatSurfData, a_cycleNum, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profStruct    : input profile
%   a_floatSurfData : input float surface data structure
%   a_cycleNum      : current cycle number
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_profStruct : output dated and located profile
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/07/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_argos( ...
   a_profStruct, a_floatSurfData, a_cycleNum, a_decoderId)

% output parameters initialization
o_profStruct = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 31}
      [o_profStruct] = add_profile_date_and_location_argos_first_float_version( ...
         a_profStruct, a_floatSurfData, a_cycleNum);

   case {30, 32}
      [o_profStruct] = add_profile_date_and_location_30_32( ...
         a_profStruct, a_floatSurfData, a_cycleNum);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing done yet in add_profile_date_and_location_argos for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
      
end

return
