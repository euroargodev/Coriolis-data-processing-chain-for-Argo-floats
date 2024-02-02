% ------------------------------------------------------------------------------
% Find duplicates in configuration labels.
%
% SYNTAX :
%   nc_find_duplicates_in_config_mission_labels or
%   nc_find_duplicates_in_config_mission_labels(6900189, 7900118)
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
%   12/06/2022 - RNU - creation
% ------------------------------------------------------------------------------
function nc_find_duplicates_in_config_mission_labels(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'D:\202211-ArgoData\coriolis\';

% default list of floats to convert (should be set to '' if we want to process
% all the floats of the DIR_INPUT_NC_FILES directory)
FLOAT_LIST_FILE_NAME = ''; % process all the floats of the DIR_INPUT_NC_FILES directory
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_apf11.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% default values initialization
init_default_values;


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

floatList = [];
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      
      floatListFileName = FLOAT_LIST_FILE_NAME;
      
      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         return
      end
      
      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

if (isempty(floatList))
   % process floats encountered in the DIR_INPUT_NC_FILES directory
   
   floatDirs = dir(DIR_INPUT_NC_FILES);
   for idDir = 1:length(floatDirs)
      
      floatDirName = floatDirs(idDir).name;
      floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
      if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
         floatList = [floatList str2num(floatDirName)];
      end
   end
end

% create and start log file recording
name = '';
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      [pathstr, name, ext] = fileparts(floatListFileName);
      name = ['_' name];
   end
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_find_duplicates_in_config_mission_labels' name '_' currentTime '.log'];
diary(logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   Input files directory: DIR_INPUT_NC_FILES = ''%s''\n', DIR_INPUT_NC_FILES);
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      fprintf('   Floats to process: %d floats of the list FLOAT_LIST_FILE_NAME = ''%s''\n', length(floatList), FLOAT_LIST_FILE_NAME);
   else
      fprintf('   Floats to process: %d floats of the directory DIR_INPUT_NC_FILES = ''%s''\n', length(floatList), DIR_INPUT_NC_FILES);
   end
else
   fprintf('   Floats to process:');
   fprintf(' %d', floatList);
   fprintf('\n');
end
fprintf('   Log file directory: DIR_LOG_FILE = ''%s''\n', DIR_LOG_FILE);
fprintf('\n');

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncInputFileDir, 'dir') == 7)
            
      % get configuration mission numbers from META.nc
      ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
      if ~(exist(ncMetaFilePathName, 'file') == 2)
         fprintf('ERROR: Meta file is missing\n');
         continue
      end

      % retrieve information from meta-data file
      wantedInputVars = [ ...
         {'FORMAT_VERSION'} ...
         {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
         {'CONFIG_PARAMETER_NAME'} ...
         ];
      [metaData] = get_data_from_nc_file(ncMetaFilePathName, wantedInputVars);
      idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)), 1);
      formatVersion = metaData{2*idVal}';
      if (str2num(formatVersion) ~= 3.1)
         fprintf('ERROR: Meta file is expected to be in 3.1 format version (but FORMAT_VERSION = %s) - ignored\n', formatVersion);
         continue
      end
      idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData(1:2:end)), 1);
      launchConfigParamName = cellstr(metaData{2*idVal}');
      idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData(1:2:end)), 1);
      configParamName = cellstr(metaData{2*idVal}');

      % check duplicates in configuration labels
      if (length(launchConfigParamName) ~= length(unique(launchConfigParamName)))
         uConfigLabelList = unique(launchConfigParamName);
         for idL = 1:length(uConfigLabelList)
            idF = find(strcmp(launchConfigParamName, uConfigLabelList{idL}));
            if (length(idF) > 1)
               fprintf('ERROR: Float %d: Multiple (%d) ''%s'' config label in launch configuration\n', ...
                  floatNum, length(idF), uConfigLabelList{idL});
            end
         end
      end
      if (length(configParamName) ~= length(unique(configParamName)))
         uConfigLabelList = unique(configParamName);
         for idL = 1:length(uConfigLabelList)
            idF = find(strcmp(configParamName, uConfigLabelList{idL}));
            if (length(idF) > 1)
               fprintf('ERROR: Float %d: Multiple (%d) ''%s'' config label in configuration\n', ...
                  floatNum, length(idF), uConfigLabelList{idL});
            end
         end
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

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
      fprintf('RTQC_ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         %          fprintf('RTQC_WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return
