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
global g_decArgo_generateNcMultiProf;
global g_decArgo_generateNcMonoProf;
global g_decArgo_generateNcTech;
global g_decArgo_generateNcMeta;
global g_decArgo_applyRtqc;

% Argos (1), Iridium RUDICS (2), Iridium SBD (3) or Iridium SBD2 (4) float
global g_decArgo_floatTransType;

% array to store GPS data
global g_decArgo_gpsData;

% global default values
global g_decArgo_dateDef;
global g_decArgo_argosLonDef;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;
g_decArgo_virtualBuff = 1;
global g_decArgo_spoolFileList;
global g_decArgo_bufFileList;


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
   
   g_decArgo_spoolFileList = [];
   g_decArgo_bufFileList = [];

   floatNum = a_floatList(idFloat);
   
   if (g_decArgo_realtimeFlag == 0)
      fprintf('\n%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   end
   
   % find current float information
   if ((g_decArgo_realtimeFlag == 0) && (g_decArgo_delayedModeFlag == 0))
      idF = find(listWmoNum == floatNum, 1);
      if (isempty(idF))
         fprintf('ERROR: No information on float #%d => nothing done\n', floatNum);
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
         fprintf('ERROR: No information on float #%d => nothing done\n', floatNum);
         continue
      end
   end
   
   % check that it is a PROVOR float
   if (floatDecId > 1000)
      fprintf('ERROR: Float #%d is not a Provor float => not decoded\n', floatNum);
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
   tabTechNMeas = [];
   if (g_decArgo_floatTransType == 1)
      
      % Argos floats
      
      if ((g_decArgo_realtimeFlag == 1) || ...
            (isempty(g_decArgo_outputCsvFileId) && (g_decArgo_applyRtqc == 1)))
         % initialize data structure to store report information
         g_decArgo_reportStruct = get_report_init_struct(floatNum, floatCycleList);
      end
      
      % create the float surface data structure used to compute profile
      % time and location
      floatSurfData = get_float_surf_data_init_struct;
      
      % add launch information to the surface data structure
      floatSurfData.launchDate = floatLaunchDate;
      floatSurfData.launchLon = floatLaunchLon;
      floatSurfData.launchLat = floatLaunchLat;
      
      floatSurfData.cycleDuration = double(floatCycleTime);
      
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, ...
         structConfig] = decode_provor_argos_data( ...
         floatNum, floatCycleList, floatExcludedCycleList, ...
         floatDecId, str2num(floatArgosId), floatFrameLen, ...
         floatCycleTime, floatDriftSamplingPeriod, ...
         floatDelay, floatRefDay, floatSurfData, floatEndDate);
      
   elseif (g_decArgo_floatTransType == 2)
      
      % Iridium RUDICS floats
      
      % update GPS data global variable
      g_decArgo_gpsData = [];
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
      end
      
      if (~ismember(floatDecId, [121, 122, 123, 124, 125]))
         
         % CTS4 Iridium RUDICS floats
         if (ismember(floatDecId, [111, 113]))
            % ICE floats
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechNMeas, ...
               structConfig] = decode_provor_iridium_rudics_cts4_delayed( ...
               floatNum, floatCycleList, ...
               floatDecId, floatArgosId, ...
               floatLaunchDate, floatRefDay);
         else
            [tabProfiles, ...
               tabTrajNMeas, tabTrajNCycle, ...
               tabNcTechIndex, tabNcTechVal, tabTechNMeas, ...
               structConfig] = decode_provor_iridium_rudics_cts4( ...
               floatNum, floatCycleList, ...
               floatDecId, floatArgosId, ...
               floatLaunchDate, floatRefDay, floatDelay, floatDmFlag);
         end
      else
         
         % CTS5 Iridium RUDICS floats
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechNMeas, ...
            structConfig] = decode_provor_iridium_rudics_cts5( ...
            floatNum, floatCycleList, ...
            floatDecId, floatArgosId, ...
            floatLaunchDate, floatRefDay, floatDmFlag);
      end
      
   elseif (g_decArgo_floatTransType == 3)
      
      % Iridium SBD floats
      
      % update GPS data global variable
      g_decArgo_gpsData = [];
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
      end
      
      if (ismember(floatDecId, [212 214 216 217]))
         % ICE floats
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechNMeas, ...
            structConfig] = decode_provor_iridium_sbd_delayed( ...
            floatNum, floatCycleList, ...
            floatDecId, str2num(floatArgosId), ...
            floatLaunchDate, floatRefDay, floatEndDate);
      else
         [tabProfiles, ...
            tabTrajNMeas, tabTrajNCycle, ...
            tabNcTechIndex, tabNcTechVal, tabTechNMeas, ...
            structConfig] = decode_provor_iridium_sbd( ...
            floatNum, floatCycleList, ...
            floatDecId, str2num(floatArgosId), ...
            floatLaunchDate, floatRefDay, floatEndDate);
      end

   elseif (g_decArgo_floatTransType == 4)
      
      % Iridium SBD ProvBioII floats
      
      % update GPS data global variable
      g_decArgo_gpsData = [];
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
      end
      
      [tabProfiles, ...
         tabTrajNMeas, tabTrajNCycle, ...
         tabNcTechIndex, tabNcTechVal, tabTechNMeas, ...
         structConfig] = decode_provor_iridium_sbd2( ...
         floatNum, floatCycleList, ...
         floatDecId, str2num(floatArgosId), ...
         floatLaunchDate, floatRefDay, floatDelay, floatEndDate, floatDmFlag);

   end
   
   if (isempty(g_decArgo_outputCsvFileId))
      % save decoded data in NetCDF files
      
      if ~(isempty(tabProfiles) && ...
            isempty(tabTrajNMeas) && ...
            isempty(tabTrajNCycle) && ...
            isempty(tabNcTechIndex) && ...
            isempty(tabNcTechVal) && ...
            isempty(tabTechNMeas) && ...
            isempty(structConfig) && ...
            isempty(tabProfiles))
         
         % meta-data used in TRAJ, PROF and TECH NetCDF files
         % when creating the META NetcCDF file the JSON meta-data file is opened
         % and all needed information are copied
         wantedMetaNames = [ ...
            {'PROJECT_NAME'} ...
            {'DATA_CENTRE'} ...
            {'PI_NAME'} ...
            {'FLOAT_SERIAL_NO'} ...
            {'FIRMWARE_VERSION'} ...
            {'CALIB_RT_PARAMETER'} ...
            {'CALIB_RT_EQUATION'} ...
            {'CALIB_RT_COEFFICIENT'} ...
            {'CALIB_RT_COMMENT'} ...
            {'CALIB_RT_DATE'} ...
            ];
         
         % retrieve information from json meta-data file
         [additionalMetaData] = get_meta_data_from_json_file(floatNum, wantedMetaNames);
         
         % NetCDF MONO-PROFILE files
         if (g_decArgo_generateNcMonoProf ~= 0)
            create_nc_mono_prof_files(floatDecId, ...
               tabProfiles, additionalMetaData);
         end
         
         % NetCDF MULTI-PROFILE files
         if (g_decArgo_generateNcMultiProf ~= 0)
            create_nc_multi_prof_file(floatDecId, ...
               tabProfiles, additionalMetaData);
         end
         
         % NetCDF TRAJ file
         if (g_decArgo_generateNcTraj ~= 0)
            create_nc_traj_file(floatDecId, ...
               tabTrajNMeas, tabTrajNCycle, additionalMetaData);
         end
         
         % NetCDF TECHNICAL file
         if (g_decArgo_generateNcTech ~= 0)
            create_nc_tech_file(floatDecId, ...
               tabNcTechIndex, tabNcTechVal, tabTechNMeas, g_decArgo_outputNcParamLabelInfo, additionalMetaData);
         end
         
         % NetCDF META-DATA file
         if (g_decArgo_generateNcMeta ~= 0)
            create_nc_meta_file(floatDecId, structConfig);
         end
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
