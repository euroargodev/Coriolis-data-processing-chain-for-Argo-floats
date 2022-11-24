% ------------------------------------------------------------------------------
% Check if some directories (of a given top directory) are empty and, if so,
% delete them.
%
% SYNTAX :
%  delete_empty_dir()
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
%   09/14/2016 - RNU - creation
% ------------------------------------------------------------------------------
function delete_empty_dir()

% directory to check
TOP_DIR_INPUT_OUTPUT = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\final_processing_V1\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


currentDate = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'delete_empty_dir_' currentDate '.log'];
diary(logFile);

fprintf('Directory checked: %s\n', TOP_DIR_INPUT_OUTPUT);

% process the directories of the input directory
dirs = dir(TOP_DIR_INPUT_OUTPUT);
nbDirs = length(dirs);
for idDir = 1:nbDirs
   
   dirName = dirs(idDir).name;
   dirPathName = [TOP_DIR_INPUT_OUTPUT '/' dirName];
   
   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))

         dirs2 = dir(dirPathName);
         if (length(dirs2) == 2)
            fprintf('%4d/%4d Directory %s: %d => deleted\n', idDir-2, nbDirs-2, dirName, length(dirs2)-2);
            rmdir(dirPathName);
         else
            fprintf('%4d/%4d Directory %s: %d\n', idDir-2, nbDirs-2, dirName, length(dirs2)-2);
         end
      end
   end
end

fprintf('done\n');

diary off;

return;
