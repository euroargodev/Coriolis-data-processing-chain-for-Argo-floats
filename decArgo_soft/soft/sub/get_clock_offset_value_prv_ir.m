% ------------------------------------------------------------------------------
% Retrieve the clock offset to apply to the times of a given cycle.
%
% SYNTAX :
%  [o_clockOffset] = get_clock_offset_value_prv_ir(a_clockOffsetData, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_clockOffsetData : clock offset information
%   a_cycleTimeData   : input cycle timings data
%
% OUTPUT PARAMETERS :
%   o_clockOffset : clock offset value
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset] = get_clock_offset_value_prv_ir(a_clockOffsetData, a_cycleTimeData)

% output parameters initialization
o_clockOffset = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_clockOffsetData.cycleNum))
   return
end

if (a_cycleTimeData.cycleNum ~= 0)
   
   idF = find(a_clockOffsetData.cycleNum == a_cycleTimeData.cycleNum);
   if (~isempty(idF))
      o_clockOffset = mean(a_clockOffsetData.clockOffset(idF));
   else
      idF1 = find(a_clockOffsetData.cycleNum <= a_cycleTimeData.cycleNum - 1, 1, 'last');
      idF2 = find(a_clockOffsetData.cycleNum >= a_cycleTimeData.cycleNum, 1, 'first');
      if (~isempty(idF1) && ~isempty(idF2))
         
         % clock offset should be interpolated at the current cycle
         % reference time
         refTime = [];
         if (~isempty(a_cycleTimeData.transStartDate))
            refTime = a_cycleTimeData.transStartDate;
         elseif (~isempty(a_cycleTimeData.ascentEndDate))
            refTime = a_cycleTimeData.ascentEndDate;
         end
         
         if (~isempty(refTime))
            
            clockOffset1 = 0;
            juldFloat1 = a_clockOffsetData.juldUtc(idF1);
            
            clockOffset2 = a_clockOffsetData.clockOffset(idF2);
            juldFloat2 = a_clockOffsetData.juldUtc(idF2) + clockOffset2/86400;

            clockOffset = interp1q([clockOffset1 clockOffset2], ...
               [juldFloat1 juldFloat2], refTime);
            o_clockOffset = round(clockOffset); % clock offset rounded to 1 second
         else
            fprintf('ERROR: Float #%d cycle #%d: cannot find a cycle timing to estimate clock offset\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
      end
   end
else
   idF = find(a_clockOffsetData.cycleNum == a_cycleTimeData.cycleNum, 1, 'last'); % IN AIR meas are provided with the last transmitted cycle #0 of the prelude
   if (~isempty(idF))
      o_clockOffset = a_clockOffsetData.clockOffset(idF);
   end
end

return
 