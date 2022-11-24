% ------------------------------------------------------------------------------
% Decode one set of Iridium SBD files.
%
% SYNTAX :
%  [o_tabProfiles, ...
%    o_tabTrajNMeas, o_tabTrajNCycle, ...
%    o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
%    decode_sbd_files_delayed( ...
%    a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
%    a_decoderId, a_refDay, a_cycleNumberList, a_whyFlag, a_delayedFlag, ...
%    a_tabProfiles, ...
%    a_tabTrajNMeas, a_tabTrajNCycle, ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList : list of SBD file names
%   a_sbdFileDateList : list of SBD file dates
%   a_sbdFileSizeList : list of SBD file sizes
%   a_decoderId       : float decoder Id
%   a_refDay          : reference day
%   a_cycleNumberList : list of cycle to decode
%   a_whyFlag         : print information on incompleted buffers
%   a_delayedFlag     : detected delayed data flag
%   a_tabProfiles     : input decoded profiles
%   a_tabTrajNMeas    : input decoded trajectory N_MEASUREMENT data
%   a_tabTrajNCycle   : input decoded trajectory N_CYCLE data
%   a_tabNcTechIndex  : input decoded technical index information
%   a_tabNcTechVal    : input decoded technical data
%   a_tabTechNMeas    : input decoded technical PARAM data
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
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabProfiles, ...
   o_tabTrajNMeas, o_tabTrajNCycle, ...
   o_tabNcTechIndex, o_tabNcTechVal, o_tabTechNMeas] = ...
   decode_sbd_files_delayed( ...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, ...
   a_decoderId, a_refDay, a_cycleNumberList, a_whyFlag, a_delayedFlag, ...
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

% offset in cycle number (in case of reset of the float)
global g_decArgo_cycleNumOffset;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter index information
global g_decArgo_outputNcParamIndex;

% output NetCDF technical parameter values
global g_decArgo_outputNcParamValue;

% SBD sub-directories
global g_decArgo_bufferDirectory;
global g_decArgo_archiveSbdDirectory;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% generate nc flag
global g_decArgo_generateNcFlag;
g_decArgo_generateNcFlag = 1;

% number of the first deep cycle
global g_decArgo_firstDeepCycleNumber;
g_decArgo_firstDeepCycleNumber = 1;

% offset between float days and julian days
global g_decArgo_julD2FloatDayOffset;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;

% last float reset date
global g_decArgo_floatLastResetDate;

% default values
global g_decArgo_janFirst1950InMatlab;


VERBOSE = 0;

% no data to process
if (isempty(a_sbdFileNameList))
   return;
end

% read the SBD file data
sbdDataDate = [];
sbdDataData = [];
for idFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idFile};
   if (g_decArgo_virtualBuff)
      sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   
   sbdData = [];
   if (a_sbdFileSizeList(idFile) > 0)
      
      if (rem(a_sbdFileSizeList(idFile), 100) == 0)
         fId = fopen(sbdFilePathName, 'r');
         if (fId == -1)
            fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
               g_decArgo_floatNum, ...
               sbdFilePathName);
         end
         
         [sbdData, sbdDataCount] = fread(fId);
         
         fclose(fId);
         
         sbdData = reshape(sbdData, 100, size(sbdData, 1)/100)';
         for idMsg = 1:size(sbdData, 1)
            data = sbdData(idMsg, :);
            if (~isempty(find(data ~= 0, 1)))
               sbdDataData = [sbdDataData; data];
               sbdDataDate = [sbdDataDate; a_sbdFileDateList(idFile)];
            end
         end
      else
         fprintf('DEC_WARNING: Float #%d: SBD file ignored because of unexpected size (%d bytes)  : %s\n', ...
            g_decArgo_floatNum, ...
            a_sbdFileSizeList(idFile), ...
            sbdFilePathName);
      end
      
   end
   
   % output CSV file
   if (~isempty(g_decArgo_outputCsvFileId))
      fprintf(g_decArgo_outputCsvFileId, '%d; -; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: %d', ...
         g_decArgo_floatNum, ...
         idFile, a_sbdFileNameList{idFile}, ...
         a_sbdFileSizeList(idFile), a_sbdFileSizeList(idFile)/100);
      
      sbdInfoStr = get_info_raw_decoding_sbd_file(sbdData, ones(size(sbdData, 1) , 1)*a_sbdFileDateList(idFile), a_decoderId);
      
      fprintf(g_decArgo_outputCsvFileId, '; %s\n', sbdInfoStr);
   end
end

% decode the data

tabBuffProfiles = [];
tabBuffTrajNMeas = [];
tabBuffTrajNCycle = [];
tabBuffNcTechIndex = [];
tabBuffNcTechVal = [];
tabBuffTechNMeas = [];

switch (a_decoderId)
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {212} % Arvor-ARN-Ice Iridium
      
      % decode the collected data
      [allCyTabTech1, allCyTabTech2, allCyDataCTD, allCyEvAct, allCyPumpAct, ...
         allCyFloatParam1, allCyFloatParam2, cycleNumberList] = ...
         decode_prv_data_ir_sbd_212(sbdDataData, sbdDataDate, 1, a_cycleNumberList);
      
      if (a_whyFlag)
         is_buffer_completed_ir_sbd_delayed(a_whyFlag, a_decoderId);
      end
      
      % manage float reset during mission at sea
      resetDetectedFlag = 0;
      for idTech2 = 1:size(allCyTabTech2, 1)
         floatLastResetTime = datenum(sprintf('%02d%02d%02d', allCyTabTech2(idTech2, 48:53)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         if (g_decArgo_floatLastResetDate < 0)
            % initialization
            g_decArgo_floatLastResetDate = floatLastResetTime;
         else
            if (floatLastResetTime ~= g_decArgo_floatLastResetDate)
               if (length(unique(cycleNumberList)) == 1)
                  fprintf('\nINFO: Float #%d: A reset has been performed at sea on %s\n', ...
                     g_decArgo_floatNum, julian_2_gregorian_dec_argo(floatLastResetTime));
                  
                  g_decArgo_floatLastResetDate = floatLastResetTime;
                  g_decArgo_cycleNumOffset = g_decArgo_cycleNum + 1;
                  resetDetectedFlag = 1;
                  
                  % update cycle numbers of decoded data
                  if (~isempty(allCyTabTech1))
                     allCyTabTech1(:, 1) = allCyTabTech1(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyTabTech1(:, 1);
                  end
                  if (~isempty(allCyTabTech2))
                     allCyTabTech2(:, 1) = allCyTabTech2(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyTabTech2(:, 1);
                  end
                  if (~isempty(allCyDataCTD))
                     allCyDataCTD(:, 1) = allCyDataCTD(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyDataCTD(:, 1);
                  end
                  if (~isempty(allCyEvAct))
                     allCyEvAct(:, 1) = allCyEvAct(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyEvAct(:, 1);
                  end
                  if (~isempty(allCyPumpAct))
                     allCyPumpAct(:, 1) = allCyPumpAct(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyPumpAct(:, 1);
                  end
                  if (~isempty(allCyFloatParam1))
                     allCyFloatParam1(:, 1) = allCyFloatParam1(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyFloatParam1(:, 1);
                  end
                  if (~isempty(allCyFloatParam2))
                     allCyFloatParam2(:, 1) = allCyFloatParam2(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyFloatParam2(:, 1);
                  end
                  cycleNumberList = unique(cycleNumberList);
               else
                  fprintf('\nERROR: Float #%d: A reset has been performed at sea on %s the reset occured in a multi-cycle buffer => not managed\n', ...
                     g_decArgo_floatNum, julian_2_gregorian_dec_argo(floatLastResetTime));
               end
            end
         end
      end
      
      % assign max cycle number value to Iridium mails currently processed
      update_mail_data_ir_sbd_delayed(a_sbdFileNameList, a_sbdFileDateList, max(cycleNumberList));
      
      % pocess the decoded cycles
      cycleNumberList = sort(cycleNumberList);
      for idCyNum = 1:length(cycleNumberList)
         
         g_decArgo_cycleNum = cycleNumberList(idCyNum);
         
         % retrieve data of the current cycle
         cyTabTech1 = [];
         cyTabTech1Done = [];
         if (~isempty(allCyTabTech1))
            cyTabTech1 = allCyTabTech1(find(allCyTabTech1(:, 1) == g_decArgo_cycleNum), :);
            cyTabTech1 = cyTabTech1(:, 2:end);
            cyTabTech1Done = zeros(size(cyTabTech1, 1), 1);
         end
         cyTabTech2 = [];
         cyTabTech2Done = [];
         if (~isempty(allCyTabTech2))
            cyTabTech2 = allCyTabTech2(find(allCyTabTech2(:, 1) == g_decArgo_cycleNum), :);
            cyTabTech2 = cyTabTech2(:, 2:end);
            cyTabTech2Done = zeros(size(cyTabTech2, 1), 1);
         end
         cyDataCTD = [];
         cyDataCTDDone = [];
         if (~isempty(allCyDataCTD))
            cyDataCTD = allCyDataCTD(find(allCyDataCTD(:, 1) == g_decArgo_cycleNum), :);
            cyDataCTD = cyDataCTD(:, 2:end);
            cyDataCTDDone = zeros(size(cyDataCTD, 1), 1);
         end
         cyEvAct = [];
         cyEvActDone = [];
         if (~isempty(allCyEvAct))
            cyEvAct = allCyEvAct(find(allCyEvAct(:, 1) == g_decArgo_cycleNum), :);
            cyEvAct = cyEvAct(:, 2:end);
            cyEvActDone = zeros(size(cyEvAct, 1), 1);
         end
         cyPumpAct = [];
         cyPumpActDone = [];
         if (~isempty(allCyPumpAct))
            cyPumpAct = allCyPumpAct(find(allCyPumpAct(:, 1) == g_decArgo_cycleNum), :);
            cyPumpAct = cyPumpAct(:, 2:end);
            cyPumpActDone = zeros(size(cyPumpAct, 1), 1);
         end
         cyFloatParam1 = [];
         cyFloatParam1Done = [];
         if (~isempty(allCyFloatParam1))
            cyFloatParam1 = allCyFloatParam1(find(allCyFloatParam1(:, 1) == g_decArgo_cycleNum), :);
            cyFloatParam1 = cyFloatParam1(:, 2:end);
         end
         cyFloatParam2 = [];
         cyFloatParam2Done = [];
         if (~isempty(allCyFloatParam2))
            cyFloatParam2 = allCyFloatParam2(find(allCyFloatParam2(:, 1) == g_decArgo_cycleNum), :);
            cyFloatParam2 = cyFloatParam2(:, 2:end);
            cyFloatParam2Done = zeros(size(cyFloatParam2, 1), 1);
         end
         
         if ((size(cyTabTech1, 1) > 1) || (size(cyTabTech2, 1) > 1) || ...
               (size(cyFloatParam1, 1) > 1) || (size(cyFloatParam2, 1) > 1))
            
            fprintf('ERROR: Float #%d: Case not checked yet (code need to be updated first)\n', ...
               g_decArgo_floatNum);
            
            % identify data packets:
            % 1 - deep cycle
            % 2 - second Iridium session
            % 3 - EOL transmission
            tech1TransType = zeros(size(cyTabTech1, 1), 1);
            for idTech1 = 1:size(cyTabTech1, 1)
               if (cyTabTech1(idTech1, 3) == 0)
                  tech1TransType(idTech1) = 1;
               else
                  tech1TransType(idTech1) = 2;
               end
            end
            tech2TransType = zeros(size(cyTabTech2, 1), 1);
            for idTech2 = 1:size(cyTabTech2, 1)
               if (cyTabTech2(idTech2, 3) == 0)
                  if (any(cyTabTech2(idTech2, 4:7) ~= 0))
                     tech2TransType(idTech2) = 1;
                  else
                     tech2TransType(idTech2) = 3;
                  end
               else
                  tech2TransType(idTech2) = 2;
               end
            end
            param1TransType = zeros(size(cyFloatParam1, 1), 1);
            for idParam1 = 1:size(cyFloatParam1, 1)
               if (cyFloatParam1(idParam1, 3) == 0)
                  param1TransType(idParam1) = 1;
               else
                  param1TransType(idParam1) = 2;
               end
            end
            param2TransType = zeros(size(cyFloatParam2, 1), 1);
            for idParam2 = 1:size(cyFloatParam2, 1)
               if (cyFloatParam2(idParam2, 3) == 0)
                  param2TransType(idParam2) = 1;
               else
                  param2TransType(idParam2) = 2;
               end
            end
         else
            tabTech1 = cyTabTech1;
            cyTabTech1Done = 1;
            tabTech2 = cyTabTech2;
            cyTabTech2Done = 1;
            dataCTD = cyDataCTD;
            cyDataCTDDone = ones(size(cyDataCTDDone));
            evAct = cyEvAct;
            cyEvActDone = ones(size(cyEvActDone));
            pumpAct = cyPumpAct;
            cyPumpActDone = ones(size(cyPumpActDone));
            floatParam1 = cyFloatParam1;
            cyFloatParam1Done = ones(size(cyFloatParam1Done));
            floatParam2 = cyFloatParam2;
            cyFloatParam2Done = ones(size(cyFloatParam2Done));
         end

         if (a_delayedFlag)
            fprintf('DEC_INFO: Float #%d Cycle #%d - DELAYED\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            fprintf('DEC_INFO: Float #%d Cycle #%d\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
         
         if (VERBOSE)
            if (~isempty(tabTech1))
               fprintf('   -> TECH1   (%d)\n', size(tabTech1, 1));
            end
            if (~isempty(tabTech2))
               fprintf('   -> TECH2   (%d)\n', size(tabTech2, 1));
            end
            if (~isempty(dataCTD))
               typeList = unique(dataCTD(:, 1));
               for idType = 1:length(typeList)
                  fprintf('   -> CTD #%02d (%d)\n', typeList(idType), size(dataCTD(find(dataCTD(:, 1) == typeList(idType)), :), 1));
               end
            end
            if (~isempty(evAct))
               fprintf('   -> EV      (%d)\n', size(evAct, 1));
            end
            if (~isempty(pumpAct))
               fprintf('   -> PUMP    (%d)\n', size(pumpAct, 1));
            end
            if (~isempty(floatParam1))
               fprintf('   -> PARAM1  (%d)\n', size(floatParam1, 1));
            end
            if (~isempty(floatParam2))
               fprintf('   -> PARAM2  (%d)\n', size(floatParam2, 1));
            end
         end
         
         % check if the data come from a deep cycle
         deepCycleFlag = 0;
         if (~isempty(tabTech2))
            % message and measurement counts are set to 0 for a surface cycle
            if (any(tabTech2(4:7) ~= 0))
               deepCycleFlag = 1;
            end
         end
         if (~isempty(dataCTD))
            % no deep measurements are transmitted for a surface cycle
            if (any(ismember(dataCTD(:, 1), [1 2 3 13])))
               deepCycleFlag = 1;
            end
         end
         
         % assign the current configuration to the decoded cycle
         if (((g_decArgo_cycleNum > 0) && (deepCycleFlag == 1)) || (resetDetectedFlag == 1))
            set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
         end
         
         % update float configuration for the next cycles
         if ~(isempty(floatParam1) && isempty(floatParam2))
            update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
         end
         
         % assign the configuration received during the prelude to this cycle
         if (g_decArgo_cycleNum == 0)
            set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
         end
         
         % store GPS data and compute JAMSTEC QC for the GPS locations of the
         % current cycle
         store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);
         
         % convert counts to physical values
         if (~isempty(dataCTD))
            [dataCTD(:, 33:47)] = sensor_2_value_for_pressure_202_210_to_214(dataCTD(:, 33:47));
            [dataCTD(:, 48:62)] = sensor_2_value_for_temperature_204_to_214(dataCTD(:, 48:62));
            [dataCTD(:, 63:77)] = sensor_2_value_for_salinity_210_to_214(dataCTD(:, 63:77));
         end
         
         % create drift data set
         [parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal] = ...
            create_prv_drift_212(dataCTD, g_decArgo_julD2FloatDayOffset);
         
         % create descending and ascending profiles
         [descProfDate, descProfPres, descProfTemp, descProfSal, ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal] = ...
            create_prv_profile_212(dataCTD, g_decArgo_julD2FloatDayOffset);
         
         % compute the main dates of the cycle
         [cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            lastResetDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            eolStartDate, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            iceDetected] = ...
            compute_prv_dates_212_214(tabTech1, tabTech2, deepCycleFlag, a_refDay);
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            % print float technical messages in CSV file
            print_tech_data_in_csv_file_212(tabTech1, tabTech2, deepCycleFlag);
            
            % print dated data in CSV file
            print_dates_in_csv_file_212_214( ...
               cycleStartDate, ...
               descentToParkStartDate, ...
               firstStabDate, firstStabPres, ...
               descentToParkEndDate, ...
               descentToProfStartDate, ...
               descentToProfEndDate, ...
               ascentStartDate, ...
               ascentEndDate, ...
               transStartDate, ...
               gpsDate, ...
               firstGroundingDate, firstGroundingPres, ...
               secondGroundingDate, secondGroundingPres, ...
               eolStartDate, ...
               firstEmergencyAscentDate, firstEmergencyAscentPres, ...
               descProfDate, descProfPres, ...
               parkDate, parkPres, ...
               ascProfDate, ascProfPres, ...
               nearSurfDate, nearSurfPres, ...
               inAirDate, inAirPres, ...
               evAct, pumpAct);
            
            % print descending profile in CSV file
            print_descending_profile_in_csv_file_204_205_210_to_212( ...
               descProfDate, descProfPres, descProfTemp, descProfSal);
            
            % print drift measurements in CSV file
            print_drift_measurements_in_csv_file_204_205_210_to_212( ...
               parkDate, parkTransDate, ...
               parkPres, parkTemp, parkSal);
            
            % print ascending profile in CSV file
            print_ascending_profile_in_csv_file_204_205_210_to_212( ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal);
            
            % print "near surface" and "in air" measurements in CSV file
            print_in_air_meas_in_csv_file_210_to_212( ...
               nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
               inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal);
            
            % print EV and pump data in CSV file
            print_hydraulic_data_in_csv_file_212_214(evAct, pumpAct);
            
            % print float parameters in CSV file
            print_float_prog_param_in_csv_file_212_214(floatParam1, floatParam2);
            
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            % process profile data for PROF NetCDF file
            tabProfiles = [];
            if (~isempty(dataCTD))
               
               [tabProfiles] = process_profiles_212( ...
                  descProfDate, descProfPres, descProfTemp, descProfSal, ...
                  ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
                  g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
                  descentToParkStartDate, ascentEndDate, transStartDate, ...
                  tabTech2, iceDetected, a_decoderId);
               
               % add the vertical sampling scheme from configuration
               % information
               [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
               
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
                        fprintf('   ->%2d: dir=%c length=%d param=(%s)\n', ...
                           idP, prof.direction, ...
                           profLength, paramList(1:end-1));
                     end
                  else
                     fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                  end
               end
               
               tabBuffProfiles = [tabBuffProfiles tabProfiles];
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
            
            % process trajectory data for TRAJ NetCDF file
            [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_212( ...
               g_decArgo_cycleNum, deepCycleFlag, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleStartDate, ...
               descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, ...
               transStartDate, ...
               firstGroundingDate, firstGroundingPres, ...
               secondGroundingDate, secondGroundingPres, ...
               tabTech1, tabTech2, ...
               tabProfiles, ...
               parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
               nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
               inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
               evAct, pumpAct, iceDetected, a_decoderId);
            
            % sort trajectory data structures according to the predefined
            % measurement code order
            [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
            
            tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
            tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % store information on received Iridium packet types
            if (deepCycleFlag == 1)
               store_received_packet_type_info_for_nc(a_decoderId);
            end
            
            % store NetCDF technical data
            store_tech1_data_for_nc_210_to_214(tabTech1, deepCycleFlag);
            store_tech2_data_for_nc_212_214(tabTech2, deepCycleFlag, iceDetected);
                                    
            tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
            tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
            tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
      end
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   case {214} % Provor-ARN-DO-Ice Iridium 5.75
      
      % decode the collected data
      [allCyTabTech1, allCyTabTech2, allCyDataCTDO, allCyEvAct, allCyPumpAct, ...
         allCyFloatParam1, allCyFloatParam2, cycleNumberList] = ...
         decode_prv_data_ir_sbd_214(sbdDataData, sbdDataDate, 1, a_cycleNumberList);
      
      if (a_whyFlag)
         is_buffer_completed_ir_sbd_delayed(a_whyFlag, a_decoderId);
      end
      
      % manage float reset during mission at sea
      resetDetectedFlag = 0;
      for idTech2 = 1:size(allCyTabTech2, 1)
         floatLastResetTime = datenum(sprintf('%02d%02d%02d', allCyTabTech2(idTech2, 48:53)), 'HHMMSSddmmyy') - g_decArgo_janFirst1950InMatlab;
         if (g_decArgo_floatLastResetDate < 0)
            % initialization
            g_decArgo_floatLastResetDate = floatLastResetTime;
         else
            if (floatLastResetTime ~= g_decArgo_floatLastResetDate)
               if (length(unique(cycleNumberList)) == 1)
                  fprintf('\nINFO: Float #%d: A reset has been performed at sea on %s\n', ...
                     g_decArgo_floatNum, julian_2_gregorian_dec_argo(floatLastResetTime));
                  
                  g_decArgo_floatLastResetDate = floatLastResetTime;
                  g_decArgo_cycleNumOffset = g_decArgo_cycleNum + 1;
                  resetDetectedFlag = 1;
                  
                  % update cycle numbers of decoded data
                  if (~isempty(allCyTabTech1))
                     allCyTabTech1(:, 1) = allCyTabTech1(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyTabTech1(:, 1);
                  end
                  if (~isempty(allCyTabTech2))
                     allCyTabTech2(:, 1) = allCyTabTech2(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyTabTech2(:, 1);
                  end
                  if (~isempty(allCyDataCTDO))
                     allCyDataCTDO(:, 1) = allCyDataCTDO(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyDataCTDO(:, 1);
                  end
                  if (~isempty(allCyEvAct))
                     allCyEvAct(:, 1) = allCyEvAct(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyEvAct(:, 1);
                  end
                  if (~isempty(allCyPumpAct))
                     allCyPumpAct(:, 1) = allCyPumpAct(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyPumpAct(:, 1);
                  end
                  if (~isempty(allCyFloatParam1))
                     allCyFloatParam1(:, 1) = allCyFloatParam1(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyFloatParam1(:, 1);
                  end
                  if (~isempty(allCyFloatParam2))
                     allCyFloatParam2(:, 1) = allCyFloatParam2(:, 3) + g_decArgo_cycleNumOffset;
                     cycleNumberList = allCyFloatParam2(:, 1);
                  end
                  cycleNumberList = unique(cycleNumberList);
               else
                  fprintf('\nERROR: Float #%d: A reset has been performed at sea on %s the reset occured in a multi-cycle buffer => not managed\n', ...
                     g_decArgo_floatNum, julian_2_gregorian_dec_argo(floatLastResetTime));
               end
            end
         end
      end
      
      % assign max cycle number value to Iridium mails currently processed
      update_mail_data_ir_sbd_delayed(a_sbdFileNameList, a_sbdFileDateList, max(cycleNumberList));
      
      % pocess the decoded cycles
      cycleNumberList = sort(cycleNumberList);
      for idCyNum = 1:length(cycleNumberList)
         
         g_decArgo_cycleNum = cycleNumberList(idCyNum);
         
         % retrieve data of the current cycle
         cyTabTech1 = [];
         cyTabTech1Done = [];
         if (~isempty(allCyTabTech1))
            cyTabTech1 = allCyTabTech1(find(allCyTabTech1(:, 1) == g_decArgo_cycleNum), :);
            cyTabTech1 = cyTabTech1(:, 2:end);
            cyTabTech1Done = zeros(size(cyTabTech1, 1), 1);
         end
         cyTabTech2 = [];
         cyTabTech2Done = [];
         if (~isempty(allCyTabTech2))
            cyTabTech2 = allCyTabTech2(find(allCyTabTech2(:, 1) == g_decArgo_cycleNum), :);
            cyTabTech2 = cyTabTech2(:, 2:end);
            cyTabTech2Done = zeros(size(cyTabTech2, 1), 1);
         end
         cyDataCTDO = [];
         cyDataCTDODone = [];
         if (~isempty(allCyDataCTDO))
            cyDataCTDO = allCyDataCTDO(find(allCyDataCTDO(:, 1) == g_decArgo_cycleNum), :);
            cyDataCTDO = cyDataCTDO(:, 2:end);
            cyDataCTDODone = zeros(size(cyDataCTDO, 1), 1);
         end
         cyEvAct = [];
         cyEvActDone = [];
         if (~isempty(allCyEvAct))
            cyEvAct = allCyEvAct(find(allCyEvAct(:, 1) == g_decArgo_cycleNum), :);
            cyEvAct = cyEvAct(:, 2:end);
            cyEvActDone = zeros(size(cyEvAct, 1), 1);
         end
         cyPumpAct = [];
         cyPumpActDone = [];
         if (~isempty(allCyPumpAct))
            cyPumpAct = allCyPumpAct(find(allCyPumpAct(:, 1) == g_decArgo_cycleNum), :);
            cyPumpAct = cyPumpAct(:, 2:end);
            cyPumpActDone = zeros(size(cyPumpAct, 1), 1);
         end
         cyFloatParam1 = [];
         cyFloatParam1Done = [];
         if (~isempty(allCyFloatParam1))
            cyFloatParam1 = allCyFloatParam1(find(allCyFloatParam1(:, 1) == g_decArgo_cycleNum), :);
            cyFloatParam1 = cyFloatParam1(:, 2:end);
         end
         cyFloatParam2 = [];
         cyFloatParam2Done = [];
         if (~isempty(allCyFloatParam2))
            cyFloatParam2 = allCyFloatParam2(find(allCyFloatParam2(:, 1) == g_decArgo_cycleNum), :);
            cyFloatParam2 = cyFloatParam2(:, 2:end);
            cyFloatParam2Done = zeros(size(cyFloatParam2, 1), 1);
         end
         
         if ((size(cyTabTech1, 1) > 1) || (size(cyTabTech2, 1) > 1) || ...
               (size(cyFloatParam1, 1) > 1) || (size(cyFloatParam2, 1) > 1))
            
            fprintf('ERROR: Float #%d: Case not checked yet (code need to be updated first)\n', ...
               g_decArgo_floatNum);
            
            % identify data packets:
            % 1 - deep cycle
            % 2 - second Iridium session
            % 3 - EOL transmission
            tech1TransType = zeros(size(cyTabTech1, 1), 1);
            for idTech1 = 1:size(cyTabTech1, 1)
               if (cyTabTech1(idTech1, 3) == 0)
                  tech1TransType(idTech1) = 1;
               else
                  tech1TransType(idTech1) = 2;
               end
            end
            tech2TransType = zeros(size(cyTabTech2, 1), 1);
            for idTech2 = 1:size(cyTabTech2, 1)
               if (cyTabTech2(idTech2, 3) == 0)
                  if (any(cyTabTech2(idTech2, 4:7) ~= 0))
                     tech2TransType(idTech2) = 1;
                  else
                     tech2TransType(idTech2) = 3;
                  end
               else
                  tech2TransType(idTech2) = 2;
               end
            end
            param1TransType = zeros(size(cyFloatParam1, 1), 1);
            for idParam1 = 1:size(cyFloatParam1, 1)
               if (cyFloatParam1(idParam1, 3) == 0)
                  param1TransType(idParam1) = 1;
               else
                  param1TransType(idParam1) = 2;
               end
            end
            param2TransType = zeros(size(cyFloatParam2, 1), 1);
            for idParam2 = 1:size(cyFloatParam2, 1)
               if (cyFloatParam2(idParam2, 3) == 0)
                  param2TransType(idParam2) = 1;
               else
                  param2TransType(idParam2) = 2;
               end
            end
         else
            tabTech1 = cyTabTech1;
            cyTabTech1Done = 1;
            tabTech2 = cyTabTech2;
            cyTabTech2Done = 1;
            dataCTDO = cyDataCTDO;
            cyDataCTDODone = ones(size(cyDataCTDODone));
            evAct = cyEvAct;
            cyEvActDone = ones(size(cyEvActDone));
            pumpAct = cyPumpAct;
            cyPumpActDone = ones(size(cyPumpActDone));
            floatParam1 = cyFloatParam1;
            cyFloatParam1Done = ones(size(cyFloatParam1Done));
            floatParam2 = cyFloatParam2;
            cyFloatParam2Done = ones(size(cyFloatParam2Done));
         end

         if (a_delayedFlag)
            fprintf('DEC_INFO: Float #%d Cycle #%d - DELAYED\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         else
            fprintf('DEC_INFO: Float #%d Cycle #%d\n', ...
               g_decArgo_floatNum, g_decArgo_cycleNum);
         end
         
         if (VERBOSE)
            if (~isempty(tabTech1))
               fprintf('   -> TECH1    (%d)\n', size(tabTech1, 1));
            end
            if (~isempty(tabTech2))
               fprintf('   -> TECH2    (%d)\n', size(tabTech2, 1));
            end
            if (~isempty(dataCTDO))
               typeList = unique(dataCTDO(:, 1));
               for idType = 1:length(typeList)
                  fprintf('   -> CTDO #%02d (%d)\n', typeList(idType), size(dataCTDO(find(dataCTDO(:, 1) == typeList(idType)), :), 1));
               end
            end
            if (~isempty(evAct))
               fprintf('   -> EV       (%d)\n', size(evAct, 1));
            end
            if (~isempty(pumpAct))
               fprintf('   -> PUMP     (%d)\n', size(pumpAct, 1));
            end
            if (~isempty(floatParam1))
               fprintf('   -> PARAM1   (%d)\n', size(floatParam1, 1));
            end
            if (~isempty(floatParam2))
               fprintf('   -> PARAM2   (%d)\n', size(floatParam2, 1));
            end
         end
         
         % check if the data come from a deep cycle
         deepCycleFlag = 0;
         if (~isempty(tabTech2))
            % message and measurement counts are set to 0 for a surface cycle
            if (any(tabTech2(4:7) ~= 0))
               deepCycleFlag = 1;
            end
         end
         if (~isempty(dataCTDO))
            % no deep measurements are transmitted for a surface cycle
            if (any(ismember(dataCTDO(:, 1), [8 9 10 11])))
               deepCycleFlag = 1;
            end
         end
         
         % assign the current configuration to the decoded cycle
         if (((g_decArgo_cycleNum > 0) && (deepCycleFlag == 1)) || (resetDetectedFlag == 1))
            set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
         end
         
         % update float configuration for the next cycles
         if ~(isempty(floatParam1) && isempty(floatParam2))
            update_float_config_ir_sbd_delayed([{floatParam1} {floatParam2}], g_decArgo_cycleNum, a_decoderId);
         end
         
         % assign the configuration received during the prelude to this cycle
         if (g_decArgo_cycleNum == 0)
            set_float_config_ir_sbd_delayed(g_decArgo_cycleNum);
         end
         
         % store GPS data and compute JAMSTEC QC for the GPS locations of the
         % current cycle
         store_gps_data_ir_sbd(tabTech1, g_decArgo_cycleNum, a_decoderId);
         
         % convert counts to physical values
         if (~isempty(dataCTDO))
            [dataCTDO(:, 17:23)] = sensor_2_value_for_pressure_202_210_to_214(dataCTDO(:, 17:23));
            [dataCTDO(:, 24:30)] = sensor_2_value_for_temperature_204_to_214(dataCTDO(:, 24:30));
            [dataCTDO(:, 31:37)] = sensor_2_value_for_salinity_210_to_214(dataCTDO(:, 31:37));
            [dataCTDO(:, 38:51)] = sensor_2_value_C1C2Phase_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 38:51));
            [dataCTDO(:, 52:58)] = sensor_2_value_for_temp_doxy_201_to_203_206_to_209_213_to_215(dataCTDO(:, 52:58));
         end

         % create drift data set
         [parkDate, parkTransDate, ...
            parkPres, parkTemp, parkSal, ...
            parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy] = ...
            create_prv_drift_214(dataCTDO, g_decArgo_julD2FloatDayOffset);
         
         % create descending and ascending profiles
         [descProfDate, descProfPres, descProfTemp, descProfSal, ...
            descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
            ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
            ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
            nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
            nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
            inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
            inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy] = ...
            create_prv_profile_214(dataCTDO, g_decArgo_julD2FloatDayOffset);
         
         % compute DOXY
         descProfDoxy = [];
         parkDoxy = [];
         ascProfDoxy = [];
         nearSurfDoxy = [];
         inAirDoxy = [];
         if (~isempty(dataCTDO))
            
            % C1/2PHASE_DOXY -> DOXY using third method: "Stern-Volmer equation"
            [descProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, ...
               descProfPres, descProfTemp, descProfSal);
            [parkDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
               parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, ...
               parkPres, parkTemp, parkSal);
            [ascProfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ...
               ascProfPres, ascProfTemp, ascProfSal);
            [nearSurfDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
               nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, ...
               nearSurfPres, nearSurfTemp, nearSurfSal);
            
            % if the optode is not mounted on an additional stick, we compute DOXY
            % for IN AIR mesurements
            [configNames, configValues] = get_float_config_ir_sbd(g_decArgo_cycleNum);
            optodeInAirMeasFlag = get_config_value('CONFIG_PX04_', configNames, configValues);
            if (isempty(optodeInAirMeasFlag) || (optodeInAirMeasFlag == 0))
               [inAirDoxy] = compute_DOXY_201_203_206_209_213_214_215( ...
                  inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, ...
                  inAirPres, inAirTemp, inAirSal);
            end
         end
         
         % compute the main dates of the cycle
         [cycleStartDate, ...
            descentToParkStartDate, ...
            firstStabDate, firstStabPres, ...
            descentToParkEndDate, ...
            descentToProfStartDate, ...
            descentToProfEndDate, ...
            ascentStartDate, ...
            ascentEndDate, ...
            transStartDate, ...
            gpsDate, ...
            lastResetDate, ...
            firstGroundingDate, firstGroundingPres, ...
            secondGroundingDate, secondGroundingPres, ...
            eolStartDate, ...
            firstEmergencyAscentDate, firstEmergencyAscentPres, ...
            iceDetected] = ...
            compute_prv_dates_212_214(tabTech1, tabTech2, deepCycleFlag, a_refDay);
         
         if (~isempty(g_decArgo_outputCsvFileId))
            
            % output CSV file
            
            % print float technical messages in CSV file
            print_tech_data_in_csv_file_214(tabTech1, tabTech2, deepCycleFlag);
            
            % print dated data in CSV file
            print_dates_in_csv_file_212_214( ...
               cycleStartDate, ...
               descentToParkStartDate, ...
               firstStabDate, firstStabPres, ...
               descentToParkEndDate, ...
               descentToProfStartDate, ...
               descentToProfEndDate, ...
               ascentStartDate, ...
               ascentEndDate, ...
               transStartDate, ...
               gpsDate, ...
               firstGroundingDate, firstGroundingPres, ...
               secondGroundingDate, secondGroundingPres, ...
               eolStartDate, ...
               firstEmergencyAscentDate, firstEmergencyAscentPres, ...
               descProfDate, descProfPres, ...
               parkDate, parkPres, ...
               ascProfDate, ascProfPres, ...
               nearSurfDate, nearSurfPres, ...
               inAirDate, inAirPres, ...
               evAct, pumpAct);
            
            % print descending profile in CSV file
            print_desc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
               descProfDate, descProfPres, descProfTemp, descProfSal, ...
               descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy);
            
            % print drift measurements in CSV file
            print_drift_meas_in_csv_file_201_to_203_206_to_208_213_to_215( ...
               parkDate, parkTransDate, ...
               parkPres, parkTemp, parkSal, ...
               parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy);
            
            % print ascending profile in CSV file
            print_asc_profile_in_csv_file_201_to_203_206_to_208_213_to_215( ...
               ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
               ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy);
            
            % print "near surface" and "in air" measurements in CSV file
            print_in_air_meas_in_csv_file_213_to_215( ...
               nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
               nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
               inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
               inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy);
            
            % print EV and pump data in CSV file
            print_hydraulic_data_in_csv_file_212_214(evAct, pumpAct);
            
            % print float parameters in CSV file
            print_float_prog_param_in_csv_file_212_214(floatParam1, floatParam2);
            
         else
            
            % output NetCDF files
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % PROF NetCDF file
            
            % process profile data for PROF NetCDF file
            tabProfiles = [];
            if (~isempty(dataCTDO))
               
               [tabProfiles] = process_profiles_214( ...
                  descProfDate, descProfPres, descProfTemp, descProfSal, ...
                  descProfC1PhaseDoxy, descProfC2PhaseDoxy, descProfTempDoxy, descProfDoxy, ...
                  ascProfDate, ascProfPres, ascProfTemp, ascProfSal, ...
                  ascProfC1PhaseDoxy, ascProfC2PhaseDoxy, ascProfTempDoxy, ascProfDoxy, ...
                  g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
                  descentToParkStartDate, ascentEndDate, transStartDate, ...
                  tabTech2, iceDetected, a_decoderId);
               
               % add the vertical sampling scheme from configuration
               % information
               [tabProfiles] = add_vertical_sampling_scheme_ir_sbd(tabProfiles, a_decoderId);
               
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
                        fprintf('   ->%2d: dir=%c length=%d param=(%s)\n', ...
                           idP, prof.direction, ...
                           profLength, paramList(1:end-1));
                     end
                  else
                     fprintf('DEC_INFO: Float #%d Cycle #%d: No profiles for NetCDF file\n', ...
                        g_decArgo_floatNum, g_decArgo_cycleNum);
                  end
               end
               
               tabBuffProfiles = [tabBuffProfiles tabProfiles];
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TRAJ NetCDF file
            
            % process trajectory data for TRAJ NetCDF file
            [tabTrajNMeas, tabTrajNCycle, tabTechNMeas] = process_trajectory_data_214( ...
               g_decArgo_cycleNum, deepCycleFlag, ...
               g_decArgo_gpsData, g_decArgo_iridiumMailData, ...
               cycleStartDate, ...
               descentToParkStartDate, firstStabDate, firstStabPres, descentToParkEndDate, ...
               descentToProfStartDate, descentToProfEndDate, ...
               ascentStartDate, ascentEndDate, ...
               transStartDate, ...
               firstGroundingDate, firstGroundingPres, ...
               secondGroundingDate, secondGroundingPres, ...
               tabTech1, tabTech2, ...
               tabProfiles, ...
               parkDate, parkTransDate, parkPres, parkTemp, parkSal, ...
               parkC1PhaseDoxy, parkC2PhaseDoxy, parkTempDoxy, parkDoxy, ...
               nearSurfDate, nearSurfTransDate, nearSurfPres, nearSurfTemp, nearSurfSal, ...
               nearSurfC1PhaseDoxy, nearSurfC2PhaseDoxy, nearSurfTempDoxy, nearSurfDoxy, ...
               inAirDate, inAirTransDate, inAirPres, inAirTemp, inAirSal, ...
               inAirC1PhaseDoxy, inAirC2PhaseDoxy, inAirTempDoxy, inAirDoxy, ...
               evAct, pumpAct, iceDetected, a_decoderId);

            % sort trajectory data structures according to the predefined
            % measurement code order
            [tabTrajNMeas] = sort_trajectory_data(tabTrajNMeas, a_decoderId);
            
            tabBuffTrajNMeas = [tabBuffTrajNMeas tabTrajNMeas];
            tabBuffTrajNCycle = [tabBuffTrajNCycle tabTrajNCycle];
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % TECH NetCDF file
            
            % store information on received Iridium packet types
            if (deepCycleFlag == 1)
               store_received_packet_type_info_for_nc(a_decoderId);
            end
            
            % store NetCDF technical data
            store_tech1_data_for_nc_210_to_214(tabTech1, deepCycleFlag);
            store_tech2_data_for_nc_212_214(tabTech2, deepCycleFlag, iceDetected);
                                    
            tabBuffNcTechIndex = [tabBuffNcTechIndex; g_decArgo_outputNcParamIndex];
            tabBuffNcTechVal = [tabBuffNcTechVal g_decArgo_outputNcParamValue];
            tabBuffTechNMeas = [tabBuffTechNMeas tabTechNMeas];
            
            g_decArgo_outputNcParamIndex = [];
            g_decArgo_outputNcParamValue = [];
            
         end
      end
      
   otherwise
      fprintf('WARNING: Float #%d: Nothing implemented yet in decode_sbd_files_delayed for decoderId #%d\n', ...
         g_decArgo_floatNum, ...
         a_decoderId);
end

% output parameters
if (~isempty(tabBuffProfiles))
   o_tabProfiles = [o_tabProfiles tabBuffProfiles];
end
if (~isempty(tabBuffTrajNMeas))
   o_tabTrajNMeas = [o_tabTrajNMeas tabBuffTrajNMeas];
end
if (~isempty(tabBuffTrajNCycle))
   o_tabTrajNCycle = [o_tabTrajNCycle tabBuffTrajNCycle];
end
if (~isempty(tabBuffNcTechIndex))
   o_tabNcTechIndex = [o_tabNcTechIndex; tabBuffNcTechIndex];
end
if (~isempty(tabBuffNcTechVal))
   o_tabNcTechVal = [o_tabNcTechVal; tabBuffNcTechVal'];
end
if (~isempty(tabBuffTechNMeas))
   o_tabTechNMeas = [o_tabTechNMeas tabBuffTechNMeas];
end

return;
