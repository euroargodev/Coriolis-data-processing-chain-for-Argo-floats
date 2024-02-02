% ------------------------------------------------------------------------------
% Create the UVP-BLACK V2 profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_uvp_black_v2(a_uvpBlackDataV2, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_uvpBlackDataV2 : CTS5-USEA UVP-BLACK V2 data
%   a_timeData       : decoded time data
%   a_gpsData        : GPS data
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
%   07/01/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_uvp_black_v2(a_uvpBlackDataV2, a_timeData, a_gpsData)

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
global g_decArgo_treatAverage;

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_DW;


if (isempty(a_uvpBlackDataV2))
   return
end

% process the profiles
for idP = 1:length(a_uvpBlackDataV2)

   dataStruct = a_uvpBlackDataV2{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing UVP-BLACK V2 profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end

   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 107;
   profStruct.payloadSensorNumber = 8;

   % store data measurements
   if (~isempty(data))

      switch (treatId)
         case {g_decArgo_cts5Treat_RW}
            % UVP-BLACK V2 (raw)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramBlackNbImPart = get_netcdf_param_attributes('BLACK_NB_IMAGE_PARTICLES');
            paramBlackTempParticles = get_netcdf_param_attributes('BLACK_TEMP_PARTICLES');
            paramBlackNbSizeSpecPart = get_netcdf_param_attributes('BLACK_NB_SIZE_SPECTRA_PARTICLES');

            profStruct.paramList = [ ...
               paramPres paramBlackNbImPart paramBlackTempParticles paramBlackNbSizeSpecPart ...
               ];
            profStruct.paramNumberWithSubLevels = [4];
            profStruct.paramNumberOfSubLevels = [5];

            profStruct.treatType = g_decArgo_treatRaw;

         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - UVP-BLACK V2 data ignored\n', ...
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
