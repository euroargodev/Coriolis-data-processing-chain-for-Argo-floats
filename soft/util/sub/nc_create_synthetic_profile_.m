% ------------------------------------------------------------------------------
% Generate one synthetic profile from one C and one B mono-profile files.
%
% SYNTAX :
%  nc_create_synthetic_profile_( ...
%    a_cProfFileName, a_bProfFileName, a_metaFileName, ...
%    a_outputDir, a_createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile)
%
% INPUT PARAMETERS :
%   a_cProfFileName       : input C prof file path name
%   a_bProfFileName       : input B prof file path name
%   a_metaFileName        : input meta file path name
%   a_outputDir           : output S prof file directory
%   a_createMultiProfFlag : generate S multi-prof flag
%   a_monoProfRefFile     : netCDF synthetic mono-profile file schema
%   a_multiProfRefFile    : netCDF synthetic multi-profile file schema

%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_create_synthetic_profile_( ...
   a_cProfFileName, a_bProfFileName, a_metaFileName, ...
   a_outputDir, a_createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile)

% current float and cycle identification
global g_cocs_floatNum;


floatWmoStr = num2str(g_cocs_floatNum);

% create output file directory
outputFloatDirName = [a_outputDir '/' floatWmoStr '/profiles/'];
if ~(exist(outputFloatDirName, 'dir') == 7)
   mkdir(outputFloatDirName);
end

% create a temporary directory
tmpDirName = [a_outputDir '/' floatWmoStr '/tmp/'];
if (exist(tmpDirName, 'dir') == 7)
   % delete the temporary directory
   remove_directory(tmpDirName);
end
% create the temporary directory
mkdir(tmpDirName);

% retrieve PROF data
profDataStruct = get_prof_data(a_cProfFileName, a_bProfFileName);

% process PROF data
syntProfDataStruct = [];
if (~isempty(profDataStruct))
   syntProfDataStruct = process_prof_data(profDataStruct, a_cProfFileName, a_bProfFileName, a_metaFileName);
end

% create S-PROF file
if (~isempty(syntProfDataStruct))
   create_synthetic_mono_profile_file(g_cocs_floatNum, syntProfDataStruct, tmpDirName, a_outputDir, a_monoProfRefFile);
end

% create multi S-PROF file
if (a_createMultiProfFlag == 1)
   
   % retrieve S-PROF data
   syntProfAllDataStruct = get_all_synthetic_prof_data(a_outputDir);
   
   if (~isempty(syntProfAllDataStruct))
      create_synthetic_multi_profiles_file(g_cocs_floatNum, syntProfAllDataStruct, tmpDirName, a_outputDir, a_multiProfRefFile);
   end
end

% delete the temporary directory
remove_directory(tmpDirName);

return;

% ------------------------------------------------------------------------------
% Retrieve data from PROF file.
%
% SYNTAX :
%  [o_profData] = get_prof_data(a_cProfFileName, a_bProfFileName)
%
% INPUT PARAMETERS :
%   a_cProfFileName : C PROF file path name
%   a_bProfFileName : B PROF file path name
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
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = get_prof_data(a_cProfFileName, a_bProfFileName)

% output parameter initialization
o_profData = [];

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


% retrieve PROF data from C and B files
profDataTabC = [];
profDataTabB = [];
for idType= 1:2
   if (idType == 1)
      profFilePathName = a_cProfFileName;
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, profFilePathName);
         return;
      end
   else
      if (isempty(a_bProfFileName))
         break;
      end
      profFilePathName = a_bProfFileName;
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, profFilePathName);
         return;
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
      fprintf('WARNING: Float #%d Cycle #%d%c: Input PROF file (%s) format version is %s => not used\n', ...
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, profFilePathName, formatVersion);
      return;
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
            continue;
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
                  break;
               end
            end
            profData.paramDataMode = [profData.paramDataMode parameterDataMode(idProf, nParamId)];
         end
         
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
                     break;
                  end
               end
            end
            if (~isempty(nParamId))
               break;
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
      if (~any((profData.presData - profDataTabB(idProfB).presData) ~= 0))
         profDataB = profDataTabB(idProfB);
         profData.paramList = [profData.paramList profDataB.paramList];
         profData.paramSensorList = [profData.paramSensorList profDataB.paramSensorList];
         profData.paramDataMode = [profData.paramDataMode profDataB.paramDataMode];
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
         break;
      end
   end
   profDataTab = [profDataTab profData];
end
if (~isempty(profDataTabB))
   fprintf('WARNING: Float #%d Cycle #%d%c: %d B profiles are not used\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, length(profDataTabB));
end

% output parameter
o_profData = profDataTab;

return;

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
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
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

return;

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
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return;

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
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncDataAtt] = get_att_from_nc_file(a_ncPathFileName, a_wantedVarAtts)

% output parameters initialization
o_ncDataAtt = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
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

return;

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
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_varName, a_dataList(1:3:end)) & strcmp(a_attName, a_dataList(2:3:end)));
if (~isempty(idVal))
   o_dataValues = a_dataList{3*idVal};
end

return;

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
%   06/15/2018 - RNU - creation
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

return;

% ------------------------------------------------------------------------------
% Process PROF data to generate synthetic profile data.
%
% SYNTAX :
%  [o_syntProfData] = process_prof_data(a_profData, ...
%    a_cProfFileName, a_bProfFileName, a_metaFileName)
%
% INPUT PARAMETERS :
%   a_profData      : data retrieved from PROF file(s)
%   a_cProfFileName : input C prof file path name
%   a_bProfFileName : input B prof file path name
%   a_metaFileName  : input meta file path name
%
% OUTPUT PARAMETERS :
%   o_syntProfData : synthetic profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_syntProfData] = process_prof_data(a_profData, ...
   a_cProfFileName, a_bProfFileName, a_metaFileName)

% output parameters initialization
o_syntProfData = [];

% QC flag values (char)
global g_decArgo_qcStrDef;

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


% check input profile consistency
errorFlag = 0;
if (length(unique({a_profData.handbookVersion})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple HANDBOOK_VERSION => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.referenceDateTime})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple REFERENCE_DATE_TIME => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.platformNumber})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PLATFORM_NUMBER => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.projectName})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PROJECT_NAME => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.piName})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PI_NAME => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.cycleNumber])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple CYCLE_NUMBER => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.direction})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple DIRECTION => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.dataCentre})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple DATA_CENTRE => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.platformType})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PLATFORM_TYPE => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.floatSerialNo})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple FLOAT_SERIAL_NO => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.firmwareVersion})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple FIRMWARE_VERSION => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.wmoInstType})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple WMO_INST_TYPE => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juld])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldResolution])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD:resolution => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.juldQc})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_QC => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldLocation])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_LOCATION => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldLocationResolution])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_LOCATION:resolution => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.latitude])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple LATITUDE => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.longitude])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple LONGITUDE => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.positionQc})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple POSITION_QC => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.positioningSystem})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple POSITIONING_SYSTEM => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.configMissionNumber])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple CONFIG_MISSION_NUMBER => file ignored\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   errorFlag = 1;
end
if (errorFlag == 1)
   return;
end

% create synthetic profile
o_syntProfData = get_synthetic_prof_data_init_struct;

% fill synthetic profile
o_syntProfData.handbookVersion = a_profData(1).handbookVersion;
o_syntProfData.referenceDateTime = a_profData(1).referenceDateTime;
o_syntProfData.platformNumber = a_profData(1).platformNumber;
o_syntProfData.projectName = a_profData(1).projectName;
o_syntProfData.piName = a_profData(1).piName;
o_syntProfData.cycleNumber = a_profData(1).cycleNumber;
o_syntProfData.direction = a_profData(1).direction;
o_syntProfData.dataCentre = a_profData(1).dataCentre;
o_syntProfData.platformType = a_profData(1).platformType;
o_syntProfData.floatSerialNo = a_profData(1).floatSerialNo;
o_syntProfData.firmwareVersion = a_profData(1).firmwareVersion;
o_syntProfData.wmoInstType = a_profData(1).wmoInstType;
o_syntProfData.juld = a_profData(1).juld;
o_syntProfData.juldResolution = a_profData(1).juldResolution;
o_syntProfData.juldQc = a_profData(1).juldQc;
o_syntProfData.juldLocation = a_profData(1).juldLocation;
o_syntProfData.juldLocationResolution = a_profData(1).juldLocationResolution;
o_syntProfData.latitude = a_profData(1).latitude;
o_syntProfData.longitude = a_profData(1).longitude;
o_syntProfData.positionQc = a_profData(1).positionQc;
o_syntProfData.positioningSystem = a_profData(1).positioningSystem;
o_syntProfData.configMissionNumber = a_profData(1).configMissionNumber;

% gather information on final parameter list
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

% compute synthetic profile data
try
   syntProfData = ARGO_simplify_getpressureaxis_v6( ...
      'cfilepath', a_cProfFileName, ...
      'bfilepath', a_bProfFileName, ...
      'metafilepath', a_metaFileName);
catch
   [~, bProfFileName, bProfFileExt] = fileparts(a_bProfFileName);
   fprintf('ERROR: Float #%d Cycle #%d%c: the synthetic profile data processing failed (ARGO_simplify_getpressureaxis_v6 fonction on file %s)\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, [bProfFileName bProfFileExt]);
   o_syntProfData = [];
   return;
end

if (isempty(syntProfData))
   fprintf('INFO: Float #%d Cycle #%d%c: no synthetic profile data reported by ARGO_simplify_getpressureaxis_v6 fonction\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   o_syntProfData = [];
   return;
end

% store synthetic profile data in the output structure

% initialize data arrays
nbLev = length(syntProfData.PRES.value);
paramData = repmat(paramFillValue, nbLev, 1);
paramDataQc = repmat(g_decArgo_qcStrDef, size(paramData));
paramDataDPres = repmat(repmat(paramFillValue(1), 1, size(paramData, 2)), nbLev, 1);
paramDataAdjusted = repmat(paramFillValue, nbLev, 1);
paramDataAdjustedQc = repmat(g_decArgo_qcStrDef, size(paramData));
paramDataAdjustedError = repmat(paramFillValue, nbLev, 1);

for idParam = 1:length(paramList)
   
   paramName = paramList{idParam};
   data = syntProfData.(paramName).value;
   idOk = find(~isnan(data));
   paramData(idOk, idParam) = data(idOk);
   
   paramNameQc = [paramName '_QC'];
   dataQc = syntProfData.(paramNameQc).value;
   idOk = find(~isnan(data));
   paramDataQc(idOk, idParam) = num2str(dataQc(idOk));
   
   paramNameDPres = [paramName '_dPRES'];
   data = syntProfData.(paramNameDPres).value;
   idOk = find(~isnan(data));
   paramDataDPres(idOk, idParam) = data(idOk);

   paramNameAdj = [paramName '_ADJUSTED'];
   data = syntProfData.(paramNameAdj).value;
   idOk = find(~isnan(data));
   paramDataAdjusted(idOk, idParam) = data(idOk);
   
   paramNameAdjQc = [paramName '_ADJUSTED_QC'];
   dataQc = syntProfData.(paramNameAdjQc).value;
   idOk = find(~isnan(data));
   paramDataAdjustedQc(idOk, idParam) = num2str(dataQc(idOk));
   
   paramNameAdjErr = [paramName '_ADJUSTED_ERROR'];
   data = syntProfData.(paramNameAdjErr).value;
   idOk = find(~isnan(data));
   paramDataAdjustedError(idOk, idParam) = data(idOk);
end

o_syntProfData.paramList = paramList;
o_syntProfData.paramDataMode = paramDataMode;

o_syntProfData.paramData = paramData;
o_syntProfData.paramDataQc = paramDataQc;
o_syntProfData.paramDataDPres = paramDataDPres;
o_syntProfData.paramDataAdjusted = paramDataAdjusted;
o_syntProfData.paramDataAdjustedQc = paramDataAdjustedQc;
o_syntProfData.paramDataAdjustedError = paramDataAdjustedError;

% retrieve SCIENTIFIC_CALIB_* information
scientificCalibEquation = cell(1, length(paramList));
scientificCalibCoefficient = cell(1, length(paramList));
scientificCalibComment = cell(1, length(paramList));
scientificCalibDate = cell(1, length(paramList));

% collect data
for idProf = 1:length(a_profData)
   profData = a_profData(idProf);
   
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
end

o_syntProfData.scientificCalibEquation = scientificCalibEquation;
o_syntProfData.scientificCalibCoefficient = scientificCalibCoefficient;
o_syntProfData.scientificCalibComment = scientificCalibComment;
o_syntProfData.scientificCalibDate = scientificCalibDate;

if (isempty(o_syntProfData.paramData))
   
   fprintf('INFO: Float #%d Cycle #%d%c: no data remain after processing => no synthetic profile\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
   o_syntProfData = [];
end

return;

% ------------------------------------------------------------------------------
% Get the dedicated structure to store synthetic profile information.
%
% SYNTAX :
%  [o_profDataStruct] = get_synthetic_prof_data_init_struct
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_profDataStruct : synthetic profile data initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDataStruct] = get_synthetic_prof_data_init_struct

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
   'paramList', [], ...
   'paramDataMode', '', ...
   ...
   'paramData', [], ...
   'paramDataQc', '', ...
   'paramDataDPres', [], ...
   'paramDataAdjusted', [], ...
   'paramDataAdjustedQc', '', ...
   'paramDataAdjustedError', [], ...
   ...
   'scientificCalibEquation', [], ...
   'scientificCalibCoefficient', [], ...
   'scientificCalibComment', [], ...
   'scientificCalibDate', [] ...
   );

return;

% ------------------------------------------------------------------------------
% Create synthetic mono-profile NetCDF file.
%
% SYNTAX :
%  create_synthetic_mono_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
%
% INPUT PARAMETERS :
%   a_floatWmo  : float WMO number
%   a_profData  : synthetic profile data
%   a_tmpDir    : temporary directory
%   a_outputDir : output directory
%   a_refFile   : synthetic profile reference file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_synthetic_mono_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)

% current float and cycle identification
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% generate NetCDF-4 flag
global g_cocs_netCDF4FlagForMonoProf;

% report information structure
global g_cocs_reportData;

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
outputFileName = ['S' modeCode num2str(a_floatWmo) '_' sprintf('%03d%c', g_cocs_cycleNum, g_cocs_cycleDir) '.nc'];
outputFilePathName = [a_tmpDir '/' outputFileName];

% retrieve the synthetic profile file schema
outputFileSchema = ncinfo(a_refFile);
if (g_cocs_netCDF4FlagForMonoProf)
   % set the deflate level of the variables
   for idVar = 1:length(outputFileSchema.Variables)
      var = outputFileSchema.Variables(idVar);
      var.DeflateLevel = DEFLATE_LEVEL;
      var.Shuffle = SHUFFLE_FLAG;
      outputFileSchema.Variables(idVar) = var;
   end
end

% compute file dimensions
nProfDim = 1;
nParamDim = size(a_profData.paramData, 2);
nLevelsDim = size(a_profData.paramData, 1);
nCalibDim = 1;
for idParam = 1:length(a_profData.scientificCalibEquation)
   scientificCalibEquation = a_profData.scientificCalibEquation{idParam};
   nCalibDim = max(nCalibDim, length(scientificCalibEquation));
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

% create synthetic profile file
ncwriteschema(outputFilePathName, outputFileSchema);

% fill synthetic profile file
fill_synthetic_mono_profile_file(outputFilePathName, a_profData);

% update output file
move_file(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/profiles/' outputFileName]);

% report information structure
g_cocs_reportData.outputSMonoProfFile = [a_outputDir '/' num2str(a_floatWmo) '/profiles/' outputFileName];

return;

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
%   06/15/2018 - RNU - creation
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

return;

% ------------------------------------------------------------------------------
% Fill synthetic mono-profile NetCDF file.
%
% SYNTAX :
%  fill_synthetic_mono_profile_file(a_fileName, a_profData)
%
% INPUT PARAMETERS :
%   a_fileName : synthetic mono-profile NetCDF file path name
%   a_profData : synthetic profile data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function fill_synthetic_mono_profile_file(a_fileName, a_profData)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocs_ncCreateSyntheticProfileVersion;

% generate NetCDF-4 flag
global g_cocs_netCDF4FlagForMonoProf;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to open NetCDF output file: %s\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, a_fileName);
   return;
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

netcdf.reDef(fCdf);

% fill global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
institution = get_institution_from_data_centre(a_profData.dataCentre);
if (isempty(institution))
   fprintf('WARNING: Float #%d Cycle #%d%c: No institution assigned to data centre %s\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, a_profData.datacentre);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
netcdf.putAtt(fCdf, globalVarId, 'history', ...
   [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ...
   ' creation (software version ' g_cocs_ncCreateSyntheticProfileVersion ')']);
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

% global quality of PARAM profile
for idParam = 1:length(paramList)
   paramName = paramList{idParam};
   profParamQcName = ['PROFILE_' paramName '_QC'];
   
   profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
   if (g_cocs_netCDF4FlagForMonoProf)
      netcdf.defVarDeflate(fCdf, profileParamQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
   end
   
   netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
   netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
   netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
end

% PARAM profile
paramPresInfo = get_netcdf_param_attributes('PRES');
for idParam = 1:length(paramList)
   
   paramName = paramList{idParam};
   paramInfo = get_netcdf_param_attributes(paramName);
   
   % parameter variable and attributes
   if (~var_is_present_dec_argo(fCdf, paramName))
      
      paramVarId = netcdf.defVar(fCdf, paramName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
      if (g_cocs_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      if (~isempty(paramInfo.longName))
         netcdf.putAtt(fCdf, paramVarId, 'long_name', paramInfo.longName);
      end
      if (~isempty(paramInfo.standardName))
         netcdf.putAtt(fCdf, paramVarId, 'standard_name', paramInfo.standardName);
      end
      if (~isempty(paramInfo.fillValue))
         netcdf.putAtt(fCdf, paramVarId, '_FillValue', paramInfo.fillValue);
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
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, paramName);
   end
   
   % parameter QC variable and attributes
   paramQcName = [paramName '_QC'];
   if (~var_is_present_dec_argo(fCdf, paramQcName))
      
      paramQcVarId = netcdf.defVar(fCdf, paramQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
      if (g_cocs_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, paramQcName);
   end
   
   % parameter displacement variable and attributes
   if (~strcmp(paramName, 'PRES'))
      paramDPresName = [paramName '_dPRES'];
      if (~var_is_present_dec_argo(fCdf, paramDPresName))
         
         paramDPresVarId = netcdf.defVar(fCdf, paramDPresName, paramPresInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         
         netcdf.putAtt(fCdf, paramDPresVarId, 'long_name', [paramName ' pressure displacement from original sampled value']);

         if (~isempty(paramInfo.fillValue))
            netcdf.putAtt(fCdf, paramDPresVarId, '_FillValue', paramPresInfo.fillValue);
         end
         if (~isempty(paramInfo.units))
            netcdf.putAtt(fCdf, paramDPresVarId, 'units', paramPresInfo.units);
         end
      else
         fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
            g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, paramDPresName);
      end
   end
   
   % parameter adjusted variable and attributes
   paramAdjName = [paramName '_ADJUSTED'];
   if (~var_is_present_dec_argo(fCdf, paramAdjName))
      
      paramAdjVarId = netcdf.defVar(fCdf, paramAdjName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
      if (g_cocs_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramAdjVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      if (~isempty(paramInfo.longName))
         netcdf.putAtt(fCdf, paramAdjVarId, 'long_name', paramInfo.longName);
      end
      if (~isempty(paramInfo.standardName))
         netcdf.putAtt(fCdf, paramAdjVarId, 'standard_name', paramInfo.standardName);
      end
      if (~isempty(paramInfo.fillValue))
         netcdf.putAtt(fCdf, paramAdjVarId, '_FillValue', paramInfo.fillValue);
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
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, paramAdjName);
   end
   
   % parameter adjusted QC variable and attributes
   paramAdjQcName = [paramName '_ADJUSTED_QC'];
   if (~var_is_present_dec_argo(fCdf, paramAdjQcName))
      
      paramAdjQcVarId = netcdf.defVar(fCdf, paramAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
      if (g_cocs_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramAdjQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, paramAdjQcName);
   end
   
   % parameter adjusted error variable and attributes
   paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
   if (~var_is_present_dec_argo(fCdf, paramAdjErrName))
      
      paramAdjErrVarId = netcdf.defVar(fCdf, paramAdjErrName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
      if (g_cocs_netCDF4FlagForMonoProf)
         netcdf.defVarDeflate(fCdf, paramAdjErrVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
      end
      
      netcdf.putAtt(fCdf, paramAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
      if (~isempty(paramInfo.fillValue))
         netcdf.putAtt(fCdf, paramAdjErrVarId, '_FillValue', paramInfo.fillValue);
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
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, paramAdjErrName);
   end
end

netcdf.endDef(fCdf);

% fill misc variable data
valueStr = 'Argo synthetic profile';
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
valueStr = a_profData.platformNumber;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_NUMBER'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.projectName;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PROJECT_NAME'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.piName;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PI_NAME'), [0 0], fliplr([1 length(valueStr)]), valueStr');
stationParametersVarId = netcdf.inqVarID(fCdf, 'STATION_PARAMETERS');
for idParam = 1:length(paramList)
   valueStr = paramList{idParam};
   netcdf.putVar(fCdf, stationParametersVarId, ...
      fliplr([0 idParam-1 0]), fliplr([1 1 length(valueStr)]), valueStr');
end
value = a_profData.cycleNumber;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'), 0, length(value), value);
valueStr = a_profData.direction;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'), 0, length(valueStr), valueStr);
valueStr = a_profData.dataCentre;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_CENTRE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.paramDataMode;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER_DATA_MODE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.platformType;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_TYPE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.floatSerialNo;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FLOAT_SERIAL_NO'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.firmwareVersion;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FIRMWARE_VERSION'), [0 0], fliplr([1 length(valueStr)]), valueStr');
valueStr = a_profData.wmoInstType;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'WMO_INST_TYPE'), [0 0], fliplr([1 length(valueStr)]), valueStr');
value = a_profData.juld;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'), 0, length(value), value);
valueStr = a_profData.juldQc;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), 0, length(valueStr), valueStr);
value = a_profData.juldLocation;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), 0, length(value), value);
value = a_profData.latitude;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), 0, length(value), value);
value = a_profData.longitude;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), 0, length(value), value);
valueStr = a_profData.positionQc;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), 0, length(valueStr), valueStr);
valueStr = a_profData.positioningSystem;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITIONING_SYSTEM'), [0 0], fliplr([1 length(valueStr)]), valueStr');
value = a_profData.configMissionNumber;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER'), 0, length(value), value);

% fill PARAM variable data
for idParam = 1:length(paramList)
   
   paramData = a_profData.paramData(:, idParam);
   paramDataQc = a_profData.paramDataQc(:, idParam);
   paramDataDPres = a_profData.paramDataDPres(:, idParam);
   paramDataAdj = a_profData.paramDataAdjusted(:, idParam);
   paramDataAdjQc = a_profData.paramDataAdjustedQc(:, idParam);
   paramDataAdjErr = a_profData.paramDataAdjustedError(:, idParam);
   
   paramName = paramList{idParam};
   paramQcName = [paramName '_QC'];
   if (~strcmp(paramName, 'PRES'))
      paramDPresName = [paramName '_dPRES'];
   end
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
   if (~strcmp(paramName, 'PRES'))
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramDPresName), fliplr([0 0]), fliplr([1 length(paramDataDPres)]), paramDataDPres);
   end
   
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjName), fliplr([0 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjQcName), fliplr([0 0]), fliplr([1 length(paramDataAdj)]), paramDataAdjQc);
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjErrName), fliplr([0 0]), fliplr([1 length(paramDataAdjErr)]), paramDataAdjErr);
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
   scientificCalibEquation = a_profData.scientificCalibEquation{idParam};
   scientificCalibCoefficient = a_profData.scientificCalibCoefficient{idParam};
   scientificCalibComment = a_profData.scientificCalibComment{idParam};
   scientificCalibDate = a_profData.scientificCalibDate{idParam};
   
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

return;

% ------------------------------------------------------------------------------
% Store data from all existing S-PROF files and a given directory in a dedicated
% structure.
%
% SYNTAX :
%  [o_syntProfAllData] = get_all_synthetic_prof_data(a_outputDir)
%
% INPUT PARAMETERS :
%   a_outputDir : directory of expected S-PROF files to load
%
% OUTPUT PARAMETERS :
%   o_syntProfAllData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_syntProfAllData] = get_all_synthetic_prof_data(a_outputDir)

% output parameter initialization
o_syntProfAllData = [];

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


floatWmoStr = num2str(g_cocs_floatNum);

% create the list of available cycle numbers for S-PROF files
files = dir([a_outputDir '/' floatWmoStr '/profiles/' 'S*' floatWmoStr '_' '*.nc']);
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

% retrieve S-PROF files data
for idCy = 1:length(cyNumList)
   
   g_cocs_cycleNum = cyNumList(idCy);
   
   % process descending and ascending profiles
   for idDir = 1:2
      
      if (idDir == 1)
         g_cocs_cycleDir = 'D';
      else
         g_cocs_cycleDir = '';
      end
      
      sProfFileName = '';
      if (exist([a_outputDir '/' floatWmoStr '/profiles/' sprintf('SD%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         sProfFileName = [a_outputDir '/' floatWmoStr '/profiles/' sprintf('SD%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)];
      elseif (exist([a_outputDir '/' floatWmoStr '/profiles/' sprintf('SR%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         sProfFileName = [a_outputDir '/' floatWmoStr '/profiles/' sprintf('SR%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)];
      end
      
      if (~isempty(sProfFileName))
         
         % retrieve S-PROF file data
         syntProfDataStruct = get_synthetic_prof_data(sProfFileName);
         
         if (~isempty(syntProfDataStruct))
            o_syntProfAllData = [o_syntProfAllData syntProfDataStruct];
         end
      end
   end
end

% uniformize N_CALIB dimension between S-PROF file data
if (~isempty(o_syntProfAllData))
   o_syntProfAllData = uniformize_n_calib_dimension(o_syntProfAllData);
end

return;

% ------------------------------------------------------------------------------
% Store data from one S-PROF file in a dedicated structure.
%
% SYNTAX :
%  [o_syntProfData] = get_synthetic_prof_data(a_sProfFileName)
%
% INPUT PARAMETERS :
%   a_sProfFileName : S-PROF file path name
%
% OUTPUT PARAMETERS :
%   o_syntProfData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_syntProfData] = get_synthetic_prof_data(a_sProfFileName)

% output parameter initialization
o_syntProfData = [];

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


if ~(exist(a_sProfFileName, 'file') == 2)
   fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, a_sProfFileName);
   return;
end

% retrieve information from S-PROF file
wantedVars = [ ...
   {'STATION_PARAMETERS'} ...
   ];
[profData1] = get_data_from_nc_file(a_sProfFileName, wantedVars);

stationParameters = get_data_from_name('STATION_PARAMETERS', profData1);

% create the list of parameters to be retrieved from S-PROF file
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
            {[paramName '_dPRES']} ...
            {[paramName '_ADJUSTED']} ...
            {[paramName '_ADJUSTED_QC']} ...
            {[paramName '_ADJUSTED_ERROR']} ...
            ];
      end
   end
   profParameterList = [profParameterList; {profParamList}];
end

% retrieve information from S-PROF file
[profData2] = get_data_from_nc_file(a_sProfFileName, wantedVars);

% retrieve information from S-PROF file
wantedVarAtts = [ ...
   {'JULD'} {'resolution'} ...
   {'JULD_LOCATION'} {'resolution'} ...
   ];

[profDataAtt] = get_att_from_nc_file(a_sProfFileName, wantedVarAtts);

% fill synthetic profile structure
o_syntProfData = get_synthetic_prof_data_init_struct;

o_syntProfData.handbookVersion = get_data_from_name('HANDBOOK_VERSION', profData2)';
o_syntProfData.referenceDateTime = get_data_from_name('REFERENCE_DATE_TIME', profData2)';
o_syntProfData.platformNumber = get_data_from_name('PLATFORM_NUMBER', profData2)';
o_syntProfData.projectName = get_data_from_name('PROJECT_NAME', profData2)';
o_syntProfData.piName = get_data_from_name('PI_NAME', profData2)';
o_syntProfData.cycleNumber = get_data_from_name('CYCLE_NUMBER', profData2)';
o_syntProfData.direction = get_data_from_name('DIRECTION', profData2)';
o_syntProfData.dataCentre = get_data_from_name('DATA_CENTRE', profData2)';
o_syntProfData.platformType = get_data_from_name('PLATFORM_TYPE', profData2)';
o_syntProfData.floatSerialNo = get_data_from_name('FLOAT_SERIAL_NO', profData2)';
o_syntProfData.firmwareVersion = get_data_from_name('FIRMWARE_VERSION', profData2)';
o_syntProfData.wmoInstType = get_data_from_name('WMO_INST_TYPE', profData2)';
o_syntProfData.juld = get_data_from_name('JULD', profData2)';
o_syntProfData.juldResolution = get_att_from_name('JULD', 'resolution', profDataAtt);
o_syntProfData.juldQc = get_data_from_name('JULD_QC', profData2)';
o_syntProfData.juldLocation = get_data_from_name('JULD_LOCATION', profData2)';
o_syntProfData.juldLocationResolution = get_att_from_name('JULD_LOCATION', 'resolution', profDataAtt);
o_syntProfData.latitude = get_data_from_name('LATITUDE', profData2)';
o_syntProfData.longitude = get_data_from_name('LONGITUDE', profData2)';
o_syntProfData.positionQc = get_data_from_name('POSITION_QC', profData2)';
o_syntProfData.positioningSystem = get_data_from_name('POSITIONING_SYSTEM', profData2)';
o_syntProfData.configMissionNumber = get_data_from_name('CONFIG_MISSION_NUMBER', profData2)';

parameterDataMode = get_data_from_name('PARAMETER_DATA_MODE', profData2)';
parameter = get_data_from_name('PARAMETER', profData2);
[~, ~, nCalib, ~] = size(parameter);
scientificCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', profData2);
scientificCalibCoefficient = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', profData2);
scientificCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', profData2);
scientificCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', profData2);

paramPresInfo = get_netcdf_param_attributes('PRES');
for idProf = 1:nProf
   profParamList = profParameterList{idProf, :};
   for idParam = 1:length(profParamList)
      paramName = profParamList{idParam};
      paramData = get_data_from_name(paramName, profData2)';
      paramDataQc = get_data_from_name([paramName '_QC'], profData2)';
      if (~strcmp(paramName, 'PRES'))
         paramDataDPres = get_data_from_name([paramName '_dPRES'], profData2)';
      else
         paramDataDPres = repmat(paramPresInfo.fillValue, 1, length(paramData));
      end
      paramDataAdjusted = get_data_from_name([paramName '_ADJUSTED'], profData2)';
      paramDataAdjustedQc = get_data_from_name([paramName '_ADJUSTED_QC'], profData2)';
      paramDataAdjustedError = get_data_from_name([paramName '_ADJUSTED_ERROR'], profData2)';
      
      o_syntProfData.paramList = [o_syntProfData.paramList {paramName}];
      o_syntProfData.paramDataMode = [o_syntProfData.paramDataMode parameterDataMode(idProf, idParam)];
      
      o_syntProfData.paramData = [o_syntProfData.paramData paramData(idProf, :)'];
      o_syntProfData.paramDataQc = [o_syntProfData.paramDataQc paramDataQc(idProf, :)'];
      o_syntProfData.paramDataDPres = [o_syntProfData.paramDataDPres paramDataDPres(idProf, :)'];
      o_syntProfData.paramDataAdjusted = [o_syntProfData.paramDataAdjusted paramDataAdjusted(idProf, :)'];
      o_syntProfData.paramDataAdjustedQc = [o_syntProfData.paramDataAdjustedQc paramDataAdjustedQc(idProf, :)'];
      o_syntProfData.paramDataAdjustedError = [o_syntProfData.paramDataAdjustedError paramDataAdjustedError(idProf, :)'];
      
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
                  break;
               end
            end
         end
         if (~isempty(nParamId))
            break;
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
      o_syntProfData.scientificCalibEquation{idParam} = scientificCalibEquationTab;
      o_syntProfData.scientificCalibCoefficient{idParam} = scientificCalibCoefficientTab;
      o_syntProfData.scientificCalibComment{idParam} = scientificCalibCommentTab;
      o_syntProfData.scientificCalibDate{idParam} = scientificCalibDateTab;
   end
end

return;

% ------------------------------------------------------------------------------
% Uniformize the N_CALIB dimension between the profile structures.
%
% SYNTAX :
%  [a_syntProfAllData] = uniformize_n_calib_dimension(o_syntProfAllData)
%
% INPUT PARAMETERS :
%   a_syntProfAllData : input profile data structure
%
% OUTPUT PARAMETERS :
%   o_syntProfAllData : output profile data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [a_syntProfAllData] = uniformize_n_calib_dimension(a_syntProfAllData)

% output parameter initialization
a_syntProfAllData = a_syntProfAllData;


% compute final N_CALB dimension
nCalibDim = 0;
for idProf = 1:length(a_syntProfAllData)
   if (~isempty(a_syntProfAllData(idProf).scientificCalibEquation))
      nCalibDim = max(nCalibDim, length(a_syntProfAllData(idProf).scientificCalibEquation{1}));
   end
end

% update data
for idProf = 1:length(a_syntProfAllData)
   nCalibProf = 0;
   if (~isempty(a_syntProfAllData(idProf).scientificCalibEquation))
      nCalibProf = length(a_syntProfAllData(idProf).scientificCalibEquation{1});
   end
   if (nCalibProf < nCalibDim)
      for idParam = 1:length(a_syntProfAllData(idProf).scientificCalibEquation)
         a_syntProfAllData(idProf).scientificCalibEquation{idParam} = ...
            cat(2, a_syntProfAllData(idProf).scientificCalibEquation{idParam}, cell(1, nCalibDim-nCalibProf));
         a_syntProfAllData(idProf).scientificCalibCoefficient{idParam} = ...
            cat(2, a_syntProfAllData(idProf).scientificCalibCoefficient{idParam}, cell(1, nCalibDim-nCalibProf));
         a_syntProfAllData(idProf).scientificCalibComment{idParam} = ...
            cat(2, a_syntProfAllData(idProf).scientificCalibComment{idParam}, cell(1, nCalibDim-nCalibProf));
         a_syntProfAllData(idProf).scientificCalibDate{idParam} = ...
            cat(2, a_syntProfAllData(idProf).scientificCalibDate{idParam}, cell(1, nCalibDim-nCalibProf));
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Create synthetic multi-profile NetCDF file.
%
% SYNTAX :
%  create_synthetic_multi_profiles_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
%
% INPUT PARAMETERS :
%   a_floatWmo  : float WMO number
%   a_profData  : synthetic profile data
%   a_tmpDir    : temporary directory
%   a_outputDir : output directory
%   a_refFile   : synthetic profile reference file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_synthetic_multi_profiles_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)

% generate NetCDF-4 flag
global g_cocs_netCDF4FlagForMultiProf;

% report information structure
global g_cocs_reportData;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% create the output file name
outputFileName = [num2str(a_floatWmo) '_Sprof.nc'];
outputFilePathName = [a_tmpDir '/' outputFileName];

% retrieve the synthetic profile file schema
outputFileSchema = ncinfo(a_refFile);
if (g_cocs_netCDF4FlagForMultiProf)
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
   nParamDim = max(nParamDim, size(profData.paramData, 2));
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

% create synthetic profile file
ncwriteschema(outputFilePathName, outputFileSchema);

% fill synthetic profile file
fill_synthetic_multi_profiles_file(outputFilePathName, a_profData);

% update output file
move_file(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/' outputFileName]);

% report information structure
g_cocs_reportData.outputSMultiProfFile = [a_outputDir '/' num2str(a_floatWmo) '/' outputFileName];

return;

% ------------------------------------------------------------------------------
% Fill synthetic multi-profile NetCDF file.
%
% SYNTAX :
%  fill_synthetic_multi_profiles_file(a_fileName, a_profData)
%
% INPUT PARAMETERS :
%   a_fileName : synthetic multi-profile NetCDF file path name
%   a_profData : synthetic profile data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function fill_synthetic_multi_profiles_file(a_fileName, a_profData)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocs_ncCreateSyntheticProfileVersion;

% generate NetCDF-4 flag
global g_cocs_netCDF4FlagForMultiProf;

% deflate levels
DEFLATE_LEVEL = 4;

% shuffle flag
SHUFFLE_FLAG = true;


% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to open NetCDF output file: %s\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, a_fileName);
   return;
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

netcdf.reDef(fCdf);

% fill global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
institution = get_institution_from_data_centre(a_profData(1).dataCentre);
if (isempty(institution))
   fprintf('WARNING: Float #%d Cycle #%d%c: No institution assigned to data centre %s\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, a_profData(1).datacentre);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
netcdf.putAtt(fCdf, globalVarId, 'history', ...
   [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ...
   ' creation (software version ' g_cocs_ncCreateSyntheticProfileVersion ')']);
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
paramPresInfo = get_netcdf_param_attributes('PRES');
for idProf = 1:length(a_profData)
   
   profData = a_profData(idProf);
   paramList = profData.paramList;
   
   % global quality of PARAM profile
   for idParam = 1:length(paramList)
      paramName = paramList{idParam};
      profParamQcName = ['PROFILE_' paramName '_QC'];
      
      if (~var_is_present_dec_argo(fCdf, profParamQcName))
         profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
         if (g_cocs_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, profileParamQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
         netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
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
         if (g_cocs_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         if (~isempty(paramInfo.longName))
            netcdf.putAtt(fCdf, paramVarId, 'long_name', paramInfo.longName);
         end
         if (~isempty(paramInfo.standardName))
            netcdf.putAtt(fCdf, paramVarId, 'standard_name', paramInfo.standardName);
         end
         if (~isempty(paramInfo.fillValue))
            netcdf.putAtt(fCdf, paramVarId, '_FillValue', paramInfo.fillValue);
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
         if (g_cocs_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
      end
      
      % parameter displacement variable and attributes
      if (~strcmp(paramName, 'PRES'))
         paramDPresName = [paramName '_dPRES'];
         if (~var_is_present_dec_argo(fCdf, paramDPresName))
            
            paramDPresVarId = netcdf.defVar(fCdf, paramDPresName, paramPresInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
            
            netcdf.putAtt(fCdf, paramDPresVarId, 'long_name', [paramName ' pressure displacement from original sampled value']);
            
            if (~isempty(paramInfo.fillValue))
               netcdf.putAtt(fCdf, paramDPresVarId, '_FillValue', paramPresInfo.fillValue);
            end
            if (~isempty(paramInfo.units))
               netcdf.putAtt(fCdf, paramDPresVarId, 'units', paramPresInfo.units);
            end
         end
      end
   
      % parameter adjusted variable and attributes
      paramAdjName = [paramName '_ADJUSTED'];
      if (~var_is_present_dec_argo(fCdf, paramAdjName))
         
         paramAdjVarId = netcdf.defVar(fCdf, paramAdjName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         if (g_cocs_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramAdjVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         if (~isempty(paramInfo.longName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'long_name', paramInfo.longName);
         end
         if (~isempty(paramInfo.standardName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'standard_name', paramInfo.standardName);
         end
         if (~isempty(paramInfo.fillValue))
            netcdf.putAtt(fCdf, paramAdjVarId, '_FillValue', paramInfo.fillValue);
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
         if (g_cocs_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramAdjQcVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
      end
      
      % parameter adjusted error variable and attributes
      paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
      if (~var_is_present_dec_argo(fCdf, paramAdjErrName))
         
         paramAdjErrVarId = netcdf.defVar(fCdf, paramAdjErrName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         if (g_cocs_netCDF4FlagForMultiProf)
            netcdf.defVarDeflate(fCdf, paramAdjErrVarId, SHUFFLE_FLAG, true, DEFLATE_LEVEL);
         end
         
         netcdf.putAtt(fCdf, paramAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
         if (~isempty(paramInfo.fillValue))
            netcdf.putAtt(fCdf, paramAdjErrVarId, '_FillValue', paramInfo.fillValue);
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

netcdf.endDef(fCdf);

% fill misc variable data
valueStr = 'Argo synthetic profile';
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
   valueStr = profData.paramDataMode;
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
      
      paramData = profData.paramData(:, idParam);
      paramDataQc = profData.paramDataQc(:, idParam);
      paramDataDPres = profData.paramDataDPres(:, idParam);
      paramDataAdj = profData.paramDataAdjusted(:, idParam);
      paramDataAdjQc = profData.paramDataAdjustedQc(:, idParam);
      paramDataAdjErr = profData.paramDataAdjustedError(:, idParam);
      
      paramName = paramList{idParam};
      paramQcName = [paramName '_QC'];
      if (~strcmp(paramName, 'PRES'))
         paramDPresName = [paramName '_dPRES'];
      end
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
      if (~strcmp(paramName, 'PRES'))
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramDPresName), fliplr([profPos 0]), fliplr([1 length(paramDataDPres)]), paramDataDPres);
      end
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjName), fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdj);
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjQcName), fliplr([profPos 0]), fliplr([1 length(paramDataAdj)]), paramDataAdjQc);
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramAdjErrName), fliplr([profPos 0]), fliplr([1 length(paramDataAdjErr)]), paramDataAdjErr);
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
      scientificCalibEquation = profData.scientificCalibEquation{idParam};
      scientificCalibCoefficient = profData.scientificCalibCoefficient{idParam};
      scientificCalibComment = profData.scientificCalibComment{idParam};
      scientificCalibDate = profData.scientificCalibDate{idParam};
      
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

return;
