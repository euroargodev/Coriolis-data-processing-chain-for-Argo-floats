% ------------------------------------------------------------------------------
% Create the RAMSES profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_ramses(a_ramsesData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_ramsesData : CTS5-USEA RAMSES data
%   a_timeData   : decoded time data
%   a_gpsData    : GPS data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : created output profiles
%   o_tabDrift     : created output drift measurement profiles
%   o_tabDesc2Prof : created output descent 2 prof measurement profiles
%   o_tabDeepDrift : created output deep drift measurement profiles
%   o_tabSurf      : created output surface measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/17/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_ramses(a_ramsesData, a_timeData, a_gpsData)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabDesc2Prof = [];
o_tabDeepDrift = [];
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
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatDecimatedRaw;

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_DW;


if (isempty(a_ramsesData))
   return
end

% process the profiles
for idP = 1:length(a_ramsesData)

   dataStruct = a_ramsesData{idP};
   phaseId = dataStruct.phaseId;
   treatId = dataStruct.treatId;
   data = dataStruct.data;

   if (phaseId == g_decArgo_cts5PhaseDescent)
      phaseNum = g_decArgo_phaseDsc2Prk;
   elseif (phaseId == g_decArgo_cts5PhasePark)
      phaseNum = g_decArgo_phaseParkDrift;
   elseif (phaseId == g_decArgo_cts5PhaseDeepProfile)
      phaseNum = g_decArgo_phaseDsc2Prof;
   elseif (phaseId == g_decArgo_cts5PhaseShortPark)
      phaseNum = g_decArgo_phaseProfDrift;
   elseif (phaseId == g_decArgo_cts5PhaseAscent)
      phaseNum = g_decArgo_phaseAscProf;
   elseif (phaseId == g_decArgo_cts5PhaseSurface)
      phaseNum = g_decArgo_phaseSatTrans;
   else
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing RAMSES profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end

   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 109;
   profStruct.payloadSensorNumber = 14;

   % store data measurements
   if (~isempty(data))

      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_DW}
            % RAMSES (raw) (decimated raw)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramRadiometerIntegrationTime = get_netcdf_param_attributes('RADIOMETER_DOWN_IRR_INTEGRATION_TIME');
            paramRadiometerPrePres = get_netcdf_param_attributes('RADIOMETER_DOWN_IRR_PRE_PRES');
            paramRadiometerPostPres = get_netcdf_param_attributes('RADIOMETER_DOWN_IRR_POST_PRES');
            paramRadiometerPreInclination = get_netcdf_param_attributes('RADIOMETER_DOWN_IRR_PRE_INCLINATION');
            paramRadiometerPostInclination = get_netcdf_param_attributes('RADIOMETER_DOWN_IRR_POST_INCLINATION');
            paramRadiometerDarkAverage = get_netcdf_param_attributes('RADIOMETER_DOWN_IRR_DARK_AVERAGE');
            paramRawDownwellingIrradiance = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE');

            profStruct.paramList = [ ...
               paramPres paramRadiometerIntegrationTime ...
               paramRadiometerPrePres paramRadiometerPostPres ...
               paramRadiometerPreInclination paramRadiometerPostInclination ...
               paramRadiometerDarkAverage paramRawDownwellingIrradiance];

            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end

         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - RAMSES data ignored\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNumFloat, ...
               g_decArgo_patternNumFloat, ...
               treatId);
            continue
      end

      profStruct.dateList = paramJuld;

      profStruct.paramNumberWithSubLevels = 8;
      profStruct.paramNumberOfSubLevels = size(data, 2) - 9;

      data(:, 9) = []; % remove "Number of channels"
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
      elseif (phaseNum == g_decArgo_phaseProfDrift)
         o_tabDeepDrift = [o_tabDeepDrift profStruct];
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

return
