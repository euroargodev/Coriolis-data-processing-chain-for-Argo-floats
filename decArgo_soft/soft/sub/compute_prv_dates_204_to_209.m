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
%    o_firstGroundingDate, o_firstGroundingPres, ...
%    o_firstEmergencyAscentDate, o_firstEmergencyAscentPres, o_refDay] = ...
%    compute_prv_dates_204_to_209(a_tabTech, a_deepCycle, a_refDay, ...
%    a_lastMsgDateOfPrevCycle, a_launchDate, a_dataCTDX)
%
% INPUT PARAMETERS :
%   a_tabTech                : decoded technical data
%   a_deepCycle              : deep cycle flag
%   a_refDay                 : reference day
%   a_lastMsgDateOfPrevCycle : last time of the messages received during the
%                              previous cycle
%   a_launchDate             : launch date
%   a_dataCTDX               : decoded CTD or CTDO data
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
%   o_firstGroundingDate       : first grounding date
%   o_firstGroundingPres       : first grounding pressure
%   o_firstEmergencyAscentDate : first emergency ascent ascent date
%   o_firstEmergencyAscentPres : first grounding pressure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/11/2015 - RNU - creation
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
   o_firstGroundingDate, o_firstGroundingPres, ...
   o_firstEmergencyAscentDate, o_firstEmergencyAscentPres, o_refDay] = ...
   compute_prv_dates_204_to_209(a_tabTech, a_deepCycle, a_refDay, ...
   a_lastMsgDateOfPrevCycle, a_launchDate, a_dataCTDX)

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
o_firstGroundingDate = [];
o_firstGroundingPres = [];
o_firstEmergencyAscentDate = [];
o_firstEmergencyAscentPres = [];
o_refDay = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;


if (isempty(a_tabTech))
   return;
end

refDay = a_refDay;
% technical message
idF = find(a_tabTech(:, 1) == 0);
if (length(idF) > 1)
   fprintf('ERROR: Float #%d cycle #%d: BUFFER anomaly (%d tech message in the buffer)\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF));
elseif (length(idF) == 1)
   
   id = idF(1);
   
   if (a_deepCycle == 1)
      
      if (a_lastMsgDateOfPrevCycle ~= g_decArgo_dateDef)
         
         o_cycleStartDate = fix(a_lastMsgDateOfPrevCycle) + a_tabTech(id, 4)/1440;
         
         %          fprintf('@; WMO:; %d; CYCLE_NUMBER:; %d; CLOCK DRIFT:; %s; CLOCK ANOMALY:; %s\n', ...
         %             g_decArgo_floatNum, g_decArgo_cycleNum, ...
         %             format_time_dec_argo((a_tabTech(id, end-3)-a_tabTech(id, end))*1440), ...
         %             format_time_dec_argo((a_lastMsgDateOfPrevCycle-o_cycleStartDate)*1440));

         if (o_cycleStartDate < (floor(a_lastMsgDateOfPrevCycle*1440)/1440))
            o_cycleStartDate = o_cycleStartDate + round((floor(a_lastMsgDateOfPrevCycle*1440)/1440)-o_cycleStartDate);
            % we cannot do o_cycleStartDate = o_cycleStartDate + 1 because clock
            % drift is not zero for some floats (Ex: 2902127) and cycle start
            % date can be < last msg date of previous floats
         end
         
      else
         
         % retrieve the last message time of the current cycle
         [~, lastMsgDateOfCycle] = ...
            compute_first_last_msg_time_from_iridium_mail(g_decArgo_iridiumMailData, g_decArgo_cycleNum);
         
         % retrieve the current cycle duration from the configuration
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         cycleDurationDays = get_config_value('CONFIG_PM01', configNames, configValues);
         
         if ((lastMsgDateOfCycle ~= g_decArgo_dateDef) && ~isnan(cycleDurationDays))
         
            % compute the estimate of the last message time of the previous
            % cycle
            estLastMsgDateOfPrevCycle = lastMsgDateOfCycle - cycleDurationDays;
            estLastMsgDateOfPrevCycle = floor(estLastMsgDateOfPrevCycle*1440)/1440;
            o_cycleStartDate = fix(estLastMsgDateOfPrevCycle) + a_tabTech(id, 4)/1440;
            if (o_cycleStartDate < estLastMsgDateOfPrevCycle)
               o_cycleStartDate = o_cycleStartDate + 1;
            end
            
            % when the prelude phase has not been received, the first deep cycle
            % dates should refer to float launch date (because the first deep
            % cycle is usually shorter than the following ones)
            % to correct o_cycleStartDate we use o_descentToParkStartDate
            % because o_cycleStartDate can be before launch date whereas
            % o_descentToParkStartDate is set when the float crosses the PT8
            % isobar
            o_descentToParkStartDate = fix(o_cycleStartDate) + a_tabTech(id, 6)/1440;
            if (o_descentToParkStartDate < o_cycleStartDate)
               o_descentToParkStartDate = o_descentToParkStartDate + 1;
            end
            corrected = 0;
            while (o_descentToParkStartDate < a_launchDate)
               o_descentToParkStartDate = o_descentToParkStartDate + 1;
               corrected = 1;
            end
            if (corrected == 1)
               while (o_descentToParkStartDate > o_cycleStartDate)
                  o_cycleStartDate = o_cycleStartDate + 1;
               end
               o_cycleStartDate = o_cycleStartDate - 1;
            end
         end
      end
      
      if (~isempty(o_cycleStartDate))
         
         o_descentToParkStartDate = fix(o_cycleStartDate) + a_tabTech(id, 6)/1440;
         if (o_descentToParkStartDate < o_cycleStartDate)
            o_descentToParkStartDate = o_descentToParkStartDate + 1;
         end
         
         o_firstStabDate = fix(o_descentToParkStartDate) + a_tabTech(id, 7)/1440;
         if (o_firstStabDate < o_descentToParkStartDate)
            o_firstStabDate = o_firstStabDate + 1;
         end
         o_firstStabPres = a_tabTech(id, 11);
         
         o_descentToParkEndDate = fix(o_firstStabDate) + a_tabTech(id, 8)/1440;
         if (o_descentToParkEndDate < o_firstStabDate)
            o_descentToParkEndDate = o_descentToParkEndDate + 1;
         end
         
         o_gpsDate = a_tabTech(id, end-3);
         
         o_transStartDate = fix(o_gpsDate) +  a_tabTech(id, 31)/1440;
         if (o_transStartDate > o_gpsDate)
            o_transStartDate = o_transStartDate - 1;
         end
         
         % The transmission start date is provided by the float
         % The ascend end date is considered at the crossing of a given pressure (end
         % of pump actions), after that the float waits 10 minutes before starting the
         % final buoyancy acquisition (duration PT4 cseconds) and then starts
         % transmission
         
         % retrieve the pump duration during buoyancy acquisition from the configuration
         [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
         PT4Seconds = get_config_value('CONFIG_PT04', configNames, configValues)/100;
         
         if (~isnan(PT4Seconds))
            
            o_ascentEndDate = o_transStartDate - 10/1440 - PT4Seconds/86400;
            
            o_ascentStartDate = fix(o_ascentEndDate) +  a_tabTech(id, 30)/1440;
            if (o_ascentStartDate > o_ascentEndDate)
               o_ascentStartDate = o_ascentStartDate - 1;
            end
            
            o_descentToProfEndDate = fix(o_ascentStartDate) +  a_tabTech(id, 20)/1440;
            if (o_descentToProfEndDate > o_ascentStartDate)
               o_descentToProfEndDate = o_descentToProfEndDate - 1;
            end
            
            o_descentToProfStartDate = fix(o_descentToProfEndDate) +  a_tabTech(id, 19)/1440;
            if (o_descentToProfStartDate > o_ascentStartDate)
               o_descentToProfStartDate = o_descentToProfStartDate - 1;
            end
         end
         
         % check refDay consistency before using it
         if (~isempty(o_transStartDate) && ~isempty(a_dataCTDX))
            
            % retrieve ascent dates
            idAsc = find((a_dataCTDX(:, 1) == 3) | ...
               (a_dataCTDX(:, 1) == 10) | ...
               (a_dataCTDX(:, 1) == 13) | ...
               (a_dataCTDX(:, 1) == 16));
            if (~isempty(idAsc))
               dates = [];
               for idP = 1:length(idAsc)
                  data = a_dataCTDX(idAsc(idP), :);
                  dates = [dates; data(2)];
               end
               expRefDate = round(o_transStartDate-max(dates));
               if (expRefDate ~= refDay)
                  fprintf('WARNING: Float #%d cycle #%d: reference day changed to %s (instead of %s)\n', ...
                     g_decArgo_floatNum, g_decArgo_cycleNum, ...
                     julian_2_gregorian_dec_argo(expRefDate), ...
                     julian_2_gregorian_dec_argo(refDay));
                  refDay = expRefDate;
               end
            end
         end
         
         if (a_tabTech(id, 55) == 1)
            modulo = round(abs(o_cycleStartDate - (refDay + a_tabTech(id, 57) + a_tabTech(id, 58)/1440))/256);
            o_firstGroundingDate = refDay + a_tabTech(id, 57) + a_tabTech(id, 58)/1440 + modulo*256;
            o_firstGroundingPres = a_tabTech(id, 56);
         end
         
         if (a_tabTech(id, 59) > 0)
            modulo = round(abs(o_cycleStartDate - (refDay + a_tabTech(id, 63) + a_tabTech(id, 60)/1440))/256);
            o_firstEmergencyAscentDate = refDay + a_tabTech(id, 63) + a_tabTech(id, 60)/1440 + modulo*256;
            o_firstEmergencyAscentPres = a_tabTech(id, 61);
         end
      end
   else
      
      o_gpsDate = a_tabTech(id, end-3);
   end
end

o_refDay = refDay;

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
   if (~isempty(o_firstEmergencyAscentDate))
      fprintf('FIRST EMERGENCY ASCENT DATE: %s (%d dbar)\n', ...
         julian_2_gregorian_dec_argo(o_firstEmergencyAscentDate), o_firstEmergencyAscentPres);
   end
end

return;
