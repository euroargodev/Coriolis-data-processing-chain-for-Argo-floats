% ------------------------------------------------------------------------------
% Apply clock offset adjustment to RTC times.
%
% SYNTAX :
%  [o_parkDateAdj, o_descProfDateAdj, o_ascProfDateAdj, ...
%    o_nearSurfDateAdj, o_inAirDateAdj, ...
%    o_evAct, o_pumpAct, o_cycleTimeData]= ...
%    adjust_clock_offset_prv_ir( ...
%    a_parkDate, a_descProfDate, a_ascProfDate, a_nearSurfDate, a_inAirDate, ...
%    a_evAct, a_pumpAct, a_cycleTimeData, a_clockOffsetData)
%
% INPUT PARAMETERS :
%   a_parkDate        : park measurement dates
%   a_descProfDate    : descending profile measurement dates
%   a_ascProfDate     : ascending profile measurement dates
%   a_nearSurfDate    : near surface measurement dates
%   a_inAirDate       : in air measurement dates
%   a_evAct           : valve actions
%   a_pumpAct         : pump actions
%   a_cycleTimeData   : cycle timings structure
%   a_clockOffsetData : clock offset information
%
% OUTPUT PARAMETERS :
%   o_parkDateAdj     : park measurement adjusted dates
%   o_descProfDateAdj : descending profile measurement adjusted dates
%   o_ascProfDateAdj  : ascending profile measurement adjusted dates
%   o_nearSurfDateAdj : near surface measurement adjusted dates
%   o_inAirDateAdj    : in air measurement adjusted dates
%   o_evAct           : valve actions
%   o_pumpAct         : pump actions
%   o_cycleTimeData   : cycle timings structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/06/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_parkDateAdj, o_descProfDateAdj, o_ascProfDateAdj, ...
   o_nearSurfDateAdj, o_inAirDateAdj, ...
   o_evAct, o_pumpAct, o_cycleTimeData]= ...
   adjust_clock_offset_prv_ir( ...
   a_parkDate, a_descProfDate, a_ascProfDate, a_nearSurfDate, a_inAirDate, ...
   a_evAct, a_pumpAct, a_cycleTimeData, a_clockOffsetData)

% output parameters initialization
o_parkDateAdj = a_parkDate;
o_descProfDateAdj = a_descProfDate;
o_ascProfDateAdj = a_ascProfDate;
o_nearSurfDateAdj = a_nearSurfDate;
o_inAirDateAdj = a_inAirDate;
o_evAct = a_evAct;
o_pumpAct = a_pumpAct;
o_cycleTimeData = a_cycleTimeData;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_clockOffsetData.cycleNum))
   return
end

% compute the clock offset to be used for the current cycle times
cycleClockOffset = get_clock_offset_value_prv_ir(a_clockOffsetData, o_cycleTimeData);

if (~isempty(cycleClockOffset))

   o_cycleTimeData.cycleClockOffset = cycleClockOffset;

   % adjust cycle measurements
   o_parkDateAdj = adjust_meas(a_parkDate, cycleClockOffset);
   o_descProfDateAdj = adjust_meas(a_descProfDate, cycleClockOffset);
   o_ascProfDateAdj = adjust_meas(a_ascProfDate, cycleClockOffset);
   o_nearSurfDateAdj = adjust_meas(a_nearSurfDate, cycleClockOffset);
   o_inAirDateAdj = adjust_meas(a_inAirDate, cycleClockOffset);
   
   % adjust hydraulic activity dates
   if (~isempty(o_evAct))
      o_evAct(:, 4) = adjust_hydrau(o_evAct(:, 3) + g_decArgo_julD2FloatDayOffset, cycleClockOffset);
   end
   if (~isempty(o_pumpAct))
      o_pumpAct(:, 4) = adjust_hydrau(o_pumpAct(:, 3) + g_decArgo_julD2FloatDayOffset, cycleClockOffset);
   end
   
   % adjust cycle timings
   [o_cycleTimeData] = adjust_times(o_cycleTimeData, cycleClockOffset);
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to times of a set of measurements.
%
% SYNTAX :
%  [o_measDateAdj] = adjust_meas(a_measDate, a_clockOffset)
%
% INPUT PARAMETERS :
%   a_measDate    : measurement times to adjust
%   a_clockOffset : clock offset to apply
%
% OUTPUT PARAMETERS :
%   o_measDateAdj : adjusted measurement times
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measDateAdj] = adjust_meas(a_measDate, a_clockOffset)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_measDateAdj = ones(size(a_measDate))*g_decArgo_dateDef;


idDated = find(a_measDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   o_measDateAdj(idDated) = a_measDate(idDated) - a_clockOffset/86400;
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to times of a set of hydraulic actions.
%
% SYNTAX :
%  [o_hydDateAdj] = adjust_hydrau(a_hydDate, a_clockOffset)
%
% INPUT PARAMETERS :
%   a_hydDate     : hydraulic action times to adjust
%   a_clockOffset : clock offset to apply
%
% OUTPUT PARAMETERS :
%   o_hydDateAdj : adjusted hydraulic action times
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_hydDateAdj] = adjust_hydrau(a_hydDate, a_clockOffset)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_hydDateAdj = ones(size(a_hydDate))*g_decArgo_dateDef;


% hydraulic times have a 1 minute resolution, we round the clock offset (in
% seconds) to the nearest minute
cycleClockOffset = round(a_clockOffset/60);

idDated = find(a_hydDate ~= g_decArgo_dateDef);
if (~isempty(idDated))
   o_hydDateAdj(idDated) = a_hydDate(idDated) - cycleClockOffset/14410;
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to float cycle timings.
%
% SYNTAX :
%  [o_cycleTimeData] = adjust_times(a_cycleTimeData, o_cycleClockOffset)
%
% INPUT PARAMETERS :
%   a_cycleTimeData : float cycle timings to adjust
%   a_clockOffset   : clock offset to apply
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : adjusted cycle timings
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData] = adjust_times(a_cycleTimeData, o_cycleClockOffset)

% output parameters initialization
o_cycleTimeData = a_cycleTimeData;

% cycle timings have a 1 minute resolution, we round the clock offset (in
% seconds) to the nearest minute
cycleClockOffset = round(o_cycleClockOffset/60);

o_cycleTimeData.cycleStartDateAdj = adjust_time(o_cycleTimeData.cycleStartDate, cycleClockOffset);
o_cycleTimeData.descentToParkStartDateAdj = adjust_time(o_cycleTimeData.descentToParkStartDate, cycleClockOffset);
o_cycleTimeData.firstStabDateAdj = adjust_time(o_cycleTimeData.firstStabDate, cycleClockOffset);
o_cycleTimeData.descentToParkEndDateAdj = adjust_time(o_cycleTimeData.descentToParkEndDate, cycleClockOffset);
o_cycleTimeData.descentToProfStartDateAdj = adjust_time(o_cycleTimeData.descentToProfStartDate, cycleClockOffset);
o_cycleTimeData.descentToProfEndDateAdj = adjust_time(o_cycleTimeData.descentToProfEndDate, cycleClockOffset);
o_cycleTimeData.ascentStartDateAdj = adjust_time(o_cycleTimeData.ascentStartDate, cycleClockOffset);
o_cycleTimeData.ascentEndDateAdj = adjust_time(o_cycleTimeData.ascentEndDate, cycleClockOffset);
o_cycleTimeData.transStartDateAdj = adjust_time(o_cycleTimeData.transStartDate, cycleClockOffset);
o_cycleTimeData.eolStartDateAdj = adjust_time(o_cycleTimeData.eolStartDate, cycleClockOffset);
o_cycleTimeData.firstGroundingDateAdj = adjust_time(o_cycleTimeData.firstGroundingDate, cycleClockOffset);
o_cycleTimeData.secondGroundingDateAdj = adjust_time(o_cycleTimeData.secondGroundingDate, cycleClockOffset);
o_cycleTimeData.firstEmergencyAscentDateAdj = adjust_time(o_cycleTimeData.firstEmergencyAscentDate, cycleClockOffset);

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to one float cycle timing.
%
% SYNTAX :
%  [o_timeAdj] = adjust_time(a_time, o_cycleClockOffset)
%
% INPUT PARAMETERS :
%   a_time        : float cycle timing to adjust
%   a_clockOffset : clock offset to apply
%
% OUTPUT PARAMETERS :
%   o_timeAdj : adjusted cycle timing
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/09/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeAdj] = adjust_time(a_time, o_cycleClockOffset)

% output parameters initialization
o_timeAdj = [];


if (~isempty(a_time))
   o_timeAdj = a_time - o_cycleClockOffset/1440;
end

return
