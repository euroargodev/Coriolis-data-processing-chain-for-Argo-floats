% ------------------------------------------------------------------------------
% Check that MTIME parameter is present in the META.nc file, in C-PROF files and
% not in B-PROF files of a given list of floats.
%
% SYNTAX :
%   nc_check_mtime_parameter or nc_check_mtime_parameter(6900189, 7900118)
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
%   10/17/2023 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_mtime_parameter(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'G:\argo_snapshot_202309\coriolis\';

% default list of floats to convert (should be set to '' if we want to process
% all the floats of the DIR_INPUT_NC_FILES directory)
% FLOAT_LIST_FILE_NAME = ''; % process all the floats of the DIR_INPUT_NC_FILES directory
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\float_with_mtime_20231016.txt';

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

logFile = [DIR_LOG_FILE '/' 'nc_check_mtime_parameter' name '_' currentTime '.log'];
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

outputFileName = [DIR_CSV_FILE '/' 'nc_check_mtime_parameter' name '_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
   return
end

fprintf(fidOut, 'WMO;FILE_TYPE;FILE_NAME;COMMENT\n');

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];

   if (exist(ncInputFileDir, 'dir') == 7)

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get parameter list from META.nc file
      ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
      if ~(exist(ncMetaFilePathName, 'file') == 2)
         fprintf('ERROR: Float %d: meta file is missing - float ignored\n', floatNum);
         continue
      end
      paramNameList = get_param_name_list(ncMetaFilePathName, 0);
      if (~any(strcmp(paramNameList, 'MTIME')))
         % fprintf('ERROR: Float %d: ''MTIME'' missing in file : %s\n', floatNum, sprintf('%d_meta.nc', floatNum));
         fprintf(fidOut, '%d;%s;%s;%s\n', ...
            floatNum, 'META', sprintf('%d_meta.nc', floatNum), '''MTIME'' missing');
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get parameter list from PROF.nc files

      ncInputFileDir = [ncInputFileDir '/profiles/'];
      if (exist(ncInputFileDir, 'dir') == 7)

         ncInputFiles = dir([ncInputFileDir '*.nc']);
         for idFile = 1:length(ncInputFiles)

            monoProfInputFileName = ncInputFiles(idFile).name;
            if (monoProfInputFileName(1) == 'S')
               continue
            end
            monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
            paramNameList = get_param_name_list(monoProfInputFilePathName, 1);
            if (monoProfInputFileName(1) == 'B')
               if (any(strcmp(paramNameList, 'MTIME')))
                  % fprintf('ERROR: Float %d: ''MTIME'' present in file : %s\n', floatNum, monoProfInputFileName);
                  fprintf(fidOut, '%d;%s;%s;%s\n', ...
                     floatNum, 'B-PROF', monoProfInputFileName, '''MTIME'' present');
               end
            else
               if (~any(strcmp(paramNameList, 'MTIME')))
                  % fprintf('ERROR: Float %d: ''MTIME'' missing in file : %s\n', floatNum, monoProfInputFileName);
                  fprintf(fidOut, '%d;%s;%s;%s\n', ...
                     floatNum, 'C-PROF', monoProfInputFileName, '''MTIME'' missing');
               end
            end
         end
      else
         fprintf('INFO: Float %d: Directory not found: %s\n', floatNum, ncInputFileDir);
      end
   else
      fprintf('WARNING: Float %d: Directory not found: %s\n', floatNum, ncInputFileDir);
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve the list of parameters of a profile or a meta file
%
% SYNTAX :
% [o_paramList] = get_param_name_list(a_filePathName, a_profFileFlag)
%
% INPUT PARAMETERS :
%   a_filePathName : NetCDF file path name
%   a_profFileFlag : 1 if it is a profile file, 0 if it is a meta file
%
% OUTPUT PARAMETERS :
%   o_paramList : list of parameters
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramList] = get_param_name_list(a_filePathName, a_profFileFlag)

% output parameters initialization
o_paramList = [];

if (a_profFileFlag == 1) % in profile file

   wantedVars = [ ...
      {'STATION_PARAMETERS'} ...
      ];
   [ncData] = get_data_from_nc_file(a_filePathName, wantedVars);

   % create the list of parameters
   idVal = find(strcmp('STATION_PARAMETERS', ncData), 1);
   if (~isempty(idVal) && ~isempty(ncData{idVal+1}))
      stationParameters = ncData{idVal+1};
      [~, nParam, nProf] = size(stationParameters);
      ncParamNameList = [];
      for idProf = 1:nProf
         for idParam = 1:nParam
            paramName = deblank(stationParameters(:, idParam, idProf)');
            if (~isempty(paramName))
               ncParamNameList{end+1} = paramName;
            end
         end
      end
      ncParamNameList = unique(ncParamNameList);
      o_paramList = ncParamNameList;
   end

else % in meta file

   wantedVars = [ ...
      {'PARAMETER'} ...
      ];
   [ncData] = get_data_from_nc_file(a_filePathName, wantedVars);

   idVal = find(strcmp('PARAMETER', ncData), 1);
   if (~isempty(idVal) && ~isempty(ncData{idVal+1}))
      parameterMetaTmp = ncData{idVal+1}';
      ncParamNameList = [];
      for id = 1:size(parameterMetaTmp, 1)
         ncParamNameList{end+1} = deblank(parameterMetaTmp(id, :));
      end
      o_paramList = ncParamNameList;
   end
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
