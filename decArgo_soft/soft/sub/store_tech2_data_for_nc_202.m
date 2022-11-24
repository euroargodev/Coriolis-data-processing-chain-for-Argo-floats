% ------------------------------------------------------------------------------
% Store technical message #2 data for output NetCDF file.
%
% SYNTAX :
%  store_tech2_data_for_nc_202(a_tabTech, a_deepCycle)
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
function store_tech2_data_for_nc_202(a_tabTech, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


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
   g_decArgo_outputNcParamValue{end+1} = tabTech2(2);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 201];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(3);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 202];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(4);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 203];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(5);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 204];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(6);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 205];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(7);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 206];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(8);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 207];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(9);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 221];
   g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_202_210_to_213(tabTech2(10));
   
   % the two following items have moved to TRAJ file
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %       g_decArgo_cycleNum 222];
   %    g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_temperature_201_202_203(tabTech2(11));
   %
   %    g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %       g_decArgo_cycleNum 223];
   %    g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_salinity_201_202_203(tabTech2(12));

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 208];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(16);
   
   if (tabTech2(16) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 209];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(18);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 210];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(19)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 227];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(20);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 211];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(21);
      
      if (tabTech2(16) > 1)
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 228];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(23);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 229];
         g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(24)/60);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 230];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(25);
         
         g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
            g_decArgo_cycleNum 231];
         g_decArgo_outputNcParamValue{end+1} = tabTech2(26);
         
      end
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 217];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(32);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 218];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(33);

   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 212];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(27);
   
   if (tabTech2(27) > 0)
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 213];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTech2(28)/60);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 214];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(29);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 215];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(30);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 216];
      g_decArgo_outputNcParamValue{end+1} = tabTech2(31);
      
   end
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 219];
   g_decArgo_outputNcParamValue{end+1} = tabTech2(34)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 220];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech2(40)+2000, tabTech2(39), tabTech2(38), tabTech2(35), tabTech2(36), tabTech2(37));

else

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 220];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%04d%02d%02d%02d%02d%02d', ...
         tabTech2(40)+2000, tabTech2(39), tabTech2(38), tabTech2(35), tabTech2(36), tabTech2(37));
   
end

return;
