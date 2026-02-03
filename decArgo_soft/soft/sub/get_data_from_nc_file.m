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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
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

   try

      % retrieve the list of variables that are present in the file
      varFlagList = vars_are_present_dec_argo(fCdf, a_wantedVars);

      % retrieve variables from NetCDF file
      for idVar = 1:length(a_wantedVars)
         if (varFlagList(idVar) == 1)
            varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, a_wantedVars{idVar}));
            o_ncData = [o_ncData {a_wantedVars{idVar}} {varValue}];
         else
            %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
            %             varName, a_ncPathFileName);
            o_ncData = [o_ncData {a_wantedVars{idVar}} {''}];
         end

      end

      netcdf.close(fCdf);

   catch MException
      netcdf.close(fCdf);
      rethrow(MException)
   end
end

return
