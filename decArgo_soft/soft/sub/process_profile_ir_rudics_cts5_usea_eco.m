% ------------------------------------------------------------------------------
% Create the ECO profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_eco(a_ecoData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_ecoData  : CTS5-USEA ECO data
%   a_timeData : decoded time data
%   a_gpsData  : GPS data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles : created output profiles
%   o_tabDrift    : created output drift measurement profiles
%   o_tabSurf     : created output surface measurement profiles
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_eco(a_ecoData, a_timeData, a_gpsData)

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
global g_decArgo_phaseAscProf;
global g_decArgo_phaseSatTrans;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatDecimatedRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;
global g_decArgo_treatAverageAndMedian;
global g_decArgo_treatAverageAndStDevAndMedian;

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_DW;


if (isempty(a_ecoData))
   return
end

% process the profiles
for idP = 1:length(a_ecoData)
   
   dataStruct = a_ecoData{idP};
   phaseId = dataStruct.phaseId;
   treatId = dataStruct.treatId;
   data = dataStruct.data;
   
   if (phaseId == g_decArgo_cts5PhaseDescent)
      phaseNum = g_decArgo_phaseDsc2Prk;
   elseif (phaseId == g_decArgo_cts5PhaseAscent)
      phaseNum = g_decArgo_phaseAscProf;
   elseif (phaseId == g_decArgo_cts5PhasePark)
      phaseNum = g_decArgo_phaseParkDrift;
   elseif (phaseId == g_decArgo_cts5PhaseSurface)
      phaseNum = g_decArgo_phaseSatTrans;
   else
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end
   
   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 3;
   profStruct.payloadSensorNumber = 4;
      
   % store data measurements
   if (~isempty(data))
      
      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
            % ECO (raw) (mean) (decimated raw)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
            paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
            paramFluorescenceCdom = get_netcdf_param_attributes('FLUORESCENCE_CDOM');

            profStruct.paramList = [ ...
               paramPres paramFluorescenceChla paramBetaBackscattering700 paramFluorescenceCdom ...
               ];
            
            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            elseif (treatId == g_decArgo_cts5Treat_AM)
               profStruct.treatType = g_decArgo_treatAverage;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end
            
         case g_decArgo_cts5Treat_AM_SD
            % ECO (mean & stDev)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
            paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
            paramFluorescenceCdom = get_netcdf_param_attributes('FLUORESCENCE_CDOM');
            paramFluorescenceChlaStDev = get_netcdf_param_attributes('FLUORESCENCE_CHLA_STD');
            paramBetaBackscattering700StDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_STD');
            paramFluorescenceCdomStDev = get_netcdf_param_attributes('FLUORESCENCE_CDOM_STD');
            
            profStruct.paramList = [ ...
               paramPres paramFluorescenceChla paramBetaBackscattering700 paramFluorescenceCdom ...
               paramFluorescenceChlaStDev paramBetaBackscattering700StDev paramFluorescenceCdomStDev ...
               ];
            
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDev;
            
         case g_decArgo_cts5Treat_AM_MD
            % ECO (mean & median)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
            paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
            paramFluorescenceCdom = get_netcdf_param_attributes('FLUORESCENCE_CDOM');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramFluorescenceChlaMed = get_netcdf_param_attributes('FLUORESCENCE_CHLA_MED');
            paramBetaBackscattering700Med = get_netcdf_param_attributes('BETA_BACKSCATTERING700_MED');
            paramFluorescenceCdomMed = get_netcdf_param_attributes('FLUORESCENCE_CDOM_MED');
            
            profStruct.paramList = [ ...
               paramPres paramFluorescenceChla paramBetaBackscattering700 paramFluorescenceCdom ...
               paramPresMed paramFluorescenceChlaMed paramBetaBackscattering700Med paramFluorescenceCdomMed ...
               ];
            
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndMedian;
            
         case g_decArgo_cts5Treat_AM_SD_MD
            % ECO (mean & stDev & median)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramFluorescenceChla = get_netcdf_param_attributes('FLUORESCENCE_CHLA');
            paramBetaBackscattering700 = get_netcdf_param_attributes('BETA_BACKSCATTERING700');
            paramFluorescenceCdom = get_netcdf_param_attributes('FLUORESCENCE_CDOM');
            paramFluorescenceChlaStDev = get_netcdf_param_attributes('FLUORESCENCE_CHLA_STD');
            paramBetaBackscattering700StDev = get_netcdf_param_attributes('BETA_BACKSCATTERING700_STD');
            paramFluorescenceCdomStDev = get_netcdf_param_attributes('FLUORESCENCE_CDOM_STD');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramFluorescenceChlaMed = get_netcdf_param_attributes('FLUORESCENCE_CHLA_MED');
            paramBetaBackscattering700Med = get_netcdf_param_attributes('BETA_BACKSCATTERING700_MED');
            paramFluorescenceCdomMed = get_netcdf_param_attributes('FLUORESCENCE_CDOM_MED');
            
            profStruct.paramList = [ ...
               paramPres paramFluorescenceChla paramBetaBackscattering700 paramFluorescenceCdom ...
               paramFluorescenceChlaStDev paramBetaBackscattering700StDev paramFluorescenceCdomStDev ...
               paramPresMed paramFluorescenceChlaMed paramBetaBackscattering700Med paramFluorescenceCdomMed ...
               ];
                        
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDevAndMedian;
            
         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - DO data ignored\n', ...
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
