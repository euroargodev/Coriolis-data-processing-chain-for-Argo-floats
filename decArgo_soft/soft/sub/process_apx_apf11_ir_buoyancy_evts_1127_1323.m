% ------------------------------------------------------------------------------
% Get buoyancy information from Apex APF11 events.
%
% SYNTAX :
%  [o_buoyancy] = process_apx_apf11_ir_buoyancy_evts_1127_1323(a_events)
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
%   06/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_buoyancy] = process_apx_apf11_ir_buoyancy_evts_1127_1323(a_events)

% output parameters initialization
o_buoyancy = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


% buoyancy events
idEvts = find(strcmp({a_events.functionName}, 'BuoyEngine'));
events = a_events(idEvts);

PATTERN_1 = 'Adjusting Buoyancy to';
PATTERN_2 = 'Buoyancy Start Position:';
for idEv = 1:length(events)
   dataStr = events(idEv).message;
   if (any(strfind(dataStr, PATTERN_1)))
      pistonStop = str2double(dataStr(length(PATTERN_1)+1:end));
      if (idEv < length(events))
         dataStr2 = events(idEv+1).message;
         if (any(strfind(dataStr2, PATTERN_2)))
            pistonStart = str2double(dataStr2(length(PATTERN_2)+1:end));
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
