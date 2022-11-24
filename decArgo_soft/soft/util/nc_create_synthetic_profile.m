% ------------------------------------------------------------------------------
% Generate a synthetic profile from C and B mono-profile files.
%
% SYNTAX :
%   nc_create_synthetic_profile(varargin)
%
% INPUT PARAMETERS :
%   varargin :
%      input parameters:
%         - should be provided as pairs ('param_name','param_value')
%         - 'param_name' value is not case sensitive
%         - all parameters are optional
%      expected parameters:
%         floatWmo      : WMO number of concerned float
%         inputDirName  : name of the input directory
%         outputDirName : name of the output directory
%      if input parameters are not provided:
%         floatWmo      => floats of the FLOAT_LIST_FILE_NAME list are processed
%         inputDirName  => DIR_INPUT_NC_FILES is used
%         outputDirName => DIR_OUTPUT_NC_FILES is used
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
%   06/15/2018 - RNU - V 1.0: creation of PI and RT tool + generate NetCDF 4 output files
%   07/13/2018 - RNU - V 1.1: the temporary directory could be set by an input parameter
%   08/22/2018 - RNU - V 1.2: manage missing PARAMETER_DATA_MODE when DATA_MODE == 'R'
%   09/25/2018 - RNU - V 1.3: added input parameters 'floatWmo', 'inputDirName'
%                             and 'outputDirName'
%   02/27/2019 - RNU - V 1.4: includes version 18.02.2019 of ARGO_simplified_profile
%   04/15/2019 - RNU - V 1.6: correction of previous version (set to 1.6
%                             instead of 1.5 so that nc_create_synthetic_profile_rt
%                             and nc_create_synthetic_profile_rt share the same
%                             version number)
%   07/08/2019 - RNU - V 1.7: for NetCDF-4 files, use 'defVarFill' function
%                             instead of 'putAtt' to define the fill Value of a
%                             variable
%   04/22/2020 - RNU - V 1.8: added a CSV output file that recall the
%                             INFO/WARNING/ERROR messages of the log file
%   07/06/2020 - RNU - V 1.9: includes version 30.06.2020 of ARGO_simplified_profile
%                             this new version generates S-PROF file (possibly
%                             empty) even when 'c' PROF or 'b' PROF file is
%                             missing
%   07/10/2020 - RNU - V 1.10: correction in processing of PROFILE_<PARAM>_QC
%                              (the input Qcs used depend on PARAMATER_DATA_MODE
%                              information)
%   04/27/2021 - RNU - V 1.11: ignore Bounce cycles (from Ice cycles of APEX
%                              APF1 floats) because they have distinct JULD and
%                              LOCATION
%   04/05/2022 - RNU - V 1.12: includes version 01.04.2022 of ARGO_simplified_profile
% ------------------------------------------------------------------------------
function nc_create_synthetic_profile(varargin)

% generate NetCDF-4 flag for mono-profile file
global g_cocs_netCDF4FlagForMonoProf;
g_cocs_netCDF4FlagForMonoProf = 0;

% generate NetCDF-4 flag for multiple-profiles file
global g_cocs_netCDF4FlagForMultiProf;
g_cocs_netCDF4FlagForMultiProf = 1;

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp_pb_S-prof.txt';
% FLOAT_LIST_FILE_NAME = '';

% top directory of input NetCDF files
DIR_INPUT_NC_FILES = 'H:\archive_201801\coriolis\';
DIR_INPUT_NC_FILES = 'H:\archive_201801\aoml\';
DIR_INPUT_NC_FILES = 'H:\archive_201801\CSIRO\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\SYNTHETIC_PROFILE\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';

% top directory of output NetCDF files
% DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST_S-PROF\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the CSV file (should be set to '' if output CSV file is not
% needed)
% DIR_CSV_FILE = ''; % if you don't need output CSV file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% base name of the temporary directory
DIR_TMP = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\TMP\';

% merged profile reference file
if (g_cocs_netCDF4FlagForMonoProf)
   MONO_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoSProf_V1.0_netcdf4_classic.nc';
else
   MONO_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoSProf_V1.0_netcdf_classic.nc';
end
if (g_cocs_netCDF4FlagForMultiProf)
   MULTI_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoSProf_V1.0_netcdf4_classic.nc';
else
   MULTI_PROF_REF_PROFILE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoSProf_V1.0_netcdf_classic.nc';
end

% to generate the multi-profile file
CREATE_MULTI_PROF_FLAG = 1;

% program version
global g_cocs_ncCreateSyntheticProfileVersion;
g_cocs_ncCreateSyntheticProfileVersion = '1.12 (version 01.04.2022 for ARGO_simplified_profile)';

% current float and cycle identification
global g_cocs_floatNum;

% output CSV file Id
global g_cocs_fidCsvFile;
g_cocs_fidCsvFile = -1;


% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

errorFlag = 0;

% get input parameters
[inputError, floatWmo, inputDirName, outputDirName] = parse_input_param(varargin);
if (inputError == 1)
   return
end

% input parameters management
floatList = [];
if (isempty(floatWmo))
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
   floatList = str2double(floatWmo);
end

if (~isempty(inputDirName))
   DIR_INPUT_NC_FILES = inputDirName;
end

if (~isempty(outputDirName))
   DIR_OUTPUT_NC_FILES = outputDirName;
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'nc_create_synthetic_profile_' currentTime '.log'];
diary(logFile);

% check configuration consistency
if ~(exist(DIR_INPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Input directory not found: %s\n', DIR_INPUT_NC_FILES);
   errorFlag = 1;
end

if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Output directory not found: %s\n', DIR_OUTPUT_NC_FILES);
   errorFlag = 1;
end

if ~(exist(MONO_PROF_REF_PROFILE_FILE, 'file') == 2)
   fprintf('ERROR: Mono-profile reference file not found: %s\n', MONO_PROF_REF_PROFILE_FILE);
   errorFlag = 1;
end

if ~(exist(MULTI_PROF_REF_PROFILE_FILE, 'file') == 2)
   fprintf('ERROR: Multi-profile reference file not found: %s\n', MULTI_PROF_REF_PROFILE_FILE);
   errorFlag = 1;
end

if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   fprintf('ERROR: Log directory not found: %s\n', DIR_LOG_FILE);
   errorFlag = 1;
end

if (~isempty(DIR_CSV_FILE))
   if ~(exist(DIR_CSV_FILE, 'dir') == 7)
      fprintf('ERROR: CSV directory not found: %s\n', DIR_CSV_FILE);
      errorFlag = 1;
   end
end

if (errorFlag == 0)
   
   % output CSV file name
   [~, logFileName, ~] = fileparts(logFile);
   csvFileName = [DIR_CSV_FILE '/' logFileName '.csv'];
   
   % create CSV file
   g_cocs_fidCsvFile = fopen(csvFileName, 'wt');
   if (g_cocs_fidCsvFile == -1)
      fprintf('ERROR: Unable to create output CSV file: %s\n', csvFileName);
      return
   end
   
   % put header
   %    header = 'dac, type, float code, cycle number, message, file';
   %    fprintf(g_cocs_fidCsvFile, '%s\n', header);

   if (~isempty(floatList))
      
      % process floats of the FLOAT_LIST_FILE_NAME file (or provided in input
      % parameters)
      
      floatNum = 1;
      for idFloat = 1:length(floatList)
         g_cocs_floatNum = floatList(idFloat);
         floatDirPathName = [DIR_INPUT_NC_FILES '/' num2str(g_cocs_floatNum) '/'];
         if (exist(floatDirPathName, 'dir') == 7)
            
            fprintf('%03d/%03d %d\n', idFloat, length(floatList), g_cocs_floatNum);
            
            process_one_float(floatDirPathName, DIR_OUTPUT_NC_FILES, ...
               CREATE_MULTI_PROF_FLAG, MONO_PROF_REF_PROFILE_FILE, MULTI_PROF_REF_PROFILE_FILE, DIR_TMP);
            
            floatNum = floatNum + 1;
         else
            fprintf('ERROR: No directory for float #%d\n', g_cocs_floatNum);
         end
      end
   else
      
      % process floats encountered in the DIR_INPUT_NC_FILES directory
      
      floatNum = 1;
      floatDirs = dir(DIR_INPUT_NC_FILES);
      for idDir = 1:length(floatDirs)
         
         floatDirName = floatDirs(idDir).name;
         floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            
            [g_cocs_floatNum, status] = str2num(floatDirName);
            if (status == 1)
               
               fprintf('%03d/%03d %d\n', floatNum, length(floatDirs)-2, g_cocs_floatNum);
               
               process_one_float(floatDirPathName, DIR_OUTPUT_NC_FILES, ...
                  CREATE_MULTI_PROF_FLAG, MONO_PROF_REF_PROFILE_FILE, MULTI_PROF_REF_PROFILE_FILE, DIR_TMP);
               
               floatNum = floatNum + 1;
            end
         end
      end
   end
end

fclose(g_cocs_fidCsvFile);

diary off;

% if (~isempty(DIR_CSV_FILE))
%    % generate CSV file (from log file contents)
%    generate_csv_file(logFile, DIR_CSV_FILE);
% end

return

% ------------------------------------------------------------------------------
% Generate a synthetic profile for a given float.
%
% SYNTAX :
%  process_one_float(a_floatDir, a_outputDir, ...
%    a_createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile, a_tmpDir)
%
% INPUT PARAMETERS :
%   a_floatDir            : float input data directory
%   a_outputDir           : top directory of synthetic profile
%   a_createMultiProfFlag : flag to generate multi-prof netCDF synthetic file
%   a_monoProfRefFile     : netCDF synthetic mono-profile file schema
%   a_multiProfRefFile    : netCDF synthetic multi-profile file schema
%   a_tmpDir              : base name of the temporary directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/08/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_one_float(a_floatDir, a_outputDir, ...
   a_createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile, a_tmpDir)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;
g_cocs_cycleDir = '';

% output CSV file information
global g_cocs_fidCsvFile;
global g_cocs_dacName;
g_cocs_dacName = '-';
global g_cocs_floatWmoStr;
g_cocs_floatWmoStr = num2str(g_cocs_floatNum);
global g_cocs_cycleNumStr;
g_cocs_cycleNumStr = '-';
global g_cocs_inputFile;
g_cocs_inputFile = '-';

floatWmoStr = num2str(g_cocs_floatNum);


% META data file
metaFileName = [a_floatDir '/' floatWmoStr '_meta.nc'];
if ~(exist(metaFileName, 'file') == 2)
   fprintf('ERROR: Float %d: META file not found: %s\n', g_cocs_floatNum, metaFileName);
   
   % CSV output
   msgType = 'error';
   message = 'File not found.';
   [~, fileName, fileExt] = fileparts(metaFileName);
   g_cocs_inputFile  = [fileName fileExt];
   fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
      g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);

   return
end

% retrieve DATA_CENTRE from META file
wantedVars = [ ...
   {'DATA_CENTRE'} ...
   ];
[metaData] = get_data_from_nc_file(metaFileName, wantedVars);
dataCentre = get_data_from_name('DATA_CENTRE', metaData);
g_cocs_dacName = dataCentre(:, 1)';

% create the list of available cycle numbers (from PROF files)
profileDir = [a_floatDir '/profiles'];
files = dir([profileDir '/' '*' floatWmoStr '_' '*.nc']);
cyNumList = [];
bgcFloatFlag = 0;
for idFile = 1:length(files)
   fileName = files(idFile).name;
   if (fileName(1) == 'B')
      bgcFloatFlag = 1;
   end
   if (ismember(fileName(1), 'DRB'))
      idF = strfind(fileName, floatWmoStr);
      cyNumStr = fileName(idF+length(floatWmoStr)+1:end-3);
      if (cyNumStr(end) == 'D')
         cyNumStr(end) = [];
      end
      cyNumList = [cyNumList str2num(cyNumStr)];
   end
end
cyNumList = unique(cyNumList);

% process PROF files
for idCy = 1:length(cyNumList)
   
   g_cocs_cycleNum = cyNumList(idCy);
   g_cocs_cycleNumStr = num2str(g_cocs_cycleNum);
   
   createMultiProfFlag = 0;
   if (idCy == length(cyNumList))
      createMultiProfFlag = a_createMultiProfFlag;
   end
   
   % process descending and ascending profiles
   for idDir = 1:2
      
      if (idDir == 1)
         g_cocs_cycleDir = 'D';
      else
         g_cocs_cycleDir = '';
      end
      
      cProfFileName = '';
      bProfFileName = '';
      if (exist([profileDir '/' sprintf('D%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         cProfFileName = [profileDir '/' sprintf('D%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)];
      elseif (exist([profileDir '/' sprintf('R%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         cProfFileName = [profileDir '/' sprintf('R%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)];
      end
      if (exist([profileDir '/' sprintf('BD%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         bProfFileName = [profileDir '/' sprintf('BD%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)];
      elseif (exist([profileDir '/' sprintf('BR%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)], 'file') == 2)
         bProfFileName = [profileDir '/' sprintf('BR%d_%03d%c.nc', g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir)];
      end
      
      if (~isempty(cProfFileName) || ~isempty(bProfFileName))
         
         fprintf('   %02d/%02d: Float #%d Cycle #%d%c\n', ...
            idCy, length(cyNumList), g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
         
         % generate S-PROF file
         nc_create_synthetic_profile_( ...
            0, ...
            cProfFileName, bProfFileName, metaFileName, ...
            createMultiProfFlag, ...
            a_outputDir, ...
            a_monoProfRefFile, a_multiProfRefFile, ...
            a_tmpDir, bgcFloatFlag);
         
      end
   end
end

return

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_inputError, o_floatWmo, o_inputDirName, o_outputDirName] = ...
%    parse_input_param(varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError    : input error flag
%   o_floatWmo      : float WMO number
%   o_inputDirName  : name of the input directory
%   o_outputDirName : name of the output directory
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/25/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError, o_floatWmo, o_inputDirName, o_outputDirName] = ...
   parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;
o_floatWmo = [];
o_inputDirName = '';
o_outputDirName = '';


% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'floatWmo'))
            o_floatWmo = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputDirName'))
            o_inputDirName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDirName'))
            o_outputDirName = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (''%s'') - ignored\n', a_varargin{id});
         end
      end
   end
end

% check input parameters
if (~isempty(o_inputDirName))
   if ~(exist(o_inputDirName, 'dir') == 7)
      fprintf('ERROR: Input directory not found: %s\n', o_inputDirName);
      o_inputError = 1;
   end
end
if (~isempty(o_outputDirName))
   if ~(exist(o_outputDirName, 'dir') == 7)
      fprintf('ERROR: Output directory not found: %s\n', o_outputDirName);
      o_inputError = 1;
   end
end
if (~isempty(o_inputDirName) && ~isempty(o_floatWmo))
   if ~(exist([o_inputDirName '/' o_floatWmo], 'dir') == 7)
      fprintf('ERROR: Float input directory not found: %s\n', [o_inputDirName '/' o_floatWmo]);
      o_inputError = 1;
   end
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
%   06/15/2018 - RNU - creation
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

% output CSV file information
global g_cocs_fidCsvFile;
global g_cocs_dacName;
global g_cocs_floatWmoStr;
global g_cocs_cycleNumStr;
global g_cocs_cycleDir;
global g_cocs_inputFile;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      
      % CSV output
      msgType = 'error';
      message = 'Unable to open file.';
      [~, fileName, fileExt] = fileparts(a_ncPathFileName);
      g_cocs_inputFile  = [fileName fileExt];
      fprintf(g_cocs_fidCsvFile, '%s,%s,%s,%s%s,%s,%s\n', ...
         g_cocs_dacName, msgType, g_cocs_floatWmoStr, g_cocs_cycleNumStr, g_cocs_cycleDir, message, g_cocs_inputFile);
      
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
