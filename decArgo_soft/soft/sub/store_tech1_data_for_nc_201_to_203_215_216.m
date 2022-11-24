% ------------------------------------------------------------------------------
% Store technical message #1 data for output NetCDF file.
%
% SYNTAX :
%  store_tech1_data_for_nc_201_to_203_215_216(a_tabTech, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech   : decoded technical data
%   a_deepCycle : deep cycle flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/14/2014 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech1_data_for_nc_201_to_203_215_216(a_tabTech, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


% retrieve technical message #1 data
idF1 = find(a_tabTech(:, 1) == 0);
if (length(idF1) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message #1 in the buffer => using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
end
tabTech1 = a_tabTech(idF1(end), :);

if (a_deepCycle == 1)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 224];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d', ...
      tabTech1(5)+2000, tabTech1(4), tabTech1(3));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 100];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(6);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 225];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(7)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 101];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(8);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 102];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(9);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 103];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(10);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 104];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(11)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 105];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(12)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 106];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(13)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 107];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(14);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 108];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(15);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 226];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', tabTech1(18));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 109];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(19);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 110];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(20);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 111];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(23);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 113];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(25)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 114];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(26)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 115];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(27);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 116];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(28);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 117];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(30);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 118];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(31);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 119];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(32);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 120];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(33);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 121];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(36)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 122];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(37)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 123];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(38);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 124];
   g_decArgo_outputNcParamValue{end+1} = twos_complement_dec_argo(tabTech1(45), 8)/10;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 125];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(46)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 126];
   g_decArgo_outputNcParamValue{end+1} = 15-tabTech1(47)/10;
   
   rtcStatus = tabTech1(48);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 127];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 128];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(49);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 129];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(50);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1000];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(59);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 130];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 131];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(61);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 132];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(62);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 133];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(63);
   
   if (tabTech1(64))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 134];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech1(70)+2000, tabTech1(69), tabTech1(68), tabTech1(65), tabTech1(66), tabTech1(67));
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 135];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(71);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 136];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(72);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 137];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(73);
   
else

   offset = 10000;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 125+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(46)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 126+offset];
   g_decArgo_outputNcParamValue{end+1} = 14-tabTech1(47)/10;
   
   rtcStatus = tabTech1(48);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 127+offset];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1000+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(59);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 130+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 131+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(61);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 132+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(62);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 133+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(63);
   
   if (tabTech1(64))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 134+offset];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech1(70)+2000, tabTech1(69), tabTech1(68), tabTech1(65), tabTech1(66), tabTech1(67));
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 135+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(71);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 136+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(72);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 137+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(73);
   
end

return;
