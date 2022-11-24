% ------------------------------------------------------------------------------
% Get cycle time information from Apex APF11 events.
%
% SYNTAX :
%  [o_cycleTimeData] = process_apx_apf11_ir_time_evts(a_events, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_events        : input system_log file event data
%   a_cycleTimeData : input cycle timings data
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : output cycle timings data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData] = process_apx_apf11_ir_time_evts(a_events, a_cycleTimeData)

% output parameters initialization
o_cycleTimeData = a_cycleTimeData;


% from 'go_to_state' events
PATTERN_STARTUP_DATE = 'Mission state IDLE -> PRELUDE';
PATTERN_DESCENT_TO_PARK_1 = 'Mission state PRELUDE -> PARKDESCENT';
PATTERN_DESCENT_TO_PARK_2 = 'Mission state SURFACE -> PARKDESCENT';
PATTERN_PARK_START = 'Mission state PARKDESCENT -> PARK';
PATTERN_DEEP_DESCENT_START = 'Mission state PARK -> DEEPDESCENT';
PATTERN_ASCENT_START_1 = 'Mission state DEEPDESCENT -> ASCENT';
PATTERN_ASCENT_START_2 = 'Mission state PARK -> ASCENT';
PATTERN_ASCENT_END = 'Mission state ASCENT -> SURFACE';

events = a_events(find(strcmp({a_events.functionName}, 'go_to_state')));
startTime = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_STARTUP_DATE)))
      startTime = evt.timestamp;
      o_cycleTimeData.preludeStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_1)) || any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_2)))
      o_cycleTimeData.descentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_PARK_START)))
      o_cycleTimeData.parkStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_DEEP_DESCENT_START)))
      o_cycleTimeData.parkEndDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_START_1)) || any(strfind(dataStr, PATTERN_ASCENT_START_2)))
      o_cycleTimeData.ascentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_END)))
      o_cycleTimeData.ascentEndDateSys = evt.timestamp;
   end
end

% from 'SURFACE' events
PATTERN_BLADDER_INFLATION_START = 'Inflating air bladder';

events = a_events(find(strcmp({a_events.functionName}, 'SURFACE')));
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_BLADDER_INFLATION_START)))
      o_cycleTimeData.bladderInflationStartDateSys = evt.timestamp;
   end
end

% from 'sky_search' events
PATTERN_TRANSMISSION_START = 'Found sky.';

events = a_events(find(strcmp({a_events.functionName}, 'sky_search')));
firstTime = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_TRANSMISSION_START)))
      if ((isempty(firstTime) || (firstTime > evt.timestamp)) && ...
            ((isempty(startTime)) || (startTime < evt.timestamp))) % to not consider times before STARTUP_DATE
         firstTime = evt.timestamp;
      end
   end
end
if (~isempty(firstTime))
   if (isempty(o_cycleTimeData.transStartDate) || (o_cycleTimeData.transStartDate > firstTime))
      o_cycleTimeData.transStartDate = firstTime;
   end
end

% from 'upload_file' events
PATTERN_TRANSMISSION_END = 'Upload Complete:';

events = a_events(find(strcmp({a_events.functionName}, 'upload_file')));
lastTime = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_TRANSMISSION_END)))
      if ((isempty(lastTime) || (lastTime < evt.timestamp)) && ...
            ((isempty(startTime)) || (startTime < evt.timestamp))) % to not consider times before STARTUP_DATE
         lastTime = evt.timestamp;
      end
   end
end
if (~isempty(lastTime))
   if (isempty(o_cycleTimeData.transEndDate) || (o_cycleTimeData.transEndDate < lastTime))
      o_cycleTimeData.transEndDate = lastTime;
   end
end

return
