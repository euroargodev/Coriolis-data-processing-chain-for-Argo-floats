% ------------------------------------------------------------------------------
% Retrieve index(es) of a parameter data in the profile structure.
%
% SYNTAX :
%  [o_idParam, o_firstCol, o_lastCol] = get_param_data_index(a_profile, a_paramName)
%
% INPUT PARAMETERS :
%   a_profile   : profile structure
%   a_paramName : parameter name
%
% OUTPUT PARAMETERS :
%   o_idParam  : index of the parameter in the profile structure
%   o_firstCol : first index of parameter data in the profile structure
%   o_lastCol  : last index of parameter data in the profile structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/02/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_idParam, o_firstCol, o_lastCol] = get_param_data_index(a_profile, a_paramName)

% output parameters initialization
o_idParam = '';
o_firstCol = '';
o_lastCol = '';


% get param index
o_idParam = find(strcmp({a_profile.paramList.name}, a_paramName));
if (isempty(o_idParam))
   return
end

% retrieve the column(s) associated with the parameter data
if (isempty(a_profile.paramNumberWithSubLevels))
   o_firstCol = o_idParam;
   o_lastCol = o_idParam;
else
   idF = find(a_profile.paramNumberWithSubLevels < o_idParam);
   if (isempty(idF))
      o_firstCol = o_idParam;
   else
      o_firstCol = o_idParam + sum(a_profile.paramNumberOfSubLevels(idF)) - length(idF);
   end
   
   idF = find(a_profile.paramNumberWithSubLevels == o_idParam);
   if (isempty(idF))
      o_lastCol = o_firstCol;
   else
      o_lastCol = o_firstCol + a_profile.paramNumberOfSubLevels(idF) - 1;
   end
end

return
