% ------------------------------------------------------------------------------
% Extract, from event data, the list of files expected for a given cycle and
% pattern.
%
% SYNTAX :
%  [o_expectedFileList] = get_expected_file_list(a_cyNum, a_ptnNum, a_filePrefix, a_firstCycle)
%
% INPUT PARAMETERS :
%   a_cyNum      : concerned cycle number
%   a_ptnNum     : concerned pattern number
%   a_filePrefix : prefix of float transmitted files
%   a_firstCycle : first cycle to consider
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_expectedFileList] = get_expected_file_list(a_cyNum, a_ptnNum, a_filePrefix, a_firstCycle)

% output parameters initialization
o_expectedFileList = [];

% input data dir
global g_decArgo_archiveDirectory;

% type of files to consider
global g_decArgo_fileTypeListCts5;

% variable to store all useful event data
global g_decArgo_eventData;

% cycle numbers missing in event data
global g_decArgo_eventDataUnseenCycleNum;


if (~isempty(a_ptnNum) && (a_ptnNum > 0))
   
   idF = find(([g_decArgo_eventData{:, 1}] == a_cyNum) & ([g_decArgo_eventData{:, 2}] == a_ptnNum));
   idF2 = find([g_decArgo_eventData{idF, 4}] == 28);
   o_expectedFileList = [o_expectedFileList g_decArgo_eventData{idF(idF2), 5}];
   idF2 = find([g_decArgo_eventData{idF, 4}] == 76);
   list = [g_decArgo_eventData{idF(idF2), 5}];
   if (~isempty(list))
      list2 = 1:2:length(list);
      idF3 = find([list{list2}] ~= 0);
      if (~isempty(idF3))
         list3 = list(list2(idF3)+1);
         o_expectedFileList = [o_expectedFileList list3];
      end
   end
   
   % an input cmd has be processed
   if (~isempty(find([g_decArgo_eventData{idF, 4}] == 141, 1)))
      o_expectedFileList = [o_expectedFileList [a_filePrefix sprintf('_%03d_%02d_apmt.ini', a_cyNum, a_ptnNum)]];
   end
   
   % skipped files
   if (~isempty(find([g_decArgo_eventData{idF, 4}] == 127, 1)))
      idF2 = find([g_decArgo_eventData{idF, 4}] == 127);
      for id = 1:length(idF2)
         fileName = g_decArgo_eventData{idF(idF2(id)), 5};
         idF3 = find(strcmp(o_expectedFileList, fileName));
         o_expectedFileList(idF3) = [];
      end
   end
   
   pattern = [a_filePrefix sprintf('_%03d_%02d_sbe41.bin', a_cyNum, a_ptnNum)];
   idF2 = find(strncmp(o_expectedFileList, pattern, length(pattern)));
   o_expectedFileList(idF2) = [];
   
elseif (~isempty(a_ptnNum) && (a_ptnNum == 0))
   
   idF2 = find([g_decArgo_eventData{:, 4}] == 28);
   o_expectedFileList = [o_expectedFileList g_decArgo_eventData{idF2, 5}];
   idF2 = find([g_decArgo_eventData{:, 4}] == 76);
   list = [g_decArgo_eventData{idF2, 5}];
   if (~isempty(list))
      list2 = 1:2:length(list);
      idF3 = find([list{list2}] ~= 0);
      if (~isempty(idF3))
         list3 = list(list2(idF3)+1);
         o_expectedFileList = [o_expectedFileList list3];
      end
   end
   
   % skipped files
   if (~isempty(find([g_decArgo_eventData{:, 4}] == 127, 1)))
      idF2 = find([g_decArgo_eventData{:, 4}] == 127);
      for id = 1:length(idF2)
         fileName = g_decArgo_eventData{idF2(id), 5};
         idF3 = find(strcmp(o_expectedFileList, fileName));
         o_expectedFileList(idF3) = [];
      end
   end
   
   % look for a possible reset of the float during its mission
   if (a_cyNum > a_firstCycle)
      pattern1 = [a_filePrefix sprintf('_%03d_autotest_', a_cyNum)];
      % if the float has been reset at sea the apmt.ini file (with a_ptnNum=0)
      % is not in the SYSTEM files
      if (any(strncmp(o_expectedFileList, pattern1, length(pattern1))))
         o_expectedFileList = [o_expectedFileList [a_filePrefix sprintf('_%03d_%02d_apmt.ini', a_cyNum, a_ptnNum)]];
         o_expectedFileList = [o_expectedFileList [a_filePrefix sprintf('_%03d_%02d_payload.xml', a_cyNum, a_ptnNum)]];
      end
   end
      
   pattern = [a_filePrefix sprintf('_%03d_%02d_', a_cyNum, a_ptnNum)];
   idF2 = find(strncmp(o_expectedFileList, pattern, length(pattern)));
   o_expectedFileList = o_expectedFileList(idF2);
   
   % first cycle
   if (a_cyNum == a_firstCycle)
      o_expectedFileList = [o_expectedFileList [a_filePrefix sprintf('_%03d_%02d_apmt.ini', a_cyNum, a_ptnNum)]];
      %       o_expectedFileList = [o_expectedFileList [a_filePrefix
      %       sprintf('_%03d_%02d_payload.xml', a_cyNum, a_ptnNum)]]; %
      %       considered in init_float_config_prv_ir_rudics_cts5
   end
   
else
   
   idF2 = find([g_decArgo_eventData{:, 4}] == 28);
   o_expectedFileList = [o_expectedFileList g_decArgo_eventData{idF2, 5}];
   idF2 = find([g_decArgo_eventData{:, 4}] == 76);
   list = [g_decArgo_eventData{idF2, 5}];
   if (~isempty(list))
      list2 = 1:2:length(list);
      idF3 = find([list{list2}] ~= 0);
      if (~isempty(idF3))
         list3 = list(list2(idF3)+1);
         o_expectedFileList = [o_expectedFileList list3];
      end
   end
   
   % skipped files
   if (~isempty(find([g_decArgo_eventData{:, 4}] == 127, 1)))
      idF2 = find([g_decArgo_eventData{:, 4}] == 127);
      for id = 1:length(idF2)
         fileName = g_decArgo_eventData{idF2(id), 5};
         idF3 = find(strcmp(o_expectedFileList, fileName));
         o_expectedFileList(idF3) = [];
      end
   end
   
   pattern1 = [a_filePrefix sprintf('_%03d_autotest_', a_cyNum)];
   pattern2 = [a_filePrefix sprintf('_%03d_default _', a_cyNum)];
   idF2 = find(strncmp(o_expectedFileList, pattern1, length(pattern1)) | ...
      strncmp(o_expectedFileList, pattern2, length(pattern2)));
   o_expectedFileList = o_expectedFileList(idF2);
end

% some cycles are not present in event data (Ex: 4901801 reseted at cycle 44)
if (ismember(a_cyNum, g_decArgo_eventDataUnseenCycleNum))
   
   if (~isempty(a_ptnNum))
      
      typeWithCycleAndPattern = [1 4 5 6 7 9];
      for idType = 1:size(g_decArgo_fileTypeListCts5, 1)
         if (ismember(g_decArgo_fileTypeListCts5{idType, 1}, typeWithCycleAndPattern))
            files = dir([g_decArgo_archiveDirectory '/' ...
               [a_filePrefix sprintf(g_decArgo_fileTypeListCts5{idType, 5}, a_cyNum, a_ptnNum)]]);
            for idFile = 1:length(files)
               fileName = files(idFile).name;
               [~, fileName, fileNameExt] = fileparts(fileName);
               o_expectedFileList = [o_expectedFileList {[fileName(1:end-15) fileNameExt]}];
            end
         end
      end
   else
      
      typeWithCycleOnly = [3];
      for idType = 1:size(g_decArgo_fileTypeListCts5, 1)
         if (ismember(g_decArgo_fileTypeListCts5{idType, 1}, typeWithCycleOnly))
            files = dir([g_decArgo_archiveDirectory '/' ...
               [a_filePrefix sprintf(g_decArgo_fileTypeListCts5{idType, 5}, a_cyNum)]]);
            for idFile = 1:length(files)
               fileName = files(idFile).name;
               [~, fileName, fileNameExt] = fileparts(fileName);
               o_expectedFileList = [o_expectedFileList {[fileName(1:end-15) fileNameExt]}];
            end
         end
      end
   end
   
   o_expectedFileList = unique(o_expectedFileList);
   
   % manage split files
   idF = strfind(o_expectedFileList, '#');
   if (~isempty(cell2mat(idF)))
      for idFile = 1:length(o_expectedFileList)
         [~, fileName, fileNameExt] = fileparts(o_expectedFileList{idFile});
         idF = strfind(fileName, '#');
         if (~isempty(idF))
            o_expectedFileList{idFile} = [fileName(1:idF(1)-1) fileNameExt];
         end
      end
   end
   
   o_expectedFileList = unique(o_expectedFileList);
   
end

o_expectedFileList = o_expectedFileList';

return
