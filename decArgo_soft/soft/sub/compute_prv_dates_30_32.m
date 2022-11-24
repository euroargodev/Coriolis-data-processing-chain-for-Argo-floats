% ------------------------------------------------------------------------------
% Compute the main dates of a PROVOR float cycle.
%
% SYNTAX :
%  [o_cycleStartDate, o_descentStartDate, o_firstStabDate, o_descentEndDate, ...
%    o_descentToProfStartDate, o_descentToProfEndDate, ...
%    o_ascentStartDate, o_ascentEndDate, o_transStartDate, ...
%    o_firstGroundingDate, o_firstEmergencyAscentDate] = ...
%    compute_prv_dates_30_32(a_tabTech2, a_tabTech1, a_floatClockDrift, a_launchDate, ...
%    a_refDay, a_meanParkPres, a_maxProfPres, ...
%    a_firstArgosMsgDate, a_lastArgosCtdMsgDate, a_lastArgosMsgDateOfPrevCycle)
%
% INPUT PARAMETERS :
%   a_tabTech2                    : decoded technical #2 data
%   a_tabTech1                    : decoded technical #1 data
%   a_floatClockDrift             : float clock drift
%   a_launchDate                  : float launch date
%   a_refDay                      : reference day (day of the magnet removal)
%   a_meanParkPres                : mean of the drift measurement pressures
%   a_maxProfPres                 : deepest ascending profile measurement
%   a_firstArgosMsgDate           : date of the first Argos message received
%   a_lastArgosCtdMsgDate         : date of the last CTD Argos message received
%   a_lastArgosMsgDateOfPrevCycle : date of the last Argos message received at
%                                   the end of the previous cycle
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate           : cycle start date
%   o_descentStartDate         : descent start date
%   o_firstStabDate            : first stabilisation date
%   o_descentEndDate           : descent end date
%   o_descentToProfStartDate   : descent to profile start date
%   o_descentToProfEndDate     : descent to profile end date
%   o_ascentStartDate          : ascent start date
%   o_ascentEndDate            : ascent end date
%   o_transStartDate           : transmission start date
%   o_firstGroundingDate       : first grounding date
%   o_firstEmergencyAscentDate : first emergency date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate, o_descentStartDate, o_firstStabDate, o_descentEndDate, ...
   o_descentToProfStartDate, o_descentToProfEndDate, ...
   o_ascentStartDate, o_ascentEndDate, o_transStartDate, ...
   o_firstGroundingDate, o_firstEmergencyAscentDate] = ...
   compute_prv_dates_30_32(a_tabTech2, a_tabTech1, a_floatClockDrift, a_launchDate, ...
   a_refDay, a_meanParkPres, a_maxProfPres, ...
   a_firstArgosMsgDate, a_lastArgosCtdMsgDate, a_lastArgosMsgDateOfPrevCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% cycle anomaly flag
global g_decArgo_cycleAnomalyFlag;

% threshold pressure for float cycle anomaly
NO_DIVE_THRESHOLD = 10;

% default values
global g_decArgo_dateDef;

% configuration values
global g_decArgo_add3Min;


% output parameters initialization
o_cycleStartDate = g_decArgo_dateDef;
o_descentStartDate = g_decArgo_dateDef;
o_firstStabDate = g_decArgo_dateDef;
o_descentEndDate = g_decArgo_dateDef;
o_descentToProfStartDate = g_decArgo_dateDef;
o_descentToProfEndDate = g_decArgo_dateDef;
o_ascentStartDate = g_decArgo_dateDef;
o_ascentEndDate = g_decArgo_dateDef;
o_transStartDate = g_decArgo_dateDef;
o_firstGroundingDate = g_decArgo_dateDef;
o_firstEmergencyAscentDate = g_decArgo_dateDef;


% cycle anomaly flag
g_decArgo_cycleAnomalyFlag = 0;
if ((a_meanParkPres < NO_DIVE_THRESHOLD) || (a_maxProfPres < NO_DIVE_THRESHOLD))
   g_decArgo_cycleAnomalyFlag = 1;
   fprintf('DEC_WARNING: Float #%d Cycle #%d: cycle anomaly detected (the float stayed near the surface) => cycle dates can be inconsistent\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
end

% add and offset of 3 minutes to technical dates (given in tenths of an
% hour after truncation))
zeroOr3Min = 0;
if (g_decArgo_add3Min == 1)
   zeroOr3Min = 3/1440;
end

% delay (in minutes) between surfacing (10 dbar) and transmission start date
% for ARVOR floats
surf2TransDelay = 14;

% determination of transmission start date

% put first Argos message date in float time
firstArgosMsgdateInFloatTime = a_firstArgosMsgDate + a_floatClockDrift;
% convert first Argos message date in a truncated number of minutes
firstArgosDate = fix(firstArgosMsgdateInFloatTime) + ...
   ((floor(((firstArgosMsgdateInFloatTime-fix(firstArgosMsgdateInFloatTime))*1440)/1))*1)/1440;

o_transStartDate = fix(firstArgosDate) + a_tabTech2(20)/1440;
if (o_transStartDate > firstArgosDate)
   o_transStartDate = o_transStartDate - 1;
end

if (g_decArgo_cycleAnomalyFlag == 0)
   % determination of ascent end date
   o_ascentEndDate = o_transStartDate - surf2TransDelay/1440;
   
   % determination of ascent start date
   o_ascentStartDate = fix(o_ascentEndDate) + a_tabTech2(19)/1440;
   if (o_ascentStartDate > o_ascentEndDate)
      o_ascentStartDate = o_ascentStartDate - 1;
   end
else
   % determination of ascent start date
   o_ascentStartDate = fix(o_transStartDate) + a_tabTech2(19)/1440;
   if (o_ascentStartDate > o_transStartDate)
      o_ascentStartDate = o_ascentStartDate - 1;
   end
   
   % determination of ascent end date
   if (o_transStartDate - surf2TransDelay/1440 > o_ascentStartDate)
      o_ascentEndDate = o_transStartDate - surf2TransDelay/1440;
   else
      o_ascentEndDate = o_transStartDate;
   end
end

% BE CAREFUL:
% "descent to profile end date" has a 6 min resolution
% "descent to profile start date" has a 1 min resolution
% then if PARK == PROF these 2 dates can be chronologically incoherent
% Ex:
% 6902689	2	 Tech2	 Descent to profile depth start time	1144	 =>	 19:04:00
% 6902689	2	 Tech2	 Descent to profile depth stop time	190	 =>	 19:00:00

descentToProfStartMinute = a_tabTech2(14);
descentToProfEndMinute = a_tabTech2(15)*6;

% retrieve the drift and profile depths from the configuration
[configNames, configValues] = get_float_config_argos_2(g_decArgo_cycleNum);
driftDepth = get_config_value('CONFIG_MC010_', configNames, configValues);
profDepth = get_config_value('CONFIG_MC011_', configNames, configValues);
if (~isempty(driftDepth) && ~isempty(profDepth))

   if (driftDepth == profDepth)
      if ((descentToProfEndMinute < descentToProfStartMinute) && ...
            (descentToProfStartMinute - descentToProfEndMinute < 6))
         descentToProfEndMinute = descentToProfStartMinute;
      end
   end
end

% determination of descent to profile end date
o_descentToProfEndDate = fix(o_ascentStartDate) + descentToProfEndMinute/1440 + zeroOr3Min;
if (o_descentToProfEndDate > o_ascentStartDate)
   o_descentToProfEndDate = o_descentToProfEndDate - 1;
end

% determination of descent to profile start date
o_descentToProfStartDate = fix(o_descentToProfEndDate) + descentToProfStartMinute/1440;
if (o_descentToProfStartDate > o_descentToProfEndDate)
   o_descentToProfStartDate = o_descentToProfStartDate - 1;
end

% determination of cycle start date
firstDeepCycleNumber = 1;
if (g_decArgo_cycleNum > firstDeepCycleNumber)
   if (a_lastArgosMsgDateOfPrevCycle ~= g_decArgo_dateDef)
      % put last Argos message date of the previous cycle in float time
      lastArgosMsgDateOfPrevCycle = a_lastArgosMsgDateOfPrevCycle + a_floatClockDrift;
      % convert last Argos message date of the previous cycle in a truncated number of minutes
      lastArgosDateOfPrevCycle = fix(lastArgosMsgDateOfPrevCycle) + ...
         ((floor(((lastArgosMsgDateOfPrevCycle-fix(lastArgosMsgDateOfPrevCycle))*1440)/1))*1)/1440;
      
      o_cycleStartDate = fix(lastArgosDateOfPrevCycle) + a_tabTech2(5)/1440;
      if (o_cycleStartDate < lastArgosDateOfPrevCycle)
         o_cycleStartDate = o_cycleStartDate + 1;
      end
   else
      % compute the transmission start date of the previous cycle
      tmpDate = fix(a_firstArgosMsgDate) + a_tabTech2(27)*6/1440;
      [dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(tmpDate);
      transStartDateOfPrevCycle = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
         yyyy, mm, a_tabTech2(26), HH, MI, SS));
      if (transStartDateOfPrevCycle > a_firstArgosMsgDate)
         % the month of transmission start date of the previous cycle is differs
         % with the month of first Argos message date of the current cycle
         % under the asssumption of a cycle duration less than 15 days cycle,
         % removing 15 days to the current date will garantee a -1 shift of the
         % month
         tmpDate = tmpDate - 15;
         [dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(tmpDate);
         transStartDateOfPrevCycle = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
            yyyy, mm, a_tabTech2(26), HH, MI, SS));
      end
      
      % transmission end date of the previous cycle (AC3 is the min duration of
      % the Argos transmission)
      
      % retrieve the min duration of the Argos transmission from the
      % configuration
      [configNames, configValues] = get_float_config_argos_2(g_decArgo_cycleNum);
      minArgosTransDur = get_config_value('CONFIG_AC3_', configNames, configValues);
      if (~isempty(minArgosTransDur))
         transEndDateOfPrevCycle = transStartDateOfPrevCycle - minArgosTransDur/24;
      else
         % retrieve the current cycle duration (always exists)
         curCycleDur = get_config_value('CONFIG_MC002_', configNames, configValues);
         transEndDateOfPrevCycle = a_lastArgosCtdMsgDate - curCycleDur/24;
      end
      
      o_cycleStartDate = fix(transEndDateOfPrevCycle) + a_tabTech2(5)/1440;
      if (o_cycleStartDate < transEndDateOfPrevCycle)
         o_cycleStartDate = o_cycleStartDate + 1;
      end
   end
else
   % for the first deep cycle, the reference day is the day of the first descent
   o_cycleStartDate = fix(a_refDay) + a_tabTech2(5)/1440;
   
   % check consistency with launch date
   if (a_launchDate - (fix(a_refDay) + a_tabTech2(5)/1440) > 1/1440)
      nbDay = 1;
      while (a_launchDate - (fix(a_refDay) + a_tabTech2(5)/1440 + nbDay) > 1/1440)
         nbDay = nbDay + 1;
      end
      fprintf('DEC_WARNING: Float #%d Cycle #%d: launch date > cycle start date => %d day added to theoretical cycle start date (based on ref day)\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, nbDay);
      o_cycleStartDate = o_cycleStartDate + nbDay;
   end
   
   nbDay = floor(o_cycleStartDate - a_launchDate);
   if (nbDay > 0)
      fprintf('DEC_WARNING: Float #%d Cycle #%d: cycle start date too far from launch date => %d day substracted to descent start date\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, nbDay);
      o_cycleStartDate = o_cycleStartDate - nbDay;
   end
end

% check consitency of cycle start date with tech msg #2 information
[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(o_cycleStartDate);
if ((a_tabTech2(3) ~= dd) || (a_tabTech2(4) ~= mm))
   newCycleStartDate = gregorian_2_julian_dec_argo(sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
      yyyy, a_tabTech2(4), a_tabTech2(3), HH, MI, SS));
   fprintf('WARNING: Float #%d Cycle #%d: computed cycle start date (%s) doesn''t match technical information ((DD/MM) = (%02d/%02d)) => cycle start date set to %s\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      julian_2_gregorian_dec_argo(o_cycleStartDate), ...
      a_tabTech2(3), a_tabTech2(4), ...
      julian_2_gregorian_dec_argo(newCycleStartDate));
   o_cycleStartDate = newCycleStartDate;
end

% compute first grounding date
if ((o_cycleStartDate ~= g_decArgo_dateDef) && ~isempty(a_tabTech1))
   if (a_tabTech1(18) > 0)

      % manage possible roll over of first grounding day
      firstGroundingDay = a_tabTech1(15);
      while ((fix(o_cycleStartDate) + firstGroundingDay + a_tabTech1(16)*6/1440) < o_cycleStartDate)
         firstGroundingDay = firstGroundingDay + 16;
      end
      
      o_firstGroundingDate = fix(o_cycleStartDate) + firstGroundingDay + a_tabTech1(16)*6/1440;
   end
end

% compute first emergency ascent date
if ((o_cycleStartDate ~= g_decArgo_dateDef) && ~isempty(a_tabTech1))
   if (a_tabTech1(43) > 0)
      
      % manage possible roll over of first emergency ascent day
      firstEmergencyAscentDay = a_tabTech1(47);
      while ((fix(o_cycleStartDate) + firstEmergencyAscentDay + a_tabTech1(44)*6/1440) < o_cycleStartDate)
         firstEmergencyAscentDay = firstEmergencyAscentDay + 16;
      end
      
      o_firstEmergencyAscentDate = fix(o_cycleStartDate) + firstEmergencyAscentDay + a_tabTech1(44)*6/1440;
   end
end

% determination of descent start date
o_descentStartDate = fix(o_cycleStartDate) + a_tabTech2(6)/1440;
if (o_descentStartDate < o_cycleStartDate)
   o_descentStartDate = o_descentStartDate + 1;
end

% determination of descent end date
o_descentEndDate = fix(o_descentStartDate) + a_tabTech2(8)/1440;
if (o_descentEndDate < o_descentStartDate)
   o_descentEndDate = o_descentEndDate + 1;
end

% check the consistency of the park drift start day (gregorian calendar)
% provided in the tech msg #2
[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(o_descentEndDate);
if (dd ~= a_tabTech2(11))
   fprintf('WARNING: Float #%d Cycle #%d: the day (in the gregorian calendar) of the park drift start date (%d) differs with the one provided in the tech msg #2 (%d)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      dd, a_tabTech2(11));
end

% determination of first stabilisation date
o_firstStabDate = fix(o_descentStartDate) + a_tabTech2(7)*6/1440 + zeroOr3Min;
if (o_firstStabDate < o_descentStartDate)
   o_firstStabDate = o_firstStabDate + 1;
end

print = 0;
if (print == 1)
   floatClockDrift = round(a_floatClockDrift*1440)/1440;
   fprintf('Float #%d cycle #%d:\n', g_decArgo_floatNum, g_decArgo_cycleNum);
   fprintf('CLOCK FLOAT DRIFT         : %s => %s\n', ...
      format_time_dec_argo(a_floatClockDrift*24), ...
      format_time_dec_argo(floatClockDrift*24));
   fprintf('CYCLE START DATE          : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_cycleStartDate), ...
      julian_2_gregorian_dec_argo(o_cycleStartDate-floatClockDrift));
   fprintf('DESCENT START DATE        : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentStartDate), ...
      julian_2_gregorian_dec_argo(o_descentStartDate-floatClockDrift));
   fprintf('FIRST STAB DATE           : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_firstStabDate), ...
      julian_2_gregorian_dec_argo(o_firstStabDate-floatClockDrift));
   fprintf('DESCENT END DATE          : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentEndDate), ...
      julian_2_gregorian_dec_argo(o_descentEndDate-floatClockDrift));
   fprintf('DESCENT TO PROF START DATE: %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentToProfStartDate), ...
      julian_2_gregorian_dec_argo(o_descentToProfStartDate-floatClockDrift));
   fprintf('DESCENT TO PROF END DATE  : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_descentToProfEndDate), ...
      julian_2_gregorian_dec_argo(o_descentToProfEndDate-floatClockDrift));
   fprintf('ASCENT START DATE         : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_ascentStartDate), ...
      julian_2_gregorian_dec_argo(o_ascentStartDate-floatClockDrift));
   fprintf('ASCENT END DATE           : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_ascentEndDate), ...
      julian_2_gregorian_dec_argo(o_ascentEndDate-floatClockDrift));
   fprintf('TRANS START DATE          : %s => %s\n', ...
      julian_2_gregorian_dec_argo(o_transStartDate), ...
      julian_2_gregorian_dec_argo(o_transStartDate-floatClockDrift));
end

return;
