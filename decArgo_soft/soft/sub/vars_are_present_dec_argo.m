% ------------------------------------------------------------------------------
% Check if a given list of variables are present in a NetCDF file.
%
% SYNTAX :
%  [o_varFlagList] = vars_are_present_dec_argo(a_ncId, a_varNameList)
%
% INPUT PARAMETERS :
%   a_ncId        : NetCDF file Id
%   a_varNameList : list of variable names
%
% OUTPUT PARAMETERS :
%   o_varFlagList : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/06/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varFlagList] = vars_are_present_dec_argo(a_ncId, a_varNameList)

o_varFlagList = ones(size(a_varNameList));

[~, nbVars, ~, ~] = netcdf.inq(a_ncId);

valList = cell(nbVars, 1);
for idVar = 0:nbVars-1
   [valList{idVar+1}, ~, ~, ~] = netcdf.inqVar(a_ncId, idVar);
end

notPresentList = setdiff(a_varNameList, valList);
for idVar = 1:length(notPresentList)
   o_varFlagList(strcmp(notPresentList{idVar}, a_varNameList)) = 0;
end

return
