% ------------------------------------------------------------------------------
% Create the OPUS-LIGHT profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf, o_nValues] = ...
%    process_profile_cts5_usea_opus_light_v2(a_opusLightV2Data, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_opusLightV2Data : CTS5-USEA OPUS-LIGHT V2 data
%   a_timeData        : decoded time data
%   a_gpsData         : GPS data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles  : created output profiles
%   o_tabDrift     : created output drift measurement profiles
%   o_tabDesc2Prof : created output descent 2 prof measurement profiles
%   o_tabDeepDrift : created output deep drift measurement profiles
%   o_tabSurf      : created output surface measurement profiles
%   o_nValues      : N_VALUES dimension of OPUS-LIGHT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/16/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf, o_nValues] = ...
   process_profile_cts5_usea_opus_light_v2(a_opusLightV2Data, a_timeData, a_gpsData)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabDesc2Prof = [];
o_tabDeepDrift = [];
o_tabSurf = [];
o_nValues = [];

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

% sensor list
global g_decArgo_sensorMountedOnFloat;


if (isempty(a_opusLightV2Data))
   return
end

% process the profiles
tabNValues = [];
for idP = 1:length(a_opusLightV2Data)

   dataStruct = a_opusLightV2Data{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing OPUS-LIGHT profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end

   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 108;
   profStruct.payloadSensorNumber = 15;

   % store data measurements
   if (~isempty(data))

      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_DW}
            % OPUS-LIGHT (raw) (decimated raw)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramSpectrumTypeNitrate = get_netcdf_param_attributes('SPECTRUM_TYPE_NITRATE');
            paramAveragingNitrate = get_netcdf_param_attributes('AVERAGING_NITRATE');
            paramFlashCountNitrate = get_netcdf_param_attributes('FLASH_COUNT_NITRATE');
            paramLampRef1 = get_netcdf_param_attributes('LAMP_REFERENCE_1');
            if (~any(strcmp(g_decArgo_sensorMountedOnFloat, 'SUNA')))
               paramTempSpectrophotometerNitrate = get_netcdf_param_attributes('TEMP_SPECTROPHOTOMETER_NITRATE');
               paramUvIntensityNitrate = get_netcdf_param_attributes('UV_INTENSITY_NITRATE');
            else
               paramTempSpectrophotometerNitrate = get_netcdf_param_attributes('TEMP_SPECTROPHOTOMETER_NITRATE_2');
               paramUvIntensityNitrate = get_netcdf_param_attributes('UV_INTENSITY_NITRATE_2');
            end
            paramUvIntensityDarkNitrateAvg = get_netcdf_param_attributes('UV_INTENSITY_DARK_NITRATE_AVG');
            paramUvIntensityDarkNitrateSd = get_netcdf_param_attributes('UV_INTENSITY_DARK_NITRATE_SD');

            profStruct.paramList = [ ...
               paramPres ...
               paramSpectrumTypeNitrate ...
               paramAveragingNitrate ...
               paramFlashCountNitrate ...
               paramTempSpectrophotometerNitrate ...
               paramLampRef1 ...
               paramUvIntensityNitrate ...
               paramUvIntensityDarkNitrateAvg ...
               paramUvIntensityDarkNitrateSd ...
               ];

            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end

         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - OPUS-LIGHT data ignored\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNumFloat, ...
               g_decArgo_patternNumFloat, ...
               treatId);
            continue
      end

      profStruct.dateList = paramJuld;

      profStruct.paramNumberWithSubLevels = 7;
      nbF = unique(data(:, 8));
      nbB = unique(data(:, 264));
      profStruct.paramNumberOfSubLevels = nbF + nbB;
      tabNValues = [tabNValues profStruct.paramNumberOfSubLevels];

      profStruct.data = [data(:, [2:7 9:9+nbF-1 265:265+nbB-1]) ...
         ones(size(data, 1), 1)*paramUvIntensityDarkNitrateAvg.fillValue ones(size(data, 1), 1)*paramUvIntensityDarkNitrateSd.fillValue];

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
      o_nValues = unique(tabNValues);
   end
end

return
