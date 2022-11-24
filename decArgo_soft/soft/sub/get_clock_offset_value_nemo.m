% ------------------------------------------------------------------------------
% Retrieve the clock offsets to apply to RTC times and counter based times of a
% given cycle.
%
% SYNTAX :
%  [o_clockOffsetCounter, o_clockOffsetRtc] = ...
%    get_clock_offset_value_nemo(a_clockOffsetData, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_clockOffsetData : clock offset information
%   a_cycleTimeData   : input cycle timings data
%
% OUTPUT PARAMETERS :
%   o_cycleClockOffsetCounter : clock offset for counter based times
%   o_cycleClockOffsetRtc     : clock offset for RTC based times
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffsetCounter, o_clockOffsetRtc] = ...
   get_clock_offset_value_nemo(a_clockOffsetData, a_cycleTimeData)

% output parameters initialization
o_clockOffsetCounter = [];
o_clockOffsetRtc = [];


% retrieve the clock offset for internal counter
idF1 = find(([a_clockOffsetData.clockOffsetCycleNum] == a_cycleTimeData.cycleNum) & ...
   ~isnan(a_clockOffsetData.clockOffsetCounterValue));
if (~isempty(idF1))
   o_clockOffsetCounter = a_clockOffsetData.clockOffsetCounterValue(idF1);
end

% retrieve the clock offset for RTC
idF2 = find(([a_clockOffsetData.clockOffsetCycleNum] == a_cycleTimeData.cycleNum) & ...
   ~isnan(a_clockOffsetData.clockOffsetRtcValue));
if (~isempty(idF2))
   
   % the float surfaced during this cycle and a GPS fix has been set
   o_clockOffsetRtc = mean(a_clockOffsetData.clockOffsetRtcValue(idF2));
   % round offset to nearest second
   if (abs(o_clockOffsetRtc) < 1)
      o_clockOffsetRtc = 0;
   else
      o_clockOffsetRtc = round(o_clockOffsetRtc);
   end
else
   
   % the float didn't surface during this cycle
   times = [ ...
      a_cycleTimeData.descentStartDate ...
      a_cycleTimeData.parkStartDate ...
      a_cycleTimeData.upcastStartDate ...
      a_cycleTimeData.ascentStartDate ...
      a_cycleTimeData.ascentEndDate ...
      a_cycleTimeData.surfaceStartDate ...
      a_cycleTimeData.rafosDate' ...
      a_cycleTimeData.profileDate' ...
      ];
   
   idFBefore = find([a_clockOffsetData.clockOffsetJuldUtc] < min(times), 1, 'last');
   idFAfter = find([a_clockOffsetData.clockOffsetJuldUtc] > max(times), 1, 'first');
   if (~isempty(idFBefore) && ~isempty(idFAfter))
      
      % interpolate existing ones to the concerned cycle
      idF3 = find([a_clockOffsetData.clockOffsetCycleNum] == a_cycleTimeData.cycleNum);
      clockOffsetRtc = interp1q( ...
         [a_clockOffsetData.xmit_surface_start_time(idFBefore); a_clockOffsetData.xmit_surface_start_time(idFAfter)], ...
         [a_clockOffsetData.clockOffsetRtcValue(idFBefore); a_clockOffsetData.clockOffsetRtcValue(idFAfter)], ...
         a_clockOffsetData.xmit_surface_start_time(idF3));

      if (~isnan(clockOffsetRtc))
         o_clockOffsetRtc = clockOffsetRtc;

         % round offset to nearest second
         if (abs(o_clockOffsetRtc) < 1)
            o_clockOffsetRtc = 0;
         else
            o_clockOffsetRtc = round(o_clockOffsetRtc);
         end
      end
   end
end

 return
 