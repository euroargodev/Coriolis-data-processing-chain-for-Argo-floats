% ------------------------------------------------------------------------------
% Apply clock offset adjustment to RTC times and counter based times.
%
% SYNTAX :
%  [o_clockOffsetInfo, o_cycleClockOffsetCounter, o_cycleClockOffsetRtc, ...
%    o_rafosData, o_profileData, o_cycleTimeData] = ...
%    adjust_clock_offset_nemo(a_rafosData, a_profileData, a_cycleTimeData, ...
%    a_clockOffsetData)   
%
% INPUT PARAMETERS :
%   a_rafosData       : input RAFOS data
%   a_profileData     : input profile data
%   a_cycleTimeData   : input cycle timings
%   a_clockOffsetData : input clock offset information
%
% OUTPUT PARAMETERS :
%   o_clockOffsetInfo         : output clock offset information
%   o_cycleClockOffsetCounter : clock offset for counter based times
%   o_cycleClockOffsetRtc     : clock offset for RTC based times
%   o_rafosData               : output RAFOS data
%   o_profileData             : output profile data
%   o_cycleTimeData           : output cycle timings
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_clockOffsetInfo, o_cycleClockOffsetCounter, o_cycleClockOffsetRtc, ...
   o_rafosData, o_profileData, o_cycleTimeData] = ...
   adjust_clock_offset_nemo(a_rafosData, a_profileData, a_cycleTimeData, ...
   a_clockOffsetData)   
   
% output parameters initialization
o_clockOffsetInfo = [];
o_cycleClockOffsetCounter = [];
o_cycleClockOffsetRtc = [];
o_rafosData = a_rafosData;
o_profileData = a_profileData;
o_cycleTimeData = a_cycleTimeData;

% output CSV file Id
global g_decArgo_outputCsvFileId;


if (isempty(a_clockOffsetData.clockOffsetJuldUtc))
   return
end

% clock offset of the current cycle
[o_cycleClockOffsetCounter, o_cycleClockOffsetRtc] = ...
   get_clock_offset_value_nemo(a_clockOffsetData, a_cycleTimeData);
% report information in CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   if (~isempty(o_cycleClockOffsetCounter))
      dataStruct = get_apx_misc_data_init_struct('Clock offset (counter)', [], [], []);
      dataStruct.label = 'CLOCK offset value (counter)';
      dataStruct.value = o_cycleClockOffsetCounter;
      dataStruct.format = '%d';
      dataStruct.unit = 'second';
      o_clockOffsetInfo{end+1} = dataStruct;
   else
      dataStruct = get_apx_misc_data_init_struct('Clock offset (counter)', [], [], []);
      dataStruct.label = 'COUNTER CLOCK OFFSET VALUE CANNOT BE DETERMINED';
      o_clockOffsetInfo{end+1} = dataStruct;
   end
   
   if (~isempty(o_cycleClockOffsetRtc))
      dataStruct = get_apx_misc_data_init_struct('Clock offset (RTC)', [], [], []);
      dataStruct.label = 'CLOCK offset value (RTC)';
      dataStruct.value = o_cycleClockOffsetRtc;
      dataStruct.format = '%d';
      dataStruct.unit = 'second';
      o_clockOffsetInfo{end+1} = dataStruct;
   else
      dataStruct = get_apx_misc_data_init_struct('Clock offset (RTC)', [], [], []);
      dataStruct.label = 'RTC CLOCK OFFSET VALUE CANNOT BE DETERMINED';
      o_clockOffsetInfo{end+1} = dataStruct;
   end
end

% clock adjustment of rafos and profile measurements
if (~isempty(o_cycleClockOffsetRtc))
   if (~isempty(o_rafosData))
      o_rafosData = adjust_profile(o_rafosData, o_cycleClockOffsetRtc);
      o_cycleTimeData.rafosAdjDate = o_rafosData.datesAdj;
   end
   if (~isempty(o_profileData))
      o_profileData = adjust_profile(o_profileData, o_cycleClockOffsetRtc);
      o_cycleTimeData.profileAdjDate = o_profileData.datesAdj;
   end
end

% clock adjustment of misc cycle times
if (~isempty(o_cycleClockOffsetCounter))
   o_cycleTimeData.descentStartAdjDate = adjust_time(o_cycleTimeData.descentStartDate, o_cycleClockOffsetCounter);
   o_cycleTimeData.parkStartAdjDate = adjust_time(o_cycleTimeData.parkStartDate, o_cycleClockOffsetCounter);
   o_cycleTimeData.upcastStartAdjDate = adjust_time(o_cycleTimeData.upcastStartDate, o_cycleClockOffsetCounter);
   o_cycleTimeData.ascentStartAdjDate = adjust_time(o_cycleTimeData.ascentStartDate, o_cycleClockOffsetCounter);
   o_cycleTimeData.ascentEndAdjDate = adjust_time(o_cycleTimeData.ascentEndDate, o_cycleClockOffsetCounter);
   o_cycleTimeData.surfaceStartAdjDate = adjust_time(o_cycleTimeData.surfaceStartDate, o_cycleClockOffsetCounter);
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to times of a set of measurements.
%
% SYNTAX :
%  [o_profData] = adjust_profile(a_profData, a_clockOffset)
%
% INPUT PARAMETERS :
%   a_profData    : profile times to adjust
%   a_clockOffset : clock offset to apply
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = adjust_profile(a_profData, a_clockOffset)

% output parameters initialization
o_profData = a_profData;


if (~isempty(o_profData))
   profDate = o_profData.dates;
   
   if (~isempty(profDate))
      o_profData.datesAdj = ones(size(o_profData.dates))*o_profData.dateList.fillValue;
      idNoDef = find(profDate ~= o_profData.dateList.fillValue);
      o_profData.datesAdj(idNoDef) = profDate(idNoDef) - a_clockOffset/86400;
   end
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to a given time.
%
% SYNTAX :
%  [o_timeAdj] = adjust_time(a_time, a_clockOffset)
%
% INPUT PARAMETERS :
%   a_time        : time to adjust
%   a_clockOffset : clock offset to apply
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
%   02/03/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_timeAdj] = adjust_time(a_time, a_clockOffset)

% output parameters initialization
o_timeAdj = [];


if (~isempty(a_time))
   o_timeAdj = a_time - a_clockOffset/86400;
end

return
