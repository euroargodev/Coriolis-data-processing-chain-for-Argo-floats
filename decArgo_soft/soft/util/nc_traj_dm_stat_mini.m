% ------------------------------------------------------------------------------
% Collect information on MC and associated param of a TRAF file.
%
% SYNTAX :
%   nc_traj_dm_stat_mini(6902899)
%
% INPUT PARAMETERS :
%   varargin : WMO number of float to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/01/2024 - RNU - creation
% ------------------------------------------------------------------------------
function nc_traj_dm_stat_mini(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START

% default list of floats to process
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ANDRO_2_TRAJ-DM\Decomptes_20240621\arvor_in_andro.txt';

% top directory of the input TRAJ NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TRAJ_DM_2024\snapshot-202405_arvor_ir_in_andro_325\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% measurement codes initialization
init_measurement_codes;

% default values initialization
init_default_values;


% check inputs
if (nargin == 0)
   if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', FLOAT_LIST_FILE_NAME);
      return
   end
end
if ~(exist(DIR_INPUT_NC_FILES, 'dir') == 7)
   fprintf('ERROR: Directory not found: %s\n', DIR_INPUT_NC_FILES);
   return
end

% get floats to process
if (nargin == 0)
   % floats to process come from default list
   fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
   floatList = load(FLOAT_LIST_FILE_NAME);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [~, name, ~] = fileparts(FLOAT_LIST_FILE_NAME);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% create log directory
if ~(exist(DIR_LOG_FILE, 'dir') == 7)
   mkdir(DIR_LOG_FILE);
end

logFile = [DIR_LOG_FILE '/' 'nc_traj_dm_stat_mini' name '_' currentTime '.log'];
diary(logFile);
tic;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process floats of the list

juldInfo = get_netcdf_param_attributes('JULD');
presInfo = get_netcdf_param_attributes('PRES');
tempInfo = get_netcdf_param_attributes('TEMP');
psalInfo = get_netcdf_param_attributes('PSAL');

resTab = [];
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   % if (floatNum == 6901821)
   %    a=1
   % end
   floatNumStr = num2str(floatNum);
   inputFloatDir = [DIR_INPUT_NC_FILES '/' floatNumStr '/'];
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   trajFile = dir([inputFloatDir sprintf('%d_Rtraj.nc', floatNum)]);
   if (isempty(trajFile))
      fprintf('INFO: No trajectory file for float %d - ignored\n', ...
         floatNum);
      continue
   end
   trajFileName = trajFile(1).name;
   trajFilePathName = [inputFloatDir trajFileName];

   wantedVars = [ ...
      {'MEASUREMENT_CODE'} ...
      {'JULD'} ...
      {'PRES'} ...
      {'TEMP'} ...
      {'PSAL'} ...
      ];

   ncTrajData = get_data_from_nc_file(trajFilePathName, wantedVars);

   measurementCode = get_data_from_name('MEASUREMENT_CODE', ncTrajData);
   juldData = get_data_from_name('JULD', ncTrajData);
   presData = get_data_from_name('PRES', ncTrajData);
   tempData = get_data_from_name('TEMP', ncTrajData);
   psalData = get_data_from_name('PSAL', ncTrajData);

   mcList = unique(measurementCode);
   for measCode = mcList'
      % if (measCode == 800)
      %    a=1
      % end
      paramStr = [];
      idForMc = find(measurementCode == measCode);
      if (any(juldData(idForMc) ~= juldInfo.fillValue))
         paramStr = [paramStr 'J '];
      end
      if (any(presData(idForMc) ~= presInfo.fillValue))
         paramStr = [paramStr 'P '];
      end
      if (any(tempData(idForMc) ~= tempInfo.fillValue))
         paramStr = [paramStr 'T '];
      end
      if (any(psalData(idForMc) ~= psalInfo.fillValue))
         paramStr = [paramStr 'S '];
      end
      if (isempty(paramStr))
         continue
      end
      resNew = [measCode {paramStr}];
      found = 0;
      if (~isempty(resTab) && any([resTab{:, 1}] == measCode))
         idF = find([resTab{:, 1}] == measCode);
         for id = idF
            if ((length(resTab{id, 2}) == length(paramStr)) && ...
                  (strcmp(resTab{id, 2}, paramStr)))
               found = 1;
               break
            end
         end
      end
      if (~found)
         resTab = [resTab; resNew];
      end
   end
end

[~, idSort] = sort([resTab{:, 1}]);
resTab = resTab(idSort, :);
for id = 1:length(resTab)
   fprintf('%s : %s\n', get_meas_code_name(resTab{id, 1}), resTab{id, 2});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
