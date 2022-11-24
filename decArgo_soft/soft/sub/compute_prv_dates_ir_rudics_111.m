% ------------------------------------------------------------------------------
% Compute the main dates of a PROVOR float cycle.
%
% SYNTAX :
%  [o_cycleStartDate, o_buoyancyRedStartDate, ...
%    o_descentToParkStartDate, ...
%    o_firstStabDate, o_firstStabPres, ...
%    o_descentToParkEndDate, ...
%    o_descentToProfStartDate, o_descentToProfEndDate, ...
%    o_ascentStartDate, o_ascentEndDate, ...
%    o_transStartDate, ...
%    o_buoyancyInvStartDate, ...
%    o_firstGroundDate, o_firstGroundPres, ...
%    o_firstHangDate, o_firstHangPres, ...
%    o_firstEmerAscentDate, o_firstEmergencyAscentPres] = ...
%    compute_prv_dates_ir_rudics_111(a_tabTech, ...
%    a_floatClockDrift, a_refDay)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical data
%   a_floatClockDrift : float clock drift
%   a_refDay          : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_cycleStartDate           : cycle start date
%   o_buoyancyRedStartDate     : buoyancy reduction start date
%   o_descentToParkStartDate   : descent to park start date
%   o_firstStabDate            : first stabilisation date
%   o_firstStabPres            : first stabilisation pressure
%   o_descentToParkEndDate     : descent to park end date
%   o_descentToProfStartDate   : descent to profile start date
%   o_descentToProfEndDate     : descent to profile end date
%   o_ascentStartDate          : ascent start date
%   o_ascentEndDate            : ascent end date
%   o_transStartDate           : transmission start date
%   o_buoyancyInvStartDate     : buoyancy inversion start date
%   o_firstGroundDate          : first grounding date
%   o_firstGroundPres          : first grounding pressure
%   o_firstHangDate            : first hanging date
%   o_firstHangPres            : first hanging pressure
%   o_firstEmerAscentDate      : first emergency ascent date
%   o_firstEmergencyAscentPres : first emergency ascent pressure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleStartDate, o_buoyancyRedStartDate, ...
   o_descentToParkStartDate, ...
   o_firstStabDate, o_firstStabPres, ...
   o_descentToParkEndDate, ...
   o_descentToProfStartDate, o_descentToProfEndDate, ...
   o_ascentStartDate, o_ascentEndDate, ...
   o_transStartDate, ...
   o_buoyancyInvStartDate, ...
   o_firstGroundDate, o_firstGroundPres, ...
   o_firstHangDate, o_firstHangPres, ...
   o_firstEmerAscentDate, o_firstEmergencyAscentPres] = ...
   compute_prv_dates_ir_rudics_111(a_tabTech, ...
   a_floatClockDrift, a_refDay)

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;
global g_decArgo_presDef;

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
o_buoyancyInvStartDate = [];
o_firstGroundDate = [];
o_firstGroundPres = [];
o_firstHangDate = [];
o_firstHangPres = [];
o_firstEmerAscentDate = [];
o_firstEmergencyAscentPres = [];

for idP = 1:size(a_tabTech, 1)
   
   % determination of cycle start date
   cycleStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 6:7) ~= 0))
      cycleStartDate = a_refDay + a_tabTech(idP, 6) + a_tabTech(idP, 7)/1440;
   end
   o_cycleStartDate = [o_cycleStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) cycleStartDate]];
   
   % determination of buoyancy reduction start date
   buoyancyRedStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 14:15) ~= 0))
      buoyancyRedStartDate = a_refDay + a_tabTech(idP, 14) + a_tabTech(idP, 15)/1440;
   end
   o_buoyancyRedStartDate = [o_buoyancyRedStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) buoyancyRedStartDate]];
   
   % determination of buoyancy inversion start date
   buoyancyInvStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 18:19) ~= 0))
      buoyancyInvStartDate = a_refDay + a_tabTech(idP, 18) + a_tabTech(idP, 19)/1440;
   end
   o_buoyancyInvStartDate = [o_buoyancyInvStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) buoyancyInvStartDate]];
   
   % determination of descent to park start date
   descentToParkStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 21:22) ~= 0))
      descentToParkStartDate = a_refDay + a_tabTech(idP, 21) + a_tabTech(idP, 22)/1440;
   end
   o_descentToParkStartDate = [o_descentToParkStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToParkStartDate]];
   
   % determination of first stabilization date and pres
   firstStabDate = g_decArgo_dateDef;
   firstStabPres = g_decArgo_presDef;
   if (any(a_tabTech(idP, [23 24 29]) ~= 0))
      firstStabDate = a_refDay + a_tabTech(idP, 23) + a_tabTech(idP, 24)/1440;
      firstStabPres = a_tabTech(idP, 29)*10;
   end
   o_firstStabDate = [o_firstStabDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstStabDate]];
   o_firstStabPres = [o_firstStabPres; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstStabPres]];
   
   % determination of descent to park end date
   descentToParkEndDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 25:26) ~= 0))
      descentToParkEndDate = a_refDay + a_tabTech(idP, 25) + a_tabTech(idP, 26)/1440;
   end
   o_descentToParkEndDate = [o_descentToParkEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToParkEndDate]];
   
   % determination of descent to profile start date
   descentToProfStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 37:38) ~= 0))
      descentToProfStartDate = a_refDay + a_tabTech(idP, 37) + a_tabTech(idP, 38)/1440;
   end
   o_descentToProfStartDate = [o_descentToProfStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToProfStartDate]];
   
   % determination of descent to profile end date
   descentToProfEndDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 39:40) ~= 0))
      descentToProfEndDate = a_refDay + a_tabTech(idP, 39) + a_tabTech(idP, 40)/1440;
   end
   o_descentToProfEndDate = [o_descentToProfEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToProfEndDate]];
   
   % determination of ascent start date
   ascentStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 50:51) ~= 0))
      ascentStartDate = a_refDay + a_tabTech(idP, 50) + a_tabTech(idP, 51)/1440;
   end
   o_ascentStartDate = [o_ascentStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) ascentStartDate]];
   
   % determination of ascent end date
   ascentEndDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 52:53) ~= 0))
      ascentEndDate = a_refDay + a_tabTech(idP, 52) + (a_tabTech(idP, 53)-10)/1440;
   end
   o_ascentEndDate = [o_ascentEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) ascentEndDate]];
   
   % determination of transmission start date
   transStartDate = g_decArgo_dateDef;
   if (any(a_tabTech(idP, 52:53) ~= 0))
      if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(idP, 4), a_tabTech(idP, 5)))
         % retrieve the value of the PT7 configuration parameter
         [configPt7Val] = config_get_value_ir_rudics_sbd2( ...
            a_tabTech(idP, 4), a_tabTech(idP, 5), 'CONFIG_PT_7');
         if (~isempty(configPt7Val) && ~isnan(configPt7Val))
            transStartDate = a_refDay + a_tabTech(idP, 52) + (a_tabTech(idP, 53)+(configPt7Val/6000))/1440;
         end
      end
   end
   o_transStartDate = [o_transStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) transStartDate]];
   
   % determination of first grounding date and pres
   firstGroundDate = g_decArgo_dateDef;
   firstGroundPres = g_decArgo_presDef;
   if (a_tabTech(idP, 56) == 1)
      if (any(a_tabTech(idP, 57:59) ~= 0))
         firstGroundDate = a_refDay + a_tabTech(idP, 58) + a_tabTech(idP, 59)/1440;
         firstGroundPres = a_tabTech(idP, 57)*10;
      end
   end
   o_firstGroundDate = [o_firstGroundDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstGroundDate]];
   o_firstGroundPres = [o_firstGroundPres; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstGroundPres]];
   
   % determination of first hanging date and pres
   firstHangDate = g_decArgo_dateDef;
   firstHangPres = g_decArgo_presDef;
   if (a_tabTech(idP, 60) == 1)
      if (any(a_tabTech(idP, 61:63) ~= 0))
         firstHangDate = a_refDay + a_tabTech(idP, 62) + a_tabTech(idP, 63)/1440;
         firstHangPres = a_tabTech(idP, 61)*10;
      end
   end
   o_firstHangDate = [o_firstHangDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstHangDate]];
   o_firstHangPres = [o_firstHangPres; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstHangPres]];
   
   % determination of first emergency ascent date and pres
   firstEmergencyAscentDate = g_decArgo_dateDef;
   firstEmergencyAscentPres = g_decArgo_presDef;
   if (a_tabTech(idP, 64) > 0)
      if (any(a_tabTech(idP, [65 66 68]) ~= 0))
         % day number is coded on one byte only => manage possible roll over of
         % first emergency ascent day
         firstEmergencyAscentDay = a_tabTech(idP, 68);
         while ((a_refDay + firstEmergencyAscentDay + a_tabTech(idP, 65)/1440) < cycleStartDate)
            firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
         end
         firstEmergencyAscentDate = a_refDay + firstEmergencyAscentDay + a_tabTech(idP, 65)/1440;
         
         firstEmergencyAscentPres = a_tabTech(idP, 66)*10;
      end
   end
   o_firstEmerAscentDate = [o_firstEmerAscentDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstEmergencyAscentDate]];
   o_firstEmergencyAscentPres = [o_firstEmergencyAscentPres; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstEmergencyAscentPres]];
   
   print = 0;
   if (print == 1)
      floatClockDrift = round(a_floatClockDrift*1440)/1440;
      fprintf('Float #%d cycle #%d prof #%d phase %s:\n', ...
         g_decArgo_floatNum, a_tabTech(idP, 4), a_tabTech(idP, 5), get_phase_name(a_tabTech(idP, 8)));
      fprintf('FLOAT CLOCK DRIFT          : %s => %s\n', ...
         format_time_dec_argo(a_floatClockDrift*24), ...
         format_time_dec_argo(floatClockDrift*24));
      fprintf('CYCLE START DATE           : %s => %s\n', ...
         julian_2_gregorian_dec_argo(cycleStartDate), ...
         julian_2_gregorian_dec_argo(cycleStartDate-floatClockDrift));
      fprintf('BUOY REDUCTION START DATE  : %s => %s\n', ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate), ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate-floatClockDrift));
      fprintf('DESCENT TO PARK START DATE : %s => %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkStartDate), ...
         julian_2_gregorian_dec_argo(descentToParkStartDate-floatClockDrift));
      fprintf('FIRST STABILIZATION DATE   : %s => %s\n', ...
         julian_2_gregorian_dec_argo(firstStabDate), ...
         julian_2_gregorian_dec_argo(firstStabDate-floatClockDrift));
      fprintf('DESCENT TO PARK END DATE   : %s => %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkEndDate), ...
         julian_2_gregorian_dec_argo(descentToParkEndDate-floatClockDrift));
      fprintf('DESCENT TO PROF START DATE : %s => %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfStartDate), ...
         julian_2_gregorian_dec_argo(descentToProfStartDate-floatClockDrift));
      fprintf('DESCENT TO PROF END DATE   : %s => %s\n', ...
         julian_2_gregorian_dec_argo(descentToProfEndDate), ...
         julian_2_gregorian_dec_argo(descentToProfEndDate-floatClockDrift));
      fprintf('ASCENT START DATE          : %s => %s\n', ...
         julian_2_gregorian_dec_argo(ascentStartDate), ...
         julian_2_gregorian_dec_argo(ascentStartDate-floatClockDrift));
      fprintf('ASCENT END DATE            : %s => %s\n', ...
         julian_2_gregorian_dec_argo(ascentEndDate), ...
         julian_2_gregorian_dec_argo(ascentEndDate-floatClockDrift));
      fprintf('TRANSMISSION START DATE    : %s => %s\n', ...
         julian_2_gregorian_dec_argo(transStartDate), ...
         julian_2_gregorian_dec_argo(transStartDate-floatClockDrift));
      fprintf('BUOY INVERSION START DATE  : %s => %s\n', ...
         julian_2_gregorian_dec_argo(buoyancyInvStartDate), ...
         julian_2_gregorian_dec_argo(buoyancyInvStartDate-floatClockDrift));
      fprintf('FIRST GROUNDING START DATE : %s => %s\n', ...
         julian_2_gregorian_dec_argo(firstGroundDate), ...
         julian_2_gregorian_dec_argo(firstGroundDate-floatClockDrift));
      fprintf('FIRST HANGING START DATE   : %s => %s\n', ...
         julian_2_gregorian_dec_argo(firstHangDate), ...
         julian_2_gregorian_dec_argo(firstHangDate-floatClockDrift));
      fprintf('FIRST EMERGENCY START DATE : %s => %s\n', ...
         julian_2_gregorian_dec_argo(firstEmergencyAscentDate), ...
         julian_2_gregorian_dec_argo(firstEmergencyAscentDate-floatClockDrift));
   end
end

return;
