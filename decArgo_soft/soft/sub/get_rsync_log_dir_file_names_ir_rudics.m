% ------------------------------------------------------------------------------
% Retrieve the list of the rsync log file names in a given directory.
%
% SYNTAX :
%  [o_fileName] = get_rsync_log_dir_file_names_ir_rudics(a_dirName)
%
% INPUT PARAMETERS :
%   a_dirName : concerned directory
%
% OUTPUT PARAMETERS :
%   o_fileName : file names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileName] = get_rsync_log_dir_file_names_ir_rudics(a_dirName)

% output parameters initialization
o_fileName = [];


% check the rsyncLog files of the directory
rsyncLogFiles = dir([a_dirName '/rsync_*.txt']);
fileDate = [];
for idFile = 1:length(rsyncLogFiles)
   
   rsyncLogFileName = rsyncLogFiles(idFile).name;
   rsyncLogFilePathName = [a_dirName '/' rsyncLogFileName];
   rsyncLogFileDate = datenum(rsyncLogFileName(7:21), 'yyyymmddTHHMMSS');
   
   o_fileName{end+1} = rsyncLogFilePathName;
   fileDate(end+1) = rsyncLogFileDate;
end

% chronologically sort the files
[fileDate, idSort] = sort(fileDate);
o_fileName = o_fileName(idSort);

return
