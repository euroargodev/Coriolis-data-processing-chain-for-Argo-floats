% ------------------------------------------------------------------------------
% Convert a set of NetCDF mono_profile files from format version V2.2, V2.3 or
% V3.0 to format version V3.1 (Argo User's Manual V3.1).
%
% SYNTAX :
%   nc_convert_apx_mono_profile_argos_to_V3_1 or nc_convert_apx_mono_profile_argos_to_V3_1(6900189, 7900118)
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
%   10/02/2015 - RNU - creation (in V 2.7 to be compliant with nc_update_dm_mono_profile_to_V3_1)
%   10/21/2015 - RNU - V 2.8 (to be compliant with nc_update_dm_mono_profile_to_V3_1)
%   04/26/2019 - RNU - V 3.2 (version updated for Argos core Apex)
% ------------------------------------------------------------------------------
% Version 2.2 (AUM 2.2 08/21/2009
%  - FIRMWARE_VERSION is missing in Coriolis files
%
% Version 2.3 (AUM 2.3 07/13/2010)
% (similar to V 2.3 AUM 2.31 07/13/2010 for variables and dimensions)
%  - V 3.0 global attributes are in Coriolis files
%  - V 3.0 VERTICAL_SAMPLING_SCHEME is in Coriolis files
%  - V 3.0 SCIENTIFIC_CALIB_DATE as already replaced CALIBRATION_DATE in Coriolis files
%
% Version 3.0 (AUM 3.0 05/03/2013)
%  - Global attributes appear
%  - VERTICAL_SAMPLING_SCHEME appears
%  - CALIBRATION_DATE replaced by SCIENTIFIC_CALIB_DATE
%
% Version 3.0 (AUM 3.01 06/28/2013)
% (similar to V 3.0 AUM 3.02 06/28/2013 for variables and dimensions)
% (similar to V 3.0 AUM 3.03 08/28/2013 for variables and dimensions)
%  - INST_REFERENCE disappears
%  - PLATFORM_TYPE appears
%  - FLOAT_SERIAL_NO appears
%  - CONFIG_MISSION_NUMBER appears
%
% At Coriolis, in V 3.0 AUM 3.03 08/28/2013 FLOAT_SERIAL_NO string length has
% been enlarged (to store data base contents):
% FLOAT_SERIAL_NO(N_PROF, STRING32) instead of FLOAT_SERIAL_NO(N_PROF, STRING16)
% ------------------------------------------------------------------------------
function nc_convert_apx_mono_profile_argos_to_V3_1(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\IN\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1_20200103\IN\';

% top directory of output NetCDF mono-profile files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1_20200103\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_pts_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_11.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_4.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.2.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_24.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_19.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_25.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.02.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.01.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_6.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.4.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.1.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_28.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.3.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.03.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_13.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_23.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.04.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_46.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_11.1.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_1.5.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_11_a_refaire_20200103.txt';

% reference files
refNcFileName1 = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoProf_V3.1_cfile_part1.nc';
refNcFileName2 = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoProf_V3.1_cfile_part2.nc';

% list of corrected cycle numbers
corCyNumFile = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\misc_info/corCyNum.txt';

% list of nc 2 DEP link
ncToDepFile = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\misc_info/link_from_nc_to_dep.txt';

% json meta-data file directory
jsonFloatMetaDatafileDir = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\json_float_meta\';

% profile times and locations from DEP files
profTimeAndLoc = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\misc_info/get_information_from_dep_files_apex.txt';

% to print all the correction done on input data
VERBOSE = 1;

% program version
global g_cofc_ncConvertMonoProfileVersion;
g_cofc_ncConvertMonoProfileVersion = '3.2';

% adjusted error values of the float
global g_cofc_presAdjErrValue;
global g_cofc_tempAdjErrValue;
global g_cofc_cndcAdjErrValue;
global g_cofc_psalAdjErrValue;

% default values initialization
init_default_values;


% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = textread(floatListFileName, '%d');
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% check the reference files
if ~(exist(refNcFileName1, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', refNcFileName1);
   return
end
if ~(exist(refNcFileName2, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', refNcFileName2);
   return
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_convert_apx_mono_profile_argos_to_V3_1' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   Input files directory: %s\n', DIR_INPUT_NC_FILES);
fprintf('   Output files directory: %s\n', DIR_OUTPUT_NC_FILES);
fprintf('   Log file directory: %s\n', DIR_LOG_FILE);
if (nargin == 0)
   fprintf('   List of floats to process: %s\n', FLOAT_LIST_FILE_NAME);
else
   fprintf('   Floats to process:');
   fprintf(' %d', floatList);
   fprintf('\n');
end
fprintf('   Reference file for mono-profile NetCDF file (part #1): %s\n', refNcFileName1);
fprintf('   Reference file for mono-profile NetCDF file (part #2): %s\n', refNcFileName2);

% retrieve reference file schema
refFileSchema = ncinfo(refNcFileName1);
refFileSchema = [refFileSchema ncinfo(refNcFileName2)];

% read list of corrected cycle number
corCyNumData = load(corCyNumFile);

% read list of nc 2 DEP link
ncToDepLinkData = load(ncToDepFile);

% read list of profile times and locations from DEP files
profTimeAndLocData = load(profTimeAndLoc);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   g_cofc_presAdjErrValue = [];
   g_cofc_tempAdjErrValue = [];
   g_cofc_cndcAdjErrValue = [];
   g_cofc_psalAdjErrValue = [];
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % convert the mono-profile files of the current float
   % retrieve information from NetCDF V3.1 meta-data file
   metaDataFilePathName = [DIR_OUTPUT_NC_FILES sprintf('/%d/%d_meta.nc', floatNum, floatNum)];
   jsonInputFileName = [jsonFloatMetaDatafileDir '/' sprintf('%d_meta.json', floatNum)];
   metaData = get_meta_data(metaDataFilePathName, jsonInputFileName);
   if (isempty(metaData))
      fprintf('ERROR: float #%d: NetCDf V3.1 meta-data file not found => float ignored\n', floatNum);
      continue
   end
   
   % convert the mono-profile files of the current float
   monoProfDirName = [DIR_INPUT_NC_FILES sprintf('/%d/profiles/', floatNum)];
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', floatNum)];
   monoProfFiles = dir(monoProfFileName);
   
   % create the output directory
   if (~isempty(monoProfFiles))
      if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
         mkdir(DIR_OUTPUT_NC_FILES);
      end
   end
   
   % convert the mono-profile files
   for idFile = 1:length(monoProfFiles)
      
      fileName = monoProfFiles(idFile).name;
      profFileName = [monoProfDirName fileName];
      
      fprintf('\nFile: %s', fileName);
      
      profFileNameOutput = fileName;
      profFileDirNameOutput = [DIR_OUTPUT_NC_FILES ...
         sprintf('/%d/profiles/', floatNum)];
      % create the float output directory
      if ~(exist(profFileDirNameOutput, 'dir') == 7)
         mkdir(profFileDirNameOutput);
      end
      profFilePathNameOutput = [profFileDirNameOutput '/' profFileNameOutput];
      
      % ascending profile
      [ok, comment] = convert_mono_profile_to_V3_1(profFileName, ...
         profFilePathNameOutput, refFileSchema, ...
         metaData, corCyNumData, ncToDepLinkData, profTimeAndLocData, VERBOSE);
   end
   
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Convert a given NetCDF mono_profile files from format version V2.2, V2.3 or
% V3.0 to format version V3.1 (Argo User's Manual V3.1).
%
% SYNTAX :
%  [o_ok, o_comment] = convert_mono_profile_to_V3_1( ...
%    a_inputFileName, a_outputFileName, a_refFileSchema, ...
%    a_metaData, a_corCyNumData, a_ncToDepLinkData, a_profTimeAndLocData, a_verbose)
%
% INPUT PARAMETERS :
%   a_inputFileName      : mono-profile NetCDF input file name
%   a_outputFileName     : mono-profile NetCDF output file name
%   a_refFileSchema      : NetCDF schema of the V3.1 file
%   a_metaData           : meta-data from nc V3.1 file
%   a_corCyNumData       : corrected cycle number data
%   a_ncToDepLinkData    : information to link nc and DEP cycles
%   a_profTimeAndLocData : profile time and location (from DEP file)
%   a_verbose            : verbose mode flag
%
% OUTPUT PARAMETERS :
%   o_ok      : success flag (1 if Ok, 0 otherwise)
%   o_comment : detailed comment (when o_ok = 0)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_comment] = convert_mono_profile_to_V3_1( ...
   a_inputFileName, a_outputFileName, a_refFileSchema, ...
   a_metaData, a_corCyNumData, a_ncToDepLinkData, a_profTimeAndLocData, a_verbose)

% output parameters initialization
o_ok = 0;
o_comment = [];


% retrieve information from Input file
wantedInputVars = [ ...
   {'FORMAT_VERSION'} ...
   ];
[inputData] = get_data_from_nc_file(a_inputFileName, wantedInputVars);

idVal = find(strcmp('FORMAT_VERSION', inputData(1:2:end)) == 1, 1);
inputFileFormatVersionStr = strtrim(inputData{2*idVal}');

fprintf(' (format version %s)\n', inputFileFormatVersionStr);

% check the format version of the input file
if ((strcmp(inputFileFormatVersionStr, '3.0') == 0) && ...
      (strcmp(inputFileFormatVersionStr, '2.3') == 0) && ...
      (strcmp(inputFileFormatVersionStr, '2.2') == 0))
   o_comment = sprintf('Input file (%s) is expected to be of 2.2 or 2.3 or 3.0 format version (but FORMAT_VERSION = %s)', ...
      a_inputFileName, inputFileFormatVersionStr);
   return
end

[o_ok, o_comment] = convert_file(a_inputFileName, ...
   a_outputFileName, str2num(inputFileFormatVersionStr), a_refFileSchema, ...
   a_metaData, a_corCyNumData, a_ncToDepLinkData, a_profTimeAndLocData, a_verbose);

if (o_ok == 0)
   fprintf('%s', o_comment);
end

return

% ------------------------------------------------------------------------------
% Convert a given NetCDF mono_profile files from format version V2.2, V2.3 or
% V3.0 to format version V3.1 (Argo User's Manual V3.1).
%
% SYNTAX :
%  [o_ok, o_comment] = convert_file( ...
%    a_inputFileName, a_outputFileName, a_inputFileFormatVersion, ...
%    a_refFileSchema, a_metaData, a_corCyNumData, a_ncToDepLinkData, ...
%    a_profTimeAndLocData, a_verbose)
%
% INPUT PARAMETERS :
%   a_inputFileName          : mono-profile NetCDF input file name
%   a_outputFileName         : mono-profile NetCDF output file name
%   a_inputFileFormatVersion : Argo format version of input file
%   a_refFileSchema          : NetCDF schema of the V3.1 file
%   a_metaData               : meta-data from nc V3.1 file
%   a_corCyNumData           : corrected cycle number data
%   a_ncToDepLinkData        : information to link nc and DEP cycles
%   a_profTimeAndLocData     : profile time and location (from DEP file)
%   a_verbose                : verbose mode flag
%
% OUTPUT PARAMETERS :
%   o_ok      : success flag (1 if Ok, 0 otherwise)
%   o_comment : detailed comment (when o_ok = 0)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_comment] = convert_file( ...
   a_inputFileName, a_outputFileName, a_inputFileFormatVersion, ...
   a_refFileSchema, a_metaData, a_corCyNumData, a_ncToDepLinkData, ...
   a_profTimeAndLocData, a_verbose)

% output parameters initialization
o_ok = 0;
o_comment = [];

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cofc_ncConvertMonoProfileVersion;

% default values
global g_decArgo_janFirst1950InMatlab;

% QC flag values (char)
global g_decArgo_qcStrDef; % ' '
global g_decArgo_qcStrNoQc; % '0'
global g_decArgo_qcStrGood; % '1'
global g_decArgo_qcStrProbablyGood; % '2'
global g_decArgo_qcStrCorrectable; % '3'
global g_decArgo_qcStrBad; % '4'
global g_decArgo_qcStrMissing; % '9'

% adjusted error values of the float
global g_cofc_presAdjErrValue;
global g_cofc_tempAdjErrValue;
global g_cofc_cndcAdjErrValue;
global g_cofc_psalAdjErrValue;


% list of variables that will be retrieved from V3.1 meta.nc file to fill the
% V3.1 prof.nc ones
metaVarList = [ ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'DATA_CENTRE'} ...
   {'PLATFORM_TYPE'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'FIRMWARE_VERSION'} ...
   {'WMO_INST_TYPE'} ...
   {'POSITIONING_SYSTEM'} ...
   ];

% retrieve information from Input file
wantedInputVars = [ ...
   {'DATA_TYPE'} ...
   {'HANDBOOK_VERSION'} ...
   {'REFERENCE_DATE_TIME'} ...
   {'DATE_CREATION'} ...
   {'DATE_UPDATE'} ...
   {'PLATFORM_NUMBER'} ...
   {'STATION_PARAMETERS'} ...
   {'CYCLE_NUMBER'} ...
   {'DIRECTION'} ...
   {'DC_REFERENCE'} ...
   {'DATA_STATE_INDICATOR'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'PRES'} ...
   {'PARAMETER'} ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'HISTORY_INSTITUTION'} ...
   {'HISTORY_STEP'} ...
   {'HISTORY_SOFTWARE'} ...
   {'HISTORY_SOFTWARE_RELEASE'} ...
   {'HISTORY_REFERENCE'} ...
   {'HISTORY_DATE'} ...
   {'HISTORY_ACTION'} ...
   {'HISTORY_PARAMETER'} ...
   {'HISTORY_START_PRES'} ...
   {'HISTORY_STOP_PRES'} ...
   {'HISTORY_PREVIOUS_VALUE'} ...
   {'HISTORY_QCTEST'} ...
   ];
if (a_inputFileFormatVersion == 2.2)
   wantedInputVars = [ ...
      wantedInputVars ...
      {'CALIBRATION_DATE'} ...
      ];
elseif (a_inputFileFormatVersion == 2.3)
   wantedInputVars = [ ...
      wantedInputVars ...
      {'CALIBRATION_DATE'} ...
      {'SCIENTIFIC_CALIB_DATE'} ... % for Coriolis floats
      ];
elseif (a_inputFileFormatVersion == 3.0)
   wantedInputVars = [ ...
      wantedInputVars ...
      {'SCIENTIFIC_CALIB_DATE'} ...
      ];
end
[inputData] = get_data_from_nc_file(a_inputFileName, wantedInputVars);

% modify CYCLE_NUMBER if needed
idVal = find(strcmp('PLATFORM_NUMBER', inputData(1:2:end)) == 1, 1);
platformNumber = str2double(inputData{2*idVal}');
idValCyNum = find(strcmp('CYCLE_NUMBER', inputData(1:2:end)) == 1, 1);
cyNum = unique(inputData{2*idValCyNum});
cyNumOri = cyNum;
cyNumCor = [];
if (~isempty(a_corCyNumData))
   idF = find((a_corCyNumData(:, 1) == platformNumber) & (a_corCyNumData(:, 2) == cyNum));
   if (~isempty(idF))
      
      % modify CYCLE_NUMBER in the data
      cyNumCor = a_corCyNumData(idF, 3);
      cyNumCor = ones(size(inputData{2*idValCyNum}))*cyNumCor;
      inputData{2*idValCyNum} = cyNumCor;
      cyNumCor = unique(cyNumCor);
      
      % modify CYCLE_NUMBER in the file name
      [filePath, fileName, fileExt] = fileparts(a_outputFileName);
      fileName = regexprep(fileName, sprintf('_%03d', cyNum), sprintf('_%03d', cyNumCor));
      a_outputFileName = [filePath filesep fileName fileExt];
   end
end

% get the N_PROF, N_CALIB and N_PARAM dimensions
idVal = find(strcmp('PARAMETER', inputData(1:2:end)) == 1, 1);
inputParameter = inputData{2*idVal};
[~, inputNParam, inputNCalib, inputNProf] = size(inputParameter);

if (inputNProf > 1)
   fprintf('WARNING: N_PROF = %d in file %s\n', ...
      length(inputNProf), a_outputFileName);
end

% get the N_LEVELS dimensions
idVal = find(strcmp('PRES', inputData(1:2:end)) == 1, 1);
inputPres = inputData{2*idVal};
[inputNLevels, ~] = size(inputPres);

% create the list of parameters
idVal = find(strcmp('STATION_PARAMETERS', inputData(1:2:end)) == 1, 1);
stationParameters = inputData{2*idVal};
paramForProf = [];
for idProf = 1:inputNProf
   for idParam = 1:inputNParam
      paramForProf{idProf, idParam} = deblank(stationParameters(:, idParam, idProf)');
   end
end
paramlist = unique(paramForProf);

% retrieve measurements from Input file
wantedInputMeasVars = [];
for idParam = 1:length(paramlist)
   paramName = paramlist{idParam};
   if (isempty(paramName))
      o_comment = sprintf('ERROR: empty parameter name in STATION_PARAMETERS of file: %s\n', a_inputFileName);
      return
   end
   profParamQcName = ['PROFILE_' paramName '_QC'];
   paramNameQc = [paramName '_QC'];
   paramNameAdj = [paramName '_ADJUSTED'];
   paramNameAdjQc = [paramName '_ADJUSTED_QC'];
   paramNameAdjErr = [paramName '_ADJUSTED_ERROR'];
   wantedInputMeasVars = [ ...
      wantedInputMeasVars ...
      {profParamQcName} ...
      {paramName} ...
      {paramNameQc} ...
      {paramNameAdj} ...
      {paramNameAdjQc} ...
      {paramNameAdjErr} ...
      ];
end
[inputMeasData] = get_data_from_nc_file(a_inputFileName, wantedInputMeasVars);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORRECTION BEGIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% corrections done on input data

idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
nProf = length(dataMode);

idVal = find(strcmp('PLATFORM_NUMBER', inputData(1:2:end)) == 1, 1);
wmoNum = inputData{2*idVal};
wmoNum = str2num(wmoNum(:, 1)');
idVal = find(strcmp('CYCLE_NUMBER', inputData(1:2:end)) == 1, 1);
cyNum = unique(inputData{2*idVal});
idVal = find(strcmp('DIRECTION', inputData(1:2:end)) == 1, 1);
dir = unique(inputData{2*idVal});

% store default adjusted error values
presParam = get_netcdf_param_attributes_3_1('PRES');
idVal = find(strcmp('PRES_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   presAdjErrValue = inputMeasData{2*idVal};
   if (any(presAdjErrValue ~= presParam.fillValue))
      idUse = find(presAdjErrValue ~= presParam.fillValue);
      g_cofc_presAdjErrValue = unique([g_cofc_presAdjErrValue unique(presAdjErrValue(idUse))']);
   end
end
tempParam = get_netcdf_param_attributes_3_1('TEMP');
idVal = find(strcmp('TEMP_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   tempAdjErrValue = inputMeasData{2*idVal};
   if (any(tempAdjErrValue ~= tempParam.fillValue))
      idUse = find(tempAdjErrValue ~= tempParam.fillValue);
      g_cofc_tempAdjErrValue = unique([g_cofc_tempAdjErrValue unique(tempAdjErrValue(idUse))']);
   end
end
cndcParam = get_netcdf_param_attributes_3_1('CNDC');
idVal = find(strcmp('CNDC_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   cndcAdjErrValue = inputMeasData{2*idVal};
   if (any(cndcAdjErrValue ~= cndcParam.fillValue))
      idUse = find(cndcAdjErrValue ~= cndcParam.fillValue);
      g_cofc_cndcAdjErrValue = unique([g_cofc_cndcAdjErrValue unique(cndcAdjErrValue(idUse))']);
   end
end
psalParam = get_netcdf_param_attributes_3_1('PSAL');
idVal = find(strcmp('PSAL_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   psalAdjErrValue = inputMeasData{2*idVal};
   if (any(psalAdjErrValue ~= psalParam.fillValue))
      idUse = find(psalAdjErrValue ~= psalParam.fillValue);
      g_cofc_psalAdjErrValue = unique([g_cofc_psalAdjErrValue unique(psalAdjErrValue(idUse))']);
   end
end

% if (0) %TEMPORARY

% be sure that DIRECTION is set
idVal = find(strcmp('DIRECTION', inputData(1:2:end)) == 1, 1);
direction = inputData{2*idVal};
updatedFlag = 0;
for idProf = 1:nProf
   if (isempty(strtrim(direction(idProf))))
      direction(idProf) = 'A';
      inputData{2*idVal} = direction;
      
      if (a_verbose)
         fprintf('INFO: Float #%d Cycle #%d %c: DIRECTION set to ''A'' (because not set)\n', ...
            wmoNum, cyNum, dir);
      end
   end
end

% be sure that PARAMETER is set
idVal1 = find(strcmp('PARAMETER', inputData(1:2:end)) == 1, 1);
parameter = inputData{2*idVal1};
[~, nParamDim, nCalibDim, nProdDim] = size(parameter);
updatedFlag = 0;
for idProf = 1:nProdDim
   for idCalib = 1:nCalibDim
      for idParam = 1:nParamDim
         paramSci = parameter(:, idParam, idCalib, idProf);
         if (isempty(strtrim(paramSci)))
            % retrieve the parameter from STATION_PARAMETERS
            idVal2 = find(strcmp('STATION_PARAMETERS', inputData(1:2:end)) == 1, 1);
            stationParameters = inputData{2*idVal2};
            paramSta = stationParameters(:, idParam, idProf);
            parameter(:, idParam, idCalib, idProf) = paramSta;
            updatedFlag = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: ''%s'' added in ''PARAMETERS'' (for N_PROF=%d; N_CALIB=%d, N_PARAM=%d)\n', ...
                  wmoNum, cyNum, dir, ...
                  paramSta', idProf, idCalib, idParam);
            end
         end
      end
   end
end
if (updatedFlag)
   inputData{2*idVal1} = parameter;
end

% replace NaN values by FillValue and set QC to '9' and _ADJUSTED_ERROR to
% FillValue
for idParam = 1:length(paramlist)
   paramNameOri = paramlist{idParam};
   for id = 1:2
      paramName = paramNameOri;
      if (id == 2)
         paramName = [paramNameOri '_ADJUSTED'];
      end
      idVal = find(strcmp(paramName, inputMeasData(1:2:end)) == 1, 1);
      paramData = inputMeasData{2*idVal};
      if (any(isnan(paramData)))
         paramInfo = get_netcdf_param_attributes_3_1(paramNameOri);
         idNan = find(isnan(paramData));
         paramData(idNan) = paramInfo.fillValue;
         inputMeasData{2*idVal} = paramData;
         
         if (a_verbose)
            fprintf('INFO: Float #%d Cycle #%d %c: %d NaN values of %s parameter replaced by FillValue (and associated QC values set to ''%c'')\n', ...
               wmoNum, cyNum, dir, ...
               length(idNan), paramNameOri, g_decArgo_qcStrMissing);
         end
         
         paramNameQc = [paramName '_QC'];
         idVal = find(strcmp(paramNameQc, inputMeasData(1:2:end)) == 1, 1);
         paramDataQc = inputMeasData{2*idVal};
         paramDataQc(idNan) = g_decArgo_qcStrMissing;
         inputMeasData{2*idVal} = paramDataQc;
         
         if (id == 2)
            paramNameAdjErr = [paramNameOri '_ADJUSTED_ERROR'];
            idVal = find(strcmp(paramNameAdjErr, inputMeasData(1:2:end)) == 1, 1);
            paramDataAdjErr = inputMeasData{2*idVal};
            paramDataAdjErr(idNan) = paramInfo.fillValue;
            inputMeasData{2*idVal} = paramDataAdjErr;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to FillValue\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idNan), paramNameAdjErr);
            end
         end
      end
   end
end

% if DATA_MODE = 'D': if PRES_QC = '0' set PRES_QC = '1'
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('PRES_QC', inputMeasData(1:2:end)) == 1, 1);
presQc = inputMeasData{2*idVal};
idValPresQc = idVal;

corDone = 0;
for idP = 1:length(dataMode)
   if (dataMode(idP) == 'D')
      if (any(presQc(:, idP) == g_decArgo_qcStrNoQc))
         idFQc0 = find(presQc(:, idP) == g_decArgo_qcStrNoQc);
         presQc(idFQc0, idP) = g_decArgo_qcStrGood;
         corDone = 1;
         
         if (a_verbose)
            fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' values (because in D mode with %s = ''%c'')\n', ...
               wmoNum, cyNum, dir, ...
               length(idFQc0), 'PRES_QC', g_decArgo_qcStrGood, 'PRES_QC', g_decArgo_qcStrNoQc);
         end
      end
   end
end
if (corDone)
   inputMeasData{2*idValPresQc} = presQc;
end

% if CNDC_QC = '0' set CNDC_QC = PSAL_QC
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('CNDC_QC', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   cndcQc = inputMeasData{2*idVal};
   idValCndcQc = idVal;
   idVal = find(strcmp('PSAL_QC', inputMeasData(1:2:end)) == 1, 1);
   psalQc = inputMeasData{2*idVal};
   
   corDone = 0;
   for idP = 1:length(dataMode)
      if (any(cndcQc(:, idP) == g_decArgo_qcStrNoQc))
         idFQc0 = find(cndcQc(:, idP) == g_decArgo_qcStrNoQc);
         cndcQc(idFQc0, idP) = psalQc(idFQc0, idP);
         corDone = 1;
         
         if (a_verbose)
            fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to %s values (because %s = ''%c'')\n', ...
               wmoNum, cyNum, dir, ...
               length(idFQc0), 'CNDC_QC', 'PSAL_QC', 'CNDC_QC', g_decArgo_qcStrNoQc);
         end
      end
   end
   if (corDone)
      inputMeasData{2*idValCndcQc} = cndcQc;
   end
end

% if DATA_MODE = 'D': if TEMP_QC = '0' and TEMP parameter has been adjusted then
% duplicate TEMP_ADJUSTED_QC in TEMP_QC
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('TEMP_QC', inputMeasData(1:2:end)) == 1, 1);
tempQc = inputMeasData{2*idVal};
idValTempQc = idVal;
idVal = find(strcmp('TEMP_ADJUSTED_QC', inputMeasData(1:2:end)) == 1, 1);
tempAdjQc = inputMeasData{2*idVal};

corDone = 0;
for idP = 1:length(dataMode)
   if (dataMode(idP) == 'D')
      if (any((tempQc(:, idP) == g_decArgo_qcStrNoQc) & (tempAdjQc(:, idP) ~= g_decArgo_qcStrDef)))
         idFQc0 = find((tempQc(:, idP) == g_decArgo_qcStrNoQc) & (tempAdjQc(:, idP) ~= g_decArgo_qcStrDef));
         tempQc(idFQc0, idP) = tempAdjQc(idFQc0, idP);
         corDone = 1;
         
         if (a_verbose)
            fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to %s values (because in D mode with %s = ''%c'')\n', ...
               wmoNum, cyNum, dir, ...
               length(idFQc0), 'TEMP_QC', 'TEMP_ADJUSTED_QC', 'TEMP_QC', g_decArgo_qcStrNoQc);
         end
      end
   end
end
if (corDone)
   inputMeasData{2*idValTempQc} = tempQc;
end

% if DATA_MODE = 'D': if PSAL_QC = '0' and PSAL parameter has been adjusted then
% duplicate PSAL_ADJUSTED_QC in PSAL_QC
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('PSAL_QC', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   psalQc = inputMeasData{2*idVal};
   idValPsalQc = idVal;
   idVal = find(strcmp('PSAL_ADJUSTED_QC', inputMeasData(1:2:end)) == 1, 1);
   psalAdjQc = inputMeasData{2*idVal};
   
   corDone = 0;
   for idP = 1:length(dataMode)
      if (dataMode(idP) == 'D')
         if (any((psalQc(:, idP) == g_decArgo_qcStrNoQc) & (psalAdjQc(:, idP) ~= g_decArgo_qcStrDef)))
            idFQc0 = find((psalQc(:, idP) == g_decArgo_qcStrNoQc) & (psalAdjQc(:, idP) ~= g_decArgo_qcStrDef));
            psalQc(idFQc0, idP) = psalAdjQc(idFQc0, idP);
            corDone = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to %s values (because in D mode with %s = ''%c'')\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idFQc0), 'PSAL_QC', 'PSAL_ADJUSTED_QC', 'PSAL_QC', g_decArgo_qcStrNoQc);
            end
         end
      end
   end
   if (corDone)
      inputMeasData{2*idValPsalQc} = psalQc;
   end
end

% if DATA_MODE = 'D': if CNDC_ADJUSTED_QC = '0' set CNDC_ADJUSTED_QC = PSAL_ADJUSTED_QC
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('CNDC_ADJUSTED_QC', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   cndcAdjQc = inputMeasData{2*idVal};
   idValCndcAdjQc = idVal;
   idVal = find(strcmp('PSAL_ADJUSTED_QC', inputMeasData(1:2:end)) == 1, 1);
   psalAdjQc = inputMeasData{2*idVal};
   
   corDone = 0;
   for idP = 1:length(dataMode)
      if (dataMode(idP) == 'D')
         if (any(cndcAdjQc(:, idP) == g_decArgo_qcStrNoQc))
            idFQc0 = find(cndcAdjQc(:, idP) == g_decArgo_qcStrNoQc);
            cndcAdjQc(idFQc0, idP) = psalAdjQc(idFQc0, idP);
            corDone = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to %s values (because in D mode with %s = ''%c'')\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idFQc0), 'CNDC_ADJUSTED_QC', 'PSAL_ADJUSTED_QC', 'CNDC_ADJUSTED_QC', g_decArgo_qcStrNoQc);
            end
         end
      end
   end
   if (corDone)
      inputMeasData{2*idValCndcAdjQc} = cndcAdjQc;
   end
end

% if DATA_MODE = 'D': if PARAM_ADJUSTED_QC = ‘4’, both PARAM_ADJUSTED and
% PARAM_ADJUSTED_ERROR should be set to FillValue.
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
for idP = 1:length(dataMode)
   if (dataMode(idP) == 'D')
      
      for idParam = 1:length(paramlist)
         
         paramName = paramlist{idParam};
         
         paramNameAdjQc = [paramName '_ADJUSTED_QC'];
         idVal = find(strcmp(paramNameAdjQc, inputMeasData(1:2:end)) == 1, 1);
         paramAdjQc = inputMeasData{2*idVal};
         
         if (any(paramAdjQc(:, idP) == g_decArgo_qcStrBad))
            paramStruct = get_netcdf_param_attributes_3_1(paramName);
            idFQc4 = find(paramAdjQc(:, idP) == g_decArgo_qcStrBad);
            
            paramNameAdj = [paramName '_ADJUSTED'];
            idVal = find(strcmp(paramNameAdj, inputMeasData(1:2:end)) == 1, 1);
            paramAdjValue = inputMeasData{2*idVal};
            if (any(paramAdjValue(idFQc4, idP) ~= paramStruct.fillValue))
               paramAdjValue(idFQc4, idP) = paramStruct.fillValue;
               inputMeasData{2*idVal} = paramAdjValue;
               
               if (a_verbose)
                  fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to FillValue (because in D mode with %s = ''%c'')\n', ...
                     wmoNum, cyNum, dir, ...
                     length(idFQc4), paramNameAdj, paramNameAdjQc, g_decArgo_qcStrBad);
               end
            end
            
            paramNameAdjErr = [paramName '_ADJUSTED_ERROR'];
            idVal = find(strcmp(paramNameAdjErr, inputMeasData(1:2:end)) == 1, 1);
            paramAdjErrorValue = inputMeasData{2*idVal};
            if (any(paramAdjErrorValue(idFQc4, idP) ~= paramStruct.fillValue))
               paramAdjErrorValue(idFQc4, idP) = paramStruct.fillValue;
               inputMeasData{2*idVal} = paramAdjErrorValue;
               
               if (a_verbose)
                  fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to FillValue (because in D mode with %s = ''%c'')\n', ...
                     wmoNum, cyNum, dir, ...
                     length(idFQc4), paramNameAdjErr, paramNameAdjQc, g_decArgo_qcStrBad);
               end
            end
         end
      end
   end
end

% if DATA_MODE = 'D': if PRES_ADJUSTED ~= FillValue, PRES_ADJUSTED_ERROR
% should be different from FillValue.
if (length(g_cofc_presAdjErrValue) == 1)
   idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
   dataMode = inputData{2*idVal};
   idVal = find(strcmp('PRES_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
   if (~isempty(idVal))
      presAdjValue = inputMeasData{2*idVal};
      idVal = find(strcmp('PRES_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
      presAdjErrorValue = inputMeasData{2*idVal};
      idPresAdjErrorVal = idVal;
      paramStruct = get_netcdf_param_attributes_3_1('PRES');
      
      corDone = 0;
      for idP = 1:length(dataMode)
         if (dataMode(idP) == 'D')
            if (any((presAdjErrorValue(:, idP) == paramStruct.fillValue) & ...
                  (presAdjValue(:, idP) ~= paramStruct.fillValue)))
               idFAdjValFillval = find(presAdjValue(:, idP) ~= paramStruct.fillValue);
               presAdjErrorValue(idFAdjValFillval, idP) = g_cofc_presAdjErrValue;
               corDone = 1;
               
               if (a_verbose)
                  fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to %g (when %s differ from FillValue)\n', ...
                     wmoNum, cyNum, dir, ...
                     length(idFAdjValFillval), 'PRES_ADJUSTED_ERROR', g_cofc_presAdjErrValue, 'PRES_ADJUSTED');
               end
            end
         end
      end
      if (corDone)
         inputMeasData{2*idPresAdjErrorVal} = presAdjErrorValue;
      end
   end
end
% if DATA_MODE = 'D': if TEMP_ADJUSTED ~= FillValue, TEMP_ADJUSTED_ERROR
% should be different from FillValue.
if (length(g_cofc_tempAdjErrValue) == 1)
   idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
   dataMode = inputData{2*idVal};
   idVal = find(strcmp('TEMP_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
   if (~isempty(idVal))
      tempAdjValue = inputMeasData{2*idVal};
      idVal = find(strcmp('TEMP_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
      tempAdjErrorValue = inputMeasData{2*idVal};
      idTempAdjErrorVal = idVal;
      paramStruct = get_netcdf_param_attributes_3_1('TEMP');
      
      corDone = 0;
      for idP = 1:length(dataMode)
         if (dataMode(idP) == 'D')
            if (any((tempAdjErrorValue(:, idP) == paramStruct.fillValue) & ...
                  (tempAdjValue(:, idP) ~= paramStruct.fillValue)))
               idFAdjValFillval = find(tempAdjValue(:, idP) ~= paramStruct.fillValue);
               tempAdjErrorValue(idFAdjValFillval, idP) = g_cofc_tempAdjErrValue;
               corDone = 1;
               
               if (a_verbose)
                  fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to %g (when %s differ from FillValue)\n', ...
                     wmoNum, cyNum, dir, ...
                     length(idFAdjValFillval), 'TEMP_ADJUSTED_ERROR', g_cofc_tempAdjErrValue, 'TEMP_ADJUSTED');
               end
            end
         end
      end
      if (corDone)
         inputMeasData{2*idTempAdjErrorVal} = tempAdjErrorValue;
      end
   end
end
% if DATA_MODE = 'D': if CNDC_ADJUSTED ~= FillValue, CNDC_ADJUSTED_ERROR
% should be different from FillValue.
if (length(g_cofc_cndcAdjErrValue) == 1)
   idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
   dataMode = inputData{2*idVal};
   idVal = find(strcmp('CNDC_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
   if (~isempty(idVal))
      cndcAdjValue = inputMeasData{2*idVal};
      idVal = find(strcmp('CNDC_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
      cndcAdjErrorValue = inputMeasData{2*idVal};
      idCndcAdjErrorVal = idVal;
      paramStruct = get_netcdf_param_attributes_3_1('CNDC');
      
      corDone = 0;
      for idP = 1:length(dataMode)
         if (dataMode(idP) == 'D')
            if (any((cndcAdjErrorValue(:, idP) == paramStruct.fillValue) & ...
                  (cndcAdjValue(:, idP) ~= paramStruct.fillValue)))
               idFAdjValFillval = find(cndcAdjValue(:, idP) ~= paramStruct.fillValue);
               cndcAdjErrorValue(idFAdjValFillval, idP) = g_cofc_cndcAdjErrValue;
               corDone = 1;
               
               if (a_verbose)
                  fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to %g (when %s differ from FillValue)\n', ...
                     wmoNum, cyNum, dir, ...
                     length(idFAdjValFillval), 'CNDC_ADJUSTED_ERROR', g_cofc_cndcAdjErrValue, 'CNDC_ADJUSTED');
               end
            end
         end
      end
      if (corDone)
         inputMeasData{2*idCndcAdjErrorVal} = cndcAdjErrorValue;
      end
   end
end
% if DATA_MODE = 'D': if PSAL_ADJUSTED ~= FillValue, PSAL_ADJUSTED_ERROR
% should be different from FillValue.
if (length(g_cofc_psalAdjErrValue) == 1)
   idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
   dataMode = inputData{2*idVal};
   idVal = find(strcmp('PSAL_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
   if (~isempty(idVal))
      psalAdjValue = inputMeasData{2*idVal};
      idVal = find(strcmp('PSAL_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
      psalAdjErrorValue = inputMeasData{2*idVal};
      idPsalAdjErrorVal = idVal;
      paramStruct = get_netcdf_param_attributes_3_1('PSAL');
      
      corDone = 0;
      for idP = 1:length(dataMode)
         if (dataMode(idP) == 'D')
            if (any((psalAdjErrorValue(:, idP) == paramStruct.fillValue) & ...
                  (psalAdjValue(:, idP) ~= paramStruct.fillValue)))
               idFAdjValFillval = find(psalAdjValue(:, idP) ~= paramStruct.fillValue);
               psalAdjErrorValue(idFAdjValFillval, idP) = g_cofc_psalAdjErrValue;
               corDone = 1;
               
               if (a_verbose)
                  fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to %g (when %s differ from FillValue)\n', ...
                     wmoNum, cyNum, dir, ...
                     length(idFAdjValFillval), 'PSAL_ADJUSTED_ERROR', g_cofc_psalAdjErrValue, 'PSAL_ADJUSTED');
               end
            end
         end
      end
      if (corDone)
         inputMeasData{2*idPsalAdjErrorVal} = psalAdjErrorValue;
      end
   end
end

% if DATA_MODE = 'D': if CNDC_ADJUSTED ~= FillValue, CNDC_ADJUSTED_ERROR
% should be different from FillValue.
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('CNDC_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   cndcAdjValue = inputMeasData{2*idVal};
   idVal = find(strcmp('CNDC_ADJUSTED_ERROR', inputMeasData(1:2:end)) == 1, 1);
   cndcAdjErrorValue = inputMeasData{2*idVal};
   idCndcAdjErrorVal = idVal;
   paramStruct = get_netcdf_param_attributes_3_1('CNDC');
   cndcAdjErrorDefaultValue = 0.01;
   
   corDone = 0;
   for idP = 1:length(dataMode)
      if (dataMode(idP) == 'D')
         if (any((cndcAdjErrorValue(:, idP) == paramStruct.fillValue) & ...
               (cndcAdjValue(:, idP) ~= paramStruct.fillValue)))
            idFAdjValFillval = find(cndcAdjValue(:, idP) ~= paramStruct.fillValue);
            cndcAdjErrorValue(idFAdjValFillval, idP) = cndcAdjErrorDefaultValue;
            corDone = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to %g (when %s differ from FillValue)\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idFAdjValFillval), 'CNDC_ADJUSTED_ERROR', cndcAdjErrorDefaultValue, 'CNDC_ADJUSTED');
            end
         end
      end
   end
   if (corDone)
      inputMeasData{2*idCndcAdjErrorVal} = cndcAdjErrorValue;
   end
end

% if DATA_MODE = 'D': if CNDC_ADJUSTED_QC == FillValue and CNDC_QC ~= FillValue
% and CNDC_ADJUSTED == FillValue set CNDC_ADJUSTED_QC to '4'
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('CNDC_ADJUSTED_QC', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   cndcAdjQc = inputMeasData{2*idVal};
   idValCndcAdjQc = idVal;
   idVal = find(strcmp('CNDC_QC', inputMeasData(1:2:end)) == 1, 1);
   cndcQc = inputMeasData{2*idVal};
   idVal = find(strcmp('CNDC_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
   cndcAdjValue = inputMeasData{2*idVal};
   paramStruct = get_netcdf_param_attributes_3_1('CNDC');
   
   corDone = 0;
   for idP = 1:length(dataMode)
      if (dataMode(idP) == 'D')
         if (any((cndcAdjQc(:, idP) == g_decArgo_qcStrDef) & (cndcQc(:, idP) ~= g_decArgo_qcStrDef) & (cndcAdjValue(:, idP) == paramStruct.fillValue)))
            idFQcFv = find((cndcAdjQc(:, idP) == g_decArgo_qcStrDef) & (cndcQc(:, idP) ~= g_decArgo_qcStrDef) & (cndcAdjValue(:, idP) == paramStruct.fillValue));
            cndcAdjQc(idFQcFv, idP) = g_decArgo_qcStrBad;
            corDone = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' (because in D mode with %s = '' '')\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idFQcFv), 'CNDC_ADJUSTED_QC', g_decArgo_qcStrBad, 'CNDC_QC');
            end
         end
      end
   end
   if (corDone)
      inputMeasData{2*idValCndcAdjQc} = cndcAdjQc;
   end
end

% if DATA_MODE = 'D': if CNDC ~= FillValue and CNDC_ADJUSTED == FillValue
% CNDC_ADJUSTED_QC should be '4'
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};
idVal = find(strcmp('CNDC', inputMeasData(1:2:end)) == 1, 1);
if (~isempty(idVal))
   cndcValue = inputMeasData{2*idVal};
   idVal = find(strcmp('CNDC_ADJUSTED', inputMeasData(1:2:end)) == 1, 1);
   cndcAdjValue = inputMeasData{2*idVal};
   idVal = find(strcmp('CNDC_ADJUSTED_QC', inputMeasData(1:2:end)) == 1, 1);
   cndcAdjQc = inputMeasData{2*idVal};
   idValCndcAdjQc = idVal;
   paramStruct = get_netcdf_param_attributes_3_1('CNDC');
   
   corDone = 0;
   for idP = 1:length(dataMode)
      if (dataMode(idP) == 'D')
         if (any((cndcValue(:, idP) ~= paramStruct.fillValue) & (cndcAdjValue(:, idP) == paramStruct.fillValue) & (cndcAdjQc(:, idP) ~= g_decArgo_qcStrBad)))
            idFQc4 = find((cndcValue(:, idP) ~= paramStruct.fillValue) & (cndcAdjValue(:, idP) == paramStruct.fillValue) & (cndcAdjQc(:, idP) ~= g_decArgo_qcStrBad));
            cndcAdjQc(idFQc4, idP) = g_decArgo_qcStrBad;
            corDone = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' (because in D mode with %s ~= FillValue and %s == FillValue)\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idFQc4), 'CNDC_ADJUSTED_QC', g_decArgo_qcStrBad, 'CNDC', 'CNDC_ADJUSTED');
            end
         end
      end
   end
   if (corDone)
      inputMeasData{2*idValCndcAdjQc} = cndcAdjQc;
   end
end

% when PARAMETER measurements are missing, PARAMETER_QC and PARAMETER_QC should
% be '9'
idVal = find(strcmp('DATA_MODE', inputData(1:2:end)) == 1, 1);
dataMode = inputData{2*idVal};

% compute profile length
tabNbLev = [];
for idP = 1:length(dataMode)
   nbLev = 0;
   for idParam = 1:length(paramlist)
      paramName = paramlist{idParam};
      paramStruct = get_netcdf_param_attributes_3_1(paramName);
      idVal = find(strcmp(paramName, inputMeasData(1:2:end)) == 1, 1);
      paramValue = inputMeasData{2*idVal};
      if (any(paramValue(:, idP) ~= paramStruct.fillValue))
         nbLev = max(nbLev, max(find(paramValue(:, idP) ~= paramStruct.fillValue)));
      end
   end
   tabNbLev(end+1) = nbLev;
end

for idParam = 1:length(paramlist)
   paramName = paramlist{idParam};
   paramQcName = [paramName '_QC'];
   paramAdjQcName = [paramName '_ADJUSTED_QC'];
   paramStruct = get_netcdf_param_attributes_3_1(paramName);
   
   idVal = find(strcmp(paramName, inputMeasData(1:2:end)) == 1, 1);
   paramValue = inputMeasData{2*idVal};
   idVal = find(strcmp(paramQcName, inputMeasData(1:2:end)) == 1, 1);
   paramQcValue = inputMeasData{2*idVal};
   idValParamQc = idVal;
   idVal = find(strcmp(paramAdjQcName, inputMeasData(1:2:end)) == 1, 1);
   paramAdjQcValue = inputMeasData{2*idVal};
   idValParamAdjQc = idVal;
   
   corDone1 = 0;
   corDone2 = 0;
   for idP = 1:length(dataMode)
      nbLev = tabNbLev(idP);
      if (any(paramValue(1:nbLev, idP) == paramStruct.fillValue))
         
         
         idMiss1 = find((paramValue(1:nbLev, idP) == paramStruct.fillValue) & ...
            (paramQcValue(1:nbLev, idP) ~= g_decArgo_qcStrMissing));
         if (~isempty(idMiss1))
            paramQcValue(idMiss1, idP) = g_decArgo_qcStrMissing;
            corDone1 = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' (because %s is missing)\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idMiss1), paramQcName, g_decArgo_qcStrMissing, paramName);
            end
         end
         idMiss2 = find((paramValue(1:nbLev, idP) == paramStruct.fillValue) & ...
            (paramAdjQcValue(1:nbLev, idP) ~= g_decArgo_qcStrMissing) & (paramAdjQcValue(1:nbLev, idP) ~= g_decArgo_qcStrDef));
         if (~isempty(idMiss2))
            paramAdjQcValue(idMiss2, idP) = g_decArgo_qcStrMissing;
            corDone2 = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' (because %s is missing)\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idMiss2), paramAdjQcName, g_decArgo_qcStrMissing, paramName);
            end
         end
      end
   end
   if (corDone1)
      inputMeasData{2*idValParamQc} = paramQcValue;
   end
   if (corDone2)
      inputMeasData{2*idValParamAdjQc} = paramAdjQcValue;
   end
end

% if PRES_ADJUSTED_QC = '9' and PRES_ADJUSTED = 99994 set PRES_ADJUSTED = FillValue
paramNameOri = 'PRES';
paramInfo = get_netcdf_param_attributes_3_1(paramNameOri);
paramNameAdjQc = [paramNameOri '_ADJUSTED_QC'];
idVal = find(strcmp(paramNameAdjQc, inputMeasData(1:2:end)) == 1, 1);
paramDataAdjQc = inputMeasData{2*idVal};
paramNameAdj = [paramNameOri '_ADJUSTED'];
idVal = find(strcmp(paramNameAdj, inputMeasData(1:2:end)) == 1, 1);
paramDataAdj = inputMeasData{2*idVal};
for idProf = 1:nProf
   if (any((paramDataAdjQc(:, idProf) == g_decArgo_qcStrMissing) & ...
         (paramDataAdj(:, idProf) == 99994)))
      idCor = find((paramDataAdjQc(:, idProf) == g_decArgo_qcStrMissing) & ...
         (paramDataAdj(:, idProf) == 99994));
      paramDataAdj(idCor, idProf) = paramInfo.fillValue;
      inputMeasData{2*idVal} = paramDataAdj;
      
      if (a_verbose)
         fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to FillValue (because %s = ''%c'' and %s = 99994)\n', ...
            wmoNum, cyNum, dir, ...
            length(idCor), paramNameAdj, paramNameAdjQc, g_decArgo_qcStrMissing, paramNameAdj);
      end
   end
end

% if DATA_MODE = 'D' and PARAM ~= FillValue and PARAM_ADJUSTED = FillValue set PARAM_ADJUSTED_QC = '4'
for idParam = 1:length(paramlist)
   paramNameOri = paramlist{idParam};
   paramInfo = get_netcdf_param_attributes_3_1(paramNameOri);
   idVal = find(strcmp(paramNameOri, inputMeasData(1:2:end)) == 1, 1);
   paramData = inputMeasData{2*idVal};
   paramNameAdj = [paramNameOri '_ADJUSTED'];
   idVal = find(strcmp(paramNameAdj, inputMeasData(1:2:end)) == 1, 1);
   paramDataAdj = inputMeasData{2*idVal};
   paramNameAdjQc = [paramNameOri '_ADJUSTED_QC'];
   idVal = find(strcmp(paramNameAdjQc, inputMeasData(1:2:end)) == 1, 1);
   paramDataAdjQc = inputMeasData{2*idVal};
   for idProf = 1:nProf
      if (dataMode(idProf) == 'D')
         if (any((paramData(:, idProf) ~= paramInfo.fillValue) & ...
               (paramDataAdj(:, idProf) == paramInfo.fillValue) & ...
               (paramDataAdjQc(:, idProf) ~= g_decArgo_qcStrBad)))
            idCor = find((paramData(:, idProf) ~= paramInfo.fillValue) & ...
               (paramDataAdj(:, idProf) == paramInfo.fillValue) & ...
               (paramDataAdjQc(:, idProf) ~= g_decArgo_qcStrBad));
            paramDataAdjQc(idCor, idProf) = g_decArgo_qcStrBad;
            inputMeasData{2*idVal} = paramDataAdjQc;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' (because in D mode %s ~= FillValue and %s = FillValue)\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idCor), paramNameAdjQc, g_decArgo_qcStrBad, paramNameOri, paramDataAdj);
            end
         end
      end
   end
end

% if DATA_MODE = 'D' and PARAM_ADJUSTED = FillValue set PARAM_ADJUSTED_ERROR = FillValue
for idParam = 1:length(paramlist)
   paramNameOri = paramlist{idParam};
   paramInfo = get_netcdf_param_attributes_3_1(paramNameOri);
   idVal = find(strcmp(paramNameOri, inputMeasData(1:2:end)) == 1, 1);
   paramData = inputMeasData{2*idVal};
   paramNameAdj = [paramNameOri '_ADJUSTED'];
   idVal = find(strcmp(paramNameAdj, inputMeasData(1:2:end)) == 1, 1);
   paramDataAdj = inputMeasData{2*idVal};
   paramNameAdjErr = [paramNameOri '_ADJUSTED_ERROR'];
   idVal = find(strcmp(paramNameAdjErr, inputMeasData(1:2:end)) == 1, 1);
   paramDataAdjErr = inputMeasData{2*idVal};
   for idProf = 1:nProf
      if (dataMode(idProf) == 'D')
         if (any((paramDataAdj(:, idProf) == paramInfo.fillValue) & ...
               (paramDataAdjErr(:, idProf) ~= paramInfo.fillValue)))
            idCor = find((paramDataAdj(:, idProf) == paramInfo.fillValue) & ...
               (paramDataAdjErr(:, idProf) ~= paramInfo.fillValue));
            paramDataAdjErr(idCor, idProf) = paramInfo.fillValue;
            inputMeasData{2*idVal} = paramDataAdjErr;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to FillValue (because in D mode %s = FillValue)\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idCor), paramNameAdjErr, paramNameAdj);
            end
         end
      end
   end
end

% if DATA_MODE = 'D' or 'A' and PARAM_QC = '9' set PARAM_ADJUSTED_QC = '9'
for idParam = 1:length(paramlist)
   paramNameOri = paramlist{idParam};
   paramNameQc = [paramNameOri '_QC'];
   idVal = find(strcmp(paramNameQc, inputMeasData(1:2:end)) == 1, 1);
   paramDataQc = inputMeasData{2*idVal};
   paramNameAdjQc = [paramNameOri '_ADJUSTED_QC'];
   idVal = find(strcmp(paramNameAdjQc, inputMeasData(1:2:end)) == 1, 1);
   paramDataAdjQc = inputMeasData{2*idVal};
   for idProf = 1:nProf
      if (dataMode(idProf) ~= 'R')
         if (any((paramDataQc(:, idProf) == g_decArgo_qcStrMissing) & ...
               (paramDataAdjQc(:, idProf) ~= g_decArgo_qcStrMissing)))
            idCor = find((paramDataQc(:, idProf) == g_decArgo_qcStrMissing) & ...
               (paramDataAdjQc(:, idProf) ~= g_decArgo_qcStrMissing));
            paramDataAdjQc(idCor, idProf) = g_decArgo_qcStrMissing;
            inputMeasData{2*idVal} = paramDataAdjQc;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s set to ''%c'' (because in D or A mode %s = ''%c'')\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idCor), paramNameAdjQc, g_decArgo_qcStrMissing, paramNameQc, g_decArgo_qcStrMissing);
            end
         end
      end
   end
end

% set <PARAM>_ADJUSTED_ERROR to FillValue if <PARAM>_ADJUSTED_QC = '9'
for idParam = 1:length(paramlist)
   paramNameOri = paramlist{idParam};
   paramInfo = get_netcdf_param_attributes_3_1(paramNameOri);
   paramNameAdj = [paramNameOri '_ADJUSTED'];
   idVal = find(strcmp(paramNameAdj, inputMeasData(1:2:end)) == 1, 1);
   paramDataAdj = inputMeasData{2*idVal};
   if (any(paramDataAdj ~= paramInfo.fillValue))
      paramNameAdjQc = [paramNameOri '_ADJUSTED_QC'];
      idVal = find(strcmp(paramNameAdjQc, inputMeasData(1:2:end)) == 1, 1);
      paramDataAdjQc = inputMeasData{2*idVal};
      if (any(paramDataAdjQc == g_decArgo_qcStrMissing))
         idMiss = find(paramDataAdjQc == g_decArgo_qcStrMissing);
         paramNameAdjErr = [paramNameOri '_ADJUSTED_ERROR'];
         idVal = find(strcmp(paramNameAdjErr, inputMeasData(1:2:end)) == 1, 1);
         paramDataAdjErr = inputMeasData{2*idVal};
         if (any(paramDataAdjErr(idMiss) ~= paramInfo.fillValue))
            idMiss2 = find(paramDataAdjErr(idMiss) ~= paramInfo.fillValue);
            paramDataAdjErr(idMiss(idMiss2)) = paramInfo.fillValue;
            % update input data
            inputMeasData{2*idVal} = paramDataAdjErr;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: %d values of %s parameter set to FillValue (because %s = ''%c'')\n', ...
                  wmoNum, cyNum, dir, ...
                  length(idMiss2), paramNameAdjErr, paramNameAdjQc, g_decArgo_qcStrMissing);
            end
         end
      end
   end
end

% update HISTORY_DATE (some of them ends with '60' (seconds)
idVal = find(strcmp('HISTORY_DATE', inputData(1:2:end)) == 1, 1);
historyDate = inputData{2*idVal};
[~, nProdDim, nHistoryDim] = size(historyDate);
updatedFlag = 0;
for idHisto = 1:nHistoryDim
   for idProf = 1:nProdDim
      histoDate = historyDate(:, idProf, idHisto);
      if (~isempty(strtrim(histoDate)))
         histoDate = histoDate';
         histoDateOri = histoDate;
         histoDate = datestr(datenum(histoDateOri, 'yyyymmddHHMMSS'), 'yyyymmddHHMMSS');
         if (~strcmp(histoDate, histoDateOri))
            historyDate(:, idProf, idHisto) = histoDate';
            updatedFlag = 1;
            
            if (a_verbose)
               fprintf('INFO: Float #%d Cycle #%d %c: HISTORY_DATE corrected (because ends with ''60'' for N_PROF=%d; N_HISTO=%d)\n', ...
                  wmoNum, cyNum, dir, ...
                  idProf, idHisto);
            end
         end
      end
   end
end
if (updatedFlag)
   inputData{2*idVal} = historyDate;
end

% check JULD, JULD_LOCATION, LATITUDE and LONGITUDE against DEP file ones
if (~isempty(a_ncToDepLinkData))
   idF = find((a_ncToDepLinkData(:, 1) == platformNumber) & (a_ncToDepLinkData(:, 2) == cyNumOri));
   if ~(isempty(idF) || (a_ncToDepLinkData(idF, 3) == -1))
      
      % DEP cycle number
      depCyNum = a_ncToDepLinkData(idF, 3);
      
      DIFF_MIN_JULD_HOURS = 24;
      DIFF_MIN_POS_METERS = 500;
      
      idVal = find(strcmp('JULD', inputData(1:2:end)) == 1, 1);
      juld = inputData{2*idVal};
      idVal = find(strcmp('JULD_QC', inputData(1:2:end)) == 1, 1);
      juldQc = inputData{2*idVal};
      idVal = find(strcmp('JULD_LOCATION', inputData(1:2:end)) == 1, 1);
      juldLocation = inputData{2*idVal};
      idVal = find(strcmp('LATITUDE', inputData(1:2:end)) == 1, 1);
      latitude = inputData{2*idVal};
      idVal = find(strcmp('LONGITUDE', inputData(1:2:end)) == 1, 1);
      longitude = inputData{2*idVal};
      idVal = find(strcmp('POSITION_QC', inputData(1:2:end)) == 1, 1);
      positionQc = inputData{2*idVal};
      
      idFDepInfo = find((a_profTimeAndLocData(:,1) == platformNumber) & ...
         (a_profTimeAndLocData(:,2) == depCyNum) & ...
         (a_profTimeAndLocData(:,3) == 1)); % ascent profile
      if (~isempty(idFDepInfo))
         depJulD = a_profTimeAndLocData(idFDepInfo,4);
         depJulDLocation = a_profTimeAndLocData(idFDepInfo,5);
         depLatitude = a_profTimeAndLocData(idFDepInfo,6);
         depLongitude = a_profTimeAndLocData(idFDepInfo,7);
         
         julParam = get_netcdf_param_attributes_3_1('JULD');
         latitudeParam = get_netcdf_param_attributes_3_1('LATITUDE');
         longitudeParam = get_netcdf_param_attributes_3_1('LONGITUDE');
         
         if (juld ~= julParam.fillValue)
            if (abs(juld - depJulD) > DIFF_MIN_JULD_HOURS/24)
               fprintf('WARNING: Float #%d Cycle #%d: %.1f hours difference in JULD (between DEP and input NetCDF)\n', ...
                  platformNumber, cyNum, abs(juld - depJulD)*24);
            end
            juld = depJulD;
            juldQc = '1';
         end
         if (juldLocation ~= julParam.fillValue)
            if (abs(juldLocation - depJulDLocation) > DIFF_MIN_JULD_HOURS/24)
               fprintf('WARNING: Float #%d Cycle #%d: %.1f hours difference in JULD_LOCATION (between DEP and input NetCDF)\n', ...
                  platformNumber, cyNum, abs(juldLocation - depJulDLocation)*24);
            end
            juldLocation = depJulDLocation;
         end
         if ((latitude ~= latitudeParam.fillValue) && ...
               (longitude ~= longitudeParam.fillValue))
            dist = distance_lpo([latitude depLatitude], [longitude depLongitude]);
            if (dist > DIFF_MIN_POS_METERS)
               fprintf('WARNING: Float #%d Cycle #%d: %d meters difference in profile location (between DEP and input NetCDF)\n', ...
                  platformNumber, cyNum, round(dist));
            end
            latitude = depLatitude;
            longitude = depLongitude;
            positionQc = '1';
         end
      else
         fprintf('WARNING: Float #%d Cycle #%d is missing in profile times and locations from DEP files\n', ...
            platformNumber, cyNum);
      end
      
      idVal = find(strcmp('JULD', inputData(1:2:end)) == 1, 1);
      inputData{2*idVal} = juld;
      idVal = find(strcmp('JULD_QC', inputData(1:2:end)) == 1, 1);
      inputData{2*idVal} = juldQc;
      idVal = find(strcmp('JULD_LOCATION', inputData(1:2:end)) == 1, 1);
      inputData{2*idVal} = juldLocation;
      idVal = find(strcmp('LATITUDE', inputData(1:2:end)) == 1, 1);
      inputData{2*idVal} = latitude;
      idVal = find(strcmp('LONGITUDE', inputData(1:2:end)) == 1, 1);
      inputData{2*idVal} = longitude;
      idVal = find(strcmp('POSITION_QC', inputData(1:2:end)) == 1, 1);
      inputData{2*idVal} = positionQc;
   end
end

% clean unused N_CALIB information
idValParam = find(strcmp('PARAMETER', inputData(1:2:end)) == 1, 1);
parameter = inputData{2*idValParam};
idValEquation = find(strcmp('SCIENTIFIC_CALIB_EQUATION', inputData(1:2:end)) == 1, 1);
scientificCalibEquation = inputData{2*idValEquation};
idValCoef = find(strcmp('SCIENTIFIC_CALIB_COEFFICIENT', inputData(1:2:end)) == 1, 1);
scientificCalibCoefficient = inputData{2*idValCoef};
idValComment = find(strcmp('SCIENTIFIC_CALIB_COMMENT', inputData(1:2:end)) == 1, 1);
scientificCalibComment = inputData{2*idValComment};
idValDate1 = find(strcmp('CALIBRATION_DATE', inputData(1:2:end)) == 1, 1);
idValDate2 = find(strcmp('SCIENTIFIC_CALIB_DATE', inputData(1:2:end)) == 1, 1);
if (~isempty(idValDate1))
   scientificCalibDate = inputData{2*idValDate1};
   if (isempty(scientificCalibDate) && ~isempty(idValDate2))
      scientificCalibDate = inputData{2*idValDate2};
      idValDate = idValDate2;
   else
      idValDate = idValDate1;
   end
else
   scientificCalibDate = inputData{2*idValDate2};
   idValDate = idValDate2;
end

[~, nParamDim, nCalibDim, nProfDim] = size(parameter);
calibToDelList = zeros(nProfDim, nCalibDim);
for idProf = 1:nProfDim
   for idCalib = 1:nCalibDim
      calibToDel = 1;
      for idParam = 1:nParamDim
         param = deblank(parameter(:, idParam, idCalib, idProf)');
         equation = deblank(scientificCalibEquation(:, idParam, idCalib, idProf)');
         coef = deblank(scientificCalibCoefficient(:, idParam, idCalib, idProf)');
         comment = deblank(scientificCalibComment(:, idParam, idCalib, idProf)');
         date = deblank(scientificCalibDate(:, idParam, idCalib, idProf)');
         % we usually have N_CALIB = 10 but with only PARAMETER filled
         if ((~isempty(param) && (idCalib == 1)) || ~isempty(equation) || ~isempty(coef) || ~isempty(comment) || ~isempty(date))
            calibToDel = 0;
            break
         end
      end
      if (calibToDel == 1)
         calibToDelList(idProf, idCalib) =1;
      end
   end
end

firstCalibToDel = -1;
for idProf = 1:nProfDim
   if (any(calibToDelList(idProf, :) == 1))
      firstCalibToDel = max(firstCalibToDel, find(calibToDelList(idProf, :) == 0, 1, 'last')+1);
   else
      firstCalibToDel = -1;
      break
   end
end
if (firstCalibToDel > 1)
   nCalibDimClean = firstCalibToDel - 1;
   parameterClean = repmat(' ', size(parameter, 1), size(parameter, 2), nCalibDimClean);
   scientificCalibEquationClean = repmat(' ', size(scientificCalibEquation, 1), size(scientificCalibEquation, 2), nCalibDimClean);
   scientificCalibCoefficientClean = repmat(' ', size(scientificCalibCoefficient, 1), size(scientificCalibCoefficient, 2), nCalibDimClean);
   scientificCalibCommentClean = repmat(' ', size(scientificCalibComment, 1), size(scientificCalibComment, 2), nCalibDimClean);
   scientificCalibDateClean = repmat(' ', size(scientificCalibDate, 1), size(scientificCalibDate, 2), nCalibDimClean);
   for idProf = 1:nProfDim
      for idCalib = 1:nCalibDimClean
         for idParam = 1:nParamDim
            parameterClean(:, idParam, idCalib, idProf) = parameter(:, idParam, idCalib, idProf);
            scientificCalibEquationClean(:, idParam, idCalib, idProf) = scientificCalibEquation(:, idParam, idCalib, idProf);
            scientificCalibCoefficientClean(:, idParam, idCalib, idProf) = scientificCalibCoefficient(:, idParam, idCalib, idProf);
            scientificCalibCommentClean(:, idParam, idCalib, idProf) = scientificCalibComment(:, idParam, idCalib, idProf);
            scientificCalibDateClean(:, idParam, idCalib, idProf) = scientificCalibDate(:, idParam, idCalib, idProf);
         end
      end
   end
   
   inputData{2*idValParam} = parameterClean;
   inputData{2*idValEquation} = scientificCalibEquationClean;
   inputData{2*idValCoef} = scientificCalibCoefficientClean;
   inputData{2*idValComment} = scientificCalibCommentClean;
   inputData{2*idValDate} = scientificCalibDateClean;
   inputNCalib = nCalibDimClean;
   
   if (a_verbose)
      list = sprintf('%d, ', firstCalibToDel:nCalibDim);
      fprintf('INFO: Float #%d Cycle #%d %c: ''CALIBRATION'' information empty for N_CALIB = (%s)\n', ...
         wmoNum, cyNum, dir, ...
         list(1:end-2));
   end
end

% if JULD > DATE_CREATION set DATE_CREATION = JULD
idVal = find(strcmp('DATE_CREATION', inputData(1:2:end)) == 1, 1);
creationDateStr = inputData{2*idVal};
creationDate = datenum(creationDateStr', 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
idValCreationDate = idVal;
idVal = find(strcmp('JULD', inputData(1:2:end)) == 1, 1);
juld = inputData{2*idVal};
paramStruct = get_netcdf_param_attributes_3_1('JULD');

juld = juld(find(juld ~= paramStruct.fillValue));
if (any(juld > creationDate))
   creationDateNew = max(juld);
   creationDateNewStr = datestr(creationDateNew + g_decArgo_janFirst1950InMatlab, 'yyyymmddHHMMSS');
   inputData{2*idValCreationDate} = creationDateNewStr';
   
   if (a_verbose)
      fprintf('INFO: Float #%d Cycle #%d %c: ''DATE_CREATION'' set to %s\n', ...
         wmoNum, cyNum, dir, ...
         creationDateNewStr);
   end
end

% end %TEMPORARY

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORRECTION END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update the schema with the Input file dimensions
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_PROF', inputNProf);
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_PARAM', inputNParam);
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_CALIB', inputNCalib);
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_LEVELS', inputNLevels);

% create the VERTICAL_SAMPLING_SCHEME of the output profiles
vssProf = [];
for idProf = 1:inputNProf
   vssProf{idProf} = 'Primary sampling: discrete []';
end

% create the Output file with the updated schema
if (exist(a_outputFileName, 'file') == 2)
   delete(a_outputFileName);
   if (exist(a_outputFileName, 'file') == 2)
      o_comment = sprintf('Cannot remove existing file %s', ...
         a_outputFileName);
      return
   end
end
ncwriteschema(a_outputFileName, a_refFileSchema(1));

% open the Output file
fCdf = netcdf.open(a_outputFileName, 'NC_WRITE');
if (isempty(fCdf))
   o_comment = sprintf('ERROR: Unable to open NetCDF input file: %s\n', a_outputFileName);
   return
end

netcdf.reDef(fCdf);

% retrieve the creation date of the Input file
idVal = find(strcmp('DATE_CREATION', inputData(1:2:end)) == 1, 1);
inputDateCreation = inputData{2*idVal}';
if (isempty(deblank(inputDateCreation)))
   inputDateCreation = datestr(now_utc, 'yyyymmddHHMMSS');
end

% set the 'history' global attribute
dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');
globalVarId = netcdf.getConstant('NC_GLOBAL');
globalHistoryText = [datestr(datenum(inputDateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
globalHistoryText = [globalHistoryText ...
   datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COFC software)'];
netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);

% set the resolution attribute to the JULD and JULD_LOCATION parameters
profJulDLocRes = double(1/86400); % 1 second
profJulDRes = double(1/86400); % 1 second
if (var_is_present_dec_argo(fCdf, 'JULD'))
   juldVarId = netcdf.inqVarID(fCdf, 'JULD');
   netcdf.putAtt(fCdf, juldVarId, 'resolution', profJulDRes);
end
if (var_is_present_dec_argo(fCdf, 'JULD_LOCATION'))
   juldLocationVarId = netcdf.inqVarID(fCdf, 'JULD_LOCATION');
   netcdf.putAtt(fCdf, juldLocationVarId, 'resolution', profJulDLocRes);
end

% retrieve the Ids of the dimensions associated with the parameter variables
nProfDimId = netcdf.inqDimID(fCdf, 'N_PROF');
nLevelsDimId = netcdf.inqDimID(fCdf, 'N_LEVELS');

% create the variables on global quality of parameter profile
for idParam = 1:length(paramlist)
   
   paramName = paramlist{idParam};
   
   % create the variables on global quality of parameter profile
   profParamQcName = ['PROFILE_' paramName '_QC'];
   if (~var_is_present_dec_argo(fCdf, profParamQcName))
      profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
      netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
      netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
      netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
   end
end

% create the parameter variables
for idParam = 1:length(paramlist)
   
   paramName = paramlist{idParam};
   
   % retrieve the information on the parameter
   paramStruct = get_netcdf_param_attributes_3_1(paramName);
   if (isempty(paramStruct))
      o_comment = sprintf('ERROR: Parameter ''%s'' not managed yet by this program\n', paramName);
      return
   end
   
   % create the parameter variable and attributes
   if (~var_is_present_dec_argo(fCdf, paramName))
      doubleType = 0;
      if ((strncmp(paramName, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
            (strncmp(paramName, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
         doubleType = 1;
      end
      if (doubleType == 0)
         paramVarId = netcdf.defVar(fCdf, paramName, 'NC_FLOAT', ...
            fliplr([nProfDimId nLevelsDimId]));
      else
         paramVarId = netcdf.defVar(fCdf, paramName, 'NC_DOUBLE', ...
            fliplr([nProfDimId nLevelsDimId]));
      end
      if (~isempty(paramStruct.longName))
         netcdf.putAtt(fCdf, paramVarId, 'long_name', paramStruct.longName);
      end
      if (~isempty(paramStruct.standardName))
         netcdf.putAtt(fCdf, paramVarId, 'standard_name', paramStruct.standardName);
      end
      if (~isempty(paramStruct.fillValue))
         netcdf.putAtt(fCdf, paramVarId, '_FillValue', paramStruct.fillValue);
      end
      if (~isempty(paramStruct.units))
         netcdf.putAtt(fCdf, paramVarId, 'units', paramStruct.units);
      end
      if (~isempty(paramStruct.validMin))
         netcdf.putAtt(fCdf, paramVarId, 'valid_min', paramStruct.validMin);
      end
      if (~isempty(paramStruct.validMax))
         netcdf.putAtt(fCdf, paramVarId, 'valid_max', paramStruct.validMax);
      end
      if (~isempty(paramStruct.cFormat))
         netcdf.putAtt(fCdf, paramVarId, 'C_format', paramStruct.cFormat);
      end
      if (~isempty(paramStruct.fortranFormat))
         netcdf.putAtt(fCdf, paramVarId, 'FORTRAN_format', paramStruct.fortranFormat);
      end
      if (~isempty(paramStruct.resolution))
         netcdf.putAtt(fCdf, paramVarId, 'resolution', paramStruct.resolution);
      end
      if (~isempty(paramStruct.axis))
         netcdf.putAtt(fCdf, paramVarId, 'axis', paramStruct.axis);
      end
   end
   
   % create the parameter QC variable and attributes
   paramNameQc = [paramName '_QC'];
   if (~var_is_present_dec_argo(fCdf, paramNameQc))
      paramQcVarId = netcdf.defVar(fCdf, paramNameQc, 'NC_CHAR', ...
         fliplr([nProfDimId nLevelsDimId]));
      netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
   end
   
   if (paramStruct.adjAllowed == 1)
      % create the parameter adjusted variable and attributes
      paramNameAdj = [paramName '_ADJUSTED'];
      if (~var_is_present_dec_argo(fCdf, paramNameAdj))
         if (doubleType == 0)
            paramAdjVarId = netcdf.defVar(fCdf, paramNameAdj, 'NC_FLOAT', ...
               fliplr([nProfDimId nLevelsDimId]));
         else
            paramAdjVarId = netcdf.defVar(fCdf, paramNameAdj, 'NC_DOUBLE', ...
               fliplr([nProfDimId nLevelsDimId]));
         end
         if (~isempty(paramStruct.longName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'long_name', paramStruct.longName);
         end
         if (~isempty(paramStruct.standardName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'standard_name', paramStruct.standardName);
         end
         if (~isempty(paramStruct.fillValue))
            netcdf.putAtt(fCdf, paramAdjVarId, '_FillValue', paramStruct.fillValue);
         end
         if (~isempty(paramStruct.units))
            netcdf.putAtt(fCdf, paramAdjVarId, 'units', paramStruct.units);
         end
         if (~isempty(paramStruct.validMin))
            netcdf.putAtt(fCdf, paramAdjVarId, 'valid_min', paramStruct.validMin);
         end
         if (~isempty(paramStruct.validMax))
            netcdf.putAtt(fCdf, paramAdjVarId, 'valid_max', paramStruct.validMax);
         end
         if (~isempty(paramStruct.cFormat))
            netcdf.putAtt(fCdf, paramAdjVarId, 'C_format', paramStruct.cFormat);
         end
         if (~isempty(paramStruct.fortranFormat))
            netcdf.putAtt(fCdf, paramAdjVarId, 'FORTRAN_format', paramStruct.fortranFormat);
         end
         if (~isempty(paramStruct.resolution))
            netcdf.putAtt(fCdf, paramAdjVarId, 'resolution', paramStruct.resolution);
         end
         if (~isempty(paramStruct.axis))
            netcdf.putAtt(fCdf, paramAdjVarId, 'axis', paramStruct.axis);
         end
      end
      
      % create the parameter adjusted QC variable and attributes
      paramNameAdjQc = [paramName '_ADJUSTED_QC'];
      if (~var_is_present_dec_argo(fCdf, paramNameAdjQc))
         paramAdjQcVarId = netcdf.defVar(fCdf, paramNameAdjQc, 'NC_CHAR', ...
            fliplr([nProfDimId nLevelsDimId]));
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
      end
      
      % create the parameter adjusted error variable and attributes
      paramNameAdjErr = [paramName '_ADJUSTED_ERROR'];
      if (~var_is_present_dec_argo(fCdf, paramNameAdjErr))
         if (doubleType == 0)
            paramAdjErrVarId = netcdf.defVar(fCdf, paramNameAdjErr, 'NC_FLOAT', ...
               fliplr([nProfDimId nLevelsDimId]));
         else
            paramAdjErrVarId = netcdf.defVar(fCdf, paramNameAdjErr, 'NC_DOUBLE', ...
               fliplr([nProfDimId nLevelsDimId]));
         end
         netcdf.putAtt(fCdf, paramAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
         if (~isempty(paramStruct.fillValue))
            netcdf.putAtt(fCdf, paramAdjErrVarId, '_FillValue', paramStruct.fillValue);
         end
         if (~isempty(paramStruct.units))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'units', paramStruct.units);
         end
         if (~isempty(paramStruct.cFormat))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'C_format', paramStruct.cFormat);
         end
         if (~isempty(paramStruct.fortranFormat))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'FORTRAN_format', paramStruct.fortranFormat);
         end
         if (~isempty(paramStruct.resolution))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'resolution', paramStruct.resolution);
         end
      end
   end
end

netcdf.close(fCdf);

% update the schema with the Input file dimensions
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_PROF', inputNProf);
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_PARAM', inputNParam);
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_CALIB', inputNCalib);
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_LEVELS', inputNLevels);

% update the Output file with the schema
ncwriteschema(a_outputFileName, a_refFileSchema(2));

% open the Output file
fCdf = netcdf.open(a_outputFileName, 'NC_WRITE');
if (isempty(fCdf))
   o_comment = sprintf('ERROR: Unable to open NetCDF input file: %s\n', a_outputFileName);
   return
end

% ready to add the data

% copy of the V3.1 meta.nc file variables into the Output file
for idVar = 1:length(metaVarList)
   
   varName = metaVarList{idVar};
   
   if (var_is_present_dec_argo(fCdf, varName))
      idVal = find(strcmp(varName, a_metaData(1:2:end)) == 1, 1);
      varValue = a_metaData{2*idVal};
      if (isempty(varValue))
         continue
      end
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), varValue);
   else
      fprintf('INFO: Variable %s not present in output format => not copied in output file\n', ...
         varName);
   end
end

% copy of the Input file variables into the Output file
inputFileNHistory = 0;
for idVar = 1:length(wantedInputVars)
   
   varNameIn = wantedInputVars{idVar};
   varNameOut = varNameIn;
   if (strcmp(varNameIn, 'PRES'))
      continue
   end
   
   if ((a_inputFileFormatVersion == 2.2) || ...
         (a_inputFileFormatVersion == 2.3))
      
      if (strcmp(varNameIn, 'CALIBRATION_DATE') == 1)
         varNameOut = 'SCIENTIFIC_CALIB_DATE';
      end
   end
   
   if (var_is_present_dec_argo(fCdf, varNameOut))
      idVal = find(strcmp(varNameIn, inputData(1:2:end)) == 1, 1);
      varValue = inputData{2*idVal};
      if (isempty(varValue))
         continue
      end
      
      if (strcmp(varNameOut, 'HISTORY_INSTITUTION') == 0)
         if (~ischar(varValue))
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), varValue);
         else
            % some STRING dimensions differ
            % Ex: FLOAT_SERIAL_NO from STRING16 to STRING32 (to store coriolis
            % float serial number)
            [varSize] = get_var_size(fCdf, varNameOut);
            if (varSize(1) ~= size(varValue, 1))
               if (length(varSize) == 2)
                  for id1 = 1:varSize(2)
                     if (varSize(1) > size(varValue, 1))
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
                           fliplr([id1-1 0]), ...
                           fliplr([1 size(varValue, 1)]), varValue(:, id1));
                     else
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
                           fliplr([id1-1 0]), ...
                           fliplr([1 varSize(1)]), varValue(1:varSize(1), id1));
                        if (~isempty(deblank(varValue(varSize(1):end, id1))))
                           fprintf('WARNING: Contents of variable ''%s'' truncated: %s truncated to %s\n', ...
                              varNameOut, varValue(:, id1)', varValue(1:varSize(1), id1)');
                        end
                     end
                  end
               elseif (length(varSize) == 3)
                  for id2 = 1:varSize(3)
                     for id1 = 1:varSize(2)
                        if (varSize(1) > size(varValue, 1))
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
                              fliplr([id2-1 id1-1 0]), ...
                              fliplr([1 1 size(varValue, 1)]), varValue(:, id1, id2));
                        else
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
                              fliplr([id2-1 id1-1 0]), ...
                              fliplr([1 1 varSize(1)]), varValue(1:varSize(1), id1, id2));
                           if (~isempty(deblank(varValue(varSize(1):end, id1, id2))))
                              fprintf('WARNING: Contents of variable ''%s'' truncated: %s truncated to %s\n', ...
                                 varNameOut, varValue(:, id1, id2)', varValue(1:varSize(1), id1, id2)');
                           end
                        end
                     end
                  end
               elseif (length(varSize) == 4)
                  for id3 = 1:varSize(4)
                     for id2 = 1:varSize(3)
                        for id1 = 1:varSize(2)
                           if (varSize(1) > size(varValue, 1))
                              netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
                                 fliplr([id3-1 id2-1 id1-1 0]), ...
                                 fliplr([1 1 1 size(varValue, 1)]), varValue(:, id1, id2, id3));
                           else
                              netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
                                 fliplr([id3-1 id2-1 id1-1 0]), ...
                                 fliplr([1 1 1 varSize(1)]), varValue(1:varSize(1), id1, id2, id3));
                              if (~isempty(deblank(varValue(varSize(1):end, id1, id2, id3))))
                                 fprintf('WARNING: Contents of variable ''%s'' truncated: %s truncated to %s\n', ...
                                    varNameOut, varValue(:, id1, id2, id3)', varValue(1:varSize(1), id1, id2, id3)');
                              end
                           end
                        end
                     end
                  end
               else
                  o_comment = sprintf('ERROR: Size length of variable %s is greather than 4\n', varNameOut);
                  return
               end
            else
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), varValue);
            end
         end
      else
         % to force the UNLIMITED N_HISTORY dimension to be updated
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), ...
            [0 0 0], [size(varValue, 1) size(varValue, 2) size(varValue, 3)], varValue);
         inputFileNHistory = size(varValue, 3);
      end
   else
      fprintf('INFO: Variable %s not present in output format => not copied in output file\n', ...
         varNameOut);
   end
end

% copy of the Input file measurements into the Output file
for idVar = 1:length(wantedInputMeasVars)
   
   varNameIn = wantedInputMeasVars{idVar};
   varNameOut = varNameIn;
   
   if (var_is_present_dec_argo(fCdf, varNameOut))
      idVal = find(strcmp(varNameIn, inputMeasData(1:2:end)) == 1, 1);
      varValue = inputMeasData{2*idVal};
      if (isempty(varValue))
         continue
      end
      
      % update the profile quality flags
      if (strncmp(varNameIn, 'PROFILE_', length('PROFILE_')))
         paramName = varNameIn(length('PROFILE_')+1:end-length('_QC'));
         paramQcName = [paramName '_QC'];
         idVal = find(strcmp(paramQcName, inputMeasData(1:2:end)) == 1, 1);
         paramQcValue = inputMeasData{2*idVal};
         profQualityFlag = compute_profile_quality_flag(paramQcValue);
         paramAdjQcName = [paramName '_ADJUSTED_QC'];
         idVal = find(strcmp(paramAdjQcName, inputMeasData(1:2:end)) == 1, 1);
         paramAdjQcValue = inputMeasData{2*idVal};
         profQualityFlag2 = compute_profile_quality_flag(paramAdjQcValue);
         if (profQualityFlag2 ~= g_decArgo_qcStrDef)
            profQualityFlag = profQualityFlag2;
         end
         varValue = profQualityFlag;
      end
      
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameOut), varValue);
   else
      fprintf('INFO: Variable %s not present in output format => not copied in output file\n', ...
         varNameOut);
   end
end

% fill the VERTICAL_SAMPLING_SCHEME variable
for idProf = 1:inputNProf
   value = vssProf{idProf};
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'VERTICAL_SAMPLING_SCHEME'), ...
      fliplr([idProf-1 0]), ...
      fliplr([1 length(value)]), value');
end

% fill the CONFIG_MISSION_NUMBER variable
idVal = find(strcmp('CYCLE_NUMBER', inputData(1:2:end)) == 1, 1);
cycleNumber = unique(inputData{2*idVal});
[confMissionNumber, noCorCyNum] = compute_config_mission_number(cycleNumber, a_metaData, a_corCyNumData);
if (~isempty(confMissionNumber))
   for idProf = 1:inputNProf
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER'), ...
         idProf-1, 1, confMissionNumber);
   end
end

% if the cycle number has not been checked (float not in ANDRO), put a 'comment'
% global attribute
if (noCorCyNum == 1)
   netcdf.reDef(fCdf);
   commentStr = '';
   if (global_att_is_present_dec_argo(fCdf, 'comment'))
      commentStr = netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'comment');
      commentStr = [commentStr ' '];
   end
   commentStr = [commentStr 'The profile number used to assign the CONFIG_MISSION_NUMBER has not been check against ANDRO data.'];
   netcdf.putAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'comment', commentStr);
   netcdf.endDef(fCdf);
end

% add history information that concerns the current program
currentHistoId = inputFileNHistory;
for idProf = 1:inputNProf
   
   value = 'IF';
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
      fliplr([currentHistoId idProf-1 0]), ...
      fliplr([1 1 length(value)]), value');
   value = 'COFC';
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
      fliplr([currentHistoId idProf-1 0]), ...
      fliplr([1 1 length(value)]), value');
   value = g_cofc_ncConvertMonoProfileVersion;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
      fliplr([currentHistoId idProf-1 0]), ...
      fliplr([1 1 length(value)]), value');
   value = dateUpdate;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
      fliplr([currentHistoId idProf-1 0]), ...
      fliplr([1 1 length(value)]), value');
end

% update the format version of the Output file
valueStr = '3.1';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'), 0, length(valueStr), valueStr);

% update the update date of the Output file
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORRECTION BEGIN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% corrections done on input data

% if (0) %TEMPORARY

% if DATA_MODE = 'D':
% for each PARAMETER of the output file:
% - if empty, set SCIENTIFIC_CALIB_DATE to the DATE_UPDATE of the input DM file
% - if empty, set SCIENTIFIC_CALIB_COMMENT to 'none'

if (var_is_present_dec_argo(fCdf, 'DATA_MODE') && ...
      var_is_present_dec_argo(fCdf, 'PARAMETER') && ...
      var_is_present_dec_argo(fCdf, 'SCIENTIFIC_CALIB_DATE') && ...
      var_is_present_dec_argo(fCdf, 'SCIENTIFIC_CALIB_COMMENT'))
   
   dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'));
   calibParam = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER'));
   calibDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE'));
   calibComment = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT'));
   [~, nParamDimInput2, nCalibDimOutput2, nProfDimOutput2] = size(calibParam);
   for idProf = 1:nProfDimOutput2
      if (dataMode(idProf) == 'D')
         for idCalib = 1:nCalibDimOutput2
            for idParam = 1:nParamDimInput2
               param = deblank(calibParam(:, idParam, idCalib, idProf)');
               if (~isempty(param))
                  date = deblank(calibDate(:, idParam, idCalib, idProf)');
                  if (isempty(date))
                     % retrieve the update date of the Input file
                     idVal = find(strcmp('DATE_UPDATE', inputData(1:2:end)) == 1, 1);
                     inputDateUpdate = inputData{2*idVal}';
                     if (~isempty(deblank(inputDateUpdate)))
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE'), ...
                           fliplr([idProf-1 idCalib-1 idParam-1 0]), ...
                           fliplr([1 1 1 length(inputDateUpdate)]), inputDateUpdate');
                        
                        if (a_verbose)
                           fprintf('INFO: Float #%d Cycle #%d %c: ''SCIENTIFIC_CALIB_DATE'' is empty for %s parameter => set to ''DATE_UPDATE'' of input DM file (= %s)\n', ...
                              wmoNum, cyNum, dir, ...
                              param, inputDateUpdate);
                        end
                     else
                        if (a_verbose)
                           fprintf('INFO: Float #%d Cycle #%d %c: ''SCIENTIFIC_CALIB_DATE'' is empty for %s parameter => nothing done since ''DATE_UPDATE'' of input DM file is empty\n', ...
                              wmoNum, cyNum, dir, ...
                              param);
                        end
                     end
                  end
                  comment = deblank(calibComment(:, idParam, idCalib, idProf)');
                  if (isempty(comment))
                     defaultComment = 'none';
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT'), ...
                        fliplr([idProf-1 idCalib-1 idParam-1 0]), ...
                        fliplr([1 1 1 length(defaultComment)]), defaultComment');
                     
                     if (a_verbose)
                        fprintf('INFO: Float #%d Cycle #%d %c: ''SCIENTIFIC_CALIB_COMMENT'' is empty for %s parameter => set to ''%s''\n', ...
                           wmoNum, cyNum, dir, ...
                           param, defaultComment);
                     end
                  end
               end
            end
         end
      end
   end
end

% end %TEMPORARY

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CORRECTION END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

netcdf.close(fCdf);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Compute the configuration number associated to a given cycle number.
%
% SYNTAX :
%  [o_confMissionNumber, o_noCorCyNum] = compute_config_mission_number(a_cycleNumber, a_metaData, a_corCyNumData)
%
% INPUT PARAMETERS :
%   a_cycleNumber  : cycle number from nc input file
%   a_metaData     : meta-data from V3.1 nc meta file
%   a_corCyNumData : corrected cycle number information
%
% OUTPUT PARAMETERS :
%   o_confMissionNumber : configuration number of the cycle
%   o_noCorCyNum        : there is no corrected cycle number
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confMissionNumber, o_noCorCyNum] = compute_config_mission_number(a_cycleNumber, a_metaData, a_corCyNumData)

% output parameters initialization
o_confMissionNumber = [];
o_noCorCyNum = 0;


idVal = find(strcmp('PLATFORM_NUMBER', a_metaData(1:2:end)) == 1, 1);
floatWmo = str2num(strtrim(a_metaData{2*idVal}'));
idVal = find(strcmp('DAC_FORMAT_ID', a_metaData(1:2:end)) == 1, 1);
dacFormatId = strtrim(a_metaData{2*idVal}');
idVal = find(strcmp('CONFIG_MISSION_NUMBER', a_metaData(1:2:end)) == 1, 1);
metaConfMisNum = a_metaData{2*idVal};

if (~isempty(floatWmo) && ~isempty(dacFormatId) && ~isempty(metaConfMisNum))
   
   % retrieve the corrected cycle number
   corCycleNumber = a_cycleNumber;
   if (~isempty(a_corCyNumData))
      idF = find((a_corCyNumData(:, 1) == floatWmo) & (a_corCyNumData(:, 2) == a_cycleNumber));
      if (isempty(idF))
         %          fprintf('INFO: Float %d: Corrected cycle number not found for cycle number #%d => no correction done + ''comment'' global attribute added\n', ...
         %             floatWmo, a_cycleNumber);
         o_noCorCyNum = 1;
      else
         corCycleNumber = a_corCyNumData(idF, 3);
      end
   end
   
   firstProfCycleNum = [];
   switch (dacFormatId)
      case {'11', '4', '1.2', '24', '19', '25', '1.02', '1.01', '6', '1.4', '1.1', '28', '1.3', '1.03', '13', '23', '1.04', '1.5'}
         firstProfCycleNum = 1;
         DPF_FLAG = 0;
      case {'46', '11.1', '013108',  '111509', '042408'}
         firstProfCycleNum = 1;
         DPF_FLAG = 1;
      otherwise
         fprintf('WARNING: Nothing done yet to first deep cycle number for dacFormatId %s\n', dacFormatId);
   end
   
   if (~DPF_FLAG)
      if (length(metaConfMisNum) == 1)
         % only one mission
         o_confMissionNumber = metaConfMisNum;
      else
         % multi-mission with their associated repetition rates
         idVal = find(strcmp('CONFIG_REPETITION_RATE', a_metaData(1:2:end)) == 1, 1);
         repRateMetaData = a_metaData{2*idVal};
         sumRepRate = 0;
         for idRep = 1:length(repRateMetaData)
            sumRepRate = sumRepRate + ...
               str2num(repRateMetaData{idRep}.(char(fieldnames(repRateMetaData{idRep}))));
         end
         if (rem(corCycleNumber-1, sumRepRate) == 0)
            o_confMissionNumber = metaConfMisNum(1);
         else
            o_confMissionNumber = metaConfMisNum(2);
         end
      end
   else
      if (corCycleNumber == firstProfCycleNum)
         % DPF cycle
         o_confMissionNumber = metaConfMisNum(1);
      elseif (length(metaConfMisNum) == 2)
         % only one mission
         o_confMissionNumber = metaConfMisNum(2);
      else
         fprintf('ERROR: TBD FOR DPF\n');
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve information from V3.1 nc meta file and JSON meta-data file.
%
% SYNTAX :
%  [o_metaData] = get_meta_data(a_metaDataFilePathName, a_jsonInputFileName)
%
% INPUT PARAMETERS :
%   a_metaDataFilePathName : V3.1 nc meta file path name
%   a_jsonFloatMetaDirName : JSON meta-data file path name
%
% OUTPUT PARAMETERS :
%   o_metaData : retrieved information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_meta_data(a_metaDataFilePathName, a_jsonInputFileName)

% output parameters initialization
o_metaData = [];


if ~(exist(a_metaDataFilePathName, 'file') == 2)
   return
end

% retrieve information from Input file
wantedInputVars = [ ...
   {'PLATFORM_NUMBER'} ...
   {'DAC_FORMAT_ID'} ...
   {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
   {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_PARAMETER_NAME'} ...
   {'CONFIG_PARAMETER_VALUE'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'DATA_CENTRE'} ...
   {'PLATFORM_TYPE'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'FIRMWARE_VERSION'} ...
   {'WMO_INST_TYPE'} ...
   {'POSITIONING_SYSTEM'} ...
   ];
[o_metaData] = get_data_from_nc_file(a_metaDataFilePathName, wantedInputVars);

% retrieve CONFIG_REPETITION_RATE from json file
repRate = '';
if (exist(a_jsonInputFileName, 'file') == 2)
   % retrieve REPETITION_RATE from json meta-data file
   wantedMetaNames = [ ...
      {'CONFIG_REPETITION_RATE'} ...
      ];
   [repRateMetaData] = get_meta_data_from_json_file(a_jsonInputFileName, wantedMetaNames);
   repRate = repRateMetaData{2};
else
   fprintf('ERROR: Json meta-data file not found: %s => CONFIG_REPETITION_RATE not found\n', ...
      a_jsonInputFileName);
end
o_metaData{end+1} = 'CONFIG_REPETITION_RATE';
o_metaData{end+1} = repRate;

return

% ------------------------------------------------------------------------------
% Retrieve information from json meta-data file.
%
% SYNTAX :
%  [o_metaData] = get_meta_data_from_json_file(a_floatNum, a_wantedMetaNames)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_wantedMetaNames : meta-data to retrieve from json file
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
%   05/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_meta_data_from_json_file(a_jsonInputFileName, a_wantedMetaNames)

% output parameters initialization
o_metaData = [];

% read meta-data file
metaData = loadjson(a_jsonInputFileName);

% retrieve variables from json structure
for idField = 1:length(a_wantedMetaNames)
   fieldName = char(a_wantedMetaNames(idField));
   
   if (isfield(metaData, fieldName))
      fieldValue = metaData.(fieldName);
      if (~isempty(fieldValue))
         o_metaData = [o_metaData {fieldName} {fieldValue}];
      else
         %          fprintf('WARNING: Field %s value is empty in file : %s\n', ...
         %             fieldName, jsonInputFileName);
         o_metaData = [o_metaData {fieldName} {' '}];
      end
   else
      %       fprintf('WARNING: Field %s not present in file : %s\n', ...
      %          fieldName, jsonInputFileName);
      o_metaData = [o_metaData {fieldName} {' '}];
   end
end

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

return

% ------------------------------------------------------------------------------
% Retrieve the dimensions of a given NetCDF variable.
%
% SYNTAX :
%  [o_varSize] = get_var_size(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_varSize : var dimension list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_varSize] = get_var_size(a_ncId, a_varName)

o_varSize = [];

[varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, netcdf.inqVarID(a_ncId, a_varName));


for idDim = 1:length(varDims)
   [dimName, dimLen] = netcdf.inqDim(a_ncId, varDims(idDim));
   o_varSize = [o_varSize dimLen];
end

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
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return
