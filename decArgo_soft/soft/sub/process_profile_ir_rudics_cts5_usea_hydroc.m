% ------------------------------------------------------------------------------
% Create the HYDROC profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_hydroc(a_hydrocMData, a_hydrocCData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_hydrocMData : CTS5-USEA HYDROC M data
%   a_hydrocCData : CTS5-USEA HYDROC C data
%   a_timeData    : decoded time data
%   a_gpsData     : GPS data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : created output profiles
%   o_tabDrift     : created output drift measurement profiles
%   o_tabDesc2Prof : created output descent 2 prof measurement profiles
%   o_tabSurf      : created output surface measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_hydroc(a_hydrocMData, a_hydrocCData, a_timeData, a_gpsData)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabDesc2Prof = [];
o_tabSurf = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle and pattern number
global g_decArgo_cycleNumFloat;
global g_decArgo_patternNumFloat;

% cycle phases
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatDecimatedRaw;

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_DW;


if (isempty(a_hydrocMData) && isempty(a_hydrocCData))
   return
end

% process the profiles
for idLoop = 1:2
   if (idLoop == 1)
      hydrocData = a_hydrocMData;
   else
      hydrocData = a_hydrocCData;
   end
   for idP = 1:length(hydrocData)

      dataStruct = hydrocData{idP};
      phaseId = dataStruct.phaseId;
      treatId = dataStruct.treatId;
      data = dataStruct.data;

      if (phaseId == g_decArgo_cts5PhaseDescent)
         phaseNum = g_decArgo_phaseDsc2Prk;
      elseif (phaseId == g_decArgo_cts5PhasePark)
         phaseNum = g_decArgo_phaseParkDrift;
      elseif (phaseId == g_decArgo_cts5PhaseDeepProfile)
         phaseNum = g_decArgo_phaseDsc2Prof;
      elseif (phaseId == g_decArgo_cts5PhaseAscent)
         phaseNum = g_decArgo_phaseAscProf;
      elseif (phaseId == g_decArgo_cts5PhaseSurface)
         phaseNum = g_decArgo_phaseSatTrans;
      else
         fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing HYDROC profiles with phase Id #%d\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            g_decArgo_cycleNumFloat, ...
            g_decArgo_patternNumFloat, ...
            phaseId);
      end

      profStruct = get_profile_init_struct( ...
         g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
      profStruct.outputCycleNumber = g_decArgo_cycleNum;
      profStruct.sensorNumber = 111;
      profStruct.payloadSensorNumber = 18;

      % store data measurements
      if (~isempty(data))

         switch (treatId)
            case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
               % HYDROC (raw) (mean) (decimated raw)

               % create parameters
               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramAcquisitionMode = get_netcdf_param_attributes('ACQUISITION_MODE');
               paramSignalRaw = get_netcdf_param_attributes('SIGNAL_RAW');
               paramSignalRef = get_netcdf_param_attributes('SIGNAL_REF');
               paramPresIn = get_netcdf_param_attributes('PRES_IN');
               paramPresNdir = get_netcdf_param_attributes('PRES_NDIR');
               paramTempNdir = get_netcdf_param_attributes('TEMP_NDIR');
               paramTempGas = get_netcdf_param_attributes('TEMP_GAS');
               paramHumidityGas = get_netcdf_param_attributes('HUMIDITY_GAS');
               paramPumpPower = get_netcdf_param_attributes('PUMP_POWER');
               paramSupplyVoltage = get_netcdf_param_attributes('SUPPLY_VOLTAGE');
               paramTotalCurrent = get_netcdf_param_attributes('TOTAL_CURRENT');
               paramRuntime = get_netcdf_param_attributes('RUNTIME');

               profStruct.paramList = [ ...
                  paramPres paramAcquisitionMode paramSignalRaw paramSignalRef ...
                  paramPresIn paramPresNdir paramTempNdir paramTempGas paramHumidityGas ...
                  paramPumpPower paramSupplyVoltage paramTotalCurrent paramRuntime];

               % treatment type
               if (treatId == g_decArgo_cts5Treat_RW)
                  profStruct.treatType = g_decArgo_treatRaw;
               else
                  profStruct.treatType = g_decArgo_treatDecimatedRaw;
               end

            otherwise
               fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - HYDROC data ignored\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  g_decArgo_cycleNumFloat, ...
                  g_decArgo_patternNumFloat, ...
                  treatId);
               continue
         end

         profStruct.dateList = paramJuld;

         profStruct.data = data(:, 2:end);
         profStruct.dates = data(:, 1);
         profStruct.datesAdj = adjust_time_cts5(profStruct.dates);

         % measurement dates
         dates = profStruct.datesAdj;
         profStruct.minMeasDate = min(dates);
         profStruct.maxMeasDate = max(dates);
      end

      if (~isempty(profStruct.paramList))

         % profile direction
         if (phaseNum == g_decArgo_phaseDsc2Prk)
            profStruct.direction = 'D';
         end

         % add profile additional information
         if (phaseNum == g_decArgo_phaseParkDrift)
            o_tabDrift = [o_tabDrift profStruct];
         elseif (phaseNum == g_decArgo_phaseDsc2Prof)
            o_tabDesc2Prof = [o_tabDesc2Prof profStruct];
         elseif (phaseNum == g_decArgo_phaseSatTrans)
            o_tabSurf = [o_tabSurf profStruct];
         else

            % positioning system
            profStruct.posSystem = 'GPS';

            % profile date and location information
            [profStruct] = add_profile_date_and_location_ir_rudics_cts5( ...
               profStruct, a_timeData, a_gpsData);

            o_tabProfiles = [o_tabProfiles profStruct];
         end
      end
   end
end

return
