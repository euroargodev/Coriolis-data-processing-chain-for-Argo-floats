% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE c and b files.
%
% SYNTAX :
%  create_nc_mono_prof_files_3_1( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_mono_prof_files_3_1( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson)

% create the c files
create_nc_mono_prof_c_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson);

% create the b files
create_nc_mono_prof_b_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson);

fprintf('... NetCDF MONO-PROFILE files created\n');

return;
