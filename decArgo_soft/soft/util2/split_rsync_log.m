% ------------------------------------------------------------------------------
% Reprocess rsync logs into equally sized files.
%
% SYNTAX :
%   split_rsync_log
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : get_config
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function split_rsync_log

% number of lines for the new logs
NB_LINES = 500;

% rsync log directory to process
rsyncLogDir = 'E:\HDD\rsync_20140519\rsync_list_ori\';

% rsync log directory to store the processed files
rsyncLogDirNew = 'E:\HDD\rsync_20140519\rsync_list_new\';


% collect the rsync logs
rsyncLogFiles = dir([rsyncLogDir '/rsync_*.txt']);
fileName = [];
fileDate = [];
for idFile = 1:length(rsyncLogFiles)
   
   rsyncLogFileName = rsyncLogFiles(idFile).name;
   rsyncLogFileDate = datenum(rsyncLogFileName(7:21), 'yyyymmddTHHMMSS');
   
   fileName{end+1} = rsyncLogFileName;
   fileDate(end+1) = rsyncLogFileDate;
end

% chronologically sort the files
[fileDate, idSort] = sort(fileDate);
fileName = fileName(idSort);

% read the file contents
lines = [];
for idFile = 1:length(fileName)
   fprintf('%d/%d %s\n', idFile, length(fileName), fileName{idFile});
   
   filePathName = [rsyncLogDir '/' fileName{idFile}];
   fId = fopen(filePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file: %s\n', filePathName);
      return;
   end
   
   while (1)
      line = fgetl(fId);
      if (line == -1)
         break;
      end
      lines{end+1} = line;
   end
   
   fclose(fId);
end

% create new rsync log files
nbLine = 0;
nbFile = 0;
if (exist(rsyncLogDirNew, 'dir') == 7)
   rmdir(rsyncLogDirNew, 's');
end
mkdir(rsyncLogDirNew);
filePathName = [rsyncLogDirNew '/' fileName{1}];
fprintf('decode_provor_2_nc_rt(''rsynclog'', ''%s'', ''floatwmo'', ''7900591'')\n', fileName{1});
fId = fopen(filePathName, 'wt');
if (fId == -1)
   fprintf('ERROR: Error while opening file: %s\n', filePathName);
   return;
end
fopenFlag = 1;
for idL = 1:length(lines)
   if (fopenFlag == 0)
      filePathName = [rsyncLogDirNew '/' sprintf('rsync_%s.txt', [datestr(fileDate(1)+nbFile/24, 'yyyymmddTHHMMSS') 'Z'])];
      fprintf('decode_provor_2_nc_rt(''rsynclog'', ''%s'', ''floatwmo'', ''7900591'')\n', ...
         sprintf('rsync_%s.txt', [datestr(fileDate(1)+nbFile/24, 'yyyymmddTHHMMSS') 'Z']));
      fId = fopen(filePathName, 'wt');
      if (fId == -1)
         fprintf('ERROR: Error while opening file: %s\n', filePathName);
         return;
      end
      fopenFlag = 1;
   end
   
   fprintf(fId, '%s\n', lines{idL});
   nbLine = nbLine + 1;
   
   if (nbLine == NB_LINES)
      fclose(fId);
      fopenFlag = 0;
      nbLine = 0;
      nbFile = nbFile + 1;
   end
end
if (fopenFlag == 1)
   fclose(fId);
end

return;
