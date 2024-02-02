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
[bFileInfo] = create_nc_mono_prof_b_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, cFileInfo);

% the C-PROF file of each new or updated B-PROF file should be also created or updated
cFileToCreate = [];
if (~isempty(cFileInfo) && ~isempty(bFileInfo))
   cFileInfoNum = cFileInfo(:, 1)*10 + cFileInfo(:, 2);
   bFileInfoNum = bFileInfo(:, 1)*10 + bFileInfo(:, 2);
   [~, id] = setdiff(bFileInfoNum, cFileInfoNum);
   if (~isempty(id))
      cFileToCreate = bFileInfo(id, :);
   end
elseif (~isempty(bFileInfo))
   cFileToCreate = bFileInfo;
end
if (~isempty(cFileToCreate))
   create_nc_mono_prof_c_files_3_1(a_decoderId, a_tabProfiles, a_metaDataFromJson, cFileToCreate);
end

fprintf('... NetCDF MONO-PROFILE files created\n');

return
