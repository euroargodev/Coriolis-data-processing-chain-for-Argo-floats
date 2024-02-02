% ------------------------------------------------------------------------------
% Duplicate newly received files from Apex APF9 Iridium RUDICS float.
%
% SYNTAX :
 % duplicate_apx_apf9_iridium_rudics_files_float_to_recover( ...
 %   a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDirName, ...
 %   a_maxFileAge, a_floatLaunchDate, a_floatDecId)
%
% INPUT PARAMETERS :
%   a_floatWmo       : float WMO number
%   a_floatLoginName : float login name
%   a_rsyncDir       : RSYNC directory
%   a_spoolDir       : SPOOL directory
%   a_outputDir      : output directory
%   a_maxFileAge     : max age (in hours) of the files to consider
%   a_floatLaunchDate     : float launch data
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/07/2023 - RNU - creation
% ------------------------------------------------------------------------------
function duplicate_apx_apf9_iridium_rudics_files_float_to_recover( ...
   a_floatWmo, a_floatLoginName, a_rsyncDir, a_spoolDir, a_outputDirName, ...
   a_maxFileAge, a_floatLaunchDate, a_floatDecId)

% default values
global g_decArgo_janFirst1950InMatlab;


if ~(exist(a_outputDirName, 'dir') == 7)
   fprintf('Creating directory: %s\n', a_outputDirName);
   mkdir(a_outputDirName);
end

% current date
curUtcDate = now_utc;

% create the output directory of this float
floatOutputDirName = [a_outputDirName '/' a_floatLoginName '_' num2str(a_floatWmo)];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end
floatOutputDirName = [floatOutputDirName '/archive/'];
if ~(exist(floatOutputDirName, 'dir') == 7)
   mkdir(floatOutputDirName);
end

% STEP 1: duplicate and rename input files

for idLoop = 1:2

   if (idLoop == 1)
      fprintf('DIR_INPUT_RSYNC_DATA files (%s):\n', a_rsyncDir);
      inputDir = a_rsyncDir;
   else
      % copy files from SPOOL_DIR
      if (~isempty(a_spoolDir))
         fprintf('SPOOL_DIR files (%s):\n', a_spoolDir);
         inputDir = a_spoolDir;
      else
         continue
      end
   end

   floatInputDirName = [inputDir '/' a_floatLoginName];
   fileNames = dir([floatInputDirName '/' a_floatLoginName '*']);
   nbFiles = 0;
   for idFile = 1:length(fileNames)

      if (fileNames(idFile).bytes == 0)
         fprintf('INFO: Empty file: %s - ignored\n', fileNames(idFile).name);
         continue
      end

      dataFilePathName = [floatInputDirName '/' fileNames(idFile).name];

      if ~(exist(dataFilePathName, 'file') == 2)
         continue
      end

      if ((curUtcDate - fileNames(idFile).datenum) > a_maxFileAge/24)
         continue
      end

      % parse input file name
      [~, dataFileName, dataFileExt] = fileparts(dataFilePathName);
      if (isempty(dataFileExt))
         dataFileExt = '.msg';
      end

      idF = strfind(dataFileName, '_');
      floatId = str2double(dataFileName(1:idF(1)-1));
      pid = 0;
      cycleNumInStr = 'CCC';
      if (length(idF) == 5)
         cycleNumInStr = dataFileName(idF(2)+1:idF(3)-1);
      else
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
            fprintf('ERROR: Float #%d: Error in file ''%s'' - ignored\n', ...
               a_floatWmo, dataFilePathName);
            continue
         end

         dates = [];
         driftData = parse_apx_ir_drift_data(driftMeasDataStr, a_floatDecId);
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
                  parse_nvs_ir_rudics_near_surface_data(nearSurfaceDataStr, a_floatDecId);
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
            fprintf('INFO: Float #%d: No dates in file ''%s'' - ignored\n', ...
               a_floatWmo, dataFilePathName);
            continue
         end

      elseif (strcmp(dataFileExt, '.log'))

         [error, events] = read_apx_ir_rudics_log_file(dataFilePathName);
         if (error == 1)
            fprintf('ERROR: Float #%d: Error in file ''%s'' - ignored\n', ...
               a_floatWmo, dataFilePathName);
            continue
         end

         dates = [events.time];
         date = min(dates);

      else
         fprintf('INFO: Float #%d: Don''t know how to manage file ''%s'' in copy_apx_iridium_rudics_files\n', ...
            a_floatWmo, dataFilePathName);
         continue
      end

      cycleNumOutStr = cycleNumInStr;
      if (any(dates < a_floatLaunchDate))
         cycleNumOutStr = 'TTT';
      end
      % followin lines not suitable for a float to recover
      % if (a_floatEndDate ~= g_decArgo_dateDef)
      %    if (any(dates > a_floatEndDate))
      %       cycleNumOutStr = 'UUU';
      %    end
      % end

      % duplicate and rename the input file name

      outputFileName = sprintf('%04d_%s_%s_%d_%s_%08d', ...
         floatId, ...
         datestr(date + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
         cycleNumInStr, ...
         a_floatWmo, ...
         cycleNumOutStr, ...
         pid);

      if (exist([floatOutputDirName outputFileName dataFileExt], 'file') == 2)
         idF = strfind(outputFileName, '_');
         cpt = 1;
         while (exist([floatOutputDirName outputFileName(1:idF(5)) sprintf('%08d', pid+cpt) dataFileExt], 'file') == 2)
            cpt = cpt + 1;
         end
         outputFileName = [outputFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
      end

      outputFilePathName = [floatOutputDirName outputFileName dataFileExt];
      if (copyfile(dataFilePathName, outputFilePathName) == 0)
         fprintf('ERROR: Float #%d: Error while copying file ''%s''\n', ...
            a_floatWmo, dataFilePathName);
      else
         nbFiles = nbFiles + 1;
      end
   end

   if (idLoop == 1)
      fprintf('INFO: Duplicated (and renamed) %d files from DIR_INPUT_RSYNC_DATA_APF9_RUDICS to DIR_OUTPUT_DATA_APF9_RUDICS dir\n', ...
         nbFiles);
   else
      fprintf('INFO: Duplicated (and renamed) %d files from DIR_INPUT_SPOOL_DATA_APF9_RUDICS to DIR_OUTPUT_DATA_APF9_RUDICS dir\n', ...
         nbFiles);
   end
end

% STEP 2: delete identical files

cyList = [];
fileNames = dir([floatOutputDirName '*.msg']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   cyList{end+1} = fileName(26:28);
end
cyList = unique(cyList);
for idCy = 1:length(cyList)
   fileNames = dir([floatOutputDirName '*_*_' cyList{idCy} '_*_*_*.msg']);
   if (length(fileNames) > 1)
      fileList = {fileNames.name};
      fileListDelete = compare_files(floatOutputDirName, fileList);
      for idFile = 1:length(fileListDelete)
         fprintf('INFO: Float #%d: Deleting file ''%s''\n', ...
            a_floatWmo, [floatOutputDirName fileListDelete{idFile}]);
         delete([floatOutputDirName fileListDelete{idFile}]);
      end
   end
end

cyList = [];
fileNames = dir([floatOutputDirName '*.log']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   cyList{end+1} = fileName(26:28);
end
cyList = unique(cyList);
for idCy = 1:length(cyList)
   fileNames = dir([floatOutputDirName '*_*_' cyList{idCy} '_*_*_*.log']);
   if (length(fileNames) > 1)
      fileList = {fileNames.name};
      fileListDelete = compare_files(floatOutputDirName, fileList);
      for idFile = 1:length(fileListDelete)
         fprintf('INFO: Float #%d: Deleting file ''%s''\n', ...
            a_floatWmo, [floatOutputDirName fileListDelete{idFile}]);
         delete([floatOutputDirName fileListDelete{idFile}]);
      end
   end
end

% STEP 4: be sure that there is no duplicates in log files (except for cycle #0)
cycleList = [];
fileList = [];
floatNumStr = num2str(a_floatWmo);
fileNames = dir([floatOutputDirName '/' sprintf('%04d', floatId) '*' floatNumStr '*.log']);
for idFile = 1:length(fileNames)
   fileName = fileNames(idFile).name;
   idF1 = strfind(fileName, floatNumStr);
   idF2 = strfind(fileName, '_');
   idF3 = find(idF2 > idF1);
   cyNum = fileName(idF2(idF3(1))+1:idF2(idF3(2))-1);
   [cyNum, status] = str2num(cyNum);
   if (status)
      cycleList(end+1) = cyNum;
      fileList{end+1} = [floatOutputDirName '/' fileName];
   end
end
uCycleList = unique(cycleList);
nbElts = hist(cycleList, uCycleList);
anomalyCyList = uCycleList(find(nbElts > 1));
if (~isempty(anomalyCyList))
   for cyNum = anomalyCyList
      if (cyNum == 0)
         continue
      end

      printLog = 0;
      log = [];

      idFCy = find(cycleList == cyNum);
      log{end+1} = sprintf('INFO: Float #%d Cycle #%d: %d log files for this cycle\n', ...
         a_floatWmo, cyNum, length(idFCy));
      fileSize = zeros(length(idFCy), 1);
      filePathNames = [];
      fileNames = [];
      for idF = 1:length(idFCy)
         filePathName = fileList{idFCy(idF)};
         file = dir(filePathName);
         [~, fileName, fileExt] = fileparts(filePathName);
         log{end+1} = sprintf('\tFile #%d: %s (%d bytes)\n', ...
            idF, ...
            [fileName fileExt], ...
            file(1).bytes);
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

                  idF1 = strfind(fileName, floatNumStr);
                  idF2 = strfind(fileName, '_');
                  idF3 = find(idF2 > idF1);
                  fileNameOut = [fileName(1:idF2(idF3(1))) 'UUU' fileName(idF2(idF3(2)):end)];

                  move_file(filePathName, [filePath '/' fileNameOut fileExt]);
                  log{end+1} = sprintf('\t=> File %s moved to %s\n', ...
                     [fileName fileExt], ...
                     [fileNameOut fileExt]);
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
