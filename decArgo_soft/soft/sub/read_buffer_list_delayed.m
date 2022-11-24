% ------------------------------------------------------------------------------
% Read, in the appropriate file, the rank and associated cycle number of each
% file to be processed in RT.
%
% SYNTAX :
%  [o_fileNameList, o_fileRank, o_fileCyNum] = ...
%    read_buffer_list_delayed(a_floatNum, a_bufferFileDirName)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_bufferFileDirName : directory of buffer list file
%
% OUTPUT PARAMETERS :
%   o_fileNameList : name of files to process
%   o_fileRank     : rank of files to process
%   o_fileCyNum    : cycle number of files to process
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileNameList, o_fileRank, o_fileCyNum] = ...
   read_buffer_list_delayed(a_floatNum, a_bufferFileDirName)

% output parameters initialization
o_fileNameList = [];
o_fileRank = [];
o_fileCyNum = [];


bufferListFileName = [a_bufferFileDirName '/' num2str(a_floatNum) '_buffers.txt'];
if (exist(bufferListFileName, 'file') == 2)
   
   fId = fopen(bufferListFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', bufferListFileName);
   end
   
   data = textscan(fId, '%d %d %s');
   
   o_fileRank = data{1}(:);
   o_fileCyNum = data{2}(:);
   o_fileNameList = data{3}(:);
   
   fclose(fId);
end

return;
