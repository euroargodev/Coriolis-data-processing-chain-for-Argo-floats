% ------------------------------------------------------------------------------
% Process one packet of float technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_float_tech_data_ir_rudics_105_to_110_112_sbd2_one( ...
%    a_dataIndex, a_tabTech, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataIndex : index of the packet
%   a_tabTech   : float technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/28/2013 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_tech_data_ir_rudics_105_to_110_112_sbd2_one( ...
   a_dataIndex, a_tabTech, a_refDay)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% default values
global g_decArgo_janFirst1950InMatlab;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;


% cycle, prof and phase number coded in the packet
cycleNum = a_tabTech(a_dataIndex, 4);
profNum = a_tabTech(a_dataIndex, 5);
phaseNum = a_tabTech(a_dataIndex, 8);

% set the current reference day
refDay = a_refDay;
if (~isempty(g_decArgo_julD2FloatDayOffset))
   idF = find((g_decArgo_julD2FloatDayOffset(:, 1) == cycleNum) & ...
      (g_decArgo_julD2FloatDayOffset(:, 2) == profNum));
   if (~isempty(idF))
      refDay = g_decArgo_julD2FloatDayOffset(idF, 3);
   else
      refDay = g_decArgo_julD2FloatDayOffset(end, 3);
   end
end

% TECH: GENERAL INFORMATION

% Packet time
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 100];
g_decArgo_outputNcParamValue{end+1} = ...
   datestr(a_tabTech(a_dataIndex, 1) + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

% Float serial number
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 101];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 2);

% Number of profiles done
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 101];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 3);

% Internal cycle number
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 174];
g_decArgo_outputNcParamValue{end+1} = cycleNum;

% Internal profile number
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 175];
g_decArgo_outputNcParamValue{end+1} = profNum;

% Cycle start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 102];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 6);

% Cycle start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 103];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 7)/60);

% Cycle start date
cycleStartDate = refDay + a_tabTech(a_dataIndex, 6) + a_tabTech(a_dataIndex, 7)/1440;
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 104];
g_decArgo_outputNcParamValue{end+1} = ...
   datestr(cycleStartDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

% Meas. card not responding
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 105];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 9);

% FP timeout
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 106];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 10);

% Internal vacuum
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 107];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 11);

% Battery voltage
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 108];
g_decArgo_outputNcParamValue{end+1} = 15-a_tabTech(a_dataIndex, 12)/10;

% Real Time Clock state
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 109];
if (a_tabTech(a_dataIndex, 13) == 0)
   rtcStatus = 1;
else
   rtcStatus = 0;
end
g_decArgo_outputNcParamValue{end+1} = rtcStatus;

% TECH: BUOYANCY REDUCTION

% Buoyancy reduction start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 110];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 14);

% Buoyancy reduction start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 111];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 15)/60);

% EV fixed action duration
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 113];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 16);

% Number of EV actions at the surface
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 114];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 17);

% TECH: DESCENT TO PARK PRES

% Descent to park start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 115];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 18);

% Descent to park start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 116];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 19)/60);

% Descent to park start date (in TRAJ)
% descentToParkStartDate = refDay + a_tabTech(a_dataIndex, 18) + a_tabTech(a_dataIndex, 19)/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 117];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(descentToParkStartDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% First stabilization day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 118];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 20);

% First stabilization hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 119];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 21)/60);

% First stabilization date (in TRAJ)
% firstStabDate = refDay + a_tabTech(a_dataIndex, 20) + a_tabTech(a_dataIndex, 21)/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 120];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(firstStabDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% First stabilization pressure (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 121];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 26)*10;

% Descent to park end day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 122];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 22);

% Descent to park end hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 123];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 23)/60);

% Descent to park end date (in TRAJ)
% descentToParkEndDate = refDay + a_tabTech(a_dataIndex, 22) + a_tabTech(a_dataIndex, 23)/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 124];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(descentToParkEndDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% Number of EV actions during descent to park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 125];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 24);

% Number of pump actions during descent to park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 126];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 25);

% Max P during descent to park (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 127];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 27)*10;

% TECH: DRIFT AT PARK PRES

% Number of entrance in drift target range
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 128];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 28);

% Number of repositions during drift at park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 129];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 29);

% Min P during drift at park (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 130];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 30)*10;

% Max P during drift at park (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 131];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 31)*10;

% Number of EV actions during drift at park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 132];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 32);

% Number of pump actions during drift at park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 133];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 33);

% TECH: DESCENT TO PROF PRES

% Descent to prof start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 134];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 34);

% Descent to prof start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 135];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 35)/60);

% Descent to prof start date (in TRAJ)
% descentToProfStartDate = refDay + a_tabTech(a_dataIndex, 34) + a_tabTech(a_dataIndex, 35)/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 136];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(descentToProfStartDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% Descent to prof end day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 137];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 36);

% Descent to prof end hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 138];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 37)/60);

% Descent to prof end date (in TRAJ)
% descentToProfEndDate = refDay + a_tabTech(a_dataIndex, 36) + a_tabTech(a_dataIndex, 37)/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 139];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(descentToProfEndDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% Number of EV actions during descent to prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 140];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 38);

% Number of pump actions during descent to prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 141];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 39);

% Max P during descent to prof (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 142];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 40)*10;

% TECH: DRIFT AT PROF PRES

% Number of entrance in prof target range
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 143];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 41);

% Number of repositions during drift at prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 144];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 42);

% Number of EV actions during drift at prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 145];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 43);

% Number of pump actions during drift at prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 146];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 44);

% Min P during drift at prof (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 147];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 45)*10;

% Max P during drift at prof (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 148];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 46)*10;

% TECH: ASCENT TO SURFACE

% Ascent start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 149];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 47);

% Ascent start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 150];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 48)/60);

% Ascent start date (in TRAJ)
% ascentStartDate = refDay + a_tabTech(a_dataIndex, 47) + a_tabTech(a_dataIndex, 48)/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 151];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(ascentStartDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% Start buoyancy acquisition day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 152];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 49);

% Start buoyancy acquisition hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 153];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 50)/60);

% Start buoyancy acquisition date
buoyancyStartDate = refDay + a_tabTech(a_dataIndex, 49) + a_tabTech(a_dataIndex, 50)/1440;
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 154];
g_decArgo_outputNcParamValue{end+1} = ...
   datestr(buoyancyStartDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

% Ascent end date (in TRAJ)
% ascentEndDate = buoyancyStartDate - 10/1440;
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 155];
% g_decArgo_outputNcParamValue{end+1} = ...
%    datestr(ascentEndDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');

% Transmission start date (in TRAJ)
% if (config_surface_after_prof_ir_rudics_sbd2(cycleNum, profNum))
%    % retrieve the value of the PT7 configuration parameter
%    [configPt7Val] = config_get_value_ir_rudics_sbd2(cycleNum, profNum, 'CONFIG_PT_7');
%    if (~isempty(configPt7Val) && ~isnan(configPt7Val))
%       transStartDate = buoyancyStartDate + configPt7Val/(6000*1440);
%       g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%          253 cycleNum profNum phaseNum 156];
%       g_decArgo_outputNcParamValue{end+1} = ...
%          datestr(transStartDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');
%    end
% end

% Number of pump actions during ascent
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 157];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 51);

% TECH: GROUNDING

% Grounding detected (in TRAJ)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 158];
% if (a_tabTech(a_dataIndex, 52) == 1)
%    groundedFlag = 'Yes';
% else
%    groundedFlag = 'No';
% end
% g_decArgo_outputNcParamValue{end+1} = groundedFlag;

if (a_tabTech(a_dataIndex, 52) == 1)

   % Grounding day
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 160];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 54);
   
   % Grounding hour
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 161];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 55)/60);
   
   % Grounding date (in TRAJ)
   %    groundingDate = refDay + a_tabTech(a_dataIndex, 54) + a_tabTech(a_dataIndex, 55)/1440;
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   %       253 cycleNum profNum phaseNum 162];
   %    g_decArgo_outputNcParamValue{end+1} = ...
   %       datestr(groundingDate + g_decArgo_janFirst1950InMatlab, 'ddmmyyyyHHMMSS');
   
   % Grounding pressure (in TRAJ)
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   %       253 cycleNum profNum phaseNum 159];
   %    g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 53)*10;

end

% TECH: EMERGENCY ASCENT

% Number of emergency ascent
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 163];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 56);

if (a_tabTech(a_dataIndex, 56) > 0)
   
   % First emergency ascent day
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 164];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 60);

   % First emergency ascent hour
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 165];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 57)/60);

   % First emergency ascent date
   firstEmergencyAscentDate = refDay + a_tabTech(a_dataIndex, 60) + a_tabTech(a_dataIndex, 57)/1440;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 166];
   g_decArgo_outputNcParamValue{end+1} = ...
      datestr(firstEmergencyAscentDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

   % First emergency ascent pressure
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 167];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 58)*10;

   % Number of pump actions during the first emergency ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 168];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 59);

end

% TECH: RECEIVED REMOTE CONTROL

% Number of succesfully received remote control
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 169];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 61) - a_tabTech(a_dataIndex, 62);

% Number of rejected remote control
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 170];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 62);

% TECH: GPS DATA

% GPS valid fix (1=Valid 2=Not valid)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 170];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 71);

% TECH: MISCELLANEOUS

% Float board show mode state (META-CONFIG)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 171];
% if (a_tabTech(a_dataIndex, 72) == 1)
%    showModeOn = 'Yes';
% else
%    showModeOn = 'No';
% end
% g_decArgo_outputNcParamValue{end+1} = showModeOn;

% Sensor board show mode state (META-CONFIG)
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 172];
% if (a_tabTech(a_dataIndex, 73) == 1)
%    showModeOn = 'Yes';
% else
%    showModeOn = 'No';
% end
% g_decArgo_outputNcParamValue{end+1} = showModeOn;

% Sensor board status
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 173];
g_decArgo_outputNcParamValue{end+1} = sprintf('%#x', a_tabTech(a_dataIndex, 74));

return
