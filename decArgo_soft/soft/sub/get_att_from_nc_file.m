% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVarAtts  : NetCDF variable names and attribute names to retrieve
%                      from the file
%
% OUTPUT PARAMETERS :
%   o_ncDataAtt : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)

% output parameters initialization
o_ncDataAtt = [];


if (exist(a_ncPathFileName, 'file') == 2)

   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end

   try

      % retrieve attributes from NetCDF file
      for idVar = 1:2:length(a_wantedVarAtts)
         varName = a_wantedVarAtts{idVar};
         attName = a_wantedVarAtts{idVar+1};

         if (var_is_present_dec_argo(fCdf, varName) && att_is_present_dec_argo(fCdf, varName, attName))
            attValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName);
            o_ncDataAtt = [o_ncDataAtt {varName} {attName} {attValue}];
         else
            o_ncDataAtt = [o_ncDataAtt {varName} {attName} {''}];
         end

      end

      netcdf.close(fCdf);

   catch MException
      netcdf.close(fCdf);
      rethrow(MException)
   end
end

return
