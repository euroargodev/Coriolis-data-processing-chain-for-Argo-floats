% ------------------------------------------------------------------------------
% Check cycle time and profile depth of converted (to 3.1) files.
% The check is performed on data which are compared to meta data.
% This check is used to control that a correct config mission number is
% assigned to each profile.
%
% SYNTAX :
%   nc_check_converted_apx_mono_profile_argos ou nc_check_converted_apx_mono_profile_argos(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : éventuellement la liste des numéros de flotteurs à traiter
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_check_converted_apx_mono_profile_argos(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default list of floats to process
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\tmp.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_pts_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_bgc_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_11.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_4_multi.txt';
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
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_all.txt';

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

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_check_converted_apx_mono_profile_argos' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

paramJuld = get_netcdf_param_attributes_3_1('JULD');
paramLat = get_netcdf_param_attributes_3_1('LATITUDE');
paramLon = get_netcdf_param_attributes_3_1('LONGITUDE');
paramPres = get_netcdf_param_attributes_3_1('PRES');

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   profPresMeta = [];
   cycleTimeMeta = [];
   confNum = [];
   tabCyNum = [];
   tabJuldLoc = [];
   tabLon = [];
   tabLat = [];
   tabJuld = [];
   tabDir = [];
   tabMisNum = [];
   tabPresMax = [];
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve information from NetCDF V3.1 meta-data file
   metaDataFilePathName = [DIR_INPUT_NC_FILES sprintf('/%d/%d_meta.nc', floatNum, floatNum)];
   if (exist(metaDataFilePathName, 'file') == 2)
      
      wantedInputVars = [ ...
         {'FORMAT_VERSION'} ...
         {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
         {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_PARAMETER_NAME'} ...
         {'CONFIG_PARAMETER_VALUE'} ...
         {'CONFIG_MISSION_NUMBER'} ...
         ];
      [metaData] = get_data_from_nc_file(metaDataFilePathName, wantedInputVars);
      
      idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
      formatVersion = strtrim(metaData{2*idVal}');
      if (~strcmp(formatVersion, '3.1'))
         fprintf('\n');
         fprintf('ERROR: Float #%d: Bad meta-data file format version (%s)\n', ...
            floatNum, formatVersion);
         continue
      end
      
      idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
      launchConfigParameterName = cellstr(metaData{2*idVal}');
      idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', metaData(1:2:end)) == 1, 1);
      launchConfigParameterValue = metaData{2*idVal};
      idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
      configParameterName = cellstr(metaData{2*idVal}');
      idVal = find(strcmp('CONFIG_PARAMETER_VALUE', metaData(1:2:end)) == 1, 1);
      configParameterValue = metaData{2*idVal};
      idVal = find(strcmp('CONFIG_MISSION_NUMBER', metaData(1:2:end)) == 1, 1);
      confNum = metaData{2*idVal}';
      
      idFl = find(strcmp('CONFIG_ProfilePressure_dbar', configParameterName) == 1);
      if (~isempty(idFl))
         profPresMeta = configParameterValue(idFl, :);
      else
         idFl = find(strcmp('CONFIG_ProfilePressure_dbar', launchConfigParameterName) == 1);
         if (~isempty(idFl))
            profPresMeta = launchConfigParameterValue(idFl);
            profPresMeta = repmat(profPresMeta, size(confNum));
         else
            fprintf('ERROR: Float #%d: ''CONFIG_ProfilePressure_dbar'' not in meta.nc\n', ...
               floatNum);
         end
      end
      idFl = find(strcmp('CONFIG_CycleTime_hours', configParameterName) == 1);
      if (~isempty(idFl))
         if (size(configParameterValue, 2) < 4)
            cycleTimeMeta = min(configParameterValue(idFl, :));
         else
            % seasonal floats
            cycleTimeMeta = configParameterValue(idFl, :);
         end
      else
         fprintf('ERROR: Float #%d: ''CONFIG_CycleTime_hours'' not in meta.nc\n', ...
            floatNum);
      end
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve information from NetCDF V3.1 mono-profile file
   monoProfDirName = [DIR_INPUT_NC_FILES sprintf('/%d/profiles/', floatNum)];
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', floatNum)];
   monoProfFiles = dir(monoProfFileName);
   for idFile = 1:length(monoProfFiles)
      
      fileName = monoProfFiles(idFile).name;
      if (fileName(1) == 'B')
         continue
      end
      profFileName = [monoProfDirName fileName];
      
      %       fprintf('\nFile: %s', fileName);
      
      % retrieve information from PROF file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'JULD_LOCATION'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'JULD'} ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'CONFIG_MISSION_NUMBER'} ...
         {'PRES'} ...
         {'PRES_QC'} ...
         ];
      [profData] = get_data_from_nc_file(profFileName, wantedVars);
      
      idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
      formatVersion = strtrim(profData{2*idVal}');
      if (~strcmp(formatVersion, '3.1'))
         fprintf('\n');
         fprintf('ERROR: Float #%d: Bad mono-profile file format version (%s)\n', ...
            floatNum, formatVersion);
         continue
      end
      
      idVal = find(strcmp('JULD_LOCATION', profData(1:2:end)) == 1, 1);
      juldLocation = profData{2*idVal};
      idVal = find(strcmp('LATITUDE', profData(1:2:end)) == 1, 1);
      latitude = profData{2*idVal};
      idVal = find(strcmp('LONGITUDE', profData(1:2:end)) == 1, 1);
      longitude = profData{2*idVal};
      idVal = find(strcmp('JULD', profData(1:2:end)) == 1, 1);
      juld = profData{2*idVal};
      idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
      cycleNumber = profData{2*idVal};
      idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
      direction = profData{2*idVal};
      idVal = find(strcmp('CONFIG_MISSION_NUMBER', profData(1:2:end)) == 1, 1);
      configMissionNumber = profData{2*idVal};
      idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
      pres = profData{2*idVal};
      idVal = find(strcmp('PRES_QC', profData(1:2:end)) == 1, 1);
      presQc = profData{2*idVal};
      
      tabCyNum = [tabCyNum; cycleNumber];
      tabJuldLoc = [tabJuldLoc; juldLocation];
      tabLon = [tabLon; longitude];
      tabLat = [tabLat; latitude];
      tabJuld = [tabJuld; juld];
      tabDir = [tabDir; direction];
      tabMisNum = [tabMisNum; configMissionNumber];
      idPresOk = find((pres ~= paramPres.fillValue) & (presQc ~= '4'));
      if (~isempty(idPresOk))
         tabPresMax = [tabPresMax; max(pres(idPresOk))];
      else
         tabPresMax = [tabPresMax; paramPres.fillValue];
      end
   end
   
   if (~isempty(profPresMeta) && ~isempty(tabPresMax))
      profPresExp = nan(size(tabPresMax));
      for idConf = 1:length(confNum)
         idF = find(tabMisNum == confNum(idConf));
         profPresExp(idF) = profPresMeta(idConf);
      end
      for idCy = 1:length(tabCyNum)
         if (tabPresMax(idCy) ~= paramPres.fillValue)
            if (abs(profPresExp(idCy)-tabPresMax(idCy))/profPresExp(idCy) > 0.25)
               fprintf('WARNING: Float #%d Cycle #%d: %.1f dbar (%d dbar) - > 25 %%\n', ...
                  floatNum, tabCyNum(idCy), tabPresMax(idCy), profPresExp(idCy));
            else
               fprintf('INFO: Float #%d Cycle #%d: %.1f dbar (%d dbar)\n', ...
                  floatNum, tabCyNum(idCy), tabPresMax(idCy), profPresExp(idCy));
            end
         end
      end
      fprintf('\n');
   end
   
   if (~isempty(tabCyNum))
      tabSort = tabCyNum;
      tabDirNum = zeros(size(tabDir));
      tabDirNum(find(tabDir == 'A')) = 1;
      tabSort = double(tabSort) + tabDirNum/10;
      [~, idSort] = sort(tabSort);
      tabCyNum = tabCyNum(idSort);
      tabJuldLoc = tabJuldLoc(idSort);
      tabLon = tabLon(idSort);
      tabLat = tabLat(idSort);
      tabJuld = tabJuld(idSort);
      for idCy = 1:length(tabCyNum)-1
         if ((tabJuldLoc(idCy) ~= paramJuld.fillValue) && ...
               (tabJuldLoc(idCy+1) ~= paramJuld.fillValue))
            if (tabJuldLoc(idCy) > tabJuldLoc(idCy+1))
               fprintf('ERROR: Float #%d Cycle #%d -> #%d: JULD_LOC=%s -> JULD_LOC=%s\n', ...
                  floatNum, tabCyNum(idCy:idCy+1), ...
                  julian_2_gregorian_dec_argo(tabJuldLoc(idCy)), ...
                  julian_2_gregorian_dec_argo(tabJuldLoc(idCy+1)));
            end
         end
         if ((tabJuld(idCy) ~= paramJuld.fillValue) && ...
               (tabJuld(idCy+1) ~= paramJuld.fillValue))
            if (tabJuld(idCy) > tabJuld(idCy+1))
               fprintf('ERROR: Float #%d Cycle #%d -> #%d: JULD=%s -> JULD=%s\n', ...
                  floatNum, tabCyNum(idCy:idCy+1), ...
                  julian_2_gregorian_dec_argo(tabJuld(idCy)), ...
                  julian_2_gregorian_dec_argo(tabJuld(idCy+1)));
            else
               if (tabCyNum(idCy+1) == tabCyNum(idCy)+1)
                  cycleTime = (tabJuld(idCy+1) - tabJuld(idCy))*24;
                  if (length(cycleTimeMeta) == 1)
                     cycleTimeExp = cycleTimeMeta;
                  else
                     idF = find(tabMisNum(idCy+1) == confNum);
                     cycleTimeExp = cycleTimeMeta(idF);
                  end
                  if (abs(cycleTimeExp-cycleTime)/cycleTimeExp > 0.25)
                     fprintf('WARNING: Float #%d Cycle #%d -> #%d: %.1f hours (%d hours) - > 25 %%\n', ...
                        floatNum, tabCyNum(idCy:idCy+1), cycleTime, cycleTimeExp);
                  else
                     fprintf('INFO: Float #%d Cycle #%d -> #%d: %.1f hours (%d hours)\n', ...
                        floatNum, tabCyNum(idCy:idCy+1), cycleTime, cycleTimeExp);
                  end
               end
            end
         end
      end
   end
end


ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
