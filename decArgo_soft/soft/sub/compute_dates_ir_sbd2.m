% ------------------------------------------------------------------------------
% Compute the dates of drift measurements.
%
% SYNTAX :
%  [o_date] = compute_dates_ir_sbd2( ...
%    a_sensorNum, a_cycleNum, a_profNum, a_date)
%
% INPUT PARAMETERS :
%   a_sensorNum : sensor number
%   a_cycleNum  : cycle number
%   a_profNum   : profile number
%   a_date      : input dates
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
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_date] = compute_dates_ir_sbd2( ...
   a_sensorNum, a_cycleNum, a_profNum, a_date)

% output parameters initialization
o_date = a_date;

% default values
global g_decArgo_dateDef;


% retrieve the sampling periods and the corresponding thresholds from the
% configuration
[driftSampPeriod] = ...
   config_get_drift_sampling_period_ir_sbd2(a_sensorNum, a_cycleNum, a_profNum);

if (driftSampPeriod ~= -1)
   
   % add date to drift measurement
   for id = 1:length(a_date)-1
      
      if (o_date(id) ~= g_decArgo_dateDef)
         o_date(id+1) = o_date(id) + driftSampPeriod;
      else
         break;
      end
   end
end

return;
