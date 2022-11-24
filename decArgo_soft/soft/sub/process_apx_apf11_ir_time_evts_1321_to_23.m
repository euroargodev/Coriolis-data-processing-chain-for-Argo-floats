% ------------------------------------------------------------------------------
% Get cycle time information from Apex APF11 events.
%
% SYNTAX :
%  [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1321_to_23(a_events, a_cycleTimeData, a_fileNum)
%
% INPUT PARAMETERS :
%   a_events        : input system_log file event data
%   a_cycleTimeData : input cycle timings data
%   a_fileNum       : file number
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
function [o_cycleTimeData] = process_apx_apf11_ir_time_evts_1321_to_23(a_events, a_cycleTimeData, a_fileNum)

% output parameters initialization
o_cycleTimeData = a_cycleTimeData;


% from 'go_to_state' events
PATTERN_STARTUP_DATE = 'Mission state IDLE -> PRELUDE';
PATTERN_DESCENT_TO_PARK_1 = 'Mission state PRELUDE -> PARKDESCENT';
PATTERN_DESCENT_TO_PARK_2 = 'Mission state SURFACE -> PARKDESCENT';
PATTERN_DESCENT_TO_PARK_3 = 'Mission state RECOVERY -> PARKDESCENT';
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
   elseif (any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_1)) || ...
         any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_2)) || ...
         any(strfind(dataStr, PATTERN_DESCENT_TO_PARK_3)))
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

% from 'SURFACE' events
PATTERN_BLADDER_INFLATION_START = 'Inflating air bladder';

events = a_events(find(strcmp({a_events.functionName}, 'SURFACE')));
for idEv = 1:length(events)
   evt = events(idEv);
   dataStr = evt.message;
   if (isempty(o_cycleTimeData.bladderInflationStartDateSys) && any(strfind(dataStr, PATTERN_BLADDER_INFLATION_START)))
      o_cycleTimeData.bladderInflationStartDateSys = evt.timestamp;
   end
end

% from 'sky_search' events
PATTERN_TRANSMISSION_START = 'Found sky.';

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

if (a_fileNum == 1) % files of the previous cycle are generally transmitted in the begining of the next one

   % from 'zmodem_upload_files' events
   PATTERN_TRANSMISSION_END = 'Upload Complete: ';

   events = a_events(find(strcmp({a_events.functionName}, 'upload_file')));
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
end

return
