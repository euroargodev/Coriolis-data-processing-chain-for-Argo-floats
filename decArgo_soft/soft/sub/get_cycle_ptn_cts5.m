% ------------------------------------------------------------------------------
% Retrieve the list of cycle numbers, pattern numbers and payload configuration
% files.
%
% SYNTAX :
%  [o_cycleList, o_cyclePatternList, o_payloadConfFiles] = get_cycle_ptn_cts5
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_cycleList        : list of cycle numbers
%   o_cyclePatternList : list of pattern numbers
%   o_payloadConfFiles : list of payload configuration files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList, o_cyclePatternList, o_payloadConfFiles] = get_cycle_ptn_cts5

% output parameters initialization
o_cycleList = [];
o_cyclePatternList = [];
o_payloadConfFiles = [];

% input data dir
global g_decArgo_archiveDirectory;

% prefix of data file names
global g_decArgo_filePrefixCts5;

% type of files to consider
global g_decArgo_fileTypeListCts5;

% RT processing flag
global g_decArgo_realtimeFlag;

% report information structure
global g_decArgo_reportStruct;


% collect cycles and patterns to consider
cycleList = [];
cyclePatternList = [];
payloadConfFileList = [];
for idType = 1:size(g_decArgo_fileTypeListCts5, 1)
   if (g_decArgo_fileTypeListCts5{idType, 1} ~= 2)
      files = dir([g_decArgo_archiveDirectory '/' [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 2}]]);
   else
      files = dir([g_decArgo_archiveDirectory '/' g_decArgo_fileTypeListCts5{idType, 2}]);
   end
   for idFile = 1:length(files)
      fileName = files(idFile).name;
      
      if (g_decArgo_realtimeFlag == 1)
         % store information for the XML report
         g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
            {[g_decArgo_archiveDirectory '/' fileName]}];
      end
      
      switch (g_decArgo_fileTypeListCts5{idType, 1})
         case {1, 4, 6, 7, 9}
            [val, count, errmsg, nextindex] = sscanf(fileName(1:g_decArgo_fileTypeListCts5{idType, 4}), [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 3}]);
            if (isempty(errmsg) && (count == 2))
               cyclePatternList = [cyclePatternList; val'];
            end
         case {3, 5}
            [val, count, errmsg, nextindex] = sscanf(fileName(1:g_decArgo_fileTypeListCts5{idType, 4}), [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 3}]);
            if (isempty(errmsg) && (count == 1))
               cycleList = [cycleList; val(1)];
            end
         case 2
            % no cycle nor pattern in the name of the payload configuration
            % file
            fileName = [fileName(1:22) fileName(end-3:end)];
            payloadConfFileList{end+1} = fileName;
      end
   end
end
cyclePatternList = unique(cyclePatternList, 'rows');
cycleList = [cycleList; cyclePatternList(:, 1)];
cycleList = unique(cycleList);

% a=1; % reduce the number of cycles (for debug)
% cycleList(find(ismember(cycleList, 1:149))) = [];
% cyclePatternList(find(ismember(cyclePatternList(:, 1), 1:149)), :) = [];

o_cycleList = cycleList;
o_cyclePatternList = cyclePatternList;
o_payloadConfFiles = payloadConfFileList;

return
