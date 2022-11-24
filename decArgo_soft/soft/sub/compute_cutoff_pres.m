% ------------------------------------------------------------------------------
% Compute cut-off pressure of the profile accoring to float version.
%
% SYNTAX :
%  [o_cutOffPres, o_stopCtdPump] = compute_cutoff_pres(a_decoderId)
%
% INPUT PARAMETERS :
%   a_decoderId : float decoder Id
%
% OUTPUT PARAMETERS :
%   o_cutOffPres  : profile cut-off pressure
%   o_stopCtdPump : CTD pump stop pressure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cutOffPres, o_stopCtdPump] = compute_cutoff_pres(a_decoderId)

% output parameters initialization
o_cutOffPres = [];
o_stopCtdPump = [];

% current float WMO number
global g_decArgo_floatNum;


% retrieve configuration information
if (ismember(a_decoderId, [30 32]))
   [configNames, configValues] = get_float_config_argos_1(0);
else
   [configNames, configValues] = get_float_config_argos_1(1);
end
if (~isempty(configNames))
   
   switch (a_decoderId)
      
      case {1, 11, 12, 4, 19, 3}
         
         % retrieve surface slice thickness
         if (a_decoderId ~= 3)
            thickSurf = get_config_value('CONFIG_PM12_', configNames, configValues);
         else
            thickSurf = get_config_value('CONFIG_PM11_', configNames, configValues);
         end
         
         if (~isempty(thickSurf))
            o_cutOffPres = 5 + thickSurf/2;
            o_stopCtdPump = 5;
         else
            fprintf('WARNING: Float #%d: Surface slice thickness configuration parameter is missing in the Json meta-data file\n', ...
               g_decArgo_floatNum);
         end
         
      case {24, 27, 25, 28, 29, 17, 30, 31, 32}
         
         % retrieve information from configuration
         if (ismember(a_decoderId, [27 28 29 31]))
            ctdPumpSwitchOffPres = get_config_value('CONFIG_PT20_', configNames, configValues);
            
            if (isempty(ctdPumpSwitchOffPres))
               ctdPumpSwitchOffPres = 5;
               fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file => using default value (%d dbars)\n', ...
                  g_decArgo_floatNum, ctdPumpSwitchOffPres);
            end
         elseif (ismember(a_decoderId, [30 32]))
            ctdPumpSwitchOffPres = get_config_value('CONFIG_TC18_', configNames, configValues);
            
            if (isempty(ctdPumpSwitchOffPres))
               ctdPumpSwitchOffPres = 5;
               fprintf('INFO: Float #%d: CTD switch off pressure parameter is missing in the Json meta-data file => using default value (%d dbars)\n', ...
                  g_decArgo_floatNum, ctdPumpSwitchOffPres);
            end
         else
            ctdPumpSwitchOffPres = 5;
         end
         
         o_cutOffPres = ctdPumpSwitchOffPres + 0.5;
         o_stopCtdPump = ctdPumpSwitchOffPres;
         
      otherwise
         fprintf('WARNING: Float #%d: No rules to compute cutoff pressure for decoderId #%d\n', ...
            g_decArgo_floatNum, ...
            a_decoderId);
   end
end

return
