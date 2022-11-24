% ------------------------------------------------------------------------------
% Generate a merged profile from C and B mono-profile files.
%
% SYNTAX :
%   nc_create_v2_merged_profile(6900189, 7900118) or
%   nc_create_v2_merged_profile (in this case all the floats of the
%                                FLOAT_LIST_FILE_NAME are processed)
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
%   01/11/2018 - RNU - V 0.1: creation
%   03/07/2018 - RNU - V 0.2: update from 20180306 version of the specifications
% ------------------------------------------------------------------------------
function nc_create_v2_merged_profile(varargin)

% list of floats to process (if empty, all encountered files will be processed)
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_rem_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_nke_apmt_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = '';

% top directory of input NetCDF files
DIR_INPUT_NC_FILES = 'H:\archive_201801\coriolis\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\SYNTHETIC_PROFILE\';

% top directory of output NetCDF files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% merged profile reference file
REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoV2MergedProf_V0.2.nc';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% to print data after each processing step
PRINT_CSV_FLAG = 0;

% program version
global g_cocm_ncCreateMergedProfileVersion;
g_cocm_ncCreateMergedProfileVersion = '0.2';

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% to print data after each processing step
global g_cocm_printCsv;
g_cocm_printCsv = PRINT_CSV_FLAG;

% report information structure
global g_cocm_reportData;
g_cocm_reportData = [];
g_cocm_reportData.trajFile = [];
g_cocm_reportData.mProfFil = [];
g_cocm_reportData.profFile = [];
g_cocm_reportData.float = [];


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
logFile = [DIR_LOG_FILE '/' 'nc_create_v2_merged_profile_' currentTime '.log'];
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
         g_cocm_floatNum = floatList(idFloat);
         floatDirPathName = [DIR_INPUT_NC_FILES '/' num2str(g_cocm_floatNum) '/'];
         if (exist(floatDirPathName, 'dir') == 7)
            
            fprintf('%03d/%03d %d\n', idFloat, length(floatList), g_cocm_floatNum);
            
            process_one_float(floatDirPathName, DIR_OUTPUT_NC_FILES, REF_PROFILE_FILE);
            
            floatNum = floatNum + 1;
         else
            fprintf('ERROR: No directory for float #%d\n', g_cocm_floatNum);
         end
      end
   else
      
      floatNum = 1;
      floatDirs = dir(DIR_INPUT_NC_FILES);
      for idDir = 1:length(floatDirs)
         
         floatDirName = floatDirs(idDir).name;
         floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            
            [g_cocm_floatNum, status] = str2num(floatDirName);
            if (status == 1)
               
               fprintf('%03d/%03d %d\n', floatNum, length(floatDirs)-2, g_cocm_floatNum);
               
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
% Generate a merged profile for a given float.
%
% SYNTAX :
%  process_one_float(a_floatDir, a_outputDir)
%
% INPUT PARAMETERS :
%   a_floatDir   : float input data directory
%   a_outputDir  : top directory of merged profile
%   a_refFileCdl : netCDF merged profile file schema
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
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;


floatWmoStr = num2str(g_cocm_floatNum);

% retrieve META data
metaDataStruct = [];
if (exist([a_floatDir '/' floatWmoStr '_meta.nc'], 'file') == 2)
   metaDataStruct = get_meta_data([a_floatDir '/' floatWmoStr '_meta.nc']);
end

% search TRAJ file(s)
cTrajFileName = '';
bTrajFileName = '';
trajDataStruct = [];
if (exist([a_floatDir '/' floatWmoStr '_Dtraj.nc'], 'file') == 2)
   cTrajFileName = [floatWmoStr '_Dtraj.nc'];
elseif (exist([a_floatDir '/' floatWmoStr '_Rtraj.nc'], 'file') == 2)
   cTrajFileName = [floatWmoStr '_Rtraj.nc'];
end
if (exist([a_floatDir '/' floatWmoStr '_BDtraj.nc'], 'file') == 2)
   bTrajFileName = [floatWmoStr '_BDtraj.nc'];
elseif (exist([a_floatDir '/' floatWmoStr '_BRtraj.nc'], 'file') == 2)
   bTrajFileName = [floatWmoStr '_BRtraj.nc'];
end

% retrieve TRAJ data
if (~isempty(cTrajFileName))
   trajDataStruct = get_traj_data(cTrajFileName, bTrajFileName, a_floatDir);
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
   
   g_cocm_cycleNum = cyNumList(idCy);
   %    if (g_cocm_cycleNum ~= 13)
   %       continue;
   %    end
   
   % process descending and ascending profiles
   for idDir = 1:2
      
      if (idDir == 1)
         g_cocm_cycleDir = 'D';
      else
         g_cocm_cycleDir = '';
      end
      
      if (~isempty(g_cocm_cycleDir))
         continue;
      end
      
      cProfFileName = '';
      bProfFileName = '';
      profDataStruct = '';
      syntProfDataStruct = '';
      if (exist([profileDir '/' sprintf('D%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)], 'file') == 2)
         cProfFileName = sprintf('D%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
      elseif (exist([profileDir '/' sprintf('R%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)], 'file') == 2)
         cProfFileName = sprintf('R%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
      end
      if (exist([profileDir '/' sprintf('BD%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)], 'file') == 2)
         bProfFileName = sprintf('BD%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
      elseif (exist([profileDir '/' sprintf('BR%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir)], 'file') == 2)
         bProfFileName = sprintf('BR%d_%03d%c.nc', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
      end
      
      % retrieve PROF data
      if (~isempty(cProfFileName))
         
         fprintf('   %02d/%02d: Float #%d Cycle #%d%c\n', ...
            idCy, length(cyNumList), g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
         
         profDataStruct = get_prof_data(cProfFileName, bProfFileName, profileDir, metaDataStruct);
      end
      
      % process PROF data
      if (~isempty(profDataStruct))
         syntProfDataStruct = process_prof_data(profDataStruct, trajDataStruct, metaDataStruct);
         
         if (~isempty(syntProfDataStruct))
            syntProfAll = [syntProfAll syntProfDataStruct];
         end
      end
      
      % create merged PROF file
      if (~isempty(syntProfDataStruct))
         create_mono_merged_profile_file(g_cocm_floatNum, syntProfDataStruct, tmpDirName, a_outputDir, a_refFile);
      end
   end
end

% if (~isempty(syntProfAll))
%    create_multi_merged_profile_file(g_cocm_floatNum, syntProfAll, tmpDirName, a_outputDir, a_refFile);
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
global g_cocm_floatNum;


% retrieve information from META file
if ~(exist(a_metaFilePathName, 'file') == 2)
   fprintf('ERROR: Float #%d: File not found: %s\n', ...
      g_cocm_floatNum, a_metaFilePathName);
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
      g_cocm_floatNum, a_metaFilePathName, formatVersion);
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
% Retrieve data from TRAJ file.
%
% SYNTAX :
%  [o_trajData] = get_traj_data(a_cTrajFileName, a_bTrajFileName, a_trajDir)
%
% INPUT PARAMETERS :
%   a_cTrajFileName : C TRAJ file name
%   a_bTrajFileName : B TRAJ file name
%   a_trajDir       : TRAJ file dir name
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_trajData] = get_traj_data(a_cTrajFileName, a_bTrajFileName, a_trajDir)

% output parameters initialization
o_trajData = [];

% current float and cycle identification
global g_cocm_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;


% retrieve TRAJ data from C and B files
for idType= 1:2
   if (idType == 1)
      trajFilePathName = [a_trajDir '/' a_cTrajFileName];
      if ~(exist(trajFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d: File not found: %s\n', ...
            g_cocm_floatNum, trajFilePathName);
         return;
      end
   else
      if (isempty(a_bTrajFileName))
         break;
      end
      trajFilePathName = [a_trajDir '/' a_bTrajFileName];
      if ~(exist(trajFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d: File not found: %s\n', ...
            g_cocm_floatNum, trajFilePathName);
         return;
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
      fprintf('WARNING: Float #%d: Input TRAJ file (%s) format version is %s => not used\n', ...
         g_cocm_floatNum, trajFilePathName, formatVersion);
      return;
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
            continue;
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
      profFilePathName = [a_profDir '/' a_cProfFileName];
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName);
         return;
      end
   else
      if (isempty(a_bProfFileName))
         break;
      end
      profFilePathName = [a_profDir '/' a_bProfFileName];
      if ~(exist(profFilePathName, 'file') == 2)
         fprintf('ERROR: Float #%d Cycle #%d%c: File not found: %s\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName);
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
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, profFilePathName, formatVersion);
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
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, ...
         idProf);
   end
end
sortedId(find(sortedId < 0)) = []; % in case of ERROR
profDataTab = profDataTab(sortedId);

% output parameter
o_profData = profDataTab;

return;

% ------------------------------------------------------------------------------
% Process PROF (and TRAJ) data to generate merged profile data.
%
% SYNTAX :
%  [o_syntProfData] = process_prof_data(a_profData, a_trajData, a_metaData)
%
% INPUT PARAMETERS :
%   a_profData : data retrieved from PROF file(s)
%   a_trajData : data retrieved from TRAJ file(s)
%   a_metaData : data retrieved from META file
%
% OUTPUT PARAMETERS :
%   o_syntProfData : merged profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_syntProfData] = process_prof_data(a_profData, a_trajData, a_metaData)

% output parameters initialization
o_syntProfData = [];

% global measurement codes
global g_MC_DescProf;
global g_MC_AscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_NearSurfaceSeriesOfMeas;
global g_MC_InAirSeriesOfMeas;

% global sampling codes
global g_SC_Unknown;
global g_SC_Profile;
global g_SC_NearSurface;
global g_SC_NearSurface_Pumped;
global g_SC_NearSurface_Unpumped;
global g_SC_InAir;
global g_SC_Default;
g_SC_Unknown = 0;
g_SC_Profile = 1;
g_SC_NearSurface = 2;
g_SC_NearSurface_Pumped = 3;
g_SC_NearSurface_Unpumped = 4;
g_SC_InAir = 5;
g_SC_Default = -128;

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
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% to print data after each processing step
global g_cocm_printCsv;


% check input profile consistency
errorFlag = 0;
if (length(unique({a_profData.handbookVersion})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple HANDBOOK_VERSION => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.referenceDateTime})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple REFERENCE_DATE_TIME => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.platformNumber})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PLATFORM_NUMBER => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.projectName})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PROJECT_NAME => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.piName})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PI_NAME => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.cycleNumber])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple CYCLE_NUMBER => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.direction})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple DIRECTION => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.dataCentre})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple DATA_CENTRE => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.platformType})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple PLATFORM_TYPE => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.floatSerialNo})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple FLOAT_SERIAL_NO => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.firmwareVersion})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple FIRMWARE_VERSION => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.wmoInstType})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple WMO_INST_TYPE => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juld])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldResolution])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD:resolution => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.juldQc})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_QC => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldLocation])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_LOCATION => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.juldLocationResolution])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple JULD_LOCATION:resolution => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.latitude])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple LATITUDE => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.longitude])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple LONGITUDE => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.positionQc})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple POSITION_QC => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique({a_profData.positioningSystem})) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple POSITIONING_SYSTEM => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   errorFlag = 1;
end
if (length(unique([a_profData.configMissionNumber])) > 1)
   fprintf('ERROR: Float #%d Cycle #%d%c: multiple CONFIG_MISSION_NUMBER => file ignored\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
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

samplingCode = ones(size(paramData, 1), 1)*g_SC_Default;

presAxisFlagConfig = [];
presAxisFlagAlgo = [];

% collect data
startLev = 1;
for idProf = 1:length(a_profData)
   profData = a_profData(idProf);
   
   if (~isempty(strfind(profData.verticalSamplingScheme, 'Near-surface sampling')))
      sampCode = g_SC_NearSurface;
      if (~isempty(strfind(profData.verticalSamplingScheme, 'unpumped')))
         sampCode = g_SC_NearSurface_Unpumped;
      elseif (~isempty(strfind(profData.verticalSamplingScheme, 'pumped')))
         sampCode = g_SC_NearSurface_Pumped;
      end
   else
      sampCode = g_SC_Profile;
   end
   
   profParamData = profData.paramData;
   profParamDataQc = profData.paramDataQc;
   profParamDataAdjusted = profData.paramDataAdjusted;
   profParamDataAdjustedQc = profData.paramDataAdjustedQc;
   profParamDataAdjustedError = profData.paramDataAdjustedError;
   
   profNbLev = size(profParamData, 1);
   
   samplingCode(startLev:startLev+profNbLev-1) = ones(size(profParamData, 1), 1)*sampCode;
   
   paramData(startLev:startLev+profNbLev-1, :) = profParamData;
   paramDataQc(startLev:startLev+profNbLev-1, :) = profParamDataQc;
   paramDataAdjusted(startLev:startLev+profNbLev-1, :) = profParamDataAdjusted;
   paramDataAdjustedQc(startLev:startLev+profNbLev-1, :) = profParamDataAdjustedQc;
   paramDataAdjustedError(startLev:startLev+profNbLev-1, :) = profParamDataAdjustedError;
   
   startLev = startLev + profNbLev;
end

if (g_cocm_printCsv)
   print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
      samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
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
samplingCode(idDel) = [];
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
samplingCode = samplingCode(idSort);
paramData = paramData(idSort, :);
paramDataQc = paramDataQc(idSort, :);
paramDataAdjusted = paramDataAdjusted(idSort, :);
paramDataAdjustedQc = paramDataAdjustedQc(idSort, :);
paramDataAdjustedError = paramDataAdjustedError(idSort, :);

if (g_cocm_printCsv)
   print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
      samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
      paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step2');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% step #2bis: add time of profile levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if (~isempty(a_trajData))
   if (o_syntProfData.direction == 'A')
      profMeasCodeList = g_MC_AscProf;
   else
      profMeasCodeList = g_MC_DescProf;
   end
   if (~isempty(a_metaData))
      if (strcmp(a_metaData.dataCentre, 'IF') && strcmp(a_metaData.platformType, 'NAVIS_A'))
         % for NAVIS floats near surface measurements are stored in the PROF and
         % in the TRAJ files
         profMeasCodeList = [profMeasCodeList g_MC_NearSurfaceSeriesOfMeas];
      end
   end
   
   idMeas = find( ...
      (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
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
               fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' parameter not found in TRAJ file => cannot add time on profile levels\n', ...
                  g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramName);
               trajParamId = [];
               break;
            end
         end
         if (~isempty(trajParamId))
            trajParamData = a_trajData.paramData(idMeas, :);
            for idM = 1:length(idMeas)
               idLev = [];
               for idL = 1:size(paramData, 1)
                  if (~any(paramData(idL, :) ~= trajParamData(idM, trajParamId)))
                     idLev = idL;
                     break;
                  end
               end
               if (~isempty(idLev))
                  juld(idLev) = a_trajData.juld(idMeas(idM));
                  juldQc(idLev) = a_trajData.juldQc(idMeas(idM));
                  juldAdjusted(idLev) = a_trajData.juldAdj(idMeas(idM));
                  juldAdjustedQc(idLev) = a_trajData.juldAdjQc(idMeas(idM));
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
      else
         fprintf('ERROR: Float #%d Cycle #%d%c: PROF and TRAJ files have not the same number of parameters => cannot add time on profile levels\n', ...
            g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
      end
      
      if (any(juld ~= paramJuldFillValue))
         
         % if juld have associated to profile levels, store juld data mode
         cycleNumberId = find(a_trajData.cycleNumberIndex == o_syntProfData.cycleNumber);
         juldDataMode = a_trajData.dataMode(cycleNumberId);
         
         if (g_cocm_printCsv)
            print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
               samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
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
      
      % only CTD and optode profiles have the Near Surface / unpumped
      % information
      samplingCode(levRef) = max(samplingCode(levels));
      
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
   samplingCode(idDel) = [];
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
      samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
      paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
      'step3');
end

% update output structure
o_syntProfData.samplingCode = samplingCode;

o_syntProfData.juldLevDataMode = juldDataMode;
o_syntProfData.juldLev = juld;
o_syntProfData.juldLevQc = juldQc;
o_syntProfData.juldLevAdjusted = juldAdjusted;
o_syntProfData.juldLevAdjustedQc = juldAdjustedQc;

o_syntProfData.paramList = paramList;
o_syntProfData.paramDataMode = paramDataMode;

o_syntProfData.paramData = paramData;
o_syntProfData.paramDataQc = paramDataQc;
o_syntProfData.paramDataAdjusted = paramDataAdjusted;
o_syntProfData.paramDataAdjustedQc = paramDataAdjustedQc;
o_syntProfData.paramDataAdjustedError = paramDataAdjustedError;

o_syntProfData.scientificCalibEquation = scientificCalibEquation;
o_syntProfData.scientificCalibCoefficient = scientificCalibCoefficient;
o_syntProfData.scientificCalibComment = scientificCalibComment;
o_syntProfData.scientificCalibDate = scientificCalibDate;

if (isempty(o_syntProfData.paramData))
   
   fprintf('INFO: Float #%d Cycle #%d%c: no data remain after processing => no merged profile\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
   o_syntProfData = [];
end

return;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % step #4: interpolate measurements on missing values (using good values as base
% % points)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% qcList = [g_decArgo_qcStrNoQc g_decArgo_qcStrGood ...
%    g_decArgo_qcStrProbablyGood g_decArgo_qcStrCorrectable g_decArgo_qcStrBad];
% if (paramDataMode(1) == 'R')
%    refPresParamData = paramData(:, 1);
% else
%    refPresParamData = paramDataAdjusted(:, 1);
% end
%
% for idParam = 2:size(paramData, 2)
%
%    qcRef = '';
%    for idQc = 1:length(qcList)
%       if (any(paramDataQc(:, idParam) == qcList(idQc)))
%          qcRef = qcList(idQc);
%          break;
%       end
%    end
%    if (~isempty(qcRef))
%       idOk = find(paramDataQc(:, idParam) == qcRef);
%       if (length(idOk) > 1)
%          idKo = setdiff((1:size(paramData, 1))', idOk);
%          interpData = interp1(paramData(idOk, 1), paramData(idOk, idParam), paramData(idKo, 1), 'linear');
%          idSet = find(~isnan(interpData) & (paramData(idKo, idParam) == paramFillValue(idParam)));
%          paramData(idKo(idSet), idParam) = interpData(idSet);
%          paramDataQc(idKo(idSet), idParam) = g_decArgo_qcStrInterpolated;
%       end
%    end
%
%    qcRef = '';
%    for idQc = 1:length(qcList)
%       if (any(paramDataAdjustedQc(:, idParam) == qcList(idQc)))
%          qcRef = qcList(idQc);
%          break;
%       end
%    end
%    if (~isempty(qcRef))
%       idOk = find(paramDataAdjustedQc(:, idParam) == qcRef);
%       if (length(idOk) > 1)
%          idKo = setdiff((1:size(paramData, 1))', idOk);
%          interpData = interp1(refPresParamData(idOk), paramDataAdjusted(idOk, idParam), refPresParamData(idKo), 'linear');
%          idSet = find(~isnan(interpData) & (paramDataAdjusted(idKo, idParam) == paramFillValue(idParam)));
%          paramDataAdjusted(idKo(idSet), idParam) = interpData(idSet);
%          paramDataAdjustedQc(idKo(idSet), idParam) = g_decArgo_qcStrInterpolated;
%
%          interpData = interp1(refPresParamData(idOk), paramDataAdjustedError(idOk, idParam), refPresParamData(idKo), 'linear');
%          idSet = find(~isnan(interpData) & (paramDataAdjustedError(idKo, idParam) == paramFillValue(idParam)));
%          paramDataAdjustedError(idKo(idSet), idParam) = interpData(idSet);
%       end
%    end
% end
%
% % interpolate time level values
% if (~isempty(juldDataMode))
%    qcRef = '';
%    for idQc = 1:length(qcList)
%       if (any(juldQc == qcList(idQc)))
%          qcRef = qcList(idQc);
%          break;
%       end
%    end
%    if (~isempty(qcRef))
%       idOk = find(juldQc == qcRef);
%       if (length(idOk) > 1)
%          idKo = setdiff((1:length(juld))', idOk);
%          interpJuld = interp1(paramData(idOk, 1), juld(idOk), paramData(idKo, 1), 'linear');
%          idSet = find(~isnan(interpJuld) & (juld(idKo) == paramJuldFillValue));
%          juld(idKo(idSet)) = interpJuld(idSet);
%          juldQc(idKo(idSet)) = g_decArgo_qcStrInterpolated;
%       end
%    end
%
%    if (juldDataMode ~= 'R')
%       qcRef = '';
%       for idQc = 1:length(qcList)
%          if (any(juldAdjustedQc == qcList(idQc)))
%             qcRef = qcList(idQc);
%             break;
%          end
%       end
%       if (~isempty(qcRef))
%          idOk = find(juldAdjustedQc == qcRef);
%          if (length(idOk) > 1)
%             idKo = setdiff((1:length(juld))', idOk);
%             interpJuld = interp1(refPresParamData(idOk), juldAdjusted(idOk), refPresParamData(idKo), 'linear');
%             idSet = find(~isnan(interpJuld) & (juldAdjusted(idKo) == paramJuldFillValue));
%             juldAdjusted(idKo(idSet)) = interpJuld(idSet);
%             juldAdjustedQc(idKo(idSet)) = g_decArgo_qcStrInterpolated;
%          end
%       end
%    end
% end
%
% if (g_cocm_printCsv)
%    print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
%       samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
%       paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
%       'step4');
% end
%
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % step #4bis: update sampling code to profile data (for NKE floats)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% % retrieve pumped/unpumped threshold value
% presCutOffProf = [];
% if (~isempty(a_trajData))
%
%    % from TRAJ data
%    idPCutOffMeas = find( ...
%       (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
%       (a_trajData.measurementCode == g_MC_LastAscPumpedCtd));
%    if (~isempty(idPCutOffMeas))
%       trajParamList = a_trajData.paramList;
%       idPres = find(strcmp('PRES', trajParamList) == 1, 1);
%       paramPres = get_netcdf_param_attributes('PRES');
%       if (a_trajData.paramData(idPCutOffMeas, idPres) ~= paramPres.fillValue)
%          presCutOffProf = a_trajData.paramData(idPCutOffMeas, idPres);
%          if (length(presCutOffProf) > 1)
%             fprintf('WARNING: Float #%d Cycle #%d%c: multiple (%d) values for presCutOffProf => the first one is used\n', ...
%                g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, length(presCutOffProf));
%             presCutOffProf = presCutOffProf(1);
%          end
%       end
%    end
% end
% if (isempty(presCutOffProf))
%    if (~isempty(a_metaData))
%
%       % from META data
%       configParameterNames = cellstr(a_metaData.configParameterName);
%       idPCutOffConf = find(strcmp('CONFIG_CTDPumpStopPressurePlusThreshold_dbar', configParameterNames));
%       if (~isempty(idPCutOffConf))
%          idMission = find(a_metaData.configMissionNumber == o_syntProfData.configMissionNumber);
%          presCutOffProf = a_metaData.configParameterValue(idMission, idPCutOffConf);
%       else
%          launchConfigParameterNames = cellstr(a_metaData.launchConfigParameterName);
%          idPCutOffLaunchConf = find(strcmp('CONFIG_CTDPumpStopPressurePlusThreshold_dbar', launchConfigParameterNames));
%          if (~isempty(idPCutOffLaunchConf))
%             presCutOffProf = a_metaData.launchConfigParameterValue(idPCutOffLaunchConf);
%          end
%       end
%    end
% end
% if (isempty(presCutOffProf))
%    if (~isempty(a_metaData))
%
%       % from META data
%       configParameterNames = cellstr(a_metaData.configParameterName);
%       idPCutOffConf = find(strcmp('CONFIG_CTDPumpStopPressure_dbar', configParameterNames));
%       if (~isempty(idPCutOffConf))
%          idMission = find(a_metaData.configMissionNumber == o_syntProfData.configMissionNumber);
%          presCutOffProf = a_metaData.configParameterValue(idMission, idPCutOffConf) + 0.5;
%       else
%          launchConfigParameterNames = cellstr(a_metaData.launchConfigParameterName);
%          idPCutOffLaunchConf = find(strcmp('CONFIG_CTDPumpStopPressure_dbar', launchConfigParameterNames));
%          if (~isempty(idPCutOffLaunchConf))
%             presCutOffProf = a_metaData.launchConfigParameterValue(idPCutOffLaunchConf) + 0.5;
%          end
%       end
%    end
% end
% if (~isempty(presCutOffProf))
%
%    % set sampling code
%    idPumped = find(paramData(:, 1) > presCutOffProf);
%    samplingCode(idPumped) = g_SC_Profile;
%    idUnpumped = find(paramData(:, 1) <= presCutOffProf);
%    samplingCode(idUnpumped) = g_SC_NearSurface_Unpumped;
% end
%
% if (g_cocm_printCsv)
%    print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
%       samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
%       paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
%       'step4bis');
% end
%
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % step #4ter: add "Near Surface" and "In Air" measurements
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% % specific to Coriolis DAC
% if (~isempty(a_metaData))
%
%    if (strcmp(a_metaData.dataCentre, 'IF'))
%       idNsMeas = [];
%       idIaMeas = [];
%       if (strcmp(a_metaData.platformType, 'APEX'))
%
%          % APEX floats: surface measurements stored with MC = g_MC_InAirSeriesOfMeas
%          idIaMeas = find( ...
%             (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
%             (a_trajData.measurementCode == g_MC_InAirSeriesOfMeas));
%
%       elseif (strcmp(a_metaData.platformType, 'NAVIS_A'))
%
%          % NAVIS floats:
%          % - near surface measurements stored with MC = g_MC_NearSurfaceSeriesOfMeas
%          % - surface measurements stored with MC = g_MC_InAirSeriesOfMeas
%          % but near surface measurements are also stored in the profile, thus
%          % already in the profile data
%          %          idNsMeas = find( ...
%          %             (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
%          %             (a_trajData.measurementCode == g_MC_NearSurfaceSeriesOfMeas));
%          idIaMeas = find( ...
%             (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
%             (a_trajData.measurementCode == g_MC_InAirSeriesOfMeas));
%
%       elseif (strcmp(a_metaData.platformType, 'PROVOR_IV'))
%
%          % PROVOR CTS5 floats: surface measurements stored with MC = g_MC_InAirSeriesOfMeas
%          idIaMeas = find( ...
%             (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
%             (a_trajData.measurementCode == g_MC_InAirSeriesOfMeas));
%
%       elseif (ismember(a_metaData.platformType, [{'PROVOR'} {'ARVOR'} {'ARVOR_D'} ]))
%
%          % PROVOR CTS3 and ARVOR floats that have the "NS & IA" feature:
%          % near surface and surface measurements stored with MC = g_MC_InAirSeriesOfMeas
%          % same number of near surface and surface measurements
%
%          configParamNames = cellstr(a_metaData.launchConfigParameterName);
%          if (any(strcmp(configParamNames, 'CONFIG_InAirMeasurementPeriodicity_NUMBER')))
%
%             % the float has the "NS & IA" feature
%             idMeas = find( ...
%                (a_trajData.cycleNumber == o_syntProfData.cycleNumber) & ...
%                (a_trajData.measurementCode == g_MC_InAirSeriesOfMeas));
%             idNsMeas = idMeas(1:length(idMeas)/2);
%             idIaMeas = idMeas(length(idMeas)/2+1:end);
%          end
%       end
%
%       % add "Near Surface" and "In Air" measurements (with associated sampling
%       % code)
%       if (~isempty(idNsMeas) || ~isempty(idIaMeas))
%          trajParamId = [];
%          trajParamList = a_trajData.paramList;
%          if (length(trajParamList) == length(paramList))
%             for idParam = 1:length(paramList)
%                paramName = paramList{idParam};
%                idF = find(strcmp(paramName, trajParamList));
%                if (~isempty(idF))
%                   trajParamId = [trajParamId idF];
%                else
%                   fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' parameter not found in TRAJ file => cannot add "Near Surface" and "In Air" measurements\n', ...
%                      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramName);
%                   trajParamId = [];
%                   break;
%                end
%             end
%             if (~isempty(trajParamId))
%                if (~isempty(idNsMeas))
%                   idNsMeas = flipud(idNsMeas);
%                   paramData = [a_trajData.paramData(idNsMeas, trajParamId); paramData];
%                   paramDataQc = [a_trajData.paramDataQc(idNsMeas, trajParamId); paramDataQc];
%
%                   % concatenate adjusted values only when paramDataMode ~= 'R'
%                   idR = find(paramDataMode == 'R');
%                   trajDataAdjusted = a_trajData.paramDataAdjusted(idNsMeas, trajParamId);
%                   trajDataAdjusted(:, idR) = repmat(paramFillValue(idR), size(trajDataAdjusted, 1), 1);
%                   trajDataAdjustedQc = a_trajData.paramDataAdjustedQc(idNsMeas, trajParamId);
%                   trajDataAdjustedQc(:, idR) = repmat(g_decArgo_qcStrDef, size(trajDataAdjustedQc, 1), length(idR));
%                   trajDataAdjustedError = a_trajData.paramDataAdjustedError(idNsMeas, trajParamId);
%                   trajDataAdjustedError(:, idR) = repmat(paramFillValue(idR), size(trajDataAdjustedError, 1), 1);
%
%                   paramDataAdjusted = [trajDataAdjusted; paramDataAdjusted];
%                   paramDataAdjustedQc = [trajDataAdjustedQc; paramDataAdjustedQc];
%                   paramDataAdjustedError = [trajDataAdjustedError; paramDataAdjustedError];
%
%                   juld = [a_trajData.juld(idNsMeas); juld];
%                   juldQc = [a_trajData.juldQc(idNsMeas); juldQc];
%                   juldAdjusted = [a_trajData.juldAdj(idNsMeas); juldAdjusted];
%                   juldAdjustedQc = [a_trajData.juldAdjQc(idNsMeas); juldAdjustedQc];
%                   samplingCode = [ones(length(idNsMeas), 1)*g_SC_NearSurface_Unpumped; samplingCode];
%                end
%                if (~isempty(idIaMeas))
%                   idIaMeas = flipud(idIaMeas);
%                   paramData = [a_trajData.paramData(idIaMeas, trajParamId); paramData];
%                   paramDataQc = [a_trajData.paramDataQc(idIaMeas, trajParamId); paramDataQc];
%
%                   % concatenate adjusted values only when paramDataMode ~= 'R'
%                   idR = find(paramDataMode == 'R');
%                   trajDataAdjusted = a_trajData.paramDataAdjusted(idIaMeas, trajParamId);
%                   trajDataAdjusted(:, idR) = repmat(paramFillValue(idR), size(trajDataAdjusted, 1), 1);
%                   trajDataAdjustedQc = a_trajData.paramDataAdjustedQc(idIaMeas, trajParamId);
%                   trajDataAdjustedQc(:, idR) = repmat(g_decArgo_qcStrDef, size(trajDataAdjustedQc, 1), length(idR));
%                   trajDataAdjustedError = a_trajData.paramDataAdjustedError(idIaMeas, trajParamId);
%                   trajDataAdjustedError(:, idR) = repmat(paramFillValue(idR), size(trajDataAdjustedError, 1), 1);
%
%                   paramDataAdjusted = [trajDataAdjusted; paramDataAdjusted];
%                   paramDataAdjustedQc = [trajDataAdjustedQc; paramDataAdjustedQc];
%                   paramDataAdjustedError = [trajDataAdjustedError; paramDataAdjustedError];
%
%                   juld = [a_trajData.juld(idIaMeas); juld];
%                   juldQc = [a_trajData.juldQc(idIaMeas); juldQc];
%                   juldAdjusted = [a_trajData.juldAdj(idIaMeas); juldAdjusted];
%                   juldAdjustedQc = [a_trajData.juldAdjQc(idIaMeas); juldAdjustedQc];
%                   samplingCode = [ones(length(idIaMeas), 1)*g_SC_InAir; samplingCode];
%                end
%
%                if (g_cocm_printCsv)
%                   print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
%                      samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
%                      paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
%                      'step4ter');
%                end
%             end
%          else
%             fprintf('ERROR: Float #%d Cycle #%d%c: PROF and TRAJ files have not the same number of parameters => cannot add "Near Surface" and "In Air" measurements\n', ...
%                g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
%          end
%       end
%    end
% end
%
% % set time level QC g_decArgo_qcStrDef to g_decArgo_qcStrMissing
% if (~isempty(juldDataMode))
%    juldQc(find(juldQc == g_decArgo_qcStrDef)) = g_decArgo_qcStrMissing;
%    if (juldDataMode ~= 'R')
%       juldQc(find(juldAdjustedQc == g_decArgo_qcStrDef)) = g_decArgo_qcStrMissing;
%    end
% end
%
% % clear unused levels
% idDel = [];
% for idLev = 1:size(paramDataQc, 1)
%    if (~any(((paramDataQc(idLev, 2:end) ~= g_decArgo_qcStrDef) & (paramDataQc(idLev, 2:end) ~= g_decArgo_qcStrMissing)) | ...
%          ((paramDataAdjustedQc(idLev, 2:end) ~= g_decArgo_qcStrDef) & (paramDataAdjustedQc(idLev, 2:end) ~= g_decArgo_qcStrMissing))))
%       idDel = [idDel idLev];
%    end
% end
% samplingCode(idDel) = [];
% paramData(idDel, :) = [];
% paramDataQc(idDel, :) = [];
% paramDataAdjusted(idDel, :) = [];
% paramDataAdjustedQc(idDel, :) = [];
% paramDataAdjustedError(idDel, :) = [];
% if (~isempty(juldDataMode))
%    juld(idDel) = [];
%    juldQc(idDel) = [];
%    juldAdjusted(idDel) = [];
%    juldAdjustedQc(idDel) = [];
% end
%
% if (g_cocm_printCsv)
%    print_profile_in_csv(paramList, paramDataMode, juldDataMode, ...
%       samplingCode, presAxisFlagConfig, presAxisFlagAlgo, juld, juldQc, juldAdjusted, juldAdjustedQc, ...
%       paramData, paramDataQc, paramDataAdjusted, paramDataAdjustedQc, paramDataAdjustedError, ...
%       'FINAL');
% end
%
% % update output structure
% o_syntProfData.samplingCode = samplingCode;
%
% o_syntProfData.juldLevDataMode = juldDataMode;
% o_syntProfData.juldLev = juld;
% o_syntProfData.juldLevQc = juldQc;
% o_syntProfData.juldLevAdjusted = juldAdjusted;
% o_syntProfData.juldLevAdjustedQc = juldAdjustedQc;
%
% o_syntProfData.paramList = paramList;
% o_syntProfData.paramDataMode = paramDataMode;
%
% o_syntProfData.paramData = paramData;
% o_syntProfData.paramDataQc = paramDataQc;
% o_syntProfData.paramDataAdjusted = paramDataAdjusted;
% o_syntProfData.paramDataAdjustedQc = paramDataAdjustedQc;
% o_syntProfData.paramDataAdjustedError = paramDataAdjustedError;
%
% o_syntProfData.scientificCalibEquation = scientificCalibEquation;
% o_syntProfData.scientificCalibCoefficient = scientificCalibCoefficient;
% o_syntProfData.scientificCalibComment = scientificCalibComment;
% o_syntProfData.scientificCalibDate = scientificCalibDate;
%
% if (isempty(o_syntProfData.paramData))
%
%    fprintf('INFO: Float #%d Cycle #%d%c: no data remain after processing => no synthetic profile\n', ...
%       g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir);
%    o_syntProfData = [];
% end
%
% return;

% ------------------------------------------------------------------------------
% Create mono synthetic profile NetCDF file.
%
% SYNTAX :
%  create_mono_merged_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
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
function create_mono_merged_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;


% create the output file name
if (any(a_profData.paramDataMode == 'D'))
   modeCode = 'D';
else
   modeCode = 'R';
end
outputFileName = ['M' modeCode num2str(a_floatWmo) '_' sprintf('%03d%c', g_cocm_cycleNum, g_cocm_cycleDir) '.nc'];
outputFilePathName = [a_tmpDir '/' outputFileName];

% retrieve the synthetic profile file schema
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
fill_merged_mono_profile_file(outputFilePathName, a_profData);

% update output file
move_file(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/profiles/' outputFileName]);

return;

% ------------------------------------------------------------------------------
% Fill mono synthetic profile NetCDF file.
%
% SYNTAX :
%  fill_merged_mono_profile_file(a_fileName, a_profData)
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
function fill_merged_mono_profile_file(a_fileName, a_profData)

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocm_ncCreateMergedProfileVersion;


% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to open NetCDF output file: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_fileName);
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
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_profData.datacentre);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
netcdf.putAtt(fCdf, globalVarId, 'history', ...
   [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ...
   ' creation (software version ' g_cocm_ncCreateMergedProfileVersion ')']);
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
   netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
   netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
   netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
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
   else
      fprintf('ERROR: Float #%d Cycle #%d%c: Parameter ''%s'' already exists in the nc file\n', ...
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramName);
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
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramQcName);
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
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramAdjName);
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
         g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, paramAdjQcName);
   end
   
   % parameter adjusted error variable and attributes
   if ~(~isempty(a_profData.juldLevDataMode) && (idParam == 1)) % there is no JULD_LEVEL_ADJUSTED_ERROR
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
valueStr = [a_profData.juldLevDataMode a_profData.paramDataMode];
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

% fill SAMPLING_CODE variable
% netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SAMPLING_CODE'), fliplr([0 0]), fliplr([1 length(a_profData.samplingCode)]), a_profData.samplingCode);

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

return;

% ------------------------------------------------------------------------------
% Create multi synthetic profile NetCDF file.
%
% SYNTAX :
%  create_multi_merged_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)
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
function create_multi_merged_profile_file(a_floatWmo, a_profData, a_tmpDir, a_outputDir, a_refFile)


% create the output file name
if (any([a_profData.paramDataMode] == 'D'))
   modeCode = 'D';
else
   modeCode = 'R';
end
outputFileName = ['M' num2str(a_floatWmo) '_prof.nc'];
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
   nParamDim = max( nParamDim, ...
      size(profData.paramData, 2) + length(profData.juldLevDataMode));
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
move_file(outputFilePathName, [a_outputDir '/' num2str(a_floatWmo) '/' outputFileName]);

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
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cocm_ncCreateMergedProfileVersion;


% open NetCDF file
fCdf = netcdf.open(a_fileName, 'NC_WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to open NetCDF output file: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_fileName);
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
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, a_profData(1).datacentre);
end
netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
netcdf.putAtt(fCdf, globalVarId, 'history', ...
   [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ...
   ' creation (software version ' g_cocm_ncCreateMergedProfileVersion ')']);
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
      if ~(~isempty(profData.juldLevDataMode) && (idParam == 1)) % there is no JULD_LEVEL_ADJUSTED_ERROR
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
   %    if (any(profData.paramDataMode == 'D'))
   %       valueStr = 'D';
   %    elseif (any(profData.paramDataMode == 'A'))
   %       valueStr = 'A';
   %    else
   %       valueStr = 'R';
   %    end
   %    netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'), profPos, length(valueStr), valueStr);
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
   
   % fill SAMPLING_CODE variable
   value = profData.samplingCode;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SAMPLING_CODE'), fliplr([profPos 0]), fliplr([1 length(value)]), value);
   
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

return;

% ------------------------------------------------------------------------------
% Print merged profile data in a CSV file.
%
% SYNTAX :
%  print_profile_in_csv(a_paramlist, a_paramDataMode, a_juldDataMode, ...
%    a_samplingCode, a_juld, a_juldQc, a_juldAdj, a_juldAdjQc, ...
%    a_paramData, a_paramDataQc, a_paramDataAdjusted, a_paramDataAdjustedQc, a_paramDataAdjustedError, ...
%    a_comment)
%
% INPUT PARAMETERS :
%   a_paramlist              : list of parameters
%   a_paramDataMode          : list of parameter data modes
%   a_juldDataMode           : data mode of JULD_LEVEL parameter
%   a_samplingCode           : SAMPLING_CODE data
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
%   01/11/2018 - RNU - creation
% ------------------------------------------------------------------------------
function print_profile_in_csv(a_paramlist, a_paramDataMode, a_juldDataMode, ...
   a_samplingCode, a_presAxisFlagConfig, a_presAxisFlagAlgo, a_juld, a_juldQc, a_juldAdj, a_juldAdjQc, ...
   a_paramData, a_paramDataQc, a_paramDataAdjusted, a_paramDataAdjustedQc, a_paramDataAdjustedError, ...
   a_comment)

a_samplingCode = [];

% current float and cycle identification
global g_cocm_floatNum;
global g_cocm_cycleNum;
global g_cocm_cycleDir;


% select the cycle to print
% if ~((g_cocm_floatNum == 6900889) && (g_cocm_cycleNum == 1) && isempty(g_cocm_cycleDir))
% if ~((g_cocm_cycleNum == 13) && isempty(g_cocm_cycleDir))
%    return;
% end

dateStr = datestr(now, 'yyyymmddTHHMMSS');

% create CSV file to print profile data
outputFileName = ['C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\nc_create_v2_merged_profile_' ...
   sprintf('%d_%03d%c', g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir) '_' a_comment '_' dateStr '.csv'];

fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Float #%d Cycle #%d%c: Unable to create CSV output file: %s\n', ...
      g_cocm_floatNum, g_cocm_cycleNum, g_cocm_cycleDir, outputFileName);
   return;
end

data = [];
header = 'PARAMETER';
format = '%s';
if (~isempty(a_samplingCode))
   header = [header '; SAMPLING_CODE'];
   format = [format '; %d'];
end
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
      if (isempty(a_samplingCode))
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
      else
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], a_samplingCode(idLev), data(idLev, :));
      end
   elseif (a_juldDataMode ~= 'R')
      if (isempty(a_samplingCode))
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
            a_samplingCode(idLev), ...
            julian_2_gregorian_dec_argo(a_juld(idLev)), a_juldQc(idLev), ...
            julian_2_gregorian_dec_argo(a_juldAdj(idLev)), a_juldAdjQc(idLev), ...
            data(idLev, :));
      end
   else
      if (isempty(a_samplingCode))
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], ...
            a_presAxisFlagConfig(idLev), a_presAxisFlagAlgo(idLev), ...
            julian_2_gregorian_dec_argo(a_juld(idLev)), a_juldQc(idLev), ...
            data(idLev, :));
      else
         fprintf(fidOut, format, ...
            ['MEAS#' num2str(idLev)], ...
            a_samplingCode(idLev), ...
            julian_2_gregorian_dec_argo(a_juld(idLev)), a_juldQc(idLev), ...
            data(idLev, :));
      end
   end
end

fclose(fidOut);

return;

% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time(a_time)

% output parameters initialization
o_time = [];

if (a_time >= 0)
   sign = '';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
if (isempty(sign))
   o_time = sprintf('%02d:%02d:%02d', h, m, s);
else
   o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);
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
%   01/11/2018 - RNU - creation
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
   'samplingCode', [], ...
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

return;


% FOLLOWING CODE ADDED FOR 'SELF CONTENT' TOOL


% ------------------------------------------------------------------------------
% Initialize global default values.
%
% SYNTAX :
%  init_default_values(varargin)
%
% INPUT PARAMETERS :
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
function init_default_values(varargin)

% global default values
global g_decArgo_dateDef;
global g_decArgo_epochDef;
global g_decArgo_argosLonDef;
global g_decArgo_argosLatDef;
global g_decArgo_ncDateDef;
global g_decArgo_ncArgosLonDef;
global g_decArgo_ncArgosLatDef;
global g_decArgo_presCountsDef;
global g_decArgo_presCountsOkDef;
global g_decArgo_tempCountsDef;
global g_decArgo_salCountsDef;
global g_decArgo_cndcCountsDef;
global g_decArgo_oxyPhaseCountsDef;
global g_decArgo_chloroACountsDef;
global g_decArgo_chloroAVoltCountsDef;
global g_decArgo_backscatCountsDef;
global g_decArgo_cdomCountsDef;
global g_decArgo_iradianceCountsDef;
global g_decArgo_parCountsDef;
global g_decArgo_turbiCountsDef;
global g_decArgo_turbiVoltCountsDef;
global g_decArgo_concNitraCountsDef;
global g_decArgo_coefAttCountsDef;
global g_decArgo_molarDoxyCountsDef;
global g_decArgo_tPhaseDoxyCountsDef;
global g_decArgo_c1C2PhaseDoxyCountsDef;
global g_decArgo_phaseDelayDoxyCountsDef;
global g_decArgo_tempDoxyCountsDef;

global g_decArgo_presDef;
global g_decArgo_tempDef;
global g_decArgo_salDef;
global g_decArgo_cndcDef;
global g_decArgo_molarDoxyDef;
global g_decArgo_mlplDoxyDef;
global g_decArgo_nbSampleDef;
global g_decArgo_c1C2PhaseDoxyDef;
global g_decArgo_bPhaseDoxyDef;
global g_decArgo_tPhaseDoxyDef;
global g_decArgo_rPhaseDoxyDef;
global g_decArgo_phaseDelayDoxyDef;
global g_decArgo_frequencyDoxyDef;
global g_decArgo_tempDoxyDef;
global g_decArgo_doxyDef;
global g_decArgo_oxyPhaseDef;
global g_decArgo_chloroADef;
global g_decArgo_backscatDef;
global g_decArgo_cdomDef;
global g_decArgo_chloroDef;
global g_decArgo_chloroVoltDef;
global g_decArgo_turbiDef;
global g_decArgo_turbiVoltDef;
global g_decArgo_concNitraDef;
global g_decArgo_coefAttDef;
global g_decArgo_fluorescenceChlaDef;
global g_decArgo_betaBackscattering700Def;
global g_decArgo_tempCpuChlaDef;
global g_decArgo_blueRefDef;
global g_decArgo_ntuRefDef;
global g_decArgo_sideScatteringTurbidityDef;

global g_decArgo_CHLADef;
global g_decArgo_PARTICLE_BACKSCATTERINGDef;

global g_decArgo_groundedDef;
global g_decArgo_durationDef;

global g_decArgo_janFirst1950InMatlab;
global g_decArgo_janFirst1970InJulD;
global g_decArgo_janFirst2000InJulD;

global g_decArgo_nbHourForProfDateCompInRtOffsetAdj;

global g_decArgo_profNum;
global g_decArgo_vertSpeed;

global g_decArgo_decoderVersion;

global g_decArgo_minNonTransDurForNewCycle;
global g_decArgo_minNonTransDurForGhost
global g_decArgo_minNumMsgForNotGhost;
global g_decArgo_minNumMsgForProcessing;
global g_decArgo_minSubSurfaceCycleDuration;
global g_decArgo_minSubSurfaceCycleDurationIrSbd2;
global g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc;

% cycle phases
global g_decArgo_phasePreMission;
global g_decArgo_phaseSurfWait;
global g_decArgo_phaseInitNewCy;
global g_decArgo_phaseInitNewProf;
global g_decArgo_phaseBuoyRed;
global g_decArgo_phaseDsc2Prk;
global g_decArgo_phaseParkDrift;
global g_decArgo_phaseDsc2Prof;
global g_decArgo_phaseProfDrift;
global g_decArgo_phaseAscProf;
global g_decArgo_phaseAscEmerg;
global g_decArgo_phaseDataProc;
global g_decArgo_phaseSatTrans;
global g_decArgo_phaseEndOfProf;
global g_decArgo_phaseEndOfLife;
global g_decArgo_phaseEmergencyAsc;
global g_decArgo_phaseUserDialog;

% treatment types
global g_decArgo_treatRaw;
global g_decArgo_treatAverage;
global g_decArgo_treatAverageAndStDev;
global g_decArgo_treatAverageAndMedian;
global g_decArgo_treatAverageAndStDevAndMedian;
global g_decArgo_treatMedian;
global g_decArgo_treatMin;
global g_decArgo_treatMax;
global g_decArgo_treatStDev;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% QC flag values (numerical)
global g_decArgo_qcDef;
global g_decArgo_qcNoQc;
global g_decArgo_qcGood;
global g_decArgo_qcProbablyGood;
global g_decArgo_qcCorrectable;
global g_decArgo_qcBad;
global g_decArgo_qcChanged;
global g_decArgo_qcInterpolated;
global g_decArgo_qcMissing;

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

% max number of CTD samples in one NOVA sensor data packet
global g_decArgo_maxCTDSampleInNovaDataPacket;

% max number of CTDO samples in one DOVA sensor data packet
global g_decArgo_maxCTDOSampleInDovaDataPacket;

% codes for CTS5 phases (used to decode CTD data)
global g_decArgo_cts5PhaseDescent;
global g_decArgo_cts5PhasePark;
global g_decArgo_cts5PhaseDeepProfile;
global g_decArgo_cts5PhaseShortPark;
global g_decArgo_cts5PhaseAscent;

% codes for CTS5 treatment types (used to decode CTD data)
global g_decArgo_cts5Treat_AM_SD_MD;
global g_decArgo_cts5Treat_AM_SD;
global g_decArgo_cts5Treat_AM_MD;
global g_decArgo_cts5Treat_RW;
global g_decArgo_cts5Treat_AM;
global g_decArgo_cts5Treat_SS;

% DOXY coefficients
global g_decArgo_doxy_nomAirPress;
global g_decArgo_doxy_nomAirMix;

global g_decArgo_doxy_201and202_201_301_d0;
global g_decArgo_doxy_201and202_201_301_d1;
global g_decArgo_doxy_201and202_201_301_d2;
global g_decArgo_doxy_201and202_201_301_d3;
global g_decArgo_doxy_201and202_201_301_sPreset;
global g_decArgo_doxy_201and202_201_301_b0_aanderaa;
global g_decArgo_doxy_201and202_201_301_b1_aanderaa;
global g_decArgo_doxy_201and202_201_301_b2_aanderaa;
global g_decArgo_doxy_201and202_201_301_b3_aanderaa;
global g_decArgo_doxy_201and202_201_301_c0_aanderaa;
global g_decArgo_doxy_201and202_201_301_b0;
global g_decArgo_doxy_201and202_201_301_b1;
global g_decArgo_doxy_201and202_201_301_b2;
global g_decArgo_doxy_201and202_201_301_b3;
global g_decArgo_doxy_201and202_201_301_c0;
global g_decArgo_doxy_201and202_201_301_pCoef2;
global g_decArgo_doxy_201and202_201_301_pCoef3;

global g_decArgo_doxy_202_204_204_d0;
global g_decArgo_doxy_202_204_204_d1;
global g_decArgo_doxy_202_204_204_d2;
global g_decArgo_doxy_202_204_204_d3;
global g_decArgo_doxy_202_204_204_sPreset;
global g_decArgo_doxy_202_204_204_b0;
global g_decArgo_doxy_202_204_204_b1;
global g_decArgo_doxy_202_204_204_b2;
global g_decArgo_doxy_202_204_204_b3;
global g_decArgo_doxy_202_204_204_c0;
global g_decArgo_doxy_202_204_204_pCoef1;
global g_decArgo_doxy_202_204_204_pCoef2;
global g_decArgo_doxy_202_204_204_pCoef3;

global g_decArgo_doxy_202_204_202_a0;
global g_decArgo_doxy_202_204_202_a1;
global g_decArgo_doxy_202_204_202_a2;
global g_decArgo_doxy_202_204_202_a3;
global g_decArgo_doxy_202_204_202_a4;
global g_decArgo_doxy_202_204_202_a5;
global g_decArgo_doxy_202_204_202_d0;
global g_decArgo_doxy_202_204_202_d1;
global g_decArgo_doxy_202_204_202_d2;
global g_decArgo_doxy_202_204_202_d3;
global g_decArgo_doxy_202_204_202_sPreset;
global g_decArgo_doxy_202_204_202_b0;
global g_decArgo_doxy_202_204_202_b1;
global g_decArgo_doxy_202_204_202_b2;
global g_decArgo_doxy_202_204_202_b3;
global g_decArgo_doxy_202_204_202_c0;
global g_decArgo_doxy_202_204_202_pCoef1;
global g_decArgo_doxy_202_204_202_pCoef2;
global g_decArgo_doxy_202_204_202_pCoef3;

global g_decArgo_doxy_202_204_203_a0;
global g_decArgo_doxy_202_204_203_a1;
global g_decArgo_doxy_202_204_203_a2;
global g_decArgo_doxy_202_204_203_a3;
global g_decArgo_doxy_202_204_203_a4;
global g_decArgo_doxy_202_204_203_a5;
global g_decArgo_doxy_202_204_203_d0;
global g_decArgo_doxy_202_204_203_d1;
global g_decArgo_doxy_202_204_203_d2;
global g_decArgo_doxy_202_204_203_d3;
global g_decArgo_doxy_202_204_203_sPreset;
global g_decArgo_doxy_202_204_203_b0;
global g_decArgo_doxy_202_204_203_b1;
global g_decArgo_doxy_202_204_203_b2;
global g_decArgo_doxy_202_204_203_b3;
global g_decArgo_doxy_202_204_203_c0;
global g_decArgo_doxy_202_204_203_pCoef1;
global g_decArgo_doxy_202_204_203_pCoef2;
global g_decArgo_doxy_202_204_203_pCoef3;

global g_decArgo_doxy_202_204_302_a0;
global g_decArgo_doxy_202_204_302_a1;
global g_decArgo_doxy_202_204_302_a2;
global g_decArgo_doxy_202_204_302_a3;
global g_decArgo_doxy_202_204_302_a4;
global g_decArgo_doxy_202_204_302_a5;
global g_decArgo_doxy_202_204_302_d0;
global g_decArgo_doxy_202_204_302_d1;
global g_decArgo_doxy_202_204_302_d2;
global g_decArgo_doxy_202_204_302_d3;
global g_decArgo_doxy_202_204_302_sPreset;
global g_decArgo_doxy_202_204_302_b0;
global g_decArgo_doxy_202_204_302_b1;
global g_decArgo_doxy_202_204_302_b2;
global g_decArgo_doxy_202_204_302_b3;
global g_decArgo_doxy_202_204_302_c0;
global g_decArgo_doxy_202_204_302_pCoef1;
global g_decArgo_doxy_202_204_302_pCoef2;
global g_decArgo_doxy_202_204_302_pCoef3;

global g_decArgo_doxy_202_205_302_a0;
global g_decArgo_doxy_202_205_302_a1;
global g_decArgo_doxy_202_205_302_a2;
global g_decArgo_doxy_202_205_302_a3;
global g_decArgo_doxy_202_205_302_a4;
global g_decArgo_doxy_202_205_302_a5;
global g_decArgo_doxy_202_205_302_d0;
global g_decArgo_doxy_202_205_302_d1;
global g_decArgo_doxy_202_205_302_d2;
global g_decArgo_doxy_202_205_302_d3;
global g_decArgo_doxy_202_205_302_sPreset;
global g_decArgo_doxy_202_205_302_b0;
global g_decArgo_doxy_202_205_302_b1;
global g_decArgo_doxy_202_205_302_b2;
global g_decArgo_doxy_202_205_302_b3;
global g_decArgo_doxy_202_205_302_c0;
global g_decArgo_doxy_202_205_302_pCoef1;
global g_decArgo_doxy_202_205_302_pCoef2;
global g_decArgo_doxy_202_205_302_pCoef3;

global g_decArgo_doxy_202_205_303_a0;
global g_decArgo_doxy_202_205_303_a1;
global g_decArgo_doxy_202_205_303_a2;
global g_decArgo_doxy_202_205_303_a3;
global g_decArgo_doxy_202_205_303_a4;
global g_decArgo_doxy_202_205_303_a5;
global g_decArgo_doxy_202_205_303_d0;
global g_decArgo_doxy_202_205_303_d1;
global g_decArgo_doxy_202_205_303_d2;
global g_decArgo_doxy_202_205_303_d3;
global g_decArgo_doxy_202_205_303_sPreset;
global g_decArgo_doxy_202_205_303_b0;
global g_decArgo_doxy_202_205_303_b1;
global g_decArgo_doxy_202_205_303_b2;
global g_decArgo_doxy_202_205_303_b3;
global g_decArgo_doxy_202_205_303_c0;
global g_decArgo_doxy_202_205_303_pCoef1;
global g_decArgo_doxy_202_205_303_pCoef2;
global g_decArgo_doxy_202_205_303_pCoef3;

global g_decArgo_doxy_202_205_304_d0;
global g_decArgo_doxy_202_205_304_d1;
global g_decArgo_doxy_202_205_304_d2;
global g_decArgo_doxy_202_205_304_d3;
global g_decArgo_doxy_202_205_304_sPreset;
global g_decArgo_doxy_202_205_304_b0;
global g_decArgo_doxy_202_205_304_b1;
global g_decArgo_doxy_202_205_304_b2;
global g_decArgo_doxy_202_205_304_b3;
global g_decArgo_doxy_202_205_304_c0;
global g_decArgo_doxy_202_205_304_pCoef1;
global g_decArgo_doxy_202_205_304_pCoef2;
global g_decArgo_doxy_202_205_304_pCoef3;

global g_decArgo_doxy_103_208_307_d0;
global g_decArgo_doxy_103_208_307_d1;
global g_decArgo_doxy_103_208_307_d2;
global g_decArgo_doxy_103_208_307_d3;
global g_decArgo_doxy_103_208_307_sPreset;
global g_decArgo_doxy_103_208_307_solB0;
global g_decArgo_doxy_103_208_307_solB1;
global g_decArgo_doxy_103_208_307_solB2;
global g_decArgo_doxy_103_208_307_solB3;
global g_decArgo_doxy_103_208_307_solC0;
global g_decArgo_doxy_103_208_307_pCoef1;
global g_decArgo_doxy_103_208_307_pCoef2;
global g_decArgo_doxy_103_208_307_pCoef3;

global g_decArgo_doxy_201_203_202_d0;
global g_decArgo_doxy_201_203_202_d1;
global g_decArgo_doxy_201_203_202_d2;
global g_decArgo_doxy_201_203_202_d3;
global g_decArgo_doxy_201_203_202_sPreset;
global g_decArgo_doxy_201_203_202_b0;
global g_decArgo_doxy_201_203_202_b1;
global g_decArgo_doxy_201_203_202_b2;
global g_decArgo_doxy_201_203_202_b3;
global g_decArgo_doxy_201_203_202_c0;
global g_decArgo_doxy_201_203_202_pCoef1;
global g_decArgo_doxy_201_203_202_pCoef2;
global g_decArgo_doxy_201_203_202_pCoef3;

global g_decArgo_doxy_201_202_202_d0;
global g_decArgo_doxy_201_202_202_d1;
global g_decArgo_doxy_201_202_202_d2;
global g_decArgo_doxy_201_202_202_d3;
global g_decArgo_doxy_201_202_202_sPreset;
global g_decArgo_doxy_201_202_202_b0;
global g_decArgo_doxy_201_202_202_b1;
global g_decArgo_doxy_201_202_202_b2;
global g_decArgo_doxy_201_202_202_b3;
global g_decArgo_doxy_201_202_202_c0;
global g_decArgo_doxy_201_202_202_pCoef1;
global g_decArgo_doxy_201_202_202_pCoef2;
global g_decArgo_doxy_201_202_202_pCoef3;

global g_decArgo_doxy_202_204_304_d0;
global g_decArgo_doxy_202_204_304_d1;
global g_decArgo_doxy_202_204_304_d2;
global g_decArgo_doxy_202_204_304_d3;
global g_decArgo_doxy_202_204_304_sPreset;
global g_decArgo_doxy_202_204_304_b0;
global g_decArgo_doxy_202_204_304_b1;
global g_decArgo_doxy_202_204_304_b2;
global g_decArgo_doxy_202_204_304_b3;
global g_decArgo_doxy_202_204_304_c0;
global g_decArgo_doxy_202_204_304_pCoef1;
global g_decArgo_doxy_202_204_304_pCoef2;
global g_decArgo_doxy_202_204_304_pCoef3;

global g_decArgo_doxy_102_207_206_a0;
global g_decArgo_doxy_102_207_206_a1;
global g_decArgo_doxy_102_207_206_a2;
global g_decArgo_doxy_102_207_206_a3;
global g_decArgo_doxy_102_207_206_a4;
global g_decArgo_doxy_102_207_206_a5;
global g_decArgo_doxy_102_207_206_b0;
global g_decArgo_doxy_102_207_206_b1;
global g_decArgo_doxy_102_207_206_b2;
global g_decArgo_doxy_102_207_206_b3;
global g_decArgo_doxy_102_207_206_c0;

% NITRATE coefficients
global g_decArgo_nitrate_a;
global g_decArgo_nitrate_b;
global g_decArgo_nitrate_c;
global g_decArgo_nitrate_d;
global g_decArgo_nitrate_opticalWavelengthOffset;


% global default values initialization
g_decArgo_dateDef = 99999.99999999;
g_decArgo_epochDef = 9999999999;
g_decArgo_argosLonDef = 999.999;
g_decArgo_argosLatDef = 99.999;
g_decArgo_ncDateDef = 999999;
g_decArgo_ncArgosLonDef = 99999;
g_decArgo_ncArgosLatDef = 99999;
g_decArgo_presCountsDef = 99999;
g_decArgo_presCountsOkDef = -1;
g_decArgo_tempCountsDef = 99999;
g_decArgo_salCountsDef = 99999;
g_decArgo_cndcCountsDef = 99999;
g_decArgo_oxyPhaseCountsDef = 9999999999;
g_decArgo_chloroACountsDef = 99999;
g_decArgo_chloroAVoltCountsDef = 99999;
g_decArgo_backscatCountsDef = 99999;
g_decArgo_cdomCountsDef = 99999;
g_decArgo_iradianceCountsDef = 9999999999;
g_decArgo_parCountsDef = 9999999999;
g_decArgo_turbiCountsDef = 99999;
g_decArgo_turbiVoltCountsDef = 99999;
g_decArgo_concNitraCountsDef = 999e+036; % max = 3.40282346e+038
g_decArgo_coefAttCountsDef = 99999;
g_decArgo_molarDoxyCountsDef = 99999;
g_decArgo_tPhaseDoxyCountsDef = 99999;
g_decArgo_c1C2PhaseDoxyCountsDef = 99999;
g_decArgo_phaseDelayDoxyCountsDef = 99999;
g_decArgo_tempDoxyCountsDef = 99999;

g_decArgo_presDef = 9999.9;
g_decArgo_tempDef = 99.999;
g_decArgo_salDef = 99.999;
g_decArgo_cndcDef = 99.9999;
g_decArgo_molarDoxyDef = 999;
g_decArgo_mlplDoxyDef = 999;
g_decArgo_nbSampleDef = 99999;
g_decArgo_c1C2PhaseDoxyDef = 999.999;
g_decArgo_bPhaseDoxyDef = 999.999;
g_decArgo_tPhaseDoxyDef = 999.999;
g_decArgo_rPhaseDoxyDef = 999.999;
g_decArgo_phaseDelayDoxyDef = 99999.999;
g_decArgo_frequencyDoxyDef = 99999.99;
g_decArgo_tempDoxyDef = 99.999;
g_decArgo_doxyDef = 999.999;
g_decArgo_oxyPhaseDef = 9999999.999;
g_decArgo_chloroADef = 9999.9;
g_decArgo_backscatDef = 9999.9;
g_decArgo_cdomDef = 9999.9;
g_decArgo_chloroDef = 9999.9;
g_decArgo_chloroVoltDef = 9.999;
g_decArgo_turbiDef = 9999.9;
g_decArgo_turbiVoltDef = 9.999;
g_decArgo_concNitraDef = 9.99e+038;
g_decArgo_coefAttDef = 99.999;
g_decArgo_fluorescenceChlaDef = 9999;
g_decArgo_betaBackscattering700Def = 9999;
g_decArgo_tempCpuChlaDef = 999;
g_decArgo_blueRefDef = 99999;
g_decArgo_ntuRefDef = 99999;
g_decArgo_sideScatteringTurbidityDef = 99999;

g_decArgo_CHLADef = 99999;
g_decArgo_PARTICLE_BACKSCATTERINGDef = 99999;

g_decArgo_groundedDef = -1;
g_decArgo_durationDef = -1;

g_decArgo_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

g_decArgo_janFirst1970InJulD = gregorian_2_julian_dec_argo('1970/01/01 00:00:00');

g_decArgo_janFirst2000InJulD = gregorian_2_julian_dec_argo('2000/01/01 00:00:00');

% RT offset adjustments comes from meta-data and are dated. The following
% parameter is used as the accepted interval to compare profile dates to
% adjustment dates (because historical adjustments could have been done with a
% different algorithm for profile date determination, thus cannot be directly
% compared)
g_decArgo_nbHourForProfDateCompInRtOffsetAdj = 2;

g_decArgo_profNum = 99;
g_decArgo_vertSpeed = 99.9;

% the first 3 digits are incremented at each new complete dated release
% the last digit is incremented at each patch associated to a given complete
% dated release
g_decArgo_decoderVersion = '016g';

% minimum duration (in hour) of a non-transmission period to create a new
% cycle for an Argos float
g_decArgo_minNonTransDurForNewCycle = 18;

% minimum duration (in hour) of a non-transmission period to use the ghost
% detection algorithm
g_decArgo_minNonTransDurForGhost = 3;

% minimum duration (in hour) of a sub-surface period for an Iridium float
g_decArgo_minSubSurfaceCycleDuration = 5;
g_decArgo_minSubSurfaceCycleDurationIrSbd2 = 1.5;

% minimum number of float messages in an Argos file to use it
% (if the Argos file contains less than g_decArgo_minNumMsgForNotGhost float
% Argos messages, the file is not decoded because considered as a ghost
% file (i.e. it only contains ghost messages))
g_decArgo_minNumMsgForNotGhost = 4;

% minimum number of float messages in an Argos file to be processed within the
% 'profile' mode
g_decArgo_minNumMsgForProcessing = 5;

% maximum time difference (in days) between 2 GPS locations used to replace
% Iridium profile locations by interpolated GPS profile locations
g_decArgo_maxDelayToReplaceIrLocByInterpolatedGpsLoc = 30;

g_decArgo_phasePreMission = 0;
g_decArgo_phaseSurfWait = 1;
g_decArgo_phaseInitNewCy = 2;
g_decArgo_phaseInitNewProf = 3;
g_decArgo_phaseBuoyRed = 4;
g_decArgo_phaseDsc2Prk = 5;
g_decArgo_phaseParkDrift = 6;
g_decArgo_phaseDsc2Prof = 7;
g_decArgo_phaseProfDrift = 8;
g_decArgo_phaseAscProf = 9;
g_decArgo_phaseAscEmerg = 10;
g_decArgo_phaseDataProc = 11;
g_decArgo_phaseSatTrans = 12;
g_decArgo_phaseEndOfProf = 13;
g_decArgo_phaseEndOfLife = 14;
g_decArgo_phaseEmergencyAsc = 15;
g_decArgo_phaseUserDialog = 16;

g_decArgo_treatRaw = 0;
g_decArgo_treatAverage = 1;
g_decArgo_treatAverageAndStDev = 7;
g_decArgo_treatAverageAndMedian = 8;
g_decArgo_treatAverageAndStDevAndMedian = 9;
g_decArgo_treatMedian = 10;
g_decArgo_treatMin = 11;
g_decArgo_treatMax = 12;
g_decArgo_treatStDev = 13;

g_decArgo_longNameOfParamAdjErr = 'Contains the error on the adjusted values as determined by the delayed mode QC process';

% QC flag values (numerical)
g_decArgo_qcDef = -1;
g_decArgo_qcNoQc = 0;
g_decArgo_qcGood = 1;
g_decArgo_qcProbablyGood = 2;
g_decArgo_qcCorrectable = 3;
g_decArgo_qcBad = 4;
g_decArgo_qcChanged = 5;
g_decArgo_qcInterpolated = 8;
g_decArgo_qcMissing = 9;

% QC flag values (char)
g_decArgo_qcStrDef = ' ';
g_decArgo_qcStrNoQc = '0';
g_decArgo_qcStrGood = '1';
g_decArgo_qcStrProbablyGood = '2';
g_decArgo_qcStrCorrectable = '3';
g_decArgo_qcStrBad = '4';
g_decArgo_qcStrChanged = '5';
g_decArgo_qcStrUnused1 = '6';
g_decArgo_qcStrUnused2 = '7';
g_decArgo_qcStrInterpolated = '8';
g_decArgo_qcStrMissing = '9';

% max number of CTD samples in one NOVA sensor data packet (340 bytes max)
g_decArgo_maxCTDSampleInNovaDataPacket = 55;

% max number of CTDO samples in one DOVA sensor data packet (340 bytes max)
g_decArgo_maxCTDOSampleInDovaDataPacket = 33;

% codes for CTS5 phases (used to decode CTD data)
g_decArgo_cts5PhaseDescent = 1;
g_decArgo_cts5PhasePark = 2;
g_decArgo_cts5PhaseDeepProfile = 3;
g_decArgo_cts5PhaseShortPark = 4;
g_decArgo_cts5PhaseAscent = 5;

% codes for CTS5 treatment types (used to decode CTD data)
g_decArgo_cts5Treat_AM_SD_MD = 1; % mean + st dev + median
g_decArgo_cts5Treat_AM_SD = 2; % mean + st dev
g_decArgo_cts5Treat_AM_MD = 3; % mean + median
g_decArgo_cts5Treat_RW = 4; % raw
g_decArgo_cts5Treat_AM = 5; % mean
g_decArgo_cts5Treat_SS = 6; % sub-surface point (last pumped raw measurement)

% DOXY coefficients
g_decArgo_doxy_nomAirPress = 1013.25;
g_decArgo_doxy_nomAirMix = 0.20946;

g_decArgo_doxy_201and202_201_301_d0 = 24.4543;
g_decArgo_doxy_201and202_201_301_d1 = -67.4509;
g_decArgo_doxy_201and202_201_301_d2 = -4.8489;
g_decArgo_doxy_201and202_201_301_d3 = -5.44e-4;
g_decArgo_doxy_201and202_201_301_sPreset = 0;
g_decArgo_doxy_201and202_201_301_b0_aanderaa = -6.24097e-3;
g_decArgo_doxy_201and202_201_301_b1_aanderaa = -6.93498e-3;
g_decArgo_doxy_201and202_201_301_b2_aanderaa = -6.90358e-3;
g_decArgo_doxy_201and202_201_301_b3_aanderaa = -4.29155e-3;
g_decArgo_doxy_201and202_201_301_c0_aanderaa = -3.11680e-7;
g_decArgo_doxy_201and202_201_301_b0 = -6.24523e-3;
g_decArgo_doxy_201and202_201_301_b1 = -7.37614e-3;
g_decArgo_doxy_201and202_201_301_b2 = -1.03410e-3;
g_decArgo_doxy_201and202_201_301_b3 = -8.17083e-3;
g_decArgo_doxy_201and202_201_301_c0 = -4.88682e-7;
g_decArgo_doxy_201and202_201_301_pCoef2 = 0.00025;
g_decArgo_doxy_201and202_201_301_pCoef3 = 0.0328;

g_decArgo_doxy_202_204_204_d0 = 24.4543;
g_decArgo_doxy_202_204_204_d1 = -67.4509;
g_decArgo_doxy_202_204_204_d2 = -4.8489;
g_decArgo_doxy_202_204_204_d3 = -5.44e-4;
g_decArgo_doxy_202_204_204_sPreset = 0;
g_decArgo_doxy_202_204_204_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_204_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_204_b2 = -1.03410e-3;
g_decArgo_doxy_202_204_204_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_204_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_204_pCoef1 = 0.1;
g_decArgo_doxy_202_204_204_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_204_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_202_a0 = 2.00856;
g_decArgo_doxy_202_204_202_a1 = 3.22400;
g_decArgo_doxy_202_204_202_a2 = 3.99063;
g_decArgo_doxy_202_204_202_a3 = 4.80299;
g_decArgo_doxy_202_204_202_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_202_a5 = 1.71069;
g_decArgo_doxy_202_204_202_d0 = 24.4543;
g_decArgo_doxy_202_204_202_d1 = -67.4509;
g_decArgo_doxy_202_204_202_d2 = -4.8489;
g_decArgo_doxy_202_204_202_d3 = -5.44e-4;
g_decArgo_doxy_202_204_202_sPreset = 0;
g_decArgo_doxy_202_204_202_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_202_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_202_b2 = -1.03410e-3;
g_decArgo_doxy_202_204_202_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_202_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_202_pCoef1 = 0.1;
g_decArgo_doxy_202_204_202_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_202_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_203_a0 = 2.00856;
g_decArgo_doxy_202_204_203_a1 = 3.22400;
g_decArgo_doxy_202_204_203_a2 = 3.99063;
g_decArgo_doxy_202_204_203_a3 = 4.80299;
g_decArgo_doxy_202_204_203_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_203_a5 = 1.71069;
g_decArgo_doxy_202_204_203_d0 = 24.4543;
g_decArgo_doxy_202_204_203_d1 = -67.4509;
g_decArgo_doxy_202_204_203_d2 = -4.8489;
g_decArgo_doxy_202_204_203_d3 = -5.44e-4;
g_decArgo_doxy_202_204_203_sPreset = 0;
g_decArgo_doxy_202_204_203_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_203_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_203_b2 = -1.03410e-3;
g_decArgo_doxy_202_204_203_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_203_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_203_pCoef1 = 0.1;
g_decArgo_doxy_202_204_203_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_203_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_302_a0 = 2.00856;
g_decArgo_doxy_202_204_302_a1 = 3.22400;
g_decArgo_doxy_202_204_302_a2 = 3.99063;
g_decArgo_doxy_202_204_302_a3 = 4.80299;
g_decArgo_doxy_202_204_302_a4 = 9.78188e-1;
g_decArgo_doxy_202_204_302_a5 = 1.71069;
g_decArgo_doxy_202_204_302_d0 = 24.4543;
g_decArgo_doxy_202_204_302_d1 = -67.4509;
g_decArgo_doxy_202_204_302_d2 = -4.8489;
g_decArgo_doxy_202_204_302_d3 = -5.44e-4;
g_decArgo_doxy_202_204_302_sPreset = 0;
g_decArgo_doxy_202_204_302_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_302_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_302_b2 = -1.03410e-3;
g_decArgo_doxy_202_204_302_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_302_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_302_pCoef1 = 0.1;
g_decArgo_doxy_202_204_302_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_302_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_302_a0 = 2.00856;
g_decArgo_doxy_202_205_302_a1 = 3.22400;
g_decArgo_doxy_202_205_302_a2 = 3.99063;
g_decArgo_doxy_202_205_302_a3 = 4.80299;
g_decArgo_doxy_202_205_302_a4 = 9.78188e-1;
g_decArgo_doxy_202_205_302_a5 = 1.71069;
g_decArgo_doxy_202_205_302_d0 = 24.4543;
g_decArgo_doxy_202_205_302_d1 = -67.4509;
g_decArgo_doxy_202_205_302_d2 = -4.8489;
g_decArgo_doxy_202_205_302_d3 = -5.44e-4;
g_decArgo_doxy_202_205_302_sPreset = 0;
g_decArgo_doxy_202_205_302_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_302_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_302_b2 = -1.03410e-3;
g_decArgo_doxy_202_205_302_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_302_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_302_pCoef1 = 0.1;
g_decArgo_doxy_202_205_302_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_302_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_303_a0 = 2.00856;
g_decArgo_doxy_202_205_303_a1 = 3.22400;
g_decArgo_doxy_202_205_303_a2 = 3.99063;
g_decArgo_doxy_202_205_303_a3 = 4.80299;
g_decArgo_doxy_202_205_303_a4 = 9.78188e-1;
g_decArgo_doxy_202_205_303_a5 = 1.71069;
g_decArgo_doxy_202_205_303_d0 = 24.4543;
g_decArgo_doxy_202_205_303_d1 = -67.4509;
g_decArgo_doxy_202_205_303_d2 = -4.8489;
g_decArgo_doxy_202_205_303_d3 = -5.44e-4;
g_decArgo_doxy_202_205_303_sPreset = 0;
g_decArgo_doxy_202_205_303_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_303_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_303_b2 = -1.03410e-3;
g_decArgo_doxy_202_205_303_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_303_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_303_pCoef1 = 0.1;
g_decArgo_doxy_202_205_303_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_303_pCoef3 = 0.0419;

g_decArgo_doxy_202_205_304_d0 = 24.4543;
g_decArgo_doxy_202_205_304_d1 = -67.4509;
g_decArgo_doxy_202_205_304_d2 = -4.8489;
g_decArgo_doxy_202_205_304_d3 = -5.44e-4;
g_decArgo_doxy_202_205_304_sPreset = 0;
g_decArgo_doxy_202_205_304_b0 = -6.24523e-3;
g_decArgo_doxy_202_205_304_b1 = -7.37614e-3;
g_decArgo_doxy_202_205_304_b2 = -1.03410e-3;
g_decArgo_doxy_202_205_304_b3 = -8.17083e-3;
g_decArgo_doxy_202_205_304_c0 = -4.88682e-7;
g_decArgo_doxy_202_205_304_pCoef1 = 0.1;
g_decArgo_doxy_202_205_304_pCoef2 = 0.00022;
g_decArgo_doxy_202_205_304_pCoef3 = 0.0419;

g_decArgo_doxy_103_208_307_d0 = 24.4543;
g_decArgo_doxy_103_208_307_d1 = -67.4509;
g_decArgo_doxy_103_208_307_d2 = -4.8489;
g_decArgo_doxy_103_208_307_d3 = -5.44e-4;
g_decArgo_doxy_103_208_307_sPreset = 0;
g_decArgo_doxy_103_208_307_solB0 = -6.24523e-3;
g_decArgo_doxy_103_208_307_solB1 = -7.37614e-3;
g_decArgo_doxy_103_208_307_solB2 = -1.03410e-3;
g_decArgo_doxy_103_208_307_solB3 = -8.17083e-3;
g_decArgo_doxy_103_208_307_solC0 = -4.88682e-7;
g_decArgo_doxy_103_208_307_pCoef1 = 0.115;
g_decArgo_doxy_103_208_307_pCoef2 = 0.00022;
g_decArgo_doxy_103_208_307_pCoef3 = 0.0419;

g_decArgo_doxy_201_203_202_d0 = 24.4543;
g_decArgo_doxy_201_203_202_d1 = -67.4509;
g_decArgo_doxy_201_203_202_d2 = -4.8489;
g_decArgo_doxy_201_203_202_d3 = -5.44e-4;
g_decArgo_doxy_201_203_202_sPreset = 0;
g_decArgo_doxy_201_203_202_b0 = -6.24523e-3;
g_decArgo_doxy_201_203_202_b1 = -7.37614e-3;
g_decArgo_doxy_201_203_202_b2 = -1.03410e-3;
g_decArgo_doxy_201_203_202_b3 = -8.17083e-3;
g_decArgo_doxy_201_203_202_c0 = -4.88682e-7;
g_decArgo_doxy_201_203_202_pCoef1 = 0.1;
g_decArgo_doxy_201_203_202_pCoef2 = 0.00022;
g_decArgo_doxy_201_203_202_pCoef3 = 0.0419;

g_decArgo_doxy_201_202_202_d0 = 24.4543;
g_decArgo_doxy_201_202_202_d1 = -67.4509;
g_decArgo_doxy_201_202_202_d2 = -4.8489;
g_decArgo_doxy_201_202_202_d3 = -5.44e-4;
g_decArgo_doxy_201_202_202_sPreset = 0;
g_decArgo_doxy_201_202_202_b0 = -6.24523e-3;
g_decArgo_doxy_201_202_202_b1 = -7.37614e-3;
g_decArgo_doxy_201_202_202_b2 = -1.03410e-3;
g_decArgo_doxy_201_202_202_b3 = -8.17083e-3;
g_decArgo_doxy_201_202_202_c0 = -4.88682e-7;
g_decArgo_doxy_201_202_202_pCoef1 = 0.1;
g_decArgo_doxy_201_202_202_pCoef2 = 0.00022;
g_decArgo_doxy_201_202_202_pCoef3 = 0.0419;

g_decArgo_doxy_202_204_304_d0 = 24.4543;
g_decArgo_doxy_202_204_304_d1 = -67.4509;
g_decArgo_doxy_202_204_304_d2 = -4.8489;
g_decArgo_doxy_202_204_304_d3 = -5.44e-4;
g_decArgo_doxy_202_204_304_sPreset = 0;
g_decArgo_doxy_202_204_304_b0 = -6.24523e-3;
g_decArgo_doxy_202_204_304_b1 = -7.37614e-3;
g_decArgo_doxy_202_204_304_b2 = -1.03410e-3;
g_decArgo_doxy_202_204_304_b3 = -8.17083e-3;
g_decArgo_doxy_202_204_304_c0 = -4.88682e-7;
g_decArgo_doxy_202_204_304_pCoef1 = 0.1;
g_decArgo_doxy_202_204_304_pCoef2 = 0.00022;
g_decArgo_doxy_202_204_304_pCoef3 = 0.0419;

g_decArgo_doxy_102_207_206_a0 = 2.00907;
g_decArgo_doxy_102_207_206_a1 = 3.22014;
g_decArgo_doxy_102_207_206_a2 = 4.0501;
g_decArgo_doxy_102_207_206_a3 = 4.94457;
g_decArgo_doxy_102_207_206_a4 = -0.256847;
g_decArgo_doxy_102_207_206_a5 = 3.88767;
g_decArgo_doxy_102_207_206_b0 = -0.00624523;
g_decArgo_doxy_102_207_206_b1 = -0.00737614;
g_decArgo_doxy_102_207_206_b2 = -0.00103410;
g_decArgo_doxy_102_207_206_b3 = -0.00817083;
g_decArgo_doxy_102_207_206_c0 = -0.000000488682;

% NITRATE coefficients
g_decArgo_nitrate_a = 1.1500276;
g_decArgo_nitrate_b = 0.02840;
g_decArgo_nitrate_c = -0.3101349;
g_decArgo_nitrate_d = 0.001222;
g_decArgo_nitrate_opticalWavelengthOffset = 208.5;

return;

% ------------------------------------------------------------------------------
% Initialize measurement code values.
%
% SYNTAX :
%  init_measurement_codes(varargin)
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/11/2013 - RNU - creation
% ------------------------------------------------------------------------------
function init_measurement_codes(varargin)

% global measurement codes
global g_MC_Launch;
global g_MC_CycleStart;
global g_MC_DST;
global g_MC_PressureOffset
global g_MC_MinPresInDriftAtParkSupportMeas;
global g_MC_MaxPresInDriftAtParkSupportMeas;
global g_MC_FST;
global g_MC_SpyInDescToPark;
global g_MC_DescProf;
global g_MC_MaxPresInDescToPark;
global g_MC_DET;
global g_MC_DescProfDeepestBin;
global g_MC_PST;
global g_MC_SpyAtPark;
global g_MC_DriftAtPark;
global g_MC_DriftAtParkStd;
global g_MC_DriftAtParkMean;
global g_MC_MinPresInDriftAtPark;
global g_MC_MaxPresInDriftAtPark;
global g_MC_PET;
global g_MC_RPP;
global g_MC_SpyInDescToProf;
global g_MC_MaxPresInDescToProf;
global g_MC_DDET;
global g_MC_DPST;
global g_MC_SpyAtProf;
global g_MC_MinPresInDriftAtProf;
global g_MC_MaxPresInDriftAtProf;
global g_MC_AST;
global g_MC_DownTimeEnd;
global g_MC_AST_Float;
global g_MC_AscProfDeepestBin;
global g_MC_SpyInAscProf;
global g_MC_AscProf;
global g_MC_MedianValueInAscProf;
global g_MC_LastAscPumpedCtd;
global g_MC_AET;
global g_MC_AET_Float;
global g_MC_SpyAtSurface;
global g_MC_NearSurfaceSeriesOfMeas;
global g_MC_TST;
global g_MC_TST_Float;
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;
global g_MC_SingleMeasToTET;
global g_MC_TET;
global g_MC_Grounded;
global g_MC_InAirSingleMeas;
global g_MC_InAirSeriesOfMeas;

% global time status
global g_JULD_STATUS_fill_value;
global g_JULD_STATUS_0;
global g_JULD_STATUS_1;
global g_JULD_STATUS_2;
global g_JULD_STATUS_3;
global g_JULD_STATUS_4;
global g_JULD_STATUS_9;

% RPP status
global g_RPP_STATUS_fill_value;
global g_RPP_STATUS_1;
global g_RPP_STATUS_2;
global g_RPP_STATUS_3;
global g_RPP_STATUS_4;
global g_RPP_STATUS_5;
global g_RPP_STATUS_6;
global g_RPP_STATUS_7;

% measurement code values
g_MC_Launch = 0;
g_MC_CycleStart = 89;
g_MC_DST = 100;
g_MC_PressureOffset = 101;
g_MC_FST = 150;
g_MC_SpyInDescToPark = 189;
g_MC_DescProf = 190;
g_MC_MaxPresInDescToPark = 198;
g_MC_DET = 200;
g_MC_DescProfDeepestBin = 203;
g_MC_PST = 250;
g_MC_MinPresInDriftAtParkSupportMeas = 287;
g_MC_MaxPresInDriftAtParkSupportMeas = 288;
g_MC_SpyAtPark = 289;
g_MC_DriftAtPark = 290;
g_MC_DriftAtParkStd = 294;
g_MC_DriftAtParkMean = 296;
g_MC_MinPresInDriftAtPark = 297;
g_MC_MaxPresInDriftAtPark = 298;
g_MC_PET = 300;
g_MC_RPP = 301;
g_MC_SpyInDescToProf = 389;
g_MC_MaxPresInDescToProf = 398;
g_MC_DDET = 400;
g_MC_DPST = 450;
g_MC_SpyAtProf = 489;
g_MC_MinPresInDriftAtProf = 497;
g_MC_MaxPresInDriftAtProf = 498;
g_MC_AST = 500;
g_MC_DownTimeEnd = 501;
g_MC_AST_Float = 502;
g_MC_AscProfDeepestBin = 503;
g_MC_SpyInAscProf = 589;
g_MC_AscProf = 590;
g_MC_MedianValueInAscProf = 595;
g_MC_LastAscPumpedCtd = 599;
g_MC_AET = 600;
g_MC_AET_Float = 602;
g_MC_SpyAtSurface = 689;
g_MC_NearSurfaceSeriesOfMeas = 690;
g_MC_TST = 700;
g_MC_TST_Float = 701;
g_MC_FMT = 702;
g_MC_Surface = 703;
g_MC_LMT = 704;
g_MC_SingleMeasToTET = 799;
g_MC_TET = 800;
g_MC_Grounded = 901;
g_MC_InAirSingleMeas = 1099;
g_MC_InAirSeriesOfMeas = 1090;

% status values
g_JULD_STATUS_fill_value = ' ';
g_JULD_STATUS_0 = '0';
g_JULD_STATUS_1 = '1';
g_JULD_STATUS_2 = '2';
g_JULD_STATUS_3 = '3';
g_JULD_STATUS_4 = '4';
g_JULD_STATUS_9 = '9';

g_RPP_STATUS_fill_value = ' ';
g_RPP_STATUS_1 = '1';
g_RPP_STATUS_2 = '2';
g_RPP_STATUS_3 = '3';
g_RPP_STATUS_4 = '4';
g_RPP_STATUS_5 = '5';
g_RPP_STATUS_6 = '6';
g_RPP_STATUS_7 = '7';

return;

% ------------------------------------------------------------------------------
% Convert a gregorian date to a julian 1950 date.
%
% SYNTAX :
%   [o_julDay] = gregorian_2_julian_dec_argo(a_gregorianDate)
%
% INPUT PARAMETERS :
%   a_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% OUTPUT PARAMETERS :
%   o_julDay : julian 1950 date
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_julDay] = gregorian_2_julian_dec_argo(a_gregorianDate)

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;

% output parameters initialization
o_julDay = g_decArgo_dateDef;

if (~strcmp(deblank(a_gregorianDate(:)), ''))
   
   if (length(a_gregorianDate) == 16)
      a_gregorianDate = [a_gregorianDate ':00'];
   end
   
   res = sscanf(a_gregorianDate, '%d/%d/%d %d:%d:%d');
   if ((res(1) ~= 9999) && (res(2) ~= 99) && (res(3) ~= 99) && ...
         (res(4) ~= 99) && (res(5) ~= 99))
      
      o_julDay = datenum(a_gregorianDate, 'yyyy/mm/dd HH:MM:SS') - g_decArgo_janFirst1950InMatlab;
   end
end

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
%   01/15/2014 - RNU - creation
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
% Check if a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present_dec_argo(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present_dec_argo(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar= 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break;
   end
end

return;

% ------------------------------------------------------------------------------
% Get Argo attributes for a given parameter.
%
% SYNTAX :
%  [o_attributeStruct] = get_netcdf_param_attributes(a_paramName)
%
% INPUT PARAMETERS :
%   a_paramName : parameter name
%
% OUTPUT PARAMETERS :
%   o_attributeStruct : parameter associated attributes
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/25/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_attributeStruct] = get_netcdf_param_attributes(a_paramName)

[o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);

% % Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
% global g_decArgo_floatTransType;
%
%
% if (g_decArgo_floatTransType == 1)
%
%    % Argos floats
%
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%
% elseif (g_decArgo_floatTransType == 2)
%
%    % Iridium RUDICS floats
%
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%
% elseif (g_decArgo_floatTransType == 3)
%
%    % Iridium SBD floats
%
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%
% elseif (g_decArgo_floatTransType == 4)
%
%    % Iridium SBD ProvBioII floats
%
%    [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName);
%
% end

return;

% ------------------------------------------------------------------------------
% Get Argo attributes for a given parameter.
%
% SYNTAX :
%  [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName)
%
% INPUT PARAMETERS :
%   a_paramName : parameter name
%
% OUTPUT PARAMETERS :
%   o_attributeStruct : parameter associated attributes
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/30/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_attributeStruct] = get_netcdf_param_attributes_3_1(a_paramName)

% output parameters initialization
o_attributeStruct = [];


paramName = a_paramName;
again = 1;
while (again ~= 0)
   
   switch (paramName)
      
      case 'JULD'
         o_attributeStruct = struct('name', 'JULD', ...
            'longName', 'Julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME', ...
            'standardName', 'time', ...
            'units', 'days since 1950-01-01 00:00:00 UTC', ...
            'conventions', 'Relative julian days with decimal part (as parts of day)', ...
            'fillValue', double(999999), ...
            'axis', 'T', ...
            'paramType', '', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'LATITUDE'
         o_attributeStruct = struct('name', 'LATITUDE', ...
            'longName', 'Latitude of each location', ...
            'standardName', 'latitude', ...
            'units', 'degree_north', ...
            'fillValue', double(99999), ...
            'validMin', double(-90), ...
            'validMax', double(90), ...
            'axis', 'Y', ...
            'paramType', '', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'LONGITUDE'
         o_attributeStruct = struct('name', 'LONGITUDE', ...
            'longName', 'Longitude of each location', ...
            'standardName', 'longitude', ...
            'units', 'degree_east', ...
            'fillValue', double(99999), ...
            'validMin', double(-180), ...
            'validMax', double(180), ...
            'axis', 'X', ...
            'paramType', '', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % C PARAMETERS
         
      case 'CNDC'
         o_attributeStruct = struct('name', 'CNDC', ...
            'longName', 'Electrical conductivity', ...
            'standardName', 'sea_water_electrical_conductivity', ...
            'fillValue', single(99999), ...
            'units', 'mhos/m', ...
            'validMin', single(0), ...
            'validMax', single(8.5), ...
            'axis', '', ...
            'cFormat', '%10.4f', ...
            'fortranFormat', 'F10.4', ...
            'resolution', single(0.0001), ...
            'paramType', 'c', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'PRES'
         o_attributeStruct = struct('name', 'PRES', ...
            'longName', 'Sea water pressure, equals 0 at sea-level', ...
            'standardName', 'sea_water_pressure', ...
            'fillValue', single(99999), ...
            'units', 'decibar', ...
            'validMin', single(0), ...
            'validMax', single(12000), ...
            'axis', 'Z', ...
            'cFormat', '%7.1f', ...
            'fortranFormat', 'F7.1', ...
            'resolution', single(0.1), ...
            'paramType', 'c', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'TEMP'
         o_attributeStruct = struct('name', 'TEMP', ...
            'longName', 'Sea temperature in-situ ITS-90 scale', ...
            'standardName', 'sea_water_temperature', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.5), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'c', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'PSAL'
         o_attributeStruct = struct('name', 'PSAL', ...
            'longName', 'Practical salinity', ...
            'standardName', 'sea_water_salinity', ...
            'fillValue', single(99999), ...
            'units', 'psu', ...
            'validMin', single(2), ...
            'validMax', single(41), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'c', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % B PARAMETERS
         
      case 'DOXY'
         o_attributeStruct = struct('name', 'DOXY', ...
            'longName', 'Dissolved oxygen', ...
            'standardName', 'moles_of_oxygen_per_unit_mass_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'micromole/kg', ...
            'validMin', single(-5), ...
            'validMax', single(600), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'BBP700'
         o_attributeStruct = struct('name', 'BBP700', ...
            'longName', 'Particle backscattering at 700 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'm-1', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'BBP532'
         o_attributeStruct = struct('name', 'BBP532', ...
            'longName', 'Particle backscattering at 532 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'm-1', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'TURBIDITY'
         o_attributeStruct = struct('name', 'TURBIDITY', ...
            'longName', 'Sea water turbidity', ...
            'standardName', 'sea_water_turbidity', ...
            'fillValue', single(99999), ...
            'units', 'ntu', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'CP660'
         o_attributeStruct = struct('name', 'CP660', ...
            'longName', 'Particle beam attenuation at 660 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'm-1', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'CP660_STD'
         o_attributeStruct = struct('name', 'CP660_STD', ...
            'longName', 'Standard deviation of particle beam attenuation at 660 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'm-1', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'CP660_MED'
         o_attributeStruct = struct('name', 'CP660_MED', ...
            'longName', 'Median value of particle beam attenuation at 660 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'm-1', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'CHLA'
         o_attributeStruct = struct('name', 'CHLA', ...
            'longName', 'Chlorophyll-A', ...
            'standardName', 'mass_concentration_of_chlorophyll_a_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'mg/m3', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.025), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'CDOM'
         o_attributeStruct = struct('name', 'CDOM', ...
            'longName', 'Concentration of coloured dissolved organic matter in sea water', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'ppb', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'NITRATE'
         o_attributeStruct = struct('name', 'NITRATE', ...
            'longName', 'Nitrate', ...
            'standardName', 'moles_of_nitrate_per_unit_mass_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'micromole/kg', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.2f', ...
            'fortranFormat', 'F.2', ...
            'resolution', single(0.01), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'BISULFIDE'
         o_attributeStruct = struct('name', 'BISULFIDE', ...
            'longName', 'Bisulfide', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'micromole/kg', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'PH_IN_SITU_TOTAL'
         o_attributeStruct = struct('name', 'PH_IN_SITU_TOTAL', ...
            'longName', 'pH', ...
            'standardName', 'sea_water_ph_reported_on_total_scale', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'DOWN_IRRADIANCE380'
         o_attributeStruct = struct('name', 'DOWN_IRRADIANCE380', ...
            'longName', 'Downwelling irradiance at 380 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'W/m^2/nm', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.6f', ...
            'fortranFormat', 'F.6', ...
            'resolution', single(0.000001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'DOWN_IRRADIANCE412'
         o_attributeStruct = struct('name', 'DOWN_IRRADIANCE412', ...
            'longName', 'Downwelling irradiance at 412 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'W/m^2/nm', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.6f', ...
            'fortranFormat', 'F.6', ...
            'resolution', single(0.000001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'DOWN_IRRADIANCE490'
         o_attributeStruct = struct('name', 'DOWN_IRRADIANCE490', ...
            'longName', 'Downwelling irradiance at 490 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'W/m^2/nm', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.6f', ...
            'fortranFormat', 'F.6', ...
            'resolution', single(0.000001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'UP_RADIANCE'
         o_attributeStruct = struct('name', 'UP_RADIANCE', ...
            'longName', 'Upwelling radiance at x nanometers', ...
            'standardName', 'upwelling_radiance_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'W/m^2/nm/sr', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
      case 'DOWNWELLING_PAR'
         o_attributeStruct = struct('name', 'DOWNWELLING_PAR', ...
            'longName', 'Downwelling photosynthetic available radiation', ...
            'standardName', 'downwelling_photosynthetic_photon_flux_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'microMoleQuanta/m^2/sec', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'b', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 1);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % I PARAMETERS
         
      case 'PRES_MED'
         o_attributeStruct = struct('name', 'PRES_MED', ...
            'longName', 'Median value of sea water pressure, equals 0 at sea-level', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'decibar', ...
            'validMin', single(0), ...
            'validMax', single(12000), ...
            'axis', '', ...
            'cFormat', '%7.1f', ...
            'fortranFormat', 'F7.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_STD'
         o_attributeStruct = struct('name', 'TEMP_STD', ...
            'longName', 'Standard deviation of sea temperature in-situ ITS-90 scale', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.5), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_MED'
         o_attributeStruct = struct('name', 'TEMP_MED', ...
            'longName', 'Median value of sea temperature in-situ ITS-90 scale', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.5), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PSAL_STD'
         o_attributeStruct = struct('name', 'PSAL_STD', ...
            'longName', 'Standard deviation of practical salinity', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'psu', ...
            'validMin', single(2), ...
            'validMax', single(41), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PSAL_MED'
         o_attributeStruct = struct('name', 'PSAL_MED', ...
            'longName', 'Median value of practical salinity', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'psu', ...
            'validMin', single(2), ...
            'validMax', single(41), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_DOXY'
         o_attributeStruct = struct('name', 'TEMP_DOXY', ...
            'longName', 'Sea temperature from oxygen sensor ITS-90 scale', ...
            'standardName', 'temperature_of_sensor_for_oxygen_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.0), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_DOXY_STD'
         o_attributeStruct = struct('name', 'TEMP_DOXY_STD', ...
            'longName', 'Standard deviation of sea temperature from oxygen sensor ITS-90 scale', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.0), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_DOXY_MED'
         o_attributeStruct = struct('name', 'TEMP_DOXY_MED', ...
            'longName', 'Median value of sea temperature from oxygen sensor ITS-90 scale', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.0), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'VOLTAGE_DOXY'
         o_attributeStruct = struct('name', 'VOLTAGE_DOXY', ...
            'longName', 'Voltage reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', single(0), ...
            'validMax', single(100), ...
            'axis', '', ...
            'cFormat', '%5.2f', ...
            'fortranFormat', 'F5.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FREQUENCY_DOXY'
         o_attributeStruct = struct('name', 'FREQUENCY_DOXY', ...
            'longName', 'Frequency reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'hertz', ...
            'validMin', single(0), ...
            'validMax', single(25000), ...
            'axis', '', ...
            'cFormat', '%7.1f', ...
            'fortranFormat', 'F7.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'COUNT_DOXY'
         o_attributeStruct = struct('name', 'COUNT_DOXY', ...
            'longName', 'Count reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%5.2f', ...
            'fortranFormat', 'F5.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BPHASE_DOXY'
         o_attributeStruct = struct('name', 'BPHASE_DOXY', ...
            'longName', 'Uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'DPHASE_DOXY'
         o_attributeStruct = struct('name', 'DPHASE_DOXY', ...
            'longName', 'Calibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TPHASE_DOXY'
         o_attributeStruct = struct('name', 'TPHASE_DOXY', ...
            'longName', 'Uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'C1PHASE_DOXY'
         o_attributeStruct = struct('name', 'C1PHASE_DOXY', ...
            'longName', 'Uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'C1PHASE_DOXY_STD'
         o_attributeStruct = struct('name', 'C1PHASE_DOXY_STD', ...
            'longName', 'Standard deviation of uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'C1PHASE_DOXY_MED'
         o_attributeStruct = struct('name', 'C1PHASE_DOXY_MED', ...
            'longName', 'Median value of uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'C2PHASE_DOXY'
         o_attributeStruct = struct('name', 'C2PHASE_DOXY', ...
            'longName', 'Uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(0), ...
            'validMax', single(15), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'C2PHASE_DOXY_STD'
         o_attributeStruct = struct('name', 'C2PHASE_DOXY_STD', ...
            'longName', 'Standard deviation of uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(0), ...
            'validMax', single(15), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'C2PHASE_DOXY_MED'
         o_attributeStruct = struct('name', 'C2PHASE_DOXY_MED', ...
            'longName', 'Median value of uncalibrated phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(0), ...
            'validMax', single(15), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'MOLAR_DOXY'
         o_attributeStruct = struct('name', 'MOLAR_DOXY', ...
            'longName', 'Uncompensated (pressure and salinity) oxygen concentration reported by the oxygen sensor', ...
            'standardName', 'mole_concentration_of_dissolved_molecular_oxygen_in_sea_water', ...
            'fillValue', single(99999), ...
            'units', 'micromole/l', ...
            'validMin', single(0), ...
            'validMax', single(650), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PHASE_DELAY_DOXY'
         o_attributeStruct = struct('name', 'PHASE_DELAY_DOXY', ...
            'longName', 'Phase delay reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'microsecond', ...
            'validMin', single(0), ...
            'validMax', single(99999), ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'MLPL_DOXY'
         o_attributeStruct = struct('name', 'MLPL_DOXY', ...
            'longName', 'Oxygen concentration reported by the oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'ml/l', ...
            'validMin', single(0), ...
            'validMax', single(650), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'NB_SAMPLE'
         o_attributeStruct = struct('name', 'NB_SAMPLE', ...
            'longName', 'Number of samples in bin', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'RPHASE_DOXY'
         o_attributeStruct = struct('name', 'RPHASE_DOXY', ...
            'longName', 'Uncalibrated red phase shift reported by oxygen sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree', ...
            'validMin', single(10), ...
            'validMax', single(70), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PPOX_DOXY'
         o_attributeStruct = struct('name', 'PPOX_DOXY', ...
            'longName', 'Partial pressure of oxygen', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'millibar', ...
            'validMin', single(-5), ...
            'validMax', single(5000), ...
            'axis', '', ...
            'cFormat', '%8.2f', ...
            'fortranFormat', 'F8.2', ...
            'resolution', single(0.01), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BETA_BACKSCATTERING700'
         o_attributeStruct = struct('name', 'BETA_BACKSCATTERING700', ...
            'longName', 'Total angle specific volume from backscattering sensor at 700 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BETA_BACKSCATTERING700_STD'
         o_attributeStruct = struct('name', 'BETA_BACKSCATTERING700_STD', ...
            'longName', 'Standard deviation of total angle specific volume from backscattering sensor at 700 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BETA_BACKSCATTERING700_MED'
         o_attributeStruct = struct('name', 'BETA_BACKSCATTERING700_MED', ...
            'longName', 'Median value of total angle specific volume from backscattering sensor at 700 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BETA_BACKSCATTERING532'
         o_attributeStruct = struct('name', 'BETA_BACKSCATTERING532', ...
            'longName', 'Total angle specific volume from backscattering sensor at 532 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BETA_BACKSCATTERING532_STD'
         o_attributeStruct = struct('name', 'BETA_BACKSCATTERING532_STD', ...
            'longName', 'Standard deviation of total angle specific volume from backscattering sensor at 532 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BETA_BACKSCATTERING532_MED'
         o_attributeStruct = struct('name', 'BETA_BACKSCATTERING532_MED', ...
            'longName', 'Median value of total angle specific volume from backscattering sensor at 532 nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_CHLA'
         o_attributeStruct = struct('name', 'FLUORESCENCE_CHLA', ...
            'longName', 'Chlorophyll-A signal from fluorescence sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_CHLA_STD'
         o_attributeStruct = struct('name', 'FLUORESCENCE_CHLA_STD', ...
            'longName', 'Standard deviation of chlorophyll-A signal from fluorescence sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_CHLA_MED'
         o_attributeStruct = struct('name', 'FLUORESCENCE_CHLA_MED', ...
            'longName', 'Median value of chlorophyll-A signal from fluorescence sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_VOLTAGE_CHLA'
         o_attributeStruct = struct('name', 'FLUORESCENCE_VOLTAGE_CHLA', ...
            'longName', 'Chlorophyll-A signal from analogic fluorescence sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_VOLTAGE_CHLA_STD'
         o_attributeStruct = struct('name', 'FLUORESCENCE_VOLTAGE_CHLA_STD', ...
            'longName', 'Standard deviation of chlorophyll-A signal from analogic fluorescence sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_VOLTAGE_CHLA_MED'
         o_attributeStruct = struct('name', 'FLUORESCENCE_VOLTAGE_CHLA_MED', ...
            'longName', 'Median value of chlorophyll-A signal from analogic fluorescence sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_CPU_CHLA'
         o_attributeStruct = struct('name', 'TEMP_CPU_CHLA', ...
            'longName', 'Thermistor signal from backscattering sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_CDOM'
         o_attributeStruct = struct('name', 'FLUORESCENCE_CDOM', ...
            'longName', 'Raw fluorescence from coloured dissolved organic matter sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_CDOM_STD'
         o_attributeStruct = struct('name', 'FLUORESCENCE_CDOM_STD', ...
            'longName', 'Standard deviation of raw fluorescence from coloured dissolved organic matter sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FLUORESCENCE_CDOM_MED'
         o_attributeStruct = struct('name', 'FLUORESCENCE_CDOM_MED', ...
            'longName', 'Median value of raw fluorescence from coloured dissolved organic matter sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'HUMIDITY_NITRATE'
         o_attributeStruct = struct('name', 'HUMIDITY_NITRATE', ...
            'longName', 'Relative humidity inside the SUNA sensor (If > 50% There is a leak)', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'percent', ...
            'validMin', single(0), ...
            'validMax', single(100), ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'SIDE_SCATTERING_TURBIDITY'
         o_attributeStruct = struct('name', 'SIDE_SCATTERING_TURBIDITY', ...
            'longName', 'Turbidity signal from side scattering sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'SIDE_SCATTERING_TURBIDITY_STD'
         o_attributeStruct = struct('name', 'SIDE_SCATTERING_TURBIDITY_STD', ...
            'longName', 'Standard deviation of turbidity signal from side scattering sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'SIDE_SCATTERING_TURBIDITY_MED'
         o_attributeStruct = struct('name', 'SIDE_SCATTERING_TURBIDITY_MED', ...
            'longName', 'Median value of turbidity signal from side scattering sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'VOLTAGE_TURBIDITY'
         o_attributeStruct = struct('name', 'VOLTAGE_TURBIDITY', ...
            'longName', 'Turbidity signal from side scattering analogic sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'VOLTAGE_TURBIDITY_STD'
         o_attributeStruct = struct('name', 'VOLTAGE_TURBIDITY_STD', ...
            'longName', 'Standard deviation of turbidity signal from side scattering analogic sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'VOLTAGE_TURBIDITY_MED'
         o_attributeStruct = struct('name', 'VOLTAGE_TURBIDITY_MED', ...
            'longName', 'Median value of turbidity signal from side scattering analogic sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_NITRATE'
         o_attributeStruct = struct('name', 'TEMP_NITRATE', ...
            'longName', 'Internal temperature of the SUNA sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_SPECTROPHOTOMETER_NITRATE'
         o_attributeStruct = struct('name', 'TEMP_SPECTROPHOTOMETER_NITRATE', ...
            'longName', 'Temperature of the spectrometer', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.1f', ...
            'fortranFormat', 'F.1', ...
            'resolution', single(0.1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION'
         o_attributeStruct = struct('name', 'TRANSMITTANCE_PARTICLE_BEAM_ATTENUATION', ...
            'longName', 'Beam attenuation from transmissometer sensor at x nanometers', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'UV_INTENSITY_NITRATE'
         o_attributeStruct = struct('name', 'UV_INTENSITY_NITRATE', ...
            'longName', 'Intensity of ultra violet flux from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'UV_INTENSITY_DARK_NITRATE'
         o_attributeStruct = struct('name', 'UV_INTENSITY_DARK_NITRATE', ...
            'longName', 'Intensity of ultra violet flux dark measurement from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'UV_INTENSITY_DARK_NITRATE_STD'
         o_attributeStruct = struct('name', 'UV_INTENSITY_DARK_NITRATE_STD', ...
            'longName', 'Standard deviation of intensity of ultra violet flux dark measurement from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'UV_INTENSITY_DARK_SEAWATER_NITRATE'
         o_attributeStruct = struct('name', 'UV_INTENSITY_DARK_SEAWATER_NITRATE', ...
            'longName', 'Intensity of ultra-violet flux dark sea water from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'E_NITRATE'
         o_attributeStruct = struct('name', 'E_NITRATE', ...
            'longName', 'E nitrate', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'l/micromol cm', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'UV_INTENSITY_REF_NITRATE'
         o_attributeStruct = struct('name', 'UV_INTENSITY_REF_NITRATE', ...
            'longName', 'Ultra-violet intensity reference from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'E_SWA_NITRATE'
         o_attributeStruct = struct('name', 'E_SWA_NITRATE', ...
            'longName', 'TBD', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'TEMP_CAL_NITRATE'
         o_attributeStruct = struct('name', 'TEMP_CAL_NITRATE', ...
            'longName', 'Temperature calibration from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'degree_Celsius', ...
            'validMin', single(-2.5), ...
            'validMax', single(40), ...
            'axis', '', ...
            'cFormat', '%9.3f', ...
            'fortranFormat', 'F9.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'ABSORBANCE_COR_NITRATE'
         o_attributeStruct = struct('name', 'ABSORBANCE_COR_NITRATE', ...
            'longName', 'Absorbance corXXX from nitrate sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'MOLAR_NITRATE'
         o_attributeStruct = struct('name', 'MOLAR_NITRATE', ...
            'longName', 'Nitrate', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'micromole/l', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'FIT_ERROR_NITRATE'
         o_attributeStruct = struct('name', 'FIT_ERROR_NITRATE', ...
            'longName', 'Nitrate fit error', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'VRS_PH'
         o_attributeStruct = struct('name', 'VRS_PH', ...
            'longName', 'Voltage difference between reference and source from pH sensor', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'volt', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PH_IN_SITU_FREE'
         o_attributeStruct = struct('name', 'PH_IN_SITU_FREE', ...
            'longName', 'pH', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PH_IN_SITU_SEAWATER'
         o_attributeStruct = struct('name', 'PH_IN_SITU_SEAWATER', ...
            'longName', 'pH', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'dimensionless', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%.3f', ...
            'fortranFormat', 'F.3', ...
            'resolution', single(0.001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE380'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE380', ...
            'longName', 'Raw downwelling irradiance at 380 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE380_STD'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE380_STD', ...
            'longName', 'Standard deviation of raw downwelling irradiance at 380 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE380_MED'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE380_MED', ...
            'longName', 'Median value of raw downwelling irradiance at 380 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE412'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE412', ...
            'longName', 'Raw downwelling irradiance at 412 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE412_STD'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE412_STD', ...
            'longName', 'Standard deviation of raw downwelling irradiance at 412 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE412_MED'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE412_MED', ...
            'longName', 'Median value of raw downwelling irradiance at 412 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE490'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE490', ...
            'longName', 'Raw downwelling irradiance at 490 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE490_STD'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE490_STD', ...
            'longName', 'Standard deviation of raw downwelling irradiance at 490 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_IRRADIANCE490_MED'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_IRRADIANCE490_MED', ...
            'longName', 'Median value of raw downwelling irradiance at 490 nanometers', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_PAR'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_PAR', ...
            'longName', 'Raw downwelling photosynthetic available radiation', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_PAR_STD'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_PAR_STD', ...
            'longName', 'Standard deviation of raw downwelling photosynthetic available radiation', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'RAW_DOWNWELLING_PAR_MED'
         o_attributeStruct = struct('name', 'RAW_DOWNWELLING_PAR_MED', ...
            'longName', 'Median value of raw downwelling photosynthetic available radiation', ...
            'standardName', '', ...
            'fillValue', double(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', double(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
      case 'MTIME'
         o_attributeStruct = struct('name', 'MTIME', ...
            'longName', 'Fractional day of the individual measurement relative to JULD of the station', ...
            'standardName', 'measurement_time', ...
            'fillValue', double(99999), ...
            'units', 'days', ...
            'validMin', '-3.0', ...
            'validMax', '3.0', ...
            'axis', '', ...
            'cFormat', '%.6f', ...
            'fortranFormat', 'F.6', ...
            'resolution', single(0.000001), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 0);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TEMPORARY PARAMETERS
         
      case 'JULD_LEVEL'
         o_attributeStruct = struct('name', 'JULD_LEVEL', ...
            'longName', 'Julian day (UTC) of each profile level measurement relative to REFERENCE_DATE_TIME', ...
            'standardName', 'time', ...
            'units', 'days since 1950-01-01 00:00:00 UTC', ...
            'conventions', 'Relative julian days with decimal part (as parts of day)', ...
            'fillValue', double(999999), ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '', ...
            'fortranFormat', '', ...
            'resolution', '', ...
            'paramType', '', ...
            'paramNcType', 'NC_DOUBLE', ...
            'adjAllowed', 1);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TEMPORARY PARAMETERS
         
      case 'VALVE_ACTION_FLAG'
         o_attributeStruct = struct('name', 'VALVE_ACTION_FLAG', ...
            'longName', 'Valve action flag', ...
            'standardName', '', ...
            'fillValue', int32(-1), ...
            'units', 'boolean', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', int32(1), ...
            'paramType', 't', ...
            'paramNcType', 'NC_INT', ...
            'adjAllowed', 0);
         
      case 'PUMP_ACTION_FLAG'
         o_attributeStruct = struct('name', 'PUMP_ACTION_FLAG', ...
            'longName', 'Pump action flag', ...
            'standardName', '', ...
            'fillValue', int32(-1), ...
            'units', 'boolean', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', int32(1), ...
            'paramType', 't', ...
            'paramNcType', 'NC_INT', ...
            'adjAllowed', 0);
         
      case 'VALVE_ACTION_DURATION'
         o_attributeStruct = struct('name', 'VALVE_ACTION_DURATION', ...
            'longName', 'Duration of valve action', ...
            'standardName', '', ...
            'fillValue', single(-1), ...
            'units', 'csec', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%f', ...
            'fortranFormat', 'F', ...
            'resolution', single(1), ...
            'paramType', 't', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'PUMP_ACTION_DURATION'
         o_attributeStruct = struct('name', 'PUMP_ACTION_DURATION', ...
            'longName', 'Duration of pump action', ...
            'standardName', '', ...
            'fillValue', single(-1), ...
            'units', 'csec', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%f', ...
            'fortranFormat', 'F', ...
            'resolution', single(1), ...
            'paramType', 't', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'BLADDER_INFLATED_FLAG'
         o_attributeStruct = struct('name', 'BLADDER_INFLATED_FLAG', ...
            'longName', 'Sample while bladder is inflated flag', ...
            'standardName', '', ...
            'fillValue', int32(-1), ...
            'units', 'boolean', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', int32(1), ...
            'paramType', 't', ...
            'paramNcType', 'NC_INT', ...
            'adjAllowed', 0);
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % TEMPORARY PARAMETERS
         
      case 'BLUE_REF'
         o_attributeStruct = struct('name', 'BLUE_REF', ...
            'longName', 'BlueRef from 082807 Apex floats (unknow parameter)', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'NTU_REF'
         o_attributeStruct = struct('name', 'NTU_REF', ...
            'longName', 'NtuRef from 082807 Apex floats (unknow parameter)', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'IFREMER_TEMPORARY_BB_SIG'
         o_attributeStruct = struct('name', 'IFREMER_TEMPORARY_BB_SIG', ...
            'longName', 'BbSig from 020110 Apex floats', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      case 'IFREMER_TEMPORARY_T_SIG'
         o_attributeStruct = struct('name', 'IFREMER_TEMPORARY_T_SIG', ...
            'longName', 'TSig from 020110 Apex floats', ...
            'standardName', '', ...
            'fillValue', single(99999), ...
            'units', 'count', ...
            'validMin', '', ...
            'validMax', '', ...
            'axis', '', ...
            'cFormat', '%d', ...
            'fortranFormat', 'I', ...
            'resolution', single(1), ...
            'paramType', 'i', ...
            'paramNcType', 'NC_FLOAT', ...
            'adjAllowed', 0);
         
      otherwise
         
         if (again == 1)
            % names like <PARAM>2 or <PARAM>_2
            if (isletter(a_paramName(end-1)) && ~isletter(a_paramName(end)))
               % <PARAM>2
               paramName = a_paramName(1:end-1);
            elseif ((a_paramName(end-1) == '_') && ~isletter(a_paramName(end)))
               % <PARAM>_2
               paramName = a_paramName(1:end-2);
            end
            again = 2;
         elseif (again == 2)
            % names like <PARAM>2_STD or <PARAM>_2_STD or <PARAM>2_MED or
            % <PARAM>_2_MED
            if ((length(a_paramName) > 4) && ...
                  (strcmp(a_paramName(end-3:end), '_STD') || strcmp(a_paramName(end-3:end), '_MED')))
               if (isletter(a_paramName(end-5)) && ~isletter(a_paramName(end-4)))
                  % <PARAM>2_STD or <PARAM>2_MED
                  paramName = a_paramName(1:end-5);
               elseif ((a_paramName(end-5) == '_') && ~isletter(a_paramName(end-4)))
                  paramName = a_paramName(1:end-6);
               end
            end
            again = 3;
         else
            % don't print any WARNING for b parameter like <PARAM>_STD or
            % <PARAM>_MED
            paramName = '';
            if (~isempty(strfind(a_paramName, '_STD')))
               pos = strfind(a_paramName, '_STD');
               paramName = a_paramName(1:pos-1);
            elseif (~isempty(strfind(a_paramName, '_MED')))
               pos = strfind(a_paramName, '_MED');
               paramName = a_paramName(1:pos-1);
            end
            
            printWarning = 1;
            if (~isempty(paramName))
               [attStruct] = get_netcdf_param_attributes_3_1(paramName);
               if (attStruct.paramType == 'b')
                  printWarning = 0;
               end
            end
            
            if (printWarning == 1)
               fprintf('WARNING: Attribute list no yet defined for parameter %s\n', a_paramName);
            end
            
            again = 0;
         end
   end
   if (~isempty(o_attributeStruct))
      if ((again == 2) || (again == 3))
         o_attributeStruct.name = a_paramName;
      end
      again = 0;
   end
end

return;

% ------------------------------------------------------------------------------
% Remove a given diretory and all its contents.
%
% SYNTAX :
%  [o_ok] = remove_directory(a_dirPathName)
%
% INPUT PARAMETERS :
%   a_dirPathName : path name of the directory to remove
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/25/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = remove_directory(a_dirPathName)

% output parameters initialization
o_ok = 0;

NB_ATTEMPTS = 10;

if (exist(a_dirPathName, 'dir') == 7)
   [status, ~, ~] = rmdir(a_dirPathName, 's');
   if (status ~= 1)
      nbAttemps = 0;
      while ((nbAttemps < NB_ATTEMPTS) && (status ~= 1))
         pause(1);
         [status, ~, ~] = rmdir(a_dirPathName, 's');
         nbAttemps = nbAttemps + 1;
      end
      if (status ~= 1)
         fprintf('ERROR: Unable to remove directory: %s\n', a_dirPathName);
         return;
      end
   end
end

o_ok = 1;

return;

% ------------------------------------------------------------------------------
% Check if a given attribute of a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = att_is_present_dec_argo(a_ncId, a_varName, a_attName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%   a_attName : attribute name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the attribute is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/05/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = att_is_present_dec_argo(a_ncId, a_varName, a_attName)

o_present = 0;

if (var_is_present_dec_argo(a_ncId, a_varName))
   
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, netcdf.inqVarID(a_ncId, a_varName));
   
   for idAtt = 0:nbAtts-1
      attName = netcdf.inqAttName(a_ncId, netcdf.inqVarID(a_ncId, a_varName), idAtt);
      if (strcmp(attName, a_attName))
         o_present = 1;
         break;
      end
   end
   
end

return;

% ------------------------------------------------------------------------------
% Convert a julian 1950 date to a gregorian date.
%
% SYNTAX :
%   [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = julian_2_gregorian_dec_argo(a_julDay)

% default values
global g_decArgo_dateDef;

% output parameters initialization
o_gregorianDate = [];

[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld_dec_argo(a_julDay);

for idDate = 1:length(dayNum)
   if (a_julDay(idDate) ~= g_decArgo_dateDef)
      o_gregorianDate = [o_gregorianDate; sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
         yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate))];
   else
      o_gregorianDate = [o_gregorianDate; '9999/99/99 99:99:99'];
   end
end

return;

% ------------------------------------------------------------------------------
% Split of a julian 1950 date in gregorian date parts.
%
% SYNTAX :
%   [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld_dec_argo(a_juld)
%
% INPUT PARAMETERS :
%   a_juld : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_dayNum : julian 1950 day number
%   o_day    : gregorian day
%   o_month  : gregorian month
%   o_year   : gregorian year
%   o_hour   : gregorian hour
%   o_min    : gregorian minute
%   o_sec    : gregorian second
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld_dec_argo(a_juld)

% output parameters initialization
o_dayNum = [];
o_day = [];
o_month = [];
o_year = [];
o_hour = [];
o_min = [];
o_sec = [];

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


for id = 1:length(a_juld)
   juldStr = num2str(a_juld(id), 11);
   res = sscanf(juldStr, '%5d.%6d');
   o_day(id) = res(1);
   
   if (o_day(id) ~= fix(g_decArgo_dateDef))
      o_dayNum(id) = fix(a_juld(id));
      
      dateNum = o_day(id) + g_decArgo_janFirst1950InMatlab;
      ymd = datestr(dateNum, 'yyyy/mm/dd');
      res = sscanf(ymd, '%4d/%2d/%d');
      o_year(id) = res(1);
      o_month(id) = res(2);
      o_day(id) = res(3);
      
      hms = datestr(a_juld(id), 'HH:MM:SS');
      res = sscanf(hms, '%d:%d:%d');
      o_hour(id) = res(1);
      o_min(id) = res(2);
      o_sec(id) = res(3);
   else
      o_dayNum(id) = 99999;
      o_day(id) = 99;
      o_month(id) = 99;
      o_year(id) = 9999;
      o_hour(id) = 99;
      o_min(id) = 99;
      o_sec(id) = 99;
   end
   
end

return;

% ------------------------------------------------------------------------------
% Retrieve current UTC date and time.
%
% SYNTAX :
%  [o_now] = now_utc
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_now : current UTC date and time
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_now] = now_utc

o_now = (java.lang.System.currentTimeMillis/8.64e7) + datenum('1970', 'yyyy');

return;

% ------------------------------------------------------------------------------
% Associate an institution name to a given data centre information.
%
% SYNTAX :
%  [o_institution] = get_institution_from_data_centre(a_dataCentre)
%
% INPUT PARAMETERS :
%   a_dataCentre : data centre
%
% OUTPUT PARAMETERS :
%   o_institution : institution
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_institution] = get_institution_from_data_centre(a_dataCentre)

o_institution = ' ';

% current float WMO number
global g_decArgo_floatNum;


switch (a_dataCentre)
   
   case 'BO'
      o_institution = 'BODC';
   case 'CS'
      o_institution = 'CSIRO';
   case 'HZ'
      o_institution = 'CSIO';
   case 'IF'
      o_institution = 'CORIOLIS';
   case 'IN'
      o_institution = 'INCOIS';
   case 'KO'
      o_institution = 'KORDI';
   case 'NM'
      o_institution = 'NMDIS';
      
   otherwise
      fprintf('WARNING: Float #%d: No institution assigned to data centre %s\n', ...
         g_decArgo_floatNum, ...
         a_dataCentre);
end

return;

% ------------------------------------------------------------------------------
% Compute the profile quality flag of a given parameter.
%
% SYNTAX :
%  [o_profQc] = compute_profile_quality_flag(a_qcFlags)
%
% INPUT PARAMETERS :
%   a_qcFlags : QC flags of the parameter
%
% OUTPUT PARAMETERS :
%   o_profQc : computed profile quality flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profQc] = compute_profile_quality_flag(a_qcFlags)

% QC flag values
global g_decArgo_qcStrDef;           % ' '
global g_decArgo_qcStrNoQc;          % '0'
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrChanged;       % '5'
global g_decArgo_qcStrInterpolated;  % '8'
global g_decArgo_qcStrMissing;       % '9'

% output parameters initialization
o_profQc = g_decArgo_qcStrDef;

if (length(find((a_qcFlags == g_decArgo_qcStrDef) | ...
      (a_qcFlags == g_decArgo_qcStrNoQc) | ...
      (a_qcFlags == g_decArgo_qcStrMissing))) ~= length(a_qcFlags))
   
   % compute the ratio of good data
   nbUsefulLev = length(find((a_qcFlags ~= g_decArgo_qcStrDef) & ...
      (a_qcFlags ~= g_decArgo_qcStrMissing)));
   nbGoodLev = length(find((a_qcFlags == g_decArgo_qcStrGood) | ...
      (a_qcFlags == g_decArgo_qcStrProbablyGood) | ...
      (a_qcFlags == g_decArgo_qcStrChanged) | ...
      (a_qcFlags == g_decArgo_qcStrInterpolated)));
   ratio = 100*nbGoodLev/nbUsefulLev;
   if (ratio == 0)
      o_profQc = 'F';
   elseif (ratio < 25)
      o_profQc = 'E';
   elseif (ratio < 50)
      o_profQc = 'D';
   elseif (ratio < 75)
      o_profQc = 'C';
   elseif (ratio < 100)
      o_profQc = 'B';
   else
      o_profQc = 'A';
   end
end

return;
