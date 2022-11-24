% ------------------------------------------------------------------------------
% Get Argo attributes for a given parameter.
%
% SYNTAX :
%  [o_attributeStruct] = get_netcdf_param_attributes(a_paramName)
%
% INPUT PARAMETERS :
%   a_paramName : parameter name
%
% OUTPUT PARAMETERS :
%   o_attributeStruct : parameter associated attributes
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/25/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_attributeStruct] = get_netcdf_param_attributes(a_paramName)

[o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);

% % Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
% global g_decArgo_floatTransType;
% 
% 
% if (g_decArgo_floatTransType == 1)
%    
%    % Argos floats
%    
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%    
% elseif (g_decArgo_floatTransType == 2)
%    
%    % Iridium RUDICS floats
%    
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%    
% elseif (g_decArgo_floatTransType == 3)
%    
%    % Iridium SBD floats
%    
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%    
% elseif (g_decArgo_floatTransType == 4)
%    
%    % Iridium SBD ProvBioII floats
%    
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
% 
% end

return
