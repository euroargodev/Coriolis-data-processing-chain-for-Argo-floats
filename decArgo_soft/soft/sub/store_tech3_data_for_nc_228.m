% ------------------------------------------------------------------------------
% Store technical message #3 data for output NetCDF file.
%
% SYNTAX :
%  store_tech3_data_for_nc_228(a_tabTech, a_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech     : decoded technical data
%   a_deepCycle   : deep cycle flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/14/2024 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech3_data_for_nc_228(a_tabTech, a_deepCycle)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


if (isempty(a_tabTech))
   return
end

% retrieve technical message #3 data
idF3 = find(a_tabTech(:, 1) == 26);
if (length(idF3) > 1)
   fprintf('WARNING: Float #%d cycle #%d: %d tech message #3 in the buffer - using the last one\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, ...
      length(idF3));
end
tabTech3 = a_tabTech(idF3(end), :);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 300];
g_decArgo_outputNcParamValue{end+1} = tabTech3(3);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 301];
g_decArgo_outputNcParamValue{end+1} = tabTech3(4);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 302];
g_decArgo_outputNcParamValue{end+1} = tabTech3(5);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 303];
g_decArgo_outputNcParamValue{end+1} = tabTech3(6);

g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   g_decArgo_cycleNum 304];
g_decArgo_outputNcParamValue{end+1} = tabTech3(7);

if (a_deepCycle == 1)
   
   for decId = 8:32
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 305+(decId-8)];
      g_decArgo_outputNcParamValue{end+1} = tabTech3(decId);
   end

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 330];
   g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_3T_228_2T_229(tabTech3(33));

   for decId = 34:44
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 331+(decId-34)];
      g_decArgo_outputNcParamValue{end+1} = tabTech3(decId);
   end

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 342];
   g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_3T_228_2T_229(tabTech3(45));

   % TECH3 information #46 to #52 not used (seems inconsistent)
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 343];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_3T_228_2T_229(tabTech3(46));
   % 
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 344];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_temperature_3T_228_2T_229(tabTech3(47));
   % 
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 345];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_salinity_3T_228_2T_229(tabTech3(48));
   % 
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 346];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_pressure_3T_228_2T_229(tabTech3(49));
   % 
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 347];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_temperature_3T_228_2T_229(tabTech3(50));
   % 
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 348];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_salinity_3T_228_2T_229(tabTech3(51));
   % 
   % g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
   %    g_decArgo_cycleNum 349];
   % g_decArgo_outputNcParamValue{end+1} = sensor_2_value_for_temperature_3T_228_2T_229(tabTech3(52));

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 350];
   g_decArgo_outputNcParamValue{end+1} = tabTech3(53);

end

return
