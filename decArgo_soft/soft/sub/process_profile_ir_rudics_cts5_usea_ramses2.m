% ------------------------------------------------------------------------------
% Create the RAMSES2 profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_ramses2(a_ramses2Data, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_ramses2Data : CTS5-USEA RAMSES V2 data
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
%   06/30/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_ramses2(a_ramses2Data, a_timeData, a_gpsData)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
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
global g_decArgo_cts5Treat_DW;


if (isempty(a_ramses2Data))
   return
end

% process the profiles
for idP = 1:length(a_ramses2Data)
   
   dataStruct = a_ramses2Data{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing RAMSES2 profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end
   
   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 112;
   profStruct.payloadSensorNumber = 21;
      
   % store data measurements
   if (~isempty(data))
      
      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_DW}
            % RAMSES V2 (raw) (decimated raw)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramRadiometerIntegrationTime = get_netcdf_param_attributes('RADIOMETER_UP_RAD_INTEGRATION_TIME');
            paramRadiometerPrePres = get_netcdf_param_attributes('RADIOMETER_UP_RAD_PRE_PRES');
            paramRadiometerPostPres = get_netcdf_param_attributes('RADIOMETER_UP_RAD_POST_PRES');
            paramRadiometerPreInclination = get_netcdf_param_attributes('RADIOMETER_UP_RAD_PRE_INCLINATION');
            paramRadiometerPostInclination = get_netcdf_param_attributes('RADIOMETER_UP_RAD_POST_INCLINATION');
            paramRadiometerDarkAverage = get_netcdf_param_attributes('RADIOMETER_UP_RAD_DARK_AVERAGE');
            paramRawUpwellingRadiance = get_netcdf_param_attributes('RAW_UPWELLING_RADIANCE');
            
            profStruct.paramList = [ ...
               paramPres paramRadiometerIntegrationTime ...
               paramRadiometerPrePres paramRadiometerPostPres ...
               paramRadiometerPreInclination paramRadiometerPostInclination ...
               paramRadiometerDarkAverage paramRawUpwellingRadiance];
            
            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end
            
         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - RAMSES V2 data ignored\n', ...
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
