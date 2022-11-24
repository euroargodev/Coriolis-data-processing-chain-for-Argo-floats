% ------------------------------------------------------------------------------
% Read, in the appropriate file, the rank of each file to be processed in RT.
%
% SYNTAX :
%  [o_fileNameList, o_fileRank] = read_buffer_list(a_floatNum, a_bufferFileDirName)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_bufferFileDirName : directory of buffer list file
%
% OUTPUT PARAMETERS :
%   o_fileNameList    : name of files to process
%   o_fileRank        : rank of files to process
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileNameList, o_fileRank] = read_buffer_list(a_floatNum, a_bufferFileDirName)

% output parameters initialization
o_fileNameList = [];
o_fileRank = [];


bufferListFileName = [a_bufferFileDirName '/' num2str(a_floatNum) '_buffers.txt'];
if (exist(bufferListFileName, 'file') == 2)
   
   fId = fopen(bufferListFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', bufferListFileName);
   end
   
   data = textscan(fId, '%d %s');
   
   o_fileRank = data{1}(:);
   o_fileNameList = data{2}(:);
   
   fclose(fId);

end

return;
