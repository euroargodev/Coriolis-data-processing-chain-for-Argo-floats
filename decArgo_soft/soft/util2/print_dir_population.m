% ------------------------------------------------------------------------------
% Print the number of files in each sub-directory of a given directory.
%
% SYNTAX :
%   print_dir_population
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
function print_dir_population()

% input directory
INPUT_DIR_NAME = 'E:\HDD\bascule_20140326\message_20140326_by_month\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 


fprintf('Input directory: %s\n', INPUT_DIR_NAME);

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'print_dir_population_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

dirs = dir(INPUT_DIR_NAME);
nbDir = length(dirs);
for idDir = 1:length(dirs)
   
   dirName = dirs(idDir).name;
   dirPathName = [INPUT_DIR_NAME '/' dirName];
   
   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         files2 = dir(dirPathName);
         fprintf('%4d/%4d directory %s: %d files\n', idDir, nbDir, dirName, length(files2)-2);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
