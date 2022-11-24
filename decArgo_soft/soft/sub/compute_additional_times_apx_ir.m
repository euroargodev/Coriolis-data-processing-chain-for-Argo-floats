% ------------------------------------------------------------------------------
% Compute additional cycle timings.
%
% SYNTAX :
%  [o_timeDataLog] = compute_additional_times_apx_ir( ...
%    a_timeDataLog, a_driftData)      
%
% INPUT PARAMETERS :
%   a_timeDataLog : input cycle timings from log file
%   a_driftData   : drift data
%
% OUTPUT PARAMETERS :
%   a_timeDataLog : updated cycle timings from log file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeDataLog] = compute_additional_times_apx_ir( ...
   a_timeDataLog, a_driftData)      
      
% output parameters initialization
o_timeDataLog = a_timeDataLog;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(a_driftData))
   
   % retrieve configuration values
   parkDescentTime = get_config_value_apx_ir('CONFIG_PDP_ParkDescentPeriod', g_decArgo_cycleNum);
   downTime = get_config_value_apx_ir('CONFIG_DOWN_DownTime', g_decArgo_cycleNum);
   deepProfileDescentTime = get_config_value_apx_ir('CONFIG_DPDP_DeepProfileDescentPeriod', g_decArgo_cycleNum);
   deepProfilePressure = get_config_value_apx_ir('CONFIG_TP_ProfilePressure', g_decArgo_cycleNum);
   parkPressure = get_config_value_apx_ir('CONFIG_PRKP_ParkPressure', g_decArgo_cycleNum);
   pnPCycleLen = get_config_value_apx_ir('CONFIG_N_ParkAndProfileCycleLength', g_decArgo_cycleNum);
   
   timeDataLog = o_timeDataLog;
   if (isempty(timeDataLog))
      timeDataLog = get_apx_ir_float_time_init_struct;
   end
   
   % DESCENT_START_TIME
   % computed as PST - ParkDescentTime (PST = time of the first drift meas)
   if (~any(a_driftData.dates == a_driftData.dateList.fillValue) && ~isempty(parkDescentTime))
      driftDates = a_driftData.dates;
      timeDataLog.descentStartDateBis = min(driftDates) - parkDescentTime/1440;
   end
   
   % DESCENT_END_TIME
   % computed as time of first drift sample within 3% of aimed drift pressure
   if (~any(a_driftData.dates == a_driftData.dateList.fillValue) && ~isempty(parkPressure))
      idDET = [];
      idDrift = 1;
      idPres = find(strcmp({a_driftData.paramList.name}, 'PRES') == 1, 1);
      if (~isempty(idPres))
         while ((idDrift <= size(a_driftData.data, 1)) && isempty(idDET))
            if ((a_driftData.dates(idDrift) ~= a_driftData.dateList.fillValue) && ...
                  (a_driftData.data(idDrift, idPres) ~= a_driftData.paramList(idPres).fillValue))
               if ((a_driftData.data(idDrift, idPres) >= parkPressure*0.97) && ...
                     (a_driftData.data(idDrift, idPres) <= parkPressure*1.03))
                  idDET = idDrift;
               end
            end
            idDrift = idDrift + 1;
         end
         if (~isempty(idDET))
            timeDataLog.descentEndDate = a_driftData.dates(idDET);
         end
      end
   end
   
   % PARK_END_TIME
   % computed as descentStartDateBis + DOWN_TIME - DeepProfileDescentTime (if
   % PARK_PRES ~= PROF_PRES) and descentStartDateBis + DOWN_TIME otherwise
   if (g_decArgo_cycleNum > 1)
      if (~isempty(timeDataLog.descentStartDateBis) && ...
            ~isempty(downTime) && ~isempty(deepProfileDescentTime) && ...
            ~isempty(deepProfilePressure) && ~isempty(parkPressure) && ...
            ~isempty(pnPCycleLen))
         if (pnPCycleLen == 254)
            timeDataLog.parkEndDateBis = timeDataLog.descentStartDateBis + downTime/1440;
         else
            if (rem(g_decArgo_cycleNum, pnPCycleLen) ~= 0)
               timeDataLog.parkEndDateBis = timeDataLog.descentStartDateBis + downTime/1440;
            else
               timeDataLog.parkEndDateBis = timeDataLog.descentStartDateBis + downTime/1440 - deepProfileDescentTime/1440;
            end
         end
      end
   end
   
   if (~isempty(timeDataLog.descentStartDateBis) || ~isempty(timeDataLog.parkEndDateBis))
      o_timeDataLog = timeDataLog;
   end
end

return;
