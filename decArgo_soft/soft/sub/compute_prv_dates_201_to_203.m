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
%    o_firstEmergencyAscentDate, o_firstEmergencyAscentPres] = ...
%    compute_prv_dates_201_to_203(a_tabTech, a_refDay)
%
% INPUT PARAMETERS :
%   a_tabTech : decoded technical data
%   a_refDay  : reference day
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
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
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
   o_firstEmergencyAscentDate, o_firstEmergencyAscentPres] = ...
   compute_prv_dates_201_to_203(a_tabTech, a_refDay)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% maximum descent speed (in cm/s)
MAX_DESC_SPEED = 20;


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


if (isempty(a_tabTech))
   return;
end

% technical message #1
idF1 = find(a_tabTech(:, 1) == 0);
if (length(idF1) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #1 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
elseif (length(idF1) == 1)
   
   id = idF1(1);

   cycleStartDateDay = g_decArgo_dateDef;
   startDateInfo = [a_tabTech(id, 3:5) a_tabTech(id, 7)];
   if ~((length(unique(startDateInfo)) == 1) && (unique(startDateInfo) == 0))
      cycleStartDateDay = datenum(sprintf('%02d%02d%02d', a_tabTech(id, 3:5)), 'ddmmyy') - g_decArgo_janFirst1950InMatlab;
      cycleStartHour = a_tabTech(id, 7);
      o_cycleStartDate = cycleStartDateDay + cycleStartHour/1440;
   end
   
   if (~isempty(o_cycleStartDate))
      descentToParkStartHour = a_tabTech(id, 11);
      o_descentToParkStartDate = cycleStartDateDay + descentToParkStartHour/1440;
      if (o_descentToParkStartDate < o_cycleStartDate)
         o_descentToParkStartDate = o_descentToParkStartDate + 1;
      end
      
      o_firstStabPres = a_tabTech(id, 16);
      o_firstStabDate = o_descentToParkStartDate;
      if (o_firstStabPres ~= 0)
         firstStabHour = a_tabTech(id, 12);
         o_firstStabDate = cycleStartDateDay + firstStabHour/1440;
         if (o_firstStabDate < o_descentToParkStartDate)
            o_firstStabDate = o_firstStabDate + 1;
         end
         
         % the descent duration can be > 24 h (see 6901757 #7)
         nbDays = 0;
         while (a_tabTech(id, 16)*100/((o_firstStabDate-o_descentToParkStartDate)*86400) > MAX_DESC_SPEED)
            o_firstStabDate = o_firstStabDate + 1;
            nbDays = nbDays + 1;
         end
         if (nbDays > 0)
            fprintf('INFO: Float #%d cycle #%d: %d day added to FIRST STAB DATE (the descent duration is > 24 h)\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
         end
      end
      
      descentToParkEndHour = a_tabTech(id, 13);
      o_descentToParkEndDate = cycleStartDateDay + descentToParkEndHour/1440;
      if (o_descentToParkEndDate < o_firstStabDate)
         o_descentToParkEndDate = o_descentToParkEndDate + 1;
      end
      
      % the descent duration can be > 24 h (see 6901757 #7)
      nbDays = 0;
      vertDist = abs(a_tabTech(id, 16)-a_tabTech(id, 17));
      while (vertDist*100/((o_descentToParkEndDate-o_firstStabDate)*86400) > MAX_DESC_SPEED)
         o_descentToParkEndDate = o_descentToParkEndDate + 1;
         nbDays = nbDays + 1;
      end
      if (nbDays > 0)
         fprintf('INFO: Float #%d cycle #%d: %d day added to DESCENT TO PARK END DATE (the descent duration is > 24 h)\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, nbDays);
      end
      
      descentToParkEndGregDate = julian_2_gregorian_dec_argo(o_descentToParkEndDate);
      if (str2num(descentToParkEndGregDate(9:10)) ~= a_tabTech(id, 18))
         fprintf('DEC_WARNING: Float #%d cycle #%d: DRIFT_PARK_START_TIME (%s) and drift at park start gregorian day (%d) are not consistent\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum, ...
            descentToParkEndGregDate, a_tabTech(id, 18));
      end
   end
   
   o_gpsDate = a_tabTech(id, end-3);
   
   if (~isempty(o_cycleStartDate))
      
      transStartHour = a_tabTech(id, 37);
      o_transStartDate = fix(o_gpsDate) +  transStartHour/1440;
      if (o_transStartDate > o_gpsDate)
         o_transStartDate = o_transStartDate - 1;
      end
      
      % The transmission start date is provided by the float
      % The ascend end date is considered at the crossing of the PT22 dbar
      % threshold, after that the float waits 10 minutes before starting the
      % final buoyancy acquisition (duration PT4 cseconds) and then starts
      % transmission
      
      % retrieve the pump duration during buoyancy acquisition from the configuration
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      PT4Seconds = get_config_value('CONFIG_PT04', configNames, configValues)/100;
      
      refDate = o_transStartDate;
      if (~isempty(PT4Seconds))
         
         o_ascentEndDate = o_transStartDate - 10/1440 - PT4Seconds/86400;
         refDate = o_ascentEndDate;
      else
         fprintf('WARNING: Float #%d cycle #%d: PT04 is unknown => AET cannot be computed\n', ...
            g_decArgo_floatNum, g_decArgo_cycleNum);
      end
         
      ascentStartHour = a_tabTech(id, 36);
      o_ascentStartDate = fix(refDate) +  ascentStartHour/1440;
      if (o_ascentStartDate > refDate)
         o_ascentStartDate = o_ascentStartDate - 1;
      end
      
      descentToProfEndHour = a_tabTech(id, 26);
      o_descentToProfEndDate = fix(o_ascentStartDate) +  descentToProfEndHour/1440;
      if (o_descentToProfEndDate > o_ascentStartDate)
         o_descentToProfEndDate = o_descentToProfEndDate - 1;
      end
      
      descentToProfStartHour = a_tabTech(id, 25);
      o_descentToProfStartDate = fix(o_descentToProfEndDate) +  descentToProfStartHour/1440;
      if (o_descentToProfStartDate > o_descentToProfEndDate)
         o_descentToProfStartDate = o_descentToProfStartDate - 1;
      end
      
      % the descent duration can be > 24 h (see 6901757 #7)
      if (a_tabTech(id, 29) > 0) % a_tabTech(id, 29) == 0 means that it is not set because the float didn't wait at profile pressure
         nbDays = 0;
         vertDist = abs(a_tabTech(id, 29)-(a_tabTech(id, 21)+a_tabTech(id, 22))/2);
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
   
   if ~((length(unique(a_tabTech(id, 65:70))) == 1) && (unique(a_tabTech(id, 65:70)) == 0))
      o_eolStartDate = datenum(sprintf('%02d%02d%02d', a_tabTech(id, 65:70)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
   end
   
end
   
% technical message #2
idF2 = find(a_tabTech(:, 1) == 4);
if (length(idF2) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message #2 in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF2));
elseif (length(idF2) == 1)
   
   id = idF2(1);

   if ~((length(unique(a_tabTech(id, 18:19))) == 1) && (unique(a_tabTech(id, 18:19)) == 0))
      
      % manage possible roll over of grounding day
      groundingDay = a_tabTech(id, 18);
      if (~isempty(o_cycleStartDate))
         while ((groundingDay + a_tabTech(id, 19)/1440 + g_decArgo_julD2FloatDayOffset) < o_cycleStartDate)
            groundingDay = groundingDay + 256;
         end
      end
      
      firstGroundingTime = groundingDay + a_tabTech(id, 19)/1440;
      o_firstGroundingDate = firstGroundingTime + g_decArgo_julD2FloatDayOffset;
      o_firstGroundingPres = a_tabTech(id, 17);
   end
   
   if ~((length(unique(a_tabTech(id, 23:24))) == 1) && (unique(a_tabTech(id, 23:24)) == 0))
      
      % manage possible roll over of grounding day
      groundingDay = a_tabTech(id, 23);
      if (~isempty(o_cycleStartDate))
         while ((groundingDay + a_tabTech(id, 24)/1440 + g_decArgo_julD2FloatDayOffset) < o_cycleStartDate)
            groundingDay = groundingDay + 256;
         end
      end
      
      secondGroundingTime = groundingDay + a_tabTech(id, 24)/1440;
      o_secondGroundingDate = secondGroundingTime + g_decArgo_julD2FloatDayOffset;
      o_secondGroundingPres = a_tabTech(id, 22);
   end

   if (a_tabTech(id, 27) > 0)
      
      % manage possible roll over of first emergency ascent day
      firstEmergencyAscentDay = a_tabTech(id, 31);
      if (~isempty(o_cycleStartDate))
         while ((a_refDay + firstEmergencyAscentDay + a_tabTech(id, 28)/1440) < o_cycleStartDate)
            firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
         end
      end
      
      o_firstEmergencyAscentDate = a_refDay + firstEmergencyAscentDay + a_tabTech(id, 28)/1440;
      o_firstEmergencyAscentPres = a_tabTech(id, 29);
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
