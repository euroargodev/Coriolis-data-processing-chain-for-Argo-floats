% ------------------------------------------------------------------------------
% Compute the main dates of this PROVOR float cycle.
%
% SYNTAX :
%  [o_cycleStartDate, ...
%    o_descentToParkStartDate, ...
%    o_firstStabDate, o_firstStabPres, ...
%    o_descentToParkEndDate, ...
%    o_descentToProfStartDate, ...
%    o_descentToProfEndDate, ...
%    o_ascentStartDate, ...
%    o_ascentEndDate, ...
%    o_transStartDate, ...
%    o_gpsDate, ...
%    o_lastResetDate, ...
%    o_firstGroundingDate, o_firstGroundingPres, ...
%    o_secondGroundingDate, o_secondGroundingPres, ...
%    o_eolStartDate, ...
%    o_firstEmergencyAscentDate, o_firstEmergencyAscentPres, ...
%    o_deepCycle] = ...
%    compute_prv_dates_210_211(a_tabTech1, a_tabTech2, a_irSessionNum)
%
% INPUT PARAMETERS :
%   a_tabTech1     : decoded data of technical msg #1
%   a_tabTech2     : decoded data of technical msg #2
%   a_irSessionNum : number of the Iridium session (1 or 2)
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate           : cycle start date
%   o_descentToParkStartDate   : descent to park start date
%   o_firstStabDate            : first stabilisation date
%   o_firstStabPres            : first stabilisation pressure
%   o_descentToParkEndDate     : descent to park end date
%   o_descentToProfStartDate   : descent to profile start date
%   o_descentToProfEndDate     : descent to profile end date
%   o_ascentStartDate          : ascent start date
%   o_ascentEndDate            : ascent end date
%   o_transStartDate           : transmission start date
%   o_gpsDate                  : date associated to the GPS location
%   o_lastResetDate            : date of the last reset of the float
%   o_firstGroundingDate       : first grounding date
%   o_firstGroundingPres       : first grounding pressure
%   o_secondGroundingDate      : second grounding date
%   o_secondGroundingPres      : second grounding pressure
%   o_eolStartDate             : EOL phase start date
%   o_firstEmergencyAscentDate : first emergency ascent ascent date
%   o_firstEmergencyAscentPres : first grounding pressure
%   o_deepCycle                : deep cycle flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/04/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate, ...
   o_descentToParkStartDate, ...
   o_firstStabDate, o_firstStabPres, ...
   o_descentToParkEndDate, ...
   o_descentToProfStartDate, ...
   o_descentToProfEndDate, ...
   o_ascentStartDate, ...
   o_ascentEndDate, ...
   o_transStartDate, ...
   o_gpsDate, ...
   o_lastResetDate, ...
   o_firstGroundingDate, o_firstGroundingPres, ...
   o_secondGroundingDate, o_secondGroundingPres, ...
   o_eolStartDate, ...
   o_firstEmergencyAscentDate, o_firstEmergencyAscentPres, ...
   o_deepCycle] = ...
   compute_prv_dates_210_211(a_tabTech1, a_tabTech2, a_irSessionNum)

% output parameters initialization
o_cycleStartDate = [];
o_descentToParkStartDate = [];
o_firstStabDate = [];
o_firstStabPres = [];
o_descentToParkEndDate = [];
o_descentToProfStartDate = [];
o_descentToProfEndDate = [];
o_ascentStartDate = [];
o_ascentEndDate = [];
o_transStartDate = [];
o_gpsDate = [];
o_lastResetDate = [];
o_firstGroundingDate = [];
o_firstGroundingPres = [];
o_secondGroundingDate = [];
o_secondGroundingPres = [];
o_eolStartDate = [];
o_firstEmergencyAscentDate = [];
o_firstEmergencyAscentPres = [];
o_deepCycle = 0;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


if (isempty(a_tabTech1) && isempty(a_tabTech1))
   return;
end

ID_OFFSET = 1;

cycleStartDateDay = g_decArgo_dateDef;

% technical message #1
idF1 = find(a_tabTech1(:, 1) == 0);
if (length(idF1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #1 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
elseif (length(idF1) == 1)
   
   id = idF1(1);
   
   o_gpsDate = a_tabTech1(id, end-3);
         
   if (a_irSessionNum == 1)
      
      startDateInfo = [a_tabTech1(id, (5:7)+ID_OFFSET) a_tabTech1(id, 9+ID_OFFSET)];
      if ~((length(unique(startDateInfo)) == 1) && (unique(startDateInfo) == 0))
         cycleStartDateDay = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, (5:7)+ID_OFFSET)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
         cycleStartHour = a_tabTech1(id, 9+ID_OFFSET);
         o_cycleStartDate = cycleStartDateDay + cycleStartHour/1440;
         o_deepCycle = 1;
      end
      
      if (~isempty(o_cycleStartDate))
         
         descentToParkStartHour = a_tabTech1(id, 13+ID_OFFSET);
         o_descentToParkStartDate = cycleStartDateDay + descentToParkStartHour/1440;
         if (o_descentToParkStartDate < o_cycleStartDate)
            o_descentToParkStartDate = o_descentToParkStartDate + 1;
         end
         
         o_firstStabPres = a_tabTech1(id, 18+ID_OFFSET);
         o_firstStabDate = o_descentToParkStartDate;
         if (o_firstStabPres ~= 0)
            firstStabHour = a_tabTech1(id, 14+ID_OFFSET);
            o_firstStabDate = cycleStartDateDay + firstStabHour/1440;
            if (o_firstStabDate < o_descentToParkStartDate)
               o_firstStabDate = o_firstStabDate + 1;
            end
         end
         
         % during the first deep cycle,the float may not set PST and DDST
         % (depending on MC04, MC05 configuration values)
         if ~((g_decArgo_cycleNum == 1) && ...
               (a_tabTech1(id, 13+ID_OFFSET) == a_tabTech1(id, 15+ID_OFFSET)) && ...
               (a_tabTech1(id, 15+ID_OFFSET) == a_tabTech1(id, 27+ID_OFFSET)))
            
            descentToParkEndHour = a_tabTech1(id, 15+ID_OFFSET);
            o_descentToParkEndDate = cycleStartDateDay + descentToParkEndHour/1440;
            if (o_descentToParkEndDate < o_firstStabDate)
               o_descentToParkEndDate = o_descentToParkEndDate + 1;
            end
            
            descentToParkEndGregDate = julian_2_gregorian_dec_argo(o_descentToParkEndDate);
            if (str2num(descentToParkEndGregDate(9:10)) ~= a_tabTech1(id, 20+ID_OFFSET))
               % if the cycle #1 is too short, the dates can be inconsistent
               newDescentToParkEndDate = o_descentToParkEndDate - 1;
               newDescentToParkEndGregDate = julian_2_gregorian_dec_argo(newDescentToParkEndDate);
               if (str2num(newDescentToParkEndGregDate(9:10)) == a_tabTech1(id, 20+ID_OFFSET))
                  o_descentToParkEndDate = newDescentToParkEndDate;
               else
                  fprintf('DEC_WARNING: Float #%d cycle #%d: DRIFT_PARK_START_TIME (%s) and drift at park start gregorian day (%d) are not consistent\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     descentToParkEndGregDate, a_tabTech1(id, 20+ID_OFFSET));
               end
            end
         end
      
         transStartHour = a_tabTech1(id, 39+ID_OFFSET);
         o_transStartDate = fix(o_gpsDate) +  transStartHour/1440;
         if (o_transStartDate > o_gpsDate)
            o_transStartDate = o_transStartDate - 1;
         end
         
         % The transmission start date is provided by the float
         % The ascend end date is considered at the crossing of the TC15 dbar
         % threshold, after that the float waits 10 minutes before:
         % 1- if IN AIR measurements are programmed:
         %     + sampling NEAR SURFACE data (MC31 minutes)
         %     + starting the final buoyancy acquisition (duration TC22 cseconds)
         %     + sampling IN AIR data (MC31 minutes)
         %     + starting transmission phase
         % 2- if no IN AIR measurements are programmed:
         %     + starting the final buoyancy acquisition (duration TC04 cseconds)
         %     + starting transmission phase
         
         % retrieve IN AIR acquisition cycle periodicity
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         inAirAcqPeriod = get_config_value('CONFIG_MC29_', configNames, configValues);
         if (mod(g_decArgo_cycleNum, inAirAcqPeriod) == 0)
            
            % cycle with IN AIR measurements
            inAirAcqDurationMin = get_config_value('CONFIG_MC31_', configNames, configValues);
            finalBuoyancyAcqSec = get_config_value('CONFIG_TC22_', configNames, configValues)/100;
            
            o_ascentEndDate = o_transStartDate - 10/1440 - inAirAcqDurationMin*2/1440 - finalBuoyancyAcqSec/86400;
         else
            
            % cycle without IN AIR measurements
            finalBuoyancyAcqSec = get_config_value('CONFIG_TC04_', configNames, configValues)/100;
            
            o_ascentEndDate = o_transStartDate - 10/1440 - finalBuoyancyAcqSec/86400;
         end
         
         ascentStartHour = a_tabTech1(id, 38+ID_OFFSET);
         o_ascentStartDate = fix(o_ascentEndDate) +  ascentStartHour/1440;
         if (o_ascentStartDate > o_ascentEndDate)
            o_ascentStartDate = o_ascentStartDate - 1;
         end
         
         descentToProfEndHour = a_tabTech1(id, 28+ID_OFFSET);
         o_descentToProfEndDate = fix(o_ascentStartDate) +  descentToProfEndHour/1440;
         if (o_descentToProfEndDate > o_ascentStartDate)
            o_descentToProfEndDate = o_descentToProfEndDate - 1;
         end
         
         % during the first deep cycle,the float may not set PST and DDST
         % (depending on MC04, MC05 configuration values)
         if ~((g_decArgo_cycleNum == 1) && ...
               (a_tabTech1(id, 13+ID_OFFSET) == a_tabTech1(id, 15+ID_OFFSET)) && ...
               (a_tabTech1(id, 15+ID_OFFSET) == a_tabTech1(id, 27+ID_OFFSET)))
            
            descentToProfStartHour = a_tabTech1(id, 27+ID_OFFSET);
            o_descentToProfStartDate = fix(o_descentToProfEndDate) +  descentToProfStartHour/1440;
            if (o_descentToProfStartDate > o_descentToProfEndDate)
               o_descentToProfStartDate = o_descentToProfStartDate - 1;
            end
         end
      end
   end
   
   if (a_tabTech1(id, 66+ID_OFFSET) == 1)
      o_eolStartDate = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, (67:72)+ID_OFFSET)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
   end
end
   
% technical message #2
idF2 = find(a_tabTech2(:, 1) == 4);
if (length(idF2) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #2 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF2));
elseif (length(idF2) == 1)
   
   id = idF2(1);
   
   if (a_irSessionNum == 1)
      
      if (a_tabTech2(id, 21+ID_OFFSET) > 0)
         firstGroundingTime = a_tabTech2(id, 23+ID_OFFSET) + a_tabTech2(id, 24+ID_OFFSET)/1440;
         o_firstGroundingDate = firstGroundingTime + g_decArgo_julD2FloatDayOffset;
         o_firstGroundingPres = a_tabTech2(id, 22+ID_OFFSET);
      end
      
      if (a_tabTech2(id, 21+ID_OFFSET) > 1)
         secondGroundingTime = a_tabTech2(id, 28+ID_OFFSET) + a_tabTech2(id, 29+ID_OFFSET)/1440;
         o_secondGroundingDate = secondGroundingTime + g_decArgo_julD2FloatDayOffset;
         o_secondGroundingPres = a_tabTech2(id, 27+ID_OFFSET);
      end
      
      if ((a_tabTech2(id, 32+ID_OFFSET) > 0) && (cycleStartDateDay ~= g_decArgo_dateDef))
         o_firstEmergencyAscentDate = a_tabTech2(id, 36+ID_OFFSET) + cycleStartDateDay;
         o_firstEmergencyAscentDate = o_firstEmergencyAscentDate + a_tabTech2(id, 33+ID_OFFSET)/1440;
         o_firstEmergencyAscentPres = a_tabTech2(id, 34+ID_OFFSET);
      end
   end
   
   o_lastResetDate = datenum(sprintf('%02d%02d%02d', a_tabTech2(id, (46:51)+ID_OFFSET)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
end         
      
print = 0;
if (print == 1)
   
   fprintf('Float #%d cycle #%d:\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   if (~isempty(o_cycleStartDate))
      fprintf('CYCLE START DATE           : %s\n', ...
         julian_2_gregorian_dec_argo(o_cycleStartDate));
   else
      fprintf('CYCLE START DATE           : UNDEF\n');
   end
   if (~isempty(o_descentToParkStartDate))
      fprintf('DESCENT TO PARK START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToParkStartDate));
   else
      fprintf('DESCENT TO PARK START DATE : UNDEF\n');
   end
   if (~isempty(o_firstStabDate))
      fprintf('FIRST STAB DATE            : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(o_firstStabDate), o_firstStabPres);
   else
      fprintf('FIRST STAB DATE            : UNDEF\n');
   end
   if (~isempty(o_descentToParkEndDate))
      fprintf('DESCENT TO PARK END DATE   : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToParkEndDate));
   else
      fprintf('DESCENT TO PARK END DATE   : UNDEF\n');
   end
   if (~isempty(o_descentToProfStartDate))
      fprintf('DESCENT TO PROF START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToProfStartDate));
   else
      fprintf('DESCENT TO PROF START DATE : UNDEF\n');
   end
   if (~isempty(o_descentToProfEndDate))
      fprintf('DESCENT TO PROF END DATE   : %s\n', ...
         julian_2_gregorian_dec_argo(o_descentToProfEndDate));
   else
      fprintf('DESCENT TO PROF END DATE   : UNDEF\n');
   end
   if (~isempty(o_ascentStartDate))
      fprintf('ASCENT START DATE          : %s\n', ...
         julian_2_gregorian_dec_argo(o_ascentStartDate));
   else
      fprintf('ASCENT START DATE          : UNDEF\n');
   end
   if (~isempty(o_ascentEndDate))
      fprintf('ASCENT END DATE            : %s\n', ...
         julian_2_gregorian_dec_argo(o_ascentEndDate));
   else
      fprintf('ASCENT END DATE            : UNDEF\n');
   end
   if (~isempty(o_transStartDate))
      fprintf('TRANSMISSION START DATE    : %s\n', ...
         julian_2_gregorian_dec_argo(o_transStartDate));
   else
      fprintf('TRANSMISSION START DATE    : UNDEF\n');
   end
   if (~isempty(o_gpsDate))
      fprintf('GPS DATE                   : %s\n', ...
         julian_2_gregorian_dec_argo(o_gpsDate));
   else
      fprintf('GPS DATE                   : UNDEF\n');
   end
   if (~isempty(o_lastResetDate))
      fprintf('LAST RESET DATE            : %s\n', ...
         julian_2_gregorian_dec_argo(o_lastResetDate));
   end   
   if (~isempty(o_firstGroundingDate))
      fprintf('FIRST GROUNDING DATE       : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(o_firstGroundingDate), o_firstGroundingPres);
   end
   if (~isempty(o_secondGroundingDate))
      fprintf('SECOND GROUNDING DATE      : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(o_secondGroundingDate), o_secondGroundingPres);
   end
   if (~isempty(o_eolStartDate))
      fprintf('EOL START DATE             : %s\n', ...
         julian_2_gregorian_dec_argo(o_eolStartDate));
   end
   if (~isempty(o_firstEmergencyAscentDate))
      fprintf('FIRST EMERGENCY ASCENT DATE: %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(o_firstEmergencyAscentDate), o_firstEmergencyAscentPres);
   end
end

return;
