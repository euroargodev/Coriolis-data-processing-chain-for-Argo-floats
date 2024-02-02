% ------------------------------------------------------------------------------
% Retrieve the number of levels of each profile of a nc mono-profile file.
%
% SYNTAX :
%  [o_ncProfLev] = get_nc_profile_level(a_ncPathFileName)
% 
% INPUT PARAMETERS :
%   a_ncPathFileName : nc mono-profile file path name
% 
% OUTPUT PARAMETERS :
%   o_ncProfLev : number of levels of each profile
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/14/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfLev] = get_nc_profile_level(a_ncPathFileName)

% output parameters initialization
o_ncProfLev = [];


if (exist(a_ncPathFileName, 'file') == 2)
   % retrieve information from existing file
   wantedProfVars = [ ...
      {'STATION_PARAMETERS'} ...
      ];
            
   % retrieve information from PROF netCDF file
   [profData] = get_data_from_nc_file(a_ncPathFileName, wantedProfVars);
            
   idVal = find(strcmp('STATION_PARAMETERS', profData) == 1);
   ncStationParameters = profData{idVal+1};
   
   [~, nParam, nProf] = size(ncStationParameters);
   paramForProf = [];
   for idProf = 1:nProf
      for idParam = 1:nParam
         paramForProf{idProf, idParam} = deblank(ncStationParameters(:, idParam, idProf)');
      end
   end
   paramList = unique(paramForProf);

   % retrieve information from existing file
   wantedProfVars = [];
   for idParam = 1:length(paramList)
      if (~isempty(paramList{idParam}))
         wantedProfVars = [ wantedProfVars ...
            {paramList{idParam}} {[paramList{idParam} '_ADJUSTED']} ...
            ];
      end
   end
               
   % retrieve information from PROF netCDF file
   [profData] = get_data_from_nc_file(a_ncPathFileName, wantedProfVars);

   % compute profile levels
   ncProfLevData = [];
   ncProfLevDataAdj = [];
   for idProf = 1:nProf
      for idLoop = 1:2
         nLevelsParam = 0;
         idNoDefAll = [];
         for idParam = 1:nParam
            paramName = paramForProf{idProf, idParam};
            if (~isempty(paramName))
               paramInfo = get_netcdf_param_attributes(paramName);
               if (idLoop == 1)
                  idVal = find(strcmp(paramName, profData) == 1);
               else
                  idVal = find(strcmp([paramName '_ADJUSTED'], profData) == 1);
               end
               ncData = profData{idVal+1};
               ncData = permute(ncData, ndims(ncData):-1:1);
               if (~isempty(ncData))
                  if (ndims(ncData) == 2)
                     idNoDef = find(ncData(idProf, :) ~= paramInfo.fillValue);
                     idNoDefAll = [idNoDefAll idNoDef];
                  elseif (ndims(ncData) == 3)
                     idNoDef = [];
                     for id = 1:size(ncData, 2)
                        if ~((length(unique(ncData(idProf, id, :))) == 1) && (unique(ncData(idProf, id, :)) == paramInfo.fillValue))
                           idNoDef = [idNoDef id];
                        end
                     end
                     idNoDefAll = [idNoDefAll idNoDef];
                  end
               end
            end
         end
         if (~isempty(idNoDefAll))
            nLevelsParam = max(idNoDefAll) - min(idNoDefAll) + 1;
         end
         if (idLoop == 1)
            ncProfLevData = [ncProfLevData nLevelsParam];
         else
            ncProfLevDataAdj = [ncProfLevDataAdj nLevelsParam];
         end
      end
   end
   if (isempty(ncProfLevDataAdj))
      ncProfLevDataAdj = zeros(size(ncProfLevData));
   end
   o_ncProfLev = [ncProfLevData; ncProfLevDataAdj];
end

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return
