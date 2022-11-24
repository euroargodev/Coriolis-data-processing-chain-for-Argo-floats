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
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\fichiers_cycle_non_identifiés_119Apex\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\split_raw_sans_doubles_FINAL_119Apex\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\zzz\zzzz\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\recup_mail_VB_20160830\final_processing\';
INPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';

% output directory
% OUTPUT_DIR_NAME = 'E:\HDD\message_20140306_by_month_split_raw_zip\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing_zip1\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\fichiers_cycle_non_identifiés_119Apex_zip\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\split_raw_sans_doubles_FINAL_119Apex_zip\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing_zip\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing_zzzz_zip\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\recup_mail_VB_20160830\final_processing_zip\';
OUTPUT_DIR_NAME = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing_zip\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


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
%       continue
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

return
