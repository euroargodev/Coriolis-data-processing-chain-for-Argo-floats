% ------------------------------------------------------------------------------
% Get buoyancy information from Apex APF11 events.
%
% SYNTAX :
%  [o_buoyancy] = process_apx_apf11_ir_buoyancy_evts_1124_25(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_buoyancy : buoyancy data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/24/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_buoyancy] = process_apx_apf11_ir_buoyancy_evts_1124_25(a_events)

% output parameters initialization
o_buoyancy = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


% buoyancy events
idEvts = find(strcmp({a_events.functionName}, 'BuoyEngine'));
events = a_events(idEvts);

PATTERN = 'adjusting from';
for idEv = 1:length(events)
   dataStr = events(idEv).message;
   if (any(strfind(dataStr, PATTERN)))
      buoy = textscan(dataStr, '%s', 'delimiter', ' ');
      buoy = buoy{:};
      if (size(buoy, 1) == 5)
         if (strcmp(buoy{1}, 'adjusting') && strcmp(buoy{2}, 'from') && strcmp(buoy{4}, 'to'))
            pistonStart = str2double(buoy{3});
            pistonStop = str2double(buoy{5});
            if (pistonStop - pistonStart > 0)
               pumpFlag = 1;
            else
               pumpFlag = 0;
            end
            o_buoyancy = [o_buoyancy; [events(idEv).timestamp g_decArgo_dateDef g_decArgo_presDef g_decArgo_presDef pumpFlag]];
         end
      end
   end
end

return
