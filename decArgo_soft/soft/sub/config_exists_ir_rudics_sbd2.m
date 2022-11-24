% ------------------------------------------------------------------------------
% Look for a configuration in the existing ones.
%
% SYNTAX :
%  [o_configNum] = config_exists_ir_rudics_sbd2( ...
%    a_newConfig, a_configNum, a_configVal, a_configIgnoreIds)
%
% INPUT PARAMETERS :
%   a_newConfig : the new configuration to check
%   a_configNum : existing configuration numbers
%   a_configVal : existing configuration values
%   a_configVal : existing configuration parameters that should be ignored in
%                 the configuration comparison
%
% OUTPUT PARAMETERS :
%   o_configNum : number of the configuration found (-1 if it does not exist)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configNum] = config_exists_ir_rudics_sbd2( ...
   a_newConfig, a_configNum, a_configVal, a_configIgnoreIds)

% output parameters initialization
o_configNum = -1;


% do not consider CONFIG_PM_3 to CONFIG_PM_52 to check if the new configuration
% already exists (because associated "final" configuration is stored in
% CONFIG_PM_03 to CONFIG_PM_07
a_newConfig(a_configIgnoreIds) = [];
a_configVal(a_configIgnoreIds, :) = [];
                  
% look for the new configuration in the existing ones
% we look for configuration from last to first because, if no configuration
% information has been received between launch date and first data processing
% date, the launch configuration(#0) has been duplicated (to configuration #1).
% In this case the current function should return #1 instead of #0.
for idC = size(a_configVal, 2):-1:1
   config = a_configVal(:, idC);
   if (isempty(find(isnan(config) ~= isnan(a_newConfig), 1)))
      idVal = ~isnan(config);
      if (isempty(find(config(idVal) ~= a_newConfig(idVal), 1)))
         o_configNum = a_configNum(idC);
         break;
      end
   end
end

return;
