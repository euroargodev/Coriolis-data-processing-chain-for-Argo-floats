function check_easy_one_argo_index

DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';
DIR_DATA_1 = 'C:\Users\jprannou\_DATA\ONE_ARGO\OUT_TMP\OneArgoCoreEov_20241128T190718Z\';
DIR_DATA_2 = 'C:\Users\jprannou\_DATA\ONE_ARGO\OUT_TMP\OneArgoCoreEovLite_20241128T190718Z\';

logFile = [DIR_LOG_FILE '/' 'check_easy_one_argo_index_' datestr(now, 'yyyymmddTHHMMSSZ') '.log'];
diary(logFile);
tic;

for idDir = 1:2
   if (idDir == 1)
      dirName = DIR_DATA_1;
      addStr = '';
   else
      dirName = DIR_DATA_2;
      addStr = '_L';
   end

   fprintf('INFO: Checking directory ''%s''\n', dirName);

   fprintf('Scaning directory ...\n');

   % retrieve directory files

   fileNames = dir([dirName '/*.csv']);
   idIndex = find(contains({fileNames.name}, 'index'));
   if (length(idIndex) ~= 1)
      if (isempty(idIndex))
         fprintf('ERROR: Cannot find index file - exit\n');
         break
      else
         fprintf('ERROR: %d index files found - exit\n', isempty(idIndex));
         break
      end
   end

   fprintf('... done\n');

   % read index file
   indexFile = [dirName '\' fileNames(idIndex).name];

   fprintf('INFO: Reading index file ''%s'' ...\n', fileNames(idIndex).name);

   fId = fopen(indexFile, 'rt');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', indexFile);
      return
   end

   fileNum = 1;
   indexFiles = cell(3000000, 1);
   header = 0;
   lineNum = 0;
   while 1
      line = fgetl(fId);
      if (line == -1)
         break
      end
      lineNum = lineNum + 1;
      if (isempty(line))
         fprintf('ERROR: Empty line #%d\n', lineNum);
         continue
      end
      if (line(1) == '#')
         continue
      elseif (header == 0)
         header = 1;
      else
         infos = split(line, ',');
         if (length(infos) ~= 8)
            fprintf('ERROR: Inconsistent line #%d (''%s'')\n', lineNum, line);
            continue
         end
         indexFiles{fileNum} = [infos{2} '_' infos{3} '_' infos{4} '_' infos{5} addStr '.csv'];
         fileNum = fileNum + 1;
      end
   end

   fclose(fId);

   indexFiles(fileNum:end) = [];

   fprintf('... done (%d lines, %d files)\n', lineNum, fileNum-1);

   fileNames(idIndex) = [];

   if (length(indexFiles) ~= length(fileNames))
      fprintf('ERROR: Inconsistent number of files %d in directory %d in index (%d missing in index)\n', ...
         length(fileNames), length(indexFiles), length(fileNames)-length(indexFiles));
   else
      fprintf('INFO: Same number of files %d\n', length(fileNames));
   end

   idDiff = setdiff({fileNames.name}, indexFiles);
   if (~isempty(idDiff))
      fprintf('ERROR: %d files are in directory only\n', length(idDiff));
      fprintf('%s\n', idDiff{:});
   else
      fprintf('No files of directory that are not in index\n');
   end
   idDiff = setdiff(indexFiles, {fileNames.name});
   if (~isempty(idDiff))
      fprintf('ERROR: %d files are in index only\n', length(idDiff));
      fprintf('%s\n', idDiff{:});
   else
      fprintf('No files of index that are not in directory\n');
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

