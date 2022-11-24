% ------------------------------------------------------------------------------
% Create the final configuration that will be used in the meta.nc file.
%
% SYNTAX :
%  [o_ncConfig] = create_output_float_config_ir_rudics_cts4( ...
%    a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)
%
% INPUT PARAMETERS :
%   a_decArgoConfParamNames : internal configuration parameter names
%   a_ncConfParamNames      : NetCDF configuration parameter names
%   a_decoderId     : float decoder Id
%
% OUTPUT PARAMETERS :
% o_ncConfig : NetCDF configuration
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncConfig] = create_output_float_config_ir_rudics_cts4( ...
   a_decArgoConfParamNames, a_ncConfParamNames, a_decoderId)

% output parameters initialization
o_ncConfig = [];

% current float WMO number
global g_decArgo_floatNum;


switch (a_decoderId)
   
   case {105, 106, 107, 109, 110, 112}
      
      [o_ncConfig] = create_output_float_config_ir_rudics_cts4_105_to_110_112(a_decArgoConfParamNames, a_ncConfParamNames);

   case {111, 113, 114}
      
      [o_ncConfig] = create_output_float_config_ir_rudics_cts4_111_113_114(a_decArgoConfParamNames, a_ncConfParamNames);
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in create_output_float_config_ir_rudics_cts4 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return
