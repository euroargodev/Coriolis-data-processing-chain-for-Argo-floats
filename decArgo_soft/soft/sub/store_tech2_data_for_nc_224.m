% ------------------------------------------------------------------------------
% Store technical message #2 data for output NetCDF file.
%
% SYNTAX :
%  store_tech2_data_for_nc_224(a_tabTech2, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech2  : decoded technical data
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
%   01/08/2021 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech2_data_for_nc_224(a_tabTech2, a_deepCycle)

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


if (isempty(a_tabTech2))
   return
end

% retrieve technical message #2 data
idF1 = find(a_tabTech2(:, 1) == 4);
if (length(idF1) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message #2 in the buffer - using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF1));
end
tabTech2 = a_tabTech2(idF1(end), :);

ID_OFFSET = 1;

if (a_deepCycle == 1)
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 200];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(3+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 201];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(4+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 202];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(5+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 203];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(6+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 204];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(7+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 205];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(8+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 206];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(9+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 207];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(10+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 208];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(11+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 209];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(12+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 210];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(13+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 211];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(14+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 213];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(21+ID_OFFSET);
   
   if (tabTech2(21+ID_OFFSET) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 214];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(23+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 215];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(24+ID_OFFSET)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 216];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(25+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 217];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(26+ID_OFFSET);
      
      if (tabTech2(21+ID_OFFSET) > 1)
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 218];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(28+ID_OFFSET);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 219];
         g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(29+ID_OFFSET)/60);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 220];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(30+ID_OFFSET);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 221];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(31+ID_OFFSET);
      end
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 222];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(32+ID_OFFSET);
   
   if (tabTech2(32+ID_OFFSET) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 223];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(33+ID_OFFSET)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 224];
      g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_202_210_to_214_217_222_to_225(tabTech2(34+ID_OFFSET));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 225];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(35+ID_OFFSET);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 226];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(36+ID_OFFSET);
   end

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 227];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(37+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 228];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(38+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 229];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(39+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 230];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(40+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 231];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(41+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 232];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(42+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 233];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(43+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 234];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(44+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 235];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(45+ID_OFFSET)*5;
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 236];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
      tabTech2(51+ID_OFFSET)+2000, tabTech2(50+ID_OFFSET), tabTech2(49+ID_OFFSET), ...
      tabTech2(46+ID_OFFSET), tabTech2(47+ID_OFFSET), tabTech2(48+ID_OFFSET));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 237];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(52+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 238];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(53+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 239];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(54+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 240];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(55+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 241];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(56+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 242];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(57+ID_OFFSET);
   
   % store ice detection flag reported in the tech msg only when ice detection
   % algorithm is enabled
   if (~isempty(g_decArgo_7TypePacketReceivedCyNum))
      [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
      iceUsed = get_config_value('CONFIG_IC00_', configNames, configValues);
      if (~isempty(iceUsed) && (iceUsed ~= 0))
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 1011];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(59+ID_OFFSET);
      end
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 244];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(60+ID_OFFSET)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 245];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(61+ID_OFFSET)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 246];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(63+ID_OFFSET)/1000;

else
   
   offset = 10000;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 227+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(37+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 228+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(38+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 229+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(39+ID_OFFSET);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 230+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(40+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 231+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(41+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 232+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(42+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 233+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(43+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 236+offset];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
      tabTech2(51+ID_OFFSET)+2000, tabTech2(50+ID_OFFSET), tabTech2(49+ID_OFFSET), ...
      tabTech2(46+ID_OFFSET), tabTech2(47+ID_OFFSET), tabTech2(48+ID_OFFSET));
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 237+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(52+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 238+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(53+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 239+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(54+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 240+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(55+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 241+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(56+ID_OFFSET);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 242+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(57+ID_OFFSET);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 244+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(60+ID_OFFSET)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 245+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(61+ID_OFFSET)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 246+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(63+ID_OFFSET)/1000;

end

return
