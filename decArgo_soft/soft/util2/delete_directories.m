% ------------------------------------------------------------------------------
% Delete sub-directories of a given directory.
%
% SYNTAX :
%   delete_directories
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
function delete_directories()

% input directory
INPUT_DIR_NAME = 'C:\users\RNU\Argo\argos\coriolis\bascule_20140303\argos_cycle_20140303_copy_split_raw\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 


% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'delete_directories_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

dirs = dir(INPUT_DIR_NAME);
nbDir = length(dirs);
for idDir = 1:nbDir
      
   dirName = dirs(idDir).name;
   dirPathName = [INPUT_DIR_NAME '/' dirName];

   fprintf('%d/%d %s\n', idDir, nbDir, dirName);
   
   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         tic;
         rmdir(dirPathName, 's');
         ellapsedTime = toc;
         fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
      end
   end
end

diary off;

return;
