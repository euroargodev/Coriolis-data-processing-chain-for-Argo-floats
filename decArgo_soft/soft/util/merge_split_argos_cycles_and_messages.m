% ------------------------------------------------------------------------------
% Merge 2 sets of split files (one file for each satellite pass) provided
% in 2 directories.
%
% SYNTAX :
%   merge_split_argos_cycles_and_messages
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
function merge_split_argos_cycles_and_messages()

DIR_BASE_ARGOS_FILES = 'E:\HDD\bascule_20140326\newfloats\cycle\';
DIR_NEW_ARGOS_FILES = 'E:\HDD\bascule_20140326\newfloats\message\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\';


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'merge_split_argos_cycles_and_messages_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the directories of the new files directory
newDirs = dir(DIR_NEW_ARGOS_FILES);
nbNewDirs = length(newDirs);
for idNewDir = 1:nbNewDirs

   newDirName = newDirs(idNewDir).name;
   newDirPathName = [DIR_NEW_ARGOS_FILES '/' newDirName];

   if (isdir(newDirPathName))
      if ~(strcmp(newDirName, '.') || strcmp(newDirName, '..'))
         
         fprintf('%03d/%03d Processing new directory %s\n', idNewDir, nbNewDirs, newDirName);

         % check if this disrectory exists in the base dir
         baseDir = [DIR_BASE_ARGOS_FILES '/' newDirName];
         if (isdir(baseDir))
      
            % add the files of the new dir in the base dir
            newFiles = dir(newDirPathName);
            nbNewFiles = length(newFiles);
            for idNewFile = 1:nbNewFiles

               newFileName = newFiles(idNewFile).name;
               newFilePathName = [newDirPathName '/' newFileName];

               if (exist(newFilePathName, 'file') == 2)
                  
                  % find a suitable name
                  if (length(newFileName) > 26)
                     pattern = newFileName(1:26);
                  else
                     pattern = newFileName(1:6);
                  end
                  
                  stop = 0;
                  fileNum = 1;
                  while (~stop)
                     filePathName = [baseDir '/' sprintf('%s_%03d.txt', pattern, fileNum)];
                     if (exist(filePathName, 'file') == 2)
                        fileNum = fileNum + 1;
                     else
                        stop = 1;
                     end
                     if (fileNum == 1000)
                        fprintf('ERROR: Unable to find an output file name %s\n', filePathName);
                     end
                  end
                  
                  % move the new file in the base dir
                  move_file(newFilePathName, filePathName);
               end
            end
         else
            % move the new dir in the base dir
            move_file(newDirPathName, DIR_BASE_ARGOS_FILES);
         end
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
