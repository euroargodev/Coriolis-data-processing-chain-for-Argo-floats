% ------------------------------------------------------------------------------
% Split Argos message files (one file for each Argos Id and each satellite
% pass).
%
% SYNTAX :
%   split_argos_messages or split_argos_messages(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
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
function split_argos_messages(varargin)

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\archive_message_20160208\ori\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\archive_cycle\ori_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160208\historical_processing\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\tmp\ori\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\tmp\ori_split\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\archive_message_20160823\ori\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\archive_cycle_20160823\ori_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing\';
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\spool_20160824\ori_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160823\historical_processing\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\spool_20160824\ori_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\archive_message_20160823\ori\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\archive_cycle_all_20160823\ori_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\archive_message_collecte_V1_20160829\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\historical_processing_V1\';
% 
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\archive_message_new_collecte_V1_20160829\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\historical_processing_V1\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\archive_cycle_back_collecte_V1_20160829\zz\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\final_processing_V1\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\archive_cycle_collecte_V1_20160829\zz\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\final_processing_V1\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\archive_message_refused_collecte_V1_20160829\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\historical_processing_V1\';
% 
% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\spool_V1_20160829\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\historical_processing_V1\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\recup_mail_VB_20160830\final_processing\ori_CORRECT\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';

DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\COLLECTE_V1\final_processing_V1\zz\';
DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_ALL\historical_processing\';

% DIR_INPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\processing_all_v1\';
% DIR_OUTPUT_ARGOS_FILES = 'C:\Users\jprannou\_DATA\ArgosApex_processing_20160914\base_traitements_20160823\';


% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';


if ~((nargin == 0) || (nargin == 4))
   fprintf('Bad input parameters!\n');
   fprintf('Expecting:\n');
   fprintf('   split_argos_messages(first_year, first_month, last_year, last_month)\n');
   fprintf('   split_argos_messages\n');
   fprintf('aborted ...\n');
   return;
end
firstYear = [];
firstMonth = [];
lastYear = [];
lastMonth = [];
if (nargin == 4)
   firstYear = varargin{1};
   firstMonth = varargin{2};
   lastYear = varargin{3};
   lastMonth = varargin{4};
end

% create the output directory
if ~(exist(DIR_OUTPUT_ARGOS_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_ARGOS_FILES);
end

% create and start log file recording
name = [];
if (nargin == 4)
   name = sprintf('_%04d-%02d_%04d-%02d', ...
      firstYear, firstMonth, lastYear, lastMonth);
end

currentDate = datestr(now, 'yyyymmddTHHMMSS');
logFile = [DIR_LOG_FILE '/' 'split_argos_messages' name '_' currentDate '.log'];
diary(logFile);

% process the directories of the input directory
if (nargin == 0)
   dirs = dir(DIR_INPUT_ARGOS_FILES);
   nbDirs = length(dirs);
   for idDir = 1:nbDirs

      dirName = dirs(idDir).name;
      dirPathName = [DIR_INPUT_ARGOS_FILES '/' dirName];

      if (isdir(dirPathName))
         if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))

            fprintf('Processing directory %s\n', dirName);
            logFileForDir = [DIR_LOG_FILE '/' 'split_argos_messages' name '_' dirName '_' currentDate '.log'];

            % process one directory (one month)
            tic;
            %             split_argos_messages_one_month( ...
            %                DIR_INPUT_ARGOS_FILES, dirName, ...
            %                DIR_OUTPUT_ARGOS_FILES, currentDate, 0);
            cmd = ['matlab -nodesktop -nosplash -r "split_argos_messages_one_month(''' DIR_INPUT_ARGOS_FILES ''', ''' dirName ''', ''' DIR_OUTPUT_ARGOS_FILES ''', ''' currentDate ''', 0,''' logFileForDir ''');exit"'];
            system(cmd);
            ellapsedTime = toc;
            fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
         end
      end
   end
else
   for idY = firstYear:lastYear
      firstM = 1;
      lastM = 12;
      if (idY == firstYear)
         firstM = firstMonth;
      end
      if (idY == lastYear)
         lastM = lastMonth;
      end
      for idM = firstM:lastM

         dirName = sprintf('%04d%02d', idY, idM);
         dirPathName = [DIR_INPUT_ARGOS_FILES '/' dirName];

         if (isdir(dirPathName))

            fprintf('Processing directory %s\n', dirName);

            % process one directory (one month)
            tic;
            %             split_argos_messages_one_month( ...
            %                DIR_INPUT_ARGOS_FILES, dirName, ...
            %                DIR_OUTPUT_ARGOS_FILES, currentDate, 0);
            cmd = ['matlab -nodesktop -nosplash -r "split_argos_messages_one_month(''' DIR_INPUT_ARGOS_FILES ''', ''' dirName ''', ''' DIR_OUTPUT_ARGOS_FILES ''', ''' currentDate ''', 0);exit"'];
            system(cmd);
            ellapsedTime = toc;
            fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
         end
      end
   end
end

fprintf('done\n');

diary off;

return;
