% ------------------------------------------------------------------------------
% Retrieve the list of cycle numbers, pattern numbers for CTS5-USEA floats.
%
% SYNTAX :
%  [o_cycleList, o_cyclePatternList] = get_cycle_ptn_cts5_usea
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%   o_cycleList        : list of cycle numbers
%   o_cyclePatternList : list of pattern numbers
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cycleList, o_cyclePatternList] = get_cycle_ptn_cts5_usea

% output parameters initialization
o_cycleList = [];
o_cyclePatternList = [];

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
for idType = 1:size(g_decArgo_fileTypeListCts5, 1)
   files = dir([g_decArgo_archiveDirectory '/' [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 2}]]);
   for idFile = 1:length(files)
      fileName = files(idFile).name;
      
      if (g_decArgo_realtimeFlag == 1)
         % store information for the XML report
         g_decArgo_reportStruct.inputFiles = [g_decArgo_reportStruct.inputFiles ...
            {[g_decArgo_archiveDirectory '/' fileName]}];
      end
      
      switch (g_decArgo_fileTypeListCts5{idType, 1})
         case {2}
            % don't consider metadata.xml file because cycle # and pattern # may
            % be wrong (see 6903706)
         case {3}
            % only cycle #, no pattern #
            [val, count, errmsg, nextindex] = sscanf(fileName(1:g_decArgo_fileTypeListCts5{idType, 4}), [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 3}]);
            if (isempty(errmsg) && (count == 1))
               cycleList = [cycleList; val(1)];
            end
         otherwise
            % cycle # and pattern #
            [val, count, errmsg, nextindex] = sscanf(fileName(1:g_decArgo_fileTypeListCts5{idType, 4}), [g_decArgo_filePrefixCts5 g_decArgo_fileTypeListCts5{idType, 3}]);
            if (isempty(errmsg) && (count == 2))
               cyclePatternList = [cyclePatternList; val'];
            end
      end
   end
end
cyclePatternList = unique(cyclePatternList, 'rows');
cycleList = [cycleList; cyclePatternList(:, 1)];
cycleList = unique(cycleList);

o_cycleList = cycleList;
o_cyclePatternList = cyclePatternList;

return
