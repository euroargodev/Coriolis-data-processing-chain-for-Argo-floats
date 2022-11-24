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

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


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
   % '_%03d_%02d_uvp6_txo*.hex'
   % '_%03d_%02d_crover*.hex'
   % '_%03d_%02d_sbeph*.hex'
   % '_%03d_%02d_suna*.hex'
   % '_%03d_%02d_ramses*.hex'
   % '_%03d_%02d_ramses2*.hex'
   % '_%03d_%02d_mpe*.hex'
   % '_%03d_%02d_hydro_c*.hex'
   % '_%03d_%02d_hydro_m*.hex'
   % '_%03d_%02d_imu*.hex'
   % '_%03d_%02d_wave*.hex'

   for idType = [1 4 6:24]
      idFL = find([g_decArgo_fileTypeListCts5{:, 1}] == idType);
      pattern = g_decArgo_fileTypeListCts5{idFL, 5};
      inputFiles = dir([g_decArgo_archiveDirectory '/' a_filePrefix sprintf(pattern, a_cyNum, a_ptnNum)]);
      for iF = 1:length(inputFiles)
         % 'ramses2' are collected with 'ramses'
         if (idType == 17)
            if (any(strfind(inputFiles(iF).name, 'ramses2')))
               continue
            end
         end
         o_receivedFileList{end+1} = inputFiles(iF).name;
      end
   end
end

% if a #01 file is alone or if any #0i expected file is missing dont consider
% associated files
if (~isempty(o_receivedFileList))
   idMultiple = cellfun(@(x) strfind(o_receivedFileList, x), {'#'}, 'UniformOutput', 0);
   idMultiple = find(~cellfun(@isempty, idMultiple{:}) == 1);
   idDel = [];
   for idFile = idMultiple
      fileName = o_receivedFileList{idFile};
      idFD = strfind(fileName, '#');
      fileName = fileName(1:idFD);
      idM = cellfun(@(x) strfind(o_receivedFileList, x), {fileName}, 'UniformOutput', 0);
      idM = find(~cellfun(@isempty, idM{:}) == 1);
      if (length(idM) == 1)
         fprintf('DEC_ERROR: Float #%d Cycle #%d: file ''%s'' is alone - not decoded\n', ...
            g_decArgo_floatNum, ...
            g_decArgo_cycleNum, ...
            o_receivedFileList{idFile});
         idDel = [idDel idFile];
      else
         for id = 1:length(idM)
            fileName2 = sprintf('%s%02d', fileName, id);
            idM2 = cellfun(@(x) strfind(o_receivedFileList, x), {fileName2}, 'UniformOutput', 0);
            if (~isempty(idM2))
               idM2 = find(~cellfun(@isempty, idM2{:}) == 1);
            end
            if (isempty(idM2))
               fprintf('DEC_ERROR: Float #%d Cycle #%d: file ''%s'' is missing - associated files not decoded\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  fileName2);
               idDel = [idDel idM];
               break
            end
         end
      end
   end
   o_receivedFileList(unique(idDel)) = [];
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
