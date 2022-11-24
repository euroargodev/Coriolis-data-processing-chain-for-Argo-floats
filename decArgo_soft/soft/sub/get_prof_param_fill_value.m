% ------------------------------------------------------------------------------
% Create the parameters FillValue list of a profile.
%
% SYNTAX :
%  [o_paramFillValueList] = get_prof_param_fill_value(a_profData)
%
% INPUT PARAMETERS :
%   a_profData : profile structure
%
% OUTPUT PARAMETERS :
%   o_paramFillValueList : parameters FillValue list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/23/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramFillValueList] = get_prof_param_fill_value(a_profData)

% output parameters initialization
o_paramFillValueList = [];

if (isempty(a_profData.paramNumberWithSubLevels))
   for idParam = 1:length(a_profData.paramList)
      paramInfo = get_netcdf_param_attributes(a_profData.paramList(idParam).name);
      o_paramFillValueList = [o_paramFillValueList double(paramInfo.fillValue)];
   end
else
   for idParam = 1:length(a_profData.paramList)
      paramInfo = get_netcdf_param_attributes(a_profData.paramList(idParam).name);
      if (any(a_profData.paramNumberWithSubLevels == idParam))
         idF = find(a_profData.paramNumberWithSubLevels == idParam);
         o_paramFillValueList = [o_paramFillValueList repmat(double(paramInfo.fillValue), 1, a_profData.paramNumberOfSubLevels(idF))];
      else
         o_paramFillValueList = [o_paramFillValueList double(paramInfo.fillValue)];
      end
   end
end

return
