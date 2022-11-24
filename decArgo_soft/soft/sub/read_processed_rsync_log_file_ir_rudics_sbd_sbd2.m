% ------------------------------------------------------------------------------
% Read the file containing the list of the rsync log files already processed.
%
% SYNTAX :
%  [o_processedLogFiles] = read_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum)
%
% INPUT PARAMETERS :
%   a_floatNum : float WMO number
%
% OUTPUT PARAMETERS :
%   o_processedLogFiles : list of already processed rsync log file names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_processedLogFiles] = read_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum)

% output parameters initialization
o_processedLogFiles = [];

% history directory
global g_decArgo_historyDirectory;


% file name of the processed rsync log file list
logFileName = sprintf('processed_rsync_log_%d.txt', a_floatNum);
logFilePathName = [g_decArgo_historyDirectory '/' logFileName];

if ~(exist(logFilePathName, 'file') == 2)
   return
else
   fId = fopen(logFilePathName, 'r');
   if (fId == -1)
      fprintf('ERROR: Unable to open file: %s\n', logFilePathName);
      return
   end
   o_processedLogFiles = textscan(fId, '%s');
   o_processedLogFiles = o_processedLogFiles{:};
   fclose(fId);
end

return
