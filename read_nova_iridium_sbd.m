% ------------------------------------------------------------------------------
% Read a set of SBD files to create the SBD data to be decoded.
%
% SYNTAX :
%  [o_sbdDataDate, o_sbdDataData] = read_nova_iridium_sbd(...
%    a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, a_printCsvFlag)
%
% INPUT PARAMETERS :
%   a_sbdFileNameList       : list of SBD file names
%   a_sbdFileDateList       : list of SBD file dates
%   a_a_sbdFileSizeListList : list of SBD file sizes
%   a_printCsvFlag          : CSV output flag
%
% OUTPUT PARAMETERS :
%   o_sbdDataDate : reception date of each SBD data frame
%   o_sbdDataData : concatenated SBD data frames
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/23/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_sbdDataDate, o_sbdDataData] = read_nova_iridium_sbd(...
   a_sbdFileNameList, a_sbdFileDateList, a_sbdFileSizeList, a_printCsvFlag)

% output parameters initialization
o_sbdDataDate = [];
o_sbdDataData = [];

% current float WMO number
global g_decArgo_floatNum;

% SBD sub-directories
global g_decArgo_bufferDirectory;
global g_decArgo_archiveSbdDirectory;

% to use virtual buffers instead of directories
global g_decArgo_virtualBuff;

% output CSV file Id
global g_decArgo_outputCsvFileId;


% no data to process
if (isempty(a_sbdFileNameList))
   return;
end

% read the SBD file data
for idBufFile = 1:length(a_sbdFileNameList)
   
   sbdFileName = a_sbdFileNameList{idBufFile};
   %       fprintf('SBD file : %s\n', sbdFileName);
   if (g_decArgo_virtualBuff)
      sbdFilePathName = [g_decArgo_archiveSbdDirectory '/' sbdFileName];
   else
      sbdFilePathName = [g_decArgo_bufferDirectory '/' sbdFileName];
   end
   sbdFileDate = a_sbdFileDateList(idBufFile);
   sbdFileSize = a_sbdFileSizeList(idBufFile);
   
   if (sbdFileSize > 0)
      
      fId = fopen(sbdFilePathName, 'r');
      if (fId == -1)
         fprintf('ERROR: Float #%d: Error while opening file : %s\n', ...
            g_decArgo_floatNum, ...
            sbdFilePathName);
      end
      
      [sbdData, sbdDataCount] = fread(fId);
      
      fclose(fId);
      
      info = get_bits(1, [8 16], sbdData);
      if (~isempty(o_sbdDataData) && (size(o_sbdDataData, 2) < info(2)-1))
         nbColToAdd = info(2)-1 - size(o_sbdDataData, 2);
         o_sbdDataData = cat(2, o_sbdDataData, repmat(-1, size(o_sbdDataData, 1), nbColToAdd));
      end
      data = [info(1) info(2)-3 sbdData(4:info(2))'];
      data = [data repmat(-1, 1, size(o_sbdDataData, 2)-length(data))];
      o_sbdDataData = [o_sbdDataData; data];
      o_sbdDataDate = [o_sbdDataDate; sbdFileDate];
   end
   
   % output CSV file
   if (a_printCsvFlag)
      if (~isempty(g_decArgo_outputCsvFileId))
         fprintf(g_decArgo_outputCsvFileId, '%d; -; info SBD file; File #%03d:   %s; Size: %d bytes; Nb Packets: 1\n', ...
            g_decArgo_floatNum, ...
            idBufFile, a_sbdFileNameList{idBufFile}, ...
            a_sbdFileSizeList(idBufFile));
      end
   end
end

return;
