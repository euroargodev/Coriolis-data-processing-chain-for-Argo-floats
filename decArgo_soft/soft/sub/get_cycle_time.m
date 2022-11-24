% ------------------------------------------------------------------------------
% Get the duration of a given cycle according to float decoder Id.
%
% SYNTAX :
%  [o_cycleDuration] = get_cycle_time(a_decoderId, a_cycleNumber)
%
% INPUT PARAMETERS :
%   a_decoderId   : float decoder Id
%   a_cycleNumber : concerned cycle number
%
% OUTPUT PARAMETERS :
%   o_cycleDuration : duration of the cycle (in days)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/28/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleDuration] = get_cycle_time(a_decoderId, a_cycleNumber)

% output parameters initialization
o_cycleDuration = [];


switch (a_decoderId)
   
   case {2001, 2002, 2003} % Nova, Dova
      
      [configNames, configValues] = get_float_config_ir_sbd(a_cycleNumber);
      o_cycleDuration = get_config_value('CONFIG_PM00', configNames, configValues);

   otherwise
      fprintf('WARNING: No cycle time information for decoderId #%d\n', a_decoderId);
      
end

return;
