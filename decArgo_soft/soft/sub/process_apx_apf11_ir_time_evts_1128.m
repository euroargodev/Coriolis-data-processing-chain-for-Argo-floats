% ------------------------------------------------------------------------------
% Get cycle time information from Apex APF11 events.
%
% SYNTAX :
%  [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1128(a_events, a_cycleTimeData)
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
%   05/12/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1128(a_events, a_cycleTimeData)

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
PATTERN_ICE_DESCENT = 'SURFACE -> ICEDESCENT';
PATTERN_ICE_ASCENT = 'ICEDESCENT -> ICEASCENT';
PATTERN_ICE_SURFACE = 'ICEASCENT -> SURFACE';

events = a_events(find(strcmp({a_events.functionName}, 'mission_state')));
startTime = [];
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (any(strfind(dataStr, PATTERN_STARTUP_DATE))) % 'IDLE -> PRELUDE'
      startTime = evt.timestamp;
      o_cycleTimeData.preludeStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_1)) || any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_2))) % 'PRELUDE -> PARKDESCENT' or 'SURFACE -> PARKDESCENT'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.descentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_PARK_START))) % 'PARKDESCENT -> PARK'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.parkStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_DEEP_DESCENT_START))) % 'PARK -> DEEPDESCENT'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.parkEndDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_START_1))) % 'DEEPDESCENT -> ASCENT'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.ascentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_START_2))) % 'PARK -> ASCENT'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.parkEndDateSys = evt.timestamp;
      o_cycleTimeData.ascentStartDateSys = evt.timestamp;
   elseif (any(strfind(dataStr, PATTERN_ASCENT_END) & (dataStr(1) == 'A'))) % 'ASCENT -> SURFACE'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.ascentEndDateSys = [ ...
         o_cycleTimeData.ascentEndDateSys evt.timestamp];
   elseif (any(strfind(dataStr, PATTERN_ICE_DESCENT))) % 'SURFACE -> ICEDESCENT'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.iceDescentStartDateSys = [ ...
         o_cycleTimeData.iceDescentStartDateSys evt.timestamp];
   elseif (any(strfind(dataStr, PATTERN_ICE_ASCENT))) % 'ICEDESCENT -> ICEASCENT'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.iceAscentStartDateSys = [ ...
         o_cycleTimeData.iceAscentStartDateSys evt.timestamp];
   elseif (any(strfind(dataStr, PATTERN_ICE_SURFACE) & (dataStr(1) == 'I'))) % 'ICEASCENT -> SURFACE'
      if (isempty(startTime))
         startTime = evt.timestamp;
      end
      o_cycleTimeData.iceAscentEndDateSys = [ ...
         o_cycleTimeData.iceAscentEndDateSys evt.timestamp];
   end
end

% manage Ice Descent and Ascent cycles
if (isempty(o_cycleTimeData.iceDescentStartDateSys))
   % if ascentEndDate as not already been set (in
   % decode_science_log_apx_apf11_ir) we use the event time to set AED
   if (isempty(o_cycleTimeData.ascentEndDate))
      o_cycleTimeData.ascentEndDate = o_cycleTimeData.ascentEndDateSys;
   end
else
   % store AED of Ice cycles
   o_cycleTimeData.iceAscentEndDateSys = [ ...
      o_cycleTimeData.iceDescentStartDateSys(2:end) ...
      o_cycleTimeData.ascentEndDateSys(end)];
   
   % first PATTERN_ICE_DESCENT is AED of primary profile
   o_cycleTimeData.ascentEndDateSys = o_cycleTimeData.iceDescentStartDateSys(1);
   % if ascentEndDate as not already been set (in
   % decode_science_log_apx_apf11_ir) we use the event time to set AED
   if (isempty(o_cycleTimeData.ascentEndDate))
      o_cycleTimeData.ascentEndDate = o_cycleTimeData.ascentEndDateSys;
   end
end

% from 'AIR' events
PATTERN_BLADDER_INFLATION_START = 'starting inflation from';

events = a_events(find(strcmp({a_events.functionName}, 'AIR')));
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (isempty(o_cycleTimeData.bladderInflationStartDateSys) && any(strfind(dataStr, PATTERN_BLADDER_INFLATION_START)))
      o_cycleTimeData.bladderInflationStartDateSys = evt.timestamp;
   end
end

% from 'sky_search' events
PATTERN_TRANSMISSION_START = 'found sky';

events = a_events(find(strcmp({a_events.functionName}, 'COMMS')));
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
PATTERN_TRANSMISSION_END = 'uploaded:';

events = a_events(find(strcmp({a_events.functionName}, 'COMMS')));
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
