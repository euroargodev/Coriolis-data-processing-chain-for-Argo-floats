% ------------------------------------------------------------------------------
% Compute the main dates of a PROVOR float cycle.
%
% SYNTAX :
%  [o_cycleStartDate, o_buoyancyRedStartDate, ...
%    o_descentToParkStartDate, ...
%    o_firstStabDate, o_firstStabPres, ...
%    o_descentToParkEndDate, ...
%    o_descentToProfStartDate, o_descentToProfEndDate, ...
%    o_ascentStartDate, o_ascentEndDate ...
%    o_transStartDate, ...
%    o_firstEmerAscentDate] = ...
%    compute_prv_dates_ir_rudics_105_to_110_112_sbd2(a_tabTech, ...
%    a_floatClockDrift, a_refDay, a_measDates)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical data
%   a_floatClockDrift : float clock drift
%   a_refDay          : reference day (day of the first descent)
%   a_measDates       : measurement dates transmitted by the float
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate         : cycle start date
%   o_buoyancyRedStartDate   : buoyancy reduction start date
%   o_descentToParkStartDate : descent to park start date
%   o_firstStabDate          : first stabilisation date
%   o_firstStabPres          : first stabilisation pressure
%   o_descentToParkEndDate   : descent to park end date
%   o_descentToProfStartDate : descent to profile start date
%   o_descentToProfEndDate   : descent to profile end date
%   o_ascentStartDate        : ascent start date
%   o_ascentEndDate          : ascent end date
%   o_transStartDate         : transmission start date
%   o_firstEmerAscentDate    : first emergency ascent date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/13/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate, o_buoyancyRedStartDate, ...
   o_descentToParkStartDate, ...
   o_firstStabDate, o_firstStabPres, ...
   o_descentToParkEndDate, ...
   o_descentToProfStartDate, o_descentToProfEndDate, ...
   o_ascentStartDate, o_ascentEndDate, ...
   o_transStartDate, ...
   o_firstEmerAscentDate] = ...
   compute_prv_dates_ir_rudics_105_to_110_112_sbd2(a_tabTech, ...
   a_floatClockDrift, a_refDay, a_measDates)

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


% output parameters initialization
o_cycleStartDate = [];
o_buoyancyRedStartDate = [];
o_descentToParkStartDate = [];
o_firstStabDate = [];
o_firstStabPres = [];
o_descentToParkEndDate = [];
o_descentToProfStartDate = [];
o_descentToProfEndDate = [];
o_ascentStartDate = [];
o_ascentEndDate = [];
o_transStartDate = [];
o_firstEmerAscentDate = [];

for idP = 1:size(a_tabTech, 1)
   
   cycleNum = a_tabTech(idP, 4);
   profileNum = a_tabTech(idP, 5);
   
   % set the current reference day for this cycle and prof number
   refDay = a_refDay;
   if (~isempty(g_decArgo_julD2FloatDayOffset))
      idF = find((g_decArgo_julD2FloatDayOffset(:, 1) == cycleNum) & ...
         (g_decArgo_julD2FloatDayOffset(:, 2) == profileNum));
      if (~isempty(idF))
         refDay = g_decArgo_julD2FloatDayOffset(idF, 3);
      else
         refDay = g_decArgo_julD2FloatDayOffset(end, 3);
      end
   end
   
   % check the current reference day
   if (a_tabTech(idP, 8) == g_decArgo_phaseSatTrans)
      
      if (~isempty(a_measDates))
         
         % check transmitted measurement dates VS float cycle timings
         % the float reference day may jump (ex: 6901515 #20)
         % we then need it and to correct it if needed
         
         % retrieve the transmitted measurement dates for each phase of the cycle
         minParkDriftDate = [];
         maxParkDriftDate = [];
         minAscProfDate = [];
         maxAscProfDate = [];
         %          id = find((a_measDates(:, 1) == cycleNum) & ...
         %             (a_measDates(:, 2) == profileNum) & ...
         %             (a_measDates(:, 3) == g_decArgo_phaseDsc2Prk));
         %          if (~isempty(id))
         %             desc2ParkDates = a_measDates(id, 4);
         %          end
         id = find((a_measDates(:, 1) == cycleNum) & ...
            (a_measDates(:, 2) == profileNum) & ...
            (a_measDates(:, 3) == g_decArgo_phaseParkDrift));
         if (~isempty(id))
            parkDriftDates = a_measDates(id, 4);
            minParkDriftDate = min(parkDriftDates);
            maxParkDriftDate = max(parkDriftDates);
            % remove seconds to compare with cycle timings which are provided in minutes
            minParkDriftDateStr = julian_2_gregorian_dec_argo(minParkDriftDate);
            maxParkDriftDateStr = julian_2_gregorian_dec_argo(maxParkDriftDate);
            minParkDriftDate = gregorian_2_julian_dec_argo([minParkDriftDateStr(1:16) ':00']);
            maxParkDriftDate = gregorian_2_julian_dec_argo([maxParkDriftDateStr(1:16) ':00']);
         end
         id = find((a_measDates(:, 1) == cycleNum) & ...
            (a_measDates(:, 2) == profileNum) & ...
            (a_measDates(:, 3) == g_decArgo_phaseAscProf));
         if (~isempty(id))
            ascProfDates = a_measDates(id, 4);
            minAscProfDate = min(ascProfDates);
            maxAscProfDate = max(ascProfDates);
            % remove seconds to compare with cycle timings which are provided in minutes
            minAscProfDateStr = julian_2_gregorian_dec_argo(minAscProfDate);
            maxAscProfDateStr = julian_2_gregorian_dec_argo(maxAscProfDate);
            minAscProfDate = gregorian_2_julian_dec_argo([minAscProfDateStr(1:16) ':00']);
            maxAscProfDate = gregorian_2_julian_dec_argo([maxAscProfDateStr(1:16) ':00']);
         end
         
         % check consistency
         offset1 = [];
         offset2 = [];
         offset3 = [];
         % we cannot use descent to park measurements because, for some
         % floats, measurements are sampled in the shallowesr zone only
         % (and before DST)
         %          if (~isempty(desc2ParkDates))
         %
         %             % determination of descent to park start date
         %             descentToParkStartDate = refDay + a_tabTech(idP, 18) + a_tabTech(idP, 19)/1440;
         %
         %             % determination of descent to park end date
         %             descentToParkEndDate = refDay + a_tabTech(idP, 22) + a_tabTech(idP, 23)/1440;
         %
         %             if (min(desc2ParkDates) > descentToParkEndDate)
         %                offset1 = 1;
         %                while (max(desc2ParkDates) > descentToParkEndDate)
         %                   descentToParkEndDate = descentToParkEndDate + offset1;
         %                   offset1 = offset1 + 1;
         %                end
         %                offset1 = offset1 - 1;
         %             elseif (max(desc2ParkDates) < descentToParkStartDate)
         %                offset1 = -1;
         %                while (max(desc2ParkDates) < descentToParkStartDate)
         %                   descentToParkStartDate = descentToParkStartDate + offset1;
         %                   offset1 = offset1 - 1;
         %                end
         %                offset1 = offset1 + 1;
         %             else
         %                offset1 = 0;
         %             end
         %          end
         if (~isempty(minParkDriftDate))
            
            % determination of descent to park end date
            descentToParkEndDate = refDay + a_tabTech(idP, 22) + a_tabTech(idP, 23)/1440;
            descentToParkEndDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(descentToParkEndDate)); % needed for comparison
            
            % determination of descent to profile start date
            descentToProfStartDate = refDay + a_tabTech(idP, 34) + a_tabTech(idP, 35)/1440;
            descentToProfStartDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(descentToProfStartDate)); % needed for comparison
            
            if (minParkDriftDate > descentToProfStartDate)
               offset2 = 1;
               while (maxParkDriftDate > descentToProfStartDate)
                  descentToProfStartDate = descentToProfStartDate + offset2;
                  offset2 = offset2 + 1;
               end
               offset2 = offset2 - 1;
            elseif (maxParkDriftDate < descentToParkEndDate)
               offset2 = -1;
               while (minParkDriftDate < descentToParkEndDate)
                  descentToParkEndDate = descentToParkEndDate + offset2;
                  offset2 = offset2 - 1;
               end
               offset2 = offset2 + 1;
            else
               offset2 = 0;
            end
         end
         if (~isempty(minAscProfDate))
            
            % determination of ascent start date
            ascentStartDate = refDay + a_tabTech(idP, 47) + a_tabTech(idP, 48)/1440;
            ascentStartDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(ascentStartDate)); % needed for comparison
            
            % determination of ascent end date
            ascentEndDate = refDay + a_tabTech(idP, 49) + (a_tabTech(idP, 50)-10)/1440;
            ascentEndDate = gregorian_2_julian_dec_argo(julian_2_gregorian_dec_argo(ascentEndDate)); % needed for comparison
            
            if (minAscProfDate > ascentEndDate)
               offset3 = 1;
               while (minAscProfDate > ascentEndDate)
                  ascentEndDate = ascentEndDate + offset3;
                  offset3 = offset3 + 1;
               end
               offset3 = offset3 - 1;
            elseif (maxAscProfDate < ascentStartDate)
               offset3 = -1;
               while (minAscProfDate < ascentStartDate)
                  ascentStartDate = ascentStartDate + offset3;
                  offset3 = offset3 - 1;
               end
               offset3 = offset3 + 1;
            else
               offset3 = 0;
            end
         end
         offset = unique([offset1 offset2 offset3]);
         if ((length(offset) == 1) && (offset ~= 0))
            fprintf('WARNING: Float #%d cycle #%d prof #%d: reference day changed to %s (instead of %s)\n', ...
               g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), ...
               julian_2_gregorian_dec_argo(refDay + offset), ...
               julian_2_gregorian_dec_argo(refDay));
            refDay = refDay + offset;
         elseif (offset2 ~= 0)
            fprintf('WARNING: Float #%d cycle #%d prof #%d: reference day changed to %s (instead of %s)\n', ...
               g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), ...
               julian_2_gregorian_dec_argo(refDay + offset2), ...
               julian_2_gregorian_dec_argo(refDay));
            refDay = refDay + offset2;
         elseif (offset3 ~= 0)
            fprintf('WARNING: Float #%d cycle #%d prof #%d: reference day changed to %s (instead of %s)\n', ...
               g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), ...
               julian_2_gregorian_dec_argo(refDay + offset3), ...
               julian_2_gregorian_dec_argo(refDay));
            refDay = refDay + offset3;
            %          elseif (length(offset) > 1)
            %             fprintf('ERROR: Float #%d cycle #%d prof #%d: check of float reference day returns inconsistent offsets (%d values)\n', ...
            %                g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), ...
            %                length(offset));
         end
      end
      
      % store the current reference day
      if (~isempty(g_decArgo_julD2FloatDayOffset))
         idF = find((g_decArgo_julD2FloatDayOffset(:, 1) == cycleNum) & ...
            (g_decArgo_julD2FloatDayOffset(:, 2) == profileNum));
         if (isempty(idF))
            g_decArgo_julD2FloatDayOffset = [g_decArgo_julD2FloatDayOffset; ...
               [cycleNum profileNum refDay]];
         else
            if (refDay ~= g_decArgo_julD2FloatDayOffset(idF, 3))
               fprintf('ERROR: Float #%d cycle #%d prof #%d: determination of float reference day returns inconsistent results (stored refDay: %s whereas newly computed refDay: %s (for the same cycle and prof))\n', ...
                  g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), ...
                  julian_2_gregorian_dec_argo(g_decArgo_julD2FloatDayOffset(idF, 3)), ...
                  julian_2_gregorian_dec_argo(refDay));
            end
         end
      else
         g_decArgo_julD2FloatDayOffset = [cycleNum profileNum refDay];
      end
   end
   
   % determination of cycle start date
   cycleStartDate = refDay + a_tabTech(idP, 6) + a_tabTech(idP, 7)/1440;
   o_cycleStartDate = [o_cycleStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) cycleStartDate]];
   
   % determination of buoyancy reduction start date
   buoyancyRedStartDate = refDay + a_tabTech(idP, 14) + a_tabTech(idP, 15)/1440;
   o_buoyancyRedStartDate = [o_buoyancyRedStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) buoyancyRedStartDate]];
   
   % determination of descent to park start date
   descentToParkStartDate = refDay + a_tabTech(idP, 18) + a_tabTech(idP, 19)/1440;
   o_descentToParkStartDate = [o_descentToParkStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToParkStartDate]];
   
   firstStabInfo = unique([a_tabTech(idP, 20) a_tabTech(idP, 21) a_tabTech(idP, 26)]);
   if ~((length(firstStabInfo) == 1) && (firstStabInfo == 0))
      % determination of first stabilization date and pres
      firstStabDate = refDay + a_tabTech(idP, 20) + a_tabTech(idP, 21)/1440;
      o_firstStabDate = [o_firstStabDate; ...
         [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstStabDate]];
      
      firstStabPres = a_tabTech(idP, 26)*10;
      o_firstStabPres = [o_firstStabPres; ...
         [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstStabPres]];
   else
      o_firstStabDate = [o_firstStabDate; ...
         [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) g_decArgo_dateDef]];
      o_firstStabPres = [o_firstStabPres; ...
         [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) g_decArgo_presDef]];
   end
   
   % determination of descent to park end date
   descentToParkEndDate = refDay + a_tabTech(idP, 22) + a_tabTech(idP, 23)/1440;
   o_descentToParkEndDate = [o_descentToParkEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToParkEndDate]];
   
   % determination of descent to profile start date
   descentToProfStartDate = refDay + a_tabTech(idP, 34) + a_tabTech(idP, 35)/1440;
   o_descentToProfStartDate = [o_descentToProfStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToProfStartDate]];
   
   % determination of descent to profile end date
   descentToProfEndDate = refDay + a_tabTech(idP, 36) + a_tabTech(idP, 37)/1440;
   o_descentToProfEndDate = [o_descentToProfEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToProfEndDate]];
   
   % determination of ascent start date
   ascentStartDate = refDay + a_tabTech(idP, 47) + a_tabTech(idP, 48)/1440;
   o_ascentStartDate = [o_ascentStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) ascentStartDate]];
   
   % determination of ascent end date
   ascentEndDate = refDay + a_tabTech(idP, 49) + (a_tabTech(idP, 50)-10)/1440;
   o_ascentEndDate = [o_ascentEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) ascentEndDate]];
   
   % determination of transmission start date
   transStartDate = g_decArgo_dateDef;
   if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(idP, 4), a_tabTech(idP, 5)))
      % retrieve the value of the PT7 configuration parameter
      [configPt7Val] = config_get_value_ir_rudics_sbd2( ...
         a_tabTech(idP, 4), a_tabTech(idP, 5), 'CONFIG_PT_7');
      if (~isempty(configPt7Val) && ~isnan(configPt7Val))
         transStartDate = refDay + a_tabTech(idP, 49) + (a_tabTech(idP, 50)+(configPt7Val/6000))/1440;
      end
   end
   o_transStartDate = [o_transStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) transStartDate]];
   
   % determination of first emergency ascent date
   firstEmerAscentDate = g_decArgo_dateDef;
   if (a_tabTech(idP, 56) > 0)
      % First emergency ascent date
      
      % manage possible roll over of first emergency ascent day
      firstEmergencyAscentDay = a_tabTech(idP, 60);
      while ((refDay + firstEmergencyAscentDay + a_tabTech(idP, 57)/1440) < cycleStartDate)
         firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
      end
      
      firstEmergencyAscentDate = refDay + firstEmergencyAscentDay + a_tabTech(idP, 57)/1440;
      o_firstEmerAscentDate = [o_firstEmerAscentDate; ...
         [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstEmergencyAscentDate]];
   end
   
   print = 0;
   if (print == 1)
      floatClockDrift = round(a_floatClockDrift*1440)/1440;
      fprintf('Float #%d cycle #%d prof #%d phase %s:\n', ...
         g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), get_phase_name(a_tabTech(idP, 8)));
      fprintf('FLOAT CLOCK DRIFT          : %s - %s\n', ...
         format_time_dec_argo(a_floatClockDrift*24), ...
         format_time_dec_argo(floatClockDrift*24));
      fprintf('CYCLE START DATE           : %s - %s\n', ...
         julian_2_gregorian_dec_argo(cycleStartDate), ...
         julian_2_gregorian_dec_argo(cycleStartDate-floatClockDrift));
      fprintf('BUOY RED START DATE        : %s - %s\n', ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate), ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate-floatClockDrift));
      fprintf('DESCENT TO PARK START DATE : %s - %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkStartDate), ...
         julian_2_gregorian_dec_argo(descentToParkStartDate-floatClockDrift));
      fprintf('FIRST STAB DATE            : %s - %s\n', ...
         julian_2_gregorian_dec_argo(firstStabDate), ...
         julian_2_gregorian_dec_argo(firstStabDate-floatClockDrift));
      fprintf('DESCENT TO PARK END DATE   : %s - %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkEndDate), ...
         julian_2_gregorian_dec_argo(descentToParkEndDate-floatClockDrift));
      fprintf('DESCENT TO PROF START DATE : %s - %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfStartDate), ...
         julian_2_gregorian_dec_argo(descentToProfStartDate-floatClockDrift));
      fprintf('DESCENT TO PROF END DATE   : %s - %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfEndDate), ...
         julian_2_gregorian_dec_argo(descentToProfEndDate-floatClockDrift));
      fprintf('ASCENT START DATE          : %s - %s\n', ...
         julian_2_gregorian_dec_argo(ascentStartDate), ...
         julian_2_gregorian_dec_argo(ascentStartDate-floatClockDrift));
      fprintf('ASCENT END DATE            : %s - %s\n', ...
         julian_2_gregorian_dec_argo(ascentEndDate), ...
         julian_2_gregorian_dec_argo(ascentEndDate-floatClockDrift));
      fprintf('TRANSMISSION START DATE    : %s - %s\n', ...
         julian_2_gregorian_dec_argo(transStartDate), ...
         julian_2_gregorian_dec_argo(transStartDate-floatClockDrift));
   end
end

return
