% ------------------------------------------------------------------------------
% Store technical message #2 data for output NetCDF file.
%
% SYNTAX :
%  store_tech2_data_for_nc_218(a_tabTech, a_deepCycle, a_iceDetected)
%
% INPUT PARAMETERS :
%   a_tabTech     : decoded technical data
%   a_deepCycle   : deep cycle flag
%   a_iceDetected : ice detected flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/02/2019 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech2_data_for_nc_218(a_tabTech, a_deepCycle, a_iceDetected)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% to detect ICE mode activation
global g_decArgo_7TypePacketReceivedCyNum;


if (isempty(a_tabTech))
   return
end

% retrieve technical message #2 data
idF2 = find(a_tabTech(:, 1) == 4);
if (length(idF2) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message #2 in the buffer => using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF2));
end
tabTech2 = a_tabTech(idF2(end), :);

if (a_deepCycle == 1)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 200];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(3);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 201];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(4);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 202];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(5);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 203];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(6);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 204];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(7);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 205];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(8);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 206];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(9);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 207];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(10);
   
   pres = sensor_2_value_for_pressure_201_203_215_216_218_221(tabTech2(11));
   temp = sensor_2_value_for_temperature_201_to_203_215_216_218_221(tabTech2(12));
   psal = tabTech2(13)/1000;
   if (any([pres temp psal] ~= 0) && (a_iceDetected == 0))
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 221];
      g_decArgo_outputNcParamValue{end+1} = pres;
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 208];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(17);
   
   if (tabTech2(17) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 209];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(19);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 210];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(20)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 227];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(21);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 211];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(22);
      
      if (tabTech2(17) > 1)
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 228];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(24);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 229];
         g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(25)/60);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 230];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(26);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 231];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(27);
         
      end
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 217];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(33);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 218];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(34);

   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 212];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(28);
   
   if (tabTech2(28) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 213];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(29)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 214];
      g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_201_203_215_216_218_221(tabTech2(30));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 215];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(31);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 216];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(32);
      
   end
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 219];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(35)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 220];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
      tabTech2(41)+2000, tabTech2(40), tabTech2(39), tabTech2(36), tabTech2(37), tabTech2(38));
      
   % store ice detection flag reported in the tech msg only when ice detection
   % algorithm is enabled
   if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      iceUsed = get_config_value('CONFIG_PG00', configNames, configValues);
      if (~isempty(iceUsed) && (iceUsed ~= 0))
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1010];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(43);
      end
   end
            
else

   offset = 10000;

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 220+offset];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech2(41)+2000, tabTech2(40), tabTech2(39), tabTech2(36), tabTech2(37), tabTech2(38));
   
end

return
