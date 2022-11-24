% ------------------------------------------------------------------------------
% Adjust float time from RTC clock offset.
%
% SYNTAX :
%  [o_timeAdj] = adjust_time_cts5(a_time)
%
% INPUT PARAMETERS :
%   a_time : float time to adjust
%
% OUTPUT PARAMETERS :
%   o_timeAdj : adjusted time
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeAdj] = adjust_time_cts5(a_time)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_timeAdj = ones(size(a_time))*g_decArgo_dateDef;

% clock offset management
global g_decArgo_clockOffset;


idF1 = find(g_decArgo_clockOffset.juldFloat <= min(a_time));
if (~isempty(idF1))
   idF1 = idF1(end);
   idF2 = find(g_decArgo_clockOffset.juldFloat >= max(a_time));
   if (~isempty(idF2))
      idF2 = idF2(1);
      
      if (idF2 - idF1 <= 1)
         % the dates span only one adjustment interval
         if (idF1 == idF2)
            o_timeAdj = a_time - g_decArgo_clockOffset.clockOffset(idF1);
         else
            clockOffset = g_decArgo_clockOffset.clockOffset(idF2)* ...
               (a_time-g_decArgo_clockOffset.juldFloat(idF1))/...
               (g_decArgo_clockOffset.juldFloat(idF2)-g_decArgo_clockOffset.juldFloat(idF1));
            o_timeAdj = a_time - clockOffset;
         end
      else
         % the dates span more than one adjustment interval
         for idD = 1:length(a_time)
            idF1 = find(g_decArgo_clockOffset.juldFloat <= a_time(idD));
            if (~isempty(idF1))
               idF1 = idF1(end);
               idF2 = find(g_decArgo_clockOffset.juldFloat >= a_time(idD));
               if (~isempty(idF2))
                  idF2 = idF2(1);
                  
                  if (idF1 == idF2)
                     o_timeAdj(idD) = a_time(idD) - g_decArgo_clockOffset.clockOffset(idF1);
                  else
                     clockOffset = g_decArgo_clockOffset.clockOffset(idF2)* ...
                        (a_time(idD)-g_decArgo_clockOffset.juldFloat(idF1))/...
                        (g_decArgo_clockOffset.juldFloat(idF2)-g_decArgo_clockOffset.juldFloat(idF1));
                     o_timeAdj(idD) = a_time(idD) - clockOffset;
                  end
               end
            end
         end
      end
   end
end

return
