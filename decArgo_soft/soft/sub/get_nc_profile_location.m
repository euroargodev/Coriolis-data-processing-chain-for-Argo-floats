% ------------------------------------------------------------------------------
% Retrieve information on profile location of a nc mono-profile file.
%
% SYNTAX :
%  [o_juldLoc, o_lat, o_lon, o_posQc, o_posSystem] = get_nc_profile_location(a_ncPathFileName)
% 
% INPUT PARAMETERS :
%   a_ncPathFileName : nc mono-profile file path name
%   a_profPos        : position of the profile in the file
% 
% OUTPUT PARAMETERS :
%   o_juldLoc   : positions JulD
%   o_lat       : positions latitudes
%   o_lon       : positions logitudes
%   o_posQc     : positions QC
%   o_posSystem : positions positioning systems
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/07/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_juldLoc, o_lat, o_lon, o_posQc, o_posSystem] = get_nc_profile_location(a_ncPathFileName)

% output parameters initialization
o_juldLoc = [];
o_lat = [];
o_lon = [];
o_posQc = [];
o_posSystem = [];


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
   o_juldLoc = profData{idVal+1};
   idVal = find(strcmp('LATITUDE', profData) == 1);
   o_lat = profData{idVal+1};
   idVal = find(strcmp('LONGITUDE', profData) == 1);
   o_lon = profData{idVal+1};
   idVal = find(strcmp('POSITION_QC', profData) == 1);
   o_posQc = profData{idVal+1};
   idVal = find(strcmp('POSITIONING_SYSTEM', profData) == 1);
   posSystem = profData{idVal+1};
   o_posSystem = [];
   for idPs = 1:size(posSystem, 2)
      o_posSystem{end+1} = strtrim(posSystem(:, idPs)');
   end
end

return
