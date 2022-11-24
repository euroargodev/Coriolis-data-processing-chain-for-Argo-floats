% ------------------------------------------------------------------------------
% Check if a given global attribute is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = global_att_is_present_dec_argo(a_ncId, a_globalAttName)
%
% INPUT PARAMETERS :
%   a_ncId          : NetCDF file Id
%   a_globalAttName : global attribut name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the global attribut is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = global_att_is_present_dec_argo(a_ncId, a_globalAttName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idGAtt = 0:nbGAtts-1
   attName = netcdf.inqAttName(a_ncId, netcdf.getConstant('NC_GLOBAL'), idGAtt);
   if (strcmp(attName, a_globalAttName))
      o_present = 1;
      break;
   end
end

return;
