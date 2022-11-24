% ------------------------------------------------------------------------------
% Retrieve information on profile location of a nc mono-profile file.
%
% SYNTAX :
%  [o_ncProfLocStr, o_ncProfQc] = get_nc_profile_location(a_ncPathFileName)
% 
% INPUT PARAMETERS :
%   a_ncPathFileName : nc mono-profile file path name
% 
% OUTPUT PARAMETERS :
%   o_ncProfLocStr : information on profile location
%   o_ncProfQc     : position QC of profile location
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/07/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfLocStr, o_ncProfQc] = get_nc_profile_location(a_ncPathFileName)

% output parameters initialization
o_ncProfLocStr = [];
o_ncProfQc = [];


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
   posSystem = profData{idVal+1};
   for idPs = 1:size(posSystem, 2)
      positioningSystem = strtrim(posSystem(:, idPs)');
      if (~isempty(positioningSystem))
         break
      end
   end

   o_ncProfLocStr = sprintf('%s %.3f %.3f %s', ...
   julian_2_gregorian_dec_argo(juldLocation), ...
   latitude, longitude, positioningSystem);
   o_ncProfQc = positionQc;
end

return
