% ------------------------------------------------------------------------------
% Store technical message data for output NetCDF file.
%
% SYNTAX :
%  store_tech_data_for_nc_4_19_25_27_to_29(a_tabTech, a_floatTimeParts, a_utcTimeJuld, a_floatClockDrift)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical data
%   a_floatTimeParts  : float time
%   a_utcTimeJuld     : satellite time
%   a_floatClockDrift : float clock drift
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech_data_for_nc_4_19_25_27_to_29(a_tabTech, a_floatTimeParts, a_utcTimeJuld, a_floatClockDrift)

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


floatClockDrift = round(a_floatClockDrift*1440)/1440;

rtcStatus = a_tabTech(35);
if (rtcStatus == 0)
   rtcStatusOut = 1;
else
   rtcStatusOut = 0;
end
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 110];
g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 111];
g_decArgo_outputNcParamValue{end+1} = sprintf('%02d%02d%02d', ...
   a_floatTimeParts(1), a_floatTimeParts(2), a_floatTimeParts(3));

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 112];
g_decArgo_outputNcParamValue{end+1} = format_date_yyyymmddhhmiss_dec_argo(a_utcTimeJuld);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 113];
g_decArgo_outputNcParamValue{end+1} = floatClockDrift*1440;

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 115];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(1)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 116];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(3)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 118];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(7)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 120];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(33)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 122];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(34)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 124];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(23)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 127];
g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(9)*6/60-floatClockDrift*24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 210];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(2);

% in TRAJ only
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%    g_decArgo_cycleNum 211];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(4);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 212];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(5);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 213];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(6);

% in TRAJ only
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%    g_decArgo_cycleNum 214];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(22);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 220];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(11);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 222];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(14);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 223];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(15);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 224];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(14) + a_tabTech(15);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 310];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(24);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 311];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(8);

% in TRAJ only
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%    g_decArgo_cycleNum 312];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(25);

% in TRAJ only
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%    g_decArgo_cycleNum 313];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(26);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 320];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(12);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 322];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(18);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 410];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(36);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 411];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(31);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 412];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(28);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 413];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(29);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 510];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(10);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 520];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(13);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 522];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(16);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 523];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(17);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 524];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(16) + a_tabTech(17);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 610];
g_decArgo_outputNcParamValue{end+1} = a_tabTech(20);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 611];
g_decArgo_outputNcParamValue{end+1} = decode_internal_pressure(a_tabTech(21));

% in TRAJ only
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%    g_decArgo_cycleNum 414];
% g_decArgo_outputNcParamValue{end+1} = a_tabTech(30);

% in TRAJ only
% grounded = a_tabTech(27);
% if (grounded == 0)
%    groundedStr = 'No';
% else
%    groundedStr = 'Yes';
% end
% g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
%    g_decArgo_cycleNum 613];
% g_decArgo_outputNcParamValue{end+1} = groundedStr;

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 614];
g_decArgo_outputNcParamValue{end+1} = 10 - (a_tabTech(32)/10);

optodeStatus = a_tabTech(37);
if (optodeStatus == 0)
   optodeStatusOut = 1;
else
   optodeStatusOut = 0;
end
g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 616];
g_decArgo_outputNcParamValue{end+1} = optodeStatusOut;

return
