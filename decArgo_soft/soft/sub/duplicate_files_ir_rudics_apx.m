% ------------------------------------------------------------------------------
% Duplicate a list of files from a directory to another one and rename them
% according to decoder specifications.
%
% SYNTAX :
%  [o_nbFiles] = duplicate_files_ir_rudics_apx(a_floatNum, a_decoderId, a_floatLaunchDate, a_floatEndDate)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_decoderId       : float decoder Id
%   a_floatLaunchDate : float launch date
%   a_floatEndDate    : float end decoding date
%
% OUTPUT PARAMETERS :
%   o_nbFiles : number of files duplicated
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/21/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbFiles] = duplicate_files_ir_rudics_apx(a_floatNum, a_decoderId, a_floatLaunchDate, a_floatEndDate)

% output parameters initialization
o_nbFiles = 0;

% decoder configuration values
global g_decArgo_dirInputRsyncData;

% IRIDIUM_DATA sub-directories
global g_decArgo_archiveDirectory;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


% STEP 1: duplicate and rename input files

nbFiles = 0;
fileIdList = find(g_decArgo_rsyncFloatWmoList == a_floatNum);
for idFile = 1:length(fileIdList)
   % for idFile = 1:130
   dataFilePathName = [g_decArgo_dirInputRsyncData '/' ...
      g_decArgo_rsyncFloatSbdFileList{fileIdList(idFile)}];
   
   if ~(exist(dataFilePathName, 'file') == 2)
      continue;
   end
   
   fileNames = dir(dataFilePathName);
   if (fileNames(1).bytes == 0)
      fprintf('RSYNC_INFO: Empty file: %s => ignored\n', dataFilePathName);
      continue;
   end
   
   % parse input file name
   [~, dataFileName, dataFileExt] = fileparts(dataFilePathName);
   if (isempty(dataFileExt))
      dataFileExt = '.msg';
   end
   
   idF = strfind(dataFileName, '_');
   floatId = str2double(dataFileName(1:idF(1)-1));
   if (length(idF) == 3)
      pid = str2double(dataFileName(idF(3)+1:end));
      cycleNumInStr = dataFileName(idF(2)+1:idF(3)-1);
   elseif (length(idF) == 5) % when the files come from V1 archive processed data (used as the first rsync)
      pid = str2double(dataFileName(idF(5)+1:end));
      cycleNumInStr = dataFileName(idF(2)+1:idF(3)-1);
   else
      pid = 0;
      cycleNumInStr = dataFileName(idF(2)+1:end);
   end
   if (length(cycleNumInStr) == 10)
      cycleNumInStr = 'CCC';
   end
   
   % create the date and the output cycle number to be set in the output file name
   if (strcmp(dataFileExt, '.msg'))
      
      [error, ...
         configDataStr, ...
         driftMeasDataStr, ...
         profInfoDataStr, ...
         profLowResMeasDataStr, ...
         profHighResMeasDataStr, ...
         gpsFixDataStr, ...
         engineeringDataStr, ...
         nearSurfaceDataStr ...
         ] = read_apx_ir_rudics_msg_file(dataFilePathName);
      if (error == 1)
         fprintf('RSYNC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
            a_floatNum, dataFilePathName);
         continue;
      end
      
      dates = [];
      driftData = parse_apx_ir_drift_data(driftMeasDataStr, a_decoderId);
      if (~isempty(driftData))
         measDates = driftData.dates;
         measDates(find(measDates == driftData.dateList.fillValue)) = [];
         dates = [dates; measDates];
      end
      profInfo = parse_apx_ir_profile_info(profInfoDataStr);
      if (~isempty(profInfo) && isfield(profInfo, 'ProfTime'))
         dates = [dates; profInfo.ProfTime];
      end
      [gpsLocDate, gpsLocLon, gpsLocLat, ...
         gpsLocNbSat, gpsLocAcqTime, ...
         gpsLocFailedAcqTime, gpsLocFailedIce] = parse_apx_ir_gps_fix(gpsFixDataStr);
      if (~isempty(gpsLocDate))
         dates = [dates; gpsLocDate];
      end
      if (isempty(dates))
         % we use NS dates only if there are no more dates in the file
         if (~isempty(nearSurfaceDataStr) && ~isempty(nearSurfaceDataStr{1}))
            [nearSurfData, surfDataBladderDeflated, surfDataBladderInflated] = ...
               parse_nvs_ir_rudics_near_surface_data(nearSurfaceDataStr, a_decoderId);
            for id = 1:length(nearSurfData)
               if (~isempty(nearSurfData{id}.dates))
                  measDates = nearSurfData{id}.dates;
                  measDates(find(measDates == nearSurfData{id}.dateList.fillValue)) = [];
                  dates = [dates; measDates];
               end
            end
            for id = 1:length(surfDataBladderDeflated)
               if (~isempty(surfDataBladderDeflated{id}.dates))
                  measDates = surfDataBladderDeflated{id}.dates;
                  measDates(find(measDates == surfDataBladderDeflated{id}.dateList.fillValue)) = [];
                  dates = [dates; measDates];
               end
            end
            for id = 1:length(surfDataBladderInflated)
               if (~isempty(surfDataBladderInflated{id}.dates))
                  measDates = surfDataBladderInflated{id}.dates;
                  measDates(find(measDates == surfDataBladderInflated{id}.dateList.fillValue)) = [];
                  dates = [dates; measDates];
               end
            end
         end
      end
      
      if (~isempty(dates))
         date = min(dates);
      else
         fprintf('RSYNC_INFO: Float #%d: No dates in file ''%s'' => ignored\n', ...
            a_floatNum, dataFilePathName);
         continue;
      end
      
   elseif (strcmp(dataFileExt, '.log'))
      
      [error, events] = read_apx_ir_rudics_log_file(dataFilePathName);
      if (error == 1)
         fprintf('RSYNC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
            a_floatNum, dataFilePathName);
         continue;
      end
      
      dates = [events.time];
      date = min(dates);
      
   else
      fprintf('RSYNC_INFO: Float #%d: Don''t know how to manage file ''%s'' in duplicate_files_ir_rudics_apx\n', ...
         a_floatNum, dataFilePathName);
      continue;
   end
   
   cycleNumOutStr = cycleNumInStr;
   if (~any(dates >= a_floatLaunchDate))
      cycleNumOutStr = 'TTT';
   end
   if (a_floatEndDate ~= g_decArgo_dateDef)
      if (any(dates > a_floatEndDate))
         cycleNumOutStr = 'UUU';
      end
   end
   
   % duplicate and rename the input file name
   
   outputFileName = sprintf('%04d_%s_%s_%d_%s_%08d', ...
      floatId, ...
      datestr(date + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
      cycleNumInStr, ...
      a_floatNum, ...
      cycleNumOutStr, ...
      pid);
   
   if (exist([g_decArgo_archiveDirectory outputFileName dataFileExt], 'file') == 2)
      idF = strfind(outputFileName, '_');
      cpt = 1;
      while (exist([g_decArgo_archiveDirectory outputFileName(1:idF(5)) sprintf('%08d', pid+cpt) dataFileExt], 'file') == 2)
         cpt = cpt + 1;
      end
      outputFileName = [outputFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
   end
   
   outputFilePathName = [g_decArgo_archiveDirectory outputFileName dataFileExt];
   if (copyfile(dataFilePathName, outputFilePathName) == 0)
      fprintf('RSYNC_ERROR: Float #%d: Error while copying file ''%s''\n', ...
         a_floatNum, dataFilePathName);
   else
      nbFiles = nbFiles + 1;
   end
end
o_nbFiles = nbFiles;

% STEP 2: delete identical files

cyList = [];
fileNames = dir([g_decArgo_archiveDirectory '*.msg']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   cyList{end+1} = fileName(26:28);
end
cyList = unique(cyList);
for idCy = 1:length(cyList)
   fileNames = dir([g_decArgo_archiveDirectory '*_*_' cyList{idCy} '_*_*_*.msg']);
   if (length(fileNames) > 1)
      fileList = {fileNames.name};
      fileListDelete = compare_files(g_decArgo_archiveDirectory, fileList);
      for idFile = 1:length(fileListDelete)
         fprintf('RSYNC_INFO: Float #%d: Deleting file ''%s''\n', ...
            a_floatNum, [g_decArgo_archiveDirectory fileListDelete{idFile}]);
         delete([g_decArgo_archiveDirectory fileListDelete{idFile}]);
      end
   end
end

cyList = [];
fileNames = dir([g_decArgo_archiveDirectory '*.log']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   cyList{end+1} = fileName(26:28);
end
cyList = unique(cyList);
for idCy = 1:length(cyList)
   fileNames = dir([g_decArgo_archiveDirectory '*_*_' cyList{idCy} '_*_*_*.log']);
   if (length(fileNames) > 1)
      fileList = {fileNames.name};
      fileListDelete = compare_files(g_decArgo_archiveDirectory, fileList);
      for idFile = 1:length(fileListDelete)
         fprintf('RSYNC_INFO: Float #%d: Deleting file ''%s''\n', ...
            a_floatNum, [g_decArgo_archiveDirectory fileListDelete{idFile}]);
         delete([g_decArgo_archiveDirectory fileListDelete{idFile}]);
      end
   end
end

% STEP 3: set remaining unknown cycle numbers

if (~isempty((dir([g_decArgo_archiveDirectory '*_*_CCC_*_CCC_*.log']))))
   
   fileNames = dir([g_decArgo_archiveDirectory '*.log']);
   cyNumDate = [];
   for idFile = 1:length(fileNames)
      fileName = fileNames(idFile).name;
      idF = strfind(fileName, '_');
      cyNum = fileName(idF(4)+1:idF(5)-1);
      date = datenum(fileName(idF(1)+1:idF(2)-1), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
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
               if (exist([g_decArgo_archiveDirectory newFileName], 'file') == 2)
                  idF = strfind(newFileName, '_');
                  pid = str2double(newFileName(idF(5):end-4));
                  cpt = 1;
                  while (exist([g_decArgo_archiveDirectory newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)], 'file') == 2)
                     cpt = cpt + 1;
                  end
                  newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)];
               end
               move_file([g_decArgo_archiveDirectory fileName], [g_decArgo_archiveDirectory newFileName]);
            end
         else
            fprintf('RSYNC_WARNING: Float #%d: Unable to determine cycle number for file ''%s''\n', ...
               a_floatNum, [g_decArgo_archiveDirectory fileName]);
         end
      else
         % use deployment date
         [error, events] = read_apx_ir_rudics_log_file([g_decArgo_archiveDirectory fileName]);
         if (error == 1)
            fprintf('RSYNC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
               a_floatNum, [g_decArgo_archiveDirectory fileName]);
            continue;
         end
         dates = [events.time];
         
         cycleNumOutStr = '000';
         if (~any(dates >= a_floatLaunchDate))
            cycleNumOutStr = 'TTT';
         end
         
         idF = strfind(fileName, '_');
         newFileName = [fileName(1:idF(4)) cycleNumOutStr fileName(idF(5):end)];
         if (~strcmp(newFileName, fileName))
            if (exist([g_decArgo_archiveDirectory newFileName], 'file') == 2)
               idF = strfind(newFileName, '_');
               pid = str2double(newFileName(idF(5):end-4));
               cpt = 1;
               while (exist([g_decArgo_archiveDirectory newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)], 'file') == 2)
                  cpt = cpt + 1;
               end
               newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)];
            end
            move_file([g_decArgo_archiveDirectory fileName], [g_decArgo_archiveDirectory newFileName]);
         end
      end
   end
end

if (~isempty((dir([g_decArgo_archiveDirectory '*_*_CCC_*_CCC_*.msg']))))
   
   fileNames = dir([g_decArgo_archiveDirectory '*.msg']);
   cyNumDate = [];
   for idFile = 1:length(fileNames)
      fileName = fileNames(idFile).name;
      idF = strfind(fileName, '_');
      cyNum = fileName(idF(4)+1:idF(5)-1);
      date = datenum(fileName(idF(1)+1:idF(2)-1), 'yyyy-mm-dd-HH-MM-SS') - g_decArgo_janFirst1950InMatlab;
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
               if (exist([g_decArgo_archiveDirectory newFileName], 'file') == 2)
                  idF = strfind(newFileName, '_');
                  pid = str2double(newFileName(idF(5):end-4));
                  cpt = 1;
                  while (exist([g_decArgo_archiveDirectory newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)], 'file') == 2)
                     cpt = cpt + 1;
                  end
                  newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)];
               end
               move_file([g_decArgo_archiveDirectory fileName], [g_decArgo_archiveDirectory newFileName]);
            end
         else
            fprintf('RSYNC_WARNING: Float #%d: Unable to determine cycle number for file ''%s''\n', ...
               a_floatNum, [g_decArgo_archiveDirectory fileName]);
         end
      else
         % use deployment date
         [error, ...
            configDataStr, ...
            driftMeasDataStr, ...
            profInfoDataStr, ...
            profLowResMeasDataStr, ...
            profHighResMeasDataStr, ...
            gpsFixDataStr, ...
            engineeringDataStr, ...
            nearSurfaceDataStr ...
            ] = read_apx_ir_rudics_msg_file([g_decArgo_archiveDirectory fileName]);
         if (error == 1)
            fprintf('RSYNC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
               a_floatNum, [g_decArgo_archiveDirectory fileName]);
            continue;
         end
         
         dates = [];
         driftData = parse_apx_ir_drift_data(driftMeasDataStr, a_decoderId);
         if (~isempty(driftData))
            measDates = driftData.dates;
            measDates(find(measDates == driftData.dateList.fillValue)) = [];
            dates = [dates; measDates];
         end
         profInfo = parse_apx_ir_profile_info(profInfoDataStr);
         if (~isempty(profInfo) && isfield(profInfo, 'ProfTime'))
            dates = [dates; profInfo.ProfTime];
         end
         [gpsLocDate, gpsLocLon, gpsLocLat, ...
            gpsLocNbSat, gpsLocAcqTime, ...
            gpsLocFailedAcqTime, gpsLocFailedIce] = parse_apx_ir_gps_fix(gpsFixDataStr);
         if (~isempty(gpsLocDate))
            dates = [dates; gpsLocDate];
         end
         if (isempty(dates))
            % we use NS dates only if there are no more dates in the file
            if (~isempty(nearSurfaceDataStr) && ~isempty(nearSurfaceDataStr{1}))
               [nearSurfData, surfDataBladderDeflated, surfDataBladderInflated] = ...
                  parse_nvs_ir_rudics_near_surface_data(nearSurfaceDataStr, a_decoderId);
               for id = 1:length(nearSurfData)
                  if (~isempty(nearSurfData{id}.dates))
                     measDates = nearSurfData{id}.dates;
                     measDates(find(measDates == nearSurfData{id}.dateList.fillValue)) = [];
                     dates = [dates; measDates];
                  end
               end
               for id = 1:length(surfDataBladderDeflated)
                  if (~isempty(surfDataBladderDeflated{id}.dates))
                     measDates = surfDataBladderDeflated{id}.dates;
                     measDates(find(measDates == surfDataBladderDeflated{id}.dateList.fillValue)) = [];
                     dates = [dates; measDates];
                  end
               end
               for id = 1:length(surfDataBladderInflated)
                  if (~isempty(surfDataBladderInflated{id}.dates))
                     measDates = surfDataBladderInflated{id}.dates;
                     measDates(find(measDates == surfDataBladderInflated{id}.dateList.fillValue)) = [];
                     dates = [dates; measDates];
                  end
               end
            end
         end
         
         cycleNumOutStr = '000';
         if (~any(dates >= a_floatLaunchDate))
            cycleNumOutStr = 'TTT';
         end
         
         idF = strfind(fileName, '_');
         newFileName = [fileName(1:idF(4)) cycleNumOutStr fileName(idF(5):end)];
         if (~strcmp(newFileName, fileName))
            if (exist([g_decArgo_archiveDirectory newFileName], 'file') == 2)
               idF = strfind(newFileName, '_');
               pid = str2double(newFileName(idF(5):end-4));
               cpt = 1;
               while (exist([g_decArgo_archiveDirectory newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)], 'file') == 2)
                  cpt = cpt + 1;
               end
               newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt) newFileName(end-3:end)];
            end
            move_file([g_decArgo_archiveDirectory fileName], [g_decArgo_archiveDirectory newFileName]);
         end
      end
   end
end

% STEP 4: be sure that there is only one msg file per cycle (except for cycle
% #0)

cycleList = [];
fileList = [];
fileNames = dir([g_decArgo_archiveDirectory '*.msg']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   idF1 = strfind(fileName, num2str(a_floatNum));
   idF2 = strfind(fileName, '_');
   idF3 = find(idF2 > idF1);
   cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
   [cyNum, status] = str2num(cyNum);
   if (status)
      cycleList(end+1) = cyNum;
      fileList{end+1} = [g_decArgo_archiveDirectory fileName];
   end
end
uCycleList = unique(cycleList);
nbElts = hist(cycleList, uCycleList);
anomalyCyList = uCycleList(find(nbElts > 1));
if (~isempty(anomalyCyList))
   for cyNum = anomalyCyList
      if (cyNum == 0)
         continue;
      end
      idFCy = find(cycleList == cyNum);
      fprintf('RSYNC_INFO: Float #%d Cycle #%d: %d msg files for this cycle\n', ...
         a_floatNum, cyNum, length(idFCy));
      fileSize = zeros(length(idFCy), 1);
      fileNames = [];
      for idF = 1:length(idFCy)
         filePathName = fileList{idFCy(idF)};
         file = dir(filePathName);
         [~, fileName, fileExt] = fileparts(filePathName);
         %          fprintf('\tFile #%d: %s (%d bytes)\n', ...
         %             idF, ...
         %             [fileName fileExt], ...
         %             file(1).bytes);
         fileSize(idF) = file(1).bytes;
         fileNames{end+1} = filePathName;
      end
      
      [~, idMax] = max(fileSize);
      fileNames(idMax) = [];
      
      % disable remaining files
      for idF = 1:length(fileNames)
         filePathName = fileNames{idF};
         [filePath, fileName, fileExt] = fileparts(filePathName);
         
         idF1 = strfind(fileName, num2str(a_floatNum));
         idF2 = strfind(fileName, '_');
         idF3 = find(idF2 > idF1);
         fileNameOut = [fileName(1:idF2(idF3(1))) 'UUU' fileName(idF2(idF3(2)):end)];
         
         move_file(filePathName, [filePath '/' fileNameOut fileExt]);
         %          fprintf('\t=> File %s moved to %s\n', ...
         %             [fileName fileExt], ...
         %             [fileNameOut fileExt]);
      end
   end
end

% STEP 4: be sure that there is no duplicates in log files (except for cycle #0)
cycleList = [];
fileList = [];
fileNames = dir([g_decArgo_archiveDirectory '*.log']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   idF1 = strfind(fileName, num2str(a_floatNum));
   idF2 = strfind(fileName, '_');
   idF3 = find(idF2 > idF1);
   cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
   [cyNum, status] = str2num(cyNum);
   if (status)
      cycleList(end+1) = cyNum;
      fileList{end+1} = [g_decArgo_archiveDirectory fileName];
   end
end
uCycleList = unique(cycleList);
nbElts = hist(cycleList, uCycleList);
anomalyCyList = uCycleList(find(nbElts > 1));
if (~isempty(anomalyCyList))
   for cyNum = anomalyCyList
      if (cyNum == 0)
         continue;
      end
      
      printLog = 0;
      log = [];
      
      idFCy = find(cycleList == cyNum);
      log{end+1} = sprintf('RSYNC_INFO: Float #%d Cycle #%d: %d log files for this cycle\n', ...
         a_floatNum, cyNum, length(idFCy));
      fileSize = zeros(length(idFCy), 1);
      filePathNames = [];
      fileNames = [];
      for idF = 1:length(idFCy)
         filePathName = fileList{idFCy(idF)};
         file = dir(filePathName);
         [~, fileName, fileExt] = fileparts(filePathName);
         %          log{end+1} = sprintf('\tFile #%d: %s (%d bytes)\n', ...
         %             idF, ...
         %             [fileName fileExt], ...
         %             file(1).bytes);
         fileSize(idF) = file(1).bytes;
         filePathNames{end+1} = filePathName;
         idF = strfind(fileName, '_');
         fileNames{end+1} = fileName(1:idF(5)-1);
      end
      
      [fileSize, idSort] = sort(fileSize, 'descend');
      filePathNames = filePathNames(idSort);
      fileNames = fileNames(idSort);
      
      stop = 0;
      idRef = 1;
      idNext = idRef + 1;
      while (~stop)
         if (length(fileNames) > idRef)
            if (length(fileNames) >= idNext)
               if (strcmp(fileNames{idRef}, fileNames{idNext}))
                  
                  filePathName = filePathNames{idNext};
                  [filePath, fileName, fileExt] = fileparts(filePathName);
                  
                  idF1 = strfind(fileName, num2str(a_floatNum));
                  idF2 = strfind(fileName, '_');
                  idF3 = find(idF2 > idF1);
                  fileNameOut = [fileName(1:idF2(idF3(1))) 'UUU' fileName(idF2(idF3(2)):end)];
                  
                  move_file(filePathName, [filePath '/' fileNameOut fileExt]);
                  %                   log{end+1} = sprintf('\t=> File %s moved to %s\n', ...
                  %                      [fileName fileExt], ...
                  %                      [fileNameOut fileExt]);
                  printLog = 1;
                  
                  fileSize(idNext) = [];
                  filePathNames(idNext) = [];
                  fileNames(idNext) = [];
               else
                  idNext = idNext + 1;
               end
            else
               idRef = idRef + 1;
               idNext = idRef + 1;
            end
         else
            stop = 1;
         end
      end
      
      if (printLog)
         fprintf('%s', log{:});
      end
   end
end

return;

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
            break;
         end
      end
      if (deleteFlag == 1)
         break;
      end
   end
   if (deleteFlag == 0)
      stop = 1;
   end
end

return;

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
   return;
end
file1Contents = textscan(fid, '%s');
file1Contents = file1Contents{:};
fclose(fid);

fid = fopen(a_fileName2, 'r');
if (fid == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_fileName2);
   return;
end
file2Contents = textscan(fid, '%s');
file2Contents = file2Contents{:};
fclose(fid);

if ((length(file1Contents) == length(file2Contents)) && ...
      ~any(strcmp(file1Contents, file2Contents) ~= 1))
   o_identical = 1;
end

return;
