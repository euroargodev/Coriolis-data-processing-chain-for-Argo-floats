% ------------------------------------------------------------------------------
% Check if a given dimension is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = dim_is_present_dec_argo(a_ncId, a_dimName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_dimName : dimension name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the dimension is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = dim_is_present_dec_argo(a_ncId, a_dimName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idDim = 0:nbDims-1
   [dimName, dimLen] = netcdf.inqDim(a_ncId, idDim);
   if (strcmp(dimName, a_dimName))
      o_present = 1;
      break;
   end
end

return;
