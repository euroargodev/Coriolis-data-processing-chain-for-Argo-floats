% ------------------------------------------------------------------------------
% Compute additional cycle timings.
%
% SYNTAX :
%  [o_cycleTimeData] = compute_additional_times_apx_apf11_ir( ...
%    a_cycleTimeData, a_profCtdP)      
%
% INPUT PARAMETERS :
%   a_cycleTimeData : input cycle timings data
%   a_profCtdP      : input CTD_P data
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : output cycle timings data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData] = compute_additional_times_apx_apf11_ir( ...
   a_cycleTimeData, a_profCtdP)      
      
% output parameters initialization
o_cycleTimeData = a_cycleTimeData;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(a_profCtdP))
   if (g_decArgo_cycleNum > 0)
   
      % retrieve configuration values
      parkPressure = get_config_value_apx_ir('CONFIG_PRKP_ParkPressure', g_decArgo_cycleNum);
      deepProfilePressure = get_config_value_apx_ir('CONFIG_TP_ProfilePressure', g_decArgo_cycleNum);
      
      presTime = a_profCtdP.dates;
      presVal = a_profCtdP.data(:, 1);      
      
      % DESCENT_END_TIME
      % computed as time of first P sample within 3% of aimed drift pressure
      idP = find((presVal >= parkPressure*0.97) & (presVal <= parkPressure*1.03));
      if (~isempty(idP))
         [descentEndDate, idMin] = min(presTime(idP));
         if (~isempty(a_cycleTimeData.parkEndDateSci) && ...
               (descentEndDate < a_cycleTimeData.parkEndDateSci))
            o_cycleTimeData.descentEndDate = descentEndDate;
            o_cycleTimeData.descentEndPres = presVal(idP(idMin));
         end
      end
      
      % DEEP_DESCENT_END_TIME
      % computed as time of first P sample within 3% of aimed profile pressure
      if (parkPressure ~= deepProfilePressure)
         if (~isempty(a_cycleTimeData.parkEndDateSci))
            idP = find((presVal >= deepProfilePressure*0.97) & (presVal <= deepProfilePressure*1.03) & ...
               (presTime >= a_cycleTimeData.parkEndDateSci));
            if (~isempty(idP))
               [deepDescentEndDate, idMin] = min(presTime(idP));
               if (~isempty(a_cycleTimeData.ascentStartDateSci) && ...
                     (deepDescentEndDate < a_cycleTimeData.ascentStartDateSci))
                  o_cycleTimeData.deepDescentEndDate = deepDescentEndDate;
                  o_cycleTimeData.deepDescentEndPres = presVal(idP(idMin));
               end
            end
         end
      end
   end
end

return
