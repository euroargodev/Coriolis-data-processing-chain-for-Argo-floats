% ------------------------------------------------------------------------------
% Apply clock offset adjustment to RTC times.
%
% SYNTAX :
%  [o_surfDataLog, ...
%    o_pMarkDataLog, ...
%    o_driftData, o_parkData, ...
%    o_profLrData, ...
%    o_profEndAdjDateMsg, ...
%    o_nearSurfData, ...
%    o_surfDataBladderDeflated, o_surfDataBladderInflated, ...
%    o_timeDataLog] = ...
%    adjust_clock_offset_apx_ir_rudics(a_surfDataLog, ...
%    a_pMarkDataLog, ...
%    a_driftData, a_parkData, ...
%    a_profLrData, ...
%    a_profEndDateMsg, ...
%    a_nearSurfData, ...
%    a_surfDataBladderDeflated, a_surfDataBladderInflated, ...
%    a_timeDataLog, ...
%    a_clockOffsetData)
%
% INPUT PARAMETERS :
%   a_surfDataLog             : input surf data from log file
%   a_pMarkDataLog            : input P marks from log file
%   a_driftData               : input drift data
%   a_parkData                : input park data
%   a_profLrData              : input profile LR data
%   a_profEndDateMsg          : input profile end date
%   a_nearSurfData            : input NS data
%   a_surfDataBladderDeflated : input surface data
%   a_surfDataBladderInflated : input surface data
%   a_timeDataLog             : input cycle timings from log file
%   a_clockOffsetData         : clock offset information
%
% OUTPUT PARAMETERS :
%   o_surfDataLog             : output surf data from log file
%   o_pMarkDataLog            : output P marks from log file
%   o_driftData               : output drift data
%   o_parkData                : output park data
%   o_profLrData              : output profile LR data
%   o_profEndAdjDateMsg       : output profile end date
%   o_nearSurfData            : output NS data
%   o_surfDataBladderDeflated : output surface data
%   o_surfDataBladderInflated : output surface data
%   o_timeDataLog             : output cycle timings from log file
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_surfDataLog, ...
   o_pMarkDataLog, ...
   o_driftData, o_parkData, ...
   o_profLrData, ...
   o_profEndAdjDateMsg, ...
   o_nearSurfData, ...
   o_surfDataBladderDeflated, o_surfDataBladderInflated, ...
   o_timeDataLog] = ...
   adjust_clock_offset_apx_ir_rudics(a_surfDataLog, ...
   a_pMarkDataLog, ...
   a_driftData, a_parkData, ...
   a_profLrData, ...
   a_profEndDateMsg, ...
   a_nearSurfData, ...
   a_surfDataBladderDeflated, a_surfDataBladderInflated, ...
   a_timeDataLog, ...
   a_clockOffsetData)

% output parameters initialization
o_surfDataLog = a_surfDataLog;
o_pMarkDataLog = a_pMarkDataLog;
o_driftData = a_driftData;
o_parkData = a_parkData;
o_profLrData = a_profLrData;
o_profEndAdjDateMsg = [];
o_nearSurfData = a_nearSurfData;
o_surfDataBladderDeflated = a_surfDataBladderDeflated;
o_surfDataBladderInflated = a_surfDataBladderInflated;
o_timeDataLog = a_timeDataLog;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_clockOffsetData.clockoffsetCycleNum))
   return;
end

% clock adjustment of meas data of the current cycle
idF = find(a_clockOffsetData.clockSetCycleNum >= g_decArgo_cycleNum);
if (~isempty(idF))
   idF = idF(1);
else
   if (any(a_clockOffsetData.clockoffsetCycleNum{end} == g_decArgo_cycleNum))
      idF = length(a_clockOffsetData.clockoffsetCycleNum);
   else
      % RTC offset information not received yet for this cycle
      return;
   end
end
clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{idF};
clockoffsetValue = a_clockOffsetData.clockoffsetValue{idF};

[o_pMarkDataLog] = adjust_profile(o_pMarkDataLog, clockoffsetJuldUtc, clockoffsetValue);
[o_driftData] = adjust_profile(o_driftData, clockoffsetJuldUtc, clockoffsetValue);
[o_parkData] = adjust_profile(o_parkData, clockoffsetJuldUtc, clockoffsetValue);
[o_profLrData] = adjust_profile(o_profLrData, clockoffsetJuldUtc, clockoffsetValue);
[o_profEndAdjDateMsg] = adjust_time(a_profEndDateMsg, clockoffsetJuldUtc, clockoffsetValue);
for idSet = 1:length(o_nearSurfData)
   [o_nearSurfData{idSet}] = adjust_profile(o_nearSurfData{idSet}, clockoffsetJuldUtc, clockoffsetValue);
end
for idSet = 1:length(o_surfDataBladderDeflated)
   [o_surfDataBladderDeflated{idSet}] = adjust_profile(o_surfDataBladderDeflated{idSet}, clockoffsetJuldUtc, clockoffsetValue);
end
for idSet = 1:length(o_surfDataBladderInflated)
   [o_surfDataBladderInflated{idSet}] = adjust_profile(o_surfDataBladderInflated{idSet}, clockoffsetJuldUtc, clockoffsetValue);
end

% clock adjsutment of misc cycle times of the current cycle
if (~isempty(o_timeDataLog))
   [o_timeDataLog.cycleStartAdjDate] = adjust_time(o_timeDataLog.cycleStartDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.descentStartAdjDate] = adjust_time(o_timeDataLog.descentStartDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.descentStartAdjDateBis] = adjust_time(o_timeDataLog.descentStartDateBis, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.descentEndAdjDate] = adjust_time(o_timeDataLog.descentEndDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.parkStartAdjDate] = adjust_time(o_timeDataLog.parkStartDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.parkEndAdjDate] = adjust_time(o_timeDataLog.parkEndDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.parkEndMeas] = adjust_profile(o_timeDataLog.parkEndMeas, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.parkEndAdjDateBis] = adjust_time(o_timeDataLog.parkEndDateBis, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.ascentStartAdjDate] = adjust_time(o_timeDataLog.ascentStartDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.ascentEndAdjDate] = adjust_time(o_timeDataLog.ascentEndDate, clockoffsetJuldUtc, clockoffsetValue);
   [o_timeDataLog.ascentEnd2AdjDate] = adjust_time(o_timeDataLog.ascentEnd2Date, clockoffsetJuldUtc, clockoffsetValue);
end

% clock adjustment of information from the previous cycle
% some information may be sampled before or after clock set

% if (g_decArgo_cycleNum == 157)
%    a=1
% end

% clock adjustment of surface data (of the previous cycle)
if (~isempty(o_surfDataLog))
   
   if (~any(a_clockOffsetData.clockSetCycleNum == max(g_decArgo_cycleNum-1, 0)))
      
      idF = find(a_clockOffsetData.clockSetCycleNum >= max(g_decArgo_cycleNum-1, 0));
      if (~isempty(idF))
         idF = idF(1);
      else
         if (any(a_clockOffsetData.clockoffsetCycleNum{end} == max(g_decArgo_cycleNum-1, 0)))
            idF = length(a_clockOffsetData.clockoffsetCycleNum);
         else
            % RTC offset information not received yet for this cycle
            return;
         end
      end
      clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{idF};
      clockoffsetValue = a_clockOffsetData.clockoffsetValue{idF};
      
      % no clock set during the cycle
      if (~isempty(o_surfDataLog.dates))
         if (min(o_surfDataLog.dates) < min(clockoffsetJuldUtc))
            % first surface measurement prior to any clock check => we use the
            % first measured clock offset to adjust its time
            clockoffsetJuldUtc = [min(o_surfDataLog.dates)-clockoffsetValue(1)/86400 clockoffsetJuldUtc];
            clockoffsetValue = [clockoffsetValue(1) clockoffsetValue];
         end
      end
      [o_surfDataLog] = adjust_profile(o_surfDataLog, clockoffsetJuldUtc, clockoffsetValue);
   else
      
      % clock set occured during surface sample
      o_surfDataLog.datesAdj = ones(size(o_surfDataLog.dates))*o_surfDataLog.dateList.fillValue;
      setList = find(a_clockOffsetData.clockSetCycleNum == max(g_decArgo_cycleNum-1, 0));
      setList = [setList max(setList)+1];
      for idSet = 1:length(setList)
         clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{setList(idSet)};
         clockoffsetValue = a_clockOffsetData.clockoffsetValue{setList(idSet)};
         clockoffsetCycleNum = a_clockOffsetData.clockoffsetCycleNum{setList(idSet)};
         clockoffsetMtime = a_clockOffsetData.clockoffsetMtime{setList(idSet)};
         
         idForCy = find(clockoffsetCycleNum == max(g_decArgo_cycleNum-1, 0));
         if (idSet == 1)
            idForSet = find(o_surfDataLog.mTime < max(clockoffsetMtime(idForCy)));
         elseif (idSet ~= length(setList))
            idForSet = find((o_surfDataLog.mTime > min(clockoffsetMtime(idForCy))) & ...
               (o_surfDataLog.mTime < max(clockoffsetMtime(idForCy))));
         else
            idForSet = find((o_surfDataLog.mTime > min(clockoffsetMtime(idForCy))) & ...
               (o_surfDataLog.mTime < max(clockoffsetMtime(idForCy))));
            idDef = find((o_surfDataLog.datesAdj == o_surfDataLog.dateList.fillValue) & ...
               (o_surfDataLog.dates ~= o_surfDataLog.dateList.fillValue));
            if ((length(idForSet) ~= length(idDef)) || any(idForSet-idDef ~= 0))
               % clock set occured before the surface sample to be adjusted => we use the
               % last measured clock offset to adjust the surface sample
               clockoffsetJuldUtc = [clockoffsetJuldUtc(1) max(o_surfDataLog.dates)-clockoffsetValue(1)/86400 clockoffsetJuldUtc(2:end)];
               clockoffsetValue = [clockoffsetValue(1) clockoffsetValue(1) clockoffsetValue(2:end)];
               clockoffsetCycleNum = [clockoffsetCycleNum(1) max(g_decArgo_cycleNum-1, 0) clockoffsetCycleNum(2:end)];
               clockoffsetMtime = [clockoffsetMtime(1) max(o_surfDataLog.mTime) clockoffsetMtime(2:end)];
               idForCy = find(clockoffsetCycleNum == max(g_decArgo_cycleNum-1, 0));
               idForSet = find((o_surfDataLog.mTime > min(clockoffsetMtime(idForCy))) & ...
                  (o_surfDataLog.mTime <= max(clockoffsetMtime(idForCy))));
            end
         end
         if (~isempty(idForSet))
            surfDataLog = o_surfDataLog;
            surfDataLog.dates = o_surfDataLog.dates(idForSet);
            surfDataLog = adjust_profile(surfDataLog, clockoffsetJuldUtc, clockoffsetValue);
            o_surfDataLog.datesAdj(idForSet) = surfDataLog.datesAdj;
         end
      end
      
      % check that all dates have been adjusted
      idDef = find(o_surfDataLog.datesAdj == o_surfDataLog.dateList.fillValue);
      if (~isempty(idDef))
         if (any(o_surfDataLog.dates(idDef) ~= o_surfDataLog.dateList.fillValue))
            fprintf('WARNING: Float #%d Cycle #%d: some surf. meas. dates have not been adjusted\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
      end
   end
end

% clock adjustment misc cycle timings (of the previous cycle)
if (~isempty(o_timeDataLog) && ~isempty(o_timeDataLog.transStartDate))
   
   if (~any(a_clockOffsetData.clockSetCycleNum == max(g_decArgo_cycleNum-1, 0)))
      
      idF = find(a_clockOffsetData.clockSetCycleNum >= max(g_decArgo_cycleNum-1, 0));
      if (~isempty(idF))
         idF = idF(1);
      else
         if (any(a_clockOffsetData.clockoffsetCycleNum{end} == max(g_decArgo_cycleNum-1, 0)))
            idF = length(a_clockOffsetData.clockoffsetCycleNum);
         else
            % RTC offset information not received yet for this cycle
            return;
         end
      end
      clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{idF};
      clockoffsetValue = a_clockOffsetData.clockoffsetValue{idF};
      
      % no clock set during the cycle
      [o_timeDataLog.transStartAdjDate] = adjust_time(o_timeDataLog.transStartDate, clockoffsetJuldUtc, clockoffsetValue);
   else
      
      % clock set occured during the cycle
      setList = find(a_clockOffsetData.clockSetCycleNum == max(g_decArgo_cycleNum-1, 0));
      setList = [setList max(setList)+1];
      for idSet = 1:length(setList)
         clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{setList(idSet)};
         clockoffsetValue = a_clockOffsetData.clockoffsetValue{setList(idSet)};
         clockoffsetCycleNum = a_clockOffsetData.clockoffsetCycleNum{setList(idSet)};
         clockoffsetMtime = a_clockOffsetData.clockoffsetMtime{setList(idSet)};
         
         idForCy = find(clockoffsetCycleNum == max(g_decArgo_cycleNum-1, 0));
         if (idSet == 1)
            idForSet = find(o_timeDataLog.transStartDateMTime < max(clockoffsetMtime(idForCy)));
         elseif (idSet ~= length(setList))
            idForSet = find((o_timeDataLog.transStartDateMTime > min(clockoffsetMtime(idForCy))) & ...
               (o_timeDataLog.transStartDateMTime < max(clockoffsetMtime(idForCy))));
         else
            idForSet = find((o_timeDataLog.transStartDateMTime > min(clockoffsetMtime(idForCy))) & ...
               (o_timeDataLog.transStartDateMTime < max(clockoffsetMtime(idForCy))));
            if (isempty(idForSet))
               % clock set occured before the time to be adjusted => we use the
               % last measured clock offset to adjust the time
               clockoffsetJuldUtc = [clockoffsetJuldUtc(1) o_timeDataLog.transStartDate-clockoffsetValue(1)/86400 clockoffsetJuldUtc(2:end)];
               clockoffsetValue = [clockoffsetValue(1) clockoffsetValue(1) clockoffsetValue(2:end)];
               clockoffsetCycleNum = [clockoffsetCycleNum(1) max(g_decArgo_cycleNum-1, 0) clockoffsetCycleNum(2:end)];
               clockoffsetMtime = [clockoffsetMtime(1) o_timeDataLog.transStartDateMTime clockoffsetMtime(2:end)];
               idForCy = find(clockoffsetCycleNum == max(g_decArgo_cycleNum-1, 0));
               idForSet = find((o_timeDataLog.transStartDateMTime > min(clockoffsetMtime(idForCy))) & ...
                  (o_timeDataLog.transStartDateMTime <= max(clockoffsetMtime(idForCy))));
            end
         end
         if (~isempty(idForSet))
            [o_timeDataLog.transStartAdjDate] = adjust_time(o_timeDataLog.transStartDate, clockoffsetJuldUtc, clockoffsetValue);
         end
      end
      
      % check that the date has been adjusted
      if (isempty(o_timeDataLog.transStartAdjDate))
         fprintf('WARNING: Float #%d Cycle #%d: TST has not been adjusted\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   end
end

if (~isempty(o_timeDataLog) && ~isempty(o_timeDataLog.transEndDate))
   
   if (~any(a_clockOffsetData.clockSetCycleNum == max(g_decArgo_cycleNum-1, 0)))
      
      idF = find(a_clockOffsetData.clockSetCycleNum >= max(g_decArgo_cycleNum-1, 0));
      if (~isempty(idF))
         idF = idF(1);
      else
         if (any(a_clockOffsetData.clockoffsetCycleNum{end} == max(g_decArgo_cycleNum-1, 0)))
            idF = length(a_clockOffsetData.clockoffsetCycleNum);
         else
            % RTC offset information not received yet for this cycle
            return;
         end
      end
      clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{idF};
      clockoffsetValue = a_clockOffsetData.clockoffsetValue{idF};
      
      % no clock set during the cycle
      [o_timeDataLog.transEndAdjDate] = adjust_time(o_timeDataLog.transEndDate, clockoffsetJuldUtc, clockoffsetValue);
   else
      
      % clock set occured during surface sample
      setList = find(a_clockOffsetData.clockSetCycleNum == max(g_decArgo_cycleNum-1, 0));
      setList = [setList max(setList)+1];
      for idSet = 1:length(setList)
         clockoffsetJuldUtc = a_clockOffsetData.clockoffsetJuldUtc{setList(idSet)};
         clockoffsetValue = a_clockOffsetData.clockoffsetValue{setList(idSet)};
         clockoffsetCycleNum = a_clockOffsetData.clockoffsetCycleNum{setList(idSet)};
         clockoffsetMtime = a_clockOffsetData.clockoffsetMtime{setList(idSet)};
         
         idForCy = find(clockoffsetCycleNum == max(g_decArgo_cycleNum-1, 0));
         if (idSet == 1)
            idForSet = find(o_timeDataLog.transEndDateMTime < max(clockoffsetMtime(idForCy)));
         elseif (idSet ~= length(setList))
            idForSet = find((o_timeDataLog.transEndDateMTime > min(clockoffsetMtime(idForCy))) & ...
               (o_timeDataLog.transEndDateMTime < max(clockoffsetMtime(idForCy))));
         else
            idForSet = find((o_timeDataLog.transEndDateMTime > min(clockoffsetMtime(idForCy))) & ...
               (o_timeDataLog.transEndDateMTime < max(clockoffsetMtime(idForCy))));
            if (isempty(idForSet))
               % clock set occured before the time to be adjusted => we use the
               % last measured clock offset to adjust the time
               clockoffsetJuldUtc = [clockoffsetJuldUtc(1) o_timeDataLog.transStartDate-clockoffsetValue(1)/86400 clockoffsetJuldUtc(2:end)];
               clockoffsetValue = [clockoffsetValue(1) clockoffsetValue(1) clockoffsetValue(2:end)];
               clockoffsetCycleNum = [clockoffsetCycleNum(1) max(g_decArgo_cycleNum-1, 0) clockoffsetCycleNum(2:end)];
               clockoffsetMtime = [clockoffsetMtime(1) o_timeDataLog.transEndDateMTime clockoffsetMtime(2:end)];
               idForCy = find(clockoffsetCycleNum == max(g_decArgo_cycleNum-1, 0));
               idForSet = find((o_timeDataLog.transEndDateMTime > min(clockoffsetMtime(idForCy))) & ...
                  (o_timeDataLog.transEndDateMTime <= max(clockoffsetMtime(idForCy))));
            end
         end
         if (~isempty(idForSet))
            [o_timeDataLog.transEndAdjDate] = adjust_time(o_timeDataLog.transEndDate, clockoffsetJuldUtc, clockoffsetValue);
         end
      end
      
      % check that the date has been adjusted
      if (isempty(o_timeDataLog.transEndAdjDate))
         fprintf('WARNING: Float #%d Cycle #%d: TET has not been adjusted\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to times of a set of measurements.
%
% SYNTAX :
%  [o_profData] = adjust_profile(a_profData, o_juldUtc, o_clockOffset)
%
% INPUT PARAMETERS :
%   a_profData    : profile times to adjust
%   o_juldUtc     : list of adjustment dates
%   o_clockOffset : list of adjustment values
%
% OUTPUT PARAMETERS :
%   o_profData : adjusted profile times
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = adjust_profile(a_profData, o_juldUtc, o_clockOffset)

% output parameters initialization
o_profData = a_profData;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(o_profData))
   profDate = o_profData.dates;
   
   if (~isempty(profDate))
      o_profData.datesAdj = ones(size(o_profData.dates))*o_profData.dateList.fillValue;
      idNoDef = find(profDate ~= o_profData.dateList.fillValue);
      idOk = find((profDate(idNoDef) >= min((o_juldUtc+o_clockOffset/86400))) & ...
         (profDate(idNoDef) <= max((o_juldUtc+o_clockOffset/86400))));
      if (~isempty(idOk))
         clockOffsets = interp1q((o_juldUtc+o_clockOffset/86400)', o_clockOffset', profDate(idNoDef(idOk)));
         clockOffsets = round(clockOffsets); % adjustments rounded to 1 second
         o_profData.datesAdj(idNoDef(idOk)) = profDate(idNoDef(idOk)) - clockOffsets/86400;
      end
      
      if (any(o_profData.datesAdj == o_profData.dateList.fillValue))
         fprintf('WARNING: Float #%d Cycle #%d: some profile data times cannot be adjusted (set to FillValue)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to a given time.
%
% SYNTAX :
%  [o_timeAdj] = adjust_time(a_time, o_juldUtc, o_clockOffset)
%
% INPUT PARAMETERS :
%   a_time        : time to adjust
%   o_juldUtc     : list of adjustment dates
%   o_clockOffset : list of adjustment values
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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeAdj] = adjust_time(a_time, o_juldUtc, o_clockOffset)

% output parameters initialization
o_timeAdj = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (~isempty(a_time))
   clockOffsets = interp1q((o_juldUtc+o_clockOffset/86400)', o_clockOffset', a_time);
   clockOffsets = round(clockOffsets); % adjustments rounded to 1 second
   o_timeAdj = a_time - clockOffsets/86400;
   
   if (any(isnan(o_timeAdj)))
      fprintf('WARNING: Float #%d Cycle #%d: some time data cannot be adjusted (set to FillValue)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum);
      o_timeAdj = [];
   end
end

return;
