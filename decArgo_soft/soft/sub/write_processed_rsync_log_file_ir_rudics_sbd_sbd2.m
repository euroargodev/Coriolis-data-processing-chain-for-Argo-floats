% ------------------------------------------------------------------------------
% Append new rsync log files in the file containing the list of the rsync log
% files already processed.
%
% SYNTAX :
%  write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, a_listType, a_logFileList)
%
% INPUT PARAMETERS :
%   a_floatNum    : float WMO number
%   a_listType    : type of list to save 'processed' or 'used'
%   a_logFileList : new rsync log files
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function write_processed_rsync_log_file_ir_rudics_sbd_sbd2(a_floatNum, a_listType, a_logFileList)

% history directory
global g_decArgo_historyDirectory;

% temporary directory used to store generated NetCDF files
global g_decArgo_ncTempDir;

% list of NetCDF files to move at the end of the run
global g_decArgo_filesToMove;


if (~isempty(a_logFileList))
   
   % file name of the processed rsync log files
   logFileName = [a_listType sprintf( '_rsync_log_%d.txt', a_floatNum)];
   logFilePathName = [g_decArgo_historyDirectory '/' logFileName];

   % need to make a copy because we append lines in the original file
   if (exist(logFilePathName, 'file') == 2)
      copy_file(logFilePathName, g_decArgo_ncTempDir)
   end

   tmpLogFilePathName = [g_decArgo_ncTempDir logFileName];
   
   % append the file
   fidOut = fopen(tmpLogFilePathName, 'a');
   if (fidOut == -1)
      fprintf('ERROR: Float #%d: Unable to open file: %s\n', a_floatNum, tmpLogFilePathName);
      return
   end
   
   fprintf(fidOut, '%s\n', a_logFileList{:});

   fclose(fidOut);

   % store NetCDF files to move
   g_decArgo_filesToMove = [g_decArgo_filesToMove; ...
      [{logFileName} {tmpLogFilePathName} {logFilePathName}]];
end

return
