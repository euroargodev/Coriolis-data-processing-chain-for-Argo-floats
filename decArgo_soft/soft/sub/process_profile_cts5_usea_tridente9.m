% ------------------------------------------------------------------------------
% Create the TRIDENTE profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf] = ...
%    process_profile_cts5_usea_tridente9(a_tridenteData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_tridenteData : CTS5-USEA TRIDENTE data
%   a_timeData     : decoded time data
%   a_gpsData      : GPS data
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
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/21/2025 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf] = ...
   process_profile_cts5_usea_tridente9(a_tridenteData, a_timeData, a_gpsData)

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

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListChla;
global g_decArgo_addParamListBackscattering;
global g_decArgo_addParamListCdom;

% sensor list
global g_decArgo_sensorMountedOnFloat;


if (isempty(a_tridenteData))
   return
end

% process the profiles
for idP = 1:length(a_tridenteData)

   dataStruct = a_tridenteData{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing TRIDENTE profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end

   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 114;
   profStruct.payloadSensorNumber = 24;

   % store data measurements
   if (~isempty(data))

      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
            % TRIDENTE (raw) (mean) (decimated raw)

            % create parameters
            if (ismember('TRIDENTE', g_decArgo_sensorMountedOnFloat))

               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramBetaBackscattering700Scaled = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED');
               paramChla = get_netcdf_param_attributes('CHLA');
               paramCdom = get_netcdf_param_attributes('CDOM');
               paramBetaBackscattering700ScaledMed = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_MED');
               paramChlaMed = get_netcdf_param_attributes('CHLA_MED');
               paramCdomMed = get_netcdf_param_attributes('CDOM_MED');
               paramBetaBackscattering700ScaledStDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_STD');
               paramChlaStDev = get_netcdf_param_attributes('CHLA_STD');
               paramCdomStDev = get_netcdf_param_attributes('CDOM_STD');

               profStruct.paramList = [ ...
                  paramPres paramBetaBackscattering700Scaled paramChla paramCdom ...
                  paramBetaBackscattering700ScaledMed paramChlaMed paramCdomMed ...
                  paramBetaBackscattering700ScaledStDev paramChlaStDev paramCdomStDev ...
                  ];

            elseif (ismember('TRIDENTE2', g_decArgo_sensorMountedOnFloat))

               paramJuld = get_netcdf_param_attributes('JULD');
               paramPres = get_netcdf_param_attributes('PRES');
               paramBetaBackscattering700Scaled = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED');
               paramBetaBackscattering700Scaled2 = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_2');
               paramChla2 = get_netcdf_param_attributes('CHLA_2');
               paramBetaBackscattering700ScaledMed = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_MED');
               paramBetaBackscattering700Scaled2Med = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_2_MED');
               paramChla2Med = get_netcdf_param_attributes('CHLA_2_MED');
               paramBetaBackscattering700ScaledStDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_STD');
               paramBetaBackscattering700Scaled2StDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_SCALED_2_STD');
               paramChla2StDev = get_netcdf_param_attributes('CHLA_2_STD');

               profStruct.paramList = [ ...
                  paramPres paramBetaBackscattering700Scaled paramBetaBackscattering700Scaled2 paramChla2 ...
                  paramBetaBackscattering700ScaledMed paramBetaBackscattering700Scaled2Med paramChla2Med ...
                  paramBetaBackscattering700ScaledStDev paramBetaBackscattering700Scaled2StDev paramChla2StDev ...
                  ];
            end
               
            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            elseif (treatId == g_decArgo_cts5Treat_AM)
               profStruct.treatType = g_decArgo_treatAverage;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end

            % parameter added "on the fly" to meta-data file
            if (ismember('TRIDENTE', g_decArgo_sensorMountedOnFloat))

               g_decArgo_addParamListBackscattering{end+1} = 'BETA_BACKSCATTERING700_SCALED_STD';
               g_decArgo_addParamListBackscattering{end+1} = 'BETA_BACKSCATTERING700_SCALED_MED';
               g_decArgo_addParamListBackscattering{end+1} = 'BBP700_STD';
               g_decArgo_addParamListBackscattering{end+1} = 'BBP700_MED';
               g_decArgo_addParamListBackscattering = unique(g_decArgo_addParamListBackscattering, 'stable');

               g_decArgo_addParamListChla{end+1} = 'CHLA_STD';
               g_decArgo_addParamListChla{end+1} = 'CHLA_MED';
               g_decArgo_addParamListChla = unique(g_decArgo_addParamListChla, 'stable');

               g_decArgo_addParamListCdom{end+1} = 'CDOM_STD';
               g_decArgo_addParamListCdom{end+1} = 'CDOM_MED';
               g_decArgo_addParamListCdom = unique(g_decArgo_addParamListCdom, 'stable');

            elseif (ismember('TRIDENTE2', g_decArgo_sensorMountedOnFloat))

               g_decArgo_addParamListBackscattering{end+1} = 'BETA_BACKSCATTERING700_SCALED_STD';
               g_decArgo_addParamListBackscattering{end+1} = 'BETA_BACKSCATTERING700_SCALED_2_STD';
               g_decArgo_addParamListBackscattering{end+1} = 'BETA_BACKSCATTERING700_SCALED_MED';
               g_decArgo_addParamListBackscattering{end+1} = 'BETA_BACKSCATTERING700_SCALED_2_MED';
               g_decArgo_addParamListBackscattering{end+1} = 'BBP700_2_STD';
               g_decArgo_addParamListBackscattering{end+1} = 'BBP700_3_STD';
               g_decArgo_addParamListBackscattering{end+1} = 'BBP700_2_MED';
               g_decArgo_addParamListBackscattering{end+1} = 'BBP700_3_MED';
               g_decArgo_addParamListBackscattering = unique(g_decArgo_addParamListBackscattering, 'stable');

               g_decArgo_addParamListChla{end+1} = 'CHLA_2_STD';
               g_decArgo_addParamListChla{end+1} = 'CHLA_2_MED';
               g_decArgo_addParamListChla = unique(g_decArgo_addParamListChla, 'stable');
            end

         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - ECO data ignored\n', ...
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
