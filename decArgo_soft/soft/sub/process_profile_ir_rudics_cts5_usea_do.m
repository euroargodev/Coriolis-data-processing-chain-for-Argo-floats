% ------------------------------------------------------------------------------
% Create the DO profiles of CTS5-USEA decoded data.
%
% SYNTAX :
%  [o_tabProfiles, o_tabDrift, o_tabDesc2Prof, o_tabSurf] = ...
%    process_profile_ir_rudics_cts5_usea_do(a_doData, a_timeData, a_gpsData)
%
% INPUT PARAMETERS :
%   a_doData   : CTS5-USEA DO data
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
   process_profile_ir_rudics_cts5_usea_do(a_doData, a_timeData, a_gpsData)

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
global g_decArgo_addParamListOxygen;


if (isempty(a_doData))
   return
end

% process the profiles
for idP = 1:length(a_doData)
   
   dataStruct = a_doData{idP};
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
      fprintf('WARNING: Float #%d Cycle #%d: (Cy,Ptn)=(%d,%d): Nothing done yet for processing DO profiles with phase Id #%d\n', ...
         g_decArgo_floatNum, ...
         g_decArgo_cycleNum, ...
         g_decArgo_cycleNumFloat, ...
         g_decArgo_patternNumFloat, ...
         phaseId);
   end
   
   profStruct = get_profile_init_struct( ...
      g_decArgo_cycleNumFloat, g_decArgo_patternNumFloat, phaseNum, 0);
   profStruct.outputCycleNumber = g_decArgo_cycleNum;
   profStruct.sensorNumber = 1;
   profStruct.payloadSensorNumber = 2;
      
   % store data measurements
   if (~isempty(data))
      
      switch (treatId)
         case {g_decArgo_cts5Treat_RW, g_decArgo_cts5Treat_AM, g_decArgo_cts5Treat_DW}
            % DO (raw) (mean) (decimated raw)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
            paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');

            profStruct.paramList = [ ...
               paramPres paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy ...
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
            % DO (mean & stDev)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
            paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
            paramC1PhaseDoxyStDev = get_netcdf_param_attributes('C1PHASE_DOXY_STD');
            paramC2PhaseDoxyStDev = get_netcdf_param_attributes('C2PHASE_DOXY_STD');
            paramTempDoxyStDev = get_netcdf_param_attributes('TEMP_DOXY_STD');
            
            profStruct.paramList = [ ...
               paramPres paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy ...
               paramC1PhaseDoxyStDev paramC2PhaseDoxyStDev paramTempDoxyStDev ...
               ];
            
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDev;

            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListOxygen{end+1} = 'C1PHASE_DOXY_STD';
            g_decArgo_addParamListOxygen{end+1} = 'C2PHASE_DOXY_STD';
            g_decArgo_addParamListOxygen{end+1} = 'TEMP_DOXY_STD';
            g_decArgo_addParamListOxygen = unique(g_decArgo_addParamListOxygen, 'stable');
            
         case g_decArgo_cts5Treat_AM_MD
            % DO (mean & median)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
            paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramC1PhaseDoxyMed = get_netcdf_param_attributes('C1PHASE_DOXY_MED');
            paramC2PhaseDoxyMed = get_netcdf_param_attributes('C2PHASE_DOXY_MED');
            paramTempDoxyMed = get_netcdf_param_attributes('TEMP_DOXY_MED');
            
            profStruct.paramList = [ ...
               paramPres paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy ...
               paramPresMed paramC1PhaseDoxyMed paramC2PhaseDoxyMed paramTempDoxyMed ...
               ];
            
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndMedian;
            
            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'PRES_MED';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');
            
            g_decArgo_addParamListOxygen{end+1} = 'C1PHASE_DOXY_MED';
            g_decArgo_addParamListOxygen{end+1} = 'C2PHASE_DOXY_MED';
            g_decArgo_addParamListOxygen{end+1} = 'TEMP_DOXY_MED';
            g_decArgo_addParamListOxygen = unique(g_decArgo_addParamListOxygen, 'stable');
            
         case g_decArgo_cts5Treat_AM_SD_MD
            % DO (mean & stDev & median)
            
            % create parameters
            paramJuld = get_netcdf_param_attributes('JULD');
            paramPres = get_netcdf_param_attributes('PRES');
            paramC1PhaseDoxy = get_netcdf_param_attributes('C1PHASE_DOXY');
            paramC2PhaseDoxy = get_netcdf_param_attributes('C2PHASE_DOXY');
            paramTempDoxy = get_netcdf_param_attributes('TEMP_DOXY');
            paramC1PhaseDoxyStDev = get_netcdf_param_attributes('C1PHASE_DOXY_STD');
            paramC2PhaseDoxyStDev = get_netcdf_param_attributes('C2PHASE_DOXY_STD');
            paramTempDoxyStDev = get_netcdf_param_attributes('TEMP_DOXY_STD');
            paramPresMed = get_netcdf_param_attributes('PRES_MED');
            paramC1PhaseDoxyMed = get_netcdf_param_attributes('C1PHASE_DOXY_MED');
            paramC2PhaseDoxyMed = get_netcdf_param_attributes('C2PHASE_DOXY_MED');
            paramTempDoxyMed = get_netcdf_param_attributes('TEMP_DOXY_MED');
            
            profStruct.paramList = [ ...
               paramPres paramC1PhaseDoxy paramC2PhaseDoxy paramTempDoxy ...
               paramC1PhaseDoxyStDev paramC2PhaseDoxyStDev paramTempDoxyStDev ...
               paramPresMed paramC1PhaseDoxyMed paramC2PhaseDoxyMed paramTempDoxyMed ...
               ];
                        
            % treatment type
            profStruct.treatType = g_decArgo_treatAverageAndStDevAndMedian;
            
            % parameter added "on the fly" to meta-data file
            g_decArgo_addParamListCtd{end+1} = 'PRES_MED';
            g_decArgo_addParamListCtd = unique(g_decArgo_addParamListCtd, 'stable');
            
            g_decArgo_addParamListOxygen{end+1} = 'C1PHASE_DOXY_STD';
            g_decArgo_addParamListOxygen{end+1} = 'C1PHASE_DOXY_MED';
            g_decArgo_addParamListOxygen{end+1} = 'C2PHASE_DOXY_STD';
            g_decArgo_addParamListOxygen{end+1} = 'C2PHASE_DOXY_MED';
            g_decArgo_addParamListOxygen{end+1} = 'TEMP_DOXY_STD';
            g_decArgo_addParamListOxygen{end+1} = 'TEMP_DOXY_MED';
            g_decArgo_addParamListOxygen = unique(g_decArgo_addParamListOxygen, 'stable');

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
