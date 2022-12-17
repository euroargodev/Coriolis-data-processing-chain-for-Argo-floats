% ------------------------------------------------------------------------------
% Create the OCR profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_ocr_126_to_129_131(a_ocrData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_ocrData  : CTS5-USEA OCR data
%   a_timeData : decoded time data
%   a_gpsData  : GPS data
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
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
   process_profile_ir_rudics_cts5_usea_ocr_126_to_129_131(a_ocrData, a_timeData, a_gpsData)

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
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;
global g_decArgo_treatAverageAndMedian;
global g_decArgo_treatAverageAndStDevAndMedian;

% codes for CTS5 phases
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_DW;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamListCtd;
global g_decArgo_addParamListRadiometry;


if (isempty(a_ocrData))
   return
end

% process the profiles
for idP = 1:length(a_ocrData)
   
   dataStruct = a_ocrData{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing OCR profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end
   
   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 2;
   profStruct.payloadSensorNumber = 3;
   
   % store data measurements
   if (~isempty(data))
      
      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
            % OCR (raw) (mean) (decimated raw)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
            paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
            paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
            paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');
            
            profStruct.paramList = [ ...
               paramPres paramIr1 paramIr2 paramIr3 paramPar ...
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
            % OCR (mean & stDev)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
            paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
            paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
            paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');
            paramIr1StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380_STD');
            paramIr2StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412_STD');
            paramIr3StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490_STD');
            paramParStDev = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR_STD');
            
            profStruct.paramList = [ ...
               paramPres paramIr1 paramIr2 paramIr3 paramPar ...
               paramIr1StDev paramIr2StDev paramIr3StDev paramParStDev ...
               ];
            
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDev;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE380_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE412_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE490_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_PAR_STD';
            g_decArgo_addParamListRadiometry = unique(g_decArgo_addParamListRadiometry, 'stable');

         case g_decArgo_cts5Treat_AM_MD
            % OCR (mean & median)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
            paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
            paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
            paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramIr1Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380_MED');
            paramIr2Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412_MED');
            paramIr3Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490_MED');
            paramParMed = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR_MED');
            
            profStruct.paramList = [ ...
               paramPres paramIr1 paramIr2 paramIr3 paramPar ...
               paramPresMed paramIr1Med paramIr2Med paramIr3Med paramParMed ...
               ];

            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndMedian;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'PRES_MED';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');

            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE380_MED';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE412_MED';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE490_MED';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_PAR_MED';
            g_decArgo_addParamListRadiometry = unique(g_decArgo_addParamListRadiometry, 'stable');

         case g_decArgo_cts5Treat_AM_SD_MD
            % OCR (mean & stDev & median)

            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramIr1 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380');
            paramIr2 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412');
            paramIr3 = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490');
            paramPar = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR');
            paramIr1StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380_STD');
            paramIr2StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412_STD');
            paramIr3StDev = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490_STD');
            paramParStDev = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR_STD');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramIr1Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE380_MED');
            paramIr2Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE412_MED');
            paramIr3Med = get_netcdf_param_attributes('RAW_DOWNWELLING_IRRADIANCE490_MED');
            paramParMed = get_netcdf_param_attributes('RAW_DOWNWELLING_PAR_MED');
            
            profStruct.paramList = [ ...
               paramPres paramIr1 paramIr2 paramIr3 paramPar ...
               paramIr1StDev paramIr2StDev paramIr3StDev paramParStDev ...
               paramPresMed paramIr1Med paramIr2Med paramIr3Med paramParMed ...
               ];

            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDevAndMedian;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'PRES_MED';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');

            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE380_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE380_MED';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE412_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE412_MED';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE490_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_IRRADIANCE490_MED';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_PAR_STD';
            g_decArgo_addParamListRadiometry{end+1} = 'RAW_DOWNWELLING_PAR_MED';
            g_decArgo_addParamListRadiometry = unique(g_decArgo_addParamListRadiometry, 'stable');

         otherwise
            fprintf('ERROR: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Treatment #%d not managed - OCR data ignored\n', ...
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

return
