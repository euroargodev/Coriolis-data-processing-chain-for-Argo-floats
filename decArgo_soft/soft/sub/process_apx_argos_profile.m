% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_ncProfile] = process_apx_argos_profile(a_profData, a_profNstData, a_cycleNum, ...
%    a_timeData, a_presOffsetData, a_floatSurfData, a_decoderId)
%
% INPUT PARAMETERS :
%   a_profData       : profile data
%   a_profNstData    : NST profile data
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
function [o_ncProfile] = process_apx_argos_profile(a_profData, a_profNstData, a_cycleNum, ...
   a_timeData, a_presOffsetData, a_floatSurfData, a_decoderId)

% output parameters initialization
o_ncProfile = [];


if (isempty(a_profData))
   return
end
   
profiles = [a_profData a_profNstData];
for idP = 1:length(profiles)
   
   profData = profiles(idP);
   
   % initialize a NetCDF profile structure and fill it with decoded profile data
   profStruct = get_profile_init_struct(a_cycleNum, -1, -1, -1);
   profStruct.sensorNumber = 0;
   
   % positioning system
   profStruct.posSystem = 'ARGOS';
   
   % add parameter variables to the profile structure
   profStruct.paramList = profData.paramList;
   profStruct.paramDataMode = profData.paramDataMode;
   
   % add parameter data to the profile structure
   profStruct.data = profData.data;
   profStruct.dataAdj = profData.dataAdj;
   
   % add press offset data to the profile structure
   idCycleStruct = find([a_presOffsetData.cycleNumAdjPres] == a_cycleNum);
   if (~isempty(idCycleStruct))
      profStruct.presOffset = a_presOffsetData.presOffset(idCycleStruct);
   end
   
   % update the profile completed flag
   if (~isempty(profData.expectedProfileLength))
      profStruct.profileCompleted = profData.expectedProfileLength - size(profStruct.data, 1);
   end
   
   % add configuration mission number
   configMissionNumber = get_config_mission_number_argos( ...
      a_cycleNum, a_timeData, a_decoderId);
   if (~isempty(configMissionNumber))
      profStruct.configMissionNumber = configMissionNumber;
   end
   
   % add vertical sampling scheme
   if (idP == 1)
      description = create_vertical_sampling_scheme_description_apx_argos(a_decoderId);
      profStruct.vertSamplingScheme = sprintf('Primary sampling: discrete [%s]', description);
      profStruct.primarySamplingProfileFlag = 1;
   else
      profStruct.vertSamplingScheme = 'Near-surface sampling: discrete, unpumped []';
      profStruct.primarySamplingProfileFlag = 0;
   end
   
   % add profile date and location information
   [profStruct] = add_profile_date_and_location_apx_argos( ...
      profStruct, a_floatSurfData, a_cycleNum);

   o_ncProfile = [o_ncProfile profStruct];
   
end

% set profiles with 'BLUE_REF' and 'NTU_REF' parameter to AUX files
if (ismember(a_decoderId, [1014]))
   
   addProfiles = [];
   for idP = 1:length(o_ncProfile)
      
      profStruct = o_ncProfile(idP);
      
      if (any(ismember('BLUE_REF', {profStruct.paramList.name})))
         
         idPres = find(strcmp({profStruct.paramList.name}, 'PRES') == 1, 1);
         idBlueRef = find(strcmp({profStruct.paramList.name}, 'BLUE_REF') == 1, 1);
         idNtuRef = find(strcmp({profStruct.paramList.name}, 'NTU_REF') == 1, 1);
         
         % create a new profile
         newProf = profStruct;
         newProf.sensorNumber = newProf.sensorNumber + 1000; % so that it will be stored in PROF_AUX file
         
         newProf.paramList = profStruct.paramList([idPres idBlueRef idNtuRef]);
         if (~isempty(profStruct.paramDataMode))
            newProf.paramDataMode = profStruct.paramDataMode([idPres idBlueRef idNtuRef]);
         end
         
         newProf.data = profStruct.data(:, [idPres idBlueRef idNtuRef]);
         if (~isempty(profStruct.dataAdj))
            newProf.dataAdj = profStruct.dataAdj(:, [idPres idBlueRef idNtuRef]);
         end
         
         % clean the current profile
         profStruct.paramList([idBlueRef idNtuRef]) = [];
         if (~isempty(profStruct.paramDataMode))
            profStruct.paramDataMode([idBlueRef idNtuRef]) = [];
         end
         
         profStruct.data(:, [idBlueRef idNtuRef]) = [];
         if (~isempty(profStruct.dataAdj))
            profStruct.dataAdj(:, [idBlueRef idNtuRef]) = [];
         end
         
         o_ncProfile(idP) = profStruct;
         addProfiles = [addProfiles newProf];
      end
   end
   
   o_ncProfile = [o_ncProfile addProfiles];
end

return
