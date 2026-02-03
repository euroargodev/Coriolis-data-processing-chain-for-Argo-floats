% ------------------------------------------------------------------------------
% Apply clock offset adjustment to RTC times.
%
% SYNTAX :
% [o_desc2ParkProf, o_parkDriftProf, o_desc2ProfProf, o_profDriftProf, o_ascProf, o_inAirProf, ...
%   o_selfTest, o_tech1, o_tech2, o_eol, ...
%   o_cycleTimeData] = ...
%   adjust_clock_offset_pfv2( ...
%   a_desc2ParkProf, a_parkDriftProf, a_desc2ProfProf, a_profDriftProf, a_ascProf, a_inAirProf, ...
%   a_selfTest, a_tech1, a_tech2, a_eol, ...
%   a_cycleTimeData, a_clockOffsetData)
%
% INPUT PARAMETERS :
%   a_desc2ParkProf   : input desc2park profile data
%   a_parkDriftProf   : input parkDrift profile data
%   a_desc2ProfProf   : input desc2Prof profile data
%   a_profDriftProf   : input profDrift profile data
%   a_ascProf         : input asc profile data
%   a_inAirProf       : input inAir profile data
%   a_selfTest        : input self test tech data
%   a_tech1           : input tech #1 data
%   a_tech2           : input tech #2 data
%   a_eol             : input EOL tech data
%   a_cycleTimeData   : input cycle timings structure
%   a_clockOffsetData : clock offset information
%
% OUTPUT PARAMETERS :
%   o_desc2ParkProf : output desc2park profile data
%   o_parkDriftProf : output parkDrift profile data
%   o_desc2ProfProf : output desc2Prof profile data
%   o_profDriftProf : output profDrift profile data
%   o_ascProf       : output asc profile data
%   o_inAirProf     : output inAir profile data
%   o_selfTest      : output self test tech data
%   o_tech1         : output tech #1 data
%   o_tech2         : output tech #2 data
%   o_eol           : output EOL tech data
%   o_cycleTimeData : output cycle timings structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_desc2ParkProf, o_parkDriftProf, o_desc2ProfProf, o_profDriftProf, o_ascProf, o_inAirProf, ...
   o_selfTest, o_tech1, o_tech2, o_eol, ...
   o_cycleTimeData]= ...
   adjust_clock_offset_pfv2( ...
   a_desc2ParkProf, a_parkDriftProf, a_desc2ProfProf, a_profDriftProf, a_ascProf, a_inAirProf, ...
   a_selfTest, a_tech1, a_tech2, a_eol, ...
   a_cycleTimeData, a_clockOffsetData)

% output parameters initialization
o_desc2ParkProf = a_desc2ParkProf;
o_parkDriftProf = a_parkDriftProf;
o_desc2ProfProf = a_desc2ProfProf;
o_profDriftProf = a_profDriftProf;
o_ascProf = a_ascProf;
o_inAirProf = a_inAirProf;
o_selfTest = a_selfTest;
o_tech1 = a_tech1;
o_tech2 = a_tech2;
o_eol = a_eol;
o_cycleTimeData = a_cycleTimeData;

% transmission end time management
global g_decArgo_transTimes;


if (isempty(a_clockOffsetData.cycleNum))
   return
end

% compute the clock offset to be used for the current cycle times
cycleClockOffset = get_clock_offset_value_pfv2(a_clockOffsetData, o_cycleTimeData);

if (~isempty(cycleClockOffset))

   o_cycleTimeData.cycleClockOffset = cycleClockOffset;

   % adjust measurement times
   o_desc2ParkProf = adjust_meas_time(o_desc2ParkProf, cycleClockOffset, o_cycleTimeData.descentToParkStartDate); % constant time adjustment on the descending profile
   o_parkDriftProf = adjust_meas_time(o_parkDriftProf, cycleClockOffset, '');
   o_desc2ProfProf = adjust_meas_time(o_desc2ProfProf, cycleClockOffset, ''); % this profile will be stored in the TRAJ file not need to adjust times with a constant value
   o_profDriftProf = adjust_meas_time(o_profDriftProf, cycleClockOffset, '');
   o_ascProf = adjust_meas_time(o_ascProf, cycleClockOffset, o_cycleTimeData.ascentEndDate); % constant time adjustment on the ascending profile
   o_inAirProf = adjust_meas_time(o_inAirProf, cycleClockOffset, '');

   % adjust technical times
   o_selfTest = adjust_tech_time(o_selfTest, cycleClockOffset, 0); % adjust RTC self test
   o_tech1 = adjust_tech_time(o_tech1, cycleClockOffset, 1); % adjust TECH #1 times with 0 offset (drift < 1 sec)
   o_tech2 = adjust_tech_time(o_tech2, cycleClockOffset, 0); % adjust TECH #2 times with in interpolated offset value for times < GPS time, with 0 value otherwise
   o_eol = adjust_tech_time(o_eol, cycleClockOffset, 1); % adjust EOL times with 0 offset (drift < 1 sec) TO BE CONFIRMED

   % adjust cycle timings
   [o_cycleTimeData] = adjust_cycle_time(o_cycleTimeData);
   
   idF = find((g_decArgo_transTimes.cycleNum == o_cycleTimeData.cycleNum) & (g_decArgo_transTimes.techNum == 2));
   if (~isempty(idF))
      g_decArgo_transTimes.transStartTimeAdj(idF) = o_cycleTimeData.transStartDateAdj;
      g_decArgo_transTimes.cycleClockOffset = [g_decArgo_transTimes.cycleClockOffset; ...
         [o_cycleTimeData.cycleNum cycleClockOffset]];
   end
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to times of a set of measurements.
%
% SYNTAX :
% [o_measProfAdj] = adjust_meas_time(a_measProf, a_clockOffset, a_refDate, a_nullOffsetFlag)
%
% INPUT PARAMETERS :
%   a_measProf    : input profile measurements
%   a_clockOffset : clock offset information for the concerned cycle
%   a_refDate     : reference date to be used to compute the offset (when times
%                   should be adjusted using a constant offset)
%
% OUTPUT PARAMETERS :
%   o_measProfAdj : output profile measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_measProfAdj] = adjust_meas_time(a_measProf, a_clockOffset, a_refDate)

% output parameters initialization
o_measProfAdj = a_measProf;

for idP = 1:length(o_measProfAdj)
   prof = o_measProfAdj(idP);
   if (~isempty(prof.dates))
      if (any(prof.dates ~= prof.dateList.fillValue))
         idDates = find(prof.dates ~= prof.dateList.fillValue);
         profDatesAdj = adjust_time_pfv2(prof.dates(idDates), a_clockOffset, a_refDate);
         prof.datesAdj = prof.dates;
         prof.datesAdj(idDates) = profDatesAdj;
      end
   end
   o_measProfAdj(idP) = prof;
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to technical times.
%
% SYNTAX :
% [o_techAdj] = adjust_tech_time(a_tech, a_clockOffset, a_nullOffsetFlag)
%
% INPUT PARAMETERS :
%   a_tech           : input TECH data
%   a_clockOffset    : clock offset information for the concerned cycle
%   a_nullOffsetFlag : if 1 adjust the times with a null offset
%
% OUTPUT PARAMETERS :
%   o_techAdj : output TECH data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_techAdj] = adjust_tech_time(a_tech, a_clockOffset, a_nullOffsetFlag)

% output parameters initialization
o_techAdj = a_tech;


for idL = 1:size(o_techAdj, 1)
   % tabTech and tabTechTime times should not be adjusted
   % tabTechTraj, tabTechBuoy and tabTechSpy should be adjsuted
   for idSet = 1:3
      if (idSet == 1)
         inputData = o_techAdj{idL, 3}; % tabTechTraj
      elseif (idSet == 2)
         inputData = o_techAdj{idL, 4}; % tabTechBuoy
      elseif (idSet == 3)
         inputData = o_techAdj{idL, 5}; % tabTechSpy
      end
      if (isempty(inputData))
         continue
      end

      timeList = [inputData.julD];
      idF = find(~isnan(timeList));
      if (~a_nullOffsetFlag)
         timeListAdj = adjust_time_pfv2(timeList(idF)', a_clockOffset, '');
      else
         timeListAdj = timeList(idF)';
      end
      timeListAdj = num2cell(timeListAdj');
      [inputData(idF).julDAdj] = deal(timeListAdj{:});

      if (idSet == 1)
         o_techAdj{idL, 3} = inputData; % tabTechTraj
      elseif (idSet == 2)
         o_techAdj{idL, 4} = inputData; % tabTechBuoy
      elseif (idSet == 3)
         o_techAdj{idL, 5} = inputData; % tabTechSpy
      end
   end
end

return

% ------------------------------------------------------------------------------
% Apply clock offset adjustment to cycle timings.
%
% SYNTAX :
% [o_cycleTimeData] = adjust_cycle_time(a_cycleTimeData)
%
% INPUT PARAMETERS :
%   a_cycleTimeData : input cycle timings
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : output cycle timings
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/27/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleTimeData] = adjust_cycle_time(a_cycleTimeData)

% output parameters initialization
o_cycleTimeData = a_cycleTimeData;


cycleClockOffset = o_cycleTimeData.cycleClockOffset;

fieldList = [ ...
   {'cycleStartDate'} ...
   {'descentToParkStartDate'} ...
   {'firstStabDate'} ...
   {'descentToParkEndDate'} ...
   {'descentToProfStartDate'} ...
   {'descentToProfEndDate'} ...
   {'ascentStartDate'} ...
   {'ascentEndDate'} ...
   {'transStartDate'} ...
   ];
for id = 1:length(fieldList)
   if (~isnan(o_cycleTimeData.(fieldList{id})))
      o_cycleTimeData.([fieldList{id} 'Adj']) = adjust_time_pfv2(o_cycleTimeData.(fieldList{id}), cycleClockOffset, '');
   end
end

%  for o_cycleTimeData.transEndDateCyPrev it will be done in process_delayed_data_pfv2

fieldList = [ ...
   {'eolStartDate'} ...
   {'groundingDate'} ...
   {'emergencyAscentDate'} ...
   ];
for id = 1:length(fieldList)
   if (~isempty(o_cycleTimeData.(fieldList{id})))
      o_cycleTimeData.([fieldList{id} 'Adj']) = adjust_time_pfv2(o_cycleTimeData.(fieldList{id}), cycleClockOffset, '');
   end
end

return
