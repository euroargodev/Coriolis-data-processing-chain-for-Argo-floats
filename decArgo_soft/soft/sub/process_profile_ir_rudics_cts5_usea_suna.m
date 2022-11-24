% ------------------------------------------------------------------------------
% Create the SUNA profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_suna(a_sunaData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_sunaData : CTS5-USEA SUNA data
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
%   01/21/2021 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_suna(a_sunaData, a_timeData, a_gpsData)

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

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_DW;

FITLM_MATLAB_FUNCTION_NOT_AVAILABLE = 0;


if (isempty(a_sunaData))
   return
end

% process the profiles
for idP = 1:length(a_sunaData)
   
   dataStruct = a_sunaData{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing SUNA profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end
   
   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 6;
   profStruct.payloadSensorNumber = 7;
      
   % store data measurements
   if (~isempty(data))
      
      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_DW}
            % SUNA (raw) (decimated raw)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramPsal = get_netcdf_param_attributes('PSAL');
            paramTempNitrate = get_netcdf_param_attributes('TEMP_NITRATE');
            paramTempSpectrophotometerNitrate = get_netcdf_param_attributes('TEMP_SPECTROPHOTOMETER_NITRATE');
            paramHumidityNitrate = get_netcdf_param_attributes('HUMIDITY_NITRATE');
            paramUvIntensityDarkNitrate = get_netcdf_param_attributes('UV_INTENSITY_DARK_NITRATE');
            paramUvIntensityDarkNitrateStd = get_netcdf_param_attributes('UV_INTENSITY_DARK_NITRATE_STD');
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               paramMolarNitrate = get_netcdf_param_attributes('MOLAR_NITRATE');
            end
            paramFitErrorNitrate = get_netcdf_param_attributes('FIT_ERROR_NITRATE');
            paramUvIntensityNitrate = get_netcdf_param_attributes('UV_INTENSITY_NITRATE');
            
            if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
               profStruct.paramList = [ ...
                  paramPres paramTemp paramPsal ...
                  paramTempNitrate paramTempSpectrophotometerNitrate paramHumidityNitrate ...
                  paramUvIntensityDarkNitrate paramUvIntensityDarkNitrateStd paramMolarNitrate ...
                  paramFitErrorNitrate paramUvIntensityNitrate];
            else
               profStruct.paramList = [ ...
                  paramPres paramTemp paramPsal ...
                  paramTempNitrate paramTempSpectrophotometerNitrate paramHumidityNitrate ...
                  paramUvIntensityDarkNitrate paramUvIntensityDarkNitrateStd ...
                  paramFitErrorNitrate paramUvIntensityNitrate];
            end
            
            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end
            
         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - SUNA data ignored\n', ...
               g_decArgo_floatNum, ...
               g_decArgo_cycleNum, ...
               g_decArgo_cycleNumFloat, ...
               g_decArgo_patternNumFloat, ...
               treatId);
            continue
      end
      
      profStruct.dateList = paramJuld;
      
      if (FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
         profStruct.paramNumberWithSubLevels = 11;
      else
         profStruct.paramNumberWithSubLevels = 10;
      end
      nbPix = size(data, 2) - 11;
      profStruct.paramNumberOfSubLevels = nbPix;
      
      if (~FITLM_MATLAB_FUNCTION_NOT_AVAILABLE)
         data(:, 10) = [];
      end
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
