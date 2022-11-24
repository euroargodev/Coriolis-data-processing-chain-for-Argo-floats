% ------------------------------------------------------------------------------
% Read, in the appropriate file, the rank of each file to be processed in RT.
%
% SYNTAX :
%  [o_fileNameList, o_fileRank, o_fileDate, o_fileCyNum, o_fileProfNum] = ...
%    read_buffer_list(a_floatNum, a_bufferFileDirName, a_fileDirName, a_allInfo)
%
% INPUT PARAMETERS :
%   a_floatNum          : float WMO number
%   a_bufferFileDirName : directory of buffer list file
%   a_fileDirName       : directory of files
%   a_allInfo           : retrieve also o_fileDate, o_fileCyNum and o_fileProfNum
%
% OUTPUT PARAMETERS :
%   o_fileNameList : name of files to process
%   o_fileRank     : rank of files to process
%   o_fileDate     : date of files to process
%   o_fileCyNum    : cycle number of files to process
%   o_fileProfNum  : profile number of files to process
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_fileNameList, o_fileRank, o_fileDate, o_fileCyNum, o_fileProfNum] = ...
   read_buffer_list(a_floatNum, a_bufferFileDirName, a_fileDirName, a_allInfo)

% output parameters initialization
o_fileNameList = [];
o_fileRank = [];
o_fileDate = [];
o_fileCyNum = [];
o_fileProfNum = [];

global g_decArgo_janFirst1950InMatlab;


bufferListFileName = [a_bufferFileDirName '/' num2str(a_floatNum) '_buffers.txt'];
if (exist(bufferListFileName, 'file') == 2)
   
   fId = fopen(bufferListFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', bufferListFileName);
   end
   
   data = textscan(fId, '%d %s');
   
   o_fileRank = data{1}(:);
   fileNameList = data{2}(:);
   
   fclose(fId);

   for idFile = 1:length(o_fileRank)
      
      fileName = fileNameList{idFile};
      
      if (a_allInfo == 1)
         
         idFUs = strfind(fileName, '_');
         dateStr = fileName(idFUs(1)+1:idFUs(2)-1);
         date = datenum(dateStr, 'yyyymmddTHHMMSS') - g_decArgo_janFirst1950InMatlab;
         
         cycleStr = fileName(idFUs(3)+1:idFUs(4)-1);
         if (strcmp(cycleStr, 'xxx'))
            cycle = -1;
         else
            cycle = str2num(cycleStr);
         end
         
         profileStr = fileName(idFUs(4)+1:idFUs(5)-1);
         if (strcmp(profileStr, 'x'))
            profile = -1;
         else
            profile = str2num(profileStr);
         end
         
         o_fileDate(idFile) = date;
         o_fileCyNum(idFile) = cycle;
         o_fileProfNum(idFile) = profile;
      end
      filePathName = fileName;
      if (~isempty(a_fileDirName))
         filePathName = [a_fileDirName '/' fileName];
      end
      o_fileNameList{idFile} = filePathName;
   end
end

return;
