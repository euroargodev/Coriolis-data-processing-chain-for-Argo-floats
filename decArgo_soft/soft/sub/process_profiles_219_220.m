% ------------------------------------------------------------------------------
% Create the profiles of decoded data.
%
% SYNTAX :
%  [o_tabProfiles] = process_profiles_219_220( ...
%    a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
%    a_gpsData, a_iridiumMailData, ...
%    a_ascentEndDate, a_transStartDate, a_tabTech)
%
% INPUT PARAMETERS :
%   a_ascProfPres            : ascending profile PRES
%   a_ascProfTemp            : ascending profile TEMP
%   a_ascProfSal             : ascending profile PSAL
%   a_gpsData                : GPS data
%   a_iridiumMailData        : Iridium mail contents
%   a_ascentEndDate          : ascent end date
%   a_transStartDate         : transmission start date
%   a_tabTech                : technical data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles] = process_profiles_219_220( ...
   a_ascProfPres, a_ascProfTemp, a_ascProfSal, ...
   a_gpsData, a_iridiumMailData, ...
   a_ascentEndDate, a_transStartDate, a_tabTech)

% output parameters initialization
o_tabProfiles = [];

% array ro store statistics on received packets
global g_decArgo_nbAscentPacketsReceived;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;


if (isempty(a_ascProfPres))
   return
end

% create the profile structure
profStruct = get_profile_init_struct(g_decArgo_cycleNum, -1, -1, 1);
profStruct.sensorNumber = 0;

% profile direction
profStruct.direction = 'A';

% positioning system
profStruct.posSystem = 'GPS';

% create the parameters
paramPres = get_netcdf_param_attributes('PRES');
paramTemp = get_netcdf_param_attributes('TEMP');
paramSal = get_netcdf_param_attributes('PSAL');

% convert decoder default values to netCDF fill values
a_ascProfPres(find(a_ascProfPres == g_decArgo_presDef)) = paramPres.fillValue;
a_ascProfTemp(find(a_ascProfTemp == g_decArgo_tempDef)) = paramTemp.fillValue;
a_ascProfSal(find(a_ascProfSal == g_decArgo_salDef)) = paramSal.fillValue;

% add parameter variables to the profile structure
profStruct.paramList = [paramPres paramTemp paramSal];

% add parameter data to the profile structure
profStruct.data = [a_ascProfPres a_ascProfTemp a_ascProfSal];

% update the profile completed flag
if (~isempty(a_tabTech))
   idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 1));
   if (~isempty(idF))
      % number of expected profile packets for the ascending profile
      nbPacketExpected = a_tabTech(idF, 23);
      profStruct.profileCompleted = nbPacketExpected - g_decArgo_nbAscentPacketsReceived;
   end
end

% add profile date and location information
[profStruct] = add_profile_date_and_location_201_to_224_2001_to_2003( ...
   profStruct, a_gpsData, a_iridiumMailData, ...
   '', a_ascentEndDate, a_transStartDate);

% add configuration mission number
profStruct.configMissionNumber = 1;

% add vertical sampling scheme
profStruct.vertSamplingScheme = 'Primary sampling: averaged []';

o_tabProfiles = profStruct;

return
