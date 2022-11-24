% ------------------------------------------------------------------------------
% Check consistency between defined and used configuration mission numbers.
%
% SYNTAX :
%   nc_check_config_mission_number or nc_check_config_mission_number(6900189, 7900118)
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
%   06/24/2020 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_config_mission_number(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'E:\202002-ArgoData\coriolis\';

% default list of floats to convert (should be set to '' if we want to process
% all the floats of the DIR_INPUT_NC_FILES directory)
FLOAT_LIST_FILE_NAME = ''; % process all the floats of the DIR_INPUT_NC_FILES directory
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the CSV file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

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

logFile = [DIR_LOG_FILE '/' 'nc_check_config_mission_number' name '_' currentTime '.log'];
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
fprintf('   Csv file directory: DIR_CSV_FILE = ''%s''\n', DIR_CSV_FILE);
fprintf('\n');

% create the CSV output file
outputFileName = [DIR_CSV_FILE '/' 'nc_check_config_mission_number' name '_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['WMO;MSG_TYPE;NB META CONFIG;NB USED CONFIG'];
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
   
   if (exist(ncInputFileDir, 'dir') == 7)
      
      configNumListMeta = [];
      configNumListTraj = [];
      configNumListProf = [];
      
      % get configuration mission numbers from META.nc
      ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
      if ~(exist(ncMetaFilePathName, 'file') == 2)
         fprintf('ERROR: meta file is missing\n');
         continue
      end
      [formatVersion, configNumMeta] = get_config_mission_number(ncMetaFilePathName);
      if (formatVersion ~= 3.1)
         fprintf('INFO: meta file version is %g (%s)\n', formatVersion, ncMetaFilePathName);
         continue
      end      
      configNumListMeta = unique(configNumMeta);
      
      % get configuration mission numbers from TRAJ.nc
      ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Rtraj.nc', floatNum)];
      if ~(exist(ncTrajInputFilePathName, 'file') == 2)
         ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Dtraj.nc', floatNum)];
         if ~(exist(ncTrajInputFilePathName, 'file') == 2)
            fprintf('ERROR: traj file is missing\n');
            ncTrajInputFilePathName = '';
         end
      end
      if (~isempty(ncTrajInputFilePathName))
         [formatVersion, configNumTraj] = get_config_mission_number(ncTrajInputFilePathName);
         if (formatVersion ~= 3.1)
            fprintf('INFO: traj file version is %g (%s)\n', formatVersion, ncTrajInputFilePathName);
         else
            configNumListTraj = unique(configNumTraj);
            configNumListTraj(find(configNumListTraj == 99999)) = [];
            
            if (~isempty(configNumListMeta))
               missingConfigNumList = setdiff(configNumListTraj, configNumListMeta);
            else
               missingConfigNumList = configNumListTraj;
            end
            if (~isempty(missingConfigNumList))
               confListStr = sprintf('%d,', missingConfigNumList);
               fprintf('ERROR: missing traj config (%s) in file (%s)\n', ...
                  confListStr(1:end-1), ncTrajInputFilePathName);
            end
         end
      end
      
      % get configuration mission numbers from PROF.nc
      ncInputFileDir = [ncInputFileDir '/profiles/'];
      if (exist(ncInputFileDir, 'dir') == 7)
         
         ncInputFiles = dir([ncInputFileDir '*.nc']);
         for idFile = 1:length(ncInputFiles)
            
            monoProfInputFileName = ncInputFiles(idFile).name;
            if ((monoProfInputFileName(1) == 'B') || (monoProfInputFileName(1) == 'S'))
               continue
            end
            monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
            [formatVersion, configNumProf] = get_config_mission_number(monoProfInputFilePathName);
            if (formatVersion ~= 3.1)
               fprintf('INFO: prof file version is %g (%s)\n', formatVersion, monoProfInputFilePathName);
            else
               configNumProf = unique(configNumProf);
               if (any(configNumProf == 99999))
                  fprintf('ERROR: default config number in file: %s\n', monoProfInputFilePathName);
               end
               
               if (~isempty(configNumListMeta))
                  missingConfigNumList = setdiff(configNumProf, configNumListMeta);
               else
                  missingConfigNumList = configNumProf;
               end
               if (~isempty(missingConfigNumList))
                  confListStr = sprintf('%d,', missingConfigNumList);
                  fprintf('ERROR: missing prof config (%s) in file (%s)\n', ...
                     confListStr(1:end-1), monoProfInputFilePathName);
               end
               
               configNumListProf = unique([configNumListProf; configNumProf]);
            end
         end
         
         usedConfigNumList = unique([configNumListTraj; configNumListProf]);
         unusedConfigNumList = [];
         if (~isempty(configNumListMeta))
            unusedConfigNumList = setdiff(configNumListMeta, usedConfigNumList);
         end
         if (~isempty(configNumListMeta))
            missingConfigNumList = setdiff(usedConfigNumList, configNumListMeta);
         else
            missingConfigNumList = usedConfigNumList;
         end
         
         fprintf(fidOut, '%d;INFO;%d;%d\n', ...
            floatNum, length(configNumListMeta), length(usedConfigNumList));

         if (~isempty(unusedConfigNumList))
            confListStr = sprintf('; %d', unusedConfigNumList);
            fprintf(fidOut, '%d;WARNING;%d;%d;UNUSED CONFIGURATIONS%s\n', ...
               floatNum, length(configNumListMeta), length(usedConfigNumList), confListStr);
         end
         
         if (~isempty(missingConfigNumList))
            confListStr = sprintf('; %d', missingConfigNumList);
            fprintf(fidOut, '%d;ERROR;%d;%d;MISSING CONFIGURATIONS%s\n', ...
               floatNum, length(configNumListMeta), length(usedConfigNumList), confListStr);
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

fclose(fidOut);

diary off;

return
   
% ------------------------------------------------------------------------------
% Retrieve the list of configuration mission numbers (CONFIG_MISSION_NUMBER)
% from NetCDF file.
%
% SYNTAX :
%  [o_formatVersion, o_confNumList] = get_config_mission_number(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : NetCDF file path name
%
% OUTPUT PARAMETERS :
%   o_formatVersion : version number of the file format
%   o_confNumList   : list of configuration mission numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_formatVersion, o_confNumList] = get_config_mission_number(a_filePathName)

% output parameters initialization
o_confNumList = [];
o_formatVersion = '';

wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   ];
[ncData] = get_data_from_nc_file(a_filePathName, wantedVars);
         
idVal = find(strcmp('FORMAT_VERSION', ncData) == 1);
if (~isempty(idVal))
   o_formatVersion = str2double(ncData{idVal+1}');
end
idVal = find(strcmp('CONFIG_MISSION_NUMBER', ncData) == 1);
if (~isempty(idVal))
   o_confNumList = ncData{idVal+1};
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
