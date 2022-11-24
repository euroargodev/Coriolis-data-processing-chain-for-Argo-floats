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
%    o_eolStartDate, ...
%    o_firstGroundingDate, o_firstGroundingPres, ...
%    o_secondGroundingDate, o_secondGroundingPres, ...
%    o_firstEmergencyAscentDate, o_firstEmergencyAscentPres, ...
%    o_iceDetected] = ...
%    compute_prv_dates_216(a_tabTech1, a_tabTech2, a_deepCycle, a_refDay)
%
% INPUT PARAMETERS :
%   a_tabTech1  : decoded data of technical msg #1
%   a_tabTech2  : decoded data of technical msg #2
%   a_deepCycle : deep cycle flag
%   a_refDay    : reference day
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
%   o_eolStartDate             : EOL start date
%   o_firstGroundingDate       : first grounding date
%   o_firstGroundingPres       : first grounding pressure
%   o_secondGroundingDate      : second grounding date
%   o_secondGroundingPres      : second grounding pressure
%   o_firstEmergencyAscentDate : first emergency ascent ascent date
%   o_firstEmergencyAscentPres : first grounding pressure
%   o_iceDetected              : ice detected value (-1: no information,
%                                0: surfaced cycle, 1: ice detected, 2: no ice
%                                detected but end of profile and transmission
%                                session aborted because of ice algorithm)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/22/2017 - RNU - creation
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
   o_eolStartDate, ...
   o_firstGroundingDate, o_firstGroundingPres, ...
   o_secondGroundingDate, o_secondGroundingPres, ...
   o_firstEmergencyAscentDate, o_firstEmergencyAscentPres, ...
   o_iceDetected] = ...
   compute_prv_dates_216(a_tabTech1, a_tabTech2, a_deepCycle, a_refDay)

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
o_eolStartDate = [];
o_firstGroundingDate = [];
o_firstGroundingPres = [];
o_secondGroundingDate = [];
o_secondGroundingPres = [];
o_firstEmergencyAscentDate = [];
o_firstEmergencyAscentPres = [];
o_iceDetected = -1;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;

% date of last ICE detection
global g_decArgo_lastDetectionDate;

% maximum descent speed (in cm/s)
MAX_DESC_SPEED = 20;


if (a_deepCycle == 1)
   idFCy = find(g_decArgo_cycleNumListForIce == g_decArgo_cycleNum);
   if (isempty(idFCy))
      idFCy = length(g_decArgo_cycleNumListForIce) + 1;
   end
   g_decArgo_cycleNumListForIce(idFCy) = g_decArgo_cycleNum;
   g_decArgo_cycleNumListIceDetected(idFCy) = 0;
end

if (isempty(a_tabTech1) && isempty(a_tabTech2))
   return;
end

% ice detection determination
% technical message #1
id1 = [];
if (~isempty(a_tabTech1))
   idF1 = find(a_tabTech1(:, 1) == 0);
   if (length(idF1) == 1)
      id1 = idF1(1);
   end
end
% technical message #2
id2 = [];
if (~isempty(a_tabTech2))
   idF2 = find(a_tabTech2(:, 1) == 4);
   if (length(idF2) == 1)
      id2 = idF2(1);
   end
end
if (~isempty(id1) && ~isempty(id2))
   gpsDate = a_tabTech1(id1, end-3); % float time at the creation of the TECH packet
   iceDetectionFlag = a_tabTech2(id2, 43);
   if (iceDetectionFlag ~= 0)
      % ice has been detected by the float
      if (isempty(g_decArgo_lastDetectionDate) || (g_decArgo_lastDetectionDate < gpsDate))
         g_decArgo_lastDetectionDate = gpsDate;
      end
      o_iceDetected = 1;
   end
   
   % retrieve the IC0 configuration parameter
   if (o_iceDetected == -1)
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      pg0Value = get_config_value('CONFIG_PG00', configNames, configValues);
      if (gpsDate < g_decArgo_lastDetectionDate + pg0Value)
         o_iceDetected = 2;
      else
         o_iceDetected = 0;
      end
   end
   
   % check consitency with other information
   gpsValidFix = a_tabTech1(id1, 59);
   gpsSessionDuration = a_tabTech1(id1, 60);
   if ((gpsValidFix == 255) && (gpsSessionDuration == 0))
      if (o_iceDetected == 0)
         fprintf('ERROR: Float #%d cycle #%d: ice detection information not consistent with TECH information (Ice detection flag: %d, GPS valid fix: %d, GPS session duration: %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            iceDetectionFlag, gpsValidFix, gpsSessionDuration);
      end
   end
elseif (~isempty(id1))
   gpsDate = a_tabTech1(id1, end-3); % float time at the creation of the TECH packet
   if (~isempty(g_decArgo_lastDetectionDate))
      % retrieve the PG0 configuration parameter
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      pg0Value = get_config_value('CONFIG_PG00', configNames, configValues);
      if (gpsDate < g_decArgo_lastDetectionDate + pg0Value)
         o_iceDetected = 2;
      else
         o_iceDetected = 0;
      end
   end
   
   % check consitency with other information
   gpsValidFix = a_tabTech1(id1, 59);
   gpsSessionDuration = a_tabTech1(id1, 60);
   if ((gpsValidFix == 255) && (gpsSessionDuration == 0))
      if (o_iceDetected == 0)
         fprintf('ERROR: Float #%d cycle #%d: ice detection information not consistent with TECH information (Ice detection: %d, GPS valid fix: %d, GPS session duration: %s\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            o_iceDetected, gpsValidFix, gpsSessionDuration);
      end
   end
elseif (~isempty(id2))
   iceDetectionFlag = a_tabTech2(id2, 43);
   if (iceDetectionFlag ~= 0)
      % ice has been detected by the float
      o_iceDetected = 1;
   end
end

% transmission session aborted during this cycle
if (o_iceDetected ~= 0)
   idFCy = find(g_decArgo_cycleNumListForIce == g_decArgo_cycleNum);
   g_decArgo_cycleNumListIceDetected(idFCy) = 1;
end

% technical message #1
idF1 = find(a_tabTech1(:, 1) == 0);
if (length(idF1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #1 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
elseif (length(idF1) == 1)
   
   id = idF1(1);

   cycleStartDateDay = g_decArgo_dateDef;
   startDateInfo = [a_tabTech1(id, 3:5) a_tabTech1(id, 7)];
   if ~((length(unique(startDateInfo)) == 1) && (unique(startDateInfo) == 0))
      cycleStartDateDay = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, 3:5)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
      cycleStartHour = a_tabTech1(id, 7);
      o_cycleStartDate = cycleStartDateDay + cycleStartHour/1440;
   end
   
   if (~isempty(o_cycleStartDate))
      descentToParkStartHour = a_tabTech1(id, 11);
      o_descentToParkStartDate = cycleStartDateDay + descentToParkStartHour/1440;
      if (o_descentToParkStartDate < o_cycleStartDate)
         o_descentToParkStartDate = o_descentToParkStartDate + 1;
      end
      
      o_firstStabPres = a_tabTech1(id, 16);
      o_firstStabDate = o_descentToParkStartDate;
      if (o_firstStabPres ~= 0)
         firstStabHour = a_tabTech1(id, 12);
         o_firstStabDate = cycleStartDateDay + firstStabHour/1440;
         if (o_firstStabDate < o_descentToParkStartDate)
            o_firstStabDate = o_firstStabDate + 1;
         end
         
         % the descent duration can be > 24 h (see 6901757 #7)
         nbDays = 0;
         while (a_tabTech1(id, 16)*100/((o_firstStabDate-o_descentToParkStartDate)*86400) > MAX_DESC_SPEED)
            o_firstStabDate = o_firstStabDate + 1;
            nbDays = nbDays + 1;
         end
         if (nbDays > 0)
            fprintf('INFO: Float #%d cycle #%d: %d day added to FIRST STAB DATE (the descent duration is > 24 h)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
         end
      end
      
      descentToParkEndHour = a_tabTech1(id, 13);
      o_descentToParkEndDate = cycleStartDateDay + descentToParkEndHour/1440;
      if (o_descentToParkEndDate < o_firstStabDate)
         o_descentToParkEndDate = o_descentToParkEndDate + 1;
      end
      
      % the descent duration can be > 24 h (see 6901757 #7)
      nbDays = 0;
      vertDist = abs(a_tabTech1(id, 16)-a_tabTech1(id, 17));
      while (vertDist*100/((o_descentToParkEndDate-o_firstStabDate)*86400) > MAX_DESC_SPEED)
         o_descentToParkEndDate = o_descentToParkEndDate + 1;
         nbDays = nbDays + 1;
      end
      if (nbDays > 0)
         fprintf('INFO: Float #%d cycle #%d: %d day added to DESCENT TO PARK END DATE (the descent duration is > 24 h)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
      end
      
      descentToParkEndGregDate = julian_2_gregorian_dec_argo(o_descentToParkEndDate);
      if (str2num(descentToParkEndGregDate(9:10)) ~= a_tabTech1(id, 18))
         fprintf('DEC_WARNING: Float #%d cycle #%d: DRIFT_PARK_START_TIME (%s) and drift at park start gregorian day (%d) are not consistent\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            descentToParkEndGregDate, a_tabTech1(id, 18));
      end
   end
   
   o_gpsDate = a_tabTech1(id, end-3);
   
   if (~isempty(o_cycleStartDate))
      
      transStartHour = a_tabTech1(id, 37);
      o_transStartDate = fix(o_gpsDate) +  transStartHour/1440;
      if (o_transStartDate > o_gpsDate)
         o_transStartDate = o_transStartDate - 1;
      end
      
      % The transmission start date is provided by the float
      % The ascend end date is considered at the crossing of the PT22 dbar
      % threshold, after that the float waits 10 minutes before:
      % 1- if IN AIR measurements are programmed:
      %     + sampling NEAR SURFACE data (PT31 minutes)
      %     + starting the final buoyancy acquisition (duration PT32 cseconds)
      %     + sampling IN AIR data (PT31 minutes)
      %     + starting transmission phase
      % 2- if no IN AIR measurements are programmed:
      %     + starting the final buoyancy acquisition (duration PT4 cseconds)
      %     + starting transmission phase
      
      % retrieve IN AIR acquisition cycle periodicity
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      inAirAcqPeriod = get_config_value('CONFIG_PT33', configNames, configValues);
      if (mod(g_decArgo_cycleNum, inAirAcqPeriod) == 0)
         
         % cycle with IN AIR measurements
         inAirAcqDurationMin = get_config_value('CONFIG_PT31', configNames, configValues);
         finalBuoyancyAcqSec = get_config_value('CONFIG_PT32', configNames, configValues)/100;
         
         o_ascentEndDate = o_transStartDate - 10/1440 - inAirAcqDurationMin*2/1440 - finalBuoyancyAcqSec/86400;
      else
         
         % cycle without IN AIR measurements
         finalBuoyancyAcqSec = get_config_value('CONFIG_PT04', configNames, configValues)/100;
         
         o_ascentEndDate = o_transStartDate - 10/1440 - finalBuoyancyAcqSec/86400;
      end
      
      ascentStartHour = a_tabTech1(id, 36);
      o_ascentStartDate = fix(o_ascentEndDate) +  ascentStartHour/1440;
      if (o_ascentStartDate > o_ascentEndDate)
         o_ascentStartDate = o_ascentStartDate - 1;
      end
      
      descentToProfEndHour = a_tabTech1(id, 26);
      o_descentToProfEndDate = fix(o_ascentStartDate) +  descentToProfEndHour/1440;
      if (o_descentToProfEndDate > o_ascentStartDate)
         o_descentToProfEndDate = o_descentToProfEndDate - 1;
      end
      
      descentToProfStartHour = a_tabTech1(id, 25);
      o_descentToProfStartDate = fix(o_descentToProfEndDate) +  descentToProfStartHour/1440;
      if (o_descentToProfStartDate > o_descentToProfEndDate)
         o_descentToProfStartDate = o_descentToProfStartDate - 1;
      end
      
      % the descent duration can be > 24 h (see 6901757 #7)
      if (a_tabTech1(id, 29) > 0) % a_tabTech1(id, 29) == 0 means that it is not set because the float didn't wait at profile pressure
         nbDays = 0;
         vertDist = abs(a_tabTech1(id, 29)-(a_tabTech1(id, 21)+a_tabTech1(id, 22))/2);
         while (vertDist*100/((o_descentToProfEndDate-o_descentToProfStartDate)*86400) > MAX_DESC_SPEED)
            o_descentToProfStartDate = o_descentToProfStartDate - 1;
            nbDays = nbDays + 1;
         end
         if (nbDays > 0)
            fprintf('INFO: Float #%d cycle #%d: %d day substracted to DESCENT TO PROF START DATE (the descent duration is > 24 h)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
         end
      end
   end
   
   if (a_tabTech1(id, 64) > 0)
      o_eolStartDate = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, 65:70)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
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

   if (a_tabTech2(id, 17) > 0)
      
      % manage possible roll over of grounding day
      groundingDay = a_tabTech2(id, 19);
      if (~isempty(o_cycleStartDate))
         while ((groundingDay + a_tabTech2(id, 20)/1440 + g_decArgo_julD2FloatDayOffset) < o_cycleStartDate)
            groundingDay = groundingDay + 256;
         end
      end
      
      firstGroundingTime = groundingDay + a_tabTech2(id, 20)/1440;
      o_firstGroundingDate = firstGroundingTime + g_decArgo_julD2FloatDayOffset;
      o_firstGroundingPres = a_tabTech2(id, 18);
   end
   
   if (a_tabTech2(id, 17) > 1)
      
      % manage possible roll over of grounding day
      groundingDay = a_tabTech2(id, 24);
      if (~isempty(o_cycleStartDate))
         while ((groundingDay + a_tabTech2(id, 25)/1440 + g_decArgo_julD2FloatDayOffset) < o_cycleStartDate)
            groundingDay = groundingDay + 256;
         end
      end
      
      secondGroundingTime = groundingDay + a_tabTech2(id, 25)/1440;
      o_secondGroundingDate = secondGroundingTime + g_decArgo_julD2FloatDayOffset;
      o_secondGroundingPres = a_tabTech2(id, 23);
   end

   if (a_tabTech2(id, 28) > 0)
      
      % manage possible roll over of first emergency ascent day
      firstEmergencyAscentDay = a_tabTech2(id, 32);
      if (~isempty(o_cycleStartDate))
         while ((a_refDay + firstEmergencyAscentDay + a_tabTech2(id, 29)/1440) < o_cycleStartDate)
            firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
         end
      end
      
      o_firstEmergencyAscentDate = a_refDay + firstEmergencyAscentDay + a_tabTech2(id, 29)/1440;
      o_firstEmergencyAscentPres = a_tabTech2(id, 30);
   end   
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
