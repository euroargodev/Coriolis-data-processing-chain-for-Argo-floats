% ------------------------------------------------------------------------------
% Create time series of technical data (to be stored in TECH_AUX file).
%
% SYNTAX :
%  [o_tabTechNMeas] = create_technical_time_series_apx_apf11_ir( ...
%    a_vitalsData, a_cycleTimeData, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_vitalsData    : vitals data
%   a_cycleTimeData : cycle timings data
%   a_cycleNum      : current cycle number
%
% OUTPUT PARAMETERS :
%   o_tabTechNMeas  : N_MEASUREMENT structure of technical data time series
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/05/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTechNMeas] = create_technical_time_series_apx_apf11_ir( ...
   a_vitalsData, a_cycleTimeData, a_cycleNum)
         
% output parameters initialization
o_tabTechNMeas = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% global measurement codes
global g_MC_FillValue;
global g_MC_DST;
global g_MC_PST;
global g_MC_PET;
global g_MC_AST;
global g_MC_AET;

% global time status
global g_JULD_STATUS_2;


if (isempty(a_vitalsData))
   return;
end

% cycle timings and associated MCs
% no MC is associated to TECH data sampled during cycle #0
% for cycle # > 0 it seems that TECH data are nominaly sampled at DST (once), at
% PST (once), at PET (twice), at AST (once) and at AET (once)
% => we will set one of these MCs to each TECH series
setMc = 0;
if (a_cycleNum > 0)
   descentStartDate = a_cycleTimeData.descentStartDateSci;
   parkStartDate = a_cycleTimeData.parkStartDateSci;
   parkEndDate = a_cycleTimeData.parkEndDateSci;
   ascentStartDate = a_cycleTimeData.ascentStartDateSci;
   ascentEndDate = a_cycleTimeData.ascentEndDateSci;
   if (~isempty(descentStartDate) && ~isempty(parkStartDate) && ...
         ~isempty(parkEndDate) && ~isempty(ascentStartDate) && ~isempty(ascentEndDate))
      cycleTime = [descentStartDate parkStartDate parkEndDate ascentStartDate ascentEndDate];
      cycleMc = [g_MC_DST g_MC_PST g_MC_PET g_MC_AST g_MC_AET];
      setMc = 1;
   end
end

% structure to store N_MEASUREMENT technical data
o_tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);

fieldNames = fields(a_vitalsData);
for idF = 1:length(fieldNames)
   
   fieldName = fieldNames{idF};
   
   % create the parameter list
   if (strcmp(fieldName, 'VITALS_CORE'))
      
      paramAirBladderPresDbar = get_netcdf_param_attributes('AIR_BLADDER_PRESSURE_DBAR');
      paramAirBladderPresCount = get_netcdf_param_attributes('AIR_BLADDER_PRESSURE_COUNT');
      paramBatteryVoltageVolt = get_netcdf_param_attributes('BATTERY_VOLTAGE_VOLT');
      paramBatteryVoltageCount = get_netcdf_param_attributes('BATTERY_VOLTAGE_COUNT');
      paramHumidityPercentRelative = get_netcdf_param_attributes('HUMIDITY_PERCENT_RELATIVE');
      paramLeakDetectVoltageVolt = get_netcdf_param_attributes('LEAK_DETECT_VOLTAGE_VOLT');
      paramInternalVacuumPresDbar = get_netcdf_param_attributes('INTERNAL_VACUUM_PRESSURE_DBAR');
      paramInternalVacuumPresCount = get_netcdf_param_attributes('INTERNAL_VACUUM_PRESSURE_COUNT');
      paramCoulombCounterAh = get_netcdf_param_attributes('COULOMB_COUNTER_AMPERE_HOUR');
      paramBatteryCurrentDrawMa = get_netcdf_param_attributes('BATTERY_CURRENT_DRAW_MILLI_AMPERE');
      paramBatteryCurrentRawMa = get_netcdf_param_attributes('BATTERY_CURRENT_RAW_MILLI_AMPERE');
      
      paramList = [paramAirBladderPresDbar paramAirBladderPresCount paramBatteryVoltageVolt ...
         paramBatteryVoltageCount paramHumidityPercentRelative paramLeakDetectVoltageVolt ...
         paramInternalVacuumPresDbar paramInternalVacuumPresCount paramCoulombCounterAh ...
         paramBatteryCurrentDrawMa paramBatteryCurrentRawMa];
   elseif (strcmp(fieldName, 'WD_CNT'))
      
      paramFirmwareWatchdogCount = get_netcdf_param_attributes('FIRMWARE_WATCHDOG_COUNT');
      
      paramList = [paramFirmwareWatchdogCount];
   else
      
      fprintf('WARNING: Float #%d Cycle #%d: Field ''%s'' not expected in vitals data structure => data ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, fieldName);
      continue;
   end
   
   for idV = 1:size(a_vitalsData.(fieldName), 1)
      
      time = a_vitalsData.(fieldName)(idV, 1);
      timeAdj = a_vitalsData.(fieldName)(idV, 2);
      
      done = 0;
      if (~isempty(o_tabTechNMeas.tabMeas))
         idMeas = find([o_tabTechNMeas.tabMeas.juld] == time);
         if (~isempty(idMeas))
            
            o_tabTechNMeas.tabMeas(idMeas).paramList = [ ...
               o_tabTechNMeas.tabMeas(idMeas).paramList paramList];
            o_tabTechNMeas.tabMeas(idMeas).paramData = [ ...
               o_tabTechNMeas.tabMeas(idMeas).paramData a_vitalsData.(fieldName)(idV, 3:end)];
            
            o_tabTechNMeas.tabMeas = [o_tabTechNMeas.tabMeas; measStruct];
            done = 1;
         end
      end
      
      if (~done)
         
         % determine the MC to be used
         measCode = g_MC_FillValue;
         if (setMc)
            [~, idMin] = min(abs(cycleTime-time));
            measCode = cycleMc(idMin);
         end
         
         [measStruct, ~] = create_one_meas_float_time_bis( ...
            measCode, ...
            time, ...
            timeAdj, ...
            g_JULD_STATUS_2);
         if (~isempty(measStruct))
            measStruct.paramList = paramList;
            measStruct.paramData = a_vitalsData.(fieldName)(idV, 3:end);
            
            o_tabTechNMeas.tabMeas = [o_tabTechNMeas.tabMeas; measStruct];
         end
      end
   end
end

return;
