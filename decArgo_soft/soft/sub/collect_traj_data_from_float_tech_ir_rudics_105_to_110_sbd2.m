% ------------------------------------------------------------------------------
% Collect trajectory data from float technical data.
%
% SYNTAX :
%  [o_trajFromTechStruct] = collect_traj_data_from_float_tech_ir_rudics_105_to_110_sbd2( ...
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
%   03/06/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajFromTechStruct] = collect_traj_data_from_float_tech_ir_rudics_105_to_110_sbd2( ...
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
cycleStartDate = a_refDay + a_tabTech(6) + a_tabTech(7)/1440;
o_trajFromTechStruct.cycleStartDate = cycleStartDate;

% Buoyancy reduction start date
buoyancyRedStartDate = a_refDay + a_tabTech(14) + a_tabTech(15)/1440;
o_trajFromTechStruct.buoyancyRedStartDate = buoyancyRedStartDate;

% Descent to park start date
descentToParkStartDate = a_refDay + a_tabTech(18) + a_tabTech(19)/1440;
o_trajFromTechStruct.descentToParkStartDate = descentToParkStartDate;

firstStabInfo = unique([a_tabTech(20) a_tabTech(21) a_tabTech(26)]);
if ~((length(firstStabInfo) == 1) && (firstStabInfo == 0))
   % First stabilization date and pres
   firstStabDate = a_refDay + a_tabTech(20) + a_tabTech(21)/1440;
   o_trajFromTechStruct.firstStabDate = firstStabDate;
   
   firstStabPres = a_tabTech(26)*10;
   o_trajFromTechStruct.firstStabPres = firstStabPres;
end

% Descent to park end date
descentToParkEndDate = a_refDay + a_tabTech(22) + a_tabTech(23)/1440;
o_trajFromTechStruct.descentToParkEndDate = descentToParkEndDate;

% Max P during descent to park
maxPDuringDescentToPark = a_tabTech(27)*10;
o_trajFromTechStruct.maxPDuringDescentToPark = maxPDuringDescentToPark;

% Min/max P during drift at park
minPDuringDriftAtPark = a_tabTech(30)*10;
o_trajFromTechStruct.minPDuringDriftAtPark = minPDuringDriftAtPark;
maxPDuringDriftAtPark = a_tabTech(31)*10;
o_trajFromTechStruct.maxPDuringDriftAtPark = maxPDuringDriftAtPark;

% Descent to profile start date
descentToProfStartDate = a_refDay + a_tabTech(34) + a_tabTech(35)/1440;
o_trajFromTechStruct.descentToProfStartDate = descentToProfStartDate;

% Descent to profile end date
descentToProfEndDate = a_refDay + a_tabTech(36) + a_tabTech(37)/1440;
o_trajFromTechStruct.descentToProfEndDate = descentToProfEndDate;

% Max P during descent to profile
maxPDuringDescentToProf = a_tabTech(40)*10;
o_trajFromTechStruct.maxPDuringDescentToProf = maxPDuringDescentToProf;

% Min/max P during drift at profile
minPDuringDriftAtProf = a_tabTech(45)*10;
o_trajFromTechStruct.minPDuringDriftAtProf = minPDuringDriftAtProf;
maxPDuringDriftAtProf = a_tabTech(46)*10;
o_trajFromTechStruct.maxPDuringDriftAtProf = maxPDuringDriftAtProf;

% Ascent start date
ascentStartDate = a_refDay + a_tabTech(47) + a_tabTech(48)/1440;
o_trajFromTechStruct.ascentStartDate = ascentStartDate;

% Ascent end date
ascentEndDate = a_refDay + a_tabTech(49) + (a_tabTech(50)-10)/1440;
o_trajFromTechStruct.ascentEndDate = ascentEndDate;

% Transmission start date
if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(4), a_tabTech(5)))
   % retrieve the value of the PT7 configuration parameter
   [configPt7Val] = config_get_value_ir_rudics_sbd2(a_tabTech(4), a_tabTech(5), 'CONFIG_PT_7');
   if (~isempty(configPt7Val) && ~isnan(configPt7Val))
      transStartDate = a_refDay + a_tabTech(49) + (a_tabTech(50)+(configPt7Val/6000))/1440;
      o_trajFromTechStruct.transStartDate = transStartDate;
   end
end

% Grounding date and pressure
if (a_tabTech(52) == 1)

   % Grounding date
   groundingDate = a_refDay + a_tabTech(54) + a_tabTech(55)/1440;
   o_trajFromTechStruct.groundingDate = groundingDate;

   % Grounding pressure
   groundingPres = a_tabTech(53)*10;
   o_trajFromTechStruct.groundingPres = groundingPres;
      
end
      
% First emergency ascent date and pressure
if (a_tabTech(56) > 0)

   % First emergency ascent date
   firstEmergencyAscentDate = a_refDay + a_tabTech(60) + a_tabTech(57)/1440;
   o_trajFromTechStruct.firstEmergencyAscentDate = firstEmergencyAscentDate;
   
   % First emergency ascent pressure
   firstEmergencyAscentpres = a_tabTech(58)*10;
   o_trajFromTechStruct.firstEmergencyAscentpres = firstEmergencyAscentpres;

end

if (config_surface_after_prof_ir_rudics_sbd2(a_tabTech(4), a_tabTech(5)))

   % GPS valid fix
   gpsValid = a_tabTech(71);
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
      gpsLon = a_tabTech(76);
      gpsLat = a_tabTech(77);

      idF = find((gpsLocDate == gpsDate) & (gpsLocCycleNum == gpsCycleNum) & ...
         (gpsLocProfNum == gpsProfNum) & (gpsLocPhase == gpsPhase) & ...
         (gpsLocLon == gpsLon) & (gpsLocLat == gpsLat));
      if (length(idF) > 1)
         fprintf('WARNING: Float #%d Cycle #%d, profile #%d phase ''%s'': %d identical GPS locations => using only the first one\n', ...
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
   
%    % GPS date
%    gpsDate = a_tabTech(1);
%    o_trajFromTechStruct.gpsDate = gpsDate;
%    
%    % GPS longitude
%    gpsLon = a_tabTech(76);
%    o_trajFromTechStruct.gpsLon = gpsLon;
%    
%    % GPS latitude
%    gpsLat = a_tabTech(77);
%    o_trajFromTechStruct.gpsLat = gpsLat;
%    
%    % GPS valid fix
%    gpsValid = a_tabTech(71);
%    o_trajFromTechStruct.gpsValid = gpsValid;
%    
%    o_trajFromTechStruct.gpsAccuracy = 'G';

end

return;
