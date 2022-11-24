% ------------------------------------------------------------------------------
% Generate a synthetic profile from C and B mono-profile files.
%
% SYNTAX :
%   nc_create_synthetic_profile or
%   nc_create_synthetic_profile(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/11/2018 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function nc_create_synthetic_profile(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_rem_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = '';

% top directory of input NetCDF files
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
DIR_INPUT_NC_FILES = 'H:\archive_201801\coriolis\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\SYNTHETIC_PROFILE\';

% top directory of output NetCDF files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_S_Prof\';

% synthetic profile reference file
REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoSProf_V0.3.nc';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% to print data after each processing step
PRINT_CSV_FLAG = 0;

% program version
global g_cocs_ncCreateSyntheticProfileVersion;
g_cocs_ncCreateSyntheticProfileVersion = '0.3b';

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% to print data after each processing step
global g_cocs_printCsv;
g_cocs_printCsv = PRINT_CSV_FLAG;


% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

errorFlag = 0;

% input parameters management
floatList = [];
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      floatListFileName = FLOAT_LIST_FILE_NAME;
      
      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         errorFlag = 1;
      end
      
      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_create_synthetic_profile_' currentTime '.log'];
diary(logFile);

if ~(exist(DIR_INPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Input directory not found: %s\n', DIR_INPUT_NC_FILES);
   errorFlag = 1;
end

if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Output directory not found: %s\n', DIR_OUTPUT_NC_FILES);
   errorFlag = 1;
end

if ~(exist(REF_PROFILE_FILE, 'file') == 2)
   fprintf('ERROR: Reference file not found: %s\n', REF_PROFILE_FILE);
   errorFlag = 1;
end

if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   fprintf('ERROR: Log directory not found: %s\n', DIR_LOG_FILE);
   errorFlag = 1;
end

if (errorFlag == 0)
   if (~isempty(floatList))
      
      floatNum = 1;
      for idFloat = 1:length(floatList)
         g_cocs_floatNum = floatList(idFloat);
         floatDirPathName = [DIR_INPUT_NC_FILES '/' num2str(g_cocs_floatNum) '/'];
         if (exist(floatDirPathName, 'dir') == 7)
            
            fprintf('%03d/%03d %d\n', idFloat, length(floatList), g_cocs_floatNum);
            
            process_one_float(floatDirPathName, DIR_OUTPUT_NC_FILES, REF_PROFILE_FILE);
            
            floatNum = floatNum + 1;
         else
            fprintf('ERROR: No directory for float #%d\n', g_cocs_floatNum);
         end
      end
   else
      
      floatNum = 1;
      floatDirs = dir(DIR_INPUT_NC_FILES);
      for idDir = 1:length(floatDirs)
         
         floatDirName = floatDirs(idDir).name;
         floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            
            [g_cocs_floatNum, status] = str2num(floatDirName);
            if (status == 1)
               
               fprintf('%03d/%03d %d\n', floatNum, length(floatDirs)-2, g_cocs_floatNum);
               
               process_one_float(floatDirPathName, DIR_OUTPUT_NC_FILES, REF_PROFILE_FILE);
               
               floatNum = floatNum + 1;
            end
         end
      end
   end
end

diary off;

return;

% ------------------------------------------------------------------------------
% Generate a synthetic profile for a given float.
%
% SYNTAX :
%  process_one_float(a_floatDir, a_outputDir)
%
% INPUT PARAMETERS :
%   a_floatDir   : float input data directory
%   a_outputDir  : top directory of synthetic profile
%   a_refFileCdl : netCDF synthetic profile file schema
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_one_float(a_floatDir, a_outputDir, a_refFile)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


floatWmoStr = num2str(g_cocs_floatNum);

% retrieve META data
metaDataStruct = [];
if (exist([a_floatDir '/' floatWmoStr '_meta.nc'], 'file') == 2)
   metaDataStruct = get_meta_data([a_floatDir '/' floatWmoStr '_meta.nc']);
end

% create the list of available cycle numbers (from PROF files)
profileDir = [a_floatDir '/profiles'];
files = dir([profileDir '/' '*' floatWmoStr '_' '*.nc']);
cyNumList = [];
for idFile = 1:length(files)
   fileName = files(idFile).name;
   if ((fileName(1) == 'D') || (fileName(1) == 'R'))
      idF = strfind(fileName, floatWmoStr);
      cyNumStr = fileName(idF+length(floatWmoStr)+1:end-3);
      if (cyNumStr(end) == 'D')
         cyNumStr(end) = [];
      end
      cyNumList = [cyNumList str2num(cyNumStr)];
   end
end
cyNumList = unique(cyNumList);

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

% process PROF files
syntProfAll = [];
for idCy = 1:length(cyNumList)
   
   g_cocs_cycleNum = cyNumList(idCy);
%    if (g_cocs_cycleNum ~= 13)
%       continue;
%    end
   
   % process descending and ascending profiles
   for idDir = 1:2
      
      if (idDir == 1)
         g_cocs_cycleDir = 'D';
      else
         g_cocs_cycleDir = '';
      end
      
      if (~isempty(g_cocs_cycleDir))
         continue;
      end
      
      cProfFileName = '';
      bProfFileName = '';
      profDataStruct = '';
      syntProfDataStruct = '';
      if (exist([profileDir '/' sprintf('D%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         cProfFileName = sprintf('D%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
      elseif (exist([profileDir '/' sprintf('R%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         cProfFileName = sprintf('R%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
      end
      if (exist([profileDir '/' sprintf('BD%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         bProfFileName = sprintf('BD%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
      elseif (exist([profileDir '/' sprintf('BR%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         bProfFileName = sprintf('BR%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
      end
      
      % retrieve PROF data
      if (~isempty(cProfFileName))
         
         fprintf('   %02d/%02d: Float #%d Cycle #%d%c\n', ...
            idCy, length(cyNumList), g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
         
         profDataStruct = get_prof_data(cProfFileName, bProfFileName, profileDir, metaDataStruct);
      end
      
      % process PROF data
      if (~isempty(profDataStruct))
         syntProfDataStruct = process_prof_data(profDataStruct);
         
         if (~isempty(syntProfDataStruct))
            syntProfAll = [syntProfAll syntProfDataStruct];
         end
      end
      
      % create SYNTHETIC PROF file
      if (~isempty(syntProfDataStruct))
         create_mono_synthetic_profile_file(g_cocs_floatNum, syntProfDataStruct, tmpDirName, a_outputDir, a_refFile);
      end
   end
end

% if (~isempty(syntProfAll))
%    create_multi_synthetic_profile_file(g_cocs_floatNum, syntProfAll, tmpDirName, a_outputDir, a_refFile);
% end

% delete the temporary directory
remove_directory(tmpDirName);

return;

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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_meta_data(a_metaFilePathName)

% output parameters initialization
o_metaData = [];

% current float and cycle identification
global g_cocs_floatNum;


% retrieve information from META file
if ~(exist(a_metaFilePathName, 'file') == 2)
   fprintf('ERROR: Float #%d: File not found: %s\n', ...
      g_cocs_floatNum, a_metaFilePathName);
   return;
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
   fprintf('WARNING: Float #%d: Input META file (%s) format version is %s => not used\n', ...
      g_cocs_floatNum, a_metaFilePathName, formatVersion);
   return;
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

return;

% ------------------------------------------------------------------------------
% Retrieve data from PROF file.
%
% SYNTAX :
%  [o_profData] = get_prof_data(a_cProfFileName, a_bProfFileName, a_profDir, a_metaData)
%
% INPUT PARAMETERS :
%   a_cProfFileName : C PROF file name
%   a_bProfFileName : B PROF file name
%   a_profDir       : PROF file dir name
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = get_prof_data(a_cProfFileName, a_bProfFileName, a_profDir, a_metaData)

% output parameter initialization
o_profData = [];

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;
global g_decArgo_qcStrChanged;
global g_decArgo_qcStrUnused1;
global g_decArgo_qcStrUnused2;
global g_decArgo_qcStrInterpolated;
global g_decArgo_qcStrMissing;


% retrieve PROF data from C and B files
profDataTabC = [];
profDataTabB = [];
for idType= 1:2
   if (idType == 1)
      profFilePathName = [a_profDir '/' a_cProfFileName];
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, profFilePathName);
         return;
      end
   else
      if (isempty(a_bProfFileName))
         break;
      end
      profFilePathName = [a_profDir '/' a_bProfFileName];
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
      
      % set sensor associated to parameters (using PARAMETER_SENSOR meta-data)
      if (~isempty(a_metaData))
         metaParamList = cellstr(a_metaData.parameter);
         metaParamSensorList = cellstr(a_metaData.parameterSensor);
         for idParam = 1:length(profData.paramList)
            paramName = profData.paramList{idParam};
            idF = find(strcmp(paramName, metaParamList));
            profData.paramSensorList{end+1} = metaParamSensorList{idF};
         end
      end
      
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
         scientificCalibEquationTab = '';
         scientificCalibCoefficientTab = '';
         scientificCalibCommentTab = '';
         scientificCalibDateTab = '';
         % find N_PARAM index of the current parameter
         nParamId = [];
         [~, ~, nCalib, ~] = size(parameter);
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
               scientificCalibEquationTab{end+1} = deblank(scientificCalibEquation(:, nParamId, idCalib, idProf)');
               scientificCalibCoefficientTab{end+1} = deblank(scientificCalibCoefficient(:, nParamId, idCalib, idProf)');
               scientificCalibCommentTab{end+1} = deblank(scientificCalibComment(:, nParamId, idCalib, idProf)');
               scientificCalibDateTab{end+1} = deblank(scientificCalibDate(:, nParamId, idCalib, idProf)');
            end
         end
         profData.scientificCalibEquation = [profData.scientificCalibEquation {scientificCalibEquationTab}];
         profData.scientificCalibCoefficient = [profData.scientificCalibCoefficient {scientificCalibCoefficientTab}];
         profData.scientificCalibComment = [profData.scientificCalibComment {scientificCalibCommentTab}];
         profData.scientificCalibDate = [profData.scientificCalibDate {scientificCalibDateTab}];
      end
      
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
         profData.paramData = [profData.paramData profDataB.paramData];
         profData.paramDataQc = [profData.paramDataQc profDataB.paramDataQc];
         profData.paramDataAdjusted = [profData.paramDataAdjusted profDataB.paramDataAdjusted];
         profData.paramDataAdjustedQc = [profData.paramDataAdjustedQc profDataB.paramDataAdjustedQc];
         profData.paramDataAdjustedError = [profData.paramDataAdjustedError profDataB.paramDataAdjustedError];
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

% get sensor PRES offset (from CONFIG_<short_sensor_name>VerticalPressureOffset_dbar)
if (~isempty(a_metaData))
   configParameterNames = cellstr(a_metaData.configParameterName);
   launchConfigParameterNames = cellstr(a_metaData.launchConfigParameterName);
   for idProf = 1:length(profDataTab)
      
      shortSensorName = get_short_sensor_name(profDataTab(idProf).paramSensorList);
      if (~isempty(shortSensorName) && ~strcmp(shortSensorName, 'Ctd'))
         
         vertPresOffset = 99999;
         idPVertPresOffset = find(strcmp(['CONFIG_' shortSensorName 'VerticalPressureOffset_dbar'], configParameterNames));
         if (~isempty(idPVertPresOffset))
            idMission = find(a_metaData.configMissionNumber == profDataTab(idProf).configMissionNumber);
            vertPresOffset = a_metaData.configParameterValue(idMission, idPVertPresOffset);
         else
            idPVertPresOffset = find(strcmp(['CONFIG_' shortSensorName 'VerticalPressureOffset_dbar'], launchConfigParameterNames));
            if (~isempty(idPVertPresOffset))
               vertPresOffset = a_metaData.launchConfigParameterValue(idPVertPresOffset);
            end
         end
         
         if (vertPresOffset ~= 99999)
            profDataTab(idProf).verticalPresOffset = vertPresOffset;
         end
      end
   end
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
               g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, ...
               paramName, idParamOld, idParam);
         end
      end
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
               break;
            end
         end
      end
   end
   if (idRef > 0)
      idToShift = find((sortedId > sortedId(idRef)) & (sortedId > 0));
      sortedId(idToShift) = sortedId(idToShift) + 1;
      sortedId(idProf) = sortedId(idRef) + 1;
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' unpumped profile #%d cannot be assocated to existing one => data ignored\n', ...
         g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, ...
         idProf);
   end
end
sortedId(find(sortedId < 0)) = []; % in case of ERROR
profDataTab = profDataTab(sortedId);

% in case of common parameters (between profiles) set to FillValue the data of
% the low priority profiles
% BE CAREFUL: this should be done considering the range of the data (not the
% individual measurements)
% to store information on parameters and associated range of data, i.e.
% param name / range min / range max
paramRangeInfoList = [];
for idProf = 1:length(profDataTab)
   paramList = profDataTab(idProf).paramList;
   idPres = find(strcmp('PRES', paramList));
   paramList(idPres) = [];
   for idParam = 1:length(paramList)
      
      paramName = paramList{idParam};
      paramInfo = get_netcdf_param_attributes(paramName);
      
      % get paramId
      idParam = find(strcmp(paramName, paramList)) + 1;
      
      % set to FillValue these parameter data (when already in higher priority
      % profiles)
      if (~isempty(paramRangeInfoList))
         idFList = find(strcmp(paramName, paramRangeInfoList(:, 1)));
         if (~isempty(idFList))
            for idP = idFList'
               rangeMin = paramRangeInfoList{idP, 2};
               rangeMax = paramRangeInfoList{idP, 3};
               
               idSetFillVal = find( ...
                  (profDataTab(idProf).paramDataQc(:, idParam) ~= g_decArgo_qcStrDef) & ...
                  (profDataTab(idProf).paramDataQc(:, idParam) ~= g_decArgo_qcStrMissing) & ...
                  (profDataTab(idProf).paramData(:, 1) >= rangeMin) & ...
                  (profDataTab(idProf).paramData(:, 1) <= rangeMax));
               
               profDataTab(idProf).paramData(idSetFillVal, idParam) = paramInfo.fillValue;
               profDataTab(idProf).paramDataQc(idSetFillVal, idParam) = g_decArgo_qcStrMissing;
            end
         end
      end
      
      % range of parameter data
      idOk = find((profDataTab(idProf).paramDataQc(:, idParam) ~= g_decArgo_qcStrDef) & ...
         (profDataTab(idProf).paramDataQc(:, idParam) ~= g_decArgo_qcStrMissing));
      if (~isempty(idOk))
         minPresParam = min(profDataTab(idProf).paramData(idOk, 1));
         maxPresParam = max(profDataTab(idProf).paramData(idOk, 1));
         paramRangeInfoList = [paramRangeInfoList; ...
            {paramName} minPresParam maxPresParam];
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

% output parameter
o_profData = profDataTab;

return;

% ------------------------------------------------------------------------------
% Process PROF (and TRAJ) data to generate synthetic profile data.
%
% SYNTAX :
%  [o_syntProfData] = process_prof_data(a_profData)
%
% INPUT PARAMETERS :
%   a_profData : data retrieved from PROF file(s)
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_syntProfData] = process_prof_data(a_profData)

% output parameters initialization
o_syntProfData = [];

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrGood;
global g_decArgo_qcStrProbablyGood;
global g_decArgo_qcStrCorrectable;
global g_decArgo_qcStrBad;
global g_decArgo_qcStrChanged;
global g_decArgo_qcStrUnused1;
global g_decArgo_qcStrUnused2;
global g_decArgo_qcStrInterpolated;
global g_decArgo_qcStrMissing;

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% to print data after each processing step
global g_cocs_printCsv;


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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #1: gather all profile data in the same array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% uniformisation of parameter list
paramList = [];
paramFillValue = [];
paramDataMode = [];
scientificCalibEquation = [];
scientificCalibCoefficient = [];
scientificCalibComment = [];
scientificCalibDate = [];
for idProf = 1:length(a_profData)
   profParamList = a_profData(idProf).paramList;
   for idParam = 1:length(profParamList)
      if (~ismember(profParamList{idParam}, paramList))
         paramList = [paramList profParamList(idParam)];
         paramInfo = get_netcdf_param_attributes(profParamList{idParam});
         paramFillValue = [paramFillValue paramInfo.fillValue];
         paramDataMode = [paramDataMode a_profData(idProf).paramDataMode(idParam)];
         scientificCalibEquation = [scientificCalibEquation a_profData(idProf).scientificCalibEquation(idParam)];
         scientificCalibCoefficient = [scientificCalibCoefficient a_profData(idProf).scientificCalibCoefficient(idParam)];
         scientificCalibComment = [scientificCalibComment a_profData(idProf).scientificCalibComment(idParam)];
         scientificCalibDate = [scientificCalibDate a_profData(idProf).scientificCalibDate(idParam)];
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
   
   % shift PRES axis from sensor verticalPresOffset value
   idNoFill = find(paramData(:, 1) ~= paramFillValue(1));
   paramData(idNoFill, 1) = paramData(idNoFill, 1) + profData.verticalPresOffset;
   
   paramDataAdjusted(:, profParamId) = profData.paramDataAdjusted;
   paramDataAdjustedQc(:, profParamId) = profData.paramDataAdjustedQc;
   paramDataAdjustedError(:, profParamId) = profData.paramDataAdjustedError;
   
   % shift PRES axis from sensor verticalPresOffset value
   idNoFill = find(paramDataAdjusted(:, 1) ~= paramFillValue(1));
   paramDataAdjusted(idNoFill, 1) = paramDataAdjusted(idNoFill, 1) + profData.verticalPresOffset;
   
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

presAxisFlag = [];

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
   
   startLev = startLev + profNbLev;
end

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      paramData, paramDataQc, [], paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step1');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #2: keep only levels with PRES_QC ~= '4' or '9'
% then sort PRES levels in ascending order
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% keep only levels with PRES_QC/PRES_ADJUSTED_QC ~= '4'
% note that PRES set to FillVale (missing pressures) have a QC = '9' (missing
% value), so these levels are also removed by this step
idDel = find((paramDataQc(:, 1) == g_decArgo_qcStrBad) | (paramDataQc(:, 1) == g_decArgo_qcStrMissing));
paramData(idDel, :) = [];
paramDataQc(idDel, :) = [];
paramDataAdjusted(idDel, :) = [];
paramDataAdjustedQc(idDel, :) = [];
paramDataAdjustedError(idDel, :) = [];

% sort PRES levels in ascending order
[~ , idSort] = sort(paramData(:, 1));
paramData = paramData(idSort, :);
paramDataQc = paramDataQc(idSort, :);
paramDataAdjusted = paramDataAdjusted(idSort, :);
paramDataAdjustedQc = paramDataAdjustedQc(idSort, :);
paramDataAdjustedError = paramDataAdjustedError(idSort, :);

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      paramData, paramDataQc, [], paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step2');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #3: align measurements on identical PRES/PRES_ADJUSTED levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

refParamData = paramData;

% round PRES data to the nearest mbar
refParamPres = int32(refParamData(:, 1)*100);

if (length(refParamPres) ~= length(unique(refParamPres)))
   
   % there are duplicate pressures
   paramMeasFillValue = paramFillValue(2:end);
   pres = refParamPres;
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
   end
   
   % remove duplicated levels
   paramData(idDel, :) = [];
   paramDataQc(idDel, :) = [];
   paramDataAdjusted(idDel, :) = [];
   paramDataAdjustedQc(idDel, :) = [];
   paramDataAdjustedError(idDel, :) = [];
end

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      paramData, paramDataQc, [], paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step3');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #4: create synthetic profile PRES axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% algorithm from Henry BITTIG (bittig@obs-vlfr.fr)on 26/01/2018 09:37

% compute PRES up and down differences between measurements and assign the min
% value of the current measurement level
paramPres = paramData(:, 1);
paramPresDiffUp = repmat(realmax('single'), size(paramData));
paramPresDiffDown = repmat(realmax('single'), size(paramData));
paramPresDiff = repmat(realmax('single'), size(paramData));
for idParam = 4:size(paramData, 2) % i.e. ignore T and S
   % sampled levels for this parameter
   idSampled = find(paramDataQc(:, idParam) ~= g_decArgo_qcStrMissing);
   paramPresDiffDown(idSampled(1:end-1), idParam) = diff(paramPres(idSampled));
   paramPresDiffUp(idSampled(2:end), idParam) = diff(paramPres(idSampled));
   paramPresDiff(idSampled, idParam) = ...
      min(paramPresDiffDown(idSampled, idParam), paramPresDiffUp(idSampled, idParam));
end

% round PRES data to the nearest mbar
paramPres = int32(paramPres*100);
paramPresDiff = int32(paramPresDiff(:, 4:end)*100);
paramPresDiffFillValue = intmax('int32');

% select synthetic profile PRES axis levels
idSPLev = [];
idLev = find(min(paramPresDiff, [], 2) ~= paramPresDiffFillValue, 1, 'last');
while (~isempty(idLev))
   
   % add current level to synthetic axis
   idSPLev = [idSPLev idLev];
      
   % get pressures that are within current level (included) and probably next level-min(dPRES) (excluded)
   interLevs = find((min(paramPresDiff, [], 2) ~= paramPresDiffFillValue) & ...
      (paramPres > (paramPres(idLev) - min(paramPresDiff(idLev, :)))) & ...
      (paramPres <= paramPres(idLev)));
   
   % check if any of the intermittent levels has such a small dPRES, that
   % there will be a second observation within the current level-min(dPRES) "jump"
   if (~isempty(interLevs))
      
      % check if any intermittent levels has more than one observation,
      % i.e. a denser sampling interval
      obsPresence = (paramPresDiff(interLevs, :) ~= paramPresDiffFillValue);
      if (any(sum(obsPresence, 1) > 1))
         
         % go to deepest upres that features a second observation in the
         % same N_PROF: sum #obs from bottom in each N_PROF, get max in each
         % line (upres), and jump to (deepest) line that has > 1
         
         sumObs = flipud(cumsum(flipud(obsPresence), 1));
         maxSumObs = max(sumObs, [], 2);
         idLev = interLevs(find(maxSumObs > 1, 1, 'last'));
      else
         
         % jump by at least current level+min(dPRES)
         idLev = find((min(paramPresDiff, [], 2) ~= paramPresDiffFillValue) & ...
            (paramPres <= (paramPres(idLev) - min(paramPresDiff(idLev,:)))), 1, 'last');
      end
   else
      
      % jump by at least current level+min(dPRES)
      idLev = find((min(paramPresDiff, [], 2) ~= paramPresDiffFillValue) & ...
         (paramPres <= (paramPres(idLev) - min(paramPresDiff(idLev,:)))), 1, 'last');
   end
end

idSPLev = sort(idSPLev);

presAxisFlag = zeros(size(paramData, 1), 1);
presAxisFlag(idSPLev) = 1;

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      [paramData(:, 1:3) single(paramPresDiff)/100], paramDataQc, [], paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step8');
end

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      paramData, paramDataQc, [], paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step9');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #4: interpolate/duplicate measurements on missing values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

refPresParamData = paramData(:, 1); % PRES (not PRES_ADJUSTED!) will be used to interpolate <PARAM>, <PARAM>_ADJUSTED and <PARAM>_ADJUSTED_ERROR on synthetic profile PRES axis

% create a paramDataAdjustedErrorQc for the need of the algorithm
paramDataAdjustedErrorQc = repmat(g_decArgo_qcStrMissing, size(paramData));
for idParam = 1:size(paramData, 2)
   idNoFill = find(paramDataAdjustedError(:, idParam) ~= paramFillValue(idParam));
   paramDataAdjustedErrorQc(idNoFill) = g_decArgo_qcStrNoQc;
end

for idLoop = 1:3 % 3 loops: <PARAM>, <PARAM>_ADJUSTED and <PARAM>_ADJUSTED_ERROR
   
   if (idLoop == 1)
      data = paramData;
      dataQc = paramDataQc;
      startParamId = 2; % i.e. ignore PRES
   elseif (idLoop == 2)
      data = paramDataAdjusted;
      dataQc = paramDataAdjustedQc;
      startParamId = 1; % i.e. process PRES_ADJUSTED
   elseif (idLoop == 3)
      data = paramDataAdjustedError;
      dataQc = paramDataAdjustedErrorQc;
      startParamId = 1; % i.e. process PRES_ADJUSTED_ERROR
   end
   
   for idParam = startParamId:size(paramData, 2)
      
      % interpolate data
      idToInterp = find(data(idSPLev, idParam) == paramFillValue(idParam));
      idToInterp = idSPLev(idToInterp);
      idBase = find(data(:, idParam) ~= paramFillValue(idParam));
      if (length(idBase) > 1)
         interpData = interp1(refPresParamData(idBase), data(idBase, idParam), refPresParamData(idToInterp), 'linear');
         idSet = find(~isnan(interpData));
         data(idToInterp(idSet), idParam) = interpData(idSet);
         dataQc(idToInterp(idSet), idParam) = g_decArgo_qcStrInterpolated;
      end
      
      % duplicate data
      idToDuplicate = find(data(idSPLev, idParam) == paramFillValue(idParam));
      idToDuplicate = idSPLev(idToDuplicate);
      idBaseFirst = find(data(:, idParam) ~= paramFillValue(idParam), 1, 'first');
      idBaseLast = find(data(:, idParam) ~= paramFillValue(idParam), 1, 'last');
      if (~isempty(idToDuplicate) && ~isempty(idBaseFirst) && ~isempty(idBaseLast))
         idFirst = find(idToDuplicate < idBaseFirst);
         data(idToDuplicate(idFirst), idParam) = data(idBaseFirst, idParam);
         dataQc(idToDuplicate(idFirst), idParam) = g_decArgo_qcStrInterpolated;
         
         idLast = find(idToDuplicate > idBaseLast);
         data(idToDuplicate(idLast), idParam) = data(idBaseLast, idParam);
         dataQc(idToDuplicate(idLast), idParam) = g_decArgo_qcStrInterpolated;
      end
   end
   
   if (idLoop == 1)
      paramData = data;
      paramDataQc = dataQc;
   elseif (idLoop == 2)
      paramDataAdjusted = data;
      paramDataAdjustedQc = dataQc;
   elseif (idLoop == 3)
      paramDataAdjustedError = data;
      paramDataAdjustedErrorQc = dataQc;
   end
   
   clear data;
   clear dataQc;
end

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      paramData, paramDataQc, [], paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step10');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #5: for each measurements, keep only nearest measurement on the
%          synthetic profile PRES axis
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% round PRES data to the nearest mbar
paramPres = int32(ones(size(paramData, 1), 1))*intmax('int32');
idNoFill = find(paramData(:, 1) ~= paramFillValue(1));
paramPres(idNoFill) = int32(paramData(idNoFill, 1)*100);

paramDataDPres = int32(ones(size(paramData)))*intmax('int32');
paramDataAdjustedDPres = int32(ones(size(paramData)))*intmax('int32');
paramDataAdjustedErrorDPres = int32(ones(size(paramData)))*intmax('int32');

for idLoop = 1:3 % 3 loops: <PARAM>, <PARAM>_ADJUSTED and <PARAM>_ADJUSTED_ERROR
   
   if (idLoop == 1)
      data = paramData;
      dataQc = paramDataQc;
      dataDPres = paramDataDPres;
      startParamId = 2; % i.e. ignore PRES
   elseif (idLoop == 2)
      data = paramDataAdjusted;
      dataQc = paramDataAdjustedQc;
      dataDPres = paramDataAdjustedDPres;
      startParamId = 1; % i.e. process PRES_ADJUSTED
   elseif (idLoop == 3)
      data = paramDataAdjustedError;
      dataQc = paramDataAdjustedErrorQc;
      dataDPres = paramDataAdjustedErrorDPres;
      startParamId = 1; % i.e. process PRES_ADJUSTED_ERROR
   end
   
   for idParam = startParamId:size(paramData, 2)
      
      dataNew = ones(size(data(:, idParam)))*paramFillValue(idParam);
      dataNewQc = repmat(g_decArgo_qcStrMissing, size(dataQc(:, idParam)));
      dataOriQc = dataQc(:, idParam);
      
      % set QC of interpolated/extrapolated variables
      idVal = find((data(:, idParam) ~= paramFillValue(idParam)) & ...
         (dataQc(:, idParam) ~= g_decArgo_qcStrInterpolated));
      idInterpol = find(dataQc(:, idParam) == g_decArgo_qcStrInterpolated);
      for idLev = idInterpol'
         idUp = find(idVal < idLev, 1, 'last');
         idUp = idVal(idUp);
         idDown = find(idVal > idLev, 1, 'first');
         idDown = idVal(idDown);
         if (~isempty(idUp) && ~isempty(idDown))
            dataOriQc(idLev) = max(dataQc(idUp, idParam), dataQc(idDown, idParam));
         elseif (~isempty(idDown))
            dataOriQc(idLev) = dataQc(idDown, idParam);
         elseif (~isempty(idUp))
            dataOriQc(idLev) = dataQc(idUp, idParam);
         end
      end
      
      % duplicate kept measurements and compute associated <PARAM>_dPRES
      idVal = find((data(:, idParam) ~= paramFillValue(idParam)) & ...
         (dataQc(:, idParam) ~= g_decArgo_qcStrInterpolated));
      for idLev = idVal'
         
         idUp = find(idSPLev <= idLev, 1, 'last');
         idUp = idSPLev(idUp);
         idDown = find(idSPLev >= idLev, 1, 'first');
         idDown = idSPLev(idDown);
         
         if (~isempty(idUp) && ~isempty(idDown))
            if (idUp == idLev)
               % measurement on the synthetic profile PRES axis
               if (dataDPres(idLev, idParam) ~= 0)
                  dataNew(idLev) = data(idLev, idParam);
                  dataNewQc(idLev) = dataOriQc(idLev);
                  dataDPres(idLev, idParam) = 0;
               end
            else
               % measurement not on the synthetic profile PRES axis
               if ((paramPres(idDown)-paramPres(idLev)) < (paramPres(idLev)-paramPres(idUp)))
                  % the 'down' value should be kept
                  if (abs(paramPres(idLev) - paramPres(idDown)) < abs(dataDPres(idDown, idParam)))
                     dataNew(idDown) = data(idDown, idParam);
                     dataNewQc(idDown) = dataOriQc(idDown);
                     dataDPres(idDown, idParam) = paramPres(idLev) - paramPres(idDown);
                  end
               elseif ((paramPres(idDown)-paramPres(idLev)) > (paramPres(idLev)-paramPres(idUp)))
                  % the 'up' value should be kept
                  if (abs(paramPres(idLev) - paramPres(idUp)) <= abs(dataDPres(idUp, idParam))) % '<=' so that dataDPres is updated with a > 0 value
                     dataNew(idUp) = data(idUp, idParam);
                     dataNewQc(idUp) = dataOriQc(idUp);
                     dataDPres(idUp, idParam) = paramPres(idLev) - paramPres(idUp);
                  end
               else
                  % both ('up' and 'down') values should be kept
                  if (abs(paramPres(idLev) - paramPres(idUp)) <= abs(dataDPres(idUp, idParam))) % '<=' so that dataDPres is updated with a > 0 value
                     dataNew(idUp) = data(idUp, idParam);
                     dataNewQc(idUp) = dataOriQc(idUp);
                     dataDPres(idUp, idParam) = paramPres(idLev) - paramPres(idUp);
                  end
                  if (abs(paramPres(idLev) - paramPres(idDown)) < abs(dataDPres(idDown, idParam)))
                     dataNew(idDown) = data(idDown, idParam);
                     dataNewQc(idDown) = dataOriQc(idDown);
                     dataDPres(idDown, idParam) = paramPres(idLev) - paramPres(idDown);
                  end
               end
            end
         elseif (~isempty(idDown))
            if (idDown == idLev)
               % measurement on the synthetic profile PRES axis
               if (dataDPres(idLev, idParam) ~= 0)
                  dataNew(idLev) = data(idLev, idParam);
                  dataNewQc(idLev) = dataOriQc(idLev);
                  dataDPres(idLev, idParam) = 0;
               end
            else
               % measurement not on the synthetic profile PRES axis
               if (abs(paramPres(idLev) - paramPres(idDown)) <= abs(dataDPres(idDown, idParam))) % '<=' so that dataDPres is updated with a > 0 value
                  dataNew(idDown) = data(idDown, idParam);
                  dataNewQc(idDown) = dataOriQc(idDown);
                  dataDPres(idDown, idParam) = paramPres(idLev) - paramPres(idDown);
               end
            end
         elseif (~isempty(idUp))
            if (idUp == idLev)
               % measurement on the synthetic profile PRES axis
               if (dataDPres(idLev, idParam) ~= 0)
                  dataNew(idLev) = data(idLev, idParam);
                  dataNewQc(idLev) = dataOriQc(idLev);
                  dataDPres(idLev, idParam) = 0;
               end
            else
               % measurement not on the synthetic profile PRES axis
               if (abs(paramPres(idLev) - paramPres(idUp)) <= abs(dataDPres(idUp, idParam))) % '<=' so that dataDPres is updated with a > 0 value
                  dataNew(idUp) = data(idUp, idParam);
                  dataNewQc(idUp) = dataOriQc(idUp);
                  dataDPres(idUp, idParam) = paramPres(idLev) - paramPres(idUp);
               end
            end
         end
      end
      
      % keep TS data on the synthetic profile PRES axis
      % keep 'simple gap' BGC data on the synthetic profile PRES axis
      idVal = find((data(:, idParam) ~= paramFillValue(idParam)) & ...
         (dataQc(:, idParam) ~= g_decArgo_qcStrInterpolated));
      spFlag = zeros(size(dataNew));
      spFlag(dataNewQc ~= g_decArgo_qcStrMissing) = 1;
      for idLev = idSPLev
         
         if (dataNewQc(idLev) == g_decArgo_qcStrMissing)
            if (dataQc(idLev, idParam) ~= g_decArgo_qcStrMissing)
               
               if (idParam < 4)
                  
                  % TS data
                  dataNew(idLev) = data(idLev, idParam);
                  dataNewQc(idLev) = dataQc(idLev, idParam);
                  
                  idUp = find(idVal < idLev, 1, 'last');
                  idUp = idVal(idUp);
                  idDown = find(idVal > idLev, 1, 'first');
                  idDown = idVal(idDown);
                  if (~isempty(idUp) && ~isempty(idDown))
                     if ((paramPres(idDown)-paramPres(idLev)) < (paramPres(idLev)-paramPres(idUp)))
                        dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
                     elseif ((paramPres(idDown)-paramPres(idLev)) > (paramPres(idLev)-paramPres(idUp)))
                        dataDPres(idLev, idParam) = paramPres(idUp) - paramPres(idLev);
                     else
                        dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
                     end
                  elseif (~isempty(idDown))
                     dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
                  elseif (~isempty(idUp))
                     dataDPres(idLev, idParam) = paramPres(idUp) - paramPres(idLev);
                  end
               else
                  
                  % BGC data
                  
                  % check if the level should be kept
                  keepLevel = 0;
                  idSpUp = find(idSPLev < idLev);
                  idSpDown = find(idSPLev > idLev);
                  if (~isempty(idSpUp) && ~isempty(idSpDown))
                     if ((length(idSpUp) > 2) && (length(idSpDown) < length(idSPLev)-1))
                        if ((length(idSpUp) > 1) && (length(idSpDown) > 1))
                           idSpUp = idSPLev(idSpUp);
                           idSpDown = idSPLev(idSpDown);
                           if (sum(spFlag([idSpUp(end-1:end) idSpDown(1:2)])) == 4)
                              keepLevel = 1;
                           end
                        end
                     elseif (length(idSpUp) == 1)
                        if (length(idSpDown) > 1)
                           idSpUp = idSPLev(idSpUp);
                           idSpDown = idSPLev(idSpDown);
                           if (sum(spFlag([idSpUp(end) idSpDown(1:2)])) == 3)
                              keepLevel = 1;
                           end
                        end
                     elseif (length(idSpDown) == length(idSPLev)-1)
                        if (length(idSpUp) > 1)
                           idSpUp = idSPLev(idSpUp);
                           idSpDown = idSPLev(idSpDown);
                           if (sum(spFlag([idSpUp(end-1:end) idSpDown(1)])) == 3)
                              keepLevel = 1;
                           end
                        end
                     end
                  else
                     if (idLev == idSPLev(1))
                        % first sample
                        if (length(idSpDown) > 1)
                           idSpDown = idSPLev(idSpDown);
                           if (sum(spFlag(idSpDown(1:2))) == 2)
                              keepLevel = 1;
                           end
                        end
                     elseif (idLev == idSPLev(end))
                        % last sample
                        if (length(idSpUp) > 1)
                           idSpUp = idSPLev(idSpUp);
                           if (sum(spFlag(idSpUp(end-1:end))) == 2)
                              keepLevel = 1;
                           end
                        end
                     end
                  end
                  
                  if (keepLevel == 1)
                     
                     idUp = find(idVal <= idLev, 1, 'last');
                     idUp = idVal(idUp);
                     idDown = find(idVal >= idLev, 1, 'first');
                     idDown = idVal(idDown);
                     
                     if ((idLev > 1) && (idLev < length(spFlag)))
                        
                        dataNew(idLev) = data(idLev, idParam);
                        dataNewQc(idLev) = dataQc(idLev, idParam);
                        
                        if (~isempty(idUp) && ~isempty(idDown))
                           if ((paramPres(idDown)-paramPres(idLev)) < (paramPres(idLev)-paramPres(idUp)))
                              dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
                           elseif ((paramPres(idDown)-paramPres(idLev)) > (paramPres(idLev)-paramPres(idUp)))
                              dataDPres(idLev, idParam) = paramPres(idUp) - paramPres(idLev);
                           else
                              dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
                           end
                        elseif (~isempty(idDown))
                           dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
                        elseif (~isempty(idUp))
                           dataDPres(idLev, idParam) = paramPres(idUp) - paramPres(idLev);
                        end
                     elseif (idLev == 1)
                        
                        % first sample
                        if (paramPres(idDown(1))-paramPres(idLev) <= 200) % i.e. 2 dbar
                           dataNew(idLev) = data(idDown(1), idParam);
                           dataNewQc(idLev) = g_decArgo_qcStrInterpolated;
                           dataDPres(idLev, idParam) = paramPres(idDown(1)) - paramPres(idLev);
                        end
                     elseif (idLev == length(spFlag))
                        
                        % last sample
                        if (paramPres(idLev)-paramPres(idUp(end)) <= 200) % i.e. 2 dbar
                           dataNew(idLev) = data(idUp(end), idParam);
                           dataNewQc(idLev) = g_decArgo_qcStrInterpolated;
                           dataDPres(idLev, idParam) = paramPres(idUp(end)) - paramPres(idLev);
                        end
                     end
                  end
               end
            end
         end
      end
      
      % a final loop to replace negative dataDPres values by positive ones
      % when both can fit
      idVal = find((data(:, idParam) ~= paramFillValue(idParam)) & ...
         (dataQc(:, idParam) ~= g_decArgo_qcStrInterpolated));
      for idLev = idSPLev
         
         idUp = find(idVal < idLev, 1, 'last');
         idUp = idVal(idUp);
         idDown = find(idVal > idLev, 1, 'first');
         idDown = idVal(idDown);
         if (~isempty(idUp) && ~isempty(idDown))
            if ((paramPres(idDown)-paramPres(idLev)) == (paramPres(idLev)-paramPres(idUp)))
               if (dataDPres(idLev, idParam) < 0)
                  dataDPres(idLev, idParam) = paramPres(idDown) - paramPres(idLev);
               end
            end
         end
      end
      
      data(:, idParam) = dataNew;
      dataQc(:, idParam) = dataNewQc;
      
      clear dataNew;
      clear dataNewQc;
      clear dataOriQc;
   end
   
   if (idLoop == 1)
      paramData = data;
      paramDataQc = dataQc;
      paramDataDPres = dataDPres;
   elseif (idLoop == 2)
      paramDataAdjusted = data;
      paramDataAdjustedQc = dataQc;
      paramDataAdjustedDPres = dataDPres;
   elseif (idLoop == 3)
      paramDataAdjustedError = data;
      paramDataAdjustedErrorQc = dataQc;
      paramDataAdjustedErrorDPres = dataDPres;
   end
   
   clear data;
   clear dataQc;
   clear dataDPres;
end   

paramDataDPres2 = ones(size(paramData))*paramFillValue(1);
idNoFill = find(paramDataDPres ~= intmax('int32'));
paramDataDPres2(idNoFill) = single(paramDataDPres(idNoFill))/100;
paramDataDPres = paramDataDPres2;

if (g_cocs_printCsv)
   print_profile_in_csv(paramList, paramDataMode, paramFillValue, ...
      presAxisFlag, ...
      paramData, paramDataQc, paramDataDPres, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step11');
end

% update output structure
o_syntProfData.paramList = paramList;
o_syntProfData.paramDataMode = paramDataMode;

o_syntProfData.paramData = paramData;
o_syntProfData.paramDataQc = paramDataQc;
o_syntProfData.paramDataDPres = paramDataDPres;
o_syntProfData.paramDataAdjusted = paramDataAdjusted;
o_syntProfData.paramDataAdjustedQc = paramDataAdjustedQc;
o_syntProfData.paramDataAdjustedError = paramDataAdjustedError;

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
% Create mono synthetic profile NetCDF file.
%
% SYNTAX :
%  create_mono_synthetic_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_mono_synthetic_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


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
movefile(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/profiles/' outputFileName]);

return;

% ------------------------------------------------------------------------------
% Fill mono synthetic profile NetCDF file.
%
% SYNTAX :
%  fill_synthetic_mono_profile_file(a_fileName, a_profData)
%
% INPUT PARAMETERS :
%   a_fileName : mono synthetic profile NetCDF file
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
%   01/11/2018 - RNU - creation
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
% if (any(a_profData.paramDataMode == 'D'))
%    valueStr = 'D';
% elseif (any(a_profData.paramDataMode == 'A'))
%    valueStr = 'A';
% else
%    valueStr = 'R';
% end
% netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'), 0, length(valueStr), valueStr);
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
% Create multi synthetic profile NetCDF file.
%
% SYNTAX :
%  create_multi_synthetic_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function create_multi_synthetic_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)


% create the output file name
if (any([a_profData.paramDataMode] == 'D'))
   modeCode = 'D';
else
   modeCode = 'R';
end
outputFileName = ['S' num2str(a_floatWmo) '_prof.nc'];
outputFilePathName = [a_tmpDir '/' outputFileName];

% retrieve the synthetic profile file schema
outputFileSchema = ncinfo(a_refFile);

% compute file dimensions
nProfDim = length(a_profData);
nParamDim = 0;
nLevelsDim = 0;
nCalibDim = 0;
for idProf = 1:length(a_profData)
   profData = a_profData(idProf);
   nParamDim = max(nParamDim, size(profData.paramData, 2));
   nLevelsDim = max(nLevelsDim, size(profData.paramData, 1));
   nCalibDimFile = 1;
   for idParam = 1:length(profData.scientificCalibEquation)
      scientificCalibEquation = profData.scientificCalibEquation{idParam};
      nCalibDim = max(nCalibDimFile, length(scientificCalibEquation));
   end
   nCalibDim = max(nCalibDim, nCalibDim);
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
fill_synthetic_multi_profile_file(outputFilePathName, a_profData);

% update output file
movefile(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/' outputFileName]);

return;

% ------------------------------------------------------------------------------
% Fill multi synthetic profile NetCDF file.
%
% SYNTAX :
%  fill_synthetic_multi_profile_file(a_fileName, a_profData)
%
% INPUT PARAMETERS :
%   a_fileName : multi synthetic profile NetCDF file
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function fill_synthetic_multi_profile_file(a_fileName, a_profData)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocs_ncCreateSyntheticProfileVersion;


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
for idProf = 1:length(a_profData)
   
   profData = a_profData(idProf);
   paramList = profData.paramList;
   
   % global quality of PARAM profile
   for idParam = 1:length(paramList)
      paramName = paramList{idParam};
      profParamQcName = ['PROFILE_' paramName '_QC'];
      
      if (~var_is_present_dec_argo(fCdf, profParamQcName))
         profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
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
         
         netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
      end
      
      % parameter adjusted variable and attributes
      paramAdjName = [paramName '_ADJUSTED'];
      if (~var_is_present_dec_argo(fCdf, paramAdjName))
         
         paramAdjVarId = netcdf.defVar(fCdf, paramAdjName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         
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
         
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
      end
      
      % parameter adjusted error variable and attributes
      paramAdjErrName = [paramName '_ADJUSTED_ERROR'];
      if (~var_is_present_dec_argo(fCdf, paramAdjErrName))
         
         paramAdjErrVarId = netcdf.defVar(fCdf, paramAdjErrName, paramInfo.paramNcType, fliplr([nProfDimId nLevelsDimId]));
         
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
   %    if (any(profData.paramDataMode == 'D'))
   %       valueStr = 'D';
   %    elseif (any(profData.paramDataMode == 'A'))
   %       valueStr = 'A';
   %    else
   %       valueStr = 'R';
   %    end
   %    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'), profPos, length(valueStr), valueStr);
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
      paramDataAdj = profData.paramDataAdjusted(:, idParam);
      paramDataAdjQc = profData.paramDataAdjustedQc(:, idParam);
      paramDataAdjErr = profData.paramDataAdjustedError(:, idParam);
      
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

% % ------------------------------------------------------------------------------
% % Get attribute data from variable name and attribute in a
% % {var_name}/{var_att}/{att_data} list.
% %
% % SYNTAX :
% %  [o_dataValues] = get_att_from_name(a_varName, a_attName, a_dataList)
% %
% % INPUT PARAMETERS :
% %   a_varName : name of the variable
% %   a_attName : name of the attribute
% %   a_dataList : {var_name}/{var_att}/{att_data} list
% %
% % OUTPUT PARAMETERS :
% %   o_dataValues : concerned data
% %
% % EXAMPLES :
% %
% % SEE ALSO :
% % AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% % ------------------------------------------------------------------------------
% % RELEASES :
% %   01/11/2018 - RNU - creation
% % ------------------------------------------------------------------------------
function [o_shortSensorName] = get_short_sensor_name(a_paramSensorList)

% output parameters initialization
o_shortSensorName = [];

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


sensor2shortNameList = [ ...
   {'CTD_'} {'Ctd'}; ...
   {'DOXY'} {'Optode'}; ...
   {'RADIOMETER_'} {'Ocr'}; ...
   {'BACKSCATTERINGMETER_'} {'Eco'}; ...
   {'FLUOROMETER_'} {'Eco'}; ...
   {'TRANSMISSOMETER_CP'} {'Crover'}; ...
   {'SPECTROPHOTOMETER_NITRATE'} {'Suna'}; ...
   {'TRANSISTOR_PH,'} {'Sfet'}];

% remove sensor 'CTD_PRES' from the list
idDel = find(strncmp('CTD_PRES', a_paramSensorList, length('CTD_PRES')) == 1, 1);
a_paramSensorList(idDel) = [];

% check the remaning sensors
for idL = 1:size(sensor2shortNameList, 1)
   idF = cellfun(@(x) strfind(x, sensor2shortNameList{idL, 1}), a_paramSensorList, 'UniformOutput', 0);
   idF = find(~cellfun(@isempty, idF) == 1);
   if (~isempty(idF))
      o_shortSensorName = sensor2shortNameList{idL, 2};
      break;
   end
end

if (isempty(o_shortSensorName))
   fprintf('WARNING: Float #%d Cycle #%d%c: unable to retrieve ''short_sensor_name'' from parameter sensor list => CONFIG_<short_sensor_name>VerticalPressureOffset_dbar set to 0 for this sensor\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
end

return;

% % ------------------------------------------------------------------------------
% % Print synthetic profile data in a CSV file.
% %
% % SYNTAX :
% %  print_profile_in_csv(a_paramlist, a_paramDataMode, a_juldDataMode, ...
% %    a_samplingCode, a_juld, a_juldQc, a_juldAdj, a_juldAdjQc, ...
% %    a_paramData, a_paramDataQc, a_paramDataAdjusted, a_paramDataAdjustedQc, a_paramDataAdjustedError, ...
% %    a_comment)
% %
% % INPUT PARAMETERS :
% %   a_paramlist              : list of parameters
% %   a_paramDataMode          : list of parameter data modes
% %   a_juldDataMode           : data mode of JULD_LEVEL parameter
% %   a_samplingCode           : SAMPLING_CODE data
% %   a_juld                   : JULD_LEVEL data
% %   a_juldQc                 : JULD_LEVEL_QC data
% %   a_juldAdj                : JULD_LEVEL_ADJUSTED data
% %   a_juldAdjQc              : JULD_LEVEL_ADJUSTED_QC data
% %   a_paramData              : PARAM data
% %   a_paramDataQc            : PARAM_QC data
% %   a_paramDataAdjusted      : PARAM_ADJUSTED data
% %   a_paramDataAdjustedQc    : PARAM_ADJUSTED_QC data
% %   a_paramDataAdjustedError : PARAM_ADJUSTED_QC data
% %   a_comment                : comment to add to the CSV file name
% %
% % OUTPUT PARAMETERS :
% %
% % EXAMPLES :
% %
% % SEE ALSO :
% % AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% % ------------------------------------------------------------------------------
% % RELEASES :
% %   01/11/2018 - RNU - creation
% % ------------------------------------------------------------------------------
function print_profile_in_csv(a_paramlist, a_paramDataMode, a_paramFillValue, ...
   a_presAxisFlag, ...
   a_paramData, a_paramDataQc, a_paramDataDPres, a_paramDataAdjusted, a_paramDataAdjustedQc, a_paramDataAdjustedError, ...
   a_comment)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


% select the cycle to print
% if ~((g_cocs_floatNum == 6900889) && (g_cocs_cycleNum == 1) && isempty(g_cocs_cycleDir))
% if ~((g_cocs_cycleNum == 13) && isempty(g_cocs_cycleDir))
%    return;
% end

dateStr = datestr(now, 'yyyymmddTHHMMSS');

% create CSV file to print profile data
outputFileName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\nc_create_synthetic_profile_' ...
   sprintf('%d_%03d%c', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir) '_' a_comment '_' dateStr '.csv'];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to create CSV output file: %s\n', ...
      g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir, outputFileName);
   return;
end

data = [];
header = 'PARAMETER';
format = '%s';
if (~isempty(a_presAxisFlag))
   header = [header '; SYNTH PRES flag'];
   format = [format '; %d'];
end
for idParam = 1:length(a_paramlist)
   paramName = a_paramlist{idParam};
   header = [header '; ' paramName '; '];
   format = [format '; %g; %c'];
   data = [data a_paramData(:, idParam) single(a_paramDataQc(:, idParam))];
   if (~isempty(a_paramDataDPres))
      if (idParam > 1)
         header = [header '; ' [paramName '_dPRES']];
         format = [format '; %g'];
         data = [data a_paramDataDPres(:, idParam)];
      end
   end
   if (a_paramDataMode(idParam) ~= 'R')
      if (any(a_paramDataAdjusted(:, idParam) ~= a_paramFillValue(idParam)))
         header = [header '; ' paramName '_ADJUSTED; '];
         format = [format '; %g; %c'];
         data = [data a_paramDataAdjusted(:, idParam) single(a_paramDataAdjustedQc(:, idParam))];
         if (a_paramDataMode(idParam) == 'D')
            if (any(a_paramDataAdjustedError(:, idParam) ~= a_paramFillValue(idParam)))
               header = [header '; ' paramName '_ADJUSTED_ERROR'];
               format = [format '; %g'];
               data = [data a_paramDataAdjustedError(:, idParam)];
            end
         end
      end
   end
end
format = [format '\n'];

fprintf(fidOut,'%s\n', header);

for idLev = 1:size(a_paramData, 1)
   if (~isempty(a_presAxisFlag))
      fprintf(fidOut, format, ...
         ['MEAS#' num2str(idLev)], ...
         a_presAxisFlag(idLev), ...
         data(idLev, :));
   else
      fprintf(fidOut, format, ...
         ['MEAS#' num2str(idLev)], ...
         data(idLev, :));
   end
end

fclose(fidOut);

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
%   01/11/2018 - RNU - creation
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
%   01/11/2018 - RNU - creation
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
%   04/09/2014 - RNU - creation
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
%   01/11/2018 - RNU - creation
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
%   01/11/2018 - RNU - creation
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
%   01/11/2018 - RNU - creation
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
   'verticalPresOffset', 0, ...
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
%   01/11/2018 - RNU - creation
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
