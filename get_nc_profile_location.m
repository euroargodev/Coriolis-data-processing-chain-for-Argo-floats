% ------------------------------------------------------------------------------
% Retrieve information on profile location of a nc mono-profile file.
%
% SYNTAX :
%  [o_ncProfLoc] = get_nc_profile_location(a_ncPathFileName)
% 
% INPUT PARAMETERS :
%   a_ncPathFileName : nc mono-profile file path name
% 
% OUTPUT PARAMETERS :
%   o_ncProfLoc : information on profile location
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/07/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfLoc] = get_nc_profile_location(a_ncPathFileName)

% output parameters initialization
o_ncProfLoc = [];


if (exist(a_ncPathFileName, 'file') == 2)
   % retrieve information from existing file
   wantedProfVars = [ ...
      {'JULD_LOCATION'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_QC'} ...
      {'POSITIONING_SYSTEM'} ...
      ];
            
   % retrieve information from PROF netCDF file
   [profData] = get_data_from_nc_file(a_ncPathFileName, wantedProfVars);
            
   idVal = find(strcmp('JULD_LOCATION', profData) == 1);
   juldLocation = profData{idVal+1};
   juldLocation = unique(juldLocation);
   idVal = find(strcmp('LATITUDE', profData) == 1);
   latitude = profData{idVal+1};
   latitude = unique(latitude);
   idVal = find(strcmp('LONGITUDE', profData) == 1);
   longitude = profData{idVal+1};
   longitude = unique(longitude);
   idVal = find(strcmp('POSITION_QC', profData) == 1);
   positionQc = profData{idVal+1};
   positionQc = unique(positionQc);
   idVal = find(strcmp('POSITIONING_SYSTEM', profData) == 1);
   positioningSystem = profData{idVal+1}';
   positioningSystem = strtrim(unique(positioningSystem)');

   o_ncProfLoc = sprintf('%s %.3f %.3f %c %s', ...
   julian_2_gregorian_dec_argo(juldLocation), ...
   latitude, longitude, positionQc, positioningSystem);
end

return
