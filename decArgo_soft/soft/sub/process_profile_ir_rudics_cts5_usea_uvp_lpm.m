% ------------------------------------------------------------------------------
% Create the UVP-LPM profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_uvp_lpm(a_uvpLpmData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_uvpLpmData : CTS5-USEA UVP-LPM data
%   a_timeData   : decoded time data
%   a_gpsData    : GPS data
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
   process_profile_ir_rudics_cts5_usea_uvp_lpm(a_uvpLpmData, a_timeData, a_gpsData)

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

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseAscent;
global g_decArgo_cts5PhaseSurface;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_DW;


if (isempty(a_uvpLpmData))
   return
end

% process the profiles
for idP = 1:length(a_uvpLpmData)
   
   dataStruct = a_uvpLpmData{idP};
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
   profStruct.sensorNumber = 107;
   profStruct.payloadSensorNumber = 8;
   
   % store data measurements
   if (~isempty(data))
      
      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
            % UVP-LPM (raw) (mean) (decimated raw)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramImNumPart = get_netcdf_param_attributes('IMAGE_NUMBER_PARTICLES');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTempPart = get_netcdf_param_attributes('TEMP_PARTICLES');
            paramNbSizeSpecPart = get_netcdf_param_attributes('NB_SIZE_SPECTRA_PARTICLES');
            paramGreySizeSpecPart = get_netcdf_param_attributes('GREY_SIZE_SPECTRA_PARTICLES');

            if (treatId == g_decArgo_cts5Treat_AM)
               profStruct.paramList = [ ...
                  paramPres paramImNumPart paramTempPart paramNbSizeSpecPart paramGreySizeSpecPart ...
                  ];
               profStruct.paramNumberWithSubLevels = [4 5];
               profStruct.paramNumberOfSubLevels = [18 18];
            else
               if (phaseNum == g_decArgo_phaseParkDrift)
                  profStruct.paramList = [ ...
                     paramPres paramImNumPart paramTempPart paramNbSizeSpecPart paramGreySizeSpecPart ...
                     ];
                  profStruct.paramNumberWithSubLevels = [4 5];
                  profStruct.paramNumberOfSubLevels = [18 18];
               else
                  profStruct.paramList = [ ...
                     paramPres paramTempPart paramNbSizeSpecPart paramGreySizeSpecPart ...
                     ];
                  profStruct.paramNumberWithSubLevels = [3 4 ];
                  profStruct.paramNumberOfSubLevels = [18 18];
               end
            end
            
            % treatment type
            if (treatId == g_decArgo_cts5Treat_RW)
               profStruct.treatType = g_decArgo_treatRaw;
            elseif (treatId == g_decArgo_cts5Treat_AM)
               profStruct.treatType = g_decArgo_treatAverage;
            else
               profStruct.treatType = g_decArgo_treatDecimatedRaw;
            end
            
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
      
      if (treatId == g_decArgo_cts5Treat_AM)
         profStruct.data = data(:, [3 2 4:end]);
      else
         if (phaseNum == g_decArgo_phaseParkDrift)
            profStruct.data = data(:, [3 2 4:end]);
         else
            profStruct.data = data(:, 2:end);
         end
      end
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
