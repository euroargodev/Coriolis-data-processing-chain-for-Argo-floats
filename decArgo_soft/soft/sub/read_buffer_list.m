% ------------------------------------------------------------------------------
% Read, in the appropriate file, the rank of each SBD file to be processed in
% DM.
%
% SYNTAX :
%  [o_sbdFileNameList, o_sbdFileRank, o_sbdFileDate, o_sbdFileCyNum, o_sbdFileProfNum] = ...
%    read_buffer_list(a_floatNum, a_dmSbdFileDirName)
%
% INPUT PARAMETERS :
%   a_floatNum         : float WMO number
%   a_dmSbdFileDirName : directory of buffer list files
%
% OUTPUT PARAMETERS :
%   o_sbdFileNameList : name of SBD files to process
%   o_sbdFileRank     : rank of SBD files to process
%   o_sbdFileDate     : date of SBD files to process
%   o_sbdFileCyNum    : cycle number of SBD files to process
%   o_sbdFileProfNum  : profile number of SBD files to process
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sbdFileNameList, o_sbdFileRank, o_sbdFileDate, o_sbdFileCyNum, o_sbdFileProfNum] = ...
   read_buffer_list(a_floatNum, a_dmSbdFileDirName)

o_sbdFileNameList = [];
o_sbdFileRank = [];
o_sbdFileDate = [];
o_sbdFileCyNum = [];
o_sbdFileProfNum = [];

global g_decArgo_dirInputDmBufferList;

global g_decArgo_janFirst1950InMatlab;


bufferListFileName = [g_decArgo_dirInputDmBufferList '/' num2str(a_floatNum) '_buffers.txt'];
if (exist(bufferListFileName, 'file') == 2)
   
   fId = fopen(bufferListFileName, 'r');
   if (fId == -1)
      fprintf('ERROR: Error while opening file : %s\n', bufferListFileName);
   end
   
   data = textscan(fId, '%d %s');
   
   o_sbdFileRank = data{1}(:);
   sbdFileName = data{2}(:);
   
   fclose(fId);

   for idFile = 1:length(o_sbdFileRank)
      
      fileName = sbdFileName{idFile};
      
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
      
      o_sbdFileNameList{idFile} = [a_dmSbdFileDirName '/' sbdFileName{idFile}];
      o_sbdFileDate(idFile) = date;
      o_sbdFileCyNum(idFile) = cycle;
      o_sbdFileProfNum(idFile) = profile;
   end
end

return;
