% ------------------------------------------------------------------------------
% Duplicate CLS Argos e-mails from a given date.
%
% SYNTAX :
%   copy_archive_message_files
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function copy_archive_message_files()

% input directory
INPUT_DIR_NAME = 'E:\HDD\message_20140306\';

% output directory
OUTPUT_DIR_NAME = 'C:\users\RNU\Argo\argos\coriolis\bascule_20140303\argos_message_20140306_2008_05_new\';


if (nargin ~= 1)
   fprintf('Bad input parameter!\n');
   fprintf('Expecting:\n');
   fprintf('   copy_archive_message_files(start_date) => move message files from start_date\n');
   fprintf('where start_date is provided as strings (format: ''yyyy/mm/dd HH:MM:SS'')\n');
   fprintf('aborted ...\n');
   return
else
   startDate = datenum(varargin{1}, 'yyyy/mm/dd HH:MM:SS');
end

% check the input directory
if ~(exist(INPUT_DIR_NAME, 'dir') == 7)
   fprintf('ERROR: Input directory doesn''t exist - exit\n');
   return
end

% create the output directory
if ~(exist(OUTPUT_DIR_NAME, 'dir') == 7)
   fprintf('Creating directory %s\n', OUTPUT_DIR_NAME);
   mkdir(OUTPUT_DIR_NAME);
end

% process the files of the input directory
nbCopied = 0;
nbCopiedNoDate = 0;
fprintf('Checking input directory contents ... ');
tic;
files = dir(INPUT_DIR_NAME);
ellapsedTime = toc;
fprintf('(%.1f min)\n', ellapsedTime/60);
fprintf('Processing files ... ');
tic;
for idF = 1:length(files)
   fileName = files(idF).name;
   filePathName = [INPUT_DIR_NAME '/' fileName];

   if (exist(filePathName, 'file') == 2)
      
      if (length(fileName) >= 12)
         [val1, count1, errmsg1, nextindex1] = sscanf(fileName(1:12), 'co_%d_');
         if ((isempty(errmsg1) && (count1 == 1)))
            fileDate = datenum(fileName(4:11), 'ddmmyyyy');
            if (fileDate >= startDate)
               fileIn = filePathName;
               fileOut = [OUTPUT_DIR_NAME '/' fileName];
               copy_file(fileIn, fileOut);
               nbCopied = nbCopied + 1;
            end
            continue
         end
      end

      if (length(fileName) >= 20)
         [val1, count1, errmsg1, nextindex1] = sscanf(fileName(1:20), 'co_%dT%dZ_');
         if ((isempty(errmsg1) && (count1 == 2)))
            fileDate = datenum(fileName(4:18), 'yyyymmddTHHMMSS');
            if (fileDate >= startDate)
               fileIn = filePathName;
               fileOut = [OUTPUT_DIR_NAME '/' fileName];
               copy_file(fileIn, fileOut);
               nbCopied = nbCopied + 1;
            end
            continue
         end
      end
      
      fileIn = filePathName;
      fileOut = [OUTPUT_DIR_NAME '/' fileName];
      copy_file(fileIn, fileOut);
      nbCopied = nbCopied + 1;
      nbCopiedNoDate = nbCopiedNoDate + 1;
      
   end
end
ellapsedTime = toc;
fprintf('(%.1f min)\n', ellapsedTime/60);

fprintf('%d files copied (%d not dated)\n', nbCopied, nbCopiedNoDate);

fprintf('done\n');

return
