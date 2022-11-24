% ------------------------------------------------------------------------------
% Check if a given attribute of a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = att_is_present_dec_argo(a_ncId, a_varName, a_attName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%   a_attName : attribute name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the attribute is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/05/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = att_is_present_dec_argo(a_ncId, a_varName, a_attName)

o_present = 0;

if (var_is_present_dec_argo(a_ncId, a_varName))
   
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, netcdf.inqVarID(a_ncId, a_varName));
   
   for idAtt = 0:nbAtts-1
      attName = netcdf.inqAttName(a_ncId, netcdf.inqVarID(a_ncId, a_varName), idAtt);
      if (strcmp(attName, a_attName))
         o_present = 1;
         break;
      end
   end
   
end

return;
