% ------------------------------------------------------------------------------
% Create the CTD profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf, o_subSurfaceMeas] = ...
%    process_profile_ir_rudics_cts5_usea_ctd(a_ctdData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_ctdData  : CTS5-USEA CTD data
%   a_timeData : decoded time data
%   a_gpsData  : GPS data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : created output profiles
%   o_tabDrift       : created output drift measurement profiles
%   o_tabDesc2Prof   : created output descent 2 prof measurement profiles
%   o_tabDeepDrift   : created output deep drift measurement profiles
%   o_tabSurf        : created output surface measurement profiles
%   o_subSurfaceMeas : created output sub surface measurement point
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabDeepDrift, o_tabSurf, o_subSurfaceMeas] = ...
   process_profile_ir_rudics_cts5_usea_ctd(a_ctdData, a_timeData, a_gpsData)

% output parameters initialization
o_tabProfiles = [];
o_tabDrift = [];
o_tabDesc2Prof = [];
o_tabDeepDrift = [];
o_tabSurf = [];
o_subSurfaceMeas = [];

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
global g_decArgo_treatAverageAndStDev;
global g_decArgo_treatAverageAndMedian;
global g_decArgo_treatAverageAndStDevAndMedian;

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_SS;
global g_decArgo_cts5Treat_DW;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListCtd;


if (isempty(a_ctdData))
   return
end

% find the subsurface point Id
subSurfaceId = [];
for idP = 1:length(a_ctdData)
   if (a_ctdData{idP}.treatId == g_decArgo_cts5Treat_SS)
      subSurfaceId = idP;
      break
   end
end

% process the profiles
for idP = 1:length(a_ctdData)

   if (idP == subSurfaceId)
      continue
   end

   ctdDataStruct = a_ctdData{idP};
   phaseId = ctdDataStruct.phaseId;
   treatId = ctdDataStruct.treatId;
   data = ctdDataStruct.data;

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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing CTD profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end

   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, -1);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 0;
   profStruct.payloadSensorNumber = 1;

   % set the CTD cut-off pressure
   if (phaseNum == g_decArgo_phaseAscProf)
      if (~isempty(subSurfaceId))
         % use the sub surface point transmitted in the CTD data
         subSurfaceMeas = a_ctdData{subSurfaceId}.data;
         if (any(subSurfaceMeas(2:end) ~= 0)) % subsurface PTS == 0 when not set (when the float didn't reach P > pump cut-off P)
            profStruct.presCutOffProf = subSurfaceMeas(2);
            profStruct.subSurfMeasReceived = 1;
            o_subSurfaceMeas = subSurfaceMeas;
         end
      end
      if (profStruct.subSurfMeasReceived == 0)
         % get the pressure cut-off for CTD ascending profile (from the
         % configuration)
         configPresCutOffProf = config_get_value_ir_rudics_cts5(g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, 'CONFIG_APMT_SENSOR_01_P54');
         if (~isempty(configPresCutOffProf) && ~isnan(configPresCutOffProf))
            profStruct.presCutOffProf = configPresCutOffProf;

            fprintf('DEC_WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): PRES_CUT_OFF_PROF parameter is missing in apmt data - value retrieved from the configuration\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNumFloat, ...
               g_decArgo_patternNumFloat);
         else
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): PRES_CUT_OFF_PROF parameter is missing in the configuration - CTD profile not split\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNumFloat, ...
               g_decArgo_patternNumFloat);
         end
      end
   end

   % store data measurements
   if (~isempty(data))

      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
            % CTD (raw) (mean) (decimated raw)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');

            profStruct.paramList = [paramPres paramTemp paramSal];

            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            elseif (treatId == g_decArgo_cts5Treat_AM)
               profStruct.treatType = g_decArgo_treatAverage;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end

         case g_decArgo_cts5Treat_AM_SD
            % CTD (mean & stDev)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');
            paramTempStDev = get_netcdf_param_attributes('TEMP_STD');
            paramSalStDev = get_netcdf_param_attributes('PSAL_STD');

            profStruct.paramList = [paramPres paramTemp paramSal paramTempStDev paramSalStDev];

            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDev;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'TEMP_STD';
            g_decArgo_addParamListCtd{end+1} = 'PSAL_STD';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');

         case g_decArgo_cts5Treat_AM_MD
            % CTD (mean & median)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramTempMed = get_netcdf_param_attributes('TEMP_MED');
            paramSalMed = get_netcdf_param_attributes('PSAL_MED');

            profStruct.paramList = [paramPres paramTemp paramSal paramPresMed paramTempMed paramSalMed];

            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndMedian;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'PRES_MED';
            g_decArgo_addParamListCtd{end+1} = 'TEMP_MED';
            g_decArgo_addParamListCtd{end+1} = 'PSAL_MED';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');

         case g_decArgo_cts5Treat_AM_SD_MD
            % CTD (mean & stDev & median)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramSal = get_netcdf_param_attributes('PSAL');
            paramTempStDev = get_netcdf_param_attributes('TEMP_STD');
            paramSalStDev = get_netcdf_param_attributes('PSAL_STD');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramTempMed = get_netcdf_param_attributes('TEMP_MED');
            paramSalMed = get_netcdf_param_attributes('PSAL_MED');

            profStruct.paramList = [paramPres paramTemp paramSal paramTempStDev paramSalStDev paramPresMed paramTempMed paramSalMed];

            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDevAndMedian;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'PRES_MED';
            g_decArgo_addParamListCtd{end+1} = 'TEMP_STD';
            g_decArgo_addParamListCtd{end+1} = 'TEMP_MED';
            g_decArgo_addParamListCtd{end+1} = 'PSAL_STD';
            g_decArgo_addParamListCtd{end+1} = 'PSAL_MED';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');

         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - CTD data ignored\n', ...
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
