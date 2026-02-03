% ------------------------------------------------------------------------------
% Extension of the get_netcdf_param_attributes function to manage parameter
% names still like <PARAM>N (instead of <PARAM>_N) for the S-PROF generator tool
% (nc_create_synthetic_profile) where parameter names may come from other DACs.
%
% SYNTAX :
%  [o_attributeStruct] = get_netcdf_param_attributes_extended(a_paramName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_paramName : parameter name
%   a_floatNum  : float WMO number
%
% OUTPUT PARAMETERS :
%   o_attributeStruct : parameter associated attributes
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/03/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_attributeStruct] = get_netcdf_param_attributes_extended(a_paramName, a_floatNum)

% output parameters initialization
o_attributeStruct = [];

% print error if the parameter is not managed
global g_cocs_printErrorMsg;
g_cocs_printErrorMsg = 0;


paramAttStruct = get_netcdf_param_attributes(a_paramName);

% nominal case
if (~isempty(paramAttStruct))
   o_attributeStruct = paramAttStruct;
   return
end

% manage names like <PARAM>N
if (isletter(a_paramName(end-1)) && ~isletter(a_paramName(end)))

   paramName = a_paramName(1:end-1);
   paramAttStruct = get_netcdf_param_attributes(paramName);

   if (~isempty(paramAttStruct))
      o_attributeStruct = paramAttStruct;
      o_attributeStruct.name = a_paramName;
      return
   end
end

% manage names like <PARAM>2_STD or <PARAM>2_MED
if ((length(a_paramName) > 4) && ...
      (strcmp(a_paramName(end-3:end), '_STD') || strcmp(a_paramName(end-3:end), '_MED')))

   if (isletter(a_paramName(end-5)) && ~isletter(a_paramName(end-4)))

      paramName = a_paramName;
      paramName(end-4) = '';
      paramAttStruct = get_netcdf_param_attributes(paramName);

      if (~isempty(paramAttStruct))
         o_attributeStruct = paramAttStruct;
         o_attributeStruct.name = a_paramName;
         return
      end
   end
end

fprintf('ERROR: Float #%d: Attribute list no yet defined for parameter %s\n', ...
   a_floatNum, a_paramName);

return
