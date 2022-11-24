% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = ...
%    create_config_param_names_ir_rudics_cts4(a_decoderId)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%    o_decArgoConfParamNames : internal configuration parameter names
%    o_ncConfParamNames      : NetCDF configuration parameter names
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decArgoConfParamNames, o_ncConfParamNames] = ...
   create_config_param_names_ir_rudics_cts4(a_decoderId)

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 112}
      
      [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_rudics_cts4_105_to_110_112;

   case {111, 113, 114}
      
      [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_rudics_cts4_111_113_114;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in create_config_param_names_ir_rudics_cts4 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
