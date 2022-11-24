% ------------------------------------------------------------------------------
% Process decoded data into Argo dedicated structures.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%    process_decoded_data_cts4( ...
%    a_decodedDataTab, a_refDay, a_decoderId, ...
%    a_tabProfiles, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas)
%
% INPUT PARAMETERS :
%   a_decodedDataTab : decoded data
%   a_refDay         : reference day
%   a_decoderId      : float decoder Id
%   a_tabProfiles    : input decoded profiles
%   a_tabTrajNMeas   : input decoded trajectory N_MEASUREMENT data
%   a_tabTrajNCycle  : input decoded trajectory N_CYCLE data
%   a_tabNcTechIndex : input decoded technical index information
%   a_tabNcTechVal   : input decoded technical data
%   a_tabTechNMeas   : input decoded technical PARAM data
%
% OUTPUT PARAMETERS :
%   o_tabProfiles    : output decoded profiles
%   o_tabTrajNMeas   : output decoded trajectory N_MEASUREMENT data
%   o_tabTrajNCycle  : output decoded trajectory N_CYCLE data
%   o_tabNcTechIndex : output decoded technical index information
%   o_tabNcTechVal   : output decoded technical data
%   o_tabTechNMeas   : output decoded technical PARAM data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/10/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   process_decoded_data_cts4( ...
   a_decodedDataTab, a_refDay, a_decoderId, ...
   a_tabProfiles, ...
   a_tabTrajNMeas, a_tabTrajNCycle, ...
   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas)

% output parameters initialization
o_tabProfiles = a_tabProfiles;
o_tabTrajNMeas = a_tabTrajNMeas;
o_tabTrajNCycle = a_tabTrajNCycle;
o_tabNcTechIndex = a_tabNcTechIndex;
o_tabNcTechVal = a_tabNcTechVal;
o_tabTechNMeas = a_tabTechNMeas;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% current cycle&prof number
global g_decArgo_cycleProfNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% array to store GPS data
global g_decArgo_gpsData;

% generate nc flag
global g_decArgo_generateNcFlag;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;


% no data to process
if (isempty(a_decodedDataTab))
   return
end

g_decArgo_generateNcFlag = 1;

% set information on current cycle
g_decArgo_cycleNum = unique([a_decodedDataTab.cyNumOut]);
g_decArgo_cycleProfNum = unique([a_decodedDataTab.cyNum]);
deepCycleFlag =  unique([a_decodedDataTab.deep]);

if (g_decArgo_realtimeFlag == 1)
   % update the reports structure cycle list
   g_decArgo_reportStruct.cycleList = [g_decArgo_reportStruct.cycleList g_decArgo_cycleNum];
end

% print SBD file description for output CSV file
if (~isempty(g_decArgo_outputCsvFileId))
   
   fileNameList = unique({a_decodedDataTab.fileName}, 'stable');
   fileSizeList = [a_decodedDataTab.fileSize];
   for idFile = 1:length(fileNameList)
      idForFile = find(strcmp({a_decodedDataTab.fileName}, fileNameList{idFile}));
      fprintf(g_decArgo_outputCsvFileId, '%d; %d; -; %s; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: %d\n', ...
         g_decArgo_floatNum, a_decodedDataTab(idFile).cyNumRaw, get_phase_name(-1), ...
         idFile, fileNameList{idFile}, fileSizeList(idForFile(1)), fileSizeList(idForFile(1))/140);
   end
end

fprintf('DEC_INFO: Float #%d Cycle #%d\n', ...
   g_decArgo_floatNum, g_decArgo_cycleNum);

% process decoded data

tabProfiles = [];
tabTrajNMeas = [];
tabTrajNCycle = [];
tabNcTechIndex = [];
tabNcTechVal = [];
tabTechNMeas = [];

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {111, 113, 114, 115} % Remocean V3.00 and higher
      
      % get decoded data
      [cyProfPhaseList, ...
         dataCTD, dataOXY, dataOCR, ...
         dataECO2, dataECO3, dataFLNTU, ...
         dataCROVER, dataSUNA, dataSEAFET, ...
         sensorTechCTD, sensorTechOPTODE, sensorTechOCR, ...
         sensorTechECO2, sensorTechECO3, ...
         sensorTechFLNTU, sensorTechSEAFET, ...
         sensorTechCROVER, sensorTechSUNA, ...
         tabTech, floatPres, grounding, ...
         floatProgRudics, floatProgTech, floatProgParam, floatProgSensor] = ...
         get_decoded_data_cts4(a_decodedDataTab, a_decoderId);
      
      % assign the current configuration to the current deep cycle
      if (deepCycleFlag == 1)
         set_float_config_ir_rudics_cts4_111_113_114_115(g_decArgo_cycleProfNum);
      end
      
      % update float configuration for the next cycles
      if (~isempty(floatProgRudics) || ~isempty(floatProgTech) || ...
            ~isempty(floatProgParam) || ~isempty(floatProgSensor))
         % BE CAREFUL!
         % in this firmware, configuration parameters of the second Iridium
         % session are considered one deep cycle later
         % Example: for float 3902124, the configuration parameters of the
         % cycle #56 second Iridium session are considered in cycle #58
         % => we should find the session number (with deepCycleFlag = 0 and
         % float cylce number > 0)
         irSessionNum = 1;
         if ((deepCycleFlag == 0) && (fix(g_decArgo_cycleProfNum/100) > 0))
            irSessionNum = 2;
         end
         update_float_config_ir_rudics_111_113_114_115( ...
            floatProgRudics, floatProgTech, floatProgParam, floatProgSensor, irSessionNum);
      end
      
      % keep only new GPS locations (acquired during a surface phase)
      [tabTech] = clean_gps_data_ir_rudics_111_113_114_115(tabTech);
      
      % store GPS data
      store_gps_data_ir_rudics_111_113_114_115(tabTech);
      
      % add dates to drift measurements
      [dataCTD, dataOXY, dataOCR, ...
         dataECO2, dataECO3, dataFLNTU, ...
         dataCROVER, dataSUNA, dataSEAFET, measDates] = ...
         add_drift_meas_dates_ir_rudics_111_113_114_115(a_decoderId, ...
         dataCTD, dataOXY, dataOCR, ...
         dataECO2, dataECO3, dataFLNTU, ...
         dataCROVER, dataSUNA, dataSEAFET);
      
      % set drift of float RTC
      floatClockDrift = 0;

      % compute the main dates of the cycle
      [cycleStartDate, buoyancyRedStartDate, ...
         descentToParkStartDate, ...
         firstStabDate, firstStabPres, ...
         descentToParkEndDate, ...
         descentToProfStartDate, descentToProfEndDate, ...
         ascentStartDate, ascentEndDate, ...
         transStartDate, ...
         buoyancyInvStartDate, ...
         firstGroundDate, firstGroundPres, ...
         firstHangDate, firstHangPres, ...
         firstEmerAscentDate, firstEmergencyAscentPres] = ...
         compute_prv_dates_ir_rudics_111_113_114_115(tabTech, ...
         floatClockDrift, a_refDay, measDates);
            
      if (~isempty(g_decArgo_outputCsvFileId))
         
         % output CSV file
         
         % print decoded data in CSV file
         print_info_in_csv_file_ir_rudics_cts4_111_113_114_115( ...
            a_decoderId, ...
            cyProfPhaseList, ...
            dataCTD, dataOXY, dataOCR, ...
            dataECO2, dataECO3, dataFLNTU, ...
            dataCROVER, dataSUNA, dataSEAFET, ...
            sensorTechCTD, sensorTechOPTODE, sensorTechOCR, ...
            sensorTechECO2, sensorTechECO3, ...
            sensorTechFLNTU, sensorTechSEAFET, ...
            sensorTechCROVER, sensorTechSUNA, ...
            tabTech, floatPres, grounding, ...
            floatProgRudics, floatProgTech, floatProgParam, floatProgSensor);
         
         % print dated data in CSV file
         if (~isempty(tabTech))
            print_dates_in_csv_file_ir_rudics_cts4_111_113_114_115( ...
               a_decoderId, ...
               cycleStartDate, buoyancyRedStartDate, ...
               descentToParkStartDate, ...
               firstStabDate, firstStabPres, ...
               descentToParkEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, ...
               transStartDate, ...
               buoyancyInvStartDate, ...
               firstGroundDate, firstGroundPres, ...
               firstHangDate, firstHangPres, ...
               firstEmerAscentDate, firstEmergencyAscentPres, ...
               dataCTD, dataOXY, dataOCR, ...
               dataECO2, dataECO3, dataFLNTU, ...
               dataCROVER, dataSUNA, dataSEAFET, ...
               g_decArgo_gpsData);
         end
      else
         
         % output NetCDF files
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % PROF NetCDF file
         
         % process profile data for PROF NetCDF file
         [tabProfiles, tabDrift] = process_profiles_ir_rudics_cts4_111_113_114_115( ...
            a_decoderId, ...
            cyProfPhaseList, ...
            dataCTD, dataOXY, dataOCR, ...
            dataECO2, dataECO3, dataFLNTU, ...
            dataCROVER, dataSUNA, dataSEAFET, ...
            descentToParkStartDate, ascentEndDate, ...
            g_decArgo_gpsData, ...
            sensorTechCTD, sensorTechOPTODE, sensorTechOCR, ...
            sensorTechECO2, sensorTechECO3, ...
            sensorTechFLNTU, sensorTechSEAFET, ...
            sensorTechCROVER, sensorTechSUNA);
         
         % add the vertical sampling scheme from configuration
         % information
         [tabProfiles] = add_vertical_sampling_scheme_ir_rudics(tabProfiles);
         
         % merge profile measurements (raw and averaged measurements of
         % a given profile)
         [tabProfiles] = merge_profile_meas_ir_rudics_sbd2(tabProfiles);
         
         % compute derived parameters of the profiles
         [tabProfiles] = compute_profile_derived_parameters_ir_rudics(tabProfiles, a_decoderId);
         
         print = 0;
         if (print == 1)
            if (~isempty(tabProfiles))
               fprintf('DEC_INFO: Float #%d Cycle #%d: %d profiles for NetCDF file\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, length(tabProfiles));
               for idP = 1:length(tabProfiles)
                  prof = tabProfiles(idP);
                  paramList = prof.paramList;
                  paramList = sprintf('%s ', paramList.name);
                  profLength = size(prof.data, 1);
                  fprintf('   ->%2d: Profile #%d dir=%c length=%d param=(%s)\n', ...
                     idP, prof.profileNumber, prof.direction, ...
                     profLength, paramList(1:end-1));
               end
            else
               fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum);
            end
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TRAJ NetCDF file
         
         % merge drift measurements (raw and averaged measurements of
         % the park phase)
         [tabDrift] = merge_profile_meas_ir_rudics_sbd2(tabDrift);
         
         % compute derived parameters of the park phase
         [tabDrift] = compute_drift_derived_parameters_ir_rudics(tabDrift, a_decoderId);
         
         % collect trajectory data for TRAJ NetCDF file
         [tabTrajIndex, tabTrajData] = collect_trajectory_data_ir_rudics_111_113_114_115(a_decoderId, ...
            tabProfiles, tabDrift, ...
            floatPres, grounding, tabTech, a_refDay, ...
            cycleStartDate, buoyancyRedStartDate, ...
            descentToParkStartDate, ...
            descentToParkEndDate, ...
            descentToProfStartDate, descentToProfEndDate, ...
            ascentStartDate, ascentEndDate, ...
            transStartDate, ...
            firstEmerAscentDate, ...
            sensorTechCTD, deepCycleFlag);

         % process trajectory data for TRAJ NetCDF file
         [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_ir_rudics_sbd2( ...
            cyProfPhaseList, tabTrajIndex, tabTrajData, a_decoderId);
         
         % sort trajectory data structures according to the predefined
         % measurement code order
         [tabTrajNMeas] = sort_trajectory_data_cyprofnum(tabTrajNMeas, a_decoderId);
                  
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TECH NetCDF file
         
         % process technical data for TECH NetCDF file
         process_technical_data_ir_rudics_111_113_114_115( ...
            a_decoderId, cyProfPhaseList, ...
            sensorTechCTD, sensorTechOPTODE, sensorTechOCR, ...
            sensorTechECO2, sensorTechECO3, ...
            sensorTechFLNTU, sensorTechSEAFET, ...
            sensorTechCROVER, sensorTechSUNA, deepCycleFlag, ...
            tabTech, a_refDay, ...
            floatProgParam);
         
         % filter useless technical data
         filter_technical_data_ir_rudics_sbd2;
         
         if (~isempty(g_decArgo_outputNcParamIndex))
            tabNcTechIndex = g_decArgo_outputNcParamIndex;
            tabNcTechVal = g_decArgo_outputNcParamValue;
         end
         
         g_decArgo_outputNcParamIndex = [];
         g_decArgo_outputNcParamValue = [];
         
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in process_decoded_data_cts4 for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% output parameters
if (isempty(g_decArgo_outputCsvFileId))
   if (~isempty(tabProfiles))
      
      % remove PPOX_DOXY data in DOXY profiles
      for idProf = 1:length(tabProfiles)
         if (tabProfiles(idProf).sensorNumber == 1)
            
            % remove temporary PPOX_DOXY
            idPpoxDoxy = find(strcmp({tabProfiles(idProf).paramList.name}, 'PPOX_DOXY') == 1);
            if (~isempty(idPpoxDoxy))
               tabProfiles(idProf).data(:, idPpoxDoxy) = [];
               if (~isempty(tabProfiles(idProf).dataQc))
                  tabProfiles(idProf).dataQc(:, idPpoxDoxy) = [];
               end
               tabProfiles(idProf).paramList(idPpoxDoxy) = [];
            end
         end
      end
      
      o_tabProfiles = [o_tabProfiles tabProfiles];
   end
   if (~isempty(tabTrajNMeas))
      o_tabTrajNMeas = [o_tabTrajNMeas tabTrajNMeas];
   end
   if (~isempty(tabTrajNCycle))
      o_tabTrajNCycle = [o_tabTrajNCycle tabTrajNCycle];
   end
   if (~isempty(tabNcTechIndex))
      o_tabNcTechIndex = [o_tabNcTechIndex; tabNcTechIndex];
   end
   if (~isempty(tabNcTechVal))
      o_tabNcTechVal = [o_tabNcTechVal; tabNcTechVal'];
   end
   if (~isempty(tabTechNMeas))
      o_tabTechNMeas = [o_tabTechNMeas tabTechNMeas];
   end
end

return
