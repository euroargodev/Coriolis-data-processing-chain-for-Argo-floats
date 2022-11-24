% ------------------------------------------------------------------------------
% Append new buffer determinations in the file containing the list of the buffer
% files already determined.
%
% SYNTAX :
%  write_buffer_list_ir_sbd_delayed(a_floatNum, ...
%    a_bufferRank, a_bufferFileList, a_bufferCyNumList)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_bufferRank      : buffer rank
%   a_bufferFileList  : buffer files
%   a_bufferCyNumList : buffer cycles
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/17/2016 - RNU - creation
% ------------------------------------------------------------------------------
function write_buffer_list_ir_sbd_delayed(a_floatNum, ...
   a_bufferRank, a_bufferFileList, a_bufferCyNumList)

% history directory
global g_decArgo_historyDirectory;


if (~isempty(a_bufferFileList))
   
   % file name of the processed rsync log files
   bufFilePathName = [g_decArgo_historyDirectory '/' num2str(a_floatNum) '_buffers.txt'];
   
   % mails with no attachment could be not sorted (in case of delayed
   % transmission)
   a_bufferFileList = sort(a_bufferFileList);
   
   % append the file
   fidOut = fopen(bufFilePathName, 'a');
   if (fidOut == -1)
      fprintf('ERROR: Float #%d: Unable to open file: %s\n', a_floatNum, bufFilePathName);
      return;
   end
   
   for idC = 1:length(a_bufferCyNumList)
      for idF = 1:length(a_bufferFileList)
         mailFileName = a_bufferFileList{idF};
         mailFileName = [mailFileName(1:end-4) '.txt'];
         fprintf(fidOut, '%d %d %s\n', a_bufferRank, a_bufferCyNumList(idC), mailFileName);
      end
   end
   
   fclose(fidOut);
end

return;
