% ------------------------------------------------------------------------------
% Store technical message data for output NetCDF file.
%
% SYNTAX :
%  store_tech_data_for_nc_209(a_tabTech, a_deepCycle)
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
%   07/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech_data_for_nc_209(a_tabTech, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


% retrieve technical message data
if (size(a_tabTech, 1) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer => using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      size(a_tabTech, 1));
end
tabTech = a_tabTech(end, :);

if (a_deepCycle == 1)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 100];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(4)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 101];
   g_decArgo_outputNcParamValue{end+1} = tabTech(5);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 102];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(6)/60);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 103];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(7)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 104];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(8)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 105];
   g_decArgo_outputNcParamValue{end+1} = tabTech(9);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 106];
   g_decArgo_outputNcParamValue{end+1} = tabTech(10);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 107];
   g_decArgo_outputNcParamValue{end+1} = tabTech(13);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 108];
   g_decArgo_outputNcParamValue{end+1} = tabTech(14);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 109];
   g_decArgo_outputNcParamValue{end+1} = tabTech(17);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 110];
   g_decArgo_outputNcParamValue{end+1} = tabTech(18);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 111];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(19)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(20)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 113];
   g_decArgo_outputNcParamValue{end+1} = tabTech(21);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 114];
   g_decArgo_outputNcParamValue{end+1} = tabTech(22);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 115];
   g_decArgo_outputNcParamValue{end+1} = tabTech(24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 116];
   g_decArgo_outputNcParamValue{end+1} = tabTech(25);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 117];
   g_decArgo_outputNcParamValue{end+1} = tabTech(26);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 118];
   g_decArgo_outputNcParamValue{end+1} = tabTech(27);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 119];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(30)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 120];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(31)/60);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 121];
   g_decArgo_outputNcParamValue{end+1} = tabTech(32);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 122];
   g_decArgo_outputNcParamValue{end+1} = tabTech(33);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 123];
   g_decArgo_outputNcParamValue{end+1} = tabTech(34);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 124];
   g_decArgo_outputNcParamValue{end+1} = tabTech(35);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 125];
   g_decArgo_outputNcParamValue{end+1} = tabTech(36);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 126];
   g_decArgo_outputNcParamValue{end+1} = tabTech(37);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 127];
   g_decArgo_outputNcParamValue{end+1} = tabTech(38);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 128];
   g_decArgo_outputNcParamValue{end+1} = tabTech(39);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 129];
   g_decArgo_outputNcParamValue{end+1} = tabTech(40);
   
   pres = sensor_2_value_for_pressure_204_to_209(tabTech(41));
   temp = sensor_2_value_for_temperature_204_to_214(tabTech(42));
   psal = tabTech(43)/1000;
   if (any([pres temp psal] ~= 0))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 145];
      g_decArgo_outputNcParamValue{end+1} = pres;
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 130];
   g_decArgo_outputNcParamValue{end+1} = tabTech(50);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 131];
   g_decArgo_outputNcParamValue{end+1} = tabTech(51)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 132];
   g_decArgo_outputNcParamValue{end+1} = 10-tabTech(52)/10;
   
   rtcStatus = tabTech(53);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 133];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 134];
   g_decArgo_outputNcParamValue{end+1} = tabTech(54);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 135];
   g_decArgo_outputNcParamValue{end+1} = tabTech(55);
   
   if (tabTech(55) == 1)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 136];
      g_decArgo_outputNcParamValue{end+1} = tabTech(57);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 137];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(58)/60);
      
   end
   
   if (tabTech(59) > 0)
   
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 138];
      g_decArgo_outputNcParamValue{end+1} = tabTech(59);
   
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 139];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech(60)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 140];
      g_decArgo_outputNcParamValue{end+1} = tabTech(61);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 141];
      g_decArgo_outputNcParamValue{end+1} = tabTech(62);

      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 142];
      g_decArgo_outputNcParamValue{end+1} = tabTech(63);

   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 143];
   g_decArgo_outputNcParamValue{end+1} = tabTech(64);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 144];
   g_decArgo_outputNcParamValue{end+1} = tabTech(65);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1000];
   g_decArgo_outputNcParamValue{end+1} = tabTech(74);

   sbeOptodeStatus = a_tabTech(76);
   if (sbeOptodeStatus == 0)
      sbeOptodeStatus = 1;
   else
      sbeOptodeStatus = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 148];
   g_decArgo_outputNcParamValue{end+1} = sbeOptodeStatus;

   aaOptodeStatus = a_tabTech(77);
   if (aaOptodeStatus == 0)
      aaOptodeStatus = 1;
   else
      aaOptodeStatus = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 149];
   g_decArgo_outputNcParamValue{end+1} = aaOptodeStatus;

else
   
   offset = 10000;

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 130+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech(50);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 131+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech(51)*5;
   
   rtcStatus = tabTech(53);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 133+offset];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 143+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech(64);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 144+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech(65);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1000+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech(74);
   
end

return;
