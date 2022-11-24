% ------------------------------------------------------------------------------
% Store technical message #1 data for output NetCDF file.
%
% SYNTAX :
%  store_tech1_data_for_nc_213_214_217(a_tabTech1, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech1  : decoded technical data
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
%   02/16/2018 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech1_data_for_nc_213_214_217(a_tabTech1, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


if (isempty(a_tabTech1))
   return
end

% retrieve technical message #1 data
idF1 = find(a_tabTech1(:, 1) == 0);
if (length(idF1) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message #1 in the buffer - using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
end
tabTech1 = a_tabTech1(idF1(end), :);

ID_OFFSET = 1;

if (a_deepCycle == 1)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 100];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d', ...
      tabTech1(7+ID_OFFSET)+2000, tabTech1(6+ID_OFFSET), tabTech1(5+ID_OFFSET));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 101];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(8+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 102];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(9+ID_OFFSET)/60);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 103];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(10+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 104];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(11+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 105];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(12+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 106];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(13+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 107];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(14+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 108];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(15+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 109];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(16+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 110];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(17+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 111];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', tabTech1(20+ID_OFFSET));

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(21+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 113];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(22+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 114];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(25+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 115];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(26+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 116];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(27+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 117];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(28+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 118];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(29+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 119];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(30+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 120];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(32+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 121];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(33+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 122];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(34+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 123];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(35+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 124];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(38+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 125];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech1(39+ID_OFFSET)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 126];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(40+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 127];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(47+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 128];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(48+ID_OFFSET)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 129];
   g_decArgo_outputNcParamValue{end+1} = 15-tabTech1(49+ID_OFFSET)/10;

   rtcStatus = tabTech1(50+ID_OFFSET);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 130];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 131];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(51+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 136];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(52+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1000];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(61+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 132];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(62+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 133];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(64+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 134];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(65+ID_OFFSET);

   if (tabTech1(66+ID_OFFSET) == 1)
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 135];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech1(72+ID_OFFSET)+2000, tabTech1(71+ID_OFFSET), tabTech1(70+ID_OFFSET), ...
         tabTech1(67+ID_OFFSET), tabTech1(68+ID_OFFSET), tabTech1(69+ID_OFFSET));
   end
   
else
   
   offset = 10000;

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 127+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(47+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 128+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(48+ID_OFFSET)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 129+offset];
   g_decArgo_outputNcParamValue{end+1} = 15-tabTech1(49+ID_OFFSET)/10;
   
   rtcStatus = tabTech1(50+ID_OFFSET);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 130+offset];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 131+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(51+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1000+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(61+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 132+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(62+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 133+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(64+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 134+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech1(65+ID_OFFSET);

   if (tabTech1(66+ID_OFFSET))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 135+offset];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech1(72+ID_OFFSET)+2000, tabTech1(71+ID_OFFSET), tabTech1(70+ID_OFFSET), ...
         tabTech1(67+ID_OFFSET), tabTech1(68+ID_OFFSET), tabTech1(69+ID_OFFSET));
   end
   
end

return
