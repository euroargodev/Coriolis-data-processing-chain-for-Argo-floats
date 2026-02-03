% ------------------------------------------------------------------------------
% Retrieve the clock offset to apply to the times of a given cycle.
%
% SYNTAX :
%  [o_clockOffset] = get_clock_offset_value_pfv2(a_clockOffsetData, a_cycleTimeData)
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffset] = get_clock_offset_value_pfv2(a_clockOffsetData, a_cycleTimeData)

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
   
   idFCy = find(a_clockOffsetData.cycleNum == a_cycleTimeData.cycleNum, 1, 'first');
   if (~isempty(idFCy))
      idPrev = find(a_clockOffsetData.juldUtc < a_clockOffsetData.juldUtc(idFCy), 1, 'last');
      if (~isempty(idPrev))
         o_clockOffset = [a_clockOffsetData.juldUtc(idPrev) a_clockOffsetData.juldUtc(idFCy) a_clockOffsetData.clockOffset(idFCy)];
      else
         o_clockOffset = [nan a_clockOffsetData.juldUtc(idFCy) a_clockOffsetData.clockOffset(idFCy)];
      end
   else
      idF1 = find(a_clockOffsetData.cycleNum <= a_cycleTimeData.cycleNum - 1, 1, 'last');
      idF2 = find(a_clockOffsetData.cycleNum >= a_cycleTimeData.cycleNum, 1, 'first');
      if (~isempty(idF1) && ~isempty(idF2))

         % clock offset should be interpolated at the current cycle reference
         % time
         refTime = nan;
         if (~isnan(a_cycleTimeData.transStartDate))
            refTime = a_cycleTimeData.transStartDate;
         elseif (~isnan(a_cycleTimeData.ascentEndDate))
            refTime = a_cycleTimeData.ascentEndDate;
         end
         
         if (~isnan(refTime))
            
            clockOffset1 = a_clockOffsetData.clockOffset(idF1);
            juldFloat1 = a_clockOffsetData.juldUtc(idF1);
            
            clockOffset2 = a_clockOffsetData.clockOffset(idF2);
            juldFloat2 = a_clockOffsetData.juldUtc(idF2) + clockOffset2/86400;

            clockOffset = interp1q([juldFloat1; juldFloat2], [clockOffset1; clockOffset2], refTime);            

            idPrev = find(a_clockOffsetData.juldUtc < refTime, 1, 'last');
            if (~isempty(idPrev))
               o_clockOffset = [a_clockOffsetData.juldUtc(idPrev) refTime clockOffset];
            else
               o_clockOffset = [nan refTime clockOffset];
            end
         else
            fprintf('WARNING: Float #%d cycle #%d: cannot find a cycle timing to estimate clock offset\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
      end
   end
else

   idFCy = find(a_clockOffsetData.cycleNum == a_cycleTimeData.cycleNum, 1, 'first');
   if (~isempty(idFCy))
      idPrev = find(a_clockOffsetData.juldUtc < a_clockOffsetData.juldUtc(idFCy), 1, 'last');
      if (~isempty(idPrev))
         o_clockOffset = [a_clockOffsetData.juldUtc(idPrev) a_clockOffsetData.juldUtc(idFCy) a_clockOffsetData.clockOffset(idFCy)];
      else
         o_clockOffset = [nan a_clockOffsetData.juldUtc(idFCy) a_clockOffsetData.clockOffset(idFCy)];
      end
   end
end

return
