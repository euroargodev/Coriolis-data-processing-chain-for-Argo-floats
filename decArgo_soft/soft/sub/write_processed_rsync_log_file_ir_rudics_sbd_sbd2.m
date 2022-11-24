% ------------------------------------------------------------------------------
% Append new rsync log files in the file containing the list of the rsync log
% files already processed.
%
% SYNTAX :
%  write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, a_logFileList)
%
% INPUT PARAMETERS :
%   a_floatNum    : float WMO number
%   a_logFileList : new rsync log files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, a_logFileList)

% tmp directory
global g_decArgo_tmpDirectory;

if (~isempty(a_logFileList))
   
   % file name of the processed rsync log files
   logFileName = sprintf('processed_rsync_log_%d.txt', a_floatNum);
   logFilePathName = [g_decArgo_tmpDirectory '/' logFileName];
   
   % append the file
   fidOut = fopen(logFilePathName, 'a');
   if (fidOut == -1)
      fprintf('ERROR: Float #%d: Unable to open file: %s\n', a_floatNum, logFilePathName);
      return;
   end
   
   fprintf(fidOut, '%s\n', a_logFileList{:});
   
   fclose(fidOut);
end

return;
