% ------------------------------------------------------------------------------
% Get buoyancy information from Apex APF11 events.
%
% SYNTAX :
%  [o_buoyancy] = process_apx_apf11_ir_buoyancy_evts(a_events)
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_buoyancy] = process_apx_apf11_ir_buoyancy_evts(a_events)

% output parameters initialization
o_buoyancy = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;


% buoyancy during parking drift
idEvts = find(strcmp({a_events.functionName}, 'PARK'));
events = a_events(idEvts);

PATTERN_PRES_START = 'Too Shallow:';
PATTERN_PRES_END = 'dbar';
PATTERN_ADJUSTING = 'Adjusting Buoyancy to';

checkTime = [];
checkLabel = [];
for idEv = 1:length(events)
   dataStr = events(idEv).message;
   if (any(strfind(dataStr, PATTERN_PRES_START)))
      checkTime(end+1) = events(idEv).timestamp;
      checkLabel{end+1} = dataStr;
   end
end

for idEv = 1:length(events)
   dataStr = events(idEv).message;
   if (any(strfind(dataStr, PATTERN_ADJUSTING)))
      [~, idMin] = min(abs(checkTime - events(idEv).timestamp));
      buoyancyPresStr = checkLabel{idMin};
      idF1 = strfind(buoyancyPresStr, PATTERN_PRES_START);
      idF2 = strfind(buoyancyPresStr, PATTERN_PRES_END);
      buoyancyPres = str2double(buoyancyPresStr(idF1+length(PATTERN_PRES_START)+1:idF2-1));
      o_buoyancy = [o_buoyancy; [events(idEv).timestamp g_decArgo_dateDef buoyancyPres g_decArgo_presDef]];
   end
end

% buoyancy during ascent
idEvts = find(strcmp({a_events.functionName}, 'ASCENT'));
events = a_events(idEvts);

PATTERN = 'Ascending Too Slowly:';
PATTERN_PRES_START = '@';
PATTERN_PRES_END = 'dbar';
PATTERN_ADJUSTING = 'Adjusting Buoyancy to';

checkTime = [];
checkLabel = [];
for idEv = 1:length(events)
   dataStr = events(idEv).message;
   if (any(strfind(dataStr, PATTERN)))
      checkTime(end+1) = events(idEv).timestamp;
      checkLabel{end+1} = dataStr;
   end
end

for idEv = 1:length(events)
   dataStr = events(idEv).message;
   if (any(strfind(dataStr, PATTERN_ADJUSTING)))
      checkTimeBis = checkTime(find(checkTime < events(idEv).timestamp));
      if (~isempty(checkTimeBis))
         [~, idMin] = min(abs(checkTimeBis - events(idEv).timestamp));
         buoyancyPresStr = checkLabel{idMin};
         idF1 = strfind(buoyancyPresStr, PATTERN_PRES_START);
         idF2 = strfind(buoyancyPresStr, PATTERN_PRES_END);
         buoyancyPres = str2double(buoyancyPresStr(idF1+length(PATTERN_PRES_START)+1:idF2(2)-1));
         o_buoyancy = [o_buoyancy; [events(idEv).timestamp g_decArgo_dateDef buoyancyPres g_decArgo_presDef]];
      end
   end
end

return;
