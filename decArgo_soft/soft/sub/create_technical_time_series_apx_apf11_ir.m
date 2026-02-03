% ------------------------------------------------------------------------------
% Create time series of technical data (to be stored in TECH_AUX file).
%
% SYNTAX :
%  [o_tabTechNMeas, o_tabTechAuxNMeas] = create_technical_time_series_apx_apf11_ir( ...
%    a_vitalsData, a_cycleTimeData, a_cycleNum)
%
% INPUT PARAMETERS :
%   a_vitalsData    : vitals data
%   a_cycleTimeData : cycle timings data
%   a_cycleNum      : current cycle number
%
% OUTPUT PARAMETERS :
%   o_tabTechNMeas    : N_MEASUREMENT structure of technical data time series
%   o_tabTechAuxNMeas : N_MEASUREMENT structure of AUX technical data time series
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/25/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTechNMeas, o_tabTechAuxNMeas] = create_technical_time_series_apx_apf11_ir( ...
   a_vitalsData, a_cycleTimeData, a_cycleNum)
         
% output parameters initialization
o_tabTechNMeas = [];
o_tabTechAuxNMeas = [];

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
   return
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
   ascentEndDate = a_cycleTimeData.ascentEndDate;
   if (~isempty(descentStartDate) && ~isempty(parkStartDate) && ...
         ~isempty(parkEndDate) && ~isempty(ascentStartDate) && ~isempty(ascentEndDate))
      cycleTime = [descentStartDate parkStartDate parkEndDate ascentStartDate ascentEndDate];
      cycleMc = [g_MC_DST g_MC_PST g_MC_PET g_MC_AST g_MC_AET];
      setMc = 1;
   end
end

% structure to store N_MEASUREMENT technical data
o_tabTechNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);
o_tabTechAuxNMeas = get_traj_n_meas_init_struct(a_cycleNum, -1);

% vitals log file data storage
fieldNames = fields(a_vitalsData);
for idF = 1:length(fieldNames)

   fieldName = fieldNames{idF};

   % create the parameter list
   if (strcmp(fieldName, 'VITALS_CORE'))

      paramAirBladderPresDbar = get_netcdf_param_attributes('PRESSURE_AirBladder_dbar'); % TECH
      paramAirBladderPresCount = get_netcdf_param_attributes('PRESSURE_AirBladder_COUNT'); % TECH_AUX
      paramBatteryVoltageVolt = get_netcdf_param_attributes('VOLTAGE_Battery_volts'); % TECH
      paramBatteryVoltageCount = get_netcdf_param_attributes('VOLTAGE_Battery_COUNT'); % TECH_AUX
      paramHumidityPercentRelative = get_netcdf_param_attributes('HUMIDITY_InsideHull_percent'); % TECH_AUX
      paramLeakDetectVoltageVolt = get_netcdf_param_attributes('VOLTAGE_WaterLeakInsideHullDetection_volts'); % TECH_AUX
      paramInternalVacuumPresDbar = get_netcdf_param_attributes('PRESSURE_InternalVacuum_dbar'); % TECH
      paramInternalVacuumPresCount = get_netcdf_param_attributes('PRESSURE_InternalVacuum_COUNT'); % TECH_AUX
      paramCoulombCounterMAh = get_netcdf_param_attributes('NUMBER_BatteryUsedCoulombCounts_mA_hour'); % TECH_AUX
      paramBatteryCurrentMa = get_netcdf_param_attributes('CURRENT_Battery_mA'); % TECH_AUX
      paramBatteryCurrentCount = get_netcdf_param_attributes('CURRENT_Battery_COUNT'); % TECH_AUX

      paramList = [paramAirBladderPresDbar paramAirBladderPresCount paramBatteryVoltageVolt ...
         paramBatteryVoltageCount paramHumidityPercentRelative paramLeakDetectVoltageVolt ...
         paramInternalVacuumPresDbar paramInternalVacuumPresCount paramCoulombCounterMAh ...
         paramBatteryCurrentMa paramBatteryCurrentCount];

      mappingTech = [1 3 7]; % TECH_TIME
      % mappingTech = []; % TECH_AUX_TIME
      mappingTechAux = setdiff(1:length(paramList), mappingTech);

   elseif (strcmp(fieldName, 'WD_CNT'))

      paramFirmwareWatchdogCount = get_netcdf_param_attributes('FIRMWARE_WATCHDOG_COUNT');

      paramList = paramFirmwareWatchdogCount;

      mappingTech = [];
      mappingTechAux = 1;

   else

      fprintf('ERROR: Float #%d Cycle #%d: Field ''%s'' not expected in vitals data structure - data ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, fieldName);
      continue
   end

   paramListTech = paramList(mappingTech);
   paramListTechAux = paramList(mappingTechAux);

   for idV = 1:size(a_vitalsData.(fieldName), 1)
      
      time = a_vitalsData.(fieldName)(idV, 1);
      timeAdj = a_vitalsData.(fieldName)(idV, 2);

      for idLoop = 1:2
         if (idLoop == 1)
            if (isempty(mappingTech))
               continue
            end
            tabNMeas = o_tabTechNMeas;
            paramList = paramListTech;
            mapping = mappingTech;
         else
            if (isempty(mappingTechAux))
               continue
            end
            tabNMeas = o_tabTechAuxNMeas;
            paramList = paramListTechAux;
            mapping = mappingTechAux;
         end

         done = 0;
         if (~isempty(tabNMeas.tabMeas))
            idMeas = find([tabNMeas.tabMeas.juld] == time);
            if (~isempty(idMeas))

               tabNMeas.tabMeas(idMeas).paramList = [ ...
                  tabNMeas.tabMeas(idMeas).paramList paramList];
               tabNMeas.tabMeas(idMeas).paramData = [ ...
                  tabNMeas.tabMeas(idMeas).paramData a_vitalsData.(fieldName)(idV, mapping+2)];

               tabNMeas.tabMeas = [tabNMeas.tabMeas; measStruct];
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
               measStruct.paramData = a_vitalsData.(fieldName)(idV, mapping+2);

               tabNMeas.tabMeas = [tabNMeas.tabMeas; measStruct];
            end
         end

         if (idLoop == 1)
           o_tabTechNMeas = tabNMeas;
         else
           o_tabTechAuxNMeas = tabNMeas;
         end
      end
   end
end

return
