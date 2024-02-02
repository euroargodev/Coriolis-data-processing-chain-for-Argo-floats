% ------------------------------------------------------------------------------
% check consistency between config mission numbers assigned to TRAJ multi PROF
% and PROF files.
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
% DIR_INPUT_NC_FILES = 'D:\202211-ArgoData\coriolis\';

% default list of floats to convert (should be set to '' if we want to process
% all the floats of the DIR_INPUT_NC_FILES directory)
FLOAT_LIST_FILE_NAME = ''; % process all the floats of the DIR_INPUT_NC_FILES directory
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';

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
% fprintf('   Csv file directory: DIR_CSV_FILE = ''%s''\n', DIR_CSV_FILE);
fprintf('\n');

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];

   if (exist(ncInputFileDir, 'dir') == 7)

      configNumMeta = [];
      cyNumTraj = [];
      configNumTraj = [];
      cyNumMProf = [];
      configNumMProf = [];
      cyNumProf = [];
      configNumProf = [];
      vssProf = [];
      dmProf = [];
      cyNumProfB = [];
      configNumProfB = [];
      trajOk = 1;
      mProfOk = 1;
      profOk = 1;

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get configuration mission numbers from META.nc
      ncMetaFilePathName = [ncInputFileDir sprintf('%d_meta.nc', floatNum)];
      if ~(exist(ncMetaFilePathName, 'file') == 2)
         fprintf('ERROR: Float %d: meta file is missing - float ignored\n', floatNum);
         continue
      end
      [formatVersion, configNumMeta, ~, ~] = get_config_mission_number(ncMetaFilePathName);
      if (formatVersion ~= 3.1)
         fprintf('INFO: Float %d: meta file version is %g - float ignored\n', floatNum, formatVersion);
         continue
      end
      if (length(configNumMeta) ~= length(unique(configNumMeta)))
         fprintf('WARNING: Float %d: META: duplicates in config numbers\n', floatNum);
      end
      configNumMeta = unique(configNumMeta);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get configuration mission numbers from TRAJ.nc
      ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Rtraj.nc', floatNum)];
      if ~(exist(ncTrajInputFilePathName, 'file') == 2)
         ncTrajInputFilePathName = [ncInputFileDir sprintf('%d_Dtraj.nc', floatNum)];
         if ~(exist(ncTrajInputFilePathName, 'file') == 2)
            fprintf('INFO: Float %d: traj file is missing\n', floatNum);
            ncTrajInputFilePathName = '';
         end
      end
      if (~isempty(ncTrajInputFilePathName))
         [formatVersion, configNumTraj, ~, cyNumTraj] = get_config_mission_number(ncTrajInputFilePathName);
         if ((formatVersion ~= 3.1) && (formatVersion ~= 3.2))
            fprintf('INFO: Float %d: traj file version is %g\n', floatNum, formatVersion);
            cyNumTraj = [];
            configNumTraj = [];
            trajOk = 0;
         else
            if (length(cyNumTraj) ~= length(unique(cyNumTraj)))
               fprintf('ERROR: Float %d: TRAJ: duplicates in config numbers\n', floatNum);
            end
            if (any(cyNumTraj == -1))
               if (any(configNumTraj(cyNumTraj == -1) ~= 99999))
                  fprintf('ERROR: Float %d: TRAJ: no config number should be associated to launch event (cyce #-1)\n', floatNum);
               end
               configNumTraj(cyNumTraj == -1) = [];
               cyNumTraj(cyNumTraj == -1) = [];
            end
            if (any((cyNumTraj < -1) | (cyNumTraj == 99999)))
               fprintf('ERROR: Float %d: TRAJ: inconsistent cycle number(s)\n', floatNum);
            end
         end
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % get configuration mission numbers from multi PROF.nc
      multiProfInputFilePathName = [ncInputFileDir sprintf('%d_prof.nc', floatNum)];
      [formatVersion, configNumMProf, cyNumMProf, ~] = get_config_mission_number(multiProfInputFilePathName);
      if (formatVersion ~= 3.1)
         fprintf('INFO: Float %d: M-PROF file version is %g\n', floatNum, formatVersion);
         cyNumMProf = [];
         configNumMProf = [];
         mProfOk = 0;
      else
         if (any(configNumMProf == 99999))
            fprintf('ERROR: Float %d: M-PROF: cycle(s) with no config number\n', floatNum);
         end
         if (any((cyNumMProf < 0) | (cyNumMProf == 99999))) % cycle #0 exists in some old files
            fprintf('ERROR: Float %d: M-PROF: inconsistent cycle number(s)\n', floatNum);
         end
         uCyNumList = unique(cyNumMProf);
         for idCy = 1:length(uCyNumList)
            if (length(unique(configNumMProf(cyNumMProf == uCyNumList(idCy)))) > 1)
               fprintf('ERROR: Float %d: Cycle %d: M-PROF: inconsistent config number\n', floatNum, uCyNumList(idCy));
            end
         end
      end

      % get configuration mission numbers from PROF.nc
      ncInputFileDir = [ncInputFileDir '/profiles/'];
      if (exist(ncInputFileDir, 'dir') == 7)

         ncInputFiles = dir([ncInputFileDir '*.nc']);
         for idFile = 1:length(ncInputFiles)

            monoProfInputFileName = ncInputFiles(idFile).name;
            if (monoProfInputFileName(1) == 'S')
               continue
            end
            monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
            [formatVersion, configNumP, cyNumP, ~, vssP] = get_config_mission_number(monoProfInputFilePathName);
            if (formatVersion ~= 3.1)
               fprintf('INFO: Float %d: PROF file version is %g\n', floatNum, formatVersion);
               profOk = 0;
            else
               if (monoProfInputFileName(1) == 'B')
                  configNumProfB = [configNumProfB; configNumP];
                  cyNumProfB = [cyNumProfB; cyNumP];
               else
                  configNumProf = [configNumProf; configNumP];
                  cyNumProf = [cyNumProf; cyNumP];
                  vssProf = [vssProf; vssP];
                  if (monoProfInputFileName(1) == 'R')
                     dmProf = [dmProf; zeros(size(configNumP))];
                  else
                     dmProf = [dmProf; ones(size(configNumP))];
                  end
               end
            end
         end
         if (any(configNumProfB == 99999))
            fprintf('ERROR: Float %d: PROF B: cycle(s) with no config number\n', floatNum);
         end
         if (any((cyNumProfB < 0) | (cyNumProfB == 99999))) % cycle #0 exists in some old files
            fprintf('ERROR: Float %d: PROF B: inconsistent cycle numbers\n', floatNum);
         end
         uCyNumList = unique(cyNumProfB);
         for idCy = 1:length(uCyNumList)
            if (length(unique(configNumProfB(cyNumProfB == uCyNumList(idCy)))) > 1)
               fprintf('ERROR: Float %d: Cycle %d: PROF B: inconsistent config number\n', floatNum, uCyNumList(idCy));
            end
         end
         if (any(configNumProf == 99999))
            configKoList = find(configNumProf == 99999);
            idDel = [];
            for idC = 1:length(configKoList)
               if (~isempty(strtrim(unique(vssProf(configKoList(idC), :)))))
                  fprintf('ERROR: Float %d: Cycle %d: PROF: cycle with no config number\n', floatNum, cyNumProf(configKoList(idC)));
               else
                  idDel = [idDel; configKoList(idC)];
               end
            end
            configNumProf(idDel) = [];
            cyNumProf(idDel) = [];
            vssProf(idDel, :) = [];
            dmProf(idDel) = [];
         end
         if (any((cyNumProf < 0) | (cyNumProf == 99999))) % cycle #0 exists in some old files
            fprintf('ERROR: Float %d: PROF: inconsistent cycle numbers\n', floatNum);
         end
         uCyNumList = unique(cyNumProf);
         for idCy = 1:length(uCyNumList)
            if (length(unique(configNumProf(cyNumProf == uCyNumList(idCy)))) > 1)
               fprintf('ERROR: Float %d: Cycle %d: PROF: inconsistent config number\n', floatNum, uCyNumList(idCy));
            end
         end
         for idCy = 1:length(uCyNumList)
            if (any(cyNumProfB == uCyNumList(idCy)))
               if (unique(configNumProf(cyNumProf == uCyNumList(idCy))) ~= unique(configNumProfB(cyNumProfB == uCyNumList(idCy))))
                  fprintf('ERROR: Float %d: Cycle %d: PROF C & B: inconsistent config number\n', floatNum, uCyNumList(idCy));
               end
            end
         end
      else
         fprintf('INFO: Float %d: Directory not found: %s\n', floatNum, ncInputFileDir);
      end
   else
      fprintf('WARNING: Float %d: Directory not found: %s\n', floatNum, ncInputFileDir);
   end

   if (any([trajOk, mProfOk, profOk] == 0))
      fprintf('INFO: Float %d: no cross check done\n', floatNum);
      continue
   end

   if (isempty(configNumTraj) && isempty(configNumMProf) && isempty(configNumProf))
      continue
   end

   % no config numbers are missing in META file
   allUsedConfig = [];
   if (~isempty(configNumTraj) && ~isempty(configNumMProf) && ~isempty(configNumProf))
      allUsedConfig = unique([configNumTraj; configNumMProf; configNumProf]);
   elseif (~isempty(configNumTraj) && ~isempty(configNumMProf))
      allUsedConfig = unique([configNumTraj; configNumMProf]);
   elseif (~isempty(configNumTraj))
      allUsedConfig = unique([configNumTraj]);
   elseif (~isempty(configNumMProf) && ~isempty(configNumProf))
      allUsedConfig = unique([configNumMProf; configNumProf]);
   elseif (~isempty(configNumProf))
      allUsedConfig = unique([configNumProf]);
   elseif (~isempty(configNumTraj) && ~isempty(configNumProf))
      allUsedConfig = unique([configNumTraj; configNumProf]);
   end
   if (~isempty(allUsedConfig))
      allUsedConfig(allUsedConfig == 99999) = [];
      missingConfigNum = setdiff(allUsedConfig, configNumMeta);
      if (~isempty(missingConfigNum))
         confListStr = sprintf('%d, ', missingConfigNum);
         fprintf('ERROR: Float %d: missing configurations (%s)\n', floatNum, confListStr(1:end-2));
      end
      unusedConfigNum = setdiff(configNumMeta, allUsedConfig);
      if (~isempty(unusedConfigNum))
         confListStr = sprintf('%d, ', unusedConfigNum);
         fprintf('INFO: Float %d: unused configurations (%s)\n', floatNum, confListStr(1:end-2));
      end
   end

   % TRAJ and PROF config are consistent
   if (~isempty(configNumTraj) && ~isempty(configNumProf))
      if (any(cyNumTraj == 0) && ~any(cyNumProf == 0))
         if (any(configNumTraj(cyNumTraj == 0) == 99999))
            configNumTraj(cyNumTraj == 0) = [];
            cyNumTraj(cyNumTraj == 0) = [];
         end
      end
      if (any(configNumTraj == 99999))
         configKoList = find(configNumTraj == 99999);
         for idC = 1:length(configKoList)
            trajCyNum = cyNumTraj(configKoList(idC));
            if (any(cyNumProf == trajCyNum))
               fprintf('ERROR: Float %d: Cycle %d: TRAJ: cycle with no config number\n', floatNum, trajCyNum);
            end
         end
      end

      trajInfo = [cyNumTraj configNumTraj];
      trajInfo = unique(trajInfo, 'rows');
      profInfo = [cyNumProf configNumProf dmProf];
      profInfo = unique(profInfo, 'rows');
      missingCyNum = setdiff(profInfo(:, 1), trajInfo(:, 1));
      if (~isempty(missingCyNum))
         confListStr = sprintf('%d, ', missingCyNum);
         fprintf('ERROR: Float %d: PROF cycles missing in TRAJ (%s)\n', floatNum, confListStr(1:end-2));
      end
      for idP = 1:size(profInfo, 1)
         if (profInfo(idP, 2) ~= trajInfo(trajInfo(:, 1) == profInfo(idP, 1), 2))
            if (profInfo(idP, 3) == 1)
               fprintf('ERROR: Float %d: Cycle %d: PROF and TRAJ config differ - DM PROF file\n', floatNum, profInfo(idP, 1));
            else
               fprintf('ERROR: Float %d: Cycle %d: PROF and TRAJ config differ\n', floatNum, profInfo(idP, 1));
            end
         end
      end
   elseif (~isempty(configNumTraj))
      if (any(cyNumTraj == 0))
         if (any(configNumTraj(cyNumTraj == 0) == 99999))
            configNumTraj(cyNumTraj == 0) = [];
            cyNumTraj(cyNumTraj == 0) = [];
         end
      end
      if (any(configNumTraj == 99999))
         fprintf('ERROR: Float %d: TRAJ: cycle(s) with no config number\n', floatNum);
      end
   end

   % PROF and M-PROF config are consistent
   if (~isempty(configNumMProf) && ~isempty(configNumProf))
      profInfo = [cyNumProf configNumProf];
      profInfo = unique(profInfo, 'rows');
      mProfInfo = [cyNumMProf configNumMProf];
      mProfInfo = unique(mProfInfo, 'rows');
      missingCyNum = setdiff(mProfInfo(:, 1), profInfo(:, 1));
      if (~isempty(missingCyNum))
         confListStr = sprintf('%d, ', missingCyNum);
         fprintf('ERROR: Float %d: M-PROF cycles missing in PROF (%s)\n', floatNum, confListStr(1:end-2));
      end
      for idP = 1:size(mProfInfo, 1)
         if (mProfInfo(idP, 2) ~= profInfo(profInfo(:, 1) == mProfInfo(idP, 1), 2))
            fprintf('ERROR: Float %d: Cycle %d: M-PROF and PROF config differ\n', floatNum, mProfInfo(idP, 1));
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve the list of configuration mission numbers and associted cycle numbers
% (CONFIG_MISSION_NUMBER, CYCLE_NUMBER, CYCLE_NUMBER_INDEX) from NetCDF file.
%
% SYNTAX :
%  [o_formatVersion, o_confNumList] = get_config_mission_number(a_filePathName)
%
% INPUT PARAMETERS :
%   a_filePathName : NetCDF file path name
%
% OUTPUT PARAMETERS :
%   o_formatVersion  : version number of the file format
%   o_confNumList    : list of configuration mission numbers
%   o_cyNumList      : list of cycle numbers (N_PROF)
%   o_cyNumIndexList : list of cycle numbers (N_CYCLE)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/23/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_formatVersion, o_confNumList, o_cyNumList, o_cyNumIndexList, o_vssList] = ...
   get_config_mission_number(a_filePathName)

% output parameters initialization
o_formatVersion = '';
o_confNumList = [];
o_cyNumList = [];
o_cyNumIndexList = [];
o_vssList = [];


wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   {'CYCLE_NUMBER'} ...
   {'CYCLE_NUMBER_INDEX'} ...
   {'VERTICAL_SAMPLING_SCHEME'} ...
   ];
[ncData] = get_data_from_nc_file(a_filePathName, wantedVars);

idVal = find(strcmp('FORMAT_VERSION', ncData), 1);
if (~isempty(idVal))
   o_formatVersion = str2double(ncData{idVal+1}');
end
idVal = find(strcmp('CONFIG_MISSION_NUMBER', ncData), 1);
if (~isempty(idVal))
   o_confNumList = ncData{idVal+1};
end
idVal = find(strcmp('CYCLE_NUMBER', ncData), 1);
if (~isempty(idVal) && ~isempty(ncData{idVal+1}))
   o_cyNumList = ncData{idVal+1};
end
idVal = find(strcmp('CYCLE_NUMBER_INDEX', ncData), 1);
if (~isempty(idVal) && ~isempty(ncData{idVal+1}))
   o_cyNumIndexList = ncData{idVal+1};
end
idVal = find(strcmp('VERTICAL_SAMPLING_SCHEME', ncData), 1);
if (~isempty(idVal) && ~isempty(ncData{idVal+1}))
   o_vssList = ncData{idVal+1}';
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
