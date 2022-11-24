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
[cFileInfo] = create_nc_mono_prof_c_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, []);

% create the b files
[bParamFlag] = create_nc_mono_prof_b_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, cFileInfo);

% check that no B-PROF files have been generated without their associated C-PROF
% files
% note that this should not theoretically happen (because PRES is present in
% all profiles), however this happended when the FillValue of a parameter is
% modified (the B-PROF file may need to be generated but not the C-PROF file).
if (bParamFlag == 1)
   [cFileToCreate] = get_missing_c_prof_files;

   if (~isempty(cFileToCreate))
      create_nc_mono_prof_c_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, cFileToCreate);
   end
end

fprintf('... NetCDF MONO-PROFILE files created\n');

return
