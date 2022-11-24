% ------------------------------------------------------------------------------
% Move CLS Argos e-mails to directories (1 directory per month).
%
% SYNTAX :
%   move_archive_message_files
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
function move_archive_message_files()

% input directory
INPUT_DIR_NAME = 'E:\HDD\bascule_20140326\message_20140326\';

% output directory
OUTPUT_DIR_NAME = 'E:\HDD\bascule_20140326\message_20140326_by_month\';


% check the input directory
% if ~(exist(INPUT_DIR_NAME, 'dir') == 7)
%    fprintf('ERROR: Input directory doesn''t exist => exit\n');
%    return;
% end

% create the output directory
if ~(exist(OUTPUT_DIR_NAME, 'dir') == 7)
   fprintf('Creating directory %s\n', OUTPUT_DIR_NAME);
   mkdir(OUTPUT_DIR_NAME);
end

tic;

% process the files of the input directory
nbMoved = 0;
files = dir(INPUT_DIR_NAME);
for idF = 1:length(files)
   
   fileName = files(idF).name;
   filePathName = [INPUT_DIR_NAME '/' fileName];

   if (exist(filePathName, 'file') == 2)
      
      if (length(fileName) >= 12)
         [val1, count1, errmsg1, nextindex1] = sscanf(fileName(1:12), 'co_%d_');
         if ((isempty(errmsg1) && (count1 == 1)))
            month = fileName(6:7);
            year = fileName(8:11);

            dirName = [OUTPUT_DIR_NAME '/' year '_' month '/'];
            % create the output directory
            if ~(exist(dirName, 'dir') == 7)
               fprintf('Creating directory %s\n', dirName);
               mkdir(dirName);
            end

            move_file(filePathName, [dirName '/' fileName]);
            nbMoved = nbMoved + 1;
            continue;
         end
      end

      if (length(fileName) >= 20)
         [val1, count1, errmsg1, nextindex1] = sscanf(fileName(1:20), 'co_%dT%dZ_');
         if ((isempty(errmsg1) && (count1 == 2)))
            year = fileName(4:7);
            month = fileName(8:9);

            dirName = [OUTPUT_DIR_NAME '/' year '_' month '/'];
            % create the output directory
            if ~(exist(dirName, 'dir') == 7)
               fprintf('Creating directory %s\n', dirName);
               mkdir(dirName);
            end

            move_file(filePathName, [dirName '/' fileName]);
            nbMoved = nbMoved + 1;
            continue;
         end
      end
      
      dirName = [OUTPUT_DIR_NAME '/no_date/'];
      % create the output directory
      if ~(exist(dirName, 'dir') == 7)
         fprintf('Creating directory %s\n', dirName);
         mkdir(dirName);
      end

      move_file(filePathName, [dirName '/' fileName]);
      nbMoved = nbMoved + 1;
      
   end
end

fprintf('\n\n%d files moved\n\n\n', nbMoved);

% files = dir(OUTPUT_DIR_NAME);
% for idF = 1:length(files)
%    
%    dirName = files(idF).name;
%    dirPathName = [OUTPUT_DIR_NAME '/' dirName];
% 
%    if (isdir(dirPathName))
%       if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
%          files2 = dir(dirPathName);
%          fprintf('directory %s: %d files\n', dirName, length(files2)-2);
%       end
%    end
% end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

return;
