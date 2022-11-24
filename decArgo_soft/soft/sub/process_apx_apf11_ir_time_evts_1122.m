% ------------------------------------------------------------------------------
% Get cycle time information from Apex APF11 events.
%
% SYNTAX :
%  [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1122(a_events, a_cycleTimeData)
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
%   06/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1122(a_events, a_cycleTimeData)

% output parameters initialization
o_cycleTimeData = a_cycleTimeData;


% from 'mission_state' events
PATTERN_STARTUP_DATE = 'IDLE -> PRELUDE';
PATTERN_DESCENT_TO_PARK_1 = 'PRELUDE -> PARKDESCENT';
PATTERN_DESCENT_TO_PARK_2 = 'SURFACE -> PARKDESCENT';
PATTERN_PARK_START = 'PARKDESCENT -> PARK';
PATTERN_DEEP_DESCENT_START = 'PARK -> DEEPDESCENT';
PATTERN_ASCENT_START_1 = 'DEEPDESCENT -> ASCENT';
PATTERN_ASCENT_START_2 = 'PARK -> ASCENT';
PATTERN_ASCENT_END = 'ASCENT -> SURFACE';

events = a_events(find(strcmp({a_events.functionName}, 'mission_state')));
startTime = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_STARTUP_DATE)))
      startTime = evt.timestamp;
      o_cycleTimeData.preludeStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_1)) || any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_2)))
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.descentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_PARK_START)))
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.parkStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_DEEP_DESCENT_START)))
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.parkEndDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_START_1)))
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.ascentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_START_2)))
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.parkEndDateSys = evt.timestamp;
      o_cycleTimeData.ascentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_END)))
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.ascentEndDateSys = evt.timestamp;
      if (isempty(o_cycleTimeData.ascentEndDate))
         o_cycleTimeData.ascentEndDate = o_cycleTimeData.ascentEndDateSys;
      end
   end
end

% from 'AIR' events
PATTERN_BLADDER_INFLATION_START = 'inflate';

events = a_events(find(strcmp({a_events.functionName}, 'AIR')));
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_BLADDER_INFLATION_START)))
      o_cycleTimeData.bladderInflationStartDateSys = evt.timestamp;
   end
end

% from 'sky_search' events
PATTERN_TRANSMISSION_START = 'Found the sky';

events = a_events(find(strcmp({a_events.functionName}, 'sky_search')));
firstTimeAfterAED = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_TRANSMISSION_START)))
      if ((isempty(firstTimeAfterAED) || (firstTimeAfterAED > evt.timestamp)) && ...
            ((isempty(startTime)) || (startTime < evt.timestamp))) % to not consider times before AED
         firstTimeAfterAED = evt.timestamp;
      end
   end
end
if (~isempty(firstTimeAfterAED))
   if (isempty(o_cycleTimeData.transStartDate) || (o_cycleTimeData.transStartDate > firstTimeAfterAED))
      o_cycleTimeData.transStartDate = firstTimeAfterAED;
   end
end

% from 'zmodem_upload_files' events
PATTERN_TRANSMISSION_END = 'Uploaded:';

events = a_events(find(strcmp({a_events.functionName}, 'zmodem_upload_files')));
lastTime = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_TRANSMISSION_END)))
      if ((isempty(lastTime) || (lastTime < evt.timestamp)))
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
