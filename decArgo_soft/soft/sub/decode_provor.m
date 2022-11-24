% ------------------------------------------------------------------------------
% Decode PROVOR data.
%
% SYNTAX :
%  decode_provor(a_floatList)
%
% INPUT PARAMETERS :
%   a_floatList : list of float to decode
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function decode_provor(a_floatList)

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabel;
global g_decArgo_outputNcParamDescription;

% output NetCDF technical parameter names additional information
global g_decArgo_outputNcParamLabelInfo;
global g_decArgo_outputNcParamLabelInfoCounter;

% output NetCDF configuration parameter Ids
global g_decArgo_outputNcConfParamId;

% output NetCDF configuration parameter labels
global g_decArgo_outputNcConfParamLabel;

% output NetCDF configuration parameter descriptions
global g_decArgo_outputNcConfParamDescription;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportData;
global g_decArgo_reportStruct;

% configuration values
global g_decArgo_floatInformationFileName;
global g_decArgo_dirInputJsonTechLabelFile;
global g_decArgo_dirInputJsonConfLabelFile;
global g_decArgo_generateNcTraj;
global g_decArgo_generateNcTraj32;
global g_decArgo_generateNcMultiProf;
global g_decArgo_generateNcMonoProf;
global g_decArgo_generateNcTech;
global g_decArgo_generateNcMeta;
global g_decArgo_applyRtqc;

% Argos (1), Iridium RUDICS (2), Iridium SBD (3) or Iridium SBD2 (4) float
global g_decArgo_floatTransType;

% array to store surface data of Argos floats
global g_decArgo_floatSurfData;

% array to store GPS data
global g_decArgo_gpsData;

% array to store Iridium mail contents
global g_decArgo_iridiumMailData;

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;

% for virtual buffers management
global g_decArgo_spoolFileList;
global g_decArgo_bufFileList;

% float launch information
global g_decArgo_floatLaunchDate;
global g_decArgo_floatLaunchLon;
global g_decArgo_floatLaunchLat;

% decoder Id check flag
global g_decArgo_decIdCheckFlag;

% Provor/Arvor hydraulic type check flag
global g_decArgo_provorArvorHydraulicTypeCheckFlag;

% to store information parameter RT adjustment
global g_decArgo_paramProfAdjInfo;
global g_decArgo_paramProfAdjId;
global g_decArgo_paramTrajAdjInfo;
global g_decArgo_paramTrajAdjId;
global g_decArgo_juldTrajAdjInfo;
global g_decArgo_juldTrajAdjId;

% lists of managed decoders
global g_decArgo_decoderIdListNkeCts4Ice;
global g_decArgo_decoderIdListNkeCts5Osean;
global g_decArgo_decoderIdListNkeCts5;

% parameter added "on the fly" to meta-data file
global g_decArgo_addParamNbSampleCtd;
global g_decArgo_addParamNbSampleSfet;
global g_decArgo_addParamListCtd;
global g_decArgo_addParamListOxygen;
global g_decArgo_addParamListPh;
global g_decArgo_addParamListChla;
global g_decArgo_addParamListBackscattering;
global g_decArgo_addParamListCdom;
global g_decArgo_addParamListRadiometry;
global g_decArgo_addParamListCp;
global g_decArgo_addParamListTurbidity;


% get floats information
if ((g_decArgo_realtimeFlag == 0) && (g_decArgo_delayedModeFlag == 0))
   [listWmoNum, listDecId, listArgosId, listFrameLen, ...
      listCycleTime, listDriftSamplingPeriod, listDelay, ...
      listLaunchDate, listLaunchLon, listLaunchLat, ...
      listRefDay, listEndDate, listDmFlag] = get_floats_info(g_decArgo_floatInformationFileName);
end

% decode the floats of the "a_floatList" list
nbFloats = length(a_floatList);
for idFloat = 1:nbFloats
   
   % these 3 global variables need to be initialized for each float
   % (even if not used, they are checked in 
   g_decArgo_floatSurfData = [];
   g_decArgo_gpsData = [];
   g_decArgo_iridiumMailData = [];
   
   g_decArgo_spoolFileList = [];
   g_decArgo_bufFileList = [];
   g_decArgo_floatLaunchDate = '';
   g_decArgo_floatLaunchLon = '';
   g_decArgo_floatLaunchLat = '';
   
   g_decArgo_decIdCheckFlag = 0;
   g_decArgo_provorArvorHydraulicTypeCheckFlag = 0;
   
   g_decArgo_paramProfAdjInfo = [];
   g_decArgo_paramProfAdjId = 1;
   g_decArgo_paramTrajAdjInfo = [];
   g_decArgo_paramTrajAdjId = 1;
   g_decArgo_juldTrajAdjInfo = [];
   g_decArgo_juldTrajAdjId = 1;
   
   g_decArgo_addParamNbSampleCtd = 0;
   g_decArgo_addParamNbSampleSfet = 0;
   g_decArgo_addParamListCtd = [];
   g_decArgo_addParamListOxygen = [];
   g_decArgo_addParamListPh = [];
   g_decArgo_addParamListChla = [];
   g_decArgo_addParamListBackscattering = [];
   g_decArgo_addParamListCdom = [];
   g_decArgo_addParamListRadiometry = [];
   g_decArgo_addParamListCp = [];
   g_decArgo_addParamListTurbidity = [];

   floatNum = a_floatList(idFloat);
   g_decArgo_floatNum = floatNum;
   
   if (g_decArgo_realtimeFlag == 0)
      fprintf('\n%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   end
   
   % find current float information
   if ((g_decArgo_realtimeFlag == 0) && (g_decArgo_delayedModeFlag == 0))
      idF = find(listWmoNum == floatNum, 1);
      if (isempty(idF))
         fprintf('ERROR: No information on float #%d - nothing done\n', floatNum);
         continue
      end
      
      floatArgosId = char(listArgosId(idF));
      floatDecId = listDecId(idF);
      floatFrameLen = listFrameLen(idF);
      floatCycleTime = double(listCycleTime(idF));
      floatDriftSamplingPeriod = double(listDriftSamplingPeriod(idF));
      floatDelay = double(listDelay(idF));
      floatLaunchDate = listLaunchDate(idF);
      floatLaunchLon = listLaunchLon(idF);
      floatLaunchLat = listLaunchLat(idF);
      floatRefDay = listRefDay(idF);
      floatEndDate = listEndDate(idF);
      floatDmFlag = listDmFlag(idF);
      
      g_decArgo_floatLaunchDate = floatLaunchDate;
      g_decArgo_floatLaunchLon = floatLaunchLon;
      g_decArgo_floatLaunchLat = floatLaunchLat;
      
      %       if (floatEndDate == g_decArgo_dateDef)
      %          if ((g_decArgo_floatTransType == 3) || (g_decArgo_floatTransType == 4))
      %
      %             % Iridium SBD floats
      %             % Iridium SBD ProvBioII floats
      %
      %             % look for floats that used the same IMEI
      %             idF1 = find(strcmp(listArgosId(idF), listArgosId) == 1);
      %             idF2 = find(listLaunchDate(idF1) > floatLaunchDate);
      %             if (~isempty(idF2))
      %                floatEndDate = min(listLaunchDate(idF1(idF2))) - 1/86400;
      %             end
      %          end
      %       end
   else
      
      [floatNum, floatArgosId, ...
         floatDecVersion, floatDecId, ...
         floatFrameLen, ...
         floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
         floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
         floatRefDay, floatEndDate, floatDmFlag] = get_one_float_info(floatNum, []);
      
      if (isempty(floatArgosId))
         fprintf('ERROR: No information on float #%d - nothing done\n', floatNum);
         continue
      end
      
      g_decArgo_floatLaunchDate = floatLaunchDate;
      g_decArgo_floatLaunchLon = floatLaunchLon;
      g_decArgo_floatLaunchLat = floatLaunchLat;
   end
   
   % check that it is a PROVOR float
   if (floatDecId > 1000)
      fprintf('ERROR: Float #%d is not a Provor float - not decoded\n', floatNum);
      continue
   end
   
   % read the NetCDF TECH parameter names
   if (isempty(g_decArgo_outputCsvFileId))
      
      % get NetCDF technical parameter list
      [g_decArgo_outputNcParamId, g_decArgo_outputNcParamLabel, g_decArgo_outputNcParamDescription] = ...
         get_nc_tech_parameters_json(g_decArgo_dirInputJsonTechLabelFile, floatDecId);
      
      g_decArgo_outputNcParamLabelInfo = [];
      g_decArgo_outputNcParamLabelInfoCounter = 2;
      
      % get NetCDF configuration parameter list
      [g_decArgo_outputNcConfParamId, g_decArgo_outputNcConfParamLabel, g_decArgo_outputNcConfParamDescription] = ...
         get_nc_config_parameters_json(g_decArgo_dirInputJsonConfLabelFile, floatDecId);
   end
   
   % create list of cycles to decode
   [floatCycleList, floatExcludedCycleList] = ...
      get_float_cycle_list(floatNum, floatArgosId, floatLaunchDate, floatDecId);
   
   % decode float cycles
   tabTechAuxNMeas = [];
   if (g_decArgo_floatTransType == 1)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Argos floats
      
      if ((g_decArgo_realtimeFlag == 1) || ...
            (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc == 1)))
         % initialize data structure to store report information
         g_decArgo_reportStruct = get_report_init_struct(floatNum, floatCycleList);
      end
      
      % create the float surface data structure used to compute profile
      % time and location
      g_decArgo_floatSurfData = get_float_surf_data_init_struct;
      
      % add launch information to the surface data structure
      g_decArgo_floatSurfData.launchDate = floatLaunchDate;
      g_decArgo_floatSurfData.launchLon = floatLaunchLon;
      g_decArgo_floatSurfData.launchLat = floatLaunchLat;
      
      g_decArgo_floatSurfData.cycleDuration = double(floatCycleTime);
      
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, ...
         structConfig] = decode_provor_argos_data( ...
         floatNum, floatCycleList, floatExcludedCycleList, ...
         floatDecId, str2num(floatArgosId), floatFrameLen, ...
         floatCycleTime, floatDriftSamplingPeriod, ...
         floatDelay, floatRefDay, floatEndDate);
      
   elseif (g_decArgo_floatTransType == 2)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Iridium RUDICS floats
      
      % update GPS data global variable
      if (floatLaunchLon ~= g_decArgo_argosLonDef)
         g_decArgo_gpsData{1} = -1;
         g_decArgo_gpsData{2} = -1;
         g_decArgo_gpsData{3} = -1;
         g_decArgo_gpsData{4} = floatLaunchDate;
         g_decArgo_gpsData{5} = floatLaunchLon;
         g_decArgo_gpsData{6} = floatLaunchLat;
         g_decArgo_gpsData{7} = 0;
         g_decArgo_gpsData{8} = ' ';
         g_decArgo_gpsData{9} = g_decArgo_dateDef;
         g_decArgo_gpsData{13} = 0;
      end
      
      if (~ismember(floatDecId, g_decArgo_decoderIdListNkeCts5))
         % CTS4 Iridium RUDICS floats
         if (ismember(floatDecId, g_decArgo_decoderIdListNkeCts4Ice))
            % ICE floats
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
               structConfig] = decode_provor_iridium_rudics_cts4_delayed( ...
               floatNum, floatCycleList, ...
               floatDecId, floatArgosId, ...
               floatLaunchDate, floatRefDay, floatEndDate);
         else
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
               structConfig] = decode_provor_iridium_rudics_cts4( ...
               floatNum, floatCycleList, ...
               floatDecId, floatArgosId, ...
               floatLaunchDate, floatRefDay, floatDelay, floatDmFlag);
         end
      else
         
         % CTS5 Iridium RUDICS floats
         if (ismember(floatDecId, g_decArgo_decoderIdListNkeCts5Osean))
            % APMT + OSEAN
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
               structConfig] = decode_provor_iridium_rudics_cts5_payload( ...
               floatNum, floatDecId, floatArgosId, ...
               floatLaunchDate);
         else
            % APMT + USEA
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
               structConfig] = decode_provor_iridium_rudics_cts5_usea( ...
               floatNum, floatDecId, floatArgosId, ...
               floatLaunchDate);
         end
      end
      
   elseif (g_decArgo_floatTransType == 3)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Iridium SBD floats
      
      % update GPS data global variable
      if (floatLaunchLon ~= g_decArgo_argosLonDef)
         g_decArgo_gpsData{1} = -1;
         g_decArgo_gpsData{2} = -1;
         g_decArgo_gpsData{3} = -1;
         g_decArgo_gpsData{4} = floatLaunchDate;
         g_decArgo_gpsData{5} = floatLaunchLon;
         g_decArgo_gpsData{6} = floatLaunchLat;
         g_decArgo_gpsData{7} = 0;
         g_decArgo_gpsData{8} = ' ';
         g_decArgo_gpsData{9} = g_decArgo_dateDef;
         g_decArgo_gpsData{13} = 0;
      end
      
      if (ismember(floatDecId, [212, 222, 214, 216, 217, 218, 221, 223, 224, 225]))
         % ICE floats
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
            structConfig] = decode_provor_iridium_sbd_delayed( ...
            floatNum, floatCycleList, ...
            floatDecId, str2num(floatArgosId), ...
            floatLaunchDate, floatRefDay, floatEndDate);
      elseif (ismember(floatDecId, [219, 220]))
         % Arvor-C floats
         % specific code because, even if they are not ice floats we must
         % decode them in delayed mode to efficiently process EOL data (Ex
         % for 6902717)
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, ...
            structConfig] = decode_arvor_c_iridium_sbd( ...
            floatNum, floatCycleList, ...
            floatDecId, str2num(floatArgosId), ...
            floatLaunchDate, floatEndDate);
      else
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
            structConfig] = decode_provor_iridium_sbd( ...
            floatNum, floatCycleList, ...
            floatDecId, str2num(floatArgosId), ...
            floatLaunchDate, floatRefDay, floatEndDate);
      end

   elseif (g_decArgo_floatTransType == 4)
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % Iridium SBD ProvBioII floats
      
      % update GPS data global variable
      if (floatLaunchLon ~= g_decArgo_argosLonDef)
         g_decArgo_gpsData{1} = -1;
         g_decArgo_gpsData{2} = -1;
         g_decArgo_gpsData{3} = -1;
         g_decArgo_gpsData{4} = floatLaunchDate;
         g_decArgo_gpsData{5} = floatLaunchLon;
         g_decArgo_gpsData{6} = floatLaunchLat;
         g_decArgo_gpsData{7} = 0;
         g_decArgo_gpsData{8} = ' ';
         g_decArgo_gpsData{9} = g_decArgo_dateDef;
         g_decArgo_gpsData{13} = 0;
      end
      
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, tabTechAuxNMeas, ...
         structConfig] = decode_provor_iridium_sbd2( ...
         floatNum, floatCycleList, ...
         floatDecId, str2num(floatArgosId), ...
         floatLaunchDate, floatRefDay, floatDelay, floatEndDate, floatDmFlag);

   end
   
   if (isempty(g_decArgo_outputCsvFileId))
      
      % check consistency of PROF an TRAJ_NMEAS structures
      check_prof_and_traj_struct_consistency(tabProfiles, tabTrajNMeas)
      
      if (g_decArgo_applyRtqc == 0)
         % remove Qc values set by the decoder
         [tabProfiles, tabTrajNMeas] = remove_data_qc(tabProfiles, tabTrajNMeas);
      end
      
      % save decoded data in NetCDF files
      
      % meta-data used in TRAJ, PROF and TECH NetCDF files
      % when creating the META NetcCDF file the JSON meta-data file is opened
      % and all needed information are copied
      wantedMetaNames = [ ...
         {'PROJECT_NAME'} ...
         {'DATA_CENTRE'} ...
         {'PI_NAME'} ...
         {'FLOAT_SERIAL_NO'} ...
         {'FIRMWARE_VERSION'} ...
         ];
      
      % retrieve information from json meta-data file
      [additionalMetaData] = get_meta_data_from_json_file(floatNum, wantedMetaNames);
      
      % NetCDF MONO-PROFILE files
      if ((g_decArgo_generateNcMonoProf ~= 0) && ~isempty(tabProfiles))
         create_nc_mono_prof_files(floatDecId, ...
            tabProfiles, additionalMetaData);
      end
      
      % NetCDF MULTI-PROFILE files
      if ((g_decArgo_generateNcMultiProf ~= 0) && ~isempty(tabProfiles))
         create_nc_multi_prof_file(floatDecId, ...
            tabProfiles, additionalMetaData);
      end
      
      % NetCDF TRAJ file
      if (((g_decArgo_generateNcTraj ~= 0) || (g_decArgo_generateNcTraj32 ~= 0)) && ~isempty(tabTrajNMeas))
         create_nc_traj_file(floatDecId, ...
            tabTrajNMeas, tabTrajNCycle, additionalMetaData);
      end
      
      % NetCDF TECHNICAL file
      if ((g_decArgo_generateNcTech ~= 0) && ...
            ~(isempty(tabNcTechIndex) && isempty(tabTechAuxNMeas)))
         create_nc_tech_file(floatDecId, ...
            tabNcTechIndex, tabNcTechVal, [], tabTechAuxNMeas, ...
            g_decArgo_outputNcParamLabelInfo, additionalMetaData);
      end
      
      % NetCDF META-DATA file
      if (g_decArgo_generateNcMeta ~= 0)
         create_nc_meta_file(floatDecId, structConfig);
      end
      
      if (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc == 1))
         % apply RTQC to NetCDF profile files
         add_rtqc_flags_to_netcdf_profile_and_trajectory_data( ...
            g_decArgo_reportStruct, floatDecId);
      end
   end
   
   % store the information for the XML report
   if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1))
      g_decArgo_reportData = [g_decArgo_reportData g_decArgo_reportStruct];
   end
   
end

return
