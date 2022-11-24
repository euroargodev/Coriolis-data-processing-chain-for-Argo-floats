% ------------------------------------------------------------------------------
% Compress sub-directories of a given directory.
%
% SYNTAX :
%   compress_directories
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
function compress_directories()

% input directory
% INPUT_DIR_NAME = 'C:\users\RNU\Argo\argos\coriolis\bascule_20140303\message_20140306_by_month_split_raw\';
INPUT_DIR_NAME = 'E:\HDD\bascule_20140326\newfloats\cycle&message_raw_sans_double_cycle\';

% output directory
% OUTPUT_DIR_NAME = 'E:\HDD\message_20140306_by_month_split_raw_zip\';
OUTPUT_DIR_NAME = 'E:\HDD\bascule_20140326\newfloats\cycle&message_raw_sans_double_cycle_zip\';

% directory to store the log file
DIR_LOG_FILE = 'C:\users\RNU\Argo\work\'; 


% create the output directories
if ~(exist(OUTPUT_DIR_NAME, 'dir') == 7)
   mkdir(OUTPUT_DIR_NAME);
end

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'compress_directories_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

dirs = dir(INPUT_DIR_NAME);
nbDir = length(dirs);
for idDir = 1:length(dirs)
   
%    if ((idDir < 376) || (idDir > 380))
%       continue;
%    end
   
   dirName = dirs(idDir).name;
   dirPathName = [INPUT_DIR_NAME '/' dirName];

   fprintf('%d/%d %s\n', idDir, nbDir, dirName);
   
   if (isdir(dirPathName))
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         %          zip([OUTPUT_DIR_NAME '/' dirName '.zip'], dirPathName);
         cmd = ['matlab -nodesktop -nosplash -r "zip(''' [OUTPUT_DIR_NAME '/' dirName '.zip'] ''', ''' dirPathName ''');exit"'];
         [status, result] = system(cmd);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;
