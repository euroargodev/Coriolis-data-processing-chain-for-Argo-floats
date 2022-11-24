% ------------------------------------------------------------------------------
% Retrieve the clock offset to apply to the times of a given cycle.
%
% SYNTAX :
%  [o_clockOffset] = get_clock_offset_value_apx_apf11_ir(a_clockOffsetData, a_cycleTimeData)
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
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset] = get_clock_offset_value_apx_apf11_ir(a_clockOffsetData, a_cycleTimeData)

% output parameters initialization
o_clockOffset = 0;


times = struct2cell(a_cycleTimeData);
times = [times{2:end}];

if (isempty(times))
   return
end

idF1 = find([a_clockOffsetData.clockOffsetJuldUtc] < min(times), 1, 'last');
idF2 = find([a_clockOffsetData.clockOffsetJuldUtc] > max(times), 1, 'first');
if (~isempty(idF1) && ~isempty(idF2))
   offset1 = a_clockOffsetData.clockOffsetValue(idF1);
   offset2 = a_clockOffsetData.clockOffsetValue(idF2);
   o_clockOffset = (offset1+offset2)/2;
   if (abs(o_clockOffset) < 1)
      o_clockOffset = 0;
   else
      o_clockOffset = round(o_clockOffset);
   end
end

 return
 