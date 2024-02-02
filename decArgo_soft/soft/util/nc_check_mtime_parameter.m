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
DIR_INPUT_NC_FILES = 'G:\argo_snapshot_202309\';

% list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\float_with_mtime_20231016.txt';

% list of floats information
FLOAT_LIST_INFO_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\select_float_mtime.txt';

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
   floatListFileName = FLOAT_LIST_FILE_NAME;

   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end

   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
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
fprintf('   Float information file: FLOAT_LIST_INFO_FILE_NAME = ''%s''\n', FLOAT_LIST_INFO_FILE_NAME);
fprintf('   Log file directory    : DIR_LOG_FILE = ''%s''\n', DIR_LOG_FILE);
fprintf('   Csv file directory    : DIR_CSV_FILE = ''%s''\n', DIR_CSV_FILE);
fprintf('\n');

% retrieve float information
[floatTypeList, floatVersionList, floatWmoList] = get_floats_info(FLOAT_LIST_INFO_FILE_NAME);

outputFileName = [DIR_CSV_FILE '/' 'nc_check_mtime_parameter' name '_' currentTime '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('ERROR: Unable to create CSV output file: %s\n', outputFileName);
   return
end

fprintf(fidOut, 'DAC;WMO;FILE_TYPE;FILE_NAME;COMMENT;FLOAT_TYPE;FLOAT_VERSION\n');

% process the directories of DIR_INPUT_NC_FILES top dir
floatListOri = floatList;
floatDoneList = zeros(length(floatListOri), 1);
nbFloats = length(floatList);
dirNames1 = dir(DIR_INPUT_NC_FILES);
idFloat = 1;
for idDir1 = 1:length(dirNames1)

   dirName1 = dirNames1(idDir1).name;
   if (~ismember(dirName1, [{'bodc'} {'coriolis'} {'incois'}]))
      continue
   end
   dirPathName1 = [DIR_INPUT_NC_FILES '/' dirName1];

   dirNames2 = dir(dirPathName1);
   for idDir2 = 1:length(dirNames2)

      dirName2 = dirNames2(idDir2).name;
      if (strcmp(dirName2, '.') || strcmp(dirName2, '..'))
         continue
      end
      floatNum = str2double(dirName2);
      idF = find(floatList == floatNum, 1);
      if (~isempty(idF))

         fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
         idFloat = idFloat + 1;
         % if (idFloat == 100)
         %    break
         % end
         floatDoneList(floatListOri == floatNum) = 1;
         floatList(idF) = [];
         floatType = floatTypeList{floatWmoList == floatNum};
         floatVersion = floatVersionList{floatWmoList == floatNum};

         ncInputFileDir = [dirPathName1 '/' num2str(floatNum) '/'];

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
               fprintf(fidOut, '%s;%d;%s;%s;%s;%s;%s\n', ...
                  dirName1, floatNum, 'META', sprintf('%d_meta.nc', floatNum), '''MTIME'' missing', floatType, floatVersion);
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
                        fprintf(fidOut, '%s;%d;%s;%s;%s;%s;%s\n', ...
                           dirName1, floatNum, 'B-PROF', monoProfInputFileName, '''MTIME'' present', floatType, floatVersion);
                     end
                  else
                     if (~any(strcmp(paramNameList, 'MTIME')))
                        % fprintf('ERROR: Float %d: ''MTIME'' missing in file : %s\n', floatNum, monoProfInputFileName);
                        fprintf(fidOut, '%s;%d;%s;%s;%s;%s;%s\n', ...
                           dirName1, floatNum, 'C-PROF', monoProfInputFileName, '''MTIME'' missing', floatType, floatVersion);
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
   end
end

fclose(fidOut);

if (any(floatDoneList == 0))
   fprintf('List of not found floats (%d):\n', length(find(floatDoneList == 0)));
   notFloundList = sprintf('%d\n', floatListOri(floatDoneList == 0));
   fprintf('%s', notFloundList);
end

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
% Get floats information from floats information file.
%
% SYNTAX :
%  [o_listWmoNum, o_listDecId, o_listArgosId, o_listFrameLen, ...
%    o_listCycleTime, o_listDriftSamplingPeriod, o_listDelay, ...
%    o_listLaunchDate, o_listLaunchLon, o_listLaunchLat, ...
%    o_listRefDay, o_listEndDate, o_listDmFlag] = get_floats_info(a_floatInfoFileName)
%
% INPUT PARAMETERS :
%   a_floatInfoFileName : float information file name
%
% OUTPUT PARAMETERS :
%   o_listWmoNum          : floats WMO number
%   o_listDecId           : floats decoder Id
%   o_listArgosId         : floats PTT number
%   o_listFrameLen        : floats data frame length
%   o_listCycleTime       : floats cycle duration
%   o_driftSamplingPeriod : sampling period during drift phase (in hours)
%   o_listDelay           : DELAI parameter (in hours)
%   o_listLaunchDate      : floats launch date
%   o_listLaunchLon       : floats launch longitude
%   o_listLaunchLat       : floats launch latitude
%   o_listRefDay          : floats reference day (day of the first descent)
%   o_listEndDate         : floats end decoding date
%   o_listDmFlag          : floats DM flag
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatType, o_floatVersion, o_floatWmo] = get_floats_info(a_floatInfoFileName)

% output parameters initialization
o_floatType = [];
o_floatVersion = [];
o_floatWmo = [];

if ~(exist(a_floatInfoFileName, 'file') == 2)
   fprintf('ERROR: Float information file not found: %s\n', a_floatInfoFileName);
   return
end

fId = fopen(a_floatInfoFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Error while opening file : %s\n', a_floatInfoFileName);
end

data = textscan(fId, '%s %s %d');

o_floatType = data{1}(:);
o_floatVersion = data{2}(:);
o_floatWmo = data{3}(:);

fclose(fId);

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
