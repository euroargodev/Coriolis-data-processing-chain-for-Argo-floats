% ------------------------------------------------------------------------------
% Retrieve dimension name and length that match a given pattern.
%
% SYNTAX :
%  [o_dimName, o_dimLength] = dim_is_present2_dec_argo(a_ncId, a_dimName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_dimName : dimension name pattern
%
% OUTPUT PARAMETERS :
%   o_dimName   : dimension name
%   o_dimLength : dimension length
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/25/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dimName, o_dimLength] = dim_is_present2_dec_argo(a_ncId, a_dimName)

o_dimName = [];
o_dimLength = [];

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idDim = 0:nbDims-1
   [dimName, dimLen] = netcdf.inqDim(a_ncId, idDim);
   if (strncmp(dimName, a_dimName, length(a_dimName)))
      o_dimName = [o_dimName {dimName}];
      o_dimLength = [o_dimLength dimLen];
   end
end

return
