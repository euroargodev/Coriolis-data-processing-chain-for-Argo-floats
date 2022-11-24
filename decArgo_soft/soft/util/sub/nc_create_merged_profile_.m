% ------------------------------------------------------------------------------
% Generate one merged profile (version 2) from one C and one B mono-profile files.
%
% SYNTAX :
%  [o_metaDataStruct, o_trajDataStruct] = nc_create_merged_profile_( ...
%    a_createOnlyMultiProfFlag, ...
%    a_cProfFileName, a_bProfFileName, a_metaFileName, a_cTrajFileName, a_bTrajFileName, ...
%    a_createMultiProfFlag, ...
%    a_metaDataStruct, a_trajDataStruct, ...
%    a_outputDir, ...
%    a_monoProfRefFile, a_multiProfRefFile, ...
%    a_tmpDir)
%
% INPUT PARAMETERS :
%   a_createOnlyMultiProfFlag : generate only M multi-profile file flag
%   a_cProfFileName       : input C prof file path name
%   a_bProfFileName       : input B prof file path name
%   a_metaFileName        : input meta file path name
%   a_cTrajFileName       : input C traj file path name
%   a_bTrajFileName       : input B traj file path name
%   a_createMultiProfFlag : generate M multi-profile file flag
%   a_metaDataStruct      : input meta-data
%   a_trajDataStruct      : input traj data
%   a_outputDir           : output M prof file directory
%   a_monoProfRefFile     : netCDF merged mono-profile file schema
%   a_multiProfRefFile    : netCDF merged multi-profile file schema
%   a_tmpDir              : base name of the temporary directory
%
% OUTPUT PARAMETERS :
%   o_metaDataStruct : output meta-data
%   o_trajDataStruct : output traj data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaDataStruct, o_trajDataStruct] = nc_create_merged_profile_( ...
   a_createOnlyMultiProfFlag, ...
   a_cProfFileName, a_bProfFileName, a_metaFileName, a_cTrajFileName, a_bTrajFileName, ...
   a_createMultiProfFlag, ...
   a_metaDataStruct, a_trajDataStruct, ...
   a_outputDir, ...
   a_monoProfRefFile, a_multiProfRefFile, ...
   a_tmpDir)     
      
% output parameters initialization
o_metaDataStruct = a_metaDataStruct;
o_trajDataStruct = a_trajDataStruct;

% current float and cycle identification
global g_cocm_floatNum;


floatWmoStr = num2str(g_cocm_floatNum);

% create a temporary directory
tmpDirName = [a_tmpDir '/'];
if ~(exist(tmpDirName, 'dir') == 7)
   mkdir(tmpDirName);
end
tmpDirName = [tmpDirName '/merged_profile/'];
if ~(exist(tmpDirName, 'dir') == 7)
   mkdir(tmpDirName);
end
tmpDirName = [tmpDirName '/' floatWmoStr '/'];
if (exist(tmpDirName, 'dir') == 7)
   % delete the temporary directory
   remove_directory(tmpDirName);
end
% create the temporary directory
mkdir(tmpDirName);

if (a_createOnlyMultiProfFlag == 0)
   
   % create output file directory
   outputFloatDirName = [a_outputDir '/' floatWmoStr '/profiles/'];
   if ~(exist(outputFloatDirName, 'dir') == 7)
      mkdir(outputFloatDirName);
   end
   
   % retrieve META data
   if (isempty(o_metaDataStruct))
      o_metaDataStruct = get_meta_data(a_metaFileName);
   end
   
   % retrieve TRAJ data
   if (isempty(o_trajDataStruct))
      o_trajDataStruct = get_traj_data(a_cTrajFileName, a_bTrajFileName);
   end
   
   % retrieve PROF data
   profDataStruct = get_prof_data(a_cProfFileName, a_bProfFileName, o_metaDataStruct);
   
   % process PROF data
   mergedProfDataStruct = [];
   if (~isempty(profDataStruct))
      mergedProfDataStruct = process_prof_data(profDataStruct, o_trajDataStruct, o_metaDataStruct);
   end
   
   % create M-PROF file
   if (~isempty(mergedProfDataStruct))
      create_merged_mono_profile_file(g_cocm_floatNum, mergedProfDataStruct, tmpDirName, a_outputDir, a_monoProfRefFile);
   end
end

% create multi M-PROF file
if ((a_createOnlyMultiProfFlag == 1) || (a_createMultiProfFlag == 1))
   
   % retrieve M-PROF data
   mergedProfAllDataStruct = get_all_merged_prof_data(a_outputDir);
   
   if (~isempty(mergedProfAllDataStruct))
      create_merged_multi_profiles_file(g_cocm_floatNum, mergedProfAllDataStruct, tmpDirName, a_outputDir, a_multiProfRefFile);
   end
end

% delete the temporary directory
remove_directory(tmpDirName);

return

% ------------------------------------------------------------------------------
% Retrieve meta-data from META file.
%
% SYNTAX :
%  [o_metaData] = get_meta_data(a_metaFilePathName)
%
% INPUT PARAMETERS :
%   a_metaFilePathName : META file path name
%
% OUTPUT PARAMETERS :
%   o_metaData : retrieved meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_meta_data(a_metaFilePathName)

% output parameters initialization
o_metaData = [];

% current float and cycle identification
global g_cocm_floatNum;


% retrieve information from META file
if ~(exist(a_metaFilePathName, 'file') == 2)
   fprintf('ERROR: Float #%d: File not found: %s\n', ...
      g_cocm_floatNum, a_metaFilePathName);
   return
end

wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'PLATFORM_TYPE'} ...
   {'DATA_CENTRE'} ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
   {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_PARAMETER_NAME'} ...
   {'CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   ];
[metaData] = get_data_from_nc_file(a_metaFilePathName, wantedVars);

formatVersion = deblank(get_data_from_name('FORMAT_VERSION', metaData)');

% check the META file format version
if (~strcmp(formatVersion, '3.1'))
   fprintf('WARNING: Float #%d: Input META file (%s) format version is %s - not used\n', ...
      g_cocm_floatNum, a_metaFilePathName, formatVersion);
   return
end

% store META file information in a dedicated structure
o_metaData = get_meta_data_init_struct;

o_metaData.platformType = deblank(get_data_from_name('PLATFORM_TYPE', metaData)');
o_metaData.dataCentre = deblank(get_data_from_name('DATA_CENTRE', metaData)');
o_metaData.parameter = get_data_from_name('PARAMETER', metaData)';
o_metaData.parameterSensor = get_data_from_name('PARAMETER_SENSOR', metaData)';
o_metaData.launchConfigParameterName = get_data_from_name('LAUNCH_CONFIG_PARAMETER_NAME', metaData)';
o_metaData.launchConfigParameterValue = get_data_from_name('LAUNCH_CONFIG_PARAMETER_VALUE', metaData);
o_metaData.configParameterName = get_data_from_name('CONFIG_PARAMETER_NAME', metaData)';
o_metaData.configParameterValue = get_data_from_name('CONFIG_PARAMETER_VALUE', metaData)';
o_metaData.configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', metaData);

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {' '}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store META information.
%
% SYNTAX :
%  [o_metaDataStruct] = get_meta_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_metaDataStruct : META data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaDataStruct] = get_meta_data_init_struct

% output parameters initialization
o_metaDataStruct = struct( ...
   'platformType', '', ...
   'dataCentre', '', ...
   'parameter', [], ...
   'parameterSensor', [], ...
   'launchConfigParameterName', [], ...
   'launchConfigParameterValue', [], ...
   'configParameterName', [], ...
   'configParameterValue', [], ...
   'configMissionNumber', []);

return

% ------------------------------------------------------------------------------
% Retrieve data from TRAJ file.
%
% SYNTAX :
%  [o_trajData] = get_traj_data(a_cTrajFileName, a_bTrajFileName)
%
% INPUT PARAMETERS :
%   a_cTrajFileName : C TRAJ file path name
%   a_bTrajFileName : B TRAJ file path name
%
% OUTPUT PARAMETERS :
%   o_trajData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajData] = get_traj_data(a_cTrajFileName, a_bTrajFileName)

% output parameters initialization
o_trajData = [];

% current float and cycle identification
global g_cocm_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;


% retrieve TRAJ data from C and B files
for idType= 1:2
   if (idType == 1)
      trajFilePathName = a_cTrajFileName;
      if ~(exist(trajFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d: File not found: %s\n', ...
            g_cocm_floatNum, trajFilePathName);
         return
      end
   else
      if (isempty(a_bTrajFileName))
         break
      end
      trajFilePathName = a_bTrajFileName;
      if ~(exist(trajFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d: File not found: %s\n', ...
            g_cocm_floatNum, trajFilePathName);
         return
      end
   end
   
   % retrieve information from TRAJ file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'TRAJECTORY_PARAMETERS'} ...
      ];
   [trajData1] = get_data_from_nc_file(trajFilePathName, wantedVars);
   
   formatVersion = deblank(get_data_from_name('FORMAT_VERSION', trajData1)');
   
   % check the TRAJ file format version
   if (~strcmp(formatVersion, '3.1'))
      fprintf('WARNING: Float #%d: Input TRAJ file (%s) format version is %s - not used\n', ...
         g_cocm_floatNum, trajFilePathName, formatVersion);
      return
   end
   
   % create the list of parameter to be retrieved from TRAJ file
   wantedVars = [ ...
      {'JULD'} ...
      {'JULD_QC'} ...
      {'JULD_ADJUSTED'} ...
      {'JULD_ADJUSTED_QC'} ...
      {'CYCLE_NUMBER'} ...
      {'MEASUREMENT_CODE'} ...
      {'CYCLE_NUMBER_INDEX'} ...
      {'DATA_MODE'} ...
      ];
   
   % add list of parameters
   trajectoryParameters = get_data_from_name('TRAJECTORY_PARAMETERS', trajData1);
   parameterList = [];
   [~, nParam] = size(trajectoryParameters);
   for idParam = 1:nParam
      paramName = deblank(trajectoryParameters(:, idParam)');
      if (~isempty(paramName))
         if ((idType == 2) && strcmp(paramName, 'PRES'))
            continue
         end
         paramInfo = get_netcdf_param_attributes(paramName);
         if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'b'))
            parameterList{end+1} = paramName;
            wantedVars = [wantedVars ...
               {paramName} ...
               {[paramName '_QC']} ...
               {[paramName '_ADJUSTED']} ...
               {[paramName '_ADJUSTED_QC']} ...
               {[paramName '_ADJUSTED_ERROR']} ...
               ];
         end
      end
   end
   
   % retrieve information from TRAJ file
   [trajData2] = get_data_from_nc_file(trajFilePathName, wantedVars);
   
   % store TRAJ data in a dedicated structure
   if (idType == 1)
      o_trajData = get_traj_data_init_struct;
   end
   
   if (idType == 1)
      o_trajData.cycleNumber = get_data_from_name('CYCLE_NUMBER', trajData2);
      o_trajData.measurementCode = get_data_from_name('MEASUREMENT_CODE', trajData2);
      o_trajData.juld = get_data_from_name('JULD', trajData2);
      o_trajData.juldQc = get_data_from_name('JULD_QC', trajData2);
      o_trajData.juldAdj = get_data_from_name('JULD_ADJUSTED', trajData2);
      o_trajData.juldAdjQc = get_data_from_name('JULD_ADJUSTED_QC', trajData2);
      o_trajData.cycleNumberIndex = get_data_from_name('CYCLE_NUMBER_INDEX', trajData2);
      o_trajData.dataMode = get_data_from_name('DATA_MODE', trajData2);
   end
   o_trajData.paramList = [o_trajData.paramList parameterList];
   
   paramFillValue = [];
   for idP = 1:length(parameterList)
      paramName = parameterList{idP};
      
      paramData = get_data_from_name(paramName, trajData2);
      % old versions of B TRAJ files may not have the same number of
      % MEASUREMENTS
      if (size(o_trajData.paramData, 1) > size(paramData, 1))
         paramInfo = get_netcdf_param_attributes(paramName);
         paramData = [paramData; repmat(paramInfo.fillValue, ...
            size(o_trajData.paramData, 1) - size(paramData, 1), 1)];
      end
      o_trajData.paramData = [o_trajData.paramData paramData];
      
      paramDataQc = get_data_from_name([paramName '_QC'], trajData2);
      % old versions of B TRAJ files may not have the same number of
      % MEASUREMENTS
      if (size(o_trajData.paramDataQc, 1) > size(paramDataQc, 1))
         paramDataQc = [paramDataQc; repmat(g_decArgo_qcStrDef, ...
            size(o_trajData.paramDataQc, 1) - size(paramDataQc, 1), 1)];
      end
      o_trajData.paramDataQc = [o_trajData.paramDataQc paramDataQc];
      
      paramDataAdjusted = get_data_from_name([paramName '_ADJUSTED'], trajData2);
      % old versions of B TRAJ files may not have the same number of
      % MEASUREMENTS
      if (size(o_trajData.paramDataAdjusted, 1) > size(paramDataAdjusted, 1))
         paramInfo = get_netcdf_param_attributes(paramName);
         paramDataAdjusted = [paramDataAdjusted; repmat(paramInfo.fillValue, ...
            size(o_trajData.paramDataAdjusted, 1) - size(paramDataAdjusted, 1), 1)];
      end
      o_trajData.paramDataAdjusted = [o_trajData.paramDataAdjusted paramDataAdjusted];
      
      paramDataAdjustedQc = get_data_from_name([paramName '_ADJUSTED_QC'], trajData2);
      % old versions of B TRAJ files may not have the same number of
      % MEASUREMENTS
      if (size(o_trajData.paramDataAdjustedQc, 1) > size(paramDataAdjustedQc, 1))
         paramDataAdjustedQc = [paramDataAdjustedQc; repmat(g_decArgo_qcStrDef, ...
            size(o_trajData.paramDataAdjustedQc, 1) - size(paramDataAdjustedQc, 1), 1)];
      end
      o_trajData.paramDataAdjustedQc = [o_trajData.paramDataAdjustedQc paramDataAdjustedQc];
      
      paramDataAdjustedError = get_data_from_name([paramName '_ADJUSTED_ERROR'], trajData2);
      % old versions of B TRAJ files may not have the same number of
      % MEASUREMENTS
      if (size(o_trajData.paramDataAdjustedError, 1) > size(paramDataAdjustedError, 1))
         paramInfo = get_netcdf_param_attributes(paramName);
         paramDataAdjustedError = [paramDataAdjustedError; repmat(paramInfo.fillValue, ...
            size(o_trajData.paramDataAdjustedError, 1) - size(paramDataAdjustedError, 1), 1)];
      end
      o_trajData.paramDataAdjustedError = [o_trajData.paramDataAdjustedError paramDataAdjustedError];
   end
end

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store TRAJ information.
%
% SYNTAX :
%  [o_trajDataStruct] = get_traj_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_trajDataStruct : TRAJ data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajDataStruct] = get_traj_data_init_struct

% output parameters initialization
o_trajDataStruct = struct( ...
   'cycleNumber', [], ...
   'measurementCode', [], ...
   'juld', [], ...
   'juldQc', '', ...
   'juldAdj', [], ...
   'juldAdjQc', '', ...
   'paramList', [], ...
   'paramData', [], ...
   'paramDataQc', '', ...
   'paramDataAdjusted', [], ...
   'paramDataAdjustedQc', '', ...
   'paramDataAdjustedError', [], ...
   'cycleNumberIndex', [], ...
   'dataMode', '');

return

% ------------------------------------------------------------------------------
% Retrieve data from PROF file.
%
% SYNTAX :
%  [o_profData] = get_prof_data(a_cProfFileName, a_bProfFileName, a_metaData)
%
% INPUT PARAMETERS :
%   a_cProfFileName : C PROF file path name
%   a_bProfFileName : B PROF file path name
%   a_metaData      : data retrieved from META file
%
% OUTPUT PARAMETERS :
%   o_profData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = get_prof_data(a_cProfFileName, a_bProfFileName, a_metaData)

% output parameter initialization
o_profData = [];

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% QC flag values (char)
global g_decArgo_qcStrDef;


% retrieve PROF data from C and B files
profDataTabC = [];
profDataTabB = [];
for idType= 1:2
   if (idType == 1)
      profFilePathName = a_cProfFileName;
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName);
         return
      end
   else
      if (isempty(a_bProfFileName))
         break
      end
      profFilePathName = a_bProfFileName;
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName);
         return
      end
   end
   
   % retrieve information from PROF file
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'STATION_PARAMETERS'} ...
      ];
   [profData1] = get_data_from_nc_file(profFilePathName, wantedVars);
   
   formatVersion = deblank(get_data_from_name('FORMAT_VERSION', profData1)');
   
   % check the PROF file format version
   if (~strcmp(formatVersion, '3.1'))
      fprintf('WARNING: Float #%d Cycle #%d%c: Input PROF file (%s) format version is %s - not used\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName, formatVersion);
      return
   end
   
   % create the list of parameters to be retrieved from PROF file
   wantedVars = [ ...
      {'HANDBOOK_VERSION'} ...
      {'REFERENCE_DATE_TIME'} ...
      ...
      {'PLATFORM_NUMBER'} ...
      {'PROJECT_NAME'} ...
      {'PI_NAME'} ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'DATA_CENTRE'} ...
      {'DATA_MODE'} ...
      {'PARAMETER_DATA_MODE'} ...
      {'PLATFORM_TYPE'} ...
      {'FLOAT_SERIAL_NO'} ...
      {'FIRMWARE_VERSION'} ...
      {'WMO_INST_TYPE'} ...
      {'JULD'} ...
      {'JULD_QC'} ...
      {'JULD_LOCATION'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_QC'} ...
      {'POSITIONING_SYSTEM'} ...
      {'VERTICAL_SAMPLING_SCHEME'} ...
      {'CONFIG_MISSION_NUMBER'} ...
      {'PARAMETER'} ...
      {'SCIENTIFIC_CALIB_EQUATION'} ...
      {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
      {'SCIENTIFIC_CALIB_COMMENT'} ...
      {'SCIENTIFIC_CALIB_DATE'} ...
      ];
   
   % add parameter measurements
   stationParameters = get_data_from_name('STATION_PARAMETERS', profData1);
   parameterList = [];
   [~, nParam, nProf] = size(stationParameters);
   for idProf = 1:nProf
      profParamList = [];
      for idParam = 1:nParam
         paramName = deblank(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            paramInfo = get_netcdf_param_attributes(paramName);
            if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'b'))
               profParamList{end+1} = paramName;
               wantedVars = [wantedVars ...
                  {paramName} ...
                  {[paramName '_QC']} ...
                  {[paramName '_ADJUSTED']} ...
                  {[paramName '_ADJUSTED_QC']} ...
                  {[paramName '_ADJUSTED_ERROR']} ...
                  ];
            end
         end
      end
      parameterList = [parameterList; {profParamList}];
   end
   
   % retrieve information from PROF file
   [profData2] = get_data_from_nc_file(profFilePathName, wantedVars);
   
   handbookVersion = get_data_from_name('HANDBOOK_VERSION', profData2)';
   referenceDateTime = get_data_from_name('REFERENCE_DATE_TIME', profData2)';
   platformNumber = get_data_from_name('PLATFORM_NUMBER', profData2)';
   projectName = get_data_from_name('PROJECT_NAME', profData2)';
   piName = get_data_from_name('PI_NAME', profData2)';
   cycleNumber = get_data_from_name('CYCLE_NUMBER', profData2)';
   direction = get_data_from_name('DIRECTION', profData2)';
   dataCentre = get_data_from_name('DATA_CENTRE', profData2)';
   dataMode = get_data_from_name('DATA_MODE', profData2)';
   parameterDataMode = get_data_from_name('PARAMETER_DATA_MODE', profData2)';
   platformType = get_data_from_name('PLATFORM_TYPE', profData2)';
   floatSerialNo = get_data_from_name('FLOAT_SERIAL_NO', profData2)';
   firmwareVersion = get_data_from_name('FIRMWARE_VERSION', profData2)';
   wmoInstType = get_data_from_name('WMO_INST_TYPE', profData2)';
   juld = get_data_from_name('JULD', profData2)';
   juldQc = get_data_from_name('JULD_QC', profData2)';
   juldLocation = get_data_from_name('JULD_LOCATION', profData2)';
   latitude = get_data_from_name('LATITUDE', profData2)';
   longitude = get_data_from_name('LONGITUDE', profData2)';
   positionQc = get_data_from_name('POSITION_QC', profData2)';
   positioningSystem = get_data_from_name('POSITIONING_SYSTEM', profData2)';
   verticalSamplingScheme = get_data_from_name('VERTICAL_SAMPLING_SCHEME', profData2)';
   configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', profData2)';
   parameter = get_data_from_name('PARAMETER', profData2);
   scientificCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', profData2);
   scientificCalibCoefficient = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', profData2);
   scientificCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', profData2);
   scientificCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', profData2);
   
   % retrieve information from PROF file
   wantedVarAtts = [ ...
      {'JULD'} {'resolution'} ...
      {'JULD_LOCATION'} {'resolution'} ...
      ];
   
   [profDataAtt] = get_att_from_nc_file(profFilePathName, wantedVarAtts);
   
   juldResolution = get_att_from_name('JULD', 'resolution', profDataAtt);
   juldLocationResolution = get_att_from_name('JULD_LOCATION', 'resolution', profDataAtt);
   
   % store PROF data in dedicated structures
   for idProf = 1:nProf
      profData = get_prof_data_init_struct;
      
      profData.nProfId = idProf;
      profData.handbookVersion = strtrim(handbookVersion);
      profData.referenceDateTime = strtrim(referenceDateTime);
      profData.platformNumber = strtrim(platformNumber(idProf, :));
      profData.projectName = strtrim(projectName(idProf, :));
      profData.piName = strtrim(piName(idProf, :));
      profData.cycleNumber = cycleNumber(idProf);
      profData.direction = direction(idProf);
      profData.dataCentre = strtrim(dataCentre(idProf, :));
      profData.platformType = strtrim(platformType(idProf, :));
      profData.floatSerialNo = strtrim(floatSerialNo(idProf, :));
      profData.firmwareVersion = strtrim(firmwareVersion(idProf, :));
      profData.wmoInstType = strtrim(wmoInstType(idProf, :));
      profData.juld = juld(idProf);
      profData.juldResolution = juldResolution;
      profData.juldQc = juldQc(idProf);
      profData.juldLocation = juldLocation(idProf);
      profData.juldLocationResolution = juldLocationResolution;
      profData.latitude = latitude(idProf);
      profData.longitude = longitude(idProf);
      profData.positionQc = positionQc(idProf);
      profData.positioningSystem = positioningSystem(idProf, :);
      profData.verticalSamplingScheme = strtrim(verticalSamplingScheme(idProf, :));
      profData.configMissionNumber = configMissionNumber(idProf);
      
      profParameterList = parameterList{idProf};
      profData.paramList = profParameterList;
      if (idType == 2)
         idPres = find(strcmp('PRES', profData.paramList) == 1, 1);
         profData.paramList(idPres) = [];
      end
      
      % set sensor associated to parameters (using PARAMETER_SENSOR meta-data)
      if (~isempty(a_metaData))
         metaParamList = cellstr(a_metaData.parameter);
         metaParamSensorList = cellstr(a_metaData.parameterSensor);
         for idParam = 1:length(profData.paramList)
            paramName = profData.paramList{idParam};
            idF = find(strcmp(paramName, metaParamList));
            if (isempty(idF))
               fprintf('ERROR: Float #%d Cycle #%d%c: No SENSOR is associated to parameter ''%s'' in the meta file - exit\n', ...
                  g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramName);
               return
            end
            profData.paramSensorList{end+1} = metaParamSensorList{idF};
         end
      end
      
      % array to store SCIENTIFIC_CALIB_* information
      [~, ~, nCalib, ~] = size(parameter);
      sciCalibEquation = cell(1, length(profData.paramList));
      sciCalibCoefficient = cell(1, length(profData.paramList));
      sciCalibComment = cell(1, length(profData.paramList));
      sciCalibDate = cell(1, length(profData.paramList));
      
      for idParam = 1:length(profParameterList)
         paramName = profParameterList{idParam};
         paramData = get_data_from_name(paramName, profData2)';
         if (strcmp(paramName, 'PRES'))
            profData.presData = paramData(idProf, :)';
         end
         if ((idType == 2) && strcmp(paramName, 'PRES'))
            continue
         end
         if (idType == 1)
            profData.paramDataMode = [profData.paramDataMode dataMode(idProf)];
         else
            % find N_PARAM index of the current parameter
            nParamId = [];
            for idParamNc = 1:nParam
               stationParametersParamName = deblank(stationParameters(:, idParamNc, idProf)');
               if (strcmp(paramName, stationParametersParamName))
                  nParamId = idParamNc;
                  break
               end
            end
            if (~isempty(deblank(parameterDataMode)))
               profData.paramDataMode = [profData.paramDataMode parameterDataMode(idProf, nParamId)];
            elseif (dataMode(idProf) == 'R')
               %                fprintf('WARNING: Float #%d Cycle #%d%c: PARAMETER_DATA_MODE information is missing in input PROF file (%s) - set to ''R'' (as DATA_MODE = ''R'')\n', ...
               %                   g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName);
               profData.paramDataMode = [profData.paramDataMode 'R'];
            else
               fprintf('ERROR: Float #%d Cycle #%d%c: PARAMETER_DATA_MODE information is missing in input PROF file (%s) - exit (as DATA_MODE = ''%c'')\n', ...
                  g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName, dataMode(idProf));
               return
            end
         end
         profData.paramData = [profData.paramData paramData(idProf, :)'];
         paramDataQc = get_data_from_name([paramName '_QC'], profData2)';
         profData.paramDataQc = [profData.paramDataQc paramDataQc(idProf, :)'];
         paramDataAdjusted = get_data_from_name([paramName '_ADJUSTED'], profData2)';
         profData.paramDataAdjusted = [profData.paramDataAdjusted paramDataAdjusted(idProf, :)'];
         paramDataAdjustedQc = get_data_from_name([paramName '_ADJUSTED_QC'], profData2)';
         profData.paramDataAdjustedQc = [profData.paramDataAdjustedQc paramDataAdjustedQc(idProf, :)'];
         paramDataAdjustedError = get_data_from_name([paramName '_ADJUSTED_ERROR'], profData2)';
         profData.paramDataAdjustedError = [profData.paramDataAdjustedError paramDataAdjustedError(idProf, :)'];
         
         % manage SCIENTIFIC_CALIB_* information
         sciCalEquation = cell(1, nCalib);
         sciCalCoefficient = cell(1, nCalib);
         sciCalComment = cell(1, nCalib);
         sciCalDate = cell(1, nCalib);
         
         % find N_PARAM index of the current parameter
         nParamId = [];
         for idCalib = 1:nCalib
            for idParamNc = 1:nParam
               calibParamName = deblank(parameter(:, idParamNc, idCalib, idProf)');
               if (~isempty(calibParamName))
                  if (strcmp(paramName, calibParamName))
                     nParamId = idParamNc;
                     break
                  end
               end
            end
            if (~isempty(nParamId))
               break
            end
         end
         if (~isempty(nParamId))
            for idCalib2 = 1:nCalib
               sciCalEquation{idCalib2} = deblank(scientificCalibEquation(:, nParamId, idCalib2, idProf)');
               sciCalCoefficient{idCalib2} = deblank(scientificCalibCoefficient(:, nParamId, idCalib2, idProf)');
               sciCalComment{idCalib2} = deblank(scientificCalibComment(:, nParamId, idCalib2, idProf)');
               sciCalDate{idCalib2} = deblank(scientificCalibDate(:, nParamId, idCalib2, idProf)');
            end
         end
         idParam2 = find(strcmp(paramName, profData.paramList) == 1, 1);
         sciCalibEquation{idParam2} = sciCalEquation;
         sciCalibCoefficient{idParam2} = sciCalCoefficient;
         sciCalibComment{idParam2} = sciCalComment;
         sciCalibDate{idParam2} = sciCalDate;
      end
      profData.scientificCalibEquation = sciCalibEquation;
      profData.scientificCalibCoefficient = sciCalibCoefficient;
      profData.scientificCalibComment = sciCalibComment;
      profData.scientificCalibDate = sciCalibDate;
      
      if (idType == 1)
         profDataTabC = [profDataTabC profData];
      else
         profDataTabB = [profDataTabB profData];
      end
   end
end

% concatenate C and B data
profDataTab = [];
for idProfC = 1:length(profDataTabC)
   profData = profDataTabC(idProfC);
   for idProfB = 1:length(profDataTabB)
      if (length(profData.presData) ~= length(profDataTabB(idProfB).presData))
         fprintf('WARNING: Float #%d Cycle #%d%c: C and B files don''t have the same number of levels (%d vs %d) - files ignored\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, ...
            length(profData.presData), ...
            length(profDataTabB(idProfB).presData));
         return
      end
      if (~any((profData.presData - profDataTabB(idProfB).presData) ~= 0))
         profDataB = profDataTabB(idProfB);
         profData.paramList = [profData.paramList profDataB.paramList];
         profData.paramSensorList = [profData.paramSensorList profDataB.paramSensorList];
         profData.paramDataMode = [profData.paramDataMode profDataB.paramDataMode];
         profData.paramData = [profData.paramData profDataB.paramData];
         profData.paramDataQc = [profData.paramDataQc profDataB.paramDataQc];
         profData.paramDataAdjusted = [profData.paramDataAdjusted profDataB.paramDataAdjusted];
         profData.paramDataAdjustedQc = [profData.paramDataAdjustedQc profDataB.paramDataAdjustedQc];
         profData.paramDataAdjustedError = [profData.paramDataAdjustedError profDataB.paramDataAdjustedError];
         % N_CALIB of C and B files are not necessarily the same
         nCalibC = 0;
         if (~isempty(profData.scientificCalibEquation))
            nCalibC = length(profData.scientificCalibEquation{1});
         end
         nCalibB = 0;
         if (~isempty(profDataB.scientificCalibEquation))
            nCalibB = length(profDataB.scientificCalibEquation{1});
         end
         if (nCalibC > nCalibB)
            for idParam = 1:length(profDataB.scientificCalibEquation)
               profDataB.scientificCalibEquation{idParam} = ...
                  cat(2, profDataB.scientificCalibEquation{idParam}, cell(1, nCalibC-nCalibB));
               profDataB.scientificCalibCoefficient{idParam} = ...
                  cat(2, profDataB.scientificCalibCoefficient{idParam}, cell(1, nCalibC-nCalibB));
               profDataB.scientificCalibComment{idParam} = ...
                  cat(2, profDataB.scientificCalibComment{idParam}, cell(1, nCalibC-nCalibB));
               profDataB.scientificCalibDate{idParam} = ...
                  cat(2, profDataB.scientificCalibDate{idParam}, cell(1, nCalibC-nCalibB));
            end
         else
            for idParam = 1:length(profData.scientificCalibEquation)
               profData.scientificCalibEquation{idParam} = ...
                  cat(2, profData.scientificCalibEquation{idParam}, cell(1, nCalibB-nCalibC));
               profData.scientificCalibCoefficient{idParam} = ...
                  cat(2, profData.scientificCalibCoefficient{idParam}, cell(1, nCalibB-nCalibC));
               profData.scientificCalibComment{idParam} = ...
                  cat(2, profData.scientificCalibComment{idParam}, cell(1, nCalibB-nCalibC));
               profData.scientificCalibDate{idParam} = ...
                  cat(2, profData.scientificCalibDate{idParam}, cell(1, nCalibB-nCalibC));
            end
         end
         profData.scientificCalibEquation = [profData.scientificCalibEquation profDataB.scientificCalibEquation];
         profData.scientificCalibCoefficient = [profData.scientificCalibCoefficient profDataB.scientificCalibCoefficient];
         profData.scientificCalibComment = [profData.scientificCalibComment profDataB.scientificCalibComment];
         profData.scientificCalibDate = [profData.scientificCalibDate profDataB.scientificCalibDate];
         profDataTabB(idProfB) = [];
         break
      end
   end
   profDataTab = [profDataTab profData];
end
if (~isempty(profDataTabB))
   fprintf('WARNING: Float #%d Cycle #%d%c: %d B profiles are not used\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, length(profDataTabB));
end

% set PRES, TEMP and PSAL parameters at the begining of the list
listParam = [{'PRES'} {'TEMP'} {'PSAL'}];
for idProf = 1:length(profDataTab)
   paramList = profDataTab(idProf).paramList;
   for idParam = 1:length(listParam)
      paramName = listParam{idParam};
      if (any(strcmp(paramList, paramName)))
         if ((length(paramList) >= length(listParam)) && ~strcmp(paramList{idParam}, paramName))
            idParamOld = find(strcmp(paramName, profParamList) == 1, 1);
            profDataTab(idProf).paramList = [profDataTab(idProf).paramList(idParamOld) profDataTab(idProf).paramList];
            profDataTab(idProf).paramDataMode = [profDataTab(idProf).paramDataMode(idParamOld) profDataTab(idProf).paramDataMode];
            profDataTab(idProf).paramData = [profDataTab(idProf).paramData(:, idParamOld) profDataTab(idProf).paramData];
            profDataTab(idProf).paramDataQc = [profDataTab(idProf).paramDataQc(:, idParamOld) profDataTab(idProf).paramDataQc];
            profDataTab(idProf).paramDataAdjusted = [profDataTab(idProf).paramDataAdjusted(:, idParamOld) profDataTab(idProf).paramDataAdjusted];
            profDataTab(idProf).paramDataAdjustedQc = [profDataTab(idProf).paramDataAdjustedQc(:, idParamOld) profDataTab(idProf).paramDataAdjustedQc];
            profDataTab(idProf).paramDataAdjustedError = [profDataTab(idProf).paramDataAdjustedError(:, idParamOld) profDataTab(idProf).paramDataAdjustedError];
            profDataTab(idProf).scientificCalibEquation = [profDataTab(idProf).scientificCalibEquation(idParamOld) profDataTab(idProf).scientificCalibEquation];
            profDataTab(idProf).scientificCalibCoefficient = [profDataTab(idProf).scientificCalibCoefficient(idParamOld) profDataTab(idProf).scientificCalibCoefficient];
            profDataTab(idProf).scientificCalibComment = [profDataTab(idProf).scientificCalibComment(idParamOld) profDataTab(idProf).scientificCalibComment];
            profDataTab(idProf).scientificCalibDate = [profDataTab(idProf).scientificCalibDate(idParamOld) profDataTab(idProf).scientificCalibDate];
            
            profDataTab(idProf).paramList(idParamOld+1) = [];
            profDataTab(idProf).paramDataMode(idParamOld+1) = [];
            profDataTab(idProf).paramData(:, idParamOld+1) = [];
            profDataTab(idProf).paramDataQc(:, idParamOld+1) = [];
            profDataTab(idProf).paramDataAdjusted(:, idParamOld+1) = [];
            profDataTab(idProf).paramDataAdjustedQc(:, idParamOld+1) = [];
            profDataTab(idProf).paramDataAdjustedError(:, idParamOld+1) = [];
            profDataTab(idProf).scientificCalibEquation(idParamOld+1) = [];
            profDataTab(idProf).scientificCalibCoefficient(idParamOld+1) = [];
            profDataTab(idProf).scientificCalibComment(idParamOld+1) = [];
            profDataTab(idProf).scientificCalibDate(idParamOld+1) = [];
            
            fprintf('INFO: Float #%d Cycle #%d%c: ''%s'' parameter moved (%d->%d)\n', ...
               g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, ...
               paramName, idParamOld, idParam);
         end
      end
   end
end

% clear unused levels
for idProf = 1:length(profDataTab)
   paramDataQc = profDataTab(idProf).paramDataQc;
   idDel = [];
   for idLev = 1:size(paramDataQc, 1)
      if (~any((paramDataQc(idLev, :) ~= g_decArgo_qcStrDef) & (paramDataQc(idLev, :) ~= '9')))
         idDel = [idDel idLev];
      end
   end
   if (~isempty(idDel))
      profDataTab(idProf).paramData(idDel, :) = [];
      profDataTab(idProf).paramDataQc(idDel, :) = [];
      profDataTab(idProf).paramDataAdjusted(idDel, :) = [];
      profDataTab(idProf).paramDataAdjustedQc(idDel, :) = [];
      profDataTab(idProf).paramDataAdjustedError(idDel, :) = [];
   end
end

% sort profiles
sortedId = nan(1, length(profDataTab));
nProfId = [profDataTab.nProfId];

% highest priority for primary sampling frofile (N_PROF = 1)
sortedId(find(nProfId == 1)) = 1;

% unpumped Near Surface sampling is part of one (original) profile
vssList = {profDataTab.verticalSamplingScheme};
idUnpumped = cellfun(@(x) strfind(x, 'Near-surface sampling') & strfind(x, 'unpumped'), vssList, 'UniformOutput', 0);
idUnpumped = find(~cellfun(@isempty, idUnpumped) == 1);
sortedId(idUnpumped) = -1;

% sort the remaining profiles according to PARAMETER_SENSOR information
profIdList = find(isnan(sortedId));
catParamSensorList = [];
for idProf = profIdList
   paramSensorList = profDataTab(idProf).paramSensorList;
   paramSensorList = sort(paramSensorList);
   catStr = paramSensorList{1};
   for idPS = 2:length(paramSensorList)
      catStr = [catStr '_' paramSensorList{idPS}];
   end
   catParamSensorList{end+1} = catStr;
end
[~, idSort] = sort(catParamSensorList);
offset = 1;
sortedId(profIdList) = idSort + offset;

% set the sorted id of unpumped Near Surface profiles
for idProf = idUnpumped
   paramList = profDataTab(idProf).paramList;
   idRef = -1;
   for idP = 1:length(profDataTab)
      if (idP ~= idProf)
         if (length(paramList) == length(profDataTab(idP).paramList))
            if (~any(strcmp(paramList, profDataTab(idP).paramList) ~= 1))
               idRef = idP;
               break
            end
         end
      end
   end
   if (idRef > 0)
      idToShift = find((sortedId > sortedId(idRef)) & (sortedId > 0));
      sortedId(idToShift) = sortedId(idToShift) + 1;
      sortedId(idProf) = sortedId(idRef) + 1;
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' unpumped profile #%d cannot be assocated to existing one - data ignored\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, ...
         idProf);
   end
end
sortedId(find(sortedId < 0)) = []; % in case of ERROR
profDataTab = profDataTab(sortedId);

% output parameter
o_profData = profDataTab;

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVarAtts  : NetCDF variable names and attribute names to retrieve
%                      from the file
%
% OUTPUT PARAMETERS :
%   o_ncDataAtt : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)

% output parameters initialization
o_ncDataAtt = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve attributes from NetCDF file
   for idVar = 1:2:length(a_wantedVarAtts)
      varName = a_wantedVarAtts{idVar};
      attName = a_wantedVarAtts{idVar+1};
      
      if (var_is_present_dec_argo(fCdf, varName) && att_is_present_dec_argo(fCdf, varName, attName))
         attValue = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName);
         o_ncDataAtt = [o_ncDataAtt {varName} {attName} {attValue}];
      else
         o_ncDataAtt = [o_ncDataAtt {varName} {attName} {' '}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Get attribute data from variable name and attribute in a
% {var_name}/{var_att}/{att_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)
%
% INPUT PARAMETERS :
%   a_varName : name of the variable
%   a_attName : name of the attribute
%   a_dataList : {var_name}/{var_att}/{att_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_varName, a_dataList(1:3:end)) & strcmp(a_attName, a_dataList(2:3:end)));
if (~isempty(idVal))
   o_dataValues = a_dataList{3*idVal};
end

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store PROF information.
%
% SYNTAX :
%  [o_profDataStruct] = get_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profDataStruct : PROF data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataStruct] = get_prof_data_init_struct

% output parameters initialization
o_profDataStruct = struct( ...
   'nProfId', [], ...
   'handbookVersion', '', ...
   'referenceDateTime', '', ...
   'platformNumber', '', ...
   'projectName', '', ...
   'piName', '', ...
   'cycleNumber', [], ...
   'direction', '', ...
   'dataCentre', '', ...
   'platformType', '', ...
   'floatSerialNo', '', ...
   'firmwareVersion', '', ...
   'wmoInstType', '', ...
   'juld', [], ...
   'juldResolution', [], ...
   'juldQc', '', ...
   'juldLocation', [], ...
   'juldLocationResolution', [], ...
   'latitude', [], ...
   'longitude', [], ...
   'positionQc', '', ...
   'positioningSystem', '', ...
   'verticalSamplingScheme', '', ...
   'configMissionNumber', [], ...
   ...
   'paramList', [], ...
   'paramSensorList', [], ...
   'paramDataMode', '', ...
   ...
   'presData', [], ...
   'paramData', [], ...
   'paramDataQc', '', ...
   'paramDataAdjusted', [], ...
   'paramDataAdjustedQc', '', ...
   'paramDataAdjustedError', [], ...
   ...
   'scientificCalibEquation', [], ...
   'scientificCalibCoefficient', [], ...
   'scientificCalibComment', [], ...
   'scientificCalibDate', [] ...
   );

return

% ------------------------------------------------------------------------------
% Process PROF (and TRAJ) data to generate merged profile data.
%
% SYNTAX :
%  [o_mergedProfData] = process_prof_data(a_profData, a_trajData, a_metaData)
%
% INPUT PARAMETERS :
%   a_profData : data retrieved from PROF file(s)
%   a_trajData : data retrieved from TRAJ file(s)
%   a_metaData : data retrieved from META file
%
% OUTPUT PARAMETERS :
%   o_mergedProfData : merged profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mergedProfData] = process_prof_data(a_profData, a_trajData, a_metaData)

% output parameters initialization
o_mergedProfData = [];

% global measurement codes
global g_MC_DescProf;
global g_MC_AscProf;
global g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrChanged;
global g_decArgo_qcStrInterpolated;
global g_decArgo_qcStrMissing;

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% to print data after each processing step
global g_cocm_printCsv;


% check input profile consistency
errorFlag = 0;
if (length(unique({a_profData.handbookVersion})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple HANDBOOK_VERSION - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.referenceDateTime})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple REFERENCE_DATE_TIME - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.platformNumber})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PLATFORM_NUMBER - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.projectName})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PROJECT_NAME - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.piName})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PI_NAME - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.cycleNumber])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple CYCLE_NUMBER - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.direction})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple DIRECTION - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.dataCentre})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple DATA_CENTRE - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.platformType})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PLATFORM_TYPE - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.floatSerialNo})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple FLOAT_SERIAL_NO - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.firmwareVersion})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple FIRMWARE_VERSION - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.wmoInstType})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple WMO_INST_TYPE - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juld])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldResolution])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD:resolution - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.juldQc})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_QC - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldLocation])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_LOCATION - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldLocationResolution])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_LOCATION:resolution - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.latitude])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple LATITUDE - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.longitude])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple LONGITUDE - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.positionQc})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple POSITION_QC - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.positioningSystem})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple POSITIONING_SYSTEM - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.configMissionNumber])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple CONFIG_MISSION_NUMBER - file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (errorFlag == 1)
   return
end

% create merged profile
o_mergedProfData = get_merged_prof_data_init_struct;

o_mergedProfData.handbookVersion = a_profData(1).handbookVersion;
o_mergedProfData.referenceDateTime = a_profData(1).referenceDateTime;
o_mergedProfData.platformNumber = a_profData(1).platformNumber;
o_mergedProfData.projectName = a_profData(1).projectName;
o_mergedProfData.piName = a_profData(1).piName;
o_mergedProfData.cycleNumber = a_profData(1).cycleNumber;
o_mergedProfData.direction = a_profData(1).direction;
o_mergedProfData.dataCentre = a_profData(1).dataCentre;
o_mergedProfData.platformType = a_profData(1).platformType;
o_mergedProfData.floatSerialNo = a_profData(1).floatSerialNo;
o_mergedProfData.firmwareVersion = a_profData(1).firmwareVersion;
o_mergedProfData.wmoInstType = a_profData(1).wmoInstType;
o_mergedProfData.juld = a_profData(1).juld;
o_mergedProfData.juldResolution = a_profData(1).juldResolution;
o_mergedProfData.juldQc = a_profData(1).juldQc;
o_mergedProfData.juldLocation = a_profData(1).juldLocation;
o_mergedProfData.juldLocationResolution = a_profData(1).juldLocationResolution;
o_mergedProfData.latitude = a_profData(1).latitude;
o_mergedProfData.longitude = a_profData(1).longitude;
o_mergedProfData.positionQc = a_profData(1).positionQc;
o_mergedProfData.positioningSystem = a_profData(1).positioningSystem;
o_mergedProfData.configMissionNumber = a_profData(1).configMissionNumber;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #1: gather all profile data in the same array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% uniformisation of parameter list
paramList = [];
paramFillValue = [];
paramDataMode = [];
for idProf = 1:length(a_profData)
   profParamList = a_profData(idProf).paramList;
   for idParam = 1:length(profParamList)
      if (~ismember(profParamList{idParam}, paramList))
         paramList = [paramList profParamList(idParam)];
         paramInfo = get_netcdf_param_attributes(profParamList{idParam});
         paramFillValue = [paramFillValue paramInfo.fillValue];
         paramDataMode = [paramDataMode a_profData(idProf).paramDataMode(idParam)];
      end
   end
end

nbLev = 0;
for idProf = 1:length(a_profData)
   
   profData = a_profData(idProf);
   
   profParamList = profData.paramList;
   profParamId = 1;
   for idParam = 2:length(profParamList)
      idF = find(strcmp(profParamList{idParam}, paramList));
      profParamId = [profParamId idF];
   end
   
   profParamDataMode = repmat(' ', 1, length(paramList));
   profParamDataMode(profParamId) = profData.paramDataMode;
   
   paramData = repmat(paramFillValue, size(profData.paramData, 1), 1);
   paramDataQc = repmat(g_decArgo_qcStrMissing, size(paramData));
   paramDataAdjusted = repmat(paramFillValue, size(profData.paramData, 1), 1);
   paramDataAdjustedQc = repmat(g_decArgo_qcStrMissing, size(paramData));
   paramDataAdjustedError = repmat(paramFillValue, size(profData.paramData, 1), 1);
   
   paramData(:, profParamId) = profData.paramData;
   paramDataQc(:, profParamId) = profData.paramDataQc;
   paramDataAdjusted(:, profParamId) = profData.paramDataAdjusted;
   paramDataAdjustedQc(:, profParamId) = profData.paramDataAdjustedQc;
   paramDataAdjustedError(:, profParamId) = profData.paramDataAdjustedError;
   
   scientificCalibEquation = cell(1, length(paramList));
   scientificCalibEquation(profParamId) = profData.scientificCalibEquation;
   scientificCalibCoefficient = cell(1, length(paramList));
   scientificCalibCoefficient(profParamId) = profData.scientificCalibCoefficient;
   scientificCalibComment = cell(1, length(paramList));
   scientificCalibComment(profParamId) = profData.scientificCalibComment;
   scientificCalibDate = cell(1, length(paramList));
   scientificCalibDate(profParamId) = profData.scientificCalibDate;
   
   a_profData(idProf).paramList = paramList;
   a_profData(idProf).paramDataMode = profParamDataMode;
   
   a_profData(idProf).paramData = paramData;
   a_profData(idProf).paramDataQc = paramDataQc;
   a_profData(idProf).paramDataAdjusted = paramDataAdjusted;
   a_profData(idProf).paramDataAdjustedQc = paramDataAdjustedQc;
   a_profData(idProf).paramDataAdjustedError = paramDataAdjustedError;
   
   a_profData(idProf).scientificCalibEquation = scientificCalibEquation;
   a_profData(idProf).scientificCalibCoefficient = scientificCalibCoefficient;
   a_profData(idProf).scientificCalibComment = scientificCalibComment;
   a_profData(idProf).scientificCalibDate = scientificCalibDate;
   
   nbLev = nbLev + size(a_profData(idProf).paramData, 1);
end

% initialize data arrays
paramData = repmat(paramFillValue, nbLev, 1);
paramDataQc = repmat(g_decArgo_qcStrDef, size(paramData));
paramDataAdjusted = repmat(paramFillValue, nbLev, 1);
paramDataAdjustedQc = repmat(g_decArgo_qcStrDef, size(paramData));
paramDataAdjustedError = repmat(paramFillValue, nbLev, 1);

juldDataMode = '';
paramJuld = get_netcdf_param_attributes('JULD');
paramJuldFillValue = paramJuld.fillValue;
juld = [];
juldQc = '';
juldAdjusted = [];
juldAdjustedQc = '';

presAxisFlagConfig = [];
presAxisFlagAlgo = [];

scientificCalibEquation = cell(1, length(paramList));
scientificCalibCoefficient = cell(1, length(paramList));
scientificCalibComment = cell(1, length(paramList));
scientificCalibDate = cell(1, length(paramList));

% collect data
startLev = 1;
for idProf = 1:length(a_profData)
   profData = a_profData(idProf);
   
   profParamData = profData.paramData;
   profParamDataQc = profData.paramDataQc;
   profParamDataAdjusted = profData.paramDataAdjusted;
   profParamDataAdjustedQc = profData.paramDataAdjustedQc;
   profParamDataAdjustedError = profData.paramDataAdjustedError;
   
   profNbLev = size(profParamData, 1);
   
   paramData(startLev:startLev+profNbLev-1, :) = profParamData;
   paramDataQc(startLev:startLev+profNbLev-1, :) = profParamDataQc;
   paramDataAdjusted(startLev:startLev+profNbLev-1, :) = profParamDataAdjusted;
   paramDataAdjustedQc(startLev:startLev+profNbLev-1, :) = profParamDataAdjustedQc;
   paramDataAdjustedError(startLev:startLev+profNbLev-1, :) = profParamDataAdjustedError;
   
   % we don't known how to manage different information from different inital
   % profiles for a same parameter => we keep only the information from the
   % first N_PROF intial profile
   sciCalibEquation = profData.scientificCalibEquation;
   sciCalibCoefficient = profData.scientificCalibCoefficient;
   sciCalibComment = profData.scientificCalibComment;
   sciCalibDate = profData.scientificCalibDate;
   for idP = 1:length(sciCalibEquation)
      scientificCalibEquationParam = scientificCalibEquation{idP};
      scientificCalibCoefficientParam = scientificCalibCoefficient{idP};
      scientificCalibCommentParam = scientificCalibComment{idP};
      scientificCalibDateParam = scientificCalibDate{idP};
      
      sciCalibEquationParam = sciCalibEquation{idP};
      sciCalibCoefficientParam = sciCalibCoefficient{idP};
      sciCalibCommentParam = sciCalibComment{idP};
      sciCalibDateParam = sciCalibDate{idP};
      
      updatedFlag = 0;
      for idC = 1:length(sciCalibEquationParam)
         
         % if N_CALIB > 1 update the size of the cell arrays
         if (length(scientificCalibEquationParam) < idC)
            tmpEquationParam = scientificCalibEquationParam;
            tmpCoefficientParam = scientificCalibCoefficientParam;
            tmpCommentParam = scientificCalibCommentParam;
            tmpDateParam = scientificCalibDateParam;
            
            scientificCalibEquationParam = cell(1, length(sciCalibEquationParam));
            scientificCalibCoefficientParam = cell(1, length(sciCalibEquationParam));
            scientificCalibCommentParam = cell(1, length(sciCalibEquationParam));
            scientificCalibDateParam = cell(1, length(sciCalibEquationParam));
            
            scientificCalibEquationParam(1:length(tmpEquationParam)) = tmpEquationParam;
            scientificCalibCoefficientParam(1:length(tmpEquationParam)) = tmpCoefficientParam;
            scientificCalibCommentParam(1:length(tmpEquationParam)) = tmpCommentParam;
            scientificCalibDateParam(1:length(tmpEquationParam)) = tmpDateParam;
            
            scientificCalibEquation{idP} = scientificCalibEquationParam;
            scientificCalibCoefficient{idP} = scientificCalibEquationParam;
            scientificCalibComment{idP} = scientificCalibEquationParam;
            scientificCalibDate{idP} = scientificCalibEquationParam;
         end
         
         % checke if the array need to be updated
         if (isempty(scientificCalibEquationParam{idC}) && ...
               isempty(scientificCalibCoefficientParam{idC}) && ...
               isempty(scientificCalibCommentParam{idC}) && ...
               isempty(scientificCalibDateParam{idC}))
            if (~isempty(sciCalibEquationParam{idC}) || ...
                  ~isempty(sciCalibCoefficientParam{idC}) || ...
                  ~isempty(sciCalibCommentParam{idC}) || ...
                  ~isempty(sciCalibDateParam{idC}))
               scientificCalibEquationParam{idC} = sciCalibEquationParam{idC};
               scientificCalibCoefficientParam{idC} = sciCalibCoefficientParam{idC};
               scientificCalibCommentParam{idC} = sciCalibCommentParam{idC};
               scientificCalibDateParam{idC} = sciCalibDateParam{idC};
               updatedFlag = 1;
            end
         end
      end
      
      if (updatedFlag)
         scientificCalibEquation{idP} = scientificCalibEquationParam;
         scientificCalibCoefficient{idP} = scientificCalibCoefficientParam;
         scientificCalibComment{idP} = scientificCalibCommentParam;
         scientificCalibDate{idP} = scientificCalibDateParam;
      end
   end
   
   startLev = startLev + profNbLev;
end

if (g_cocm_printCsv)
   print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
      presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
      paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step1');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #2: keep only levels with PRES_QC/PRES_ADJUSTED_QC = '1', '2', '5' or
% '8', then sort PRES levels in ascending order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% keep only levels with PRES_QC/PRES_ADJUSTED_QC = '1', '2', '5' or '8'
% note that PRES set to FillVale (missing pressures) have a QC = '9' (missing
% value), so these levels are also removed by this step
qcToKeepList = [g_decArgo_qcStrGood g_decArgo_qcStrProbablyGood ...
   g_decArgo_qcStrChanged g_decArgo_qcStrInterpolated];
if (paramDataMode(1) == 'R')
   idDel = find(~ismember(paramDataQc(:, 1), qcToKeepList));
else
   idDel = find(~ismember(paramDataAdjustedQc(:, 1), qcToKeepList));
end
paramData(idDel, :) = [];
paramDataQc(idDel, :) = [];
paramDataAdjusted(idDel, :) = [];
paramDataAdjustedQc(idDel, :) = [];
paramDataAdjustedError(idDel, :) = [];

% sort PRES levels in ascending order
if (paramDataMode(1) == 'R')
   [~ , idSort] = sort(paramData(:, 1));
else
   [~ , idSort] = sort(paramDataAdjusted(:, 1));
end
paramData = paramData(idSort, :);
paramDataQc = paramDataQc(idSort, :);
paramDataAdjusted = paramDataAdjusted(idSort, :);
paramDataAdjustedQc = paramDataAdjustedQc(idSort, :);
paramDataAdjustedError = paramDataAdjustedError(idSort, :);

if (g_cocm_printCsv)
   print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
      presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
      paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step2');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #2bis: add time of profile levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_trajData))
   if (o_mergedProfData.direction == 'A')
      profMeasCodeList = g_MC_AscProf;
   else
      profMeasCodeList = g_MC_DescProf;
   end
   if (~isempty(a_metaData))
      if (strcmp(a_metaData.dataCentre, 'IF') && strcmp(a_metaData.platformType, 'NAVIS_A'))
         % for NAVIS floats near surface measurements are stored in the PROF and
         % in the TRAJ files
         profMeasCodeList = [profMeasCodeList g_MC_InWaterSeriesOfMeasPartOfEndOfProfileRelativeToTST];
      end
   end
   
   idMeas = find( ...
      (a_trajData.cycleNumber == o_mergedProfData.cycleNumber) & ...
      (ismember(a_trajData.measurementCode, profMeasCodeList)));
   if (~isempty(idMeas))
      
      juld = repmat(paramJuldFillValue, size(paramData, 1), 1);
      juldQc = repmat(g_decArgo_qcStrMissing, size(juld));
      juldAdjusted = repmat(paramJuldFillValue, size(paramData, 1), 1);
      juldAdjustedQc = repmat(g_decArgo_qcStrMissing, size(juld));
      
      % search the level (in the profile) of each TRAJ measurement
      
      trajParamList = a_trajData.paramList;
      if (length(trajParamList) == length(paramList))
         trajParamId = [];
         for idParam = 1:length(paramList)
            paramName = paramList{idParam};
            idF = find(strcmp(paramName, trajParamList));
            if (~isempty(idF))
               trajParamId = [trajParamId idF];
            else
               fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' parameter not found in TRAJ file - cannot add time on profile levels\n', ...
                  g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramName);
               trajParamId = [];
               break
            end
         end
         if (~isempty(trajParamId))
            trajParamData = a_trajData.paramData(idMeas, :);
            for idL = 1:size(paramData, 1)
               idF = find(paramData(idL, 1) == trajParamData(:, trajParamId(1))); % much more efficient to select, in a first step, only the data of same PRES
               if (~isempty(idF))
                  idLev = [];
                  for idM = 1:length(idF)
                     if (~any(paramData(idL, :) ~= trajParamData(idF(idM), trajParamId)))
                        idLev = idF(idM);
                        break
                     end
                  end
                  if (~isempty(idLev))
                     juld(idL) = a_trajData.juld(idMeas(idLev));
                     juldQc(idL) = a_trajData.juldQc(idMeas(idLev));
                     juldAdjusted(idL) = a_trajData.juldAdj(idMeas(idLev));
                     juldAdjustedQc(idL) = a_trajData.juldAdjQc(idMeas(idLev));
                  else
                     % some TRAJ measurements are not present in current profile
                     % data. They correspond to measurements sampled by a given
                     % sensor at a same PRES level. These PRES values have a
                     % QC = '4' set by the Test#8: "Pressure increasing test" and
                     % then have been cleared during step #2.
                     %                   fprintf('DEBUG: Float #%d Cycle #%d%c: TRAJ meas #%d not found in current profile data\n', ...
                     %                      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, idMeas(idM));
                  end
               end
            end
         end
      else
         fprintf('ERROR: Float #%d Cycle #%d%c: PROF and TRAJ files have not the same number of parameters - cannot add time on profile levels\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
      end
      
      if (any(juld ~= paramJuldFillValue))
         
         % if juld have associated to profile levels, store juld data mode
         cycleNumberId = find(a_trajData.cycleNumberIndex == o_mergedProfData.cycleNumber);
         juldDataMode = a_trajData.dataMode(cycleNumberId);
         
         if (g_cocm_printCsv)
            print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
               presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
               paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
               'step2bis');
         end
      end
   end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #3: align measurements on identical PRES/PRES_ADJUSTED levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (paramDataMode(1) == 'R')
   refParamData = paramData;
else
   refParamData = paramDataAdjusted;
end

if (length(refParamData(:, 1)) ~= length(unique(refParamData(:, 1))))
   
   % there are duplicate pressures
   paramMeasFillValue = paramFillValue(2:end);
   pres = refParamData(:, 1);
   uPres = unique(pres);
   [binPopulation, binNumber] = histc(pres, uPres);
   idSameP = find(binPopulation > 1);
   idDel = [];
   for idSP = 1:length(idSameP)
      
      levels = find(binNumber == idSameP(idSP));
      levRef = levels(1);
      
      dataRef = paramData(levRef, 2:end);
      dataQcRef = paramDataQc(levRef, 2:end);
      dataAdjustedRef = paramDataAdjusted(levRef, 2:end);
      dataAdjustedQcRef = paramDataAdjustedQc(levRef, 2:end);
      dataAdjustedErrorRef = paramDataAdjustedError(levRef, 2:end);
      
      for idL = 2:length(levels)
         
         dataLev = paramData(levels(idL), 2:end);
         dataQcLev = paramDataQc(levels(idL), 2:end);
         dataAdjustedLev = paramDataAdjusted(levels(idL), 2:end);
         dataAdjustedQcLev = paramDataAdjustedQc(levels(idL), 2:end);
         dataAdjustedErrorLev = paramDataAdjustedError(levels(idL), 2:end);
         
         idNoDef = find(dataLev ~= paramMeasFillValue);
         % align PARAM measurements
         if (~any(dataRef(idNoDef) ~= paramMeasFillValue(idNoDef)))
            dataRef(idNoDef) = dataLev(idNoDef);
            dataQcRef(idNoDef) = dataQcLev(idNoDef);
         else
            % should not happen because identical pressure levels have been
            % removed for each profiles (QC set to '4' with RTQC)
         end
         
         % align PARAM_ADJUSTED measurements
         if (~any(dataAdjustedRef(idNoDef) ~= paramMeasFillValue(idNoDef)))
            dataAdjustedRef(idNoDef) = dataAdjustedLev(idNoDef);
            dataAdjustedQcRef(idNoDef) = dataAdjustedQcLev(idNoDef);
            dataAdjustedErrorRef(idNoDef) = dataAdjustedErrorLev(idNoDef);
         else
            % should not happen because identical pressure levels have been
            % removed for each profiles (QC set to '4' with RTQC)
         end
      end
      idDel = [idDel; levels(2:end)];
      
      % assign aligned measurement to the first duplicated level
      paramData(levRef, 2:end) = dataRef;
      paramDataQc(levRef, 2:end) = dataQcRef;
      paramDataAdjusted(levRef, 2:end) = dataAdjustedRef;
      paramDataAdjustedQc(levRef, 2:end) = dataAdjustedQcRef;
      paramDataAdjustedError(levRef, 2:end) = dataAdjustedErrorRef;
      
      % align time levels
      if (~isempty(juldDataMode))
         idJuldNoDef = find(juld(levels) ~= paramJuldFillValue);
         if (~isempty(idJuldNoDef) && ~ismember(1, idJuldNoDef))
            juld(levRef) = juld(levels(idJuldNoDef(1)));
            juldQc(levRef) = juldQc(levels(idJuldNoDef(1)));
         end
         if (juldDataMode ~= 'R')
            if (~isempty(idJuldNoDef) && ~ismember(1, idJuldNoDef))
               juldAdjusted(levRef) = juldAdjusted(levels(idJuldNoDef(1)));
               juldAdjustedQc(levRef) = juldAdjustedQc(levels(idJuldNoDef(1)));
            end
         end
      end
   end
   
   % remove duplicated levels
   paramData(idDel, :) = [];
   paramDataQc(idDel, :) = [];
   paramDataAdjusted(idDel, :) = [];
   paramDataAdjustedQc(idDel, :) = [];
   paramDataAdjustedError(idDel, :) = [];
   if (~isempty(juldDataMode))
      juld(idDel) = [];
      juldQc(idDel) = [];
      juldAdjusted(idDel) = [];
      juldAdjustedQc(idDel) = [];
   end
end

if (g_cocm_printCsv)
   print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
      presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
      paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step3');
end

% update output structure
o_mergedProfData.juldLevDataMode = juldDataMode;
o_mergedProfData.juldLev = juld;
o_mergedProfData.juldLevQc = juldQc;
o_mergedProfData.juldLevAdjusted = juldAdjusted;
o_mergedProfData.juldLevAdjustedQc = juldAdjustedQc;

o_mergedProfData.paramList = paramList;
o_mergedProfData.paramDataMode = paramDataMode;

o_mergedProfData.paramData = paramData;
o_mergedProfData.paramDataQc = paramDataQc;
o_mergedProfData.paramDataAdjusted = paramDataAdjusted;
o_mergedProfData.paramDataAdjustedQc = paramDataAdjustedQc;
o_mergedProfData.paramDataAdjustedError = paramDataAdjustedError;

o_mergedProfData.scientificCalibEquation = scientificCalibEquation;
o_mergedProfData.scientificCalibCoefficient = scientificCalibCoefficient;
o_mergedProfData.scientificCalibComment = scientificCalibComment;
o_mergedProfData.scientificCalibDate = scientificCalibDate;

if (isempty(o_mergedProfData.paramData))
   
   fprintf('INFO: Float #%d Cycle #%d%c: no data remain after processing - no merged profile\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   o_mergedProfData = [];
end

return

% ------------------------------------------------------------------------------
% Get the dedicated structure to store merged profile information.
%
% SYNTAX :
%  [o_profDataStruct] = get_merged_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profDataStruct : merged profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataStruct] = get_merged_prof_data_init_struct

% output parameters initialization
o_profDataStruct = struct( ...
   'handbookVersion', '', ...
   'referenceDateTime', '', ...
   'platformNumber', '', ...
   'projectName', '', ...
   'piName', '', ...
   'cycleNumber', [], ...
   'direction', '', ...
   'dataCentre', '', ...
   'platformType', '', ...
   'floatSerialNo', '', ...
   'firmwareVersion', '', ...
   'wmoInstType', '', ...
   'juld', [], ...
   'juldResolution', [], ...
   'juldQc', '', ...
   'juldLocation', [], ...
   'juldLocationResolution', [], ...
   'latitude', [], ...
   'longitude', [], ...
   'positionQc', '', ...
   'positioningSystem', '', ...
   'configMissionNumber', [], ...
   ...
   'juldLevDataMode', '', ...
   'juldLev', [], ...
   'juldLevQc', '', ...
   'juldLevAdjusted', [], ...
   'juldLevAdjustedQc', '', ...
   ...
   'paramList', [], ...
   'paramDataMode', '', ...
   ...
   'paramData', [], ...
   'paramDataQc', '', ...
   'paramDataAdjusted', [], ...
   'paramDataAdjustedQc', '', ...
   'paramDataAdjustedError', [], ...
   ...
   'scientificCalibEquation', [], ...
   'scientificCalibCoefficient', [], ...
   'scientificCalibComment', [], ...
   'scientificCalibDate', [] ...
   );

return

% ------------------------------------------------------------------------------
% Print merged profile data in a CSV file.
%
% SYNTAX :
%  print_profile_in_csv(a_paramlist, a_paramDataMode, a_juldDataMode, ...
%    a_juld, a_juldQc, a_juldAdj, a_juldAdjQc, ...
%    a_paramData, a_paramDataQc, a_paramDataAdjusted, a_paramDataAdjustedQc, a_paramDataAdjustedError, ...
%    a_comment)
%
% INPUT PARAMETERS :
%   a_paramlist              : list of parameters
%   a_paramDataMode          : list of parameter data modes
%   a_juldDataMode           : data mode of JULD_LEVEL parameter
%   a_juld                   : JULD_LEVEL data
%   a_juldQc                 : JULD_LEVEL_QC data
%   a_juldAdj                : JULD_LEVEL_ADJUSTED data
%   a_juldAdjQc              : JULD_LEVEL_ADJUSTED_QC data
%   a_paramData              : PARAM data
%   a_paramDataQc            : PARAM_QC data
%   a_paramDataAdjusted      : PARAM_ADJUSTED data
%   a_paramDataAdjustedQc    : PARAM_ADJUSTED_QC data
%   a_paramDataAdjustedError : PARAM_ADJUSTED_QC data
%   a_comment                : comment to add to the CSV file name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_profile_in_csv(a_paramlist, a_paramDataMode, a_juldDataMode, ...
   a_presAxisFlagConfig, a_presAxisFlagAlgo, a_juld, a_juldQc, a_juldAdj, a_juldAdjQc, ...
   a_paramData, a_paramDataQc, a_paramDataAdjusted, a_paramDataAdjustedQc, a_paramDataAdjustedError, ...
   a_comment)

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;


% select the cycle to print
% if ~((g_cocm_floatNum == 6900889) && (g_cocm_cycleNum == 1) && isempty(g_cocm_cycleDir))
% if ~((g_cocm_cycleNum == 13) && isempty(g_cocm_cycleDir))
%    return
% end

dateStr = datestr(now, 'yyyymmddTHHMMSS');

% create CSV file to print profile data
outputFileName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\nc_create_merged_profile_' ...
   sprintf('%d_%03d%c', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir) '_' a_comment '_' dateStr '.csv'];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to create CSV output file: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, outputFileName);
   return
end

data = [];
header = 'PARAMETER';
format = '%s';
if (~isempty(a_presAxisFlagConfig))
   header = [header '; PRES from CONFIG; PRES from HB'];
   format = [format '; %d; %d'];
end
if (~isempty(a_juldDataMode))
   header = [header '; JULD; '];
   format = [format '; %s; %c'];
   if (a_juldDataMode ~= 'R')
      header = [header '; JULD_ADJUSTED; '];
      format = [format '; %s; %c'];
   end
end
for idParam = 1:length(a_paramlist)
   paramName = a_paramlist{idParam};
   header = [header '; ' paramName '; '];
   format = [format '; %g; %c'];
   data = [data a_paramData(:, idParam) single(a_paramDataQc(:, idParam))];
   if (a_paramDataMode(idParam) ~= 'R')
      header = [header '; ' paramName '_ADJUSTED; '];
      format = [format '; %g; %c'];
      data = [data a_paramDataAdjusted(:, idParam) single(a_paramDataAdjustedQc(:, idParam))];
      if (a_paramDataMode(idParam) ~= 'D')
         header = [header '; ' paramName '_ADJUSTED_ERROR'];
         format = [format '; %g'];
         data = [data a_paramDataAdjustedError(:, idParam)];
      end
   end
end
format = [format '\n'];

fprintf(fidOut,'%s\n', header);

for idLev = 1:size(a_paramData, 1)
   if (isempty(a_juldDataMode))
      if (~isempty(a_presAxisFlagConfig))
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], ...
            a_presAxisFlagConfig(idLev), a_presAxisFlagAlgo(idLev), ...
            data(idLev, :));
      else
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], ...
            data(idLev, :));
      end
   elseif (a_juldDataMode ~= 'R')
      if (~isempty(a_presAxisFlagConfig))
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], ...
            a_presAxisFlagConfig(idLev), a_presAxisFlagAlgo(idLev), ...
            julian_2_gregorian_dec_argo(a_juld(idLev)), a_juldQc(idLev), ...
            julian_2_gregorian_dec_argo(a_juldAdj(idLev)), a_juldAdjQc(idLev), ...
            data(idLev, :));
      else
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], ...
            julian_2_gregorian_dec_argo(a_juld(idLev)), a_juldQc(idLev), ...
            julian_2_gregorian_dec_argo(a_juldAdj(idLev)), a_juldAdjQc(idLev), ...
            data(idLev, :));
      end
   else
      fprintf(fidOut, format, ...
         ['MEAS#' num2str(idLev)], ...
         a_presAxisFlagConfig(idLev), a_presAxisFlagAlgo(idLev), ...
         julian_2_gregorian_dec_argo(a_juld(idLev)), a_juldQc(idLev), ...
         data(idLev, :));
   end
end

fclose(fidOut);

return

% ------------------------------------------------------------------------------
% Create merged mono-profile NetCDF file.
%
% SYNTAX :
%  create_merged_mono_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
%
% INPUT PARAMETERS :
%   a_floatWmo  : float WMO number
%   a_profData  : merged profile data
%   a_tmpDir    : temporary directory
%   a_outputDir : output directory
%   a_refFile   : merged profile reference file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_merged_mono_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)

% current float and cycle identification
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% generate NetCDF-4 flag
global g_cocm_netCDF4FlagForMonoProf;

% report information structure
global g_cocm_reportData;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% create the output file name
if (any(a_profData.paramDataMode == 'D'))
   modeCode = 'D';
else
   modeCode = 'R';
end
outputFileName = ['M' modeCode num2str(a_floatWmo) '_' sprintf('%03d%c', g_cocm_cycleNum, g_cocm_cycleDir) '.nc'];
outputFilePathName = [a_tmpDir '/' outputFileName];

% retrieve the merged profile file schema
outputFileSchema = ncinfo(a_refFile);

% compute file dimensions
nProfDim = 1;
nParamDim = size(a_profData.paramData, 2) + length(a_profData.juldLevDataMode);
nLevelsDim = size(a_profData.paramData, 1);
nCalibDim = 1;
for idParam = 1:length(a_profData.scientificCalibEquation)
   scientificCalibEquation = a_profData.scientificCalibEquation{idParam};
   nCalibDim = max(nCalibDim, length(scientificCalibEquation));
end
if (g_cocm_netCDF4FlagForMonoProf)
   % set the deflate level of the variables
   for idVar = 1:length(outputFileSchema.Variables)
      var = outputFileSchema.Variables(idVar);
      var.DeflateLevel = DEFLATE_LEVEL;
      var.Shuffle = SHUFFLE_FLAG;
      outputFileSchema.Variables(idVar) = var;
   end
end

% update the file schema with the new dimensions
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_PROF', nProfDim);
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_PARAM', nParamDim);
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_LEVELS', nLevelsDim);
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_CALIB', nCalibDim);

% create merged profile file
ncwriteschema(outputFilePathName, outputFileSchema);

% fill merged profile file
fill_merged_mono_profile_file(outputFilePathName, a_profData);

% update output file
move_file(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/profiles/' outputFileName]);

% report information structure
g_cocm_reportData.outputMMonoProfFile = [a_outputDir '/' num2str(a_floatWmo) '/profiles/' outputFileName];

return

% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}) == 1, 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;
   
   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      idDims = find(strcmp(a_dimName, {var.Dimensions.Name}) == 1);
      a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
      for idDim = 1:length(idDims)
         a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
      end
   end
end

o_outputSchema = a_inputSchema;

return

% ------------------------------------------------------------------------------
% Fill merged mono-profile NetCDF file.
%
% SYNTAX :
%  fill_merged_mono_profile_file(a_fileName, a_profData)
%
% INPUT PARAMETERS :
%   a_fileName : merged mono-profile NetCDF file path name
%   a_profData : merged profile data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function fill_merged_mono_profile_file(a_fileName, a_profData)

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocm_ncCreateMergedProfileVersion;

% generate NetCDF-4 flag
global g_cocm_netCDF4FlagForMonoProf;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to open NetCDF output file: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_fileName);
   return
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

netcdf.reDef(fCdf);

% fill global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
institution = get_institution_from_data_centre(a_profData.dataCentre, 0);
if (isempty(deblank(institution)))
   fprintf('WARNING: Float #%d Cycle #%d%c: No institution assigned to data centre %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_profData.dataCentre);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
netcdf.putAtt(fCdf, globalVarId, 'history', ...
   [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ...
   ' creation (software version ' g_cocm_ncCreateMergedProfileVersion ')']);
netcdf.putAtt(fCdf, globalVarId, 'software_version', g_cocm_ncCreateMergedProfileVersion);
netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '1.0');
netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');

% fill specific attributes
netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD'), 'resolution', a_profData.juldResolution);
netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), 'resolution', a_profData.juldLocationResolution);

% create parameter variables
nProfDimId = netcdf.inqDimID(fCdf, 'N_PROF');
nLevelsDimId = netcdf.inqDimID(fCdf, 'N_LEVELS');
paramList = a_profData.paramList;
if (~isempty(a_profData.juldLevDataMode))
   paramList = [{'JULD_LEVEL'} paramList];
end

% global quality of PARAM profile
for idParam = 1:length(paramList)
   paramName = paramList{idParam};
   profParamQcName = ['PROFILE_' paramName '_QC'];
   
   profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
   if (g_cocm_netCDF4FlagForMonoProf)
      netcdf.defVarDeflate(fCdf, profileParamQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
   end
   
   netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
   netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
   if (g_cocm_netCDF4FlagForMonoProf)
      netcdf.defVarFill(fCdf, profileParamQcVarId, false, ' ')
   else
      netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
   end
end

% PARAM profile
for idParam = 1:length(paramList)
   
   paramName = paramList{idParam};
   paramInfo = get_netcdf_param_attributes(paramName);
   
   % parameter variable and attributes
   if (~var_is_present_dec_argo(fCdf, paramName))
      
      paramVarId = netcdf.defVar(fCdf, paramName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
      if (g_cocm_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      if (~isempty(paramInfo.longName))
         netcdf.putAtt(fCdf, paramVarId, 'long_name', paramInfo.longName);
      end
      if (~isempty(paramInfo.standardName))
         netcdf.putAtt(fCdf, paramVarId, 'standard_name', paramInfo.standardName);
      end
      if (~isempty(paramInfo.fillValue))
         if (g_cocm_netCDF4FlagForMonoProf)
            netcdf.defVarFill(fCdf, paramVarId, false, paramInfo.fillValue)
         else
            netcdf.putAtt(fCdf, paramVarId, '_FillValue', paramInfo.fillValue);
         end
      end
      if (~isempty(paramInfo.units))
         netcdf.putAtt(fCdf, paramVarId, 'units', paramInfo.units);
      end
      if (~isempty(paramInfo.validMin))
         netcdf.putAtt(fCdf, paramVarId, 'valid_min', paramInfo.validMin);
      end
      if (~isempty(paramInfo.validMax))
         netcdf.putAtt(fCdf, paramVarId, 'valid_max', paramInfo.validMax);
      end
      if (~isempty(paramInfo.cFormat))
         netcdf.putAtt(fCdf, paramVarId, 'C_format', paramInfo.cFormat);
      end
      if (~isempty(paramInfo.fortranFormat))
         netcdf.putAtt(fCdf, paramVarId, 'FORTRAN_format', paramInfo.fortranFormat);
      end
      if (~isempty(paramInfo.resolution))
         netcdf.putAtt(fCdf, paramVarId, 'resolution', paramInfo.resolution);
      end
      if (~isempty(paramInfo.axis))
         netcdf.putAtt(fCdf, paramVarId, 'axis', paramInfo.axis);
      end
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramName);
   end
   
   % parameter QC variable and attributes
   paramQcName = [paramName '_QC'];
   if (~var_is_present_dec_argo(fCdf, paramQcName))
      
      paramQcVarId = netcdf.defVar(fCdf, paramQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
      if (g_cocm_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
      if (g_cocm_netCDF4FlagForMonoProf)
         netcdf.defVarFill(fCdf, paramQcVarId, false, ' ')
      else
         netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
      end
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramQcName);
   end
   
   % parameter adjusted variable and attributes
   paramAdjName = [paramName '_ADJUSTED'];
   if (~var_is_present_dec_argo(fCdf, paramAdjName))
      
      paramAdjVarId = netcdf.defVar(fCdf, paramAdjName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
      if (g_cocm_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramAdjVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      if (~isempty(paramInfo.longName))
         netcdf.putAtt(fCdf, paramAdjVarId, 'long_name', paramInfo.longName);
      end
      if (~isempty(paramInfo.standardName))
         netcdf.putAtt(fCdf, paramAdjVarId, 'standard_name', paramInfo.standardName);
      end
      if (~isempty(paramInfo.fillValue))
         if (g_cocm_netCDF4FlagForMonoProf)
            netcdf.defVarFill(fCdf, paramAdjVarId, false, paramInfo.fillValue)
         else
            netcdf.putAtt(fCdf, paramAdjVarId, '_FillValue', paramInfo.fillValue);
         end
      end
      if (~isempty(paramInfo.units))
         netcdf.putAtt(fCdf, paramAdjVarId, 'units', paramInfo.units);
      end
      if (~isempty(paramInfo.validMin))
         netcdf.putAtt(fCdf, paramAdjVarId, 'valid_min', paramInfo.validMin);
      end
      if (~isempty(paramInfo.validMax))
         netcdf.putAtt(fCdf, paramAdjVarId, 'valid_max', paramInfo.validMax);
      end
      if (~isempty(paramInfo.cFormat))
         netcdf.putAtt(fCdf, paramAdjVarId, 'C_format', paramInfo.cFormat);
      end
      if (~isempty(paramInfo.fortranFormat))
         netcdf.putAtt(fCdf, paramAdjVarId, 'FORTRAN_format', paramInfo.fortranFormat);
      end
      if (~isempty(paramInfo.resolution))
         netcdf.putAtt(fCdf, paramAdjVarId, 'resolution', paramInfo.resolution);
      end
      if (~isempty(paramInfo.axis))
         netcdf.putAtt(fCdf, paramAdjVarId, 'axis', paramInfo.axis);
      end
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramAdjName);
   end
   
   % parameter adjusted QC variable and attributes
   paramAdjQcName = [paramName '_ADJUSTED_QC'];
   if (~var_is_present_dec_argo(fCdf, paramAdjQcName))
      
      paramAdjQcVarId = netcdf.defVar(fCdf, paramAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
      if (g_cocm_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramAdjQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
      if (g_cocm_netCDF4FlagForMonoProf)
         netcdf.defVarFill(fCdf, paramAdjQcVarId, false, ' ')
      else
         netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
      end
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramAdjQcName);
   end
   
   % parameter adjusted error variable and attributes
   if ~(~isempty(a_profData.juldLevDataMode) && (idParam == 1)) % there is no JULD_LEVEL_ADJUSTED_ERROR
      paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
      if (~var_is_present_dec_argo(fCdf, paramAdjErrName))
         
         paramAdjErrVarId = netcdf.defVar(fCdf, paramAdjErrName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         if (g_cocm_netCDF4FlagForMonoProf)
            netcdf.defVarDeflate(fCdf, paramAdjErrVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, paramAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
         if (~isempty(paramInfo.fillValue))
            if (g_cocm_netCDF4FlagForMonoProf)
               netcdf.defVarFill(fCdf, paramAdjErrVarId, false, paramInfo.fillValue)
            else
               netcdf.putAtt(fCdf, paramAdjErrVarId, '_FillValue', paramInfo.fillValue);
            end
         end
         if (~isempty(paramInfo.units))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'units', paramInfo.units);
         end
         if (~isempty(paramInfo.cFormat))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'C_format', paramInfo.cFormat);
         end
         if (~isempty(paramInfo.fortranFormat))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'FORTRAN_format', paramInfo.fortranFormat);
         end
         if (~isempty(paramInfo.resolution))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'resolution', paramInfo.resolution);
         end
      else
         fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramAdjErrName);
      end
   end
end

netcdf.endDef(fCdf);

% fill misc variable data
valueStr = 'Argo merged profile version 2';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_TYPE'), 0, length(valueStr), valueStr);
valueStr = '1.0';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'), 0, length(valueStr), valueStr);
valueStr = a_profData.handbookVersion;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HANDBOOK_VERSION'), 0, length(valueStr), valueStr);
end
valueStr = a_profData.referenceDateTime;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'REFERENCE_DATE_TIME'), 0, length(valueStr), valueStr);
end
valueStr = currentDate;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'), 0, length(valueStr), valueStr);
end
valueStr = currentDate;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), 0, length(valueStr), valueStr);
end
valueStr = a_profData.platformNumber;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_NUMBER'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.projectName;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PROJECT_NAME'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.piName;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PI_NAME'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
stationParametersVarId = netcdf.inqVarID(fCdf, 'STATION_PARAMETERS');
for idParam = 1:length(paramList)
   valueStr = paramList{idParam};
   netcdf.putVar(fCdf, stationParametersVarId, ...
      fliplr([0 idParam-1 0]), fliplr([1 1 length(valueStr)]), valueStr');
end
value = a_profData.cycleNumber;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'), 0, length(value), value);
end
valueStr = a_profData.direction;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'), 0, length(valueStr), valueStr);
end
valueStr = a_profData.dataCentre;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_CENTRE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.paramDataMode;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER_DATA_MODE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.platformType;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_TYPE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.floatSerialNo;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FLOAT_SERIAL_NO'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.firmwareVersion;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FIRMWARE_VERSION'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
valueStr = a_profData.wmoInstType;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'WMO_INST_TYPE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
value = a_profData.juld;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'), 0, length(value), value);
end
valueStr = a_profData.juldQc;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), 0, length(valueStr), valueStr);
end
value = a_profData.juldLocation;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), 0, length(value), value);
end
value = a_profData.latitude;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), 0, length(value), value);
end
value = a_profData.longitude;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), 0, length(value), value);
end
valueStr = a_profData.positionQc;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), 0, length(valueStr), valueStr);
end
valueStr = a_profData.positioningSystem;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITIONING_SYSTEM'), [0 0], fliplr([1 length(valueStr)]), valueStr');
end
value = a_profData.configMissionNumber;
if (~isempty(valueStr))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER'), 0, length(value), value);
end

% fill PARAM variable data
for idParam = 1:length(paramList)
   
   if (~isempty(a_profData.juldLevDataMode))
      if (idParam == 1)
         paramData = a_profData.juldLev;
         paramDataQc = a_profData.juldLevQc;
         paramDataAdj = a_profData.juldLevAdjusted;
         paramDataAdjQc = a_profData.juldLevAdjustedQc;
      else
         paramData = a_profData.paramData(:, idParam-1);
         paramDataQc = a_profData.paramDataQc(:, idParam-1);
         paramDataAdj = a_profData.paramDataAdjusted(:, idParam-1);
         paramDataAdjQc = a_profData.paramDataAdjustedQc(:, idParam-1);
         paramDataAdjErr = a_profData.paramDataAdjustedError(:, idParam-1);
      end
   else
      paramData = a_profData.paramData(:, idParam);
      paramDataQc = a_profData.paramDataQc(:, idParam);
      paramDataAdj = a_profData.paramDataAdjusted(:, idParam);
      paramDataAdjQc = a_profData.paramDataAdjustedQc(:, idParam);
      paramDataAdjErr = a_profData.paramDataAdjustedError(:, idParam);
   end
   
   paramName = paramList{idParam};
   paramQcName = [paramName '_QC'];
   paramAdjName = [paramName '_ADJUSTED'];
   paramAdjQcName = [paramName '_ADJUSTED_QC'];
   paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
   
   % global quality of PARAM profile
   profParamQcData = compute_profile_quality_flag(paramDataQc);
   profParamQcName = ['PROFILE_' paramName '_QC'];
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), 0, 1, profParamQcData);
   
   % PARAM profile
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramName), fliplr([0 0]), fliplr([1 length(paramData)]), paramData);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), fliplr([0 0]), fliplr([1 length(paramData)]), paramDataQc);
   
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjName), fliplr([0 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjQcName), fliplr([0 0]), fliplr([1 length(paramDataAdj)]), paramDataAdjQc);
   if ~(~isempty(a_profData.juldLevDataMode) && (idParam == 1)) % there is no JULD_LEVEL_ADJUSTED_ERROR
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjErrName), fliplr([0 0]), fliplr([1 length(paramDataAdjErr)]), paramDataAdjErr);
   end
end

% fill SCIENTIFIC_CALIB_* variable data
[~, nCalibDim] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_CALIB'));
parameterVarId = netcdf.inqVarID(fCdf, 'PARAMETER');
scientificCalibEquationVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_EQUATION');
scientificCalibCoefficientVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT');
scientificCalibCommentVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT');
scientificCalibDateVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE');
for idParam = 1:length(paramList)
   
   paramName = paramList{idParam};
   if (~isempty(a_profData.juldLevDataMode))
      if (idParam == 1)
         scientificCalibEquation = [];
         scientificCalibCoefficient = [];
         scientificCalibComment = [];
         scientificCalibDate = [];
      else
         scientificCalibEquation = a_profData.scientificCalibEquation{idParam-1};
         scientificCalibCoefficient = a_profData.scientificCalibCoefficient{idParam-1};
         scientificCalibComment = a_profData.scientificCalibComment{idParam-1};
         scientificCalibDate = a_profData.scientificCalibDate{idParam-1};
      end
   else
      scientificCalibEquation = a_profData.scientificCalibEquation{idParam};
      scientificCalibCoefficient = a_profData.scientificCalibCoefficient{idParam};
      scientificCalibComment = a_profData.scientificCalibComment{idParam};
      scientificCalibDate = a_profData.scientificCalibDate{idParam};
   end
   
   for idCalib = 1:nCalibDim
      netcdf.putVar(fCdf, parameterVarId, ...
         fliplr([0 idCalib-1 idParam-1 0]), fliplr([1 1 1 length(paramName)]), paramName');
   end
   for idCalib = 1:length(scientificCalibEquation)
      valueStr = scientificCalibEquation{idCalib};
      if (~isempty(valueStr))
         netcdf.putVar(fCdf, scientificCalibEquationVarId, ...
            fliplr([0 idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
      end
      valueStr = scientificCalibCoefficient{idCalib};
      if (~isempty(valueStr))
         netcdf.putVar(fCdf, scientificCalibCoefficientVarId, ...
            fliplr([0 idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
      end
      valueStr = scientificCalibComment{idCalib};
      if (~isempty(valueStr))
         netcdf.putVar(fCdf, scientificCalibCommentVarId, ...
            fliplr([0 idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
      end
      valueStr = scientificCalibDate{idCalib};
      if (~isempty(valueStr))
         netcdf.putVar(fCdf, scientificCalibDateVarId, ...
            fliplr([0 idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
      end
   end
end

% close NetCDF file
netcdf.close(fCdf);

return

% ------------------------------------------------------------------------------
% Store data from all existing M-PROF files and a given directory in a dedicated
% structure.
%
% SYNTAX :
%  [o_mergedProfAllData] = get_all_merged_prof_data(a_outputDir)
%
% INPUT PARAMETERS :
%   a_outputDir : directory of expected M-PROF files to load
%
% OUTPUT PARAMETERS :
%   o_mergedProfAllData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mergedProfAllData] = get_all_merged_prof_data(a_outputDir)

% output parameter initialization
o_mergedProfAllData = [];

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;


floatWmoStr = num2str(g_cocm_floatNum);

% create the list of available cycle numbers for M-PROF files
files = dir([a_outputDir '/' floatWmoStr '/profiles/' 'M*' floatWmoStr '_' '*.nc']);
cyNumList = [];
for idFile = 1:length(files)
   fileName = files(idFile).name;
   idF = strfind(fileName, floatWmoStr);
   cyNumStr = fileName(idF+length(floatWmoStr)+1:end-3);
   if (cyNumStr(end) == 'D')
      cyNumStr(end) = [];
   end
   cyNumList = [cyNumList str2num(cyNumStr)];
end
cyNumList = unique(cyNumList);

% retrieve M-PROF files data
for idCy = 1:length(cyNumList)
   
   g_cocm_cycleNum = cyNumList(idCy);
   
   % process descending and ascending profiles
   for idDir = 1:2
      
      if (idDir == 1)
         g_cocm_cycleDir = 'D';
      else
         g_cocm_cycleDir = '';
      end
      
      mProfFileName = '';
      if (exist([a_outputDir '/' floatWmoStr '/profiles/' sprintf('MD%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)], 'file') == 2)
         mProfFileName = [a_outputDir '/' floatWmoStr '/profiles/' sprintf('MD%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)];
      elseif (exist([a_outputDir '/' floatWmoStr '/profiles/' sprintf('MR%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)], 'file') == 2)
         mProfFileName = [a_outputDir '/' floatWmoStr '/profiles/' sprintf('MR%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)];
      end
      
      if (~isempty(mProfFileName))
         
         % retrieve M-PROF file data
         mergedProfDataStruct = get_merged_prof_data(mProfFileName);
         
         if (~isempty(mergedProfDataStruct))
            o_mergedProfAllData = [o_mergedProfAllData mergedProfDataStruct];
         end
      end
   end
end

% uniformize N_CALIB dimension between M-PROF file data
if (~isempty(o_mergedProfAllData))
   o_mergedProfAllData = uniformize_n_calib_dimension(o_mergedProfAllData);
end

return

% ------------------------------------------------------------------------------
% Store data from one M-PROF file in a dedicated structure.
%
% SYNTAX :
%  [o_mergedProfData] = get_merged_prof_data(a_mProfFileName)
%
% INPUT PARAMETERS :
%   a_mProfFileName : M-PROF file path name
%
% OUTPUT PARAMETERS :
%   o_mergedProfData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mergedProfData] = get_merged_prof_data(a_mProfFileName)

% output parameter initialization
o_mergedProfData = [];

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;


if ~(exist(a_mProfFileName, 'file') == 2)
   fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_mProfFileName);
   return
end

% retrieve information from M-PROF file
wantedVars = [ ...
   {'STATION_PARAMETERS'} ...
   ];
[profData1] = get_data_from_nc_file(a_mProfFileName, wantedVars);

stationParameters = get_data_from_name('STATION_PARAMETERS', profData1);

% create the list of parameters to be retrieved from M-PROF file
wantedVars = [ ...
   {'HANDBOOK_VERSION'} ...
   {'REFERENCE_DATE_TIME'} ...
   ...
   {'PLATFORM_NUMBER'} ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'CYCLE_NUMBER'} ...
   {'DIRECTION'} ...
   {'DATA_CENTRE'} ...
   {'PARAMETER_DATA_MODE'} ...
   {'PLATFORM_TYPE'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'FIRMWARE_VERSION'} ...
   {'WMO_INST_TYPE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'POSITIONING_SYSTEM'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'PARAMETER'} ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'SCIENTIFIC_CALIB_DATE'} ...
   ];

% add parameter measurements
profParameterList = [];
[~, nParam, nProf] = size(stationParameters);
for idProf = 1:nProf
   profParamList = [];
   for idParam = 1:nParam
      paramName = deblank(stationParameters(:, idParam, idProf)');
      if (~isempty(paramName))
         profParamList{end+1} = paramName;
         wantedVars = [wantedVars ...
            {paramName} ...
            {[paramName '_QC']} ...
            {[paramName '_ADJUSTED']} ...
            {[paramName '_ADJUSTED_QC']} ...
            {[paramName '_ADJUSTED_ERROR']} ...
            ];
      end
   end
   profParameterList = [profParameterList; {profParamList}];
end

% retrieve information from M-PROF file
[profData2] = get_data_from_nc_file(a_mProfFileName, wantedVars);

% retrieve information from PROF file
wantedVarAtts = [ ...
   {'JULD'} {'resolution'} ...
   {'JULD_LOCATION'} {'resolution'} ...
   ];

[profDataAtt] = get_att_from_nc_file(a_mProfFileName, wantedVarAtts);

% fill merged profile structure
o_mergedProfData = get_merged_prof_data_init_struct;

o_mergedProfData.handbookVersion = get_data_from_name('HANDBOOK_VERSION', profData2)';
o_mergedProfData.referenceDateTime = get_data_from_name('REFERENCE_DATE_TIME', profData2)';
o_mergedProfData.platformNumber = get_data_from_name('PLATFORM_NUMBER', profData2)';
o_mergedProfData.projectName = get_data_from_name('PROJECT_NAME', profData2)';
o_mergedProfData.piName = get_data_from_name('PI_NAME', profData2)';
o_mergedProfData.cycleNumber = get_data_from_name('CYCLE_NUMBER', profData2)';
o_mergedProfData.direction = get_data_from_name('DIRECTION', profData2)';
o_mergedProfData.dataCentre = get_data_from_name('DATA_CENTRE', profData2)';
o_mergedProfData.platformType = get_data_from_name('PLATFORM_TYPE', profData2)';
o_mergedProfData.floatSerialNo = get_data_from_name('FLOAT_SERIAL_NO', profData2)';
o_mergedProfData.firmwareVersion = get_data_from_name('FIRMWARE_VERSION', profData2)';
o_mergedProfData.wmoInstType = get_data_from_name('WMO_INST_TYPE', profData2)';
o_mergedProfData.juld = get_data_from_name('JULD', profData2)';
o_mergedProfData.juldResolution = get_att_from_name('JULD', 'resolution', profDataAtt);
o_mergedProfData.juldQc = get_data_from_name('JULD_QC', profData2)';
o_mergedProfData.juldLocation = get_data_from_name('JULD_LOCATION', profData2)';
o_mergedProfData.juldLocationResolution = get_att_from_name('JULD_LOCATION', 'resolution', profDataAtt);
o_mergedProfData.latitude = get_data_from_name('LATITUDE', profData2)';
o_mergedProfData.longitude = get_data_from_name('LONGITUDE', profData2)';
o_mergedProfData.positionQc = get_data_from_name('POSITION_QC', profData2)';
o_mergedProfData.positioningSystem = get_data_from_name('POSITIONING_SYSTEM', profData2)';
o_mergedProfData.configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', profData2)';

parameterDataMode = get_data_from_name('PARAMETER_DATA_MODE', profData2)';
parameter = get_data_from_name('PARAMETER', profData2);
[~, ~, nCalib, ~] = size(parameter);
scientificCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', profData2);
scientificCalibCoefficient = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', profData2);
scientificCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', profData2);
scientificCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', profData2);

offset = 0;
for idProf = 1:nProf
   profParamList = profParameterList{idProf, :};
   for idParam = 1:length(profParamList)
      paramName = profParamList{idParam};
      paramData = get_data_from_name(paramName, profData2)';
      paramDataQc = get_data_from_name([paramName '_QC'], profData2)';
      paramDataAdjusted = get_data_from_name([paramName '_ADJUSTED'], profData2)';
      paramDataAdjustedQc = get_data_from_name([paramName '_ADJUSTED_QC'], profData2)';
      paramDataAdjustedError = get_data_from_name([paramName '_ADJUSTED_ERROR'], profData2)';
      
      if (strcmp(paramName, 'JULD_LEVEL'))
         
         o_mergedProfData.juldLevDataMode = parameterDataMode(idProf, idParam);
         
         o_mergedProfData.juldLev = paramData(idProf, :)';
         o_mergedProfData.juldLevQc = paramDataQc(idProf, :)';
         o_mergedProfData.juldLevAdjusted = paramDataAdjusted(idProf, :)';
         o_mergedProfData.juldLevAdjustedQc = paramDataAdjustedQc(idProf, :)';
         offset = -1;
      else
         
         o_mergedProfData.paramList = [o_mergedProfData.paramList {paramName}];
         o_mergedProfData.paramDataMode = [o_mergedProfData.paramDataMode parameterDataMode(idProf, idParam)];
         
         o_mergedProfData.paramData = [o_mergedProfData.paramData paramData(idProf, :)'];
         o_mergedProfData.paramDataQc = [o_mergedProfData.paramDataQc paramDataQc(idProf, :)'];
         o_mergedProfData.paramDataAdjusted = [o_mergedProfData.paramDataAdjusted paramDataAdjusted(idProf, :)'];
         o_mergedProfData.paramDataAdjustedQc = [o_mergedProfData.paramDataAdjustedQc paramDataAdjustedQc(idProf, :)'];
         o_mergedProfData.paramDataAdjustedError = [o_mergedProfData.paramDataAdjustedError paramDataAdjustedError(idProf, :)'];
         
         % find N_PARAM index of the current parameter
         scientificCalibEquationTab = '';
         scientificCalibCoefficientTab = '';
         scientificCalibCommentTab = '';
         scientificCalibDateTab = '';
         nParamId = [];
         for idCalib = 1:nCalib
            for idParamNc = 1:nParam
               calibParamName = deblank(parameter(:, idParamNc, idCalib, idProf)');
               if (~isempty(calibParamName))
                  if (strcmp(paramName, calibParamName))
                     nParamId = idParamNc;
                     break
                  end
               end
            end
            if (~isempty(nParamId))
               break
            end
         end
         if (~isempty(nParamId))
            for idCalib2 = 1:nCalib
               scientificCalibEquationTab{end+1} = deblank(scientificCalibEquation(:, nParamId, idCalib2, idProf)');
               scientificCalibCoefficientTab{end+1} = deblank(scientificCalibCoefficient(:, nParamId, idCalib2, idProf)');
               scientificCalibCommentTab{end+1} = deblank(scientificCalibComment(:, nParamId, idCalib2, idProf)');
               scientificCalibDateTab{end+1} = deblank(scientificCalibDate(:, nParamId, idCalib2, idProf)');
            end
         end
         o_mergedProfData.scientificCalibEquation{idParam+offset} = scientificCalibEquationTab;
         o_mergedProfData.scientificCalibCoefficient{idParam+offset} = scientificCalibCoefficientTab;
         o_mergedProfData.scientificCalibComment{idParam+offset} = scientificCalibCommentTab;
         o_mergedProfData.scientificCalibDate{idParam+offset} = scientificCalibDateTab;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Uniformize the N_CALIB dimension between the profile structures.
%
% SYNTAX :
%  [o_mergedProfAllData] = uniformize_n_calib_dimension(a_mergedProfAllData)
%
% INPUT PARAMETERS :
%   a_mergedProfAllData : input profile data structure
%
% OUTPUT PARAMETERS :
%   o_mergedProfAllData : output profile data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mergedProfAllData] = uniformize_n_calib_dimension(a_mergedProfAllData)

% output parameter initialization
o_mergedProfAllData = a_mergedProfAllData;


% compute final N_CALB dimension
nCalibDim = 0;
for idProf = 1:length(o_mergedProfAllData)
   if (~isempty(o_mergedProfAllData(idProf).scientificCalibEquation))
      nCalibDim = max(nCalibDim, length(o_mergedProfAllData(idProf).scientificCalibEquation{1}));
   end
end

% update data
for idProf = 1:length(o_mergedProfAllData)
   nCalibProf = 0;
   if (~isempty(o_mergedProfAllData(idProf).scientificCalibEquation))
      nCalibProf = length(o_mergedProfAllData(idProf).scientificCalibEquation{1});
   end
   if (nCalibProf < nCalibDim)
      for idParam = 1:length(o_mergedProfAllData(idProf).scientificCalibEquation)
         o_mergedProfAllData(idProf).scientificCalibEquation{idParam} = ...
            cat(2, o_mergedProfAllData(idProf).scientificCalibEquation{idParam}, cell(1, nCalibDim-nCalibProf));
         o_mergedProfAllData(idProf).scientificCalibCoefficient{idParam} = ...
            cat(2, o_mergedProfAllData(idProf).scientificCalibCoefficient{idParam}, cell(1, nCalibDim-nCalibProf));
         o_mergedProfAllData(idProf).scientificCalibComment{idParam} = ...
            cat(2, o_mergedProfAllData(idProf).scientificCalibComment{idParam}, cell(1, nCalibDim-nCalibProf));
         o_mergedProfAllData(idProf).scientificCalibDate{idParam} = ...
            cat(2, o_mergedProfAllData(idProf).scientificCalibDate{idParam}, cell(1, nCalibDim-nCalibProf));
      end
   end
end

return

% ------------------------------------------------------------------------------
% Create merged multi-profile NetCDF file.
%
% SYNTAX :
%  create_merged_multi_profiles_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
%
% INPUT PARAMETERS :
%   a_floatWmo  : float WMO number
%   a_profData  : merged profile data
%   a_tmpDir    : temporary directory
%   a_outputDir : output directory
%   a_refFile   : merged profile reference file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_merged_multi_profiles_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)

% generate NetCDF-4 flag
global g_cocm_netCDF4FlagForMultiProf;

% report information structure
global g_cocm_reportData;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% create the output file name
outputFileName = [num2str(a_floatWmo) '_Mprof.nc'];
outputFilePathName = [a_tmpDir '/' outputFileName];

% retrieve the merged profile file schema
outputFileSchema = ncinfo(a_refFile);
if (g_cocm_netCDF4FlagForMultiProf)
   % set the deflate level of the variables
   for idVar = 1:length(outputFileSchema.Variables)
      var = outputFileSchema.Variables(idVar);
      var.DeflateLevel = DEFLATE_LEVEL;
      var.Shuffle = SHUFFLE_FLAG;
      outputFileSchema.Variables(idVar) = var;
   end
end

% compute file dimensions
nProfDim = length(a_profData);
nParamDim = 0;
nLevelsDim = 0;
nCalibDim = 0;
for idProf = 1:length(a_profData)
   profData = a_profData(idProf);
   nParamDim = max( nParamDim, ...
      size(profData.paramData, 2) + length(profData.juldLevDataMode));
   nLevelsDim = max(nLevelsDim, size(profData.paramData, 1));
   for idParam = 1:length(profData.scientificCalibEquation)
      nCalibDim = max(nCalibDim, length(profData.scientificCalibEquation{idParam}));
   end
end

% update the file schema with the new dimensions
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_PROF', nProfDim);
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_PARAM', nParamDim);
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_LEVELS', nLevelsDim);
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_CALIB', nCalibDim);

% create merged profile file
ncwriteschema(outputFilePathName, outputFileSchema);

% fill merged profile file
fill_merged_multi_profiles_file(outputFilePathName, a_profData);

% update output file
move_file(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/' outputFileName]);

% report information structure
g_cocm_reportData.outputMMultiProfFile = [a_outputDir '/' num2str(a_floatWmo) '/' outputFileName];

return

% ------------------------------------------------------------------------------
% Fill merged multi-profile NetCDF file.
%
% SYNTAX :
%  fill_merged_multi_profiles_file(a_fileName, a_profData)
%
% INPUT PARAMETERS :
%   a_fileName : merged multi-profile NetCDF file path name
%   a_profData : merged profile data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function fill_merged_multi_profiles_file(a_fileName, a_profData)

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocm_ncCreateMergedProfileVersion;

% generate NetCDF-4 flag
global g_cocm_netCDF4FlagForMultiProf;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to open NetCDF output file: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_fileName);
   return
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

netcdf.reDef(fCdf);

% fill global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
institution = get_institution_from_data_centre(a_profData(1).dataCentre, 0);
if (isempty(deblank(institution)))
   fprintf('WARNING: Float #%d Cycle #%d%c: No institution assigned to data centre %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_profData(1).dataCentre);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
netcdf.putAtt(fCdf, globalVarId, 'history', ...
   [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ...
   ' creation (software version ' g_cocm_ncCreateMergedProfileVersion ')']);
netcdf.putAtt(fCdf, globalVarId, 'software_version', g_cocm_ncCreateMergedProfileVersion);
netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '1.0');
netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');

% fill specific attributes
netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD'), 'resolution', a_profData(1).juldResolution);
netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), 'resolution', a_profData(1).juldLocationResolution);

% create parameter variables
nProfDimId = netcdf.inqDimID(fCdf, 'N_PROF');
nLevelsDimId = netcdf.inqDimID(fCdf, 'N_LEVELS');
for idProf = 1:length(a_profData)
   
   profData = a_profData(idProf);
   paramList = profData.paramList;
   if (~isempty(profData.juldLevDataMode))
      paramList = [{'JULD_LEVEL'} paramList];
   end
   
   % global quality of PARAM profile
   for idParam = 1:length(paramList)
      paramName = paramList{idParam};
      profParamQcName = ['PROFILE_' paramName '_QC'];
      
      if (~var_is_present_dec_argo(fCdf, profParamQcName))
         profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, profileParamQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
         netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarFill(fCdf, profileParamQcVarId, false, ' ')
         else
            netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
         end
      end
   end
   
   % PARAM profile
   for idParam = 1:length(paramList)
      
      paramName = paramList{idParam};
      paramInfo = get_netcdf_param_attributes(paramName);
      
      % parameter variable and attributes
      if (~var_is_present_dec_argo(fCdf, paramName))
         
         paramVarId = netcdf.defVar(fCdf, paramName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         if (~isempty(paramInfo.longName))
            netcdf.putAtt(fCdf, paramVarId, 'long_name', paramInfo.longName);
         end
         if (~isempty(paramInfo.standardName))
            netcdf.putAtt(fCdf, paramVarId, 'standard_name', paramInfo.standardName);
         end
         if (~isempty(paramInfo.fillValue))
            if (g_cocm_netCDF4FlagForMultiProf)
               netcdf.defVarFill(fCdf, paramVarId, false, paramInfo.fillValue)
            else
               netcdf.putAtt(fCdf, paramVarId, '_FillValue', paramInfo.fillValue);
            end
         end
         if (~isempty(paramInfo.units))
            netcdf.putAtt(fCdf, paramVarId, 'units', paramInfo.units);
         end
         if (~isempty(paramInfo.validMin))
            netcdf.putAtt(fCdf, paramVarId, 'valid_min', paramInfo.validMin);
         end
         if (~isempty(paramInfo.validMax))
            netcdf.putAtt(fCdf, paramVarId, 'valid_max', paramInfo.validMax);
         end
         if (~isempty(paramInfo.cFormat))
            netcdf.putAtt(fCdf, paramVarId, 'C_format', paramInfo.cFormat);
         end
         if (~isempty(paramInfo.fortranFormat))
            netcdf.putAtt(fCdf, paramVarId, 'FORTRAN_format', paramInfo.fortranFormat);
         end
         if (~isempty(paramInfo.resolution))
            netcdf.putAtt(fCdf, paramVarId, 'resolution', paramInfo.resolution);
         end
         if (~isempty(paramInfo.axis))
            netcdf.putAtt(fCdf, paramVarId, 'axis', paramInfo.axis);
         end
      end
      
      % parameter QC variable and attributes
      paramQcName = [paramName '_QC'];
      if (~var_is_present_dec_argo(fCdf, paramQcName))
         
         paramQcVarId = netcdf.defVar(fCdf, paramQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarFill(fCdf, paramQcVarId, false, ' ')
         else
            netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
         end
      end
      
      % parameter adjusted variable and attributes
      paramAdjName = [paramName '_ADJUSTED'];
      if (~var_is_present_dec_argo(fCdf, paramAdjName))
         
         paramAdjVarId = netcdf.defVar(fCdf, paramAdjName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramAdjVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         if (~isempty(paramInfo.longName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'long_name', paramInfo.longName);
         end
         if (~isempty(paramInfo.standardName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'standard_name', paramInfo.standardName);
         end
         if (~isempty(paramInfo.fillValue))
            if (g_cocm_netCDF4FlagForMultiProf)
               netcdf.defVarFill(fCdf, paramAdjVarId, false, paramInfo.fillValue)
            else
               netcdf.putAtt(fCdf, paramAdjVarId, '_FillValue', paramInfo.fillValue);
            end
         end
         if (~isempty(paramInfo.units))
            netcdf.putAtt(fCdf, paramAdjVarId, 'units', paramInfo.units);
         end
         if (~isempty(paramInfo.validMin))
            netcdf.putAtt(fCdf, paramAdjVarId, 'valid_min', paramInfo.validMin);
         end
         if (~isempty(paramInfo.validMax))
            netcdf.putAtt(fCdf, paramAdjVarId, 'valid_max', paramInfo.validMax);
         end
         if (~isempty(paramInfo.cFormat))
            netcdf.putAtt(fCdf, paramAdjVarId, 'C_format', paramInfo.cFormat);
         end
         if (~isempty(paramInfo.fortranFormat))
            netcdf.putAtt(fCdf, paramAdjVarId, 'FORTRAN_format', paramInfo.fortranFormat);
         end
         if (~isempty(paramInfo.resolution))
            netcdf.putAtt(fCdf, paramAdjVarId, 'resolution', paramInfo.resolution);
         end
         if (~isempty(paramInfo.axis))
            netcdf.putAtt(fCdf, paramAdjVarId, 'axis', paramInfo.axis);
         end
      end
      
      % parameter adjusted QC variable and attributes
      paramAdjQcName = [paramName '_ADJUSTED_QC'];
      if (~var_is_present_dec_argo(fCdf, paramAdjQcName))
         
         paramAdjQcVarId = netcdf.defVar(fCdf, paramAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramAdjQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
         if (g_cocm_netCDF4FlagForMultiProf)
            netcdf.defVarFill(fCdf, paramAdjQcVarId, false, ' ')
         else
            netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
         end
               end
      
      % parameter adjusted error variable and attributes
      if ~(~isempty(profData.juldLevDataMode) && (idParam == 1)) % there is no JULD_LEVEL_ADJUSTED_ERROR
         paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
         if (~var_is_present_dec_argo(fCdf, paramAdjErrName))
            
            paramAdjErrVarId = netcdf.defVar(fCdf, paramAdjErrName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
            if (g_cocm_netCDF4FlagForMultiProf)
               netcdf.defVarDeflate(fCdf, paramAdjErrVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
            end
            
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
            if (~isempty(paramInfo.fillValue))
               if (g_cocm_netCDF4FlagForMultiProf)
                  netcdf.defVarFill(fCdf, paramAdjErrVarId, false, paramInfo.fillValue)
               else
                  netcdf.putAtt(fCdf, paramAdjErrVarId, '_FillValue', paramInfo.fillValue);
               end
            end
            if (~isempty(paramInfo.units))
               netcdf.putAtt(fCdf, paramAdjErrVarId, 'units', paramInfo.units);
            end
            if (~isempty(paramInfo.cFormat))
               netcdf.putAtt(fCdf, paramAdjErrVarId, 'C_format', paramInfo.cFormat);
            end
            if (~isempty(paramInfo.fortranFormat))
               netcdf.putAtt(fCdf, paramAdjErrVarId, 'FORTRAN_format', paramInfo.fortranFormat);
            end
            if (~isempty(paramInfo.resolution))
               netcdf.putAtt(fCdf, paramAdjErrVarId, 'resolution', paramInfo.resolution);
            end
         end
      end
   end
end

netcdf.endDef(fCdf);

% fill misc variable data
valueStr = 'Argo merged profile version 2';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_TYPE'), 0, length(valueStr), valueStr);
valueStr = '1.0';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'), 0, length(valueStr), valueStr);
valueStr = a_profData.handbookVersion;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HANDBOOK_VERSION'), 0, length(valueStr), valueStr);
valueStr = a_profData.referenceDateTime;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'REFERENCE_DATE_TIME'), 0, length(valueStr), valueStr);
valueStr = currentDate;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'), 0, length(valueStr), valueStr);
valueStr = currentDate;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), 0, length(valueStr), valueStr);

for idProf = 1:length(a_profData)
   
   profData = a_profData(idProf);
   profPos = idProf-1;
   paramList = profData.paramList;
   if (~isempty(profData.juldLevDataMode))
      paramList = [{'JULD_LEVEL'} paramList];
   end
   
   valueStr = profData.platformNumber;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_NUMBER'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = profData.projectName;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PROJECT_NAME'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = profData.piName;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PI_NAME'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   stationParametersVarId = netcdf.inqVarID(fCdf, 'STATION_PARAMETERS');
   for idParam = 1:length(paramList)
      valueStr = paramList{idParam};
      netcdf.putVar(fCdf, stationParametersVarId, ...
         fliplr([profPos idParam-1 0]), fliplr([1 1 length(valueStr)]), valueStr');
   end
   value = profData.cycleNumber;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'), profPos, length(value), value);
   valueStr = profData.direction;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'), profPos, length(valueStr), valueStr);
   valueStr = profData.dataCentre;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_CENTRE'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = [profData.juldLevDataMode profData.paramDataMode];
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER_DATA_MODE'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = profData.platformType;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_TYPE'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = profData.floatSerialNo;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FLOAT_SERIAL_NO'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = profData.firmwareVersion;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FIRMWARE_VERSION'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   valueStr = profData.wmoInstType;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'WMO_INST_TYPE'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   value = profData.juld;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'), profPos, length(value), value);
   valueStr = profData.juldQc;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), profPos, length(valueStr), valueStr);
   value = profData.juldLocation;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), profPos, length(value), value);
   value = profData.latitude;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), profPos, length(value), value);
   value = profData.longitude;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), profPos, length(value), value);
   valueStr = profData.positionQc;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), profPos, length(valueStr), valueStr);
   valueStr = profData.positioningSystem;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITIONING_SYSTEM'), fliplr([profPos 0]), fliplr([1 length(valueStr)]), valueStr');
   value = profData.configMissionNumber;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER'), profPos, length(value), value);
   
   % fill PARAM variable data
   for idParam = 1:length(paramList)
      
      if (~isempty(profData.juldLevDataMode))
         if (idParam == 1)
            paramData = profData.juldLev;
            paramDataQc = profData.juldLevQc;
            paramDataAdj = profData.juldLevAdjusted;
            paramDataAdjQc = profData.juldLevAdjustedQc;
         else
            paramData = profData.paramData(:, idParam-1);
            paramDataQc = profData.paramDataQc(:, idParam-1);
            paramDataAdj = profData.paramDataAdjusted(:, idParam-1);
            paramDataAdjQc = profData.paramDataAdjustedQc(:, idParam-1);
            paramDataAdjErr = profData.paramDataAdjustedError(:, idParam-1);
         end
      else
         paramData = profData.paramData(:, idParam);
         paramDataQc = profData.paramDataQc(:, idParam);
         paramDataAdj = profData.paramDataAdjusted(:, idParam);
         paramDataAdjQc = profData.paramDataAdjustedQc(:, idParam);
         paramDataAdjErr = profData.paramDataAdjustedError(:, idParam);
      end
      
      paramName = paramList{idParam};
      paramQcName = [paramName '_QC'];
      paramAdjName = [paramName '_ADJUSTED'];
      paramAdjQcName = [paramName '_ADJUSTED_QC'];
      paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
      
      % global quality of PARAM profile
      profParamQcData = compute_profile_quality_flag(paramDataQc);
      profParamQcName = ['PROFILE_' paramName '_QC'];
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), profPos, 1, profParamQcData);
      
      % PARAM profile
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramName), fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData);
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramQcName), fliplr([profPos 0]), fliplr([1 length(paramData)]), paramDataQc);
      
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjName), fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj);
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjQcName), fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdjQc);
      if ~(~isempty(profData.juldLevDataMode) && (idParam == 1)) % there is no JULD_LEVEL_ADJUSTED_ERROR
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjErrName), fliplr([profPos 0]), fliplr([1 length(paramDataAdjErr)]), paramDataAdjErr);
      end
   end
   
   % fill SCIENTIFIC_CALIB_* variable data
   [~, nCalibDim] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_CALIB'));
   parameterVarId = netcdf.inqVarID(fCdf, 'PARAMETER');
   scientificCalibEquationVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_EQUATION');
   scientificCalibCoefficientVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT');
   scientificCalibCommentVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT');
   scientificCalibDateVarId = netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE');
   for idParam = 1:length(paramList)
      
      paramName = paramList{idParam};
      if (~isempty(profData.juldLevDataMode))
         if (idParam == 1)
            scientificCalibEquation = [];
            scientificCalibCoefficient = [];
            scientificCalibComment = [];
            scientificCalibDate = [];
         else
            scientificCalibEquation = profData.scientificCalibEquation{idParam-1};
            scientificCalibCoefficient = profData.scientificCalibCoefficient{idParam-1};
            scientificCalibComment = profData.scientificCalibComment{idParam-1};
            scientificCalibDate = profData.scientificCalibDate{idParam-1};
         end
      else
         scientificCalibEquation = profData.scientificCalibEquation{idParam};
         scientificCalibCoefficient = profData.scientificCalibCoefficient{idParam};
         scientificCalibComment = profData.scientificCalibComment{idParam};
         scientificCalibDate = profData.scientificCalibDate{idParam};
      end
      
      for idCalib = 1:nCalibDim
         netcdf.putVar(fCdf, parameterVarId, ...
            fliplr([profPos idCalib-1 idParam-1 0]), fliplr([1 1 1 length(paramName)]), paramName');
      end
      for idCalib = 1:length(scientificCalibEquation)
         valueStr = scientificCalibEquation{idCalib};
         if (~isempty(valueStr))
            netcdf.putVar(fCdf, scientificCalibEquationVarId, ...
               fliplr([profPos idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
         end
         valueStr = scientificCalibCoefficient{idCalib};
         if (~isempty(valueStr))
            netcdf.putVar(fCdf, scientificCalibCoefficientVarId, ...
               fliplr([profPos idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
         end
         valueStr = scientificCalibComment{idCalib};
         if (~isempty(valueStr))
            netcdf.putVar(fCdf, scientificCalibCommentVarId, ...
               fliplr([profPos idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
         end
         valueStr = scientificCalibDate{idCalib};
         if (~isempty(valueStr))
            netcdf.putVar(fCdf, scientificCalibDateVarId, ...
               fliplr([profPos idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
         end
      end
   end
end

% close NetCDF file
netcdf.close(fCdf);

return
