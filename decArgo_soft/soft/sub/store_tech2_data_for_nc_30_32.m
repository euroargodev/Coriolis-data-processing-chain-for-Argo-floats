% ------------------------------------------------------------------------------
% Store technical message #2 data for output NetCDF file.
%
% SYNTAX :
%  store_tech2_data_for_nc_30_32(a_tabTech, a_floatTimeParts, a_utcTimeJuld, a_floatClockDrift, o_deepCycle)
%
% INPUT PARAMETERS :
%   a_tabTech         : decoded technical data
%   a_floatTimeParts  : float time
%   a_utcTimeJuld     : satellite time
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
%   05/10/2015 - RNU - creation
% ------------------------------------------------------------------------------
function store_tech2_data_for_nc_30_32(a_tabTech, a_floatTimeParts, a_utcTimeJuld, a_floatClockDrift, o_deepCycle)

% current cycle number
global g_decArgo_cycleNum;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;


floatClockDrift = round(a_floatClockDrift*1440)/1440;

if (o_deepCycle == 1)

   if ((a_tabTech(5)/60-floatClockDrift*24) >= 0)
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1200];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(3));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1201];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(4));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1202];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(5)/60-floatClockDrift*24);
   else
      [dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(a_utcTimeJuld);
      cycleStartTime = a_utcTimeJuld;
      while (a_tabTech(3) ~= dd)
         cycleStartTime = cycleStartTime - 1;
         [dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(cycleStartTime);
      end
      cycleStartTime = fix(cycleStartTime) + (a_tabTech(5)/60-floatClockDrift*24)/24;
      [dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(cycleStartTime);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1200];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', dd);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1201];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', mm);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum 1202];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%02d%02d', HH, MI);
   end
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1203];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(6)/60-floatClockDrift*24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1204];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(7)*6/60-floatClockDrift*24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1205];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(8)/60-floatClockDrift*24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1206];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(11));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1207];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(14)/60-floatClockDrift*24);
   
   % we store the transmitted time with its associated resolution
   % i.e. the modification done in compute_prv_dates_30_32 is not reported here
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1208];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(15)*6/60-floatClockDrift*24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1209];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(19)/60-floatClockDrift*24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1210];
   g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(20)/60-floatClockDrift*24);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1211];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d%02d%02d', ...
      a_floatTimeParts(1), a_floatTimeParts(2), a_floatTimeParts(3));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112];
   g_decArgo_outputNcParamValue{end+1} = format_date_yyyymmddhhmiss_dec_argo(a_utcTimeJuld);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 113];
   g_decArgo_outputNcParamValue{end+1} = floatClockDrift*1440;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1212];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(24));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1213];
   g_decArgo_outputNcParamValue{end+1} = a_tabTech(25)/10;
   
   if (g_decArgo_cycleNum > 1)
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum-1 1214];
      g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(26));
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum-1 1215];
      g_decArgo_outputNcParamValue{end+1} = format_time_hhmm_dec_argo(a_tabTech(27)*6/60-floatClockDrift*24);
      
      g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
         g_decArgo_cycleNum-1 1216];
      g_decArgo_outputNcParamValue{end+1} = a_tabTech(28);
   end

else
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1211];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d%02d%02d', ...
      a_floatTimeParts(1), a_floatTimeParts(2), a_floatTimeParts(3));
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 112];
   g_decArgo_outputNcParamValue{end+1} = format_date_yyyymmddhhmiss_dec_argo(a_utcTimeJuld);
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 113];
   g_decArgo_outputNcParamValue{end+1} = floatClockDrift*1440;
   
   g_decArgo_outputNcParamIndex = [g_decArgo_outputNcParamIndex;
      g_decArgo_cycleNum 1212];
   g_decArgo_outputNcParamValue{end+1} = sprintf('%02d', a_tabTech(24));
   
end

return;
