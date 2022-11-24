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
%    compute_prv_dates_ir_rudics_105_to_110_sbd2(a_tabTech, ...
%    a_floatClockDrift, a_refDay)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical data
%   a_floatClockDrift : float clock drift
%   a_refDay          : reference day (day of the first descent)
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
   compute_prv_dates_ir_rudics_105_to_110_sbd2(a_tabTech, ...
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
o_firstEmerAscentDate = [];

for idP = 1:size(a_tabTech, 1)

   % determination of cycle start date
   cycleStartDate = a_refDay + a_tabTech(idP, 6) + a_tabTech(idP, 7)/1440;
   o_cycleStartDate = [o_cycleStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) cycleStartDate]];

   % determination of buoyancy reduction start date
   buoyancyRedStartDate = a_refDay + a_tabTech(idP, 14) + a_tabTech(idP, 15)/1440;
   o_buoyancyRedStartDate = [o_buoyancyRedStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) buoyancyRedStartDate]];

   % determination of descent to park start date
   descentToParkStartDate = a_refDay + a_tabTech(idP, 18) + a_tabTech(idP, 19)/1440;
   o_descentToParkStartDate = [o_descentToParkStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToParkStartDate]];

   firstStabInfo = unique([a_tabTech(idP, 20) a_tabTech(idP, 21) a_tabTech(idP, 26)]);
   if ~((length(firstStabInfo) == 1) && (firstStabInfo == 0))
      % determination of first stabilization date and pres
      firstStabDate = a_refDay + a_tabTech(idP, 20) + a_tabTech(idP, 21)/1440;
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
   descentToParkEndDate = a_refDay + a_tabTech(idP, 22) + a_tabTech(idP, 23)/1440;
   o_descentToParkEndDate = [o_descentToParkEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToParkEndDate]];

   % determination of descent to profile start date
   descentToProfStartDate = a_refDay + a_tabTech(idP, 34) + a_tabTech(idP, 35)/1440;
   o_descentToProfStartDate = [o_descentToProfStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToProfStartDate]];

   % determination of descent to profile end date
   descentToProfEndDate = a_refDay + a_tabTech(idP, 36) + a_tabTech(idP, 37)/1440;
   o_descentToProfEndDate = [o_descentToProfEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) descentToProfEndDate]];

   % determination of ascent start date
   ascentStartDate = a_refDay + a_tabTech(idP, 47) + a_tabTech(idP, 48)/1440;
   o_ascentStartDate = [o_ascentStartDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) ascentStartDate]];

   % determination of ascent end date
   ascentEndDate = a_refDay + a_tabTech(idP, 49) + (a_tabTech(idP, 50)-10)/1440;
   o_ascentEndDate = [o_ascentEndDate; ...
      [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) ascentEndDate]];
   
   % determination of transmission start date
   transStartDate = g_decArgo_dateDef;
   if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(idP, 4), a_tabTech(idP, 5)))
      % retrieve the value of the PT7 configuration parameter
      [configPt7Val] = config_get_value_ir_rudics_sbd2( ...
         a_tabTech(idP, 4), a_tabTech(idP, 5), 'CONFIG_PT_7');
      if (~isempty(configPt7Val) && ~isnan(configPt7Val))
         transStartDate = a_refDay + a_tabTech(idP, 49) + (a_tabTech(idP, 50)+(configPt7Val/6000))/1440;
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
      while ((a_refDay + firstEmergencyAscentDay + a_tabTech(idP, 57)/1440) < cycleStartDate)
         firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
      end
      
      firstEmergencyAscentDate = a_refDay + firstEmergencyAscentDay + a_tabTech(idP, 57)/1440;
      o_firstEmerAscentDate = [o_firstEmerAscentDate; ...
         [a_tabTech(idP, 4) a_tabTech(idP, 5) a_tabTech(idP, 8) a_tabTech(idP, end) firstEmergencyAscentDate]];
   end
   
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
      fprintf('BUOY RED START DATE        : %s => %s\n', ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate), ...
         julian_2_gregorian_dec_argo(buoyancyRedStartDate-floatClockDrift));
      fprintf('DESCENT TO PARK START DATE : %s => %s\n', ...
         julian_2_gregorian_dec_argo(descentToParkStartDate), ...
         julian_2_gregorian_dec_argo(descentToParkStartDate-floatClockDrift));
      fprintf('FIRST STAB DATE            : %s => %s\n', ...
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
   end
end

return;
