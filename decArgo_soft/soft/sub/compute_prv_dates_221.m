% ------------------------------------------------------------------------------
% Compute the main dates of this PROVOR float cycle.
%
% SYNTAX :
%  o_cycleTimeData = ...
%    compute_prv_dates_221(a_tabTech1, a_tabTech2, a_deepCycle, ...
%    a_iceDelayedCycleFlag, a_refDay, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_tabTech1            : decoded data of technical msg #1
%   a_tabTech2            : decoded data of technical msg #2
%   a_deepCycle           : deep cycle flag
%   a_iceDelayedCycleFlag : Ice delayed cycle flag
%   a_refDay              : reference day
%   a_cycleNum            : cycle number
%
% OUTPUT PARAMETERS :
%   o_cycleTimeData : cycle timings structure
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/06/2019 - RNU - creation
% ------------------------------------------------------------------------------
function o_cycleTimeData = ...
   compute_prv_dates_221(a_tabTech1, a_tabTech2, a_deepCycle, ...
   a_iceDelayedCycleFlag, a_refDay, a_cycleNum)

% output parameters initialization
o_cycleTimeData = get_prv_ir_float_time_init_struct(a_cycleNum);

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% list of cycle numbers and ice detection flag
global g_decArgo_cycleNumListForIce;
global g_decArgo_cycleNumListIceDetected;

% date of last ICE detection
global g_decArgo_lastDetectionDate;

% float configuration
global g_decArgo_floatConfig;

% maximum descent speed (in cm/s)
MAX_DESC_SPEED = 20;

% times and information to be set
cycleStartDate = [];
descentToParkStartDate = [];
firstStabDate = [];
firstStabPres = [];
descentToParkEndDate = [];
descentToProfStartDate = [];
descentToProfEndDate = [];
ascentStartDate = [];
ascentEndDate = [];
transStartDate = [];
gpsDate = [];
eolStartDate = [];
firstGroundingDate = [];
firstGroundingPres = [];
secondGroundingDate = [];
secondGroundingPres = [];
firstEmergencyAscentDate = [];
firstEmergencyAscentPres = [];
iceDetected = -1;


if ((a_deepCycle == 1) || (a_iceDelayedCycleFlag == 1))
   idFCy = find(g_decArgo_cycleNumListForIce == g_decArgo_cycleNum);
   if (isempty(idFCy))
      idFCy = length(g_decArgo_cycleNumListForIce) + 1;
   end
   g_decArgo_cycleNumListForIce(idFCy) = g_decArgo_cycleNum;
   g_decArgo_cycleNumListIceDetected(idFCy) = 0;
end

if (isempty(a_tabTech1) && isempty(a_tabTech2))
   return
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
   gpsDateVal = a_tabTech1(id1, end-3); % float time at the creation of the TECH packet
   iceDetectionFlag = a_tabTech2(id2, 43);
   if (iceDetectionFlag ~= 0)
      % ice has been detected by the float
      if (isempty(g_decArgo_lastDetectionDate) || (g_decArgo_lastDetectionDate < gpsDateVal))
         g_decArgo_lastDetectionDate = gpsDateVal;
      end
      iceDetected = 1;
   end
   
   % retrieve the PG0 configuration parameter
   if (iceDetected == -1)
      if (a_deepCycle == 1)
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         pg0Value = get_config_value('CONFIG_PG00', configNames, configValues);
         if (~isempty(pg0Value))
            if (gpsDateVal < g_decArgo_lastDetectionDate + pg0Value)
               iceDetected = 2;
            else
               iceDetected = 0;
            end
         end
      elseif (a_iceDelayedCycleFlag == 1) % there is no configuration for such cycle, look for the previous one
         cyNum = g_decArgo_cycleNum - 1;
         while (cyNum >= 0)
            if (any(g_decArgo_floatConfig.USE.CYCLE == cyNum))
               [configNames, configValues] = get_float_config_ir_sbd(cyNum);
               break
            end
            cyNum = cyNum - 1;
         end
         pg0Value = get_config_value('CONFIG_PG00', configNames, configValues);
         if (~isempty(pg0Value))
            if (gpsDateVal < g_decArgo_lastDetectionDate + pg0Value)
               iceDetected = 2;
            else
               iceDetected = 0;
            end
         end
      end
   end
   
   % check consitency with other information
   gpsValidFix = a_tabTech1(id1, 59);
   gpsSessionDuration = a_tabTech1(id1, 60);
   if ((gpsValidFix == 255) && (gpsSessionDuration == 0))
      if (iceDetected == 0)
         fprintf('INFO: Float #%d cycle #%d: the float did not try to reach the surface (still in the IC0 days period) (Ice detection flag: %d, GPS valid fix: %d, GPS session duration: %d)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            iceDetectionFlag, gpsValidFix, gpsSessionDuration);
      end
   end
elseif (~isempty(id1))
   gpsDateVal = a_tabTech1(id1, end-3); % float time at the creation of the TECH packet
   if (~isempty(g_decArgo_lastDetectionDate))
      % retrieve the PG0 configuration parameter
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      pg0Value = get_config_value('CONFIG_PG00', configNames, configValues);
      if (~isempty(pg0Value))
         if (gpsDateVal < g_decArgo_lastDetectionDate + pg0Value)
            iceDetected = 2;
         else
            iceDetected = 0;
         end
      end
   end
   
   % check consitency with other information
   gpsValidFix = a_tabTech1(id1, 59);
   gpsSessionDuration = a_tabTech1(id1, 60);
   if ((gpsValidFix == 255) && (gpsSessionDuration == 0))
      if (iceDetected == 0)
         fprintf('ERROR: Float #%d cycle #%d: ice detection information not consistent with TECH information (Ice detection: %d, GPS valid fix: %d, GPS session duration: %d)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            iceDetected, gpsValidFix, gpsSessionDuration);
      end
   end
elseif (~isempty(id2))
   iceDetectionFlag = a_tabTech2(id2, 43);
   if (iceDetectionFlag ~= 0)
      % ice has been detected by the float
      iceDetected = 1;
   end
end

% transmission session aborted during this cycle
if (iceDetected ~= 0)
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
      cycleStartDate = cycleStartDateDay + cycleStartHour/1440;
   end
   
   if (~isempty(cycleStartDate))
      descentToParkStartHour = a_tabTech1(id, 11);
      descentToParkStartDate = cycleStartDateDay + descentToParkStartHour/1440;
      if (descentToParkStartDate < cycleStartDate)
         descentToParkStartDate = descentToParkStartDate + 1;
      end
      
      firstStabPres = a_tabTech1(id, 16);
      firstStabDate = descentToParkStartDate;
      if (firstStabPres ~= 0)
         firstStabHour = a_tabTech1(id, 12);
         firstStabDate = cycleStartDateDay + firstStabHour/1440;
         if (firstStabDate < descentToParkStartDate)
            firstStabDate = firstStabDate + 1;
         end
         
         % the descent duration can be > 24 h (see 6901757 #7)
         nbDays = 0;
         while (a_tabTech1(id, 16)*100/((firstStabDate-descentToParkStartDate)*86400) > MAX_DESC_SPEED)
            firstStabDate = firstStabDate + 1;
            nbDays = nbDays + 1;
         end
         if (nbDays > 0)
            fprintf('INFO: Float #%d cycle #%d: %d day added to FIRST STAB DATE (the descent duration is > 24 h)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
         end
      end
      
      descentToParkEndHour = a_tabTech1(id, 13);
      descentToParkEndDate = cycleStartDateDay + descentToParkEndHour/1440;
      if (descentToParkEndDate < firstStabDate)
         descentToParkEndDate = descentToParkEndDate + 1;
      end
      
      % the descent duration can be > 24 h (see 6901757 #7)
      nbDays = 0;
      vertDist = abs(a_tabTech1(id, 16)-a_tabTech1(id, 17));
      while (vertDist*100/((descentToParkEndDate-firstStabDate)*86400) > MAX_DESC_SPEED)
         descentToParkEndDate = descentToParkEndDate + 1;
         nbDays = nbDays + 1;
      end
      if (nbDays > 0)
         fprintf('INFO: Float #%d cycle #%d: %d day added to DESCENT TO PARK END DATE (the descent duration is > 24 h)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
      end
      
      descentToParkEndGregDate = julian_2_gregorian_dec_argo(descentToParkEndDate);
      if (str2num(descentToParkEndGregDate(9:10)) ~= a_tabTech1(id, 18))
         fprintf('DEC_WARNING: Float #%d cycle #%d: DRIFT_PARK_START_TIME (%s) and drift at park start gregorian day (%d) are not consistent\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            descentToParkEndGregDate, a_tabTech1(id, 18));
      end
   end
   
   gpsDate = a_tabTech1(id, end-3);
   
   if (~isempty(cycleStartDate))
      
      transStartHour = a_tabTech1(id, 37);
      transStartDate = fix(gpsDate) +  transStartHour/1440;
      if (transStartDate > gpsDate)
         transStartDate = transStartDate - 1;
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
         
         ascentEndDate = transStartDate - 10/1440 - inAirAcqDurationMin*2/1440 - round(finalBuoyancyAcqSec/60)/1440;
      else
         
         % cycle without IN AIR measurements
         finalBuoyancyAcqSec = get_config_value('CONFIG_PT04', configNames, configValues)/100;
         
         ascentEndDate = transStartDate - 10/1440 - round(finalBuoyancyAcqSec/60)/1440;
      end
      
      ascentStartHour = a_tabTech1(id, 36);
      ascentStartDate = fix(ascentEndDate) +  ascentStartHour/1440;
      if (ascentStartDate > ascentEndDate)
         ascentStartDate = ascentStartDate - 1;
      end
      
      descentToProfEndHour = a_tabTech1(id, 26);
      descentToProfEndDate = fix(ascentStartDate) +  descentToProfEndHour/1440;
      if (descentToProfEndDate > ascentStartDate)
         descentToProfEndDate = descentToProfEndDate - 1;
      end
      
      descentToProfStartHour = a_tabTech1(id, 25);
      descentToProfStartDate = fix(descentToProfEndDate) +  descentToProfStartHour/1440;
      if (descentToProfStartDate > descentToProfEndDate)
         descentToProfStartDate = descentToProfStartDate - 1;
      end
      
      % the descent duration can be > 24 h (see 6901757 #7)
      if (a_tabTech1(id, 29) > 0) % a_tabTech1(id, 29) == 0 means that it is not set because the float didn't wait at profile pressure
         nbDays = 0;
         vertDist = abs(a_tabTech1(id, 29)-(a_tabTech1(id, 21)+a_tabTech1(id, 22))/2);
         while (vertDist*100/((descentToProfEndDate-descentToProfStartDate)*86400) > MAX_DESC_SPEED)
            descentToProfStartDate = descentToProfStartDate - 1;
            nbDays = nbDays + 1;
         end
         if (nbDays > 0)
            fprintf('INFO: Float #%d cycle #%d: %d day substracted to DESCENT TO PROF START DATE (the descent duration is > 24 h)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
         end
      end
   end
   
   if (a_tabTech1(id, 64) > 0)
      eolStartDate = datenum(sprintf('%02d%02d%02d', a_tabTech1(id, 65:70)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
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
      
      if (~isempty(cycleStartDate))
         firstGroundingDate = fix(cycleStartDate) + a_tabTech2(id, 19) + a_tabTech2(id, 20)/1440;
      end
      firstGroundingPres = a_tabTech2(id, 18);
   end
   
   if (a_tabTech2(id, 17) > 1)
      
      if (~isempty(cycleStartDate))
         secondGroundingDate = fix(cycleStartDate) + a_tabTech2(id, 24) + a_tabTech2(id, 25)/1440;
      end
      secondGroundingPres = a_tabTech2(id, 23);
   end

   if (a_tabTech2(id, 28) > 0)
      
      % manage possible roll over of first emergency ascent day
      firstEmergencyAscentDay = a_tabTech2(id, 32);
      if (~isempty(cycleStartDate))
         while ((a_refDay + firstEmergencyAscentDay + a_tabTech2(id, 29)/1440) < cycleStartDate)
            firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
         end
      end
      
      firstEmergencyAscentDate = a_refDay + firstEmergencyAscentDay + a_tabTech2(id, 29)/1440;
      firstEmergencyAscentPres = a_tabTech2(id, 30);
   end   
end

% fill output structure
o_cycleTimeData.cycleStartDate = cycleStartDate;
o_cycleTimeData.descentToParkStartDate = descentToParkStartDate;
o_cycleTimeData.firstStabDate = firstStabDate;
o_cycleTimeData.firstStabPres = firstStabPres;
o_cycleTimeData.descentToParkEndDate = descentToParkEndDate;
o_cycleTimeData.descentToProfStartDate = descentToProfStartDate;
o_cycleTimeData.descentToProfEndDate = descentToProfEndDate;
o_cycleTimeData.ascentStartDate = ascentStartDate;
o_cycleTimeData.ascentEndDate = ascentEndDate;
o_cycleTimeData.transStartDate = transStartDate;
o_cycleTimeData.gpsDate = gpsDate;
o_cycleTimeData.eolStartDate = eolStartDate;
o_cycleTimeData.firstGroundingDate = firstGroundingDate;
o_cycleTimeData.firstGroundingPres = firstGroundingPres;
o_cycleTimeData.secondGroundingDate = secondGroundingDate;
o_cycleTimeData.secondGroundingPres = secondGroundingPres;
o_cycleTimeData.firstEmergencyAscentDate = firstEmergencyAscentDate;
o_cycleTimeData.firstEmergencyAscentPres = firstEmergencyAscentPres;
o_cycleTimeData.iceDetected = iceDetected;

print = 0;
if (print == 1)
   
   fprintf('Float #%d cycle #%d:\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum);
   if (~isempty(cycleStartDate))
      fprintf('CYCLE START DATE           : %s\n', ...
         julian_2_gregorian_dec_argo(cycleStartDate));
   else
      fprintf('CYCLE START DATE           : UNDEF\n');
   end
   if (~isempty(descentToParkStartDate))
      fprintf('DESCENT TO PARK START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkStartDate));
   else
      fprintf('DESCENT TO PARK START DATE : UNDEF\n');
   end
   if (~isempty(firstStabDate))
      fprintf('FIRST STAB DATE            : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(firstStabDate), firstStabPres);
   else
      fprintf('FIRST STAB DATE            : UNDEF\n');
   end
   if (~isempty(descentToParkEndDate))
      fprintf('DESCENT TO PARK END DATE   : %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkEndDate));
   else
      fprintf('DESCENT TO PARK END DATE   : UNDEF\n');
   end
   if (~isempty(descentToProfStartDate))
      fprintf('DESCENT TO PROF START DATE : %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfStartDate));
   else
      fprintf('DESCENT TO PROF START DATE : UNDEF\n');
   end
   if (~isempty(descentToProfEndDate))
      fprintf('DESCENT TO PROF END DATE   : %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfEndDate));
   else
      fprintf('DESCENT TO PROF END DATE   : UNDEF\n');
   end
   if (~isempty(ascentStartDate))
      fprintf('ASCENT START DATE          : %s\n', ...
         julian_2_gregorian_dec_argo(ascentStartDate));
   else
      fprintf('ASCENT START DATE          : UNDEF\n');
   end
   if (~isempty(ascentEndDate))
      fprintf('ASCENT END DATE            : %s\n', ...
         julian_2_gregorian_dec_argo(ascentEndDate));
   else
      fprintf('ASCENT END DATE            : UNDEF\n');
   end
   if (~isempty(transStartDate))
      fprintf('TRANSMISSION START DATE    : %s\n', ...
         julian_2_gregorian_dec_argo(transStartDate));
   else
      fprintf('TRANSMISSION START DATE    : UNDEF\n');
   end
   if (~isempty(gpsDate))
      fprintf('GPS DATE                   : %s\n', ...
         julian_2_gregorian_dec_argo(gpsDate));
   else
      fprintf('GPS DATE                   : UNDEF\n');
   end
   if (~isempty(firstGroundingDate))
      fprintf('FIRST GROUNDING DATE       : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(firstGroundingDate), firstGroundingPres);
   end
   if (~isempty(secondGroundingDate))
      fprintf('SECOND GROUNDING DATE      : %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(secondGroundingDate), secondGroundingPres);
   end
   if (~isempty(eolStartDate))
      fprintf('EOL START DATE             : %s\n', ...
         julian_2_gregorian_dec_argo(eolStartDate));
   end
   if (~isempty(firstEmergencyAscentDate))
      fprintf('FIRST EMERGENCY ASCENT DATE: %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(firstEmergencyAscentDate), firstEmergencyAscentPres);
   end
end

return
