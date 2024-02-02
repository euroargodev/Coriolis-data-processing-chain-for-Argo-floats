% ------------------------------------------------------------------------------
% Process one packet of float technical data for TECH NetCDF file.
%
% SYNTAX :
%  process_float_tech_data_ir_rudics_111_113_to_116_one( ...
%    a_dataIndex, a_tabTech, a_refDay)
%
% INPUT PARAMETERS :
%   a_dataIndex : index of the packet
%   a_tabTech   : float technical data
%   a_refDay    : reference day (day of the first descent)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/19/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_float_tech_data_ir_rudics_111_113_to_116_one( ...
   a_dataIndex, a_tabTech, a_refDay)

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% default values
global g_decArgo_janFirst1950InMatlab;

% float configuration
global g_decArgo_floatConfig;

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
   253 cycleNum profNum phaseNum 102];
g_decArgo_outputNcParamValue{end+1} = cycleNum;

% Internal profile number
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 103];
g_decArgo_outputNcParamValue{end+1} = profNum;

% Cycle start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 104];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 6);

% Cycle start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 105];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 7)/60);

% Cycle start date
cycleStartDate = refDay + a_tabTech(a_dataIndex, 6) + a_tabTech(a_dataIndex, 7)/1440;
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 106];
g_decArgo_outputNcParamValue{end+1} = ...
   datestr(cycleStartDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

% Meas. card not responding
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 107];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 9);

% FP timeout
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 108];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 10);

% Internal vacuum
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 109];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 11);

% Battery voltage
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 110];
g_decArgo_outputNcParamValue{end+1} = 15-a_tabTech(a_dataIndex, 12)/10;

% Real Time Clock state
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 111];
if (a_tabTech(a_dataIndex, 13) == 0)
   rtcStatus = 1;
else
   rtcStatus = 0;
end
g_decArgo_outputNcParamValue{end+1} = rtcStatus;

% TECH: BUOYANCY REDUCTION

% Buoyancy reduction start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 112];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 14);

% Buoyancy reduction start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 113];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 15)/60);

% Cumulative valve actions at the surface
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 115];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 16);

% Additionnal valve actions at the surface
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 116];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 17);

% TECH: BUOYANCY INVERSION

if (any(a_tabTech(a_dataIndex, 18:20) ~= 0))
   % Buoyancy inversion start day
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 117];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 18);
   
   % Buoyancy inversion start hour
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 118];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 19)/60);
   
   % Buoyancy inversion start date
   buoyancyRedStartDate = refDay + a_tabTech(a_dataIndex, 18) + a_tabTech(a_dataIndex, 19)/1440;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 119];
   g_decArgo_outputNcParamValue{end+1} = ...
      datestr(buoyancyRedStartDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
   
   % Cumulative valve actions at the surface
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 120];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 20);
end

% TECH: DESCENT TO PARK PRES

% Descent to park start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 121];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 21);

% Descent to park start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 122];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 22)/60);

% First stabilization day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 123];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 23);

% First stabilization hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 124];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 24)/60);

% Descent to park end day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 125];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 25);

% Descent to park end hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 126];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 26)/60);

% Number of EV actions during descent to park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 127];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 27);

% Number of pump actions during descent to park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 128];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 28);

% TECH: DRIFT AT PARK PRES

% Number of entrance in drift target range
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 129];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 31);

% Number of repositions during drift at park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 130];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 32);

% Number of EV actions during drift at park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 131];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 35);

% Number of pump actions during drift at park
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 132];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 36);

% TECH: DESCENT TO PROF PRES

% Descent to prof start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 133];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 37);

% Descent to prof start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 134];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 38)/60);

% Descent to prof end day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 135];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 39);

% Descent to prof end hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 136];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 40)/60);

% Number of EV actions during descent to prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 137];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 41);

% Number of pump actions during descent to prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 138];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 42);

% TECH: DRIFT AT PROF PRES

% Number of entrance in prof target range
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 139];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 44);

% Number of repositions during drift at prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 140];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 45);

% Number of EV actions during drift at prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 141];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 46);

% Number of pump actions during drift at prof
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 142];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 47);

% TECH: ASCENT TO SURFACE

% Ascent start day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 143];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 50);

% Ascent start hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 144];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 51)/60);

% Start buoyancy acquisition day
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 145];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 52);

% Start buoyancy acquisition hour
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 146];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 53)/60);

% Start buoyancy acquisition date
buoyancyStartDate = refDay + a_tabTech(a_dataIndex, 52) + a_tabTech(a_dataIndex, 53)/1440;
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 147];
g_decArgo_outputNcParamValue{end+1} = ...
   datestr(buoyancyStartDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');

% Number of pump actions during ascent
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 148];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 54);

if (config_ice_mode_active_111_113_to_116(cycleNum, profNum))
   
   % Ice detection flags
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 149];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 55);
   
   % TBD (when delayed data due to Ice evasion will be available)
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   %       253 cycleNum profNum phaseNum 150];
   %    g_decArgo_outputNcParamValue{end+1} = compute_ice_detected_bit_value;
end

% TECH: GROUNDING

if (a_tabTech(a_dataIndex, 56) == 1)

   % Grounding day
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 151];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 58);
   
   % Grounding hour
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 152];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 59)/60);
end

% TECH: HANGING

if (a_tabTech(a_dataIndex, 60) == 1)

   % Hanging pressure
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 153];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 61)*10;

   % Hanging day
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 154];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 62);
   
   % Hanging hour
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 155];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 63)/60);
   
   % Hanging date
   buoyancyStartDate = refDay + a_tabTech(a_dataIndex, 62) + a_tabTech(a_dataIndex, 63)/1440;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 156];
   g_decArgo_outputNcParamValue{end+1} = ...
      datestr(buoyancyStartDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
end

% TECH: EMERGENCY ASCENT

% Number of emergency ascent
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 157];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 64);

if (a_tabTech(a_dataIndex, 64) > 0)
   
   % First emergency ascent hour
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 158];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(a_dataIndex, 65)/60);
   
   % First emergency ascent pressure
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 159];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 66)*10;
   
   % Number of pump actions during the first emergency ascent
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 160];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 67);

   % First emergency ascent day
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 161];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 68);

   % First emergency ascent date
   firstEmergencyAscentDate = refDay + a_tabTech(a_dataIndex, 68) + a_tabTech(a_dataIndex, 65)/1440;
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
      253 cycleNum profNum phaseNum 162];
   g_decArgo_outputNcParamValue{end+1} = ...
      datestr(firstEmergencyAscentDate + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
end

% TECH: MISCELLANEOUS

% Sensor board status
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 163];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 80);

% TECH: RUDICS INFORMATION

% Number of Rudics session Time-out
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 164];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 81);

% Nb of errors during rudics session
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 165];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 82);

% TECH: SESSION INFORMATION

% Iridium delay of previous session
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 166];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 83);

% GPS Fix delay of current session
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 167];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 84);

% TECH: FIRMWARE INFORMATION

% Vector firmware checksum
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 168];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 85);
idPos = find(strcmp(g_decArgo_floatConfig.STATIC.NAMES, 'CONFIG_PX_0_0_0_0_3') == 1, 1);
if (isempty(idPos))
   g_decArgo_floatConfig.STATIC.NAMES{end+1} = 'CONFIG_PX_0_0_0_0_3';
   g_decArgo_floatConfig.STATIC.VALUES{end+1} = num2str(a_tabTech(a_dataIndex, 85));
   if (size(g_decArgo_floatConfig.STATIC.NAMES, 2) > size(g_decArgo_floatConfig.STATIC.NAMES, 1))
      g_decArgo_floatConfig.STATIC.NAMES = g_decArgo_floatConfig.STATIC.NAMES';
      g_decArgo_floatConfig.STATIC.VALUES = g_decArgo_floatConfig.STATIC.VALUES';
   end
else
   g_decArgo_floatConfig.STATIC.VALUES{idPos} = num2str(a_tabTech(a_dataIndex, 85));
end

% Measure firmware checksum
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
%    253 cycleNum profNum phaseNum 169];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 86);
idPos = find(strcmp(g_decArgo_floatConfig.STATIC.NAMES, 'CONFIG_PX_0_0_0_0_4') == 1, 1);
if (isempty(idPos))
   g_decArgo_floatConfig.STATIC.NAMES{end+1} = 'CONFIG_PX_0_0_0_0_4';
   g_decArgo_floatConfig.STATIC.VALUES{end+1} = num2str(a_tabTech(a_dataIndex, 86));
   if (size(g_decArgo_floatConfig.STATIC.NAMES, 2) > size(g_decArgo_floatConfig.STATIC.NAMES, 1))
      g_decArgo_floatConfig.STATIC.NAMES = g_decArgo_floatConfig.STATIC.NAMES';
      g_decArgo_floatConfig.STATIC.VALUES = g_decArgo_floatConfig.STATIC.VALUES';
   end
else
   g_decArgo_floatConfig.STATIC.VALUES{idPos} = num2str(a_tabTech(a_dataIndex, 86));
end

% TECH: AUTOTEST INFORMATION

% Auotest Result
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex; ...
   253 cycleNum profNum phaseNum 170];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(a_dataIndex, 87);

return
