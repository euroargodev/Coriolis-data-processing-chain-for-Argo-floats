% ------------------------------------------------------------------------------
% Collect trajectory data from float technical data.
%
% SYNTAX :
%  [o_trajFromTechStruct] = collect_traj_data_from_float_tech_ir_rudics_111_113( ...
%    a_trajFromTechStruct, a_tabTech, a_refDay)
%
% INPUT PARAMETERS :
%   a_trajFromTechStruct : input structure to store trajectory data collected
%                          from tech data
%   a_tabTech            : float technical data
%   a_refDay             : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%   o_trajFromTechStruct : output structure to store trajectory data collected
%                          from tech data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajFromTechStruct] = collect_traj_data_from_float_tech_ir_rudics_111_113( ...
   a_trajFromTechStruct, a_tabTech, a_refDay)

% output parameters initialization
o_trajFromTechStruct = a_trajFromTechStruct;

% array to store GPS data
global g_decArgo_gpsData;

% current float WMO number
global g_decArgo_floatNum;


% Packet time
o_trajFromTechStruct.packetTime = a_tabTech(1);

% RTC state
o_trajFromTechStruct.rtcState = a_tabTech(13);

% Cycle start date
if (any(a_tabTech(6:7) ~= 0))
   cycleStartDate = a_refDay + a_tabTech(6) + a_tabTech(7)/1440;
   o_trajFromTechStruct.cycleStartDate = cycleStartDate;
end

% Buoyancy reduction start date
if (any(a_tabTech(14:15) ~= 0))
   buoyancyRedStartDate = a_refDay + a_tabTech(14) + a_tabTech(15)/1440;
   o_trajFromTechStruct.buoyancyRedStartDate = buoyancyRedStartDate;
end

% Descent to park start date
if (any(a_tabTech(21:22) ~= 0))
   descentToParkStartDate = a_refDay + a_tabTech(21) + a_tabTech(22)/1440;
   o_trajFromTechStruct.descentToParkStartDate = descentToParkStartDate;
end

% First stabilization date and pres
if (any(a_tabTech([23 24 29]) ~= 0))
   firstStabDate = a_refDay + a_tabTech(23) + a_tabTech(24)/1440;
   o_trajFromTechStruct.firstStabDate = firstStabDate;
   
   firstStabPres = a_tabTech(29)*10;
   o_trajFromTechStruct.firstStabPres = firstStabPres;
end

% Descent to park end date
if (any(a_tabTech(25:26) ~= 0))
   descentToParkEndDate = a_refDay + a_tabTech(25) + a_tabTech(26)/1440;
   o_trajFromTechStruct.descentToParkEndDate = descentToParkEndDate;
end

% Max P during descent to park
maxPDuringDescentToPark = a_tabTech(30)*10;
o_trajFromTechStruct.maxPDuringDescentToPark = maxPDuringDescentToPark;

% Min/max P during drift at park
minPDuringDriftAtPark = a_tabTech(33)*10;
o_trajFromTechStruct.minPDuringDriftAtPark = minPDuringDriftAtPark;
maxPDuringDriftAtPark = a_tabTech(34)*10;
o_trajFromTechStruct.maxPDuringDriftAtPark = maxPDuringDriftAtPark;

% Descent to profile start date
if (any(a_tabTech(37:38) ~= 0))
   descentToProfStartDate = a_refDay + a_tabTech(37) + a_tabTech(38)/1440;
   o_trajFromTechStruct.descentToProfStartDate = descentToProfStartDate;
end

% Descent to profile end date
if (any(a_tabTech(39:40) ~= 0))
   descentToProfEndDate = a_refDay + a_tabTech(39) + a_tabTech(40)/1440;
   o_trajFromTechStruct.descentToProfEndDate = descentToProfEndDate;
end

% Max P during descent to profile
maxPDuringDescentToProf = a_tabTech(43)*10;
o_trajFromTechStruct.maxPDuringDescentToProf = maxPDuringDescentToProf;

% Min/max P during drift at profile
minPDuringDriftAtProf = a_tabTech(48)*10;
o_trajFromTechStruct.minPDuringDriftAtProf = minPDuringDriftAtProf;
maxPDuringDriftAtProf = a_tabTech(49)*10;
o_trajFromTechStruct.maxPDuringDriftAtProf = maxPDuringDriftAtProf;

% Ascent start date
if (any(a_tabTech(50:51) ~= 0))
   ascentStartDate = a_refDay + a_tabTech(50) + a_tabTech(51)/1440;
   o_trajFromTechStruct.ascentStartDate = ascentStartDate;
end

% Ascent end date
if (any(a_tabTech(52:53) ~= 0))
   ascentEndDate = a_refDay + a_tabTech(52) + (a_tabTech(53)-10)/1440;
   o_trajFromTechStruct.ascentEndDate = ascentEndDate;
end

% Transmission start date
if (any(a_tabTech(52:53) ~= 0))
   if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(4), a_tabTech(5)))
      % retrieve the value of the PT7 configuration parameter
      [configPt7Val] = config_get_value_ir_rudics_sbd2(a_tabTech(4), a_tabTech(5), 'CONFIG_PT_7');
      if (~isempty(configPt7Val) && ~isnan(configPt7Val))
         transStartDate = a_refDay + a_tabTech(52) + (a_tabTech(53)+(configPt7Val/6000))/1440;
         o_trajFromTechStruct.transStartDate = transStartDate;
      end
   end
end

% Grounding date and pressure
if (a_tabTech(56) == 1)
   if (any(a_tabTech(57:59) ~= 0))
      % Grounding date
      groundingDate = a_refDay + a_tabTech(58) + a_tabTech(59)/1440;
      o_trajFromTechStruct.groundingDate = groundingDate;
      
      % Grounding pressure
      groundingPres = a_tabTech(57)*10;
      o_trajFromTechStruct.groundingPres = groundingPres;
   end
end
      
% First emergency ascent date and pressure
if (a_tabTech(64) > 0)
   if (any(a_tabTech([65 66 68]) ~= 0))
      % First emergency ascent date
      % day number is coded on one byte only => manage possible roll over of
      % first emergency ascent day
      firstEmergencyAscentDay = a_tabTech(68);
      while ((a_refDay + firstEmergencyAscentDay + a_tabTech(65)/1440) < o_trajFromTechStruct.cycleStartDate)
         firstEmergencyAscentDay = firstEmergencyAscentDay + 256;
      end
      firstEmergencyAscentDate = a_refDay + firstEmergencyAscentDay + a_tabTech(65)/1440;
      o_trajFromTechStruct.firstEmergencyAscentDate = firstEmergencyAscentDate;
      
      % First emergency ascent pressure
      firstEmergencyAscentpres = a_tabTech(66)*10;
      o_trajFromTechStruct.firstEmergencyAscentpres = firstEmergencyAscentpres;
   end
end

if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(4), a_tabTech(5)))

   % GPS valid fix
   gpsValid = a_tabTech(77);
   if (gpsValid == 1)
   
      % unpack the GPS data
      if (~isempty(g_decArgo_gpsData))
         gpsLocCycleNum = g_decArgo_gpsData{1};
         gpsLocProfNum = g_decArgo_gpsData{2};
         gpsLocPhase = g_decArgo_gpsData{3};
         gpsLocDate = g_decArgo_gpsData{4};
         gpsLocLon = g_decArgo_gpsData{5};
         gpsLocLat = g_decArgo_gpsData{6};
         gpsLocQc = g_decArgo_gpsData{7};
         gpsLocAccuracy = g_decArgo_gpsData{8};
      else
         gpsLocCycleNum = [];
         gpsLocProfNum = [];
         gpsLocPhase = [];
         gpsLocDate = [];
         gpsLocLon = [];
         gpsLocLat = [];
         gpsLocQc = [];
         gpsLocAccuracy = [];
      end
      
      gpsDate = a_tabTech(1);
      gpsCycleNum = a_tabTech(4);
      gpsProfNum = a_tabTech(5);
      gpsPhase = a_tabTech(8);
      gpsLon = a_tabTech(88);
      gpsLat = a_tabTech(89);

      idF = find((gpsLocDate == gpsDate) & (gpsLocCycleNum == gpsCycleNum) & ...
         (gpsLocProfNum == gpsProfNum) & (gpsLocPhase == gpsPhase) & ...
         (gpsLocLon == gpsLon) & (gpsLocLat == gpsLat));
      if (length(idF) > 1)
         fprintf('WARNING: Float #%d Cycle #%d, profile #%d phase ''%s'': %d identical GPS locations - using only the first one\n', ...
            g_decArgo_floatNum, gpsCycleNum, gpsProfNum, get_phase_name(gpsPhase), length(idF));
         idF = idF(1);
      end
      if (~isempty(idF))
         o_trajFromTechStruct.gpsDate = gpsLocDate(idF);
         o_trajFromTechStruct.gpsLon = gpsLocLon(idF);
         o_trajFromTechStruct.gpsLat = gpsLocLat(idF);
         o_trajFromTechStruct.gpsQc = num2str(gpsLocQc(idF));
         o_trajFromTechStruct.gpsAccuracy = gpsLocAccuracy(idF);
      end
   end
end

return
