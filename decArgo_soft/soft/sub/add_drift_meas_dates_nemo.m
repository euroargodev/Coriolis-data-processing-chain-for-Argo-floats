% ------------------------------------------------------------------------------
% Add dates to drift measurements.
%
% SYNTAX :
%  [o_cycleTimeData, o_parkData] = add_drift_meas_dates_nemo(a_cycleTimeData, a_parkData)
%
% INPUT PARAMETERS :
%   a_cycleTimeData : input cycle timings
%   a_parkData      : input park data
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : output cycle timings
%   o_parkData      : output park data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData, o_parkData] = add_drift_meas_dates_nemo(a_cycleTimeData, a_parkData)

% output parameters initialization
o_cycleTimeData = a_cycleTimeData;
o_parkData = a_parkData;

% global default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(o_parkData.data) || isempty(o_cycleTimeData.parkStartDate))
   return
end

% the drift sampling period is supposed to be 1 day
driftSampPeriodDays = 1;

o_parkData.dateList = get_netcdf_param_attributes('JULD');
o_parkData.dates = ones(size(o_parkData.data, 1), 1)*g_decArgo_dateDef;
if (~isempty(o_cycleTimeData.parkStartAdjDate))
   o_parkData.datesAdj = ones(size(o_parkData.data, 1), 1)*g_decArgo_dateDef;
end
for idMeas = 1:size(o_parkData.data, 1)
   o_parkData.dates(idMeas) = o_cycleTimeData.parkStartDate + (idMeas-1)*driftSampPeriodDays;
   if (~isempty(o_cycleTimeData.parkStartAdjDate))
      o_parkData.datesAdj(idMeas) = o_cycleTimeData.parkStartAdjDate + (idMeas-1)*driftSampPeriodDays;
   end
end

o_cycleTimeData.parkDate = o_parkData.dates;
if (~isempty(o_parkData.datesAdj))
   o_cycleTimeData.parkAdjDate = o_parkData.datesAdj;
end
idPres = find(strcmp({o_parkData.paramList.name}, 'PRES') == 1, 1);
o_cycleTimeData.parkPres = o_parkData.data(:, idPres);
if (~isempty(o_parkData.dataAdj))
   o_cycleTimeData.parkAdjPres = o_parkData.dataAdj(:, idPres);
end

% check drift times consistency
if (~isempty(g_decArgo_outputCsvFileId))
   if (~isempty(o_cycleTimeData.upcastStartDate))
      idF = find(o_parkData.dates > o_cycleTimeData.upcastStartDate);
      if (~isempty(idF))
         fprintf('WARNING: Float #%d Cycle#%d: %d drift times are not consistent with PET (%s)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(idF), julian_2_gregorian_dec_argo(o_cycleTimeData.upcastStartDate));
      end
   end
   if (~isempty(o_cycleTimeData.upcastStartAdjDate))
      idF = find(o_parkData.datesAdj > o_cycleTimeData.upcastStartAdjDate);
      if (~isempty(idF))
         fprintf('WARNING: Float #%d Cycle#%d: %d ADJUSTED drift times are not consistent with PET (%s)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            length(idF), julian_2_gregorian_dec_argo(o_cycleTimeData.upcastStartAdjDate));
      end
   end
end
   
return
