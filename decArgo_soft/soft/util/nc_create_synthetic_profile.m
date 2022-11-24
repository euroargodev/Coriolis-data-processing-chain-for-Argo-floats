% ------------------------------------------------------------------------------
% Generate a synthetic profile from C and B mono-profile files.
%
% SYNTAX :
%   nc_create_synthetic_profile(6900189, 7900118) or
%   nc_create_synthetic_profile (in this case all the floats of the
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
%   06/15/2018 - RNU - V 1.0: creation of PI and RT tool + generate NetCDF 4 output files
% ------------------------------------------------------------------------------
function nc_create_synthetic_profile(varargin)

% generate NetCDF-4 flag for mono-profile file
global g_cocs_netCDF4FlagForMonoProf;
g_cocs_netCDF4FlagForMonoProf = 0;

% generate NetCDF-4 flag for multiple-profiles file
global g_cocs_netCDF4FlagForMultiProf;
g_cocs_netCDF4FlagForMultiProf = 1;

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of input NetCDF files
DIR_INPUT_NC_FILES = 'H:\archive_201801\coriolis\';
DIR_INPUT_NC_FILES = 'H:\archive_201801\aoml\';
DIR_INPUT_NC_FILES = 'H:\archive_201801\CSIRO\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\SYNTHETIC_PROFILE\';

% top directory of output NetCDF files
% DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST_S-PROF_classic\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST_S-PROF_netcdf4_classic_co\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST_S-PROF_netcdf4_classic_aoml\';
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST_S-PROF_netcdf4_classic_csiro\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

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
g_cocs_ncCreateSyntheticProfileVersion = '1.0 (version 29.06.2018 for ARGO_simplify_getpressureaxis_v6)';

% current float and cycle identification
global g_cocs_floatNum;


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
   if (iscellstr(varargin))
      if (nargin == 1)
         floatList = str2double(cell2mat(varargin));
      else
         fprintf('ERROR: Inconsistent input parameter\n');
         errorFlag = 1;
      end
   else
      floatList = cell2mat(varargin);
   end
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

if (errorFlag == 0)
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
               CREATE_MULTI_PROF_FLAG, MONO_PROF_REF_PROFILE_FILE, MULTI_PROF_REF_PROFILE_FILE);
            
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
                  CREATE_MULTI_PROF_FLAG, MONO_PROF_REF_PROFILE_FILE, MULTI_PROF_REF_PROFILE_FILE);
               
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
%  process_one_float(a_floatDir, a_outputDir, ...
%    a_createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile)
%
% INPUT PARAMETERS :
%   a_floatDir            : float input data directory
%   a_outputDir           : top directory of synthetic profile
%   a_createMultiProfFlag : flag to generate multi-prof netCDF synthetic file
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
function process_one_float(a_floatDir, a_outputDir, ...
   a_createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile)

% current float and cycle identification
global g_cocs_floatNum;
global g_cocs_cycleNum;
global g_cocs_cycleDir;


% consider float only if B prof files exist
if (isempty(dir([a_floatDir '/profiles/' sprintf('B*%d*.nc', g_cocs_floatNum)])))
   return;
end

floatWmoStr = num2str(g_cocs_floatNum);

% META data file
metaFileName = [a_floatDir '/' floatWmoStr '_meta.nc'];
if ~(exist(metaFileName, 'file') == 2)
   fprintf('ERROR: Float %d: META file not found: %s\n', g_cocs_floatNum, metaFileName);
   return;
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

% process PROF files
for idCy = 1:length(cyNumList)
   
   g_cocs_cycleNum = cyNumList(idCy);
   
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
      
      if (~isempty(cProfFileName))
         if (~isempty(bProfFileName))
            
            fprintf('   %02d/%02d: Float #%d Cycle #%d%c\n', ...
               idCy, length(cyNumList), g_cocs_floatNum, g_cocs_cycleNum, g_cocs_cycleDir);
            
            % generate S-PROF file
            nc_create_synthetic_profile_(cProfFileName, bProfFileName, metaFileName, ...
               a_outputDir, createMultiProfFlag, a_monoProfRefFile, a_multiProfRefFile);
         end
      end
   end
end

return;
