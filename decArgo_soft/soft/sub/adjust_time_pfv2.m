% ------------------------------------------------------------------------------
% Apply clock offset adjustment to a set of dates.
%
% SYNTAX :
% [o_datesAdj] = adjust_time_pfv2(a_dates, a_clockOffset, a_refDate)
%
% INPUT PARAMETERS :
%   a_dates       : input set of dates
%   a_clockOffset : clock offset information for the concerned cycle
%   a_refDate     : reference date to be used to compute the offset (when times
%                   should be adjusted using a constant offset)
%
% OUTPUT PARAMETERS :
%   o_datesAdj : output set of dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_datesAdj] = adjust_time_pfv2(a_dates, a_clockOffset, a_refDate)

% output parameters initialization
o_datesAdj = a_dates;

% clock offset si set at GPS fix time, consequently
% times >= GPS fix time should be adjusted with 0 offset
idToAdjust = find(o_datesAdj < a_clockOffset(2));
if (~isnan(a_clockOffset(1)))
   % we will adjust times between 2 reference times
   if (isempty(a_refDate))
      % nominal case
      offset = interp1q([a_clockOffset(1); a_clockOffset(2)], [0; a_clockOffset(3)], o_datesAdj(idToAdjust));
      o_datesAdj(idToAdjust) = o_datesAdj(idToAdjust) - round(offset)/86400;
   else
      % fro profile measurements, we adjust all the times at the same reference
      % date
      offset = interp1q([a_clockOffset(1); a_clockOffset(2)], [0; a_clockOffset(3)/86400], a_refDate);
      o_datesAdj(idToAdjust) = o_datesAdj(idToAdjust) - round(offset)/86400;
   end
else
   % we will use the min date to adjust as the 0 offset base
   if (isempty(a_refDate))
      offset = interp1q([min(o_datesAdj(idToAdjust)); a_clockOffset(2)], [0; a_clockOffset(3)], o_datesAdj(idToAdjust));
      o_datesAdj(idToAdjust) = o_datesAdj(idToAdjust) - round(offset)/86400;
   else
      offset = interp1q([min(o_datesAdj(idToAdjust)); a_clockOffset(2)], [0; a_clockOffset(3)/86400], a_refDate);
      o_datesAdj(idToAdjust) = o_datesAdj(idToAdjust) - round(offset)/86400;
   end
end

return
