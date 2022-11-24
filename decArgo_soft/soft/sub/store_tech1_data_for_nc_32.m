% ------------------------------------------------------------------------------
% Store technical message #1 data for output NetCDF file.
%
% SYNTAX :
%  store_tech1_data_for_nc_32(a_tabTech, a_floatClockDrift, o_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical data
%   a_floatClockDrift : float clock drift
%   o_deepCycle       : deep cycle flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/07/2016 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech1_data_for_nc_32(a_tabTech, a_floatClockDrift, o_deepCycle)

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


floatClockDrift = round(a_floatClockDrift*1440)/1440;

if (o_deepCycle == 1)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1100];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(2);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1101];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(3)*10;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1102];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(4);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1103];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(5);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1104];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(6);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1105];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(7);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1106];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(8);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1107];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(9);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1108];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(10);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1109];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(11);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1110];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(12);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1111];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(13);
   
   if (a_tabTech(18) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1112];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(15);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1113];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(16)*6/60-floatClockDrift*24);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1114];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(17);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1115];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(18);
      
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1116];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(19);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1117];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(20);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1118];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(21);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1119];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(22);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1120];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(23);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1121];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1122];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(25);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1123];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(26);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1124];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(27);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1125];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(28);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1126];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(29);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 224];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(28) + a_tabTech(29);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1127];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(30);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1128];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(31);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1129];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(32);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 524];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(31) + a_tabTech(32);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1130];
   g_decArgo_outputNcParamValue{end+1} = decode_internal_pressure(a_tabTech(33));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1131];
   g_decArgo_outputNcParamValue{end+1} = decode_internal_pressure(a_tabTech(34));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1132];
   g_decArgo_outputNcParamValue{end+1} = 15 - (a_tabTech(35)/10);
   
   rtcStatus = a_tabTech(36);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1133];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1134];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(37);
   
   if (a_tabTech(37) ~= 0)
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1135];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(38);
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1144];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(39);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1136];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(40);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1137];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(41));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1138];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(42));
   
   if (a_tabTech(43) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1139];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(43);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1140];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(44)*6/60-floatClockDrift*24);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1141];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(45);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1142];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(46);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1143];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(47);
      
   end
   
else
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1100];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(2);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1132];
   g_decArgo_outputNcParamValue{end+1} = 15 - (a_tabTech(35)/10);
   
   rtcStatus = a_tabTech(36);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1133];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1136];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(40);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1137];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(41));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1138];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(42));

end

return;
