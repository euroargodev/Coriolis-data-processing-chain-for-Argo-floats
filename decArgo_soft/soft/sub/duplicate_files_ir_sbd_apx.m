% ------------------------------------------------------------------------------
% Rename (and concat if needed) raw .msg and .log ASCII files so that they
% can be processed by the decoder.
%
% SYNTAX :
%  [o_nbMsgFiles, o_nbLogFiles] = duplicate_files_ir_sbd_apx( ...
%    a_floatNum, a_decoderId, ...
%    a_floatLaunchDate, a_floatEndDate, a_inputDirName, a_outputDirName)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_decoderId       : float decoder Id
%   a_floatLaunchDate : float launch date
%   a_floatEndDate    : float end decoding date
%   a_inputDirName    : input directory
%   a_outputDirName   : output directory
%
% OUTPUT PARAMETERS :
%   o_nbMsgFiles : number of final .msg files
%   o_nbLogFiles : number of final .log files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/03/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_nbMsgFiles, o_nbLogFiles] = duplicate_files_ir_sbd_apx( ...
   a_floatNum, a_decoderId, ...
   a_floatLaunchDate, a_floatEndDate, a_inputDirName, a_outputDirName)

% output parameters initialization
o_nbMsgFiles = 0;
o_nbLogFiles = 0;

% default values
global g_decArgo_dateDef;
global g_decArgo_janFirst1950InMatlab;


% fileInfoList contains:
% col1: file type (1 for .msg, 2 for .log)
% col2: cycle number (as string)
% col3: min file date (also stored in the file name)
% col4: max file date
% col5: file name
% col6: exist flag (1 if the file still exists, 0 otherwise)
fileInfoList = [];
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 1: duplicate and rename input files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nbFiles = 0;
files = dir(a_inputDirName);
for idFile = 1:length(files)
   
   dataFileName = files(idFile).name;
   if ~(strcmp(dataFileName, '.') || strcmp(dataFileName, '..'))
      
      dataFilePathName = [a_inputDirName '/' dataFileName];
      
      % parse input file name
      [~, dataFileName, dataFileExt] = fileparts(dataFilePathName);
      
      idF = strfind(dataFileName, '.');
      floatId = str2double(dataFileName(1:idF(1)-1));
      pid = 0;
      cycleNumInStr = dataFileName(idF(1)+1:end);
      if (length(cycleNumInStr) == 10)
         cycleNumInStr = 'CCC';
      end
      
      % create the date and the output cycle number to be set in the output file name
      if (strcmp(dataFileExt, '.msg'))
         
         fileType = 1;
         [error, ...
            configDataStr, ...
            driftMeasDataStr, ...
            profInfoDataStr, ...
            profLowResMeasDataStr, ...
            profHighResMeasDataStr, ...
            gpsFixDataStr, ...
            engineeringDataStr, ...
            ] = read_apx_ir_sbd_msg_file(dataFilePathName, a_decoderId, 0);
         if (error == 1)
            fprintf('DEC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
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
            fprintf('DEC_INFO: Float #%d: No dates in file ''%s'' => ignored\n', ...
               a_floatNum, dataFilePathName);
            continue;
         end
         
      elseif (strcmp(dataFileExt, '.log'))
         
         fileType = 2;
         [error, events] = read_apx_ir_sbd_log_file(dataFilePathName);
         if (error == 1)
            fprintf('DEC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
               a_floatNum, dataFilePathName);
            continue;
         end
         
         dates = [events.time];
         
      else
         fprintf('DEC_INFO: Float #%d: Don''t know how to manage file ''%s'' in duplicate_files_ir_sbd_apx\n', ...
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
         datestr(min(dates) + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS'), ...
         cycleNumInStr, ...
         a_floatNum, ...
         cycleNumOutStr, ...
         pid);
      
      if (exist([a_outputDirName outputFileName dataFileExt], 'file') == 2)
         idF = strfind(outputFileName, '_');
         cpt = 1;
         while (exist([a_outputDirName outputFileName(1:idF(5)) sprintf('%08d', pid+cpt) dataFileExt], 'file') == 2)
            cpt = cpt + 1;
         end
         outputFileName = [outputFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
      end
      
      outputFilePathName = [a_outputDirName outputFileName dataFileExt];
      if (copyfile(dataFilePathName, outputFilePathName) == 0)
         fprintf('DEC_ERROR: Float #%d: Error while copying file ''%s''\n', ...
            a_floatNum, dataFilePathName);
      else
         nbFiles = nbFiles + 1;
         fileInfoList = [fileInfoList; ...
            fileType {cycleNumOutStr} {min(dates)} {max(dates)} {[outputFileName dataFileExt]} 1];
      end
   end
end

% 'TTT' and 'UUU' files are not managed anymore
idDel = find(strcmp(fileInfoList(:, 2), 'TTT') | ...
   strcmp(fileInfoList(:, 2), 'UUU'));
fileInfoList(idDel, :) = [];

% sort files according to min date (easier to debug)
[~, idSort] = sort([fileInfoList{:, 3}]);
fileInfoList = fileInfoList(idSort, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 2: split log files with unknown cycle numbers (if needed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

idFileNoCyLog = find((cell2mat(fileInfoList(:, 1)) == 2) & strcmp(fileInfoList(:, 2), 'CCC'));
for idFile = 1:length(idFileNoCyLog)
   
   curFileId = idFileNoCyLog(idFile);
   
   % check if log file needs to be split and retrieve associated cycle number(s)
   [cyNumList, startLine, endLine] = check_apx_ir_log_file( ...
      [a_outputDirName fileInfoList{curFileId, 5}]);
   
   if (length(cyNumList) == 1)
      
      % no need to split current log file
      cyNumStr = cyNumList{1};
      if (~strcmp(cyNumStr, 'CCC'))
         
         % assign associated cycle number to current file
         fileName = fileInfoList{curFileId, 5};
         idF = strfind(fileName, '_');
         newFileName = [fileName(1:idF(4)) cyNumStr fileName(idF(5):end-4)];
         if (exist([a_outputDirName newFileName '.log'], 'file') == 2)
            cpt = 1;
            while (exist([a_outputDirName newFileName(1:idF(5)) sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
               cpt = cpt + 1;
            end
            newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
         end
         newFileName = [newFileName '.log'];
         move_file([a_outputDirName fileName], [a_outputDirName newFileName]);
         
         fileInfoList{curFileId, 2} = cyNumStr;
         fileInfoList{curFileId, 5} = newFileName;
      end
   else
      
      % current log file should be split
      
      % move current file to temporary file
      fileName = fileInfoList{curFileId, 5};
      fileNameTmp2 = fileName;
      fileNameTmp2 = [fileNameTmp2(1:end-4) '_TMP2' fileNameTmp2(end-3:end)];
      move_file([a_outputDirName fileInfoList{curFileId, 5}], [a_outputDirName fileNameTmp2]);
      fileInfoList{curFileId, 6} = 0;
      
      % split file
      for idFSplit = 1:length(cyNumList)
         
         cyNumStr = cyNumList{idFSplit};
         
         split_apx_ir_log_file([a_outputDirName fileNameTmp2], ...
            [a_outputDirName fileName], startLine(idFSplit), endLine(idFSplit));
         
         % get dates of the new file
         [error, events] = read_apx_ir_sbd_log_file([a_outputDirName fileName]);
         dates = [events.time];
         
         % create new log file
         idF = strfind(fileName, '_');
         newFileName = [fileName(1:idF(1)) ...
            sprintf('%s', datestr(min(dates) + g_decArgo_janFirst1950InMatlab, 'yyyy-mm-dd-HH-MM-SS')) ...
            fileName(idF(2):idF(4)) cyNumStr fileName(idF(5):end-4)];
         if (exist([a_outputDirName newFileName '.log'], 'file') == 2)
            cpt = 1;
            while (exist([a_outputDirName newFileName(1:idF(5)) sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
               cpt = cpt + 1;
            end
            newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
         end
         newFileName = [newFileName '.log'];
         
         move_file([a_outputDirName fileName], [a_outputDirName newFileName]);
         
         fileInfoList = [fileInfoList; ...
            2 cyNumStr {min(dates)} {max(dates)} {newFileName} 1];
      end
      
      delete([a_outputDirName fileNameTmp2]);
   end
end

% delete not existing files
idDel = find(cell2mat(fileInfoList(:, 6)) == 0);
fileInfoList(idDel, :) = [];

% sort files according to min date
[~, idSort] = sort([fileInfoList{:, 3}]);
fileInfoList = fileInfoList(idSort, :);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 3: set remaining unknown cycle numbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process msg files
idFileNoCyMsg = find((cell2mat(fileInfoList(:, 1)) == 1) & strcmp(fileInfoList(:, 2), 'CCC'));
for idFile = 1:length(idFileNoCyMsg)
   
   done = 0;
   curFileId = idFileNoCyMsg(idFile);
   
   % find first msg file with max date before current file min date
   idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
      ~strcmp(fileInfoList(:, 2), 'CCC') & ...
      (cell2mat(fileInfoList(:, 4)) < fileInfoList{curFileId, 3}));
   if (~isempty(idF))
      
      cyNumStr = fileInfoList{idF(end), 2};
      
      % assign associated cycle number to current file
      fileName = fileInfoList{curFileId, 5};
      idF = strfind(fileName, '_');
      newFileName = [fileName(1:idF(4)) cyNumStr fileName(idF(5):end-4)];
      if (exist([a_outputDirName newFileName '.msg'], 'file') == 2)
         cpt = 1;
         while (exist([a_outputDirName newFileName(1:idF(5)) sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
            cpt = cpt + 1;
         end
         newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
      end
      newFileName = [newFileName '.msg'];
      move_file([a_outputDirName fileName], [a_outputDirName newFileName]);
      
      fileInfoList{curFileId, 2} = cyNumStr;
      fileInfoList{curFileId, 5} = newFileName;
      done = 1;
   else
      
      % find first file with min date after current file max date
      idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
         ~strcmp(fileInfoList(:, 2), 'CCC') & ...
         (cell2mat(fileInfoList(:, 3)) > fileInfoList{curFileId, 4}));
      if (~isempty(idF))
         
         cyNumStr = fileInfoList{idF(1), 2};
         cyNum = str2num(cyNumStr);
         if (cyNum > 0)
            cyNumStr = sprintf('%03d', cyNum-1);
         end
         
         % assign current file cycle number to previous cycle
         fileName = fileInfoList{curFileId, 5};
         idF = strfind(fileName, '_');
         newFileName = [fileName(1:idF(4)) cyNumStr fileName(idF(5):end-4)];
         if (exist([a_outputDirName newFileName '.msg'], 'file') == 2)
            cpt = 1;
            while (exist([a_outputDirName newFileName(1:idF(5)) sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
               cpt = cpt + 1;
            end
            newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
         end
         newFileName = [newFileName '.msg'];
         move_file([a_outputDirName fileName], [a_outputDirName newFileName]);
         
         fileInfoList{curFileId, 2} = cyNumStr;
         fileInfoList{curFileId, 5} = newFileName;
         done = 1;
      end
   end
   
   if (done == 0)
      fprintf('DEC_WARNING: Float #%d: Unable to determine cycle number for file ''%s''\n', ...
         a_floatNum, [a_outputDirName fileInfoList{curFileId, 5}]);
   end
end

% process log files
idFileNoCyLog = find((cell2mat(fileInfoList(:, 1)) == 2) & strcmp(fileInfoList(:, 2), 'CCC'));
for idFile = 1:length(idFileNoCyLog)
   
   done = 0;
   curFileId = idFileNoCyLog(idFile);
   
   % find first msg file with max date before current file min date
   idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
      ~strcmp(fileInfoList(:, 2), 'CCC') & ...
      (cell2mat(fileInfoList(:, 4)) < fileInfoList{curFileId, 3}));
   if (~isempty(idF))
      
      cyNumStr = fileInfoList{idF(end), 2};
      
      % assign associated cycle number to current file
      fileName = fileInfoList{curFileId, 5};
      idF = strfind(fileName, '_');
      newFileName = [fileName(1:idF(4)) cyNumStr fileName(idF(5):end-4)];
      if (exist([a_outputDirName newFileName '.log'], 'file') == 2)
         cpt = 1;
         while (exist([a_outputDirName newFileName(1:idF(5)) sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
            cpt = cpt + 1;
         end
         newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
      end
      newFileName = [newFileName '.log'];
      move_file([a_outputDirName fileName], [a_outputDirName newFileName]);
      
      fileInfoList{curFileId, 2} = cyNumStr;
      fileInfoList{curFileId, 5} = newFileName;
      done = 1;
   else
      
      % find first file with min date after current file max date
      idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
         ~strcmp(fileInfoList(:, 2), 'CCC') & ...
         (cell2mat(fileInfoList(:, 3)) > fileInfoList{curFileId, 4}));
      if (~isempty(idF))
         
         cyNumStr = fileInfoList{idF(1), 2};
         cyNum = str2num(cyNumStr);
         if (cyNum > 0)
            cyNumStr = sprintf('%03d', cyNum-1);
         end
         
         % assign current file cycle number to previous cycle
         fileName = fileInfoList{curFileId, 5};
         idF = strfind(fileName, '_');
         newFileName = [fileName(1:idF(4)) cyNumStr fileName(idF(5):end-4)];
         if (exist([a_outputDirName newFileName '.log'], 'file') == 2)
            cpt = 1;
            while (exist([a_outputDirName newFileName(1:idF(5)) sprintf('%08d', pid+cpt) '.log'], 'file') == 2)
               cpt = cpt + 1;
            end
            newFileName = [newFileName(1:idF(5)) sprintf('%08d', pid+cpt)];
         end
         newFileName = [newFileName '.log'];
         move_file([a_outputDirName fileName], [a_outputDirName newFileName]);
         
         fileInfoList{curFileId, 2} = cyNumStr;
         fileInfoList{curFileId, 5} = newFileName;
         done = 1;
      end
   end
   
   if (done == 0)
      fprintf('DEC_WARNING: Float #%d: Unable to determine cycle number for file ''%s''\n', ...
         a_floatNum, [a_outputDirName fileInfoList{curFileId, 5}]);
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 4: delete identical files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process msg files
idDel = [];
idF = find((cell2mat(fileInfoList(:, 1)) == 1));
cyList = fileInfoList(idF, 2);
cyList = unique(cyList);
for idCy = 1:length(cyList)
   idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
      strcmp(fileInfoList(:, 2), cyList{idCy}));
   fileNames = fileInfoList(idF, 5);
   if (length(fileNames) > 1)
      fileListDelete = compare_files(a_outputDirName, fileNames);
      for idFile = 1:length(fileListDelete)
         fprintf('DEC_INFO: Float #%d: Deleting file ''%s''\n', ...
            a_floatNum, [a_outputDirName fileListDelete{idFile}]);
         delete([a_outputDirName fileListDelete{idFile}]);
         idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
            strcmp(fileInfoList(:, 5), fileListDelete{idFile}));
         idDel = [idDel idF];
      end
   end
end
fileInfoList(idDel, :) = [];

% process log files
idDel = [];
idF = find((cell2mat(fileInfoList(:, 1)) == 2));
cyList = fileInfoList(idF, 2);
cyList = unique(cyList);
for idCy = 1:length(cyList)
   idF = find((cell2mat(fileInfoList(:, 1)) == 2) & ...
      strcmp(fileInfoList(:, 2), cyList{idCy}));
   fileNames = fileInfoList(idF, 5);
   if (length(fileNames) > 1)
      fileListDelete = compare_files(a_outputDirName, fileNames);
      for idFile = 1:length(fileListDelete)
         fprintf('DEC_INFO: Float #%d: Deleting file ''%s''\n', ...
            a_floatNum, [a_outputDirName fileListDelete{idFile}]);
         delete([a_outputDirName fileListDelete{idFile}]);
         idF = find((cell2mat(fileInfoList(:, 1)) == 2) & ...
            strcmp(fileInfoList(:, 5), fileListDelete{idFile}));
         idDel = [idDel idF];
      end
   end
end
fileInfoList(idDel, :) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STEP 5: create a unique msg and log file per cycle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% process msg files
idF = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
   ~strcmp(fileInfoList(:, 2), 'CCC'));
cyList = fileInfoList(idF, 2);
cyList = unique(cyList);
for idCy = 1:length(cyList)
   
   curCyNumStr = cyList{idCy};
   
   % retrieve msg files with the current cycle number
   idFFiles = find((cell2mat(fileInfoList(:, 1)) == 1) & ...
      strcmp(fileInfoList(:, 2), curCyNumStr) & ...
      (cell2mat(fileInfoList(:, 6)) == 1));
   if (length(idFFiles) > 1)
      
      % cancatenate files
      fileName = fileInfoList{idFFiles(1), 5};
      fileNameTmp = [fileName(1:end-4) '_TMP' fileName(end-3:end)];
      concat_files(a_outputDirName, fileInfoList(idFFiles, 5), a_outputDirName, fileNameTmp);
      
      for idFile = 1:length(idFFiles)
         delete([a_outputDirName fileInfoList{idFFiles(idFile), 5}]);
         if (idFile > 1)
            fileInfoList{idFFiles(idFile), 6} = 0;
         end
      end
      
      move_file([a_outputDirName fileNameTmp], [a_outputDirName fileName]);
      fileInfoList{curFileId, 4} = max([fileInfoList{idFFiles, 4}]);
   end  
end

% process log files
idF = find((cell2mat(fileInfoList(:, 1)) == 2) & ...
   ~strcmp(fileInfoList(:, 2), 'CCC'));
cyList = fileInfoList(idF, 2);
cyList = unique(cyList);
for idCy = 1:length(cyList)
   
   curCyNumStr = cyList{idCy};
   
   % retrieve log files with the current cycle number
   idFFiles = find((cell2mat(fileInfoList(:, 1)) == 2) & ...
      strcmp(fileInfoList(:, 2), curCyNumStr) & ...
      (cell2mat(fileInfoList(:, 6)) == 1));
   if (length(idFFiles) > 1)
      
      % cancatenate files
      fileName = fileInfoList{idFFiles(1), 5};
      fileNameTmp = [fileName(1:end-4) '_TMP' fileName(end-3:end)];
      concat_files(a_outputDirName, fileInfoList(idFFiles, 5), a_outputDirName, fileNameTmp);
      
      for idFile = 1:length(idFFiles)
         delete([a_outputDirName fileInfoList{idFFiles(idFile), 5}]);
         if (idFile > 1)
            fileInfoList{idFFiles(idFile), 6} = 0;
         end
      end
      
      move_file([a_outputDirName fileNameTmp], [a_outputDirName fileName]);
      fileInfoList{curFileId, 4} = max([fileInfoList{idFFiles, 4}]);
   end  
end

% delete not existing files
idDel = find(cell2mat(fileInfoList(:, 6)) == 0);
fileInfoList(idDel, :) = [];

o_nbMsgFiles = length(find((cell2mat(fileInfoList(:, 1)) == 1) & ...
   ~strcmp(fileInfoList(:, 2), 'CCC')));
o_nbLogFiles = length(find((cell2mat(fileInfoList(:, 1)) == 2) & ...
   ~strcmp(fileInfoList(:, 2), 'CCC')));

% should be disabled once validated
FINAL_CHECK = 0;
if (FINAL_CHECK)
   
   checkDates = [];
   files = dir(a_outputDirName);
   for idFile = 1:length(files)
      
      dataFileName = files(idFile).name;
      if ~(strcmp(dataFileName, '.') || strcmp(dataFileName, '..'))
         
         dataFilePathName = [a_outputDirName '/' dataFileName];
         
         idF = strfind(dataFileName, '_');
         cyNumStr = dataFileName(idF(4)+1:idF(5)-1);
         cyNum = str2num(cyNumStr);
                  
         % retrieve the dates of the file
         dataFileExt = dataFileName(end-3:end);
         if (strcmp(dataFileExt, '.msg'))
            
            fileType = 1;
            [error, ...
               configDataStr, ...
               driftMeasDataStr, ...
               profInfoDataStr, ...
               profLowResMeasDataStr, ...
               profHighResMeasDataStr, ...
               gpsFixDataStr, ...
               engineeringDataStr, ...
               ] = read_apx_ir_sbd_msg_file(dataFilePathName, a_decoderId, 0);
            if (error == 1)
               fprintf('DEC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
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
               fprintf('DEC_INFO: Float #%d: No dates in file ''%s'' => ignored\n', ...
                  a_floatNum, dataFilePathName);
               continue;
            end
            
         elseif (strcmp(dataFileExt, '.log'))
            
            fileType = 2;
            [error, events] = read_apx_ir_sbd_log_file(dataFilePathName);
            if (error == 1)
               fprintf('DEC_ERROR: Float #%d: Error in file ''%s'' => ignored\n', ...
                  a_floatNum, dataFilePathName);
               continue;
            end
            
            dates = [events.time]';
            
         else
            fprintf('DEC_INFO: Float #%d: Don''t know how to manage file ''%s'' in duplicate_files_ir_sbd_apx\n', ...
               a_floatNum, dataFilePathName);
            continue;
         end
         
         checkDates = [checkDates;
            ones(length(dates), 1)*fileType ones(length(dates), 1)*cyNum dates];
      end
   end
   
   [~, idSort] = sort(checkDates(:, 3));
   checkDates = checkDates(idSort, :);
   idF = find(checkDates < 0);
   if (~isempty(idF))
      fprintf('ERROR: Float #%d: Inconsistencies in cycle assignement in duplicate_files_ir_sbd_apx\n', ...
         a_floatNum);
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
