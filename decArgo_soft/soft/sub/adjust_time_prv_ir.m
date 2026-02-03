% ------------------------------------------------------------------------------
% Adjust measurement times using cycle timings.
%
% SYNTAX :
% [o_descProfDate, o_parkDate, o_ascProfDate, o_nearSurfDate, o_inAirDate, ...
%   o_evAct, o_pumpAct] = adjust_time_prv_ir( ...
%   a_descProfDate, a_parkDate, a_ascProfDate, a_nearSurfDate, a_inAirDate, ...
%   a_evAct, a_pumpAct, a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_descProfDate  : input desc prof dates
%   a_parkDate      : input park dates
%   a_ascProfDate   : input asc prof dates
%   a_nearSurfDate  : input NS dates
%   a_inAirDate     : input IA dates
%   a_evAct         : input EV dates
%   a_pumpAct       : input PUMP dates
%   a_cycleTimeData : cycle timings
%
% OUTPUT PARAMETERS :
%   o_descProfDate  : output desc prof dates
%   o_parkDate      : output park dates
%   o_ascProfDate   : output asc prof dates
%   o_nearSurfDate  : output NS dates
%   o_inAirDate     : output IA dates
%   o_evAct         : output EV dates
%   o_pumpAct       : output PUMP dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfDate, o_parkDate, o_ascProfDate, o_nearSurfDate, o_inAirDate, ...
   o_evAct, o_pumpAct] = adjust_time_prv_ir( ...
   a_descProfDate, a_parkDate, a_ascProfDate, a_nearSurfDate, a_inAirDate, ...
   a_evAct, a_pumpAct, a_cycleTimeData)

% output parameters initialization
o_descProfDate = a_descProfDate;
o_parkDate = a_parkDate;
o_ascProfDate = a_ascProfDate;
o_nearSurfDate = a_nearSurfDate;
o_inAirDate = a_inAirDate;
o_evAct = a_evAct;
o_pumpAct = a_pumpAct;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;


for idLoop = 1:3
   if (idLoop == 1)
      if (~isempty(o_descProfDate))
         if (~isempty(a_cycleTimeData.descentToParkStartDate) && ...
               ~isempty(a_cycleTimeData.descentToParkEndDate))
            dates = o_descProfDate(o_descProfDate ~= g_decArgo_dateDef);
            refDateStart = a_cycleTimeData.descentToParkStartDate;
            refDateEnd = a_cycleTimeData.descentToParkEndDate;
         else
            continue
         end
      else
         continue
      end
   elseif (idLoop == 2)
      if (~isempty(o_parkDate))
         if (~isempty(a_cycleTimeData.descentToParkEndDate) && ...
               ~isempty(a_cycleTimeData.descentToProfStartDate))
            dates = o_parkDate(o_parkDate ~= g_decArgo_dateDef);
            refDateStart = a_cycleTimeData.descentToParkEndDate;
            refDateEnd = a_cycleTimeData.descentToProfStartDate;
         else
            continue
         end
      else
         continue
      end
   elseif (idLoop == 3)
      if (~isempty(o_ascProfDate))
         if (~isempty(a_cycleTimeData.ascentStartDate) && ...
               ~isempty(a_cycleTimeData.ascentEndDate))
            dates = o_ascProfDate(o_ascProfDate ~= g_decArgo_dateDef);
            refDateStart = a_cycleTimeData.ascentStartDate;
            refDateEnd = a_cycleTimeData.ascentEndDate;
         else
            continue
         end
      else
         continue
      end
   end

   minDate = min(dates);
   maxDate = max(dates);
   if (minDate < refDateStart)
      offset = 0;
      while (minDate+offset < refDateStart)
         offset = offset + 1;
      end
      if (maxDate+offset < refDateEnd)
         dates = dates + offset;
         fprintf('Float #%d Cycle #%d: offset = %d days\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, offset);
      else
         offset2 = offset - 1;
         % while (~((minAscProfDate+offset2 >= ascentStartDate) && (maxAscProfDate+offset2 <= ascentEndDate)) && (offset2 < offset))
         while (~((minDate+offset2 > refDateStart)) && (offset2 < offset))
            offset2 = offset2 + 1/1440;
         end
         % if (offset2 < offset)
         dates = dates + offset2;
         fprintf('Float #%d Cycle #%d: offset = %.1f days\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, offset2);
         % end
      end
   else
   end

   if (idLoop == 1)
      o_descProfDate(o_descProfDate ~= g_decArgo_dateDef) = dates;
   elseif (idLoop == 2)
      o_parkDate(o_parkDate ~= g_decArgo_dateDef) = dates;
   elseif (idLoop == 3)
      o_ascProfDate(o_ascProfDate ~= g_decArgo_dateDef) = dates;
   end
end

return
