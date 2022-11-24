% ------------------------------------------------------------------------------
% Store technical message data for output NetCDF file.
%
% SYNTAX :
%  store_tech_data_for_nc_219_220(a_tabTech)
%
% INPUT PARAMETERS :
%   a_tabTech   : decoded technical data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech_data_for_nc_219_220(a_tabTech)

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


% retrieve technical message data
tabTechDeep = [];
if (~isempty(a_tabTech))
   idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 1));
   if (length(idF) > 1)
      fprintf('WARNING: Float #%d cycle #%d: %d tech message in the buffer => using the last one\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, ...
         length(idF));
   end
   if (~isempty(idF))
      tabTechDeep = a_tabTech(idF(end), :);
   end
end
tabTechSurf = [];
if (~isempty(a_tabTech))
   idF = find((a_tabTech(:, 1) == 0) & (a_tabTech(:, end-4) == 0));
   if (~isempty(idF))
      tabTechSurf = a_tabTech(idF, :);
   end
end

if (~isempty(tabTechDeep))
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 100];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTechDeep(2)/60);
      
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 101];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTechDeep(3)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 102];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTechDeep(4)/60);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 103];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTechDeep(5)/60);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 104];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTechDeep(6)/60);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 105];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(tabTechDeep(7)/60);

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 106];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(11);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 107];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(12);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 108];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(13) + 1; % to get the total number of grounding for a deep cycle
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 109];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(17);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 110];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(18)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 111];
   g_decArgo_outputNcParamValue{end+1} = 10-tabTechDeep(19)/10;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(20);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 113];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(21);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 114];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(22);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 115];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(23);
      
   rtcStatus = tabTechDeep(31);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 116];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 117];
   g_decArgo_outputNcParamValue{end+1} = tabTechDeep(32);
end
   
offset = 10000;
for idT = 1:size(tabTechSurf, 1)

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 109+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTechSurf(idT, 17);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 110+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTechSurf(idT, 18)*5;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 111+offset];
   g_decArgo_outputNcParamValue{end+1} = 10-tabTechSurf(idT, 19)/10;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTechSurf(idT, 20);
   
   rtcStatus = tabTechSurf(idT, 31);
   if (rtcStatus == 0)
      rtcStatusOut = 1;
   else
      rtcStatusOut = 0;
   end
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 116+offset];
   g_decArgo_outputNcParamValue{end+1} = rtcStatusOut;

   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 117+offset];
   g_decArgo_outputNcParamValue{end+1} = tabTechSurf(idT, 32);
   
end

return
