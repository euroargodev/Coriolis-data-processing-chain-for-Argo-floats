% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_ncProfile] = process_apx_profile(a_profData, a_cycleNum, ...
%    a_timeData, a_presOffsetData, a_floatSurfData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profData       : profile data
%   a_cycleNum       : cycle number
%   a_timeData       : updated cycle time data structure
%   a_presOffsetData : updated pressure offset data structure
%   a_floatSurfData   : float surface data structure
%   a_decoderId       : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_ncProfile : created output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfile] = process_apx_profile(a_profData, a_cycleNum, ...
   a_timeData, a_presOffsetData, a_floatSurfData, a_decoderId)

% output parameters initialization
o_ncProfile = [];


if (isempty(a_profData))
   return;
end
   
% initialize a NetCDF profile structure and fill it with decoded profile data
profStruct = get_profile_init_struct(a_cycleNum, -1, -1, 1);

% positioning system
profStruct.posSystem = 'ARGOS';

% add parameter variables to the profile structure
profStruct.paramList = a_profData.paramList;

% add parameter data to the profile structure
profStruct.data = a_profData.data;

% add press offset data to the profile structure
idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
if (~isempty(idCycleStruct))
   profStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
end

% update the profile completed flag
if (~isempty(a_profData.expectedProfileLength))
   profStruct.profileCompleted = a_profData.expectedProfileLength - size(profStruct.data, 1);
end

% add configuration mission number
configMissionNumber = get_config_mission_number_argos( ...
   a_cycleNum, a_timeData, a_decoderId);
if (~isempty(configMissionNumber))
   profStruct.configMissionNumber = configMissionNumber;
end

% add vertical sampling scheme
profStruct.vertSamplingScheme = 'Primary sampling: discrete []';

% add profile date and location information
[profStruct] = add_apx_profile_date_and_location_argos( ...
   profStruct, a_floatSurfData, a_cycleNum);

o_ncProfile = profStruct;

return;
