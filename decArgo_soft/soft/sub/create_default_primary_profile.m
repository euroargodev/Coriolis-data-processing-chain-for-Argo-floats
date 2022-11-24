% ------------------------------------------------------------------------------
% Create a default primary profile.
%
% SYNTAX :
%  [o_defaultPrimaryProf] = create_default_primary_profile( ...
%    a_cycleNum, a_direction, a_tabProfiles, a_decoderId)
%
% INPUT PARAMETERS :
%   a_cycleNum    : output cycle number
%   a_direction   : profile direction
%   a_tabProfiles : decoded profiles
%   a_decoderId   : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_defaultPrimaryProf : default primary profile
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/24/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_defaultPrimaryProf] = create_default_primary_profile( ...
   a_cycleNum, a_direction, a_tabProfiles, a_decoderId)

% output parameter initialization
o_defaultPrimaryProf = [];


% collect information on profiles
profInfo = [];
profVss = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag]];
   profVss{end+1} = profile.vertSamplingScheme;
end

% look for the near-surface profile (unpumped part of the primary profile)
idProfInFile = find( ...
   (profInfo(:, 1) == a_cycleNum) & ...
   (profInfo(:, 2) == a_direction));
idSecondary = find(profInfo(idProfInFile, 3) == 2);
if (~isempty(idSecondary))
   
   % 6901473 #127 anomaly
   if (length(idSecondary) > 1)
      idSecondary = idSecondary(1);
   end
   
   secondaryProf = a_tabProfiles(idProfInFile(idSecondary));
   
   [o_defaultPrimaryProf] = get_profile_init_struct( ...
      secondaryProf.cycleNumber, secondaryProf.profileNumber, secondaryProf.phaseNumber, 1);
   
   o_defaultPrimaryProf.outputCycleNumber = secondaryProf.outputCycleNumber;
   o_defaultPrimaryProf.direction = secondaryProf.direction;
   o_defaultPrimaryProf.date = secondaryProf.date;
   o_defaultPrimaryProf.dateQc = secondaryProf.dateQc;
   o_defaultPrimaryProf.locationDate = secondaryProf.locationDate;
   o_defaultPrimaryProf.locationLon = secondaryProf.locationLon;
   o_defaultPrimaryProf.locationLat = secondaryProf.locationLat;
   o_defaultPrimaryProf.locationQc = secondaryProf.locationQc;
   o_defaultPrimaryProf.posSystem = secondaryProf.posSystem;
   o_defaultPrimaryProf.vertSamplingScheme = 'Primary sampling: averaged []';
   o_defaultPrimaryProf.paramList = secondaryProf.paramList;
   o_defaultPrimaryProf.data = [];
   o_defaultPrimaryProf.dataQc = [];
   o_defaultPrimaryProf.configMissionNumber = secondaryProf.configMissionNumber;
   o_defaultPrimaryProf.sensorNumber = secondaryProf.sensorNumber;
   o_defaultPrimaryProf.updated = 0;
   o_defaultPrimaryProf.fakeProfFlag = 1;
   
else
   
   [o_defaultPrimaryProf] = get_profile_init_struct( ...
      -1, -1, -1, 1);
   
   o_defaultPrimaryProf.outputCycleNumber = a_cycleNum;
   direction = 'A';
   if (a_direction == 1)
      direction = 'D';
   end
   o_defaultPrimaryProf.direction = direction;
   o_defaultPrimaryProf.posSystem = get_positioning_system(a_decoderId);
   o_defaultPrimaryProf.vertSamplingScheme = 'Primary sampling: averaged []';
   o_defaultPrimaryProf.paramList = create_primary_parameter_list(a_decoderId);
   o_defaultPrimaryProf.data = [];
   o_defaultPrimaryProf.dataQc = [];
   o_defaultPrimaryProf.sensorNumber = 0;
   o_defaultPrimaryProf.updated = 0;
   o_defaultPrimaryProf.fakeProfFlag = 1;
   
end

return

% ------------------------------------------------------------------------------
% Create the list of primary parameters.
%
% SYNTAX :
%  [o_paramList] = create_primary_parameter_list(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_paramList : primary parameter list
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/24/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramList] = create_primary_parameter_list(a_decoderId)

% output parameters initialization
o_paramList = [];


% retrieve the list of primary parameters for the concerned decoder Id
[parameterList] = get_primary_parameter_list(a_decoderId);

for idP = 1:length(parameterList)
   o_paramList = [o_paramList get_netcdf_param_attributes(parameterList{idP})];
end

return
