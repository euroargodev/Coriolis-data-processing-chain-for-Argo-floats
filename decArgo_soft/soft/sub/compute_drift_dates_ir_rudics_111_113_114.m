% ------------------------------------------------------------------------------
% Compute the dates of drift measurements.
%
% SYNTAX :
%  [o_date] = compute_drift_dates_ir_rudics_111_113_114( ...
%    a_sensorNum, a_cycleNum, a_profNum, a_date, a_pressure)
%
% INPUT PARAMETERS :
%   a_sensorNum : sensor number
%   a_cycleNum  : cycle number
%   a_profNum   : profile number
%   a_date      : input dates
%   a_pressure  : drift measurement pressures
%
% OUTPUT PARAMETERS :
%   o_date : output dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_date] = compute_drift_dates_ir_rudics_111_113_114( ...
   a_sensorNum, a_firstPres, a_cycleNum, a_profNum, a_date, a_pressure)

% output parameters initialization
o_date = a_date;

% default values
global g_decArgo_dateDef;


% retrieve the sampling periods and the corresponding thresholds from the
% configuration
[driftSampPeriod, zoneThreshold] = ...
   config_get_drift_sampling_periods_ir_rudics(a_sensorNum, a_cycleNum, a_profNum);

% add date to drift measurement
idT = find(a_firstPres > zoneThreshold);
if (isempty(idT))
   zoneNum = 1;
else
   zoneNum = idT(end) + 1;
end

% float anomaly: if the drift measurement is present it should have been sampled
% in a zone where driftSampPeriod > 0 => look in surrounding zones
if ((driftSampPeriod(zoneNum) == -1) || (driftSampPeriod(zoneNum) == 0))
   [~, idMin] = min(abs(zoneThreshold-a_firstPres));
   % possible zoneNum are idMin and idMin + 1 check the value that have not been
   % checked
   if (zoneNum == idMin)
      zoneNum = idMin + 1;
   else
      zoneNum = idMin;
   end
end

if (~isnan(driftSampPeriod(zoneNum)) && ...
      (driftSampPeriod(zoneNum) ~= -1) && (driftSampPeriod(zoneNum) ~= 0))
   
   for id = 1:length(a_pressure)-1
            
      if (o_date(id) ~= g_decArgo_dateDef)
         o_date(id+1) = o_date(id) + driftSampPeriod(zoneNum);
      else
         break
      end
   end
end

return
