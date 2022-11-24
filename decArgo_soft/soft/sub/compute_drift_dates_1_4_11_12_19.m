% ------------------------------------------------------------------------------
% Compute drift measurement dates.
%
% SYNTAX :
%  [o_parkDateHour] = compute_drift_dates_1_4_11_12_19(...
%    a_tryNumber, a_tabDrifCTD, a_driftSamplingPeriod, ...
%    a_descentEndDate, a_endParkDate, a_msgDates, a_msgNbMeas)
%
% INPUT PARAMETERS :
%   a_tryNumber           : number of the try (1 or 2), for output message purposes only
%   a_tabDrifCTD          : drift CTD data
%   a_driftSamplingPeriod : sampling period during drift phase (in hours)
%   a_descentEndDate      : descent end date
%   a_endParkDate         : end date of drift phase (different between try #1
%                           and #2)
%   a_msgDates            : transmitted dates of drift measurements
%   a_msgNbMeas           : number of drift measurements associated with a
%                           transmitted date
%
% OUTPUT PARAMETERS :
%   o_parkDateHour : computed dates of drift measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDateHour] = compute_drift_dates_1_4_11_12_19(...
   a_tryNumber, a_tabDrifCTD, a_driftSamplingPeriod, ...
   a_descentEndDate, a_endParkDate, a_msgDates, a_msgNbMeas)

% output parameters initialization
o_parkDateHour = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% sampling period in days
driftSampPeriodDay = a_driftSamplingPeriod/24;

% compute theoretical dates of drift measurements
firstDriftMesDate = floor(a_descentEndDate*24)/24 + driftSampPeriodDay;
nbDriftMes = floor((a_endParkDate-firstDriftMesDate)/driftSampPeriodDay) + 1;
if (rem(a_endParkDate-firstDriftMesDate, driftSampPeriodDay) == 0)
   nbDriftMes = nbDriftMes - 1;
end
lastDriftMesDate = firstDriftMesDate + (nbDriftMes-1)*driftSampPeriodDay;
o_parkDateHour = round([firstDriftMesDate*24:a_driftSamplingPeriod:lastDriftMesDate*24]);

% try to fit transmitted data in theoretical array
[~, idSort] = sort(a_msgDates);
filled = zeros(length(o_parkDateHour), 1);
for id = 1:size(a_tabDrifCTD, 1)
   idMsg = idSort(id);

   % try to find the right place
   firstMesDate = a_msgDates(idMsg)*24;

   idCurMes = find(o_parkDateHour == firstMesDate);
   if (~isempty(idCurMes))
      if (filled(idCurMes) == 0)
         filled(idCurMes) = 1;
      else
         fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
         o_parkDateHour = [];
         return
      end

      for idMeas = 1:a_msgNbMeas(idMsg)-1
         idCurMes = idCurMes + 2;
         if (idCurMes <= length(filled))
            if (filled(idCurMes) == 0)
               filled(idCurMes) = 1;
            else
               fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
               o_parkDateHour = [];
               return
            end
         else
            if (length(filled) > 1)
               if (filled(2) == 0)
                  filled(2) = 1;
                  idCurMes = 2;
               else
                  if (a_tryNumber == 2)
                     fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                  end
                  o_parkDateHour = [];
                  return
               end
            else
               fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
               o_parkDateHour = [];
               return
            end
         end
      end
   else
      if (isempty(find(filled == 1, 1)))
         fprintf('DEC_INFO: Float #%d Cycle #%d: all drift measurement dates have shifted\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      else
         fprintf('DEC_WARNING: Float #%d Cycle #%d: some drift measurement dates have shifted => drift measurements possibly erroneously dated\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
      
      % next theoretical dates are false, drift measurement dates should be
      % re-sampled
      
      nbNewDriftMes = floor((a_endParkDate-firstMesDate/24)/driftSampPeriodDay) + 1;
      if (rem(a_endParkDate-firstMesDate/24, driftSampPeriodDay) == 0)
         nbNewDriftMes = nbNewDriftMes - 1;
      end
      lastMesDate = firstMesDate + (nbNewDriftMes-1)*a_driftSamplingPeriod;
      newParkDateHour = round([firstMesDate:a_driftSamplingPeriod:lastMesDate]);

      %       idDay = find(fix(o_parkDateHour/24) == fix(firstMesDate/24));
      %       [~, idMin] = min(abs(o_parkDateHour(idDay)-firstMesDate));
      %       idMin = idDay(idMin);
      %       if (filled(idMin) == 1)
      %          [~, idMin] = min(abs(o_parkDateHour-firstMesDate));
      %       end
      [~, idMin] = min(abs(o_parkDateHour-firstMesDate));
      prevLength = length(o_parkDateHour);
      if (~isempty(idMin))
         o_parkDateHour(idMin:idMin+length(newParkDateHour)-1) = newParkDateHour;
      else
         o_parkDateHour = newParkDateHour;
      end

      if (prevLength == length(o_parkDateHour))
         idCurMes = find(o_parkDateHour == firstMesDate);
         if (filled(idCurMes) == 0)
            filled(idCurMes) = 1;
         else
            fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
            o_parkDateHour = [];
            return
         end

         for idMeas = 1:a_msgNbMeas(idMsg)-1
            idCurMes = idCurMes + 2;
            if (idCurMes <= length(filled))
               if (filled(idCurMes) == 0)
                  filled(idCurMes) = 1;
               else
                  fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
                  o_parkDateHour = [];
                  return
               end
            else
               if (length(filled) > 1)
                  if (filled(2) == 0)
                     filled(2) = 1;
                     idCurMes = 2;
                  else
                     if (a_tryNumber == 2)
                        fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                           g_decArgo_floatNum, g_decArgo_cycleNum);
                     end
                     o_parkDateHour = [];
                     return
                  end
               else
                  fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum);
                  o_parkDateHour = [];
                  return
               end
            end
         end
      else
         filled = zeros(length(o_parkDateHour), 1);
         for id2 = 1:id
            idMsg = idSort(id2);

            % try to find the right place
            firstMesDate = a_msgDates(idMsg)*24;

            idCurMes = find(o_parkDateHour == firstMesDate);
            if (filled(idCurMes) == 0)
               filled(idCurMes) = 1;
            else
               fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
               o_parkDateHour = [];
               return
            end

            for idMeas = 1:a_msgNbMeas(idMsg)-1
               idCurMes = idCurMes + 2;
               if (idCurMes <= length(filled))
                  if (filled(idCurMes) == 0)
                     filled(idCurMes) = 1;
                  else
                     fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                     o_parkDateHour = [];
                     return
                  end
               else
                  if (length(filled) > 1)
                     if (filled(2) == 0)
                        filled(2) = 1;
                        idCurMes = 2;
                     else
                        if (a_tryNumber == 2)
                           fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                              g_decArgo_floatNum, g_decArgo_cycleNum);
                        end
                        o_parkDateHour = [];
                        return
                     end
                  else
                     fprintf('DEC_ERROR: Float #%d Cycle #%d: this should never happen!\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                     o_parkDateHour = [];
                     return
                  end
               end
            end
         end
      end
   end
end

return
