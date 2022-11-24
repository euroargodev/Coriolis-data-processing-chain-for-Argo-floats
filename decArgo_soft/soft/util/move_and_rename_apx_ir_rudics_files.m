% ------------------------------------------------------------------------------
% For a given list of Apex Iridium Rudics or Navis floats, process the
% associated log and msg files by:
%   1: renaming the files
%   2: deleting duplicated files
%   3: identifying the files (by setting their cycle number)
%
% SYNTAX :
%   move_and_rename_apx_ir_rudics_files or move_and_rename_apx_ir_rudics_files(6900189, 7900118)
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
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function move_and_rename_apx_ir_rudics_files(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;

% default values initialization
init_default_values;

% input directory to process
DIR_INPUT_IR_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_IR\data_in_20170904\';
DIR_INPUT_IR_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_IR\data_in_test\';

% output directory
DIR_OUTPUT_IR_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_IR\data_out_20170904\';
DIR_OUTPUT_IR_FILES = 'C:\Users\jprannou\_DATA\IN\APEX_IR\data_out_test\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% if we want to set all PID numbers to zero (needed for comparison with V2 RT
% data
PID_ZERO = 1;

STEP_1 = 1; % move and rename msg files
STEP_2 = 1; % move and rename log files
STEP_3 = 1; % delete duplicated msg files
STEP_4 = 1; % delete duplicated log files
STEP_5 = 1; % identify msg files
STEP_6 = 1; % identify log files

% configuration parameters
configVar = [];
configVar{end+1} = 'FLOAT_INFORMATION_FILE_NAME';

% get configuration parameters
g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 0;
[configVal, unusedVarargin, inputError] = get_config_dec_argo(configVar, []);
floatInformationFileName = configVal{1};

logFile = [DIR_LOG_FILE '/' 'move_and_rename_apx_ir_rudics_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% rename 'msg' files erroneously named 'log'
move_log_to_msg(DIR_INPUT_IR_FILES);

% get floats information
[listWmo, listDecId, listSN, listFrameLen, ...
   listCycleTime, listDriftSamplingPeriod, listDelay, ...
   listLaunchDate, listLaunchLon, listLaunchLat, ...
   listRefDay, listEndDate, listDmFlag] = get_floats_info(floatInformationFileName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% duplicate and rename files
if (STEP_1)
   
   fprintf('\n DUPLICATE AND RENAME MSG FILES\n\n');
   
   if ~(exist(DIR_OUTPUT_IR_FILES, 'dir') == 7)
      mkdir(DIR_OUTPUT_IR_FILES);
   end
   
   dirNames = dir(DIR_INPUT_IR_FILES);
   for idDir = 1:length(dirNames)
      if (strcmp(dirNames(idDir).name, '.') || strcmp(dirNames(idDir).name, '..'))
         continue
      end
      
      %       fprintf('Directory: %s\n', dirNames(idDir).name);
      dirName = dirNames(idDir).name;
      idF = strfind(dirName, '_');
      if (~isempty(idF))
         dirName = dirName(1:idF(1)-1);
      end
      [floatRudicsId, status] = str2num(dirName);
      if (status == 0)
         continue
      end
      
      %       if (floatRudicsId ~= 9253)
      %          continue
      %       end
      
      % check if this file is managed
      decId = [];
      idF = find(strcmp(listSN, num2str(floatRudicsId)));
      if (~isempty(idF))
         decIdList = listDecId(idF);
         
         % float SN 7126 is used with firmwRev 120210 and 062813 which share the
         % same drift meas decoder => we can set decId = decIdList(1) for all
         % floats
         decId = decIdList(1);
      end
      
      dirPathFileName = [DIR_INPUT_IR_FILES dirNames(idDir).name];
      if (exist(dirPathFileName, 'dir') == 7)
         fileNames = dir([dirPathFileName '/' '*msg*']);
         for idFile = 1:length(fileNames)
            fileName = fileNames(idFile).name;
            %             fprintf('File: %s\n', fileName);
            
            filePathName = [dirPathFileName '/' fileName];
            
            if (fileNames(idFile).bytes == 0)
               fprintf('INFO: Empty file: %s - ignored\n', filePathName);
               continue
            end
            
            if (~isempty(decId))
               
               [error, ...
                  configDataStr, ...
                  driftMeasDataStr, ...
                  profInfoDataStr, ...
                  profLowResMeasDataStr, ...
                  profHighResMeasDataStr, ...
                  gpsFixDataStr, ...
                  engineeringDataStr, ...
                  nearSurfaceDataStr ...
                  ] = read_apx_ir_rudics_msg_file(filePathName);
               if (error == 1)
                  fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
                  continue
               end
               
               [configData] = parse_apx_ir_config_data(configDataStr);
               [profInfo] = parse_apx_ir_profile_info(profInfoDataStr);
               [driftData] = parse_apx_ir_drift_data(driftMeasDataStr, decId);
               [gpsLocDate, gpsLocLon, gpsLocLat, ...
                  gpsLocNbSat, gpsLocAcqTime, ...
                  gpsLocFailedAcqTime, gpsLocFailedIce] = parse_apx_ir_gps_fix(gpsFixDataStr);
               
               dates = [];
               if (~isempty(profInfo) && isfield(profInfo, 'ProfTime'))
                  dates = [dates profInfo.ProfTime];
               end
               if (~isempty(gpsLocDate))
                  dates = [dates; gpsLocDate];
               end
               if (~isempty(driftData))
                  dates = [dates; driftData.dates(:, 1)];
               end
               
               if (~isempty(dates))
                  date = min(dates);
               else
                  fprintf('ERROR: No dates in file: %s - ignored\n', filePathName);
                  continue
               end
            else
               date = fileNames(idFile).datenum - g_decArgo_janFirst1950InMatlab;
            end
            
            floatId = [];
            cyNum = [];
            pid = 0;
            
            idF = strfind(fileName, '.');
            if (length(idF) == 2)
               [val, count, errmsg, nextIndex] = sscanf(fileName, '%d.%d.msg');
               if (~isempty(errmsg) || (count ~= 2))
                  fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
                  continue
               end
               floatId = val(1);
               cyNum = val(2);
            elseif (length(idF) == 3)
               [val, count, errmsg, nextIndex] = sscanf(fileName, '%d.%d.msg.%d');
               if (~isempty(errmsg) || (count ~= 3))
                  fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
                  continue
               end
               floatId = val(1);
               cyNum = val(2);
               if (~PID_ZERO)
                  pid = val(3);
               end
            elseif (length(idF) == 4)
               [val, count, errmsg, nextIndex] = sscanf(fileName, '%d.%d.msg.%d.%d');
               if (~isempty(errmsg) || (count ~= 4))
                  fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
                  continue
               end
               floatId = val(1);
               cyNum = val(2);
               if (~PID_ZERO)
                  pid = val(3);
               end
            else
               fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
               continue
            end
            
            if (~isempty(decId))
               outputFileName = sprintf('%04d_%s_%03d_WWWWWWW_WWW_%08d.msg', ...
                  floatId, ...
                  datestr(date + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
                  cyNum, ...
                  pid);
            else
               outputFileName = sprintf('%04d_%s_%03d_%08d.msg', ...
                  floatId, ...
                  datestr(date + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
                  cyNum, ...
                  pid);
            end
            
            floatDirPathName = [DIR_OUTPUT_IR_FILES '/' sprintf('%04d', floatId) '/'];
            if ~(exist(floatDirPathName, 'dir') == 7)
               mkdir(floatDirPathName);
            end
            
            if (exist([floatDirPathName outputFileName], 'file') == 2)
               idF = strfind(outputFileName, '_');
               if (length(idF) == 5)
                  baseOutputFileName = outputFileName(1:idF(5));
               else
                  baseOutputFileName = outputFileName(1:idF(3));
               end
               cpt = 1;
               while (exist([floatDirPathName baseOutputFileName sprintf('%08d', pid+cpt) '.msg'], 'file') == 2)
                  cpt = cpt + 1;
               end
               %                fprintf('WARNING: File ''%s'' renamed ''%s''\n', ...
               %                   outputFileName, [baseOutputFileName sprintf('%08d', pid+cpt) '.msg']);
               
               outputFileName = [baseOutputFileName sprintf('%08d', pid+cpt) '.msg'];
            end
            
            outputFilePathName = [floatDirPathName outputFileName];
            if (copyfile(filePathName, outputFilePathName) == 0)
               fprintf('ERROR: Error while copying file ''%s''\n', outputFilePathName);
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (STEP_2)
   
   fprintf('\n DUPLICATE AND RENAME LOG FILES\n\n');
   
   if ~(exist(DIR_OUTPUT_IR_FILES, 'dir') == 7)
      mkdir(DIR_OUTPUT_IR_FILES);
   end
   
   dirNames = dir(DIR_INPUT_IR_FILES);
   for idDir = 1:length(dirNames)
      if (strcmp(dirNames(idDir).name, '.') || strcmp(dirNames(idDir).name, '..'))
         continue
      end
      
      dirName = dirNames(idDir).name;
      idF = strfind(dirName, '_');
      if (~isempty(idF))
         dirName = dirName(1:idF(1)-1);
      end
      [floatRudicsId, status] = str2num(dirName);
      if (status == 0)
         continue
      end
      
      %       if (floatRudicsId ~= 9253)
      %          continue
      %       end
      
      % check if this file is managed
      decId = [];
      idF = find(strcmp(listSN, num2str(floatRudicsId)));
      if (~isempty(idF))
         decIdList = listDecId(idF);
         
         % float SN 7126 is used with firmwRev 120210 and 062813 which share the
         % same drift meas decoder => we can set decId = decIdList(1) for all
         % floats
         decId = decIdList(1);
      end
      
      %       fprintf('Directory: %s\n', dirNames(idDir).name);
      dirPathFileName = [DIR_INPUT_IR_FILES dirNames(idDir).name];
      if (exist(dirPathFileName, 'dir') == 7)
         fileNames = dir([dirPathFileName '/' '*log*']);
         for idFile = 1:length(fileNames)
            fileName = fileNames(idFile).name;
            %             fprintf('File: %s\n', fileName);
            
            filePathName = [dirPathFileName '/' fileName];
            
            if (fileNames(idFile).bytes == 0)
               fprintf('INFO: Empty file: %s - ignored\n', filePathName);
               continue
            end
            
            [error, events] = read_apx_ir_rudics_log_file(filePathName);
            if (error == 1)
               fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
               continue
            end
            
            floatId = [];
            cyNum = [];
            pid = 0;
            
            idF = strfind(fileName, '.');
            if (length(idF) == 2)
               [val, count, errmsg, nextIndex] = sscanf(fileName, '%d.%d.log');
               if (~isempty(errmsg) || (count ~= 2))
                  fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
                  continue
               end
               floatId = val(1);
               if (val(2) < 1000)
                  cyNum = val(2);
               end
            elseif (length(idF) == 3)
               [val, count, errmsg, nextIndex] = sscanf(fileName, '%d.%d.log.%d');
               if (~isempty(errmsg) || (count ~= 3))
                  fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
                  continue
               end
               floatId = val(1);
               if (val(2) < 1000)
                  cyNum = val(2);
               end
               if (~PID_ZERO)
                  pid = val(3);
               end
            elseif (length(idF) == 4)
               [val, count, errmsg, nextIndex] = sscanf(fileName, '%d.%d.log.%d.%d');
               if (~isempty(errmsg) || (count ~= 4))
                  fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
                  continue
               end
               floatId = val(1);
               if (val(2) < 1000)
                  cyNum = val(2);
               end
               if (~PID_ZERO)
                  pid = val(3);
               end
            else
               fprintf('WARNING: Anomaly detected in file name ''%s'' - file ignored\n', fileName);
            end
            
            cyNumStr = 'CCC';
            if (~isempty(cyNum))
               cyNumStr = sprintf('%03d', cyNum);
            end
            
            time = min([events.time]);
            if (~isempty(decId))
               outputFileName = sprintf('%04d_%s_%s_WWWWWWW_WWW_%08d.log', ...
                  floatId, ...
                  datestr(time + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
                  cyNumStr, ...
                  pid);
            else
               outputFileName = sprintf('%04d_%s_%s_%08d.log', ...
                  floatId, ...
                  datestr(time + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
                  cyNumStr, ...
                  pid);
            end
            
            floatDirPathName = [DIR_OUTPUT_IR_FILES '/' sprintf('%04d', floatId) '/'];
            if ~(exist(floatDirPathName, 'dir') == 7)
               mkdir(floatDirPathName);
            end
            
            if (exist([floatDirPathName outputFileName], 'file') == 2)
               idF = strfind(outputFileName, '_');
               if (length(idF) == 5)
                  baseOutputFileName = outputFileName(1:idF(5));
               else
                  baseOutputFileName = outputFileName(1:idF(3));
               end
               cpt = 1;
               while (exist([floatDirPathName baseOutputFileName sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
                  cpt = cpt + 1;
               end
               %                fprintf('WARNING: File ''%s'' renamed ''%s''\n', ...
               %                   outputFileName, [baseOutputFileName sprintf('%08d', pid+cpt) '.msg']);
               
               outputFileName = [baseOutputFileName sprintf('%08d', pid+cpt) '.log'];
            end
            
            outputFilePathName = [floatDirPathName outputFileName];
            if (copyfile(filePathName, outputFilePathName) == 0)
               fprintf('ERROR: Error while copying file ''%s''\n', outputFilePathName);
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean duplicated files
if (STEP_3)
   
   fprintf('\n DELETE DUPLICATED MSG FILES\n\n');
   
   dirNames = dir(DIR_OUTPUT_IR_FILES);
   for idDir = 1:length(dirNames)
      if (strcmp(dirNames(idDir).name, '.') || strcmp(dirNames(idDir).name, '..'))
         continue
      end
      
      fprintf('Directory: %s\n', dirNames(idDir).name);
      
      dirPathFileName = [DIR_OUTPUT_IR_FILES dirNames(idDir).name];
      if (exist(dirPathFileName, 'dir') == 7)
         cyList = [];
         fileNames = dir([dirPathFileName '/' '*.msg']);
         for idFile = 1:length(fileNames)
            fileName = fileNames(idFile).name;
            cyList{end+1} = fileName(26:28);
         end
         cyList = unique(cyList);
         for idCy = 1:length(cyList)
            fileNames = dir([dirPathFileName '/' dirNames(idDir).name '_*_' cyList{idCy} '_' '*.msg']);
            if (length(fileNames) > 1)
               fileList = {fileNames.name};
               fileListDelete = compare_files(dirPathFileName, fileList);
               for idFile = 1:length(fileListDelete)
                  fprintf('Deleting file: %s\n', fileListDelete{idFile});
                  delete([dirPathFileName '/' fileListDelete{idFile}]);
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (STEP_4)
   
   fprintf('\n DELETE DUPLICATED LOG FILES\n\n');
   
   dirNames = dir(DIR_OUTPUT_IR_FILES);
   for idDir = 1:length(dirNames)
      if (strcmp(dirNames(idDir).name, '.') || strcmp(dirNames(idDir).name, '..'))
         continue
      end
      
      fprintf('Directory: %s\n', dirNames(idDir).name);
      
      %       if (str2num(dirNames(idDir).name) ~= 9283)
      %          continue
      %       end
      
      dirPathFileName = [DIR_OUTPUT_IR_FILES dirNames(idDir).name];
      if (exist(dirPathFileName, 'dir') == 7)
         cyList = [];
         fileNames = dir([dirPathFileName '/' '*.log']);
         for idFile = 1:length(fileNames)
            fileName = fileNames(idFile).name;
            cyList{end+1} = fileName(26:28);
         end
         cyList = unique(cyList);
         for idCy = 1:length(cyList)
            fileNames = dir([dirPathFileName '/' dirNames(idDir).name '_*_' cyList{idCy} '_' '*.log']);
            if (length(fileNames) > 1)
               fileList = {fileNames.name};
               fileListDelete = compare_files(dirPathFileName, fileList);
               for idFile = 1:length(fileListDelete)
                  fprintf('Deleting file: %s\n', fileListDelete{idFile});
                  delete([dirPathFileName '/' fileListDelete{idFile}]);
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% identify files
if (STEP_5)
   
   fprintf('\n IDENTIFY MSG FILES\n\n');
   
   dirNames = dir(DIR_OUTPUT_IR_FILES);
   for idDir = 1:length(dirNames)
      if (strcmp(dirNames(idDir).name, '.') || strcmp(dirNames(idDir).name, '..'))
         continue
      end
      
      fprintf('Directory: %s\n', dirNames(idDir).name);
      floatRudicsId = str2num(dirNames(idDir).name);
      
      %       if (floatRudicsId ~= 9253)
      %          continue
      %       end
      
      wmoList = [];
      launchDateList = [];
      endDateList = [];
      decId = [];
      
      % check if this file is managed
      idF = find(strcmp(listSN, num2str(floatRudicsId)));
      if (~isempty(idF))
         wmoList = listWmo(idF);
         launchDateList = listLaunchDate(idF);
         endDateList = listEndDate(idF);
         decIdList = listDecId(idF);
         
         [launchDateList, sortId] = sort(launchDateList);
         wmoList = wmoList(sortId);
         endDateList = endDateList(sortId);
         decIdList = decIdList(sortId);
         
         % float SN 7126 is used with firmwRev 120210 and 062813 which share the
         % same drift meas decoder => we can set decId = decIdList(1) for all
         % floats
         decId = decIdList(1);
      end
      
      dirPathFileName = [DIR_OUTPUT_IR_FILES dirNames(idDir).name];
      if (exist(dirPathFileName, 'dir') == 7)
         fileNames = dir([dirPathFileName '/' '*.msg']);
         for idFile = 1:length(fileNames)
            fileName = fileNames(idFile).name;
            
            idF = strfind(fileName, '_');
            foatId = str2num(fileName(1:idF(1)-1));
            cyNum = str2num(fileName(idF(2)+1:idF(3)-1));
            
            filePathName = [dirPathFileName '/' fileName];
            
            [error, ...
               configDataStr, ...
               driftMeasDataStr, ...
               profInfoDataStr, ...
               profLowResMeasDataStr, ...
               profHighResMeasDataStr, ...
               gpsFixDataStr, ...
               engineeringDataStr, ...
               nearSurfaceDataStr ...
               ] = read_apx_ir_rudics_msg_file(filePathName);
            if (error == 1)
               fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
               continue
            end
            
            [configData] = parse_apx_ir_config_data(configDataStr);
            [profInfo] = parse_apx_ir_profile_info(profInfoDataStr);
            
            if (~isempty(configData) && isfield(configData, 'floatRudicsId'))
               if (foatId ~= str2num(configData.floatRudicsId))
                  fprintf('ERROR: Inconsistent FloatId (%d vs %d)\n', foatId, str2num(configData.floatRudicsId));
               end
            end
            if (~isempty(configData) && isfield(configData, 'FloatId'))
               if (foatId ~= str2num(configData.FloatId))
                  fprintf('ERROR: Inconsistent FloatId (%d vs %d)\n', foatId, str2num(configData.FloatId));
               end
            end
            if (~isempty(profInfo) && isfield(profInfo, 'floatRudicsId'))
               if (foatId ~= str2num(profInfo.floatRudicsId))
                  fprintf('ERROR: Inconsistent FloatId (%d vs %d)\n', foatId, str2num(profInfo.floatRudicsId));
               end
            end
            if (~isempty(profInfo) && isfield(profInfo, 'CyNum'))
               if (cyNum ~= str2num(profInfo.CyNum))
                  fprintf('ERROR: Inconsistent CyNum (%d vs %d)\n', cyNum, str2num(profInfo.CyNum));
               end
            end
            
            if (~isempty(wmoList))
               
               [driftData] = parse_apx_ir_drift_data(driftMeasDataStr, decId);
               
               [gpsLocDate, gpsLocLon, gpsLocLat, ...
                  gpsLocNbSat, gpsLocAcqTime, ...
                  gpsLocFailedAcqTime, gpsLocFailedIce] = parse_apx_ir_gps_fix(gpsFixDataStr);
               
               floatWmo = [];
               dates = [];
               if (~isempty(profInfo) && isfield(profInfo, 'ProfTime'))
                  dates = [dates profInfo.ProfTime];
               end
               if (~isempty(driftData))
                  dates = [dates; driftData.dates(:, 1)];
               end
               if (~isempty(gpsLocDate))
                  dates = [dates; gpsLocDate];
               end
               
               if (~isempty(dates))
                  if (length(wmoList) == 1)
                     % check consistency
                     if (~any(dates >= launchDateList))
                        fprintf('WARNING: Dates before launch in file: %s\n', fileName);
                        
                        idF = strfind(fileName, '_');
                        newFileName = [fileName(1:idF(3)) num2str(wmoList) '_TTT' fileName(idF(5):end)];
                        if (~strcmp(newFileName, fileName))
                           %                         fprintf('INFO: Renaming file: %s - %s\n', fileName, newFileName);
                           move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                        end
                     else
                        floatWmo = wmoList;
                     end
                  else
                     for idD = 1:length(launchDateList)
                        startDate = launchDateList(idD);
                        endDate = endDateList(idD);
                        if (endDate == g_decArgo_dateDef)
                           if (~any(dates < startDate))
                              floatWmo = wmoList(idD);
                              break
                           end
                        else
                           if (~any(dates < startDate) && ~any(dates > endDate))
                              floatWmo = wmoList(idD);
                              break
                           end
                        end
                     end
                     if (isempty(floatWmo))
                        fprintf('WARNING: unable to get WMO number for file: %s\n', fileName);
                     end
                  end
               else
                  fprintf('WARNING: No date to get WMO number for file: %s\n', fileName);
               end
               if (~isempty(floatWmo))
                  idF = strfind(fileName, '_');
                  newFileName = [fileName(1:idF(3)) num2str(floatWmo) fileName(idF(2):idF(3)-1) fileName(idF(5):end)];
                  if (~strcmp(newFileName, fileName))
                     %                   fprintf('INFO: Renaming file: %s - %s\n', fileName, newFileName);
                     move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                  end
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if (STEP_6)
   
   fprintf('\n IDENTIFY LOG FILES\n\n');
   
   dirNames = dir(DIR_OUTPUT_IR_FILES);
   for idDir = 1:length(dirNames)
      if (strcmp(dirNames(idDir).name, '.') || strcmp(dirNames(idDir).name, '..'))
         continue
      end
      
      fprintf('Directory: %s\n', dirNames(idDir).name);
      floatRudicsId = str2num(dirNames(idDir).name);
      
      %       if (floatRudicsId ~= 9253)
      %          continue
      %       end
      
      % check if this file is managed
      idF = find(strcmp(listSN, num2str(floatRudicsId)));
      if (~isempty(idF))
         wmoList = listWmo(idF);
         launchDateList = listLaunchDate(idF);
         endDateList = listEndDate(idF);
         decIdList = listDecId(idF);
         
         [launchDateList, sortId] = sort(launchDateList);
         wmoList = wmoList(sortId);
         endDateList = endDateList(sortId);
         
         dirPathFileName = [DIR_OUTPUT_IR_FILES dirNames(idDir).name];
         if (exist(dirPathFileName, 'dir') == 7)
            
            % set wmo numbers
            fileNames = dir([dirPathFileName '/' '*.log']);
            for idFile = 1:length(fileNames)
               fileName = fileNames(idFile).name;
               
               filePathName = [dirPathFileName '/' fileName];
               
               [error, events] = read_apx_ir_rudics_log_file(filePathName);
               if (error == 1)
                  fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
                  continue
               end
               
               dates = [events.time];
               if (length(wmoList) == 1)
                  % check consistency
                  if (~any(dates >= launchDateList))
                     fprintf('WARNING: Dates before launch in file: %s\n', fileName);
                     idF = strfind(fileName, '_');
                     newFileName = [fileName(1:idF(3)) num2str(wmoList) '_TTT' fileName(idF(5):end)];
                     if (~strcmp(newFileName, fileName))
                        move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                     end
                  else
                     idF = strfind(fileName, '_');
                     newFileName = [fileName(1:idF(3)) num2str(wmoList) fileName(idF(2):idF(3)-1) fileName(idF(5):end)];
                     if (~strcmp(newFileName, fileName))
                        move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                     end
                  end
               else
                  floatWmo = [];
                  if (~any(dates >= min(launchDateList)))
                     floatWmo = wmoList(1);
                  else
                     for idD = 1:length(launchDateList)
                        startDate = launchDateList(idD);
                        endDate = endDateList(idD);
                        if (endDate == g_decArgo_dateDef)
                           if (any(dates >= startDate))
                              floatWmo = wmoList(idD);
                              break
                           end
                        else
                           if (any((dates >= startDate) & (dates <= endDate)))
                              floatWmo = wmoList(idD);
                              break
                           end
                        end
                     end
                  end
                  if (isempty(floatWmo))
                     fprintf('WARNING: unable to get WMO number for file: %s\n', fileName);
                  else
                     idF = strfind(fileName, '_');
                     newFileName = [fileName(1:idF(3)) num2str(floatWmo) fileName(idF(2):idF(3)-1) fileName(idF(5):end)];
                     if (~strcmp(newFileName, fileName))
                        move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                     end
                  end
               end
            end
            
            % set remaining unknown cycle numbers
            fileNames = dir([dirPathFileName '/' '*CCC*CCC*.log']);
            if (~isempty(fileNames))
               wmoList = [];
               for idFile = 1:length(fileNames)
                  fileName = fileNames(idFile).name;
                  idF = strfind(fileName, '_');
                  floatWmo = str2num(fileName(idF(3)+1:idF(4)-1));
                  wmoList = [wmoList floatWmo];
               end
               wmoList = unique(wmoList);
               
               for idFloat = 1:length(wmoList)
                  fileNames = dir([dirPathFileName '/' '*' num2str(wmoList(idFloat)) '*.log']);
                  cyNumDate = [];
                  for idFile = 1:length(fileNames)
                     fileName = fileNames(idFile).name;
                     
                     filePathName = [dirPathFileName '/' fileName];
                     
                     [error, events] = read_apx_ir_rudics_log_file(filePathName);
                     if (error == 1)
                        fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
                        continue
                     end
                     
                     idF = strfind(fileName, '_');
                     cyNum = fileName(idF(4)+1:idF(5)-1);
                     date = min([events.time]);
                     cyNumDate = [cyNumDate; {cyNum} {date} {fileName}];
                  end
                  
                  [~, idSort] = sort([cyNumDate{:, 2}]);
                  cyNumDate = cyNumDate(idSort, :);
                  idFileCy = find(~strcmp(cyNumDate(:, 1), 'CCC'));
                  idFileNoCy = find(strcmp(cyNumDate(:, 1), 'CCC'));
                  
                  for idFile = 1:length(idFileNoCy)
                     fileName = cyNumDate{idFileNoCy(idFile), 3};
                     cyNumPrev = [];
                     cyNumNext = [];
                     idF1 = find(idFileCy < idFileNoCy(idFile));
                     if (~isempty(idF1))
                        idB = idFileCy(idF1(end));
                        [cyNumPrev, status] = str2num(cyNumDate{idB, 1});
                     end
                     idF2 = find(idFileCy > idFileNoCy(idFile));
                     if (~isempty(idF2))
                        idA = idFileCy(idF2(1));
                        [cyNumNext, status] = str2num(cyNumDate{idA, 1});
                     end
                     if (~isempty(cyNumPrev) && ~isempty(cyNumNext))
                        if (cyNumPrev == cyNumNext-1)
                           idF = strfind(fileName, '_');
                           newFileName = [fileName(1:idF(4)) cyNumDate{idB, 1} fileName(idF(5):end)];
                           if (~strcmp(newFileName, fileName))
                              move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                           end
                        else
                           fprintf('WARNING: unable to determine cycle number for file: %s\n', fileName);
                        end
                        %                      elseif (~isempty(cyNumNext) && ((cyNumNext == 0) || (cyNumNext == 1)))
                     else
                        % use deployment date
                        idF = find(wmoList(idFloat) == listWmo);
                        if (~isempty(idF))
                           launchDate = listLaunchDate(idF);
                           
                           filePathName = [dirPathFileName '/' fileName];
                           
                           [error, events] = read_apx_ir_rudics_log_file(filePathName);
                           if (error == 1)
                              fprintf('ERROR: Error in file: %s - ignored\n', filePathName);
                              continue
                           end
                           
                           dates = [events.time];
                           if (any(dates >= launchDate))
                              cyNum = '000';
                           else
                              cyNum = 'TTT';
                           end
                           idF = strfind(fileName, '_');
                           newFileName = [fileName(1:idF(4)) cyNum fileName(idF(5):end)];
                           if (~strcmp(newFileName, fileName))
                              move_file([dirPathFileName '/' fileName], [dirPathFileName '/' newFileName]);
                           end
                        else
                           fprintf('WARNING: unable to determine cycle number for file: %s\n', fileName);
                        end
                        %                      else
                        %                         fprintf('WARNING: unable to determine cycle number for file: %s\n', fileName);
                     end
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

% ------------------------------------------------------------------------------
% Compare the content of one file to a list of files.
%
% SYNTAX :
%  [o_delete] = compare_files(a_filePathName, a_fileNameList)
%
% INPUT PARAMETERS :
%   a_filePathName : file path name
%   a_fileNameList : list of file path names
%
% OUTPUT PARAMETERS :
%   o_delete : delete checked file flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_delete] = compare_files(a_filePathName, a_fileNameList)

% output parameters initialization
o_delete = [];

stop = 0;
while (~stop)
   deleteFlag = 0;
   for idF1 = 1:length(a_fileNameList)-1
      for idF2 = idF1+1:length(a_fileNameList)
         if (identical([a_filePathName '/' a_fileNameList{idF1}], ...
               [a_filePathName '/' a_fileNameList{idF2}]) == 1)
            o_delete{end+1} = a_fileNameList{idF2};
            a_fileNameList(idF2) = [];
            deleteFlag = 1;
            break
         end
      end
      if (deleteFlag == 1)
         break
      end
   end
   if (deleteFlag == 0)
      stop = 1;
   end
end

return

% ------------------------------------------------------------------------------
% Check if 2 file contents are identical.
%
% SYNTAX :
%  [o_identical] = identical(a_fileName1, a_fileName2)
%
% INPUT PARAMETERS :
%   a_fileName1 : first file path name
%   a_fileName2 : second file path name
%
% OUTPUT PARAMETERS :
%   o_identical :identical files flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_identical] = identical(a_fileName1, a_fileName2)

% output parameters initialization
o_identical = 0;


fid = fopen(a_fileName1, 'r');
if (fid == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_fileName1);
   return
end
file1Contents = textscan(fid, '%s');
file1Contents = file1Contents{:};
fclose(fid);

fid = fopen(a_fileName2, 'r');
if (fid == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_fileName2);
   return
end
file2Contents = textscan(fid, '%s');
file2Contents = file2Contents{:};
fclose(fid);

if ((length(file1Contents) == length(file2Contents)) && ...
      ~any(strcmp(file1Contents, file2Contents) ~= 1))
   o_identical = 1;
end

return

% ------------------------------------------------------------------------------
% Rename a list of msg files erroneously named log.
%
% SYNTAX :
% move_log_to_msg(a_inputFilePathName)
%
% INPUT PARAMETERS :
%   a_inputFilePathName : input file path name
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function move_log_to_msg(a_inputFilePathName)

file_names = [ ...
   {'7126_6901901/7126.009.log.10939285'} {'7126_6901901/7126.009.msg.10939285'}; ...
   {'7126_6901901/7126.010.log.10939286'} {'7126_6901901/7126.010.msg.10939286'}; ...
   {'7126_6901901/7126.011.log.10939288'} {'7126_6901901/7126.011.msg.10939288'}; ...
   {'7126_6901901/7126.012.log.10939289'} {'7126_6901901/7126.012.msg.10939289'}; ...
   {'7126_6901901/7126.013.log.10939290'} {'7126_6901901/7126.013.msg.10939290'}; ...
   {'7126_6901901/7126.014.log.10939291'} {'7126_6901901/7126.014.msg.10939291'}; ...
   {'7126_6901901/7126.015.log.10939292'} {'7126_6901901/7126.015.msg.10939292'}; ...
   {'7126_6901901/7126.016.log.10939294'} {'7126_6901901/7126.016.msg.10939294'}; ...
   {'7126_6901901/7126.017.log.10939295'} {'7126_6901901/7126.017.msg.10939295'}; ...
   {'7126_6901901/7126.018.log.10939296'} {'7126_6901901/7126.018.msg.10939296'}; ...
   {'7126_6901901/7126.020.log.10939298'} {'7126_6901901/7126.020.msg.10939298'}; ...
   {'7126_6901901/7126.021.log.10946860'} {'7126_6901901/7126.021.msg.10946860'} ...
   ];

for idFile = 1:size(file_names, 1)
   if (exist([a_inputFilePathName '/' file_names{idFile, 1}], 'file') == 2)
      [status, message, messageId] = move_file( ...
         [a_inputFilePathName '/' file_names{idFile, 1}], [a_inputFilePathName '/' file_names{idFile, 2}]);
      if (status == 0)
         fprintf('ERROR: Unable to rename file: %s (''%s'')\n', ...
            [a_inputFilePathName '/' file_names{idFile, 1}], message);
      end
   end
end

return
