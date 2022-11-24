% ------------------------------------------------------------------------------
% Retrieve clock offset at a given date.
%
% SYNTAX :
%  [o_clockOffset] = get_nva_clock_offset(a_time, a_cycleNumber, ...
%    a_clockDrift, a_clockDriftRefDateStart, a_clockDriftRefDateEnd)
%
% INPUT PARAMETERS :
%   a_time                   : time to compute clock offset
%   a_cycleNumber            : concerned cycle number
%   a_clockDrift             : RTC clock offset (between reference times)
%   a_clockDriftRefDateStart : end reference time of RTC clock offset
%   a_clockDriftRefDateEnd   : end reference time of RTC clock offset
%
% OUTPUT PARAMETERS :
%   o_clockOffset : clock offset
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset] = get_nva_clock_offset(a_time, a_cycleNumber, ...
   a_clockDrift, a_clockDriftRefDateStart, a_clockDriftRefDateEnd)

% output parameters initialization
o_clockOffset = 0;

% cycle timings storage
global g_decArgo_timeData;


clockDrift = [];
refDateStart = [];
refDateEnd = [];
if (~isempty(a_clockDrift))
   
   % use input parameters
   clockDrift = a_clockDrift;
   refDateStart = a_clockDriftRefDateStart;
   refDateEnd = a_clockDriftRefDateEnd;
else
   
   % retrieve information from g_decArgo_timeData structure
   if (~isempty(g_decArgo_timeData))
      idCycleStruct = find([g_decArgo_timeData.cycleNum] == a_cycleNumber);
      if (length(idCycleStruct) == 1) % same cycle number only for a_cycleNumber = 255 (EOL mode => surface cycle => no time to adjust)
         if (~isempty(g_decArgo_timeData.cycleTime(idCycleStruct).clockDrift))
            clockDrift = g_decArgo_timeData.cycleTime(idCycleStruct).clockDrift;
            refDateStart = g_decArgo_timeData.cycleTime(idCycleStruct).cycleStartTime;
            refDateEnd = g_decArgo_timeData.cycleTime(idCycleStruct).gpsTime;
         else
            o_clockOffset = [];
         end
      end
   end
end

if (~isempty(clockDrift))
   
   % interpolate clock offset at a_time
   o_clockOffset = interp1([refDateStart; refDateEnd], [0; clockDrift], a_time);
   
   if (isnan(o_clockOffset))
      if (a_time < refDateStart)
         o_clockOffset = 0;
      elseif (a_time > refDateEnd)
         o_clockOffset = clockDrift;
      end
   end
end

return
