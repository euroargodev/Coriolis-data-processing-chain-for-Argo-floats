   % ------------------------------------------------------------------------------
% Retrieve the list of configuration parameters we want to see (even if not
% modified) for a given decoder.
%
% SYNTAX :
%  [o_configParamName] = get_config_param_mandatory(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_configParamName : configuration parameter list
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configParamName] = get_config_param_mandatory(a_decoderId)

% output parameter initialization
o_configParamName = [];

% current float WMO number
global g_decArgo_floatNum;

switch (a_decoderId)
   
   case {1, 3, 4, 11, 12, 17, 19, 24, 25, 27, 28, 29, 30, 31}
      
      o_configParamName = [ ...
         {'CONFIG_CycleTime_days'}; ...
         {'CONFIG_ParkPressure_dbar'}; ...
         {'CONFIG_ProfilePressure_dbar'}; ...
         ];
            
   case {105, 106, 107, 108, 109, 301, 302, 303}
      
      o_configParamName = [ ...
         {'CONFIG_NumberOfSubCycles_NUMBER'}; ...
         {'CONFIG_CycleTime_hours'}; ...
         {'CONFIG_ParkPressure_dbar'}; ...
         {'CONFIG_ProfilePressure_dbar'}; ...
         {'CONFIG_TransmissionEndCycle_LOGICAL'}; ...
         ];
      
   case {201, 202, 203, 204, 205, 206, 207, 208, 209}
      
      o_configParamName = [ ...
         {'CONFIG_CycleTime_days'}; ...
         {'CONFIG_ParkPressure_dbar'}; ...
         {'CONFIG_ProfilePressure_dbar'}; ...
         ];
      
   case {1001, 1002, 1003, 1004, 1005, 1006}
      
      o_configParamName = [ ...
         {'CONFIG_CycleTime_hours'}; ...
         {'CONFIG_ParkPressure_dbar'}; ...
         {'CONFIG_ProfilePressure_dbar'}; ...
         ];
      
   otherwise
      fprintf('WARNING: Float #%d: No mandatory configuration parameter list defined yet for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

return;
