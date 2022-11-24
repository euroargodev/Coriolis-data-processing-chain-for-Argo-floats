% ------------------------------------------------------------------------------
% Append new buffer determinations in the file containing the list of the buffer
% files already determined.
%
% SYNTAX :
%     write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, a_bufferFileList, a_bufferRank)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_bufferFileList : buffer files
%   a_bufferRank     : buffer rank
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function write_buffer_list_ir_rudics_sbd_sbd2(a_floatNum, a_bufferFileList, a_bufferRank)

% history directory
global g_decArgo_historyDirectory;


if (~isempty(a_bufferFileList))
   
   % file name of the processed rsync log files
   bufFilePathName = [g_decArgo_historyDirectory '/' num2str(a_floatNum) '_buffers.txt'];
   
   % append the file
   fidOut = fopen(bufFilePathName, 'a');
   if (fidOut == -1)
      fprintf('ERROR: Float #%d: Unable to open file: %s\n', a_floatNum, bufFilePathName);
      return;
   end
   
   for idF = 1:length(a_bufferFileList)
      fprintf(fidOut, '%d %s\n', a_bufferRank, a_bufferFileList{idF});
   end
   
   fclose(fidOut);
end

return;
