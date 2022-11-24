% ------------------------------------------------------------------------------
% Get clock offset information from Apex APF11 events.
%
% SYNTAX :
%  [o_rtcOffset] = process_apx_apf11_ir_rudics_clock_offset_evts(a_events)
%
% INPUT PARAMETERS :
%   a_events : input system_log file event data
%
% OUTPUT PARAMETERS :
%   o_rtcOffset : clock offset data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_rtcOffset] = process_apx_apf11_ir_rudics_clock_offset_evts(a_events)

% output parameters initialization
o_rtcOffset = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

PATTERN_UNUSED = [ ...
   {'Almanac expiration in '} ...
   {'Updating GPS Almanac for '} ...
   {'Completed GPS Almanac Update on '} ...
   {'Next GPS Almanac Update '} ...
   {'GPS Fix: '} ...
   {'GPS TimeToFix: '} ...
   {'Timeout during update of time and location'} ...
   {'Time and location set'} ...
   {'Updating Almanac for '} ...
   {'Completed Almanac Update on '} ...
   {'Next Almanac Update '} ...
   {'test start'} ...
   {'test passed'} ...
   {'time and location set'} ...
   ];

PATTERN = 'GPS Skew: ';

for idEv = 1:length(a_events)
   dataStr = a_events(idEv).message;
   if (isempty(dataStr))
      continue
   end
   %    fprintf('''%s''\n', dataStr);
   
   if (any(strfind(dataStr, PATTERN)))
   
      [val, count, errmsg, nextIndex] = sscanf(dataStr, 'GPS Skew: %d secs');
      if (~isempty(errmsg) || (count ~= 1))
         fprintf('DEC_INFO: %sAnomaly detected while parsing GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
      
      % store RTC offset
      rtcOffset = get_apx_apf11_ir_clock_offset_init_struct;
      rtcOffset.clockOffsetJuldUtc = a_events(idEv).timestamp - val/86400;
      rtcOffset.clockOffsetValue = val;
      o_rtcOffset = [o_rtcOffset rtcOffset];

   else
      idF = cellfun(@(x) strfind(dataStr, x), PATTERN_UNUSED, 'UniformOutput', 0);
      if (isempty([idF{:}]))
         fprintf('DEC_INFO: %sNot managed GPS information (from evts) ''%s'' - ignored\n', errorHeader, dataStr);
         continue
      end
   end
end

return
