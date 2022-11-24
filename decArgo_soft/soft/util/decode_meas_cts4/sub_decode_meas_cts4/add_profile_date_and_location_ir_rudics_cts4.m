% ------------------------------------------------------------------------------
% Add the profile date and location of a profile.
%
% SYNTAX :
%  [o_profStruct] = add_profile_date_and_location_ir_rudics_cts4( ...
%    a_profStruct, ...
%    a_descentToParkStartDate, a_ascentEndDate,...
%    a_gpsData)
%
% INPUT PARAMETERS :
%   a_profStruct             : input profile
%   a_descentToParkStartDate : descent to park start date
%   a_ascentEndDate          : ascent end date
%   a_gpsData                : information on GPS locations
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
%   02/05/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profStruct] = add_profile_date_and_location_ir_rudics_cts4( ...
   a_profStruct, ...
   a_descentToParkStartDate, a_ascentEndDate,...
   a_gpsData)

% output parameters initialization
o_profStruct = a_profStruct;

return;
