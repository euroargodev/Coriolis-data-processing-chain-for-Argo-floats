% ------------------------------------------------------------------------------
% Retrieve the list of files received for a given cycle and pattern from a
% CTS5-USEA float.
%
% SYNTAX :
%  [o_receivedFileList] = get_received_file_list_usea(a_cyNum, a_ptnNum, a_filePrefix)
%
% INPUT PARAMETERS :
%   a_cyNum      : concerned cycle number
%   a_ptnNum     : concerned pattern number
%   a_filePrefix : prefix of float transmitted files
%
% OUTPUT PARAMETERS :
%   o_receivedFileList : list of received files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_receivedFileList] = get_received_file_list_usea(a_cyNum, a_ptnNum, a_filePrefix)

% output parameters initialization
o_receivedFileList = [];

% input data dir
global g_decArgo_archiveDirectory;

% type of files to consider
global g_decArgo_fileTypeListCts5;


if (isempty(a_ptnNum))
   
   % '_%03d_autotest_*.txt'
   % '_%03d_%02d_default_*.txt'
   for idType = [3 5]
      idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
      pattern = g_decArgo_fileTypeListCts5{idFL, 5};
      inputFiles = dir([g_decArgo_archiveDirectory '/' a_filePrefix sprintf(pattern, a_cyNum)]);
      for iF = 1:length(inputFiles)
         o_receivedFileList{end+1} = inputFiles(iF).name;
      end
   end
else
   % '_%03d_%02d_apmt*.ini'
   % '_%03d_%02d_technical*.txt'
   % '_%03d_%02d_sbe41*.hex'
   % '_%03d_%02d_do*.hex'
   % '_%03d_%02d_eco*.hex'
   % '_%03d_%02d_ocr*.hex'
   % '_%03d_%02d_opus_blk*.hex'
   % '_%03d_%02d_opus_lgt*.hex'
   % '_%03d_%02d_uvp6_blk*.hex'
   % '_%03d_%02d_uvp6_lpm*.hex'
   % '_%03d_%02d_crover*.hex'
   % '_%03d_%02d_sbeph*.hex'
   % '_%03d_%02d_suna*.hex'
   % '_%03d_%02d_ramses*.hex'
   % '_%03d_%02d_mpe*.hex'

   for idType = [1 4 6:18]
      idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
      pattern = g_decArgo_fileTypeListCts5{idFL, 5};
      inputFiles = dir([g_decArgo_archiveDirectory '/' a_filePrefix sprintf(pattern, a_cyNum, a_ptnNum)]);
      for iF = 1:length(inputFiles)
         o_receivedFileList{end+1} = inputFiles(iF).name;
      end
   end
end

for idF = 1:length(o_receivedFileList)
   expectedFileList = o_receivedFileList{idF};
   idFP = strfind(expectedFileList, '.');
   idFD = strfind(expectedFileList, '#');
   idFUs = strfind(expectedFileList, '_');
   idStart = idFUs(end);
   if (~isempty(idFD))
      idStart = idFD(end);
   end
   idEnd = idFP(end);
   expectedFileList(idStart:idEnd-1) = '';
   o_receivedFileList{idF} = expectedFileList;
end

o_receivedFileList = unique(o_receivedFileList);

return
