% ------------------------------------------------------------------------------
% Find APEX specific mission where both spot sampling mode and continuous
% profile mode are active.
%
% SYNTAX :
%   nc_find_apf11_specific_config_mission or
%   nc_find_apf11_specific_config_mission(6900189, 7900118)
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
%   12/16/2022 - RNU - creation
% ------------------------------------------------------------------------------
function nc_find_apf11_specific_config_mission(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
DIR_INPUT_NC_FILES = 'D:\202211-ArgoData\coriolis\';

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

logFile = [DIR_LOG_FILE '/' 'nc_find_apf11_specific_config_mission' name '_' currentTime '.log'];
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
         {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_PARAMETER_NAME'} ...
         {'CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_MISSION_NUMBER'} ...
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
      idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', metaData(1:2:end)), 1);
      launchConfigParamValue = metaData{2*idVal};
      idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData(1:2:end)), 1);
      configParamName = cellstr(metaData{2*idVal}');
      idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData(1:2:end)), 1);
      configParamValue = metaData{2*idVal};
      idVal = find(strcmp('CONFIG_MISSION_NUMBER', metaData(1:2:end)), 1);
      configMissionNum = metaData{2*idVal};
      nbConfig = length(configMissionNum);

      if (any(strcmp(launchConfigParamName, 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER')) && ...
            any(strcmp(launchConfigParamName, 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER')))

         % get number of depth zones in continuous mode
         nbDepthZoneCp = 0;
         idL = find(strcmp(launchConfigParamName, 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER'));
         if (length(idL) > 1)
            fprintf('ERROR: Multiple (%d) ''%s'' config label in launch configuration\n', ...
               length(idL), 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER');
            idL = idL(1);
         end
         if (launchConfigParamValue(idL) ~= 99999)
            nbDepthZoneCp = launchConfigParamValue(idL);
         end
         idL = find(strcmp(configParamName, 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER'));
         if (~isempty(idL))
            if (length(idL) > 1)
               fprintf('ERROR: Multiple (%d) ''%s'' config label in configuration\n', ...
                  length(idL), 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER');
               idL = idL(1);
            end
            nbDepthZoneCpList = configParamValue(idL, :);
            nbDepthZoneCpList(nbDepthZoneCpList == 99999) = [];
            if (~isempty(nbDepthZoneCpList))
               nbDepthZoneCp = max(nbDepthZoneCp, max(nbDepthZoneCpList));
            end
         end

         % get number of depth zones in spot mode
         nbDepthZone = 0;
         idL = find(strcmp(launchConfigParamName, 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER'));
         if (length(idL) > 1)
            fprintf('ERROR: Multiple (%d) ''%s'' config label in launch configuration\n', ...
               length(idL), 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER');
            idL = idL(1);
         end
         if (launchConfigParamValue(idL) ~= 99999)
            nbDepthZone = launchConfigParamValue(idL);
         end
         idL = find(strcmp(configParamName, 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER'));
         if (~isempty(idL))
            if (length(idL) > 1)
               fprintf('ERROR: Multiple (%d) ''%s'' config label in configuration\n', ...
                  length(idL), 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER');
               idL = idL(1);
            end
            nbDepthZoneList = configParamValue(idL, :);
            nbDepthZoneList(nbDepthZoneList == 99999) = [];
            if (~isempty(nbDepthZoneList))
               nbDepthZone = max(nbDepthZoneCp, max(nbDepthZoneList));
            end
         end

         startPresCp = nan(nbConfig, nbDepthZoneCp);
         stopPresCp = nan(nbConfig, nbDepthZoneCp);
         startPres = nan(nbConfig, nbDepthZone);
         stopPres = nan(nbConfig, nbDepthZone);

         if (any(strcmp(configParamName, 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER')))

            idL = find(strcmp(configParamName, 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER'));
            idL = idL(1);
            nbDepthZoneCpList = configParamValue(idL, :);
            for idC = 1:nbConfig
               if (nbDepthZoneCpList(idC) ~= 99999)
                  nbDepthZoneCp = nbDepthZoneCpList(idC);
                  for dzNum = 1:nbDepthZoneCp
                     idL1 = find(strcmp(configParamName, ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']));
                     if (length(idL1) > 1)
                        fprintf('ERROR: Multiple (%d) ''%s'' config label in configuration\n', ...
                           length(idL1), ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']);
                        idL1 = idL1(1);
                     end
                     value = configParamValue(idL1, idC);
                     if (value ~= 99999)
                        startPresCp(idC, dzNum) = value;
                     end
                     idL2 = find(strcmp(configParamName, ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']));
                     if (length(idL2) > 1)
                        fprintf('ERROR: Multiple (%d) ''%s'' config label in configuration\n', ...
                           length(idL2), ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']);
                        idL2 = idL2(1);
                     end
                     value = configParamValue(idL2, idC);
                     if (value ~= 99999)
                        stopPresCp(idC, dzNum) = value;
                     end
                  end
               end
            end
         else

            idL = find(strcmp(launchConfigParamName, 'CONFIG_CtdCpAscentPhaseNumberOfDepthZone_NUMBER'));
            idL = idL(1);
            value = launchConfigParamValue(idL);
            if (value ~= 99999)
               nbDepthZoneCp = value;
               for dzNum = 1:nbDepthZoneCp
                  idL1 = find(strcmp(launchConfigParamName, ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']));
                  if (length(idL1) > 1)
                     fprintf('ERROR: Multiple (%d) ''%s'' config label in launch configuration\n', ...
                        length(idL1), ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']);
                     idL1 = idL1(1);
                  end
                  value = launchConfigParamValue(idL1);
                  if (value ~= 99999)
                     startPresCp(1, dzNum) = value;
                  end
                  idL2 = find(strcmp(launchConfigParamName, ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']));
                  if (length(idL2) > 1)
                     fprintf('ERROR: Multiple (%d) ''%s'' config label in launch configuration\n', ...
                        length(idL2), ['CONFIG_CtdCpAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']);
                     idL2 = idL2(1);
                  end
                  value = launchConfigParamValue(idL2);
                  if (value ~= 99999)
                     stopPresCp(1, dzNum) = value;
                  end
               end
            end
         end

         if (any(strcmp(configParamName, 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER')))

            idL = find(strcmp(configParamName, 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER'));
            idL = idL(1);
            nbDepthZoneList = configParamValue(idL, :);
            for idC = 1:nbConfig
               if (nbDepthZoneList(idC) ~= 99999)
                  nbDepthZone = nbDepthZoneList(idC);
                  for dzNum = 1:nbDepthZone
                     idL1 = find(strcmp(configParamName, ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']));
                     if (length(idL1) > 1)
                        fprintf('ERROR: Multiple (%d) ''%s'' config label in configuration\n', ...
                           length(idL1), ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']);
                        idL1 = idL1(1);
                     end
                     value = configParamValue(idL1, idC);
                     if (value ~= 99999)
                        startPres(idC, dzNum) = value;
                     end
                     idL2 = find(strcmp(configParamName, ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']));
                     if (length(idL2) > 1)
                        fprintf('ERROR: Multiple (%d) ''%s'' config label in configuration\n', ...
                           length(idL2), ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']);
                        idL2 = idL2(1);
                     end
                     value = configParamValue(idL2, idC);
                     if (value ~= 99999)
                        stopPres(idC, dzNum) = value;
                     end
                  end
               end
            end
         else

            idL = find(strcmp(launchConfigParamName, 'CONFIG_CtdAscentPhaseNumberOfDepthZone_NUMBER'));
            idL = idL(1);
            value = launchConfigParamValue(idL);
            if (value ~= 99999)
               nbDepthZone = value;
               for dzNum = 1:nbDepthZone
                  idL1 = find(strcmp(launchConfigParamName, ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']));
                  if (length(idL1) > 1)
                     fprintf('ERROR: Multiple (%d) ''%s'' config label in launch configuration\n', ...
                        length(idL1), ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StartPres_dbar']);
                     idL1 = idL1(1);
                  end
                  value = launchConfigParamValue(idL1);
                  if (value ~= 99999)
                     startPres(1, dzNum) = value;
                  end
                  idL2 = find(strcmp(launchConfigParamName, ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']));
                  if (length(idL2) > 1)
                     fprintf('ERROR: Multiple (%d) ''%s'' config label in launch configuration\n', ...
                        length(idL2), ['CONFIG_CtdAscentPhaseDepthZone' num2str(dzNum) 'StopPres_dbar']);
                     idL2 = idL2(1);
                  end
                  value = launchConfigParamValue(idL2);
                  if (value ~= 99999)
                     stopPres(1, dzNum) = value;
                  end
               end
            end
         end

         fprintf('Float %d\n', floatNum);
         for idC = 1:nbConfig
            startPresCpList = startPresCp(idC, :);
            startPresCpList(isnan(startPresCpList)) = [];
            startPresCpVal = max(startPresCpList);
            stopPresCpList = stopPresCp(idC, :);
            stopPresCpList(isnan(stopPresCpList)) = [];
            stopPresCpVal = min(stopPresCpList);
            startPresList = startPres(idC, :);
            startPresList(isnan(startPresList)) = [];
            startPresVal = max(startPresList);
            stopPresList = stopPres(idC, :);
            stopPresList(isnan(stopPresList)) = [];
            stopPresVal = min(stopPresList);

            if (~isempty(startPresCpVal) && ~isempty(stopPresCpVal) && ...
                  ~isempty(startPresVal) &&~isempty(stopPresVal))
               fprintf('Config %d: continuous profile mode %d-%d spot sampling mode %d-%d\n', ...
                  idC, startPresCpVal, stopPresCpVal, startPresVal, stopPresVal);
            end
         end
      end
   else
      fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

% fclose(fidOut);

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
