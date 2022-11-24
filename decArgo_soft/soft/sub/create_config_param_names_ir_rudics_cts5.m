% ------------------------------------------------------------------------------
% Create configuration parameter lists of decoder names and NetCDF names.
%
% SYNTAX :
%  [o_decArgoConfParamNames, o_ncConfParamNames] = ...
%    create_config_param_names_ir_rudics_cts5(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
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
   create_config_param_names_ir_rudics_cts5(a_decoderId)

% output parameters initialization
o_decArgoConfParamNames = [];
o_ncConfParamNames = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {121, 122, 123}
      
      [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_rudics_cts5_121_to_123;

   case {124}
      
      [o_decArgoConfParamNames, o_ncConfParamNames] = create_config_param_names_ir_rudics_cts5_124;
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in create_config_param_names_ir_rudics_cts5 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
