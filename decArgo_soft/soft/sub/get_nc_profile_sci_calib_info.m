% ------------------------------------------------------------------------------
% Retrieve RT adjustment information.
%
% SYNTAX :
%  o_sciCalibInfo = get_nc_profile_sci_calib_info(a_ncPathFileName)
% 
% INPUT PARAMETERS :
%   a_ncPathFileName : nc mono-profile file path name
% 
% OUTPUT PARAMETERS :
%   o_sciCalibInfo : RT adjustment information
% 
% EXAMPLES :
% 
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/10/2023 - RNU - creation
% ------------------------------------------------------------------------------
function o_sciCalibInfo = get_nc_profile_sci_calib_info(a_ncPathFileName)

% output parameters initialization
o_sciCalibInfo = [];


if (exist(a_ncPathFileName, 'file') == 2)
   % retrieve information from existing file
   wantedVars = [ ...
      {'PARAMETER'} ...
      {'SCIENTIFIC_CALIB_EQUATION'} ...
      {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
      {'SCIENTIFIC_CALIB_COMMENT'} ...
      {'SCIENTIFIC_CALIB_DATE'} ...
      ];
            
   % retrieve information from PROF netCDF file
   [ncData] = get_data_from_nc_file(a_ncPathFileName, wantedVars);
            
   idVal = find(strcmp('PARAMETER', ncData));
   parameter = ncData{idVal+1};
   idVal = find(strcmp('SCIENTIFIC_CALIB_EQUATION', ncData));
   sciCalibEq = ncData{idVal+1};
   idVal = find(strcmp('SCIENTIFIC_CALIB_COEFFICIENT', ncData));
   sciCalibCoef = ncData{idVal+1};
   idVal = find(strcmp('SCIENTIFIC_CALIB_COMMENT', ncData));
   sciCalibComment = ncData{idVal+1};
   idVal = find(strcmp('SCIENTIFIC_CALIB_DATE', ncData));
   sciCalibDate = ncData{idVal+1};

   [~, nParam, nCalib, nProf] = size(parameter);
   o_sciCalibInfo = cell(10, 8);
   cpt = 1;
   for idProf = 1:nProf
      for idCalib = 1:nCalib
         for idParam = 1:nParam
            o_sciCalibInfo{cpt, 1} = idProf;
            o_sciCalibInfo{cpt, 2} = idCalib;
            o_sciCalibInfo{cpt, 3} = idParam;
            o_sciCalibInfo{cpt, 4} = deblank(parameter(:, idParam, idCalib, idProf)');
            o_sciCalibInfo{cpt, 5} =  deblank(sciCalibEq(:, idParam, idCalib, idProf)');
            o_sciCalibInfo{cpt, 6} =  deblank(sciCalibCoef(:, idParam, idCalib, idProf)');
            o_sciCalibInfo{cpt, 7} =  deblank(sciCalibComment(:, idParam, idCalib, idProf)');
            o_sciCalibInfo{cpt, 8} =  deblank(sciCalibDate(:, idParam, idCalib, idProf)');
            cpt = cpt + 1;
            if (cpt > size(o_sciCalibInfo, 1))
               o_sciCalibInfo = cat(1, o_sciCalibInfo, cell(10, 8));
            end
         end
      end
   end
   o_sciCalibInfo(cpt:end, :) = [];
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
